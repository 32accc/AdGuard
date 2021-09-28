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

import XCTest

class KeychainServiceTest: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testSave() {

        let keychain = KeychainService(resources: SharedResourcesMock())

        XCTAssert(keychain.saveAuth(server: "test.com", login: "login", password: "pass"))

        let auth = keychain.loadAuth(server: "test.com")

        XCTAssertNotNil(auth)
        XCTAssertEqual(auth!.login, "login")
        XCTAssertEqual(auth!.password, "pass")
    }

    func testDelete() {
        let keychain = KeychainService(resources: SharedResourcesMock())

        XCTAssert(keychain.saveAuth(server: "test.com", login: "login", password: "pass"))
        XCTAssert(keychain.deleteAuth(server: "test.com"))

        XCTAssertNil(keychain.loadAuth(server: "test.com"))
    }

    func testOverwrite() {
        let keychain = KeychainService(resources: SharedResourcesMock())

        XCTAssert(keychain.saveAuth(server: "test.com", login: "login", password: "pass"))
        XCTAssert(keychain.saveAuth(server: "test.com", login: "login2", password: "pass2"))

        let auth = keychain.loadAuth(server: "test.com")

        XCTAssertEqual(auth!.login, "login2")
        XCTAssertEqual(auth!.password, "pass2")
    }

    func testStoreId() {
        let keychain = KeychainService(resources: SharedResourcesMock())
        _ = keychain.deleteAppId()

        let appId = keychain.appId
        XCTAssertNotNil(appId)

        let appId2 = keychain.appId
        XCTAssertNotNil(appId2)

        XCTAssertEqual(appId, appId2)
    }

    func testDeleteId() {
        let keychain = KeychainService(resources: SharedResourcesMock())

        // delete app id from previous tests
        _ = keychain.deleteAppId()

        let appId = keychain.appId
        XCTAssertNotNil(appId)

        XCTAssert(keychain.deleteAppId())

        let appId2 = keychain.appId
        XCTAssertNotNil(appId2)

        XCTAssertNotEqual(appId, appId2)
    }

    func testSaveLicenseKey() {
        let keychain = KeychainService(resources: SharedResourcesMock())

        XCTAssert(keychain.saveLicenseKey(server: "test.server", key: "test key"))

        let key = keychain.loadLicenseKey(server: "test.server")

        XCTAssertNotNil(key)
        XCTAssertEqual(key, "test key")
    }

    func testDeleteLicenseKey() {
        let keychain = KeychainService(resources: SharedResourcesMock())

        XCTAssert(keychain.saveLicenseKey(server: "test.server", key: "test key"))

        XCTAssert(keychain.deleteLicenseKey(server: "test.server"))

        let key = keychain.loadLicenseKey(server: "test.server")

        XCTAssertNil(key)
    }

    func testStoreLicenseReadLogin() {
        let keychain = KeychainService(resources: SharedResourcesMock())

        XCTAssert(keychain.deleteAuth(server: "test.server"))
        XCTAssert(keychain.saveLicenseKey(server: "test.server", key: "test key"))

        let login = keychain.loadAuth(server: "test.server")

        XCTAssertNil(login)
    }
}
