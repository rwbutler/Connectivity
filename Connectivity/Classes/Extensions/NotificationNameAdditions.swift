//
//  NotificationNameAdditions.swift
//  Connectivity
//
//  Created by Ross Butler on 12/9/18.
//

import Foundation

extension Notification.Name {
    public static let ReachabilityDidChange = Notification.Name("kNetworkReachabilityChangedNotification")
    public static let ConnectivityDidChange = Notification.Name("kNetworkConnectivityChangedNotification")
}
