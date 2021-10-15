/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.

       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.

       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.

       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import SharedAdGuardSDK

public struct DnsFilter: ExtendedCustomFilterMetaProtocol, Codable, Equatable {
    public let filterId: Int
    public let subscriptionUrl: URL
    public var isEnabled: Bool
    public var name: String?
    public let description: String?
    public let version: String?
    public let lastUpdateDate: Date?
    public let updateFrequency: Int?
    public let homePage: String?
    public let licensePage: String?
    public let issuesReportPage: String?
    public let communityPage: String?
    public let filterDownloadPage: String?
    public let rulesCount: Int

    public init(filterId: Int, subscriptionUrl: URL, isEnabled: Bool, name: String?, description: String?, version: String?, lastUpdateDate: Date?, updateFrequency: Int?, homePage: String?, licensePage: String?, issuesReportPage: String?, communityPage: String?, filterDownloadPage: String?, rulesCount: Int) {
        self.filterId = filterId
        self.subscriptionUrl = subscriptionUrl
        self.isEnabled = isEnabled
        self.name = name
        self.description = description
        self.version = version
        self.lastUpdateDate = lastUpdateDate
        self.updateFrequency = updateFrequency
        self.homePage = homePage
        self.licensePage = licensePage
        self.issuesReportPage = issuesReportPage
        self.communityPage = communityPage
        self.filterDownloadPage = filterDownloadPage
        self.rulesCount = rulesCount
    }

    init(meta: ExtendedCustomFilterMetaProtocol?, name: String, filterId: Int, subscriptionUrl: URL, isEnabled: Bool) {
        self.filterId = filterId
        self.subscriptionUrl = subscriptionUrl
        self.isEnabled = isEnabled
        self.name = name
        self.description = meta?.description
        self.version = meta?.version
        self.lastUpdateDate = meta?.lastUpdateDate
        self.updateFrequency = meta?.updateFrequency
        self.homePage = meta?.homePage
        self.licensePage = meta?.licensePage
        self.issuesReportPage = meta?.issuesReportPage
        self.communityPage = meta?.communityPage
        self.filterDownloadPage = meta?.filterDownloadPage
        self.rulesCount = meta?.rulesCount ?? 0
    }
}
