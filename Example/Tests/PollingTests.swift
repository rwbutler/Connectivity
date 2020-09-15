//
//  PollingTests.swift
//  Connectivity
//
//  Created by Ross Butler on 15/09/2020.
//  Copyright © 2020 Ross Butler. All rights reserved.
//

@testable import Connectivity
import OHHTTPStubs
import UIKit
import XCTest

class PollingTests: XCTestCase {
    private let timeout: TimeInterval = 5.0

    func testConnectivityDetectedWhenPolling() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = true
        connectivity.pollingInterval = 0.1
        connectivity.framework = .systemConfiguration
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [connectedNotificationExpectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testConnectivityNotDetectedWhenNotPolling() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = false
        connectivity.pollingInterval = 0.1
        connectivity.framework = .systemConfiguration
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        connectedNotificationExpectation.isInverted = true
        wait(for: [connectedNotificationExpectation], timeout: timeout / 2)
        connectivity.stopNotifier()
    }

    func testConnectivityDetectedWhenPollingOfflineOnlyAndConnectionOffline() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = true
        connectivity.pollWhileOfflineOnly = true
        connectivity.pollingInterval = 0.1
        connectivity.framework = .systemConfiguration
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [connectedNotificationExpectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testConnectivityNotDetectedWhenPollingOfflineOnlyAndConnectionOnline() {
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = true
        connectivity.pollWhileOfflineOnly = true
        connectivity.pollingInterval = 0.1
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

    func testConnectivityDetectedWhenPollingUsingNetwork() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = true
        connectivity.pollingInterval = 0.1
        connectivity.framework = .network
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [connectedNotificationExpectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testConnectivityNotDetectedWhenNotPollingUsingNetwork() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = false
        connectivity.pollingInterval = 0.1
        connectivity.framework = .network
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        connectedNotificationExpectation.isInverted = true
        wait(for: [connectedNotificationExpectation], timeout: timeout / 2)
        connectivity.stopNotifier()
    }

    func testConnectivityDetectedWhenPollingOfflineOnlyAndConnectionOfflineUsingNetwork() {
        stubHost("captive.apple.com", withHTMLFrom: "failure-response.html")
        stubHost("www.apple.com", withHTMLFrom: "failure-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = true
        connectivity.pollWhileOfflineOnly = true
        connectivity.pollingInterval = 0.1
        connectivity.framework = .network
        connectivity.startNotifier()

        // First notification will be posted on invocation of `startNotifier`.
        let disconnectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [disconnectedNotificationExpectation], timeout: timeout)

        // In order for another notification to be posted the connectivity status will need to change.
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")

        // Posting `UIApplication.didBecomeActiveNotification` will trigger another check.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        let connectedNotificationExpectation = expectation(
            forNotification: Notification.Name.ConnectivityDidChange,
            object: connectivity,
            handler: nil
        )
        wait(for: [connectedNotificationExpectation], timeout: timeout)
        connectivity.stopNotifier()
    }

    func testConnectivityNotDetectedWhenPollingOfflineOnlyAndConnectionOnlineUsingNetwork() {
        stubHost("www.apple.com", withHTMLFrom: "success-response.html")
        let connectivity = Connectivity()
        connectivity.checkWhenApplicationDidBecomeActive = false
        connectivity.isPollingEnabled = true
        connectivity.pollWhileOfflineOnly = true
        connectivity.pollingInterval = 0.1
        connectivity.framework = .network
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
