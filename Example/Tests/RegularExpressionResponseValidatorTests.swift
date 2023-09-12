//
//  ConnectivityResponseRegExValidatorTests.swift
//  Connectivity_Example
//
//  Created by Ross Butler on 10/24/19.
//  Copyright © 2019 Ross Butler. All rights reserved.
//

@testable import Connectivity
import Foundation
import XCTest

class RegularExpressionResponseValidatorTests: XCTestCase {
    func testRegexStringValidation() throws {
        try checkValid(string: "test1234", matchedBy: "test[0-9]+", expectedResult: true)
        try checkValid(string: "testa1234", matchedBy: "test[0-9]+", expectedResult: false)
    }

    private func checkValid(
        string: String,
        matchedBy regEx: String,
        expectedResult: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let data = string.data(using: .utf8)
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let urlRequest = URLRequest(url: url)
        let validator = ConnectivityResponseRegExValidator(regEx: regEx)
        let result = validator.isResponseValid(urlRequest: urlRequest, response: nil, data: data)
        let expectedResultStr = expectedResult ? "match" : "not match"
        let message = "Expected \"\(string)\" to \(expectedResultStr) \(regEx) via regex"
        XCTAssertEqual(result, expectedResult, message, file: file, line: line)
    }

    func testResponseInvalidWhenDataIsNil() throws {
        let regEx = "test[0-9]+"
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let urlRequest = URLRequest(url: url)
        let validator = ConnectivityResponseRegExValidator(regEx: regEx)
        let responseValid = validator.isResponseValid(urlRequest: urlRequest, response: nil, data: nil)
        XCTAssertFalse(responseValid)
    }
}
