//
//  ConnectivityResponseValidationMode.swift
//  Connectivity
//
//  Created by Ross Butler on 1/20/19.
//

import Foundation

@objc
public enum ConnectivityResponseValidationMode: Int {
    case containsExpectedResponseString,
         equalsExpectedResponseString,
         matchesRegularExpression,
         custom
}
