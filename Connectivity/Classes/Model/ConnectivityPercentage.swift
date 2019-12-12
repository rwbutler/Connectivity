//
//  ConnectivityPercentage.swift
//  Connectivity
//
//  Created by Ross Butler on 12/9/18.
//

import Foundation

public struct ConnectivityPercentage: Comparable {
    let value: Double

    public init(_ value: Double) {
        var result = value < 0.0 ? 0.0 : value
        result = value > 100.0 ? 100.0 : value
        self.value = result
    }

    public static func < (lhs: ConnectivityPercentage, rhs: ConnectivityPercentage) -> Bool {
        return lhs.value < rhs.value
    }
}
