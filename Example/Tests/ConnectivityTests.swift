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

    func testContainsStringValidation() {
        checkValidation(
            string: "a test",
            matchedBy: "test",
            expectedResult: true,
            using: .containsExpectedResponseString
        )
        checkValidation(
            string: "est",
            matchedBy: "test",
            expectedResult: false,
            using: .containsExpectedResponseString
        )
    }

    func testEqualsStringValidation() {
        checkValidation(
            string: "test",
            matchedBy: "test",
            expectedResult: true,
            using: .equalsExpectedResponseString
        )
        checkValidation(
            string: "est",
            matchedBy: "test",
            expectedResult: false,
            using: .equalsExpectedResponseString
        )
    }

    func testRegexStringValidation() {
        checkValidation(
            string: "test1234",
            matchedBy: "test[0-9]+",
            expectedResult: true,
            using: .matchesRegularExpression
        )
        checkValidation(
            string: "testa1234",
            matchedBy: "test[0-9]+",
            expectedResult: false,
            using: .matchesRegularExpression
        )
    }

    func testCustomValidation() {
        // swiftlint:disable:next nesting
        final class Validator: ConnectivityResponseValidator {
            func isResponseValid(url: URL, response _: URLResponse?, data: Data?) -> Bool {
                let str = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                return url.host == "example.com" &&
                    str.hasPrefix("1") &&
                    str.hasSuffix("z")
            }
        }

        let validator = Validator()
        let example = URL(string: "https://example.com")!
        XCTAssertTrue(validator.isResponseValid(
            url: example,
            response: nil,
            data: "11234z".data(using: .utf8)
        ))
        XCTAssertFalse(validator.isResponseValid(
            url: URL(string: "https://apple.com")!,
            response: nil,
            data: "11234z".data(using: .utf8)
        ))
        XCTAssertFalse(validator.isResponseValid(
            url: example,
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
        let connectivityURLs: [URL] = [connectivityURL]
        let configuration = Configuration(connectivityURLs: connectivityURLs)
        let sut = Connectivity(configuration: configuration)
        XCTAssertEqual(sut.connectivityURLs.count, 1)
        guard let firstConnectivityURL = sut.connectivityURLs.first else {
            return
        }
        XCTAssertEqual(firstConnectivityURL, connectivityURL)
    }
    
    func testWhenConfigurationConnectivityURLIsNotHTTPSThenConnectivityURLIsNotSet() throws {
        let connectivityURL = try XCTUnwrap(URL(string: "http://www.microsoft.com"))
        let connectivityURLs: [URL] = [connectivityURL]
        let configuration = Configuration(connectivityURLs: connectivityURLs)
        let sut = Connectivity(configuration: configuration)
        XCTAssertTrue(sut.connectivityURLs.isEmpty)
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
    ) {
        let validator = ConnectivityResponseStringValidator(
            validationMode: mode,
            expectedResponse: matchStr
        )
        let result = validator.isResponseValid(
            url: URL(string: "https://example.com")!,
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
