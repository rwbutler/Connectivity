//
//  ResponseValidatorFactory.swift
//  Connectivity
//
//  Created by Ross Butler on 25/10/2019.
//

import Foundation

struct ResponseValidatorFactory: Factory {
    typealias ValidationMode = ConnectivityResponseValidationMode
    typealias Validator = ConnectivityResponseValidator

    /// A custom validator if the user has supplied one
    private let customValidator: Validator

    /// String used to match against the response to determine whether or not it is valid.
    private let expectedResponse: String

    /// Regular expression used to determine whether or not the response is valid.
    private let regularExpression: String

    /// Determines the means of validating the response.
    private let validationMode: ValidationMode

    init(
        validationMode: ValidationMode,
        expectedResponse: String,
        regEx: String,
        customValidator: Validator
    ) {
        self.customValidator = customValidator
        self.expectedResponse = expectedResponse
        self.regularExpression = regEx
        self.validationMode = validationMode
    }

    /// Returns the appropriate validator for the given validation mode.
    func manufacture() -> Validator {
        let validator: Validator
        switch validationMode {
        case .equalsExpectedResponseString:
            validator = ConnectivityResponseStringEqualityValidator(
                expectedResponse: expectedResponse
            )
        case .containsExpectedResponseString:
            validator = ConnectivityResponseContainsStringValidator(
                expectedResponse: expectedResponse
            )
        case .matchesRegularExpression:
            validator = ConnectivityResponseRegExValidator(
                regEx: regularExpression
            )
        case .custom:
            validator = customValidator
        }
        return validator
    }
}
