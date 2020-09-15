//
//  BackgroundingTests.swift
//  Connectivity
//
//  Created by Ross Butler on 15/09/2020.
//  Copyright © 2020 Ross Butler. All rights reserved.
//

@testable import Connectivity
import OHHTTPStubs
import UIKit
import XCTest

class BackgroundingTests: XCTestCase {
    private let timeout: TimeInterval = 5.0

    func testConnectivityCheckOnApplicationDidBecomeActive() {
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = true
        connectivity.framework = .systemConfiguration
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [connectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testConnectivityDoesNotCheckOnApplicationDidBecomeActive() {
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.framework = .systemConfiguration
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [connectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        disconnectedNotificationExpectation.isInverted = true
        wait(for: [disconnectedNotificationExpectation], timeout: timeout / 2)
        connectivity.stopNotifier()
    }
}
