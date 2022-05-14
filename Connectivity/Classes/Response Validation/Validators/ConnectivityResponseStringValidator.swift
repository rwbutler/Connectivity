//
//  ConnectivityResponseStringValidator.swift
//  Connectivity
//
//  Created by Ross Butler on 19/01/2019.
//

import Foundation

@objc
public enum ConnectivityResponseStringValidationMode: Int {
    case containsExpectedResponseString,
         equalsExpectedResponseString,
         matchesRegularExpression
}

typealias ResponseStringValidator = ConnectivityResponseStringValidator // For internal use.

@objcMembers
public class ConnectivityResponseStringValidator: ConnectivityResponseValidator {
    public typealias ValidationMode = ConnectivityResponseStringValidationMode

    /// The method used to validate the response from the connectivity endpoints.
    public let responseValidationMode: ValidationMode

    /// The `String` expected in the response, which is tested based on the validationMode
    public let expectedResponse: String

    /// Initializes the receiver to validate response `String`s
    /// using the given validation mode
    ///
    /// - Parameter validationMode:   The mode to use for validating the response `String`.
    /// - Parameter expectedResponse: The `String` expected in the response, which is
    ///                               tested based on the validationMode
    public init(validationMode: ValidationMode, expectedResponse: String) {
        self.responseValidationMode = validationMode
        self.expectedResponse = expectedResponse
    }

    public func isResponseValid(url: URL, response: URLResponse?, data: Data?) -> Bool {
        let validator: ConnectivityResponseValidator
        switch responseValidationMode {
        case .containsExpectedResponseString:
            validator = ConnectivityResponseContainsStringValidator(
                expectedResponse: expectedResponse
            )
        case .equalsExpectedResponseString:
            validator = ConnectivityResponseStringEqualityValidator(
                expectedResponse: expectedResponse
            )
        case .matchesRegularExpression:
            validator = ConnectivityResponseRegExValidator(regEx: expectedResponse)
        }
        return validator.isResponseValid(url: url, response: response, data: data)
    }
}
