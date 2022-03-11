//
// This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
// Copyright © Adguard Software Limited. All rights reserved.
//
// Adguard for iOS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Adguard for iOS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Adguard for iOS. If not, see <http://www.gnu.org/licenses/>.
//

import OrderedCollections
import SharedAdGuardSDK

private let LOG = ComLog_LoggerFactory.getLoggerWrapper(DnsUserRulesStorage.self)

final class DnsUserRulesStorage: UserRulesStorageProtocol {

    var rules: OrderedSet<UserRule> {
        get {
            if self.userRules != nil {
                return self.userRules!
            }

            // TODO: we should store DISABLED rules, not enabled, the list would be shorter this way
            let allRules = getAllRules()
            let enabledRules = Set(getEnabledRules())
            let rulesObjects: [UserRule] = allRules.map {
                let isEnabled = enabledRules.contains($0)
                return UserRule(ruleText: $0, isEnabled: isEnabled)
            }
            self.userRules = OrderedSet(rulesObjects)

            return self.userRules!;
        }
        set {
            var allRules: [String] = []
            var enabledRules: [String] = []
            newValue.forEach {
                allRules.append($0.ruleText)
                if $0.isEnabled {
                    enabledRules.append($0.ruleText)
                }
            }
            saveAllRules(allRules)
            saveEnabledRules(enabledRules)
            self.userRules = nil
        }
    }

    // MARK: - Private properties

    private let type: DnsUserRuleType
    private let fileStorage: FilterFilesStorageProtocol
    private var userRules: OrderedSet<UserRule>?

    // fileStorage should be passed as new object with unique folder to avoid filters ids collisions
    init(type: DnsUserRuleType, fileStorage: FilterFilesStorageProtocol, readOnly: Bool = false) {
        LOG.info("Init start")
        self.type = type
        self.fileStorage = fileStorage

        /*
         The only purpose of readOnly is to disable this part of functionality when this
         class is initialized in the Tunnel process.
         The reason for it is this bug: https://github.com/AdguardTeam/AdguardForiOS/issues/1907
         Despite that the code below is perfectly valid and *should* work inside Tunnel,
         something very wrong happens after the device reboot and we somehow replace the
         existing user rules files with empty ones.
         TODO: figure out what's the real cause or reformat the code.
         */
        if (!readOnly) {
            // Create empty file if doesn't exist for all rules
            if fileStorage.getFilterContentForFilter(withId: type.allRulesFilterId) == nil {
                do {
                    LOG.info("Filter \(type.allRulesFilterId) not found, creating an empty filter")
                    try fileStorage.saveFilter(withId: type.allRulesFilterId, filterContent: "")
                } catch {
                    LOG.error("Failed to create empty file with id=\(type.allRulesFilterId). It can lead to various errors")
                }
            }

            // Create empty file if doesn't exist for enabled rules
            if fileStorage.getFilterContentForFilter(withId: type.enabledRulesFilterId) == nil {
                do {
                    LOG.info("Filter \(type.enabledRulesFilterId) not found, creating an empty filter")
                    try fileStorage.saveFilter(withId: type.enabledRulesFilterId, filterContent: "")
                } catch {
                    LOG.error("Failed to create empty file with id=\(type.enabledRulesFilterId). It can lead to various errors")
                }
            }
        }
        LOG.info("Init end")
    }

    // MARK: - Private methods

    private func getAllRules() -> [String] {
        guard let rules = fileStorage.getFilterContentForFilter(withId: type.allRulesFilterId) else {
            return []
        }
        return rules.isEmpty ? [] : rules.components(separatedBy: .newlines)
    }

    private func saveAllRules(_ rules: [String]) {
        let rulesString = rules.joined(separator: "\n")
        do {
            try fileStorage.saveFilter(withId: type.allRulesFilterId, filterContent: rulesString)
        } catch {
            LOG.error("Error saving all rules; Error: \(error)")
        }
    }

    private func getEnabledRules() -> [String] {
        guard let rules = fileStorage.getFilterContentForFilter(withId: type.enabledRulesFilterId) else {
            return []
        }
        return rules.components(separatedBy: .newlines)
    }

    private func saveEnabledRules(_ rules: [String]) {
        let rulesString = rules.joined(separator: "\n")
        do {
            try fileStorage.saveFilter(withId: type.enabledRulesFilterId, filterContent: rulesString)
        } catch {
            LOG.error("Error saving enabled rules; Error: \(error)")
        }
    }
}

// MARK: - DnsUserRuleType + Filter ids

extension DnsUserRuleType {

    var enabledRulesFilterId: Int {
        switch self {
        case .allowlist: return 10001
        case .blocklist: return 10002
        }
    }

    fileprivate var allRulesFilterId: Int {
        switch self {
        case .allowlist: return 10003
        case .blocklist: return 10004
        }
    }
}
