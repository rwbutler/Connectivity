@testable import Connectivity
import OHHTTPStubs
import UIKit
import XCTest

class ConnectivityTests: XCTestCase {
    private let timeout: TimeInterval = 5.0

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testSuccessfulConnectivityCheckUsingSysConfig() {
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.framework = .systemConfiguration
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssertEqual(connectivity.status, .connectedViaWiFi)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testSuccessfulConnectivityCheckUsingNetwork() {
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.framework = .network
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssertTrue(connectivity.isConnected)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testFailedConnectivityCheckUsingSysConfig() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let expectation = XCTestExpectation(description: "Connectivity checks fails")
        let connectivity = Connectivity()
        connectivity.framework = .systemConfiguration
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssertEqual(connectivity.status, .connectedViaWiFiWithoutInternet)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testFailedConnectivityCheckUsingNetwork() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let expectation = XCTestExpectation(description: "Connectivity checks fails")
        let connectivity = Connectivity()
        connectivity.framework = .network
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssertFalse(connectivity.isConnected)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testContainsStringValidation() throws {
        try checkValidation(
            string: "a test",
            matchedBy: "test",
            expectedResult: true,
            using: .containsExpectedResponseString
        )
        try checkValidation(
            string: "est",
            matchedBy: "test",
            expectedResult: false,
            using: .containsExpectedResponseString
        )
    }

    func testEqualsStringValidation() throws {
        try checkValidation(
            string: "test",
            matchedBy: "test",
            expectedResult: true,
            using: .equalsExpectedResponseString
        )
        try checkValidation(
            string: "est",
            matchedBy: "test",
            expectedResult: false,
            using: .equalsExpectedResponseString
        )
    }

    func testRegexStringValidation() throws {
        try checkValidation(
            string: "test1234",
            matchedBy: "test[0-9]+",
            expectedResult: true,
            using: .matchesRegularExpression
        )
        try checkValidation(
            string: "testa1234",
            matchedBy: "test[0-9]+",
            expectedResult: false,
            using: .matchesRegularExpression
        )
    }

    func testCustomValidation() throws {
        // swiftlint:disable:next nesting
        final class Validator: ConnectivityResponseValidator {
            func isResponseValid(urlRequest: URLRequest, response _: URLResponse?, data: Data?) -> Bool {
                let str = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                return urlRequest.url?.host == "example.com" &&
                    str.hasPrefix("1") &&
                    str.hasSuffix("z")
            }
        }

        let validator = Validator()
        let appleURL = try XCTUnwrap(URL(string: "https://apple.com"))
        let exampleURL = try XCTUnwrap(URL(string: "https://example.com"))
        XCTAssertTrue(validator.isResponseValid(
            urlRequest: URLRequest(url: exampleURL),
            response: nil,
            data: "11234z".data(using: .utf8)
        ))
        XCTAssertFalse(validator.isResponseValid(
            urlRequest: URLRequest(url: appleURL),
            response: nil,
            data: "11234z".data(using: .utf8)
        ))
        XCTAssertFalse(validator.isResponseValid(
            urlRequest: URLRequest(url: exampleURL),
            response: nil,
            data: "21234y".data(using: .utf8)
        ))
    }

    // MARK: - Fluent configuration API.
    
    func testWhenConfigurationCheckWhenApplicationDidBecomeActiveIsTrueThenConnectivityIsTrue() {
        let configuration = Configuration(checkWhenApplicationDidBecomeActive: true)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.checkWhenApplicationDidBecomeActive)
    }
    
    func testWhenConfigurationCheckWhenApplicationDidBecomeActiveIsFalseThenConnectivityIsFalse() {
        let configuration = Configuration(checkWhenApplicationDidBecomeActive: false)
        let sut = Connectivity(configuration: configuration)
        XCTAssertFalse(sut.checkWhenApplicationDidBecomeActive)
    }
    
    func testWhenConfigurationConnectivityURLsAreSetThenConnectivityURLsAreSetCorrectly() throws {
        let connectivityURL = try XCTUnwrap(URL(string: "https://www.microsoft.com"))
        let connectivityURLRequests: [URLRequest] = [connectivityURL].map {
            URLRequest(url: $0)
        }
        let configuration = Configuration(connectivityURLRequests: connectivityURLRequests)
        let sut = Connectivity(configuration: configuration)
        XCTAssertEqual(sut.connectivityURLRequests.count, 1)
        guard let firstConnectivityURLRequest = sut.connectivityURLRequests.first else {
            return
        }
        XCTAssertEqual(firstConnectivityURLRequest.url, connectivityURL)
    }
    
    func testWhenConfigurationConnectivityURLIsNotHTTPSThenConnectivityURLIsNotSet() throws {
        let connectivityURL = try XCTUnwrap(URL(string: "http://www.microsoft.com"))
        let connectivityURLRequests: [URLRequest] = [connectivityURL].map {
            URLRequest(url: $0)
        }
        let configuration = Configuration(connectivityURLRequests: connectivityURLRequests)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.connectivityURLRequests.isEmpty)
    }
    
    func testWhenConfigurationCallbackQueueIsSetThenConnectivityExternalQueueIsSetCorrectly() {
        let callbackQueue = DispatchQueue(label: "test-queue")
        let configuration = Configuration(callbackQueue: callbackQueue)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.externalQueue === callbackQueue)
    }
    
    func testWhenConfigurationConnectivityQueueIsSetThenConnectivityInternalQueueIsSetCorrectly() {
        let connectivityQueue = DispatchQueue(label: "test-queue")
        let configuration = Configuration(connectivityQueue: connectivityQueue)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.internalQueue === connectivityQueue)
    }
    
    func testWhenConfigurationPollingIsEnabledIsTrueThenConnectivityIsPollingEnabledIsTrue() {
        let configuration = Configuration(pollingIsEnabled: true)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.isPollingEnabled)
    }
    
    func testWhenConfigurationPollingIntervalIsSetThenConnectivityPollingIntervalIsSetCorrectly() {
        let configuration = Configuration(pollingInterval: 21)
        let sut = Connectivity(configuration: configuration)
        XCTAssertEqual(sut.pollingInterval, 21)
    }
    
    func testWhenConfigurationPollingIsEnabledIsFalseThenConnectivityIsPollingEnabledIsFalse() {
        let configuration = Configuration(pollingIsEnabled: false)
        let sut = Connectivity(configuration: configuration)
        XCTAssertFalse(sut.isPollingEnabled)
    }
    
    func testWhenConfigurationPollWhileOfflineOnlyIsTrueThenConnectivityPollWhileOfflineOnlyIsTrue() {
        let configuration = Configuration(pollWhileOfflineOnly: true)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.pollWhileOfflineOnly)
    }
    
    func testWhenConfigurationPollWhileOfflineOnlyIsFalseThenConnectivityPollWhileOfflineOnlyIsFalse() {
        let configuration = Configuration(pollWhileOfflineOnly: true)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.pollWhileOfflineOnly)
    }
    
    func testWhenConfigurationResponseValidatorIsSetThenConnectivityResponseValidatorIsSetCorrectly() {
        let responseValidator = MockResponseValidator()
        let configuration = Configuration(responseValidator: responseValidator)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.responseValidator === sut.responseValidator)
    }
    
    func testWhenConfigurationSuccessThresholdIs50PCThenConnectivityIs50PC() {
        let configuration = Configuration(successThreshold: Connectivity.Percentage(50))
        let sut = Connectivity(configuration: configuration)
        XCTAssertEqual(sut.successThreshold, Connectivity.Percentage(50))
    }
    
    func testWhenConfigurationURLSessionConfigIsSetThenConnectivityURLSessionConfigIsSetCorrectly() {
        let urlSessionConfiguration = URLSessionConfiguration.default
        let configuration = Configuration(urlSessionConfiguration: urlSessionConfiguration)
        let _ = Connectivity(configuration: configuration)
        XCTAssertTrue(Connectivity.urlSessionConfiguration === urlSessionConfiguration)
    }
}

extension XCTestCase {
    func stubHost(_ host: String, withHTMLFrom fileName: String) {
        stub(condition: isHost(host)) { _ in
            let stubPath = OHPathForFile(fileName, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
    }
}

private extension XCTestCase {
    // Test helper for ConnectivityResponseStringValidator
    func checkValidation(
        string: String,
        matchedBy matchStr: String,
        expectedResult: Bool,
        using mode: ConnectivityResponseStringValidationMode,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let validator = ConnectivityResponseStringValidator(
            validationMode: mode,
            expectedResponse: matchStr
        )
        let result = validator.isResponseValid(
            urlRequest: URLRequest(url: url),
            response: nil,
            data: string.data(using: .utf8)
        )
        let modeStr: String
        switch mode {
        case .containsExpectedResponseString: modeStr = "contains"
        case .equalsExpectedResponseString: modeStr = "equals"
        case .matchesRegularExpression: modeStr = "regexp"
        }
        let expectedResultStr = expectedResult ? "match" : "not match"
        XCTAssertEqual(
            result,
            expectedResult,
            "Expected \"\(string)\" to \(expectedResultStr) \(matchStr) via `\(modeStr)`",
            file: file,
            line: line
        )
    }
}
