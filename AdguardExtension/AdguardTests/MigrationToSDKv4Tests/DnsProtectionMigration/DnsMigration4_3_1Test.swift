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

import XCTest
import SharedAdGuardSDK

class DnsMigration4_3_1Test: XCTestCase {
    private var dnsProtection: DnsProtectionMock!
    private var resources: SharedResourcesMock!
    private var dnsMigration: DnsMigration4_3_1Protocol!

    override func setUp() {
        resources = SharedResourcesMock()
        dnsProtection = DnsProtectionMock()
        dnsMigration = DnsMigration4_3_1(resources: resources, dnsProtection: dnsProtection)
    }

    func testMigration() {
        generateUserRules()
        dnsMigration.migrate()
        let expectedRules: [UserRule] = [
            UserRule(ruleText: "rule#1", isEnabled: true),
            UserRule(ruleText: "rule#2", isEnabled: false),
            UserRule(ruleText: "rule#3", isEnabled: false),
            UserRule(ruleText: "rule#4", isEnabled: false),
            UserRule(ruleText: "rule#5", isEnabled: true)
        ]
        XCTAssertEqual(dnsProtection.allRulesCalledCount, 2)
        XCTAssertEqual(dnsProtection.removeAllRulesCalledCount, 2)
        XCTAssertEqual(dnsProtection.addRulesCalledCount, 2)
        XCTAssertEqual(dnsProtection.addRulesParametersList.count, 2)
        dnsProtection.addRulesParametersList.forEach {
            XCTAssertEqual($0.rules, expectedRules)
        }
    }

    func testMigrationWithEmptyRules() {
        dnsMigration.migrate()
        XCTAssertEqual(dnsProtection.allRulesCalledCount, 2)
        XCTAssertEqual(dnsProtection.removeAllRulesCalledCount, 0)
        XCTAssertEqual(dnsProtection.addRulesCalledCount, 0)
        XCTAssertEqual(dnsProtection.addRulesParametersList.count, 0)
    }

    func testMigrationWithAddError() {
        dnsProtection.addRuleError = NSError(domain: "test_error", code: 1, userInfo: nil)
        dnsMigration.migrate()
        let expectedRules: [UserRule] = [
            UserRule(ruleText: "rule#1", isEnabled: true),
            UserRule(ruleText: "rule#2", isEnabled: false),
            UserRule(ruleText: "rule#3", isEnabled: false),
            UserRule(ruleText: "rule#4", isEnabled: false),
            UserRule(ruleText: "rule#5", isEnabled: true)
        ]
        XCTAssertEqual(dnsProtection.allRulesCalledCount, 2)
        XCTAssertEqual(dnsProtection.removeAllRulesCalledCount, 0)
        XCTAssertEqual(dnsProtection.addRulesCalledCount, 0)
        XCTAssertEqual(dnsProtection.addRulesParametersList.count, 0)
        dnsProtection.addRulesParametersList.forEach {
            XCTAssertEqual($0.rules, expectedRules)
        }
    }

    private func generateUserRules() {
        let rules: [UserRule] = [
            UserRule(ruleText: "rule#1", isEnabled: true),
            UserRule(ruleText: "rule#2\nrule#3\nrule#4", isEnabled: false),
            UserRule(ruleText: "rule#5", isEnabled: true),
        ]
        dnsProtection.allRulesResult = rules
    }
}
