//
//  ConnectivityResponseStringEqualityValidator.swift
//  Connectivity
//
//  Created by Ross Butler on 25/10/2019.
//

import Foundation

@objcMembers
public class ConnectivityResponseStringEqualityValidator: ConnectivityResponseValidator {
    /// The `String` expected as the response
    public let expectedResponse: String

    /// Initializes the receiver to validate that the response `String` is equal to the expected response.
    ///
    /// - Parameter expectedResponse: The `String` expected as the response.
    public init(expectedResponse: String) {
        self.expectedResponse = expectedResponse
    }

    public func isResponseValid(url _: URL, response _: URLResponse?, data: Data?) -> Bool {
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            return false
        }
        return expectedResponse == responseString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
