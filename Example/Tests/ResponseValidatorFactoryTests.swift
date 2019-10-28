//
//  ResponseValidatorFactoryTests.swift
//  Connectivity_Tests
//
//  Created by Ross Butler on 25/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Connectivity

class ResponseValidatorFactoryTests: XCTestCase {

    /// Test correct validator is returned for validation mode `.equalsExpectedResponseString`.
    func testEqualsExpectedResponseString() {
        let responseValidator = ConnectivityResponseContainsStringValidator()
        let factory = ResponseValidatorFactory(
            validationMode: .equalsExpectedResponseString,
            expectedResponse: "expected",
            regEx: "",
            customValidator: responseValidator
        )
        let validator = factory.manufacture()
        XCTAssert(validator is ConnectivityResponseStringEqualityValidator)
    }
    
    /// Test correct validator is returned for validation mode `.containsExpectedResponseString`.
    func testContainsExpectedResponseString() {
        let responseValidator = ConnectivityResponseContainsStringValidator()
        let factory = ResponseValidatorFactory(
            validationMode: .containsExpectedResponseString,
            expectedResponse: "expected",
            regEx: "",
            customValidator: responseValidator
        )
        let validator = factory.manufacture()
        XCTAssert(validator is ConnectivityResponseContainsStringValidator)
    }
    
    /// Test correct validator is returned for validation mode `.matchesRegularExpression`.
    func testMatchesRegularExpression() {
        let responseValidator = ConnectivityResponseContainsStringValidator()
        let factory = ResponseValidatorFactory(
            validationMode: .matchesRegularExpression,
            expectedResponse: "expected",
            regEx: "",
            customValidator: responseValidator
        )
        let validator = factory.manufacture()
        XCTAssert(validator is ConnectivityResponseRegExValidator)
    }
    
    /// Test correct validator is returned for validation mode `.custom`.
    func testCustomValidatorReturnedForCustomValidationMode() {
        let responseValidator = ConnectivityResponseRegExValidator()
        let factory = ResponseValidatorFactory(
            validationMode: .custom,
            expectedResponse: "expected",
            regEx: "",
            customValidator: responseValidator
        )
        let validator = factory.manufacture()
        XCTAssert(validator === responseValidator)
    }
    
}
