import Foundation
@_implementationOnly import ContentBlockerConverter

// MARK: - FilterFileContent

struct FilterFileContent: Equatable {
    let text: String
    let lines: [String]
    let group: SafariGroup.GroupType
    
    init(text: String, group: SafariGroup.GroupType) {
        self.text = text
        self.lines = text.components(separatedBy: .newlines)
        self.group = group
    }
}

// MARK: - ContentBlockerConverterWrapper

/*
 This converter is a wrapper for ContentBlockerConverter responsible for converting rules to JSON files
 We use it in order to be able to test code in FiltersConverter
 cbType is used to differ conversion results because ConversionResult init is inaccessible
 */
protocol ContentBlockerConverterProtocol {
    func convertArray(rules: [String], safariVersion: SafariVersion, optimize: Bool, advancedBlocking: Bool) -> ConversionResult?
}

final class ContentBlockerConverterWrapper: ContentBlockerConverterProtocol {
    func convertArray(rules: [String], safariVersion: SafariVersion, optimize: Bool, advancedBlocking: Bool) -> ConversionResult? {
        let converter = ContentBlockerConverter()
        let result = converter.convertArray(rules: rules, safariVersion: safariVersion, optimize: optimize, advancedBlocking: advancedBlocking)
        return result
    }
}

// MARK: - FiltersConverter

protocol FiltersConverterProtocol {
    /**
     Creates **SafariFilter** objects from all available rules for each content blocker
     - Parameter filters: Array of enabled predefined and custom filters
     - Parameter blocklistRules: Array of enabled blocklist user rules
     - Parameter allowlistRules: Array of enabled blocklist user rules
     - Parameter invertedAllowlistRulesString: String represantation of enabled inverted allowlist rules
     Note that one of **allowlistRules** and **invertedAllowlistRulesString** should be nil
     - Returns: ContentBlockerConverter result for each content blocker
     */
    func convert(filters: [FilterFileContent], blocklistRules: [String]?, allowlistRules: [String]?, invertedAllowlistRulesString: String?) -> [FiltersConverter.Result]?
}

struct FiltersConverter: FiltersConverterProtocol {

    // MARK: - Result
    
    /* This struct is used to represent Converted Lib result and return only usefull info */
    struct Result {
        let type: ContentBlockerType // Content blocker type the result is related with
        let jsonString: String // String representation of converted JSON we receive from Converter Lib
        let totalRules: Int // Total valis rules number, because some rules that we pass can be invalid
        let totalConverted: Int // The result number of rules with Content blockers limit of 'contentBlockerRulesLimit' rules
        let overlimit: Bool // Is true if totalRules is greater than 'contentBlockerRulesLimit' rules
    }
    
    private let configuration: SafariConfigurationProtocol
    private let converter: ContentBlockerConverterProtocol
    
    init(configuration: SafariConfigurationProtocol, converter: ContentBlockerConverterProtocol = ContentBlockerConverterWrapper()) {
        self.configuration = configuration
        self.converter = converter
    }
    
    // MARK: - Internal method
    
    func convert(filters: [FilterFileContent], blocklistRules: [String]?, allowlistRules: [String]?, invertedAllowlistRulesString: String?) -> [Result]? {
        let sortedRules = sortRulesByContentBlockers(filters, blocklistRules, allowlistRules, invertedAllowlistRulesString)
        let safariFilters = convert(filters: sortedRules)
        return safariFilters
    }
    
    // MARK: - private methods
    
    // Sorts all filters and rules by content blockers
    func sortRulesByContentBlockers(_ filters: [FilterFileContent],
                                    _ blocklistRules: [String]?,
                                    _ allowlistRules: [String]?,
                                    _ invertedAllowlistRulesString: String?) -> [ContentBlockerType: [String]]
    {
        var filterRules = parse(filters: filters)
        addUserRules(blocklistRules: blocklistRules,
                     allowlistRules: allowlistRules,
                     invertedAllowlistRulesString: invertedAllowlistRulesString,
                     filters: &filterRules)
        return filterRules
    }
    
    // Returns rules sorted by content blockers
    private func parse(filters: [FilterFileContent]) -> [ContentBlockerType: [String]] {
        var rulesByCBType: [ContentBlockerType: [String]] = [:]
        ContentBlockerType.allCases.forEach { rulesByCBType[$0] = [] }
        
        for filter in filters {
            let rules = AffinityRulesParser.parse(strings: filter.lines)
            let cbType = filter.group.contentBlockerType
            sortRulesByAffinity(filterRules: rules, defaultCBType: cbType, rulesByAffinityBlocks: &rulesByCBType)
        }
        
        return rulesByCBType
    }
    
    // Sorts rules by affinity and adds them to the proper content blocker
    private func sortRulesByAffinity(filterRules: [FilterRule], defaultCBType: ContentBlockerType, rulesByAffinityBlocks: inout [ContentBlockerType: [String]]) {
        for rule in filterRules {
            guard let ruleAffinity = rule.affinity else {
                rulesByAffinityBlocks[defaultCBType]?.append(rule.rule)
                continue
            }
            
            for type in ContentBlockerType.allCases {
                let affinity = type.affinity
                if ruleAffinity == .all || ruleAffinity.contains(affinity) {
                    rulesByAffinityBlocks[type]?.append(rule.rule)
                }
            }
        }
    }
    
    // Adds all types of user rules to all content blockers
    private func addUserRules(blocklistRules: [String]?, allowlistRules: [String]?, invertedAllowlistRulesString: String?, filters: inout [ContentBlockerType: [String]]) {
        // add blacklist rules
        if let blocklistRules = blocklistRules {
            filters.keys.forEach { filters[$0]?.append(contentsOf: blocklistRules) }
        }
        
        // add allowlist rules
        if let allowlistRules = allowlistRules {
            let converter = AllowlistRuleConverter()
            let properAllowlistRules = allowlistRules.map { converter.convertDomainToRule($0) }
            filters.keys.forEach { filters[$0]?.append(contentsOf: properAllowlistRules) }
        }
        
        // add inverted allowlist rules string
        if let invertedAllowlistRulesString = invertedAllowlistRulesString {
            filters.keys.forEach { filters[$0]?.append(invertedAllowlistRulesString) }
        }
    }
    
    // Converts all rules to jsons
    private func convert(filters: [ContentBlockerType: [String]]) -> [Result] {
        var resultFilters: [Result] = []
        let safariVersion = SafariVersion(rawValue: configuration.iosVersion) ?? .safari15
        for (cbType, rules) in filters {
            guard let result = converter.convertArray(rules: rules, safariVersion: safariVersion, optimize: false, advancedBlocking: configuration.advancedBlockingIsEnabled) else {
                Logger.logError("FiltersConverter error - can not convert filter with type: \(cbType)")
                continue
            }
            Logger.logInfo("FiltersCoverter result: \(result.message)")
            
            // Just take the info we need
            let safariFilter = Result(type: cbType,
                                      jsonString: result.converted,
                                      totalRules: result.totalConvertedCount,
                                      totalConverted: result.convertedCount,
                                      overlimit: result.overLimit)
            resultFilters.append(safariFilter)
        }
        return resultFilters
    }
}
