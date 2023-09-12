//
//  ConnectivityConfigurationTests.swift
//  Connectivity
//
//  Created by Ross Butler on 14/05/2022.
//  Copyright © 2022 Ross Butler. All rights reserved.
//

@testable import Connectivity
import Foundation
import XCTest

class ConfigurationTests: XCTestCase {
    // MARK: Default Values
    func testDefaultCallbackQueueIsMain() {
        let sut = Configuration()
        XCTAssertEqual(sut.callbackQueue, DispatchQueue.main)
    }
    
    /// QOS is actually set to `default` which is above `background` and `utility`. At the time if writing the `default` value results in `unspecified` being set.
    func testDefaultConnectivityCheckingQueueHasQOSOfUnspecified() {
        let sut = Configuration()
        XCTAssertEqual(sut.connectivityQueue.qos, DispatchQoS.unspecified)
    }
    
    func testDefaultConnectivityURLsAreCorrect() {
        let sut = Configuration()
        XCTAssertEqual(sut.connectivityURLRequests.count, 2)
        guard sut.connectivityURLRequests.count == 2 else {
            return
        }
        XCTAssertEqual(
            sut.connectivityURLRequests[0].url,
            URL(string: "https://www.apple.com/library/test/success.html")
        )
        XCTAssertEqual(
            sut.connectivityURLRequests[1].url,
            URL(string: "https://captive.apple.com/hotspot-detect.html")
        )
    }
    
    func testConfiguringConnectivityURLs() throws {
        let appleURL = try XCTUnwrap(URL(string: "https://www.apple.com"))
        let googleURL = try XCTUnwrap(URL(string: "https://www.google.com"))
        let configuration = Configuration()
            .configureConnectivity(urls: [appleURL, googleURL])
        XCTAssertEqual(configuration.connectivityURLRequests[0].url, appleURL)
        XCTAssertEqual(configuration.connectivityURLRequests[1].url, googleURL)
    }
    
    func testConfiguringConnectivityURLRequests() throws {
        let appleURL = try XCTUnwrap(URL(string: "https://www.apple.com"))
        let appleURLRequest = URLRequest(url: appleURL)
        let googleURL = try XCTUnwrap(URL(string: "https://www.google.com"))
        let googleURLRequest = URLRequest(url: googleURL)
        let configuration = Configuration()
            .configureConnectivity(urlRequests: [appleURLRequest, googleURLRequest])
        XCTAssertEqual(configuration.connectivityURLRequests[0], appleURLRequest)
        XCTAssertEqual(configuration.connectivityURLRequests[1], googleURLRequest)
    }
    
    func testDefaultFrameworkIsNetwork() {
        let sut = Configuration()
        XCTAssertEqual(sut.framework, .network)
    }
    
    func testDefaultPollingIntervalIsSetTo10() {
        let sut = Configuration()
        XCTAssertEqual(sut.pollingInterval, 10.0)
    }
    
    func testPollingIsEnabledByDefault() {
        let sut = Configuration()
        XCTAssertTrue(sut.pollingIsEnabled)
    }
    
    func testDefaultPollingIsWhileOfflineOnly() {
        let sut = Configuration()
        XCTAssertTrue(sut.pollWhileOfflineOnly)
    }
    
    func testDefaultResponseValidatorIsResponseStringValidator() {
        let sut = Configuration()
        XCTAssertTrue(sut.responseValidator is ResponseStringValidator)
    }
    
    func testDefaultValidationModeIsContainsExpectedString() throws {
        let sut = Configuration()
        let responseStringValidator = try XCTUnwrap(sut.responseValidator as? ResponseStringValidator)
        XCTAssertEqual(responseStringValidator.responseValidationMode, .containsExpectedResponseString)
    }
    
    func testDefaultSuccessThresholdIs50Percent() {
        let sut = Configuration()
        XCTAssertEqual(sut.successThreshold, Connectivity.Percentage(50.0))
    }
    
    func testDefaultURLSessionConfigurationIgnoresCacheData() {
        let sut = Configuration()
        XCTAssertEqual(sut.urlSessionConfiguration.requestCachePolicy, .reloadIgnoringCacheData)
    }
    
    func testDefaultURLSessionConfigurationURLCacheIsNil() {
        let sut = Configuration()
        XCTAssertNil(sut.urlSessionConfiguration.urlCache)
    }
    
    func testDefaultURLSessionConfigurationRequestTimeoutIs5() {
        let sut = Configuration()
        XCTAssertEqual(sut.urlSessionConfiguration.timeoutIntervalForRequest, 5.0)
    }
    
    func testDefaultURLSessionConfigurationResourceTimeoutIs5() {
        let sut = Configuration()
        XCTAssertEqual(sut.urlSessionConfiguration.timeoutIntervalForResource, 5.0)
    }
    
    func testDefaultURLSessionConfigurationDefaultIsACopy() {
        let sut = Configuration()
        XCTAssertFalse(sut.urlSessionConfiguration === URLSessionConfiguration.default)
    }
    
    func testDefaultURLSessionConfigurationDefaultIsNotModified() {
        let sut = Configuration()
        XCTAssertNotEqual(sut.urlSessionConfiguration.requestCachePolicy, URLSessionConfiguration.default.requestCachePolicy)
    }
    
    func testWhenPollingConfiguredPollingIsEnabledByDefault() {
        let sut = Configuration().configurePolling()
        XCTAssertTrue(sut.pollingIsEnabled)
    }
    
    func testWhenPollingConfiguredDefaultIntervalIsTen() {
        let sut = Configuration().configurePolling()
        XCTAssertEqual(sut.pollingInterval, 10.0)
    }
    
    func testWhenPollingConfiguredDefaultIsToOnlyPollWhileOffline() {
        let sut = Configuration().configurePolling()
        XCTAssertTrue(sut.pollWhileOfflineOnly)
    }
    
    func testConfigurePollingSetsPollingInterval() {
        let sut = Configuration().configurePolling(interval: 88)
        XCTAssertEqual(sut.pollingInterval, 88)
    }
    
    func testConfigurePollingSetsPollingEnabled() {
        let sut = Configuration().configurePolling(isEnabled: true)
        XCTAssertTrue(sut.pollingIsEnabled)
    }
    
    func testConfigurePollingSetsPollingDisabled() {
        let sut = Configuration().configurePolling(isEnabled: false)
        XCTAssertFalse(sut.pollingIsEnabled)
    }
    
    func testConfigurePollingSetsPollingWhenOfflineOnlyEnabled() {
        let sut = Configuration().configurePolling(offlineOnly: true)
        XCTAssertTrue(sut.pollWhileOfflineOnly)
    }
    
    func testConfigurePollingSetsPollingWhenOfflineOnlyDisabled() {
        let sut = Configuration().configurePolling(offlineOnly: false)
        XCTAssertFalse(sut.pollWhileOfflineOnly)
    }

    func testConfigureResponseValidationSetsResponseValidator() {
        let sut = Configuration().configureResponseValidation(.matchesRegularExpression, expected: "regex")
        XCTAssertTrue(sut.responseValidator is ResponseStringValidator)
        guard let responseValidator = sut.responseValidator as? ResponseStringValidator else {
            return
        }
        XCTAssertEqual(responseValidator.responseValidationMode, .matchesRegularExpression)
        XCTAssertEqual(responseValidator.expectedResponse, "regex")
    }
    
    func testConfigureResponseValidatorSetsResponseValidator() {
        let responseValidator = MockResponseValidator()
        let sut = Configuration().configureResponseValidator(responseValidator)
        XCTAssertTrue(sut.responseValidator is MockResponseValidator)
    }
    
    private func testConfigureURLSessionSetsURLSessionConfiguration() {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForRequest = 77
        let sut = Configuration().configureURLSession(urlSessionConfiguration)
        XCTAssertEqual(sut.urlSessionConfiguration.timeoutIntervalForRequest, 77)
    }
}
