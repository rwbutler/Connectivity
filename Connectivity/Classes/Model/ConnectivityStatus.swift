//
//  ConnectivityStatus.swift
//  Connectivity
//
//  Created by Ross Butler on 12/9/18.
//

import Foundation

@objc public enum ConnectivityStatus: Int, CustomStringConvertible {
    case connected, // where a connection is present but the interface cannot be determined.
        connectedViaCellular,
        connectedViaCellularWithoutInternet,
        connectedViaWiFi,
        connectedViaWiFiWithoutInternet,
        determining,
        notConnected

    public var description: String {
        switch self {
        case .connected:
            return "Internet access"
        case .connectedViaCellular:
            return "Cellular with Internet access"
        case .connectedViaCellularWithoutInternet:
            return "Cellular without Internet access"
        case .connectedViaWiFi:
            return "Wi-Fi with Internet access"
        case .connectedViaWiFiWithoutInternet:
            return "Wi-Fi without Internet access"
        case .determining:
            return "Connectivity checks pending"
        case .notConnected:
            return "No Connection"
        }
    }
}
