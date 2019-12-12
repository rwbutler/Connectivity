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
    func testRegexStringValidation() {
        checkValid(string: "test1234", matchedBy: "test[0-9]+", expectedResult: true)
        checkValid(string: "testa1234", matchedBy: "test[0-9]+", expectedResult: false)
    }

    private func checkValid(
        string: String,
        matchedBy regEx: String,
        expectedResult: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let validator = ConnectivityResponseRegExValidator(regEx: regEx)
        let result = validator.isResponseValid(
            url: URL(string: "https://example.com")!,
            response: nil,
            data: string.data(using: .utf8)
        )
        let expectedResultStr = expectedResult ? "match" : "not match"
        let message = "Expected \"\(string)\" to \(expectedResultStr) \(regEx) via regex"
        XCTAssertEqual(result, expectedResult, message, file: file, line: line)
    }
}
