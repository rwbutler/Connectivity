//
//  StringEqualityResponseValidatorTests.swift
//  Connectivity
//
//  Created by Ross Butler on 10/28/19.
//  Copyright © 2019 Ross Butler. All rights reserved.
//

@testable import Connectivity
import Foundation
import OHHTTPStubs
import XCTest

class StringEqualityResponseValidatorTests: XCTestCase {
    private let timeout: TimeInterval = 5.0

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    /// Test response is valid when the response string is equal to the expected response.
    func testEqualsExpectedResponseString() {
        stubHost("www.apple.com", withHTMLFrom: "string-equality-response.html")
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.responseValidator = ConnectivityResponseStringEqualityValidator(expectedResponse: "Success")
        connectivity.validationMode = .custom
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFi)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    /// Test response is invalid when the response string is not equal to the expected response.
    func testNotEqualsExpectedResponseString() {
        stubHost("www.apple.com", withHTMLFrom: "string-contains-response.html")
        let expectation = XCTestExpectation(description: "Connectivity check fails")
        let connectivity = Connectivity()
        connectivity.responseValidator = ConnectivityResponseStringEqualityValidator(expectedResponse: "Success")
        connectivity.validationMode = .custom
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFiWithoutInternet)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: timeout)
        connectivity.stopNotifier()
    }
}
