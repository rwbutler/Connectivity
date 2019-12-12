//
//  ConnectivityResponseContainsStringValidator.swift
//  Connectivity
//
//  Created by Ross Butler on 26/10/2019.
//

import Foundation

@objcMembers
public class ConnectivityResponseContainsStringValidator: ConnectivityResponseValidator {
    /// The `String` expected to be contained in the response
    public let expectedResponse: String

    /// Initializes the receiver to validate that the response `String` contains the expected response.
    ///
    /// - Parameter expectedResponse: The `String` expected to be contained in the response.
    public init(expectedResponse: String = "Success") {
        self.expectedResponse = expectedResponse
    }

    public func isResponseValid(url _: URL, response _: URLResponse?, data: Data?) -> Bool {
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            return false
        }
        return responseString.contains(expectedResponse)
    }
}
