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

import SQLite
import SharedAdGuardSDK

/* FilterGroupsTable; filter_groups table */
struct FilterGroupsTable: Equatable {
    // Properties from table
    let groupId: Int
    let name: String
    let displayNumber: Int
    let isEnabled: Bool

    // Table name
    static let table = Table("filter_groups")

    // Columns names
    static let groupId = Expression<Int>("group_id")
    static let name = Expression<String>("name")
    static let displayNumber = Expression<Int>("display_number")
    static let isEnabled = Expression<Bool>("is_enabled")

    // Localized initializer
    init(dbGroup: Row, localizedName: String) {
        self.groupId = dbGroup[FilterGroupsTable.groupId]
        self.name = localizedName
        self.displayNumber = dbGroup[FilterGroupsTable.displayNumber]
        self.isEnabled = dbGroup[FilterGroupsTable.isEnabled]
    }

    // Initializer from DB result
    init(dbGroup: Row) {
        self.groupId = dbGroup[FilterGroupsTable.groupId]
        self.name = dbGroup[FilterGroupsTable.name]
        self.displayNumber = dbGroup[FilterGroupsTable.displayNumber]
        self.isEnabled = dbGroup[FilterGroupsTable.isEnabled]
    }

    // Default initializer
    init(groupId: Int, name: String, displayNumber: Int, isEnabled: Bool) {
        self.groupId = groupId
        self.name = name
        self.displayNumber = displayNumber
        self.isEnabled = isEnabled
    }
}

// MARK: - MetaStorage + Groups
protocol GroupsMetaStorageProtocol {
    func getAllLocalizedGroups(forSuitableLanguages suitableLanguages: [String]) throws -> [FilterGroupsTable]
    func setGroup(withId id: Int, enabled: Bool) throws
    func update(group: GroupMetaProtocol) throws
    func update(groups: [GroupMetaProtocol]) throws
    func add(groups: [GroupMetaProtocol]) throws
}

private let LOG = ComLog_LoggerFactory.getLoggerWrapper(MetaStorage.self)

extension MetaStorage: GroupsMetaStorageProtocol {

    // Returns all groups with localization for specified language from database
    func getAllLocalizedGroups(forSuitableLanguages suitableLanguages: [String]) throws -> [FilterGroupsTable] {
        let lang = try collectGroupsMetaLocalizationLanguage(from: suitableLanguages)
        // Query: SELECT * FROM filter_groups ORDER BY display_number, group_id
        let query = FilterGroupsTable.table.order(FilterGroupsTable.displayNumber, FilterGroupsTable.groupId)

        let result: [FilterGroupsTable] = try filtersDb.prepare(query).compactMap { group in
            let dbGroup = FilterGroupsTable(dbGroup: group)

            /* If there is no localized group name we trying to get default english localization and if it is steel nil set default localized name from filter_group row */
            var localizedName = getLocalizationForGroup(withId: dbGroup.groupId, forLanguage: lang)?.name
            if localizedName == nil && lang != MetaStorage.defaultDbLanguage  {
                localizedName = getLocalizationForGroup(withId: dbGroup.groupId, forLanguage: lang)?.name
            }

            return FilterGroupsTable(dbGroup: group, localizedName: localizedName ?? dbGroup.name)
        }
        LOG.debug("GetAllLocalizedGroups returning \(result.count) groups objects for lang=\(lang)")
        return result
    }

    // Enables or disables a group with specified id
    func setGroup(withId id: Int, enabled: Bool) throws {
        // Query: UPDATE filter_groups SET is_enabled = enabled WHERE group_id = id
        let query = FilterGroupsTable.table.filter(FilterGroupsTable.groupId == id)
        try filtersDb.run(query.update(FilterGroupsTable.isEnabled <- enabled))
        LOG.debug("SetGroup group with id=\(id) was set to enabled=\(enabled)")
    }

    // Updates group metadata with passed one
    func update(group: GroupMetaProtocol) throws {
        // Query: UPDATE filter_groups SET name = group.groupName, display_number = group.displayNumber) WHERE group_id = group.groupId
        let query = FilterGroupsTable.table
                                     .where(FilterGroupsTable.groupId == group.groupId)
                                     .update(FilterGroupsTable.name <- group.groupName, FilterGroupsTable.displayNumber <- group.displayNumber)
        try filtersDb.run(query)
        LOG.debug("Update group with id=\(group.groupId)")
    }

    // Updates passed groups meta
    func update(groups: [GroupMetaProtocol]) throws {
        try groups.forEach { try update(group: $0) }
    }

    // TODO: - Needs tests
    /// Adds group to DB
    /// This methods should be used only in `Builder`
    func add(groups: [GroupMetaProtocol]) throws {
        try groups.forEach {
            let query = FilterGroupsTable.table.insert(or: .replace, [
                FilterGroupsTable.groupId <- $0.groupId,
                FilterGroupsTable.name <- $0.groupName,
                FilterGroupsTable.displayNumber <- $0.displayNumber,
                FilterGroupsTable.isEnabled <- false
            ])
            try filtersDb.run(query)
        }
    }
}
