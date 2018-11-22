//
//  Connectivity.swift
//  Connectivity
//
//  Created by Ross Butler on 7/12/17.
//  Copyright © 2017 - 2018 Ross Butler. All rights reserved.
//

extension Notification.Name {
    public static let ReachabilityDidChange = Notification.Name("kNetworkReachabilityChangedNotification")
    public static let ConnectivityDidChange = Notification.Name("kNetworkConnectivityChangedNotification")
}

public class Connectivity {

    // MARK: Type definitions
    public enum ConnectivityStatus: CustomStringConvertible {
        case notConnected,
        connectedViaWiFi,
        connectedViaWWAN,
        connectedViaWiFiWithoutInternet,
        connectedViaWWANWithoutInternet

        public var description: String {
            switch self {
            case .connectedViaWWAN:
                return "Cellular with Internet access"
            case .connectedViaWWANWithoutInternet:
                return "Cellular without Internet access"
            case .connectedViaWiFi:
                return "WiFi with Internet access"
            case .connectedViaWiFiWithoutInternet:
                return "WiFi without Internet access"
            case .notConnected:
                return "No Connection"
            }
        }
    }
    public typealias NetworkConnected = (Connectivity) -> Void
    public typealias NetworkDisconnected = (Connectivity) -> Void
    public struct Percentage: Comparable {
        let value: Double
        init(_ value: Double) {
            var result = value < 0.0 ? 0.0 : value
            result = value > 100.0 ? 100.0 : value
            self.value = result
        }

        public static func < (lhs: Connectivity.Percentage, rhs: Connectivity.Percentage) -> Bool {
            return lhs.value < rhs.value
        }
    }

    // MARK: State

    /// % successful connections required to be deemed to have connectivity
    public var successThreshold: Connectivity.Percentage = Connectivity.Percentage(75.0)

    /// URLs to contact in order to check connectivity
    public var connectivityURLs: [URL] = Connectivity
        .defaultConnectivityURLs(shouldUseHTTPS: Connectivity.isHTTPSOnly) {
        didSet {
            if Connectivity.isHTTPSOnly { // if HTTPS only set only allow HTTPS URLs
                connectivityURLs = connectivityURLs.filter({ url in
                    return url.absoluteString.lowercased().starts(with: "https")
                })
            }
        }
    }

    /// Response expected from connectivity URLs
    private let expectedResponse = "Success"

    /// Whether or not we are currently deemed to have connectivity
    public private(set) var isConnected: Bool = false

    /// Whether or not only HTTPS URLs should be used to check connectivity
    public static var isHTTPSOnly: Bool = true {
        didSet {
            // Only set true if `allow arbitrary loads` is set
            guard let bundleInfo = Bundle.main.infoDictionary,
                let appTransportSecurity = bundleInfo["NSAppTransportSecurity"] as? [String: Any],
                let allowsArbitraryLoads = appTransportSecurity["NSAllowsArbitraryLoads"] as? Bool,
                    allowsArbitraryLoads else {
                    isHTTPSOnly = true
                    return
            }
        }
    }

    /// Whether we are listening for changes in reachability (otherwise performing a one-off connectivity check)
    fileprivate var isObservingReachability = false

    /// Whether connectivity checks should be performed without waiting for reachability changes
    public var isPollingEnabled: Bool = false {
        didSet {
            if isObservingReachability, oldValue != isPollingEnabled {
                setPollingEnabled(isPollingEnabled)
            }
        }
    }

    /// Where polling is enabled, the interval at which connectivity checks will be performed.
    private var pollingInterval: Double = 10.0

    /// Status last time a check was performed
    private var previousStatus: ConnectivityStatus?

    /// Queue to callback on
    private var queue: DispatchQueue = DispatchQueue.main

    /// Reachability instance for checking network adapter status
    private let reachability: Reachability

    /// Status of the current connection
    public var status: ConnectivityStatus {
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        switch reachability.currentReachabilityStatus() {
        case ReachableViaWWAN:
            return (isConnected) ? .connectedViaWWAN : .connectedViaWWANWithoutInternet
        case ReachableViaWiFi:
            return (isConnected) ? .connectedViaWiFi : .connectedViaWiFiWithoutInternet
        default: // Needed as Obj-C Int-backed enum
            return .notConnected
        }
    }

    /// Timer for polling connectivity endpoints when not awaiting changes in reachability
    private var timer: Timer?

    /// URL session configuration ignoring cache
    public static var urlSessionConfiguration: URLSessionConfiguration = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .reloadIgnoringCacheData
        sessionConfiguration.timeoutIntervalForRequest = 5.0
        sessionConfiguration.timeoutIntervalForResource = 5.0
        return sessionConfiguration
    }()

    /// Callback to invoke when connected
    public var whenConnected: NetworkConnected?

    /// Callback to invoke when disconnected
    public var whenDisconnected: NetworkDisconnected?

    // MARK: Life cycle
    public init(shouldUseHTTPS: Bool = true) {
        type(of: self).isHTTPSOnly = shouldUseHTTPS
        reachability = Reachability.forInternetConnection()
    }

    deinit {
        stopNotifier()
    }
}

// Public API
public extension Connectivity {

    /// Textual representation of connectivity state
    var description: String {
        return "\(status)"
    }

    var isConnectedViaWWAN: Bool {
        return isConnected(with: ReachableViaWWAN)
    }

    var isConnectedViaWiFi: Bool {
        return isConnected(with: ReachableViaWiFi)
    }

    var isConnectedViaWWANWithoutInternet: Bool {
        return isDisconnected(with: ReachableViaWWAN)
    }

    var isConnectedViaWiFiWithoutInternet: Bool {
        return isDisconnected(with: ReachableViaWiFi)
    }

    /// Listen for changes in Reachability
    func startNotifier(queue: DispatchQueue = DispatchQueue.main) {
        if isObservingReachability { stopNotifier() } // Perform cleanup in event this method called twice
        self.queue = queue
        checkConnectivity()
        reachability.startNotifier()
        isObservingReachability = true
        setPollingEnabled(isPollingEnabled)
        NotificationCenter.default.addObserver(self,
                                       selector: #selector(reachabilityDidChange(_:)),
                                       name: NSNotification.Name.ReachabilityDidChange,
                                       object: nil)
    }

    /// Stop listening for Reachability changes
    func stopNotifier() {
        timer?.invalidate()
        if isObservingReachability { reachability.stopNotifier() }
        isObservingReachability = false
        NotificationCenter.default.removeObserver(self)
    }
}

// Private API
private extension Connectivity {

    /// Checks specified URLs for the expected response to determine whether Internet connectivity exists
    func checkConnectivity() {
        let dispatchGroup = DispatchGroup()
        var tasks: [URLSessionDataTask] = []
        let session: URLSession = urlSession()
        var successfulChecks: Int = 0, failedChecks: Int = 0
        let totalChecks: Int = connectivityURLs.count

        // Check whether enough tasks have successfully completed to be considered connected
        let exitEarly = { [weak self] in
            let isConnected = self?.isThresholdMet(successfulChecks, outOf: totalChecks) ?? false
            guard isConnected else { return }
            self?.cancelPendingTasks(tasks)
        }

        // Connectivity check callback
        let completionHandler: (Data?, URLResponse?, Error?) -> Void = {  [weak self] (data, _, _) in
            let connectivityCheckSuccess = self?.connectivityCheckSucceeded(data: data) ?? false
            connectivityCheckSuccess ? (successfulChecks += 1) : (failedChecks += 1)
            dispatchGroup.leave()
            exitEarly() // Abort early if enough tasks have completed successfully
        }

        // Check each of the specified URLs in turn
        tasks = connectivityURLs.map({ session.dataTask(with: $0, completionHandler: completionHandler) })
        tasks.forEach({ task in
            dispatchGroup.enter()
            task.resume()
        })

        dispatchGroup.notify(queue: queue) { [weak self] in
            self?.isConnected = self?.isThresholdMet(successfulChecks, outOf: totalChecks) ?? false
            self?.notifyConnectivityDidChange()
        }
    }

    /// Cancels tasks in the specified array which haven't yet completed.
    private func cancelPendingTasks(_ tasks: [URLSessionDataTask]) {
        for task in tasks where [.running, .suspended].contains(task.state) {
            task.cancel()
        }
    }

    /// Determines whether or not the connectivity check was successful.
    private func connectivityCheckSucceeded(data: Data?) -> Bool {
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            return false
        }
        return responseString.contains(expectedResponse)
    }

    /// Set of connectivity URLs used by default if none are otherwise specified.
    static func defaultConnectivityURLs(shouldUseHTTPS: Bool) -> [URL] {
        var result: [URL] = []
        let connectivityDomains: [String] = (shouldUseHTTPS)
            ? [ "www.apple.com" ] // Replace with custom URLs
            : [ "www.apple.com",
                "apple.com",
                "www.appleiphonecell.com",
                "www.itools.info",
                "www.ibook.info",
                "www.airport.us",
                "www.thinkdifferent.us"
        ]
        let connectivityPath = "/library/test/success.html"
        let httpProtocol = (isHTTPSOnly) ? "https" : "http"
        for domain in connectivityDomains {
            if let connectivityURL = URL(string: "\(httpProtocol)://\(domain)\(connectivityPath)") {
                result.append(connectivityURL)
            }
        }
        return result
    }

    /// Determines whether connected based on percentage of successful connectivity checks
    private func isThresholdMet(percentage: Percentage) -> Bool {
        return percentage >= successThreshold
    }

    /// Determines whether connected with the given method.
    func isConnected(with networkStatus: NetworkStatus) -> Bool {
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        return isConnected && reachability.currentReachabilityStatus() == networkStatus
    }

    /// Determines whether connected with the given method without Internet access (no connectivity).
    func isDisconnected(with networkStatus: NetworkStatus) -> Bool {
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        return !isConnected && reachability.currentReachabilityStatus() == networkStatus
    }

    /// Determines whether enough connectivity checks have succeeded to be considered connected.
    private func isThresholdMet(_ successfulChecks: Int, outOf totalChecks: Int) -> Bool {
        let success: Percentage = percentageSuccessful(successfulChecks, outOf: totalChecks)
        return isThresholdMet(percentage: success)
    }

    /// Posts notification and invokes the appropriate callback when a change in connectivity has occurred.
    private func notifyConnectivityDidChange() {
        let callback = self.isConnected ? self.whenConnected : self.whenDisconnected
        unowned let unownedSelf = self // Caller responsible for maintaining the reference
        if self.statusHasChanged(previousStatus: self.previousStatus, currentStatus: self.status) {
            NotificationCenter.default.post(name: .ConnectivityDidChange, object: unownedSelf)
            callback?(unownedSelf)
        }
        self.previousStatus = self.status // Update for the next connectivity check
    }

    /// Determines percentage successful connectivity checks.
    private func percentageSuccessful(_ successfulChecks: Int, outOf totalChecks: Int) -> Percentage {
        let percentageValue: Double = (Double(successfulChecks) / Double(totalChecks)) * 100.0
        return Percentage(percentageValue)
    }

    /// Checks connectivity when change in reachability observed
    @objc func reachabilityDidChange(_ notification: NSNotification) {
        checkConnectivity()
    }

    /// Determines whether a change in connectivity has taken place
    private func statusHasChanged(previousStatus: ConnectivityStatus?, currentStatus: ConnectivityStatus) -> Bool {
        guard let previousStatus = previousStatus else {
            return true
        }
        return previousStatus != currentStatus
    }

    /// Checks connectivity every <polling interval> seconds rather than waiting for changes in Reachability status
    func setPollingEnabled(_ enabled: Bool) {
        if #available(iOS 10.0, *) {
            timer?.invalidate()
            guard enabled else { return }
            timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true, block: { [weak self] _ in
                self?.checkConnectivity()
            })
        }
    }

    /// Returns URLSession configured with the urlSessionConfiguration property.
    func urlSession() -> URLSession {
        return URLSession(configuration: type(of: self).urlSessionConfiguration)
    }
}
