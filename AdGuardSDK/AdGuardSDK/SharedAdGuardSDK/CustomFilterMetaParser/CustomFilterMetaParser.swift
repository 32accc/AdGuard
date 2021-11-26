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

import Foundation

// MARK: - CustomFilterMetaParserError

public enum CustomFilterMetaParserError: Error {
    case invalidFileContent
}

// MARK: - CustomFilterMetaParserType

public enum CustomFilterMetaParserType {
    case safari
    case system
}

// MARK: - CustomFilterMetaParserProtocol

public protocol CustomFilterMetaParserProtocol {
    /**
     Parses filter's file content and converts content to FilterMetadata object.
     ```
     Filter example: https://easylist.to/easylist/easylist.txt
     ```

     - Parameter filterFileContentString: File content as string
     - Parameter parserType: Parsing can differ for **system** and **safary** filters
     - Throws: Throws an error if parsing fails
     - Returns: FilterMetadata object
     */
    func parse(_ filterFileContentString: String, for parserType: CustomFilterMetaParserType, filterDownloadPage: String?) throws -> ExtendedCustomFilterMetaProtocol
}

// MARK: - CustomFilterMetaParserProtocol + default implementation

public extension CustomFilterMetaParserProtocol {

    func parse(_ filterFileContentString: String, for parserType: CustomFilterMetaParserType, filterDownloadPage: String?) throws -> ExtendedCustomFilterMetaProtocol {

        // Check if file's content is valid
        guard !isInvalid(content: filterFileContentString) else {
            throw CustomFilterMetaParserError.invalidFileContent
        }

        // When header is parsed we suppose that lines started with '!' and in case of system protection filters '#'
        // are comments and we don't parse them as header
        var headerWasParsed = false

        // Header possible values
        var name: String?
        var description: String?
        var version: String?
        var lastUpdateDate: Date?
        var homePage: String?
        var licensePage: String?
        var issuesReportPage: String?
        var communityPage: String?
        var filterDownloadPageInternal: String?
        var rulesCount: Int = 0

        // Iterating over file's content line by line
        filterFileContentString.enumerateLines { line, _ in

            // Filter's header can begin with it's name in brackets, for example: [Adblock Plus 2.0]
            if line.first == "[" && line.last == "]" && !headerWasParsed {
                return
            }

            // Process line as header if it starts with '!' and header wasn't parsed yet
            if line.first == "!" && !headerWasParsed {
                processHeader(line: line,
                              &name,
                              &description,
                              &version,
                              &lastUpdateDate,
                              &homePage,
                              &licensePage,
                              &issuesReportPage,
                              &communityPage,
                              &filterDownloadPageInternal)
                return
            }

            // When line doesn't start with '!' we suppose that header was parsed
            headerWasParsed = true

            // Ignore blank lines
            if line.isEmpty {
                return
            }

            // Ignore comments when counting rules
            if line.first == "!" {
                return
            }

            // '#' can also be a comment but only for DNS filters
            if line.first == "#" && parserType == .system {
                return
            }

            // If line is not a comment increment rules number
            rulesCount += 1
        }

        // Return result object when all lines are parsed
        return CustomFilterMeta(
            name: name,
            description: description,
            version: version,
            lastUpdateDate: lastUpdateDate,
            homePage: homePage,
            licensePage: licensePage,
            issuesReportPage: issuesReportPage,
            communityPage: communityPage,
            filterDownloadPage: filterDownloadPage ?? filterDownloadPageInternal,
            rulesCount: rulesCount
        )
    }


    /**
     Processes header line and sets values for the variables
     For example: ! Title: AdGuard Turkish filter (Optimized)
     Line will be processed and description variable will be set to: description = "AdGuard Turkish filter (Optimized)"
     */
    private func processHeader(line: String,
                                      _ name: inout String?,
                                      _ description: inout String?,
                                      _ version: inout String?,
                                      _ lastUpdateDate: inout Date?,
                                      _ homePage: inout String?,
                                      _ licensePage: inout String?,
                                      _ issuesReportPage: inout String?,
                                      _ communityPage: inout String?,
                                      _ filterDownloadPage: inout String?) {

        let lowercasedLine = line.lowercased()
        let headerLowercasedTags = ["title", "description", "version", "last modified", "timeupdated", "homepage", "license", "licence", "reporting issues", "community", "download"]

        for tag in headerLowercasedTags {
            if let tagRange = lowercasedLine.range(of: tag + ":"), tagRange.upperBound < line.endIndex {
                let tagValue = line[tagRange.upperBound ..< line.endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                switch tag {
                case "title": name = tagValue
                case "description": description = tagValue
                case "version": version = tagValue
                case "last modified", "timeupdated": lastUpdateDate = processUpdateDate(tagValue)
                case "homepage": homePage = tagValue
                case "license", "licence": licensePage = tagValue
                case "reporting issues": issuesReportPage = tagValue
                case "community": communityPage = tagValue
                case "download": filterDownloadPage = tagValue
                default: continue
                }
                return
            }
        }
    }

    /**
     Converts filter last modification date string to Date object
     For example: "11 May 2021 12:36 UTC" -> Date
     Returns Date object on success or nil if failed to parse date string
     */
    private func processUpdateDate(_ dateString: String) -> Date? {
        let possibleDateFormats = ["d MMM yyyy HH:mm Z", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZ"]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for dateFormat in possibleDateFormats {
            dateFormatter.dateFormat = dateFormat
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    /**
     Checks if file's content is valid
     Returns true if first 256 chars of content are empty or contain some HTML's tags
     Returns false if content is correct
     */
    private func isInvalid(content: String) -> Bool {
        let nsContent = content as NSString
        var contentBeginsWith = nsContent.substring(to: nsContent.length > 256 ? 256 : nsContent.length)
        contentBeginsWith = contentBeginsWith.lowercased()
        contentBeginsWith = contentBeginsWith.trimmingCharacters(in: .whitespacesAndNewlines)

        return contentBeginsWith.isEmpty
            || contentBeginsWith.contains("<!doctype")
            || contentBeginsWith.contains("<html")
            || contentBeginsWith.contains("<head")
    }
}

// MARK: - CustomFilterMetaParserProtocol + getMetaFromUrl

public extension CustomFilterMetaParserProtocol {
    /**
     Gets filter's file content from url, parses it  and converts content to FilterMetadata object.
     ~~~
     Filter example: https://easylist.to/easylist/easylist.txt
     ~~~

     - Parameter url: File's location url
     - Parameter parserType: Parsing can differ for **system** and **safary** filters
     - Throws: Throws an error if parsing or reading file fails
     - Returns: FilterMetadata object
     */
    func getMetaFrom(url: URL, for parserType: CustomFilterMetaParserType) throws -> ExtendedCustomFilterMetaProtocol {
        let filterContent = try String(contentsOf: url)
        return try parse(filterContent, for: parserType, filterDownloadPage: url.absoluteString)
    }
}


// MARK: - FilterMetadataParser

public struct CustomFilterMetaParser: CustomFilterMetaParserProtocol {
    public init() {}
}
