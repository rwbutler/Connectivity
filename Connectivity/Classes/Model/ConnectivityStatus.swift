//
//  ConnectivityStatus.swift
//  Connectivity
//
//  Created by Ross Butler on 12/9/18.
//

import Foundation

public enum ConnectivityStatus: CustomStringConvertible {
    case connected, // where a connection is present but the interface cannot be determined.
    connectedViaCellular,
    connectedViaCellularWithoutInternet,
    connectedViaWiFi,
    connectedViaWiFiWithoutInternet,
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
        case .notConnected:
            return "No Connection"
        }
    }
}
