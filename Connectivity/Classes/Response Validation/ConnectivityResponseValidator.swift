//
//  ConnectivityResponseValidator.swift
//  Connectivity
//
//  Created by Benjamin Asher on 10/12/19.
//

import Foundation

typealias ResponseValidator = ConnectivityResponseValidator // For internal use.

/// The contract for a response validator used to determine
/// connectivity based on a network response
@objc public protocol ConnectivityResponseValidator {
    /// Determines whether or not the response is valid
    /// and expected for a given `URL`
    ///
    /// - Parameter url: The `URL`, from which the response was fetched
    /// - Parameter response: The `URLResponse` returned by url
    /// - Parameter data: The data in the response returned by url
    func isResponseValid(url: URL, response: URLResponse?, data: Data?) -> Bool
}
