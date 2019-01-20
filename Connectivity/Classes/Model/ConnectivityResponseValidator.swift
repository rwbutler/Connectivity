//
//  ConnectivityResponseValidation.swift
//  Connectivity
//
//  Created by Ross Butler on 1/19/19.
//

import Foundation

class ConnectivityResponseValidator {
    
    /// Determines the method used to validate the response from the connectivity endpoints.
    private let responseValidationMode: ConnectivityResponseValidationMode
    
    init(validationMode: ConnectivityResponseValidationMode) {
        self.responseValidationMode = validationMode
    }
    
    /// Determine whether the response is valid for the given mode.
    func isValid(expected: String, responseString: String) -> Bool {
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
