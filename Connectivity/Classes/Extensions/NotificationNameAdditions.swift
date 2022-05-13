//
//  NotificationNameAdditions.swift
//  Connectivity
//
//  Created by Ross Butler on 12/9/18.
//

import Foundation

public extension Notification.Name {
    static let ReachabilityDidChange = Notification.Name("kNetworkReachabilityChangedNotification")
    static let ConnectivityDidChange = Notification.Name("kNetworkConnectivityChangedNotification")
}
