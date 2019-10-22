import UIKit
import XCTest
import OHHTTPStubs
@testable import Connectivity

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }
    
    func testSuccessfulConnectivityCheckUsingSysConfig() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("success-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.framework = .systemConfiguration
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFi)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
    func testSuccessfulConnectivityCheckUsingNetwork() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("success-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.framework = .systemConfiguration
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFi)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
    func testFailedConnectivityCheckUsingSysConfig() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("failure-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity checks fails")
        let connectivity = Connectivity()
        connectivity.framework = .network
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFiWithoutInternet)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
    func testFailedConnectivityCheckUsingNetwork() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("failure-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity checks fails")
        let connectivity = Connectivity()
        connectivity.framework = .network
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFiWithoutInternet)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
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
        //swiftlint:disable:next nesting
        final class Validator: ConnectivityResponseValidator {
            func isResponseValid(url: URL, response: URLResponse?, data: Data?) -> Bool {
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
}

fileprivate extension XCTestCase {
    // Test helper for ConnectivityResponseStringTestValidator
    func checkValidation(
        string: String,
        matchedBy matchStr: String,
        expectedResult: Bool,
        using mode: ConnectivityResponseStringValidationMode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let validator = ConnectivityResponseStringTestValidator(
            validationMode: mode,
            expected: matchStr
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
