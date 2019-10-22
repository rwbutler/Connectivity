//
//  ConnectivityResponseStringValidator.swift
//  Connectivity
//
//  Created by Ross Butler on 1/19/19.
//

import Foundation

@objc
public enum ConnectivityResponseStringValidationMode: Int {
    case containsExpectedResponseString,
    equalsExpectedResponseString,
    matchesRegularExpression
}

public class ConnectivityResponseStringValidator: ConnectivityResponseValidator {

    public typealias ValidationMode = ConnectivityResponseStringValidationMode

    /// The method used to validate the response from the connectivity endpoints.
    public let responseValidationMode: ValidationMode

    /// The `String` expected in the response, which is tested based on the validationMode
    public let expected: String

    /// Initializes the receiver to validate response `String`s
    /// using the given validation mode
    ///
    /// - Parameter validationMode: The mode to use for validating the
    ///                             response `String`
    /// - Parameter expected: The `String` expected in the response, which is
    ///                       tested based on the validationMode
    public init(validationMode: ValidationMode, expected: String) {
        self.responseValidationMode = validationMode
        self.expected = expected
    }

    public func isResponseValid(url: URL, response: URLResponse?, data: Data?) -> Bool {
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            return false
        }
        switch responseValidationMode {
        case .containsExpectedResponseString:
            return responseString.contains(expected)
        case .equalsExpectedResponseString:
            return expected == responseString
        case .matchesRegularExpression:
            let responseStrRange = NSRange(location: 0, length: responseString.count)
            let options: NSRegularExpression.Options =
                [.caseInsensitive, .allowCommentsAndWhitespace, .dotMatchesLineSeparators]
            guard let regEx = try? NSRegularExpression(pattern: expected, options: options) else {
                return false
            }
            let matches = regEx.matches(in: responseString, options: [], range: responseStrRange)
            return !matches.isEmpty
        }
    }
}
