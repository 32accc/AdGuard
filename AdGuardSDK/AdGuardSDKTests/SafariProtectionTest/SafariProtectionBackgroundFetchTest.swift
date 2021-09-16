import XCTest

class SafariProtectionBackgroundFetchTest: XCTestCase {
    var configuration: SafariConfigurationMock!
    var defaultConfiguration: SafariConfigurationMock!
    var userDefaults: UserDefaultsStorageMock!
    var filters: FiltersServiceMock!
    var converter: FiltersConverterServiceMock!
    var cbStorage: ContentBlockersInfoStorageMock!
    var cbService: ContentBlockerServiceMock!
    var safariManagers: SafariUserRulesManagersProviderMock!
    var dnsBackgroundFetchUpdater: DnsBackgroundFetchUpdaterMock!
    
    var safariProtection: SafariProtectionProtocol!
    
    override func setUp() {
        configuration = SafariConfigurationMock()
        defaultConfiguration = SafariConfigurationMock()
        userDefaults = UserDefaultsStorageMock()
        filters = FiltersServiceMock()
        converter = FiltersConverterServiceMock()
        cbStorage = ContentBlockersInfoStorageMock()
        cbService = ContentBlockerServiceMock()
        safariManagers = SafariUserRulesManagersProviderMock()
        dnsBackgroundFetchUpdater = DnsBackgroundFetchUpdaterMock()
        safariProtection = SafariProtection(configuration: configuration,
                                            defaultConfiguration: defaultConfiguration,
                                            userDefaults: userDefaults,
                                            filters: filters,
                                            converter: converter,
                                            cbStorage: cbStorage,
                                            cbService: cbService,
                                            safariManagers: safariManagers,
                                            userRulesClipper: UserRulesClipperMock(),
                                            dnsBackgroundFetchUpdater: dnsBackgroundFetchUpdater)
    }
    
    func testUpdateSafariProtectionInBackgroundExecutesInRightSequence() {
        let expectation = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 0)
        XCTAssertEqual(cbStorage.invokedSaveCount, 0)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        
        let expectation2 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        
        let expectation3 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        
        let expectation4 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 2)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 2)
    }
    
    func testUpdateSafariProtectionInBackgroundExecutesInRightSequenceWithErrors() {
        let expectation = XCTestExpectation()
        filters.updateAllMetaResult = .error(MetaStorageMockError.error)
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .noData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 0)
        XCTAssertEqual(cbStorage.invokedSaveCount, 0)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        
        let expectation2 = XCTestExpectation()
        filters.updateAllMetaResult = .success(FiltersUpdateResult())
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 2)
        XCTAssertEqual(converter.convertFiltersCalledCount, 0)
        XCTAssertEqual(cbStorage.invokedSaveCount, 0)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 2)
        
        let expectation3 = XCTestExpectation()
        cbStorage.stubbedSaveError = MetaStorageMockError.error
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .noData)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 2)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 2)
        
        let expectation4 = XCTestExpectation()
        cbStorage.stubbedSaveError = nil
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 2)
        XCTAssertEqual(converter.convertFiltersCalledCount, 2)
        XCTAssertEqual(cbStorage.invokedSaveCount, 2)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 2)
        
        let expectation5 = XCTestExpectation()
        cbService.updateContentBlockersError = MetaStorageMockError.error
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .noData)
            expectation5.fulfill()
        }
        wait(for: [expectation5], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 2)
        XCTAssertEqual(converter.convertFiltersCalledCount, 2)
        XCTAssertEqual(cbStorage.invokedSaveCount, 2)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 2)
        
        let expectation6 = XCTestExpectation()
        cbService.updateContentBlockersError = nil
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation6.fulfill()
        }
        wait(for: [expectation6], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 2)
        XCTAssertEqual(converter.convertFiltersCalledCount, 2)
        XCTAssertEqual(cbStorage.invokedSaveCount, 2)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 2)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 2)
        
        let expectation7 = XCTestExpectation()
        filters.updateAllMetaResult = .success(FiltersUpdateResult())
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation7.fulfill()
        }
        wait(for: [expectation7], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 3)
        XCTAssertEqual(converter.convertFiltersCalledCount, 2)
        XCTAssertEqual(cbStorage.invokedSaveCount, 2)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 2)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 3)
    }
    
    func testFinishBackgroundUpdateFromLoadAndSaveFiltersStateWithSuccess() {
        let expectation = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        filters.updateAllMetaCalledCount = 0
        
        let expectation2 = XCTestExpectation()
        safariProtection.finishBackgroundUpdate { error in
            XCTAssertNil(error)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        
        XCTAssertEqual(filters.updateAllMetaCalledCount, 0)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
    }
    
    func testFinishBackgroundUpdateFromConvertFiltersStateWithSuccess() {
        let expectation = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        let expectation2 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        filters.updateAllMetaCalledCount = 0
        converter.convertFiltersCalledCount = 0
        cbStorage.invokedSaveCount = 0
        
        let expectation3 = XCTestExpectation()
        safariProtection.finishBackgroundUpdate { error in
            XCTAssertNil(error)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 0.5)
        
        XCTAssertEqual(filters.updateAllMetaCalledCount, 0)
        XCTAssertEqual(converter.convertFiltersCalledCount, 0)
        XCTAssertEqual(cbStorage.invokedSaveCount, 0)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
    }
    
    func testFinishBackgroundUpdateFromConvertFiltersStateWithError() {
        let expectation = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        let expectation2 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        filters.updateAllMetaCalledCount = 0
        converter.convertFiltersCalledCount = 0
        cbStorage.invokedSaveCount = 0
        
        cbService.updateContentBlockersError = MetaStorageMockError.error
        let expectation3 = XCTestExpectation()
        safariProtection.finishBackgroundUpdate { error in
            XCTAssertEqual(error as! MetaStorageMockError, .error)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 0.5)
        
        XCTAssertEqual(filters.updateAllMetaCalledCount, 0)
        XCTAssertEqual(converter.convertFiltersCalledCount, 0)
        XCTAssertEqual(cbStorage.invokedSaveCount, 0)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
    }
    
    func testFinishBackgroundUpdateFromReloadContentBlockersState() {
        let expectation = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        
        let expectation2 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        
        let expectation3 = XCTestExpectation()
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .newData)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
        filters.updateAllMetaCalledCount = 0
        converter.convertFiltersCalledCount = 0
        cbStorage.invokedSaveCount = 0
        cbService.updateContentBlockersCalledCount = 0
        
        let expectation4 = XCTestExpectation()
        safariProtection.finishBackgroundUpdate { error in
            XCTAssertNil(error)
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 0)
        XCTAssertEqual(converter.convertFiltersCalledCount, 0)
        XCTAssertEqual(cbStorage.invokedSaveCount, 0)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 0)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
    }
    
    func testFinishBackgroundUpdateFromLoadAndSaveFiltersStateWithDnsFiltersUpdateError() {
        let expectation = XCTestExpectation()
        dnsBackgroundFetchUpdater.updateFiltersInBackgroundError = CommonError.error(message: "")
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .noData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        filters.updateAllMetaCalledCount = 0
        
        let expectation2 = XCTestExpectation()
        safariProtection.finishBackgroundUpdate { error in
            XCTAssertNil(error)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        
        XCTAssertEqual(filters.updateAllMetaCalledCount, 0)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
    }
    
    func testFinishBackgroundUpdateFromLoadAndSaveFiltersStateWithSafariAndDnsUpdateError() {
        let expectation = XCTestExpectation()
        filters.updateAllMetaResult = .error(MetaStorageMockError.error)
        safariProtection.updateSafariProtectionInBackground { fetchResult in
            XCTAssertEqual(fetchResult, .noData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        filters.updateAllMetaCalledCount = 0
        
        let expectation2 = XCTestExpectation()
        safariProtection.finishBackgroundUpdate { error in
            XCTAssertNil(error)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.5)
        
        XCTAssertEqual(filters.updateAllMetaCalledCount, 1)
        XCTAssertEqual(converter.convertFiltersCalledCount, 1)
        XCTAssertEqual(cbStorage.invokedSaveCount, 1)
        XCTAssertEqual(cbService.updateContentBlockersCalledCount, 1)
        XCTAssertEqual(dnsBackgroundFetchUpdater.updateFiltersInBackgroundCalledCount, 1)
    }
}
