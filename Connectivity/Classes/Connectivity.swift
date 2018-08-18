//
//  Connectivity.swift
//  Connectivity
//
//  Created by Ross Butler on 7/12/17.
//  Copyright © 2017 Ross Butler. All rights reserved.
//

extension Notification.Name {
    static let ReachabilityDidChange = Notification.Name("kNetworkReachabilityChangedNotification")
    static let ConnectivityDidChange = Notification.Name("kNetworkConnectivityChangedNotification")
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
    public struct Percentage {
        let value: Double
        init(_ value: Double) {
            var result = value < 0.0 ? 0.0 : value
            result = value > 100.0 ? 100.0 : value
            self.value = result
        }
    }

    // MARK: State
    // Whether connectivity checks should be performed without waiting for reachability changes
    public var aggressivePolling: Bool = false {
        didSet {
            setAggressivePolling(enabled: aggressivePolling)
        }
    }

    /// % successful connections required to be deemed to have connectivity
    public var connectivityThreshold: Connectivity.Percentage = Connectivity.Percentage(75.0)

    /// URLs to contact in order to check connectivity
    public var connectivityURLs: [URL] = {
        var result: [URL] = []
        let connectivityDomains: [String] = (isHTTPSOnly)
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
    }()

    /// Response expected from connectivity URLs
    private let expectedResponse = "Success"

    /// Whether or not we are currently deemed to have connectivity
    public private(set) var isConnected: Bool = false

    /// Whether or not only HTTPS URLs should be used to check connectivity
    public static var isHTTPSOnly: Bool = {
        guard let bundleInfo = Bundle.main.infoDictionary,
            let appTransportSecurity = bundleInfo["NSAppTransportSecurity"] as? [String: Any],
            let allowsArbitraryLoads = appTransportSecurity["NSAllowsArbitraryLoads"] as? Bool else {
                return true
        }
        return !allowsArbitraryLoads
    }()

    /// Whether we are listening for changes in reachability (otherwise performing a one-off connectivity check)
    fileprivate var isObservingReachability = false

    /// Queue to callback on
    private var queue: DispatchQueue = DispatchQueue.main

    /// Status last time a check was performed
    private var previousStatus: ConnectivityStatus?

    /// Reachability instance for checking network adapter status
    private let reachability: Reachability

    /// Status of the current connection
    public var status: ConnectivityStatus {
        switch reachability.currentReachabilityStatus() {
        case ReachableViaWWAN:
            return (isConnected) ? .connectedViaWWAN : .connectedViaWWANWithoutInternet
        case ReachableViaWiFi:
            return (isConnected) ? .connectedViaWiFi : .connectedViaWiFiWithoutInternet
        case NotReachable:
            return .notConnected
        default: // Satisfy compiler
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
    public init() {
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
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        return isConnected && reachability.currentReachabilityStatus() == ReachableViaWWAN
    }

    var isConnectedViaWiFi: Bool {
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        return isConnected && reachability.currentReachabilityStatus() == ReachableViaWiFi
    }

    var isConnectedViaWWANWithoutInternet: Bool {
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        return reachability.currentReachabilityStatus() == ReachableViaWWAN
    }

    var isConnectedViaWiFiWithoutInternet: Bool {
        if !isObservingReachability { checkConnectivity() } // Support one-off connectivity checks
        return reachability.currentReachabilityStatus() == ReachableViaWiFi
    }

    /// Listen for changes in Reachability
    func startNotifier(queue: DispatchQueue = DispatchQueue.main) {
        if isObservingReachability { stopNotifier() } // Perform cleanup in event this method called twice
        self.queue = queue
        checkConnectivity()
        reachability.startNotifier()
        isObservingReachability = true
        setAggressivePolling(enabled: aggressivePolling)
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
        let dispatchGroup: DispatchGroup = DispatchGroup()
        var tasks: [URLSessionDataTask] = []
        let urlSession = URLSession(configuration: type(of: self).urlSessionConfiguration)

        // Count successful / unsuccessful connectivity checks
        var successfulConnectivityChecks: Double = 0
        var failedConnectivityChecks: Double = 0
        let totalConnectivityChecks: Double = Double(connectivityURLs.count)
        let percentageSuccessful = { (successfulConnectivityChecks / totalConnectivityChecks) * 100.0 }
        let isConnected = { percentageSuccessful() >= self.connectivityThreshold.value }

        // Check whether enough tasks have successfully completed to be considered connected
        let earlyExit = {
            guard isConnected() else { return }
            for task in tasks {
                switch task.state {
                case .running, .suspended:
                    task.cancel()
                case .completed, .canceling:
                    continue
                }
            }
        }

        // Connectivity check callback
        let completionHandler: (Data?, URLResponse?, Error?) -> Void = {  [weak self] (data, _, _) in
            if let data = data,
                let expectedResponse = self?.expectedResponse,
                let responseString = String(data: data, encoding: .utf8),
                responseString.contains(expectedResponse) {
                successfulConnectivityChecks += 1
            } else {
                failedConnectivityChecks += 1
            }
            dispatchGroup.leave()
            earlyExit() // Abort early if enough tasks have completed successfully
        }

        // Check each of the specified URLs in turn
        for connectivityURL in connectivityURLs {
            let task = urlSession.dataTask(with: connectivityURL, completionHandler: completionHandler)
            tasks.append(task)
            dispatchGroup.enter()
            task.resume()
        }

        dispatchGroup.notify(queue: queue) {
            self.isConnected = isConnected()
            let callback = self.isConnected ? self.whenConnected : self.whenDisconnected
            unowned let unownedSelf = self // Caller responsible for maintaining the reference
            if self.statusHasChanged(previousStatus: self.previousStatus, currentStatus: self.status) {
                NotificationCenter.default.post(name: .ConnectivityDidChange, object: unownedSelf)
                callback?(unownedSelf)
            }
            self.previousStatus = self.status // Update for the next connectivity check
        }
    }

    /// Checks connectivity when change in reachability observed
    @objc func reachabilityDidChange(_ notification: NSNotification) {
        checkConnectivity()
    }

    /// Determines whether a change in connectivity has taken place
    func statusHasChanged(previousStatus: ConnectivityStatus?, currentStatus: ConnectivityStatus) -> Bool {
        guard let previousStatus = previousStatus else {
            return true
        }
        return previousStatus != currentStatus
    }

    /// Checks connectivity every 5 seconds rather than waiting for changes in Reachability status
    func setAggressivePolling(enabled: Bool) {
        if #available(iOS 10.0, *) {
            timer?.invalidate()
            guard enabled else { return }
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] _ in
                self?.checkConnectivity()
            })
        }
    }
}
