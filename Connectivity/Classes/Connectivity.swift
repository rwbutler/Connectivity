//
//  Connectivity.swift
//  Connectivity
//
//  Created by Ross Butler on 7/12/17.
//  Copyright © 2017 - 2019 Ross Butler. All rights reserved.
//

import Foundation
import Network
#if IMPORT_REACHABILITY
import Reachability
#endif

@objcMembers
public class Connectivity: NSObject {
    public typealias Framework = ConnectivityFramework
    public typealias Interface = ConnectivityInterface
    public typealias NetworkConnected = (Connectivity) -> Void
    public typealias NetworkDisconnected = (Connectivity) -> Void
    public typealias Percentage = ConnectivityPercentage
    public typealias Status = ConnectivityStatus
    public typealias ValidationMode = ConnectivityResponseValidationMode
#if canImport(Combine)
    @available(iOS 13.0, tvOS 13.0, *)
    public typealias Publisher = ConnectivityPublisher
#endif

    // MARK: State

    /// % successful connections required to be deemed to have connectivity
    public var successThreshold = Connectivity.Percentage(50.0)

    /// URLs to contact in order to check connectivity
    public var connectivityURLs: [URL] = Connectivity
        .defaultConnectivityURLs(shouldUseHTTPS: Connectivity.isHTTPSOnly) {
        didSet {
            if Connectivity.isHTTPSOnly { // if HTTPS only set only allow HTTPS URLs
                connectivityURLs = connectivityURLs.filter { url in
                    return url.absoluteString.lowercased().starts(with: "https")
                }
            }
        }
    }

    /// Optionally configure a bearer token to be sent as part of an Authorization header.
    public var bearerToken: String?

    /// Available network interfaces as of most recent connectivity check.
    public private(set) var availableInterfaces: [Interface] = []

    /// There can be a delay between being informed of a network interface change and the
    /// network actually being available.
    public var connectivityCheckLatency: Double = 0.5

    /// Current network interface as of most recent connectivity check.
    public private(set) var currentInterface: Interface = .other

    /// Regex expected to match connectivity URL response
    public var expectedResponseRegEx = ".*?<BODY>.*?Success.*?</BODY>.*" {
        didSet {
            updateValidator(for: validationMode)
        }
    }

    /// Response expected from connectivity URLs
    public var expectedResponseString = "Success" {
        didSet {
            updateValidator(for: validationMode)
        }
    }

    /// Whether or not to use System Configuration or Network (on iOS 12+) framework.
    public var framework: Connectivity.Framework = .systemConfiguration

    /// Used to for checks using NWPathMonitor
    private var internalQueue: DispatchQueue = DispatchQueue.global(qos: .background)

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
    fileprivate var isObservingInterfaceChanges = false

    /// Whether connectivity checks should be performed without waiting for reachability changes
    public var isPollingEnabled: Bool = false {
        didSet {
            if isObservingInterfaceChanges, oldValue != isPollingEnabled {
                setPollingEnabled(isPollingEnabled)
            }
        }
    }

    // Stores a NWPathMonitor reference - erase type information where Network framework unavailable.
    private var pathMonitor: Any?

    /// Where polling is enabled, the interval at which connectivity checks will be performed.
    public var pollingInterval: Double = 10.0

    /// Status last time a check was performed
    private var previousStatus: ConnectivityStatus = .determining

    /// Queue to callback on
    private var externalQueue: DispatchQueue = DispatchQueue.main

    /// Reachability instance for checking network adapter status
    private let reachability: Reachability

    /// Can be used to set a custom validator conforming to `ConnectivityResponseValidator`
    public var responseValidator: ConnectivityResponseValidator =
        ConnectivityResponseContainsStringValidator()

    /// Returns the appropriate validator for the current validation mode.
    private var responseValidatorFactory: ResponseValidatorFactory {
        return ResponseValidatorFactory(
            validationMode: validationMode,
            expectedResponse: expectedResponseString,
            regEx: expectedResponseRegEx,
            customValidator: responseValidator
        )
    }

    /// Status of the current connection
    public var status: ConnectivityStatus = .determining

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

    /// Method used to determine whether response content is valid
    public var validationMode: ValidationMode = .containsExpectedResponseString {
        didSet {
            updateValidator(for: validationMode)
        }
    }

    /// Callback to invoke when connected
    public var whenConnected: NetworkConnected?

    /// Callback to invoke when disconnected
    public var whenDisconnected: NetworkDisconnected?

    // MARK: Life cycle

    public init(shouldUseHTTPS: Bool = true) {
        type(of: self).isHTTPSOnly = shouldUseHTTPS
        self.reachability = Reachability.forInternetConnection()
    }

    deinit {
        stopNotifier()
    }
}

// Public API
public extension Connectivity {
    /// Textual representation of connectivity state
    override var description: String {
        return "\(status)"
    }

    var isConnectedViaCellular: Bool {
        return isConnected(with: ReachableViaWWAN)
    }

    var isConnectedViaWiFi: Bool {
        return isConnected(with: ReachableViaWiFi)
    }

    var isConnectedViaCellularWithoutInternet: Bool {
        return isDisconnected(with: ReachableViaWWAN)
    }

    var isConnectedViaWiFiWithoutInternet: Bool {
        return isDisconnected(with: ReachableViaWiFi)
    }

    /// Checks specified URLs for the expected response to determine whether Internet connectivity exists
    func checkConnectivity(completion: ((Connectivity) -> Void)? = nil) {
        let dispatchGroup = DispatchGroup()
        var tasks: [URLSessionDataTask] = []
        let session: URLSession = urlSession()
        var successfulChecks: Int = 0, failedChecks: Int = 0
        let totalChecks: Int = connectivityURLs.count

        // Connectivity check callback
        let completionHandlerForUrl: (URL) -> ((Data?, URLResponse?, Error?) -> Void) = { url in
            return { [weak self] data, response, _ in
                let connectivityCheckSuccess = self?.connectivityCheckSucceeded(
                    for: url,
                    response: response,
                    data: data
                ) ?? false
                connectivityCheckSuccess ? (successfulChecks += 1) : (failedChecks += 1)
                dispatchGroup.leave()
                // Abort early if enough tasks have completed successfully
                self?.cancelConnectivityCheck(
                    pendingTasks: tasks,
                    successfulChecks: successfulChecks,
                    totalChecks: totalChecks
                )
            }
        }

        // Check each of the specified URLs in turn
        tasks = connectivityURLs.map {
            if let urlRequest = authorizedURLRequest(with: $0) {
                return session.dataTask(with: urlRequest, completionHandler: completionHandlerForUrl($0))
            }
            return session.dataTask(with: $0, completionHandler: completionHandlerForUrl($0))
        }

        tasks.forEach { task in
            dispatchGroup.enter()
            let deadline: DispatchTime = (previousStatus == .notConnected)
                ? DispatchTime.now() + connectivityCheckLatency
                : DispatchTime.now()
            internalQueue.asyncAfter(deadline: deadline) {
                task.resume()
            }
        }
        dispatchGroup.notify(queue: externalQueue) { [weak self] in
            let isConnected = self?.isThresholdMet(successfulChecks, outOf: totalChecks) ?? false
            self?.updateStatus(isConnected: isConnected)
            if let strongSelf = self {
                unowned let unownedSelf = strongSelf
                completion?(unownedSelf) // Caller responsible for retaining the reference.
            }
            if let isObserving = self?.isObservingInterfaceChanges, isObserving {
                self?.notifyConnectivityDidChange()
            }
        }
    }

    /// Listen for changes in Reachability
    func startNotifier(queue: DispatchQueue = DispatchQueue.main) {
        if isObservingInterfaceChanges { stopNotifier() } // Perform cleanup in event this method called twice
        externalQueue = queue
        isObservingInterfaceChanges = true
        setPollingEnabled(isPollingEnabled)
        if #available(iOS 12.0, tvOS 12.0, *), isNetworkFramework() {
            startPathMonitorNotifier()
        } else {
            startReachabilityNotifier()
        }
    }

    @available(iOS 12.0, tvOS 12.0, *)
    private func startPathMonitorNotifier() {
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] _ in
            self?.checkConnectivity()
        }
        monitor.start(queue: internalQueue)
    }

    private func startReachabilityNotifier() {
        checkConnectivity()
        reachability.startNotifier()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityDidChange(_:)),
            name: NSNotification.Name.ReachabilityDidChange,
            object: nil
        )
    }

    /// Stop listening for Reachability changes
    func stopNotifier() {
        timer?.invalidate()
        if #available(iOS 12.0, tvOS 12.0, *), isNetworkFramework() {
            stopPathMonitorNotifier()
        } else {
            stopReachabilityNotifier()
        }
        isObservingInterfaceChanges = false
    }

    @available(iOS 12.0, tvOS 12.0, *)
    private func stopPathMonitorNotifier() {
        if isObservingInterfaceChanges, let monitor = pathMonitor as? NWPathMonitor {
            monitor.cancel()
            pathMonitor = nil
        }
    }

    private func stopReachabilityNotifier() {
        if isObservingInterfaceChanges { reachability.stopNotifier() }
        NotificationCenter.default.removeObserver(self)
    }
}

// Private API
private extension Connectivity {
    /// Returns a URL request for an Authorization header if the `bearerToken` property is set,
    /// otherwise `nil` is returned.
    func authorizedURLRequest(with url: URL) -> URLRequest? {
        guard let bearerToken = self.bearerToken else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// Check whether enough tasks have successfully completed to be considered connected
    private func cancelConnectivityCheck(pendingTasks: [URLSessionDataTask], successfulChecks: Int, totalChecks: Int) {
        let isConnected = isThresholdMet(successfulChecks, outOf: totalChecks)
        guard isConnected else { return }
        cancelPendingTasks(pendingTasks)
    }

    /// Cancels tasks in the specified array which haven't yet completed.
    private func cancelPendingTasks(_ tasks: [URLSessionDataTask]) {
        for task in tasks where [.running, .suspended].contains(task.state) {
            task.cancel()
        }
    }

    /// Determines whether or not the connectivity check was successful.
    private func connectivityCheckSucceeded(for url: URL, response: URLResponse?, data: Data?) -> Bool {
        let validator = responseValidatorFactory.manufacture()
        return validator.isResponseValid(url: url, response: response, data: data)
    }

    /// Set of connectivity URLs used by default if none are otherwise specified.
    static func defaultConnectivityURLs(shouldUseHTTPS: Bool) -> [URL] {
        var result: [URL] = []
        let connectivityURLs: [String] = shouldUseHTTPS
            ? ["https://www.apple.com/library/test/success.html",
               "https://captive.apple.com/hotspot-detect.html"] // Replace with custom URLs
            : ["http://www.apple.com/library/test/success.html",
               "http://apple.com/library/test/success.html",
               "http://www.appleiphonecell.com/library/test/success.html",
               "http://www.itools.info/library/test/success.html",
               "http://www.ibook.info/library/test/success.html",
               "http://www.airport.us/library/test/success.html",
               "http://www.thinkdifferent.us/library/test/success.html",
               "http://captive.apple.com/hotspot-detect.html"]
        for connectivityURLStr in connectivityURLs {
            if let connectivityURL = URL(string: connectivityURLStr) {
                result.append(connectivityURL)
            }
        }
        return result
    }

    func interface(with networkStatus: NetworkStatus) -> ConnectivityInterface {
        switch networkStatus {
        case ReachableViaWiFi:
            return .wifi
        case ReachableViaWWAN:
            return .cellular
        default:
            return .other
        }
    }

    @available(iOS 12.0, tvOS 12.0, *)
    func interface(with path: NWPath) -> ConnectivityInterface {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else {
            return .other
        }
    }

    @available(iOS 12.0, tvOS 12.0, *)
    func interfaces(with path: NWPath) -> [ConnectivityInterface] {
        return path.availableInterfaces.map { interface in
            switch interface.type {
            case .cellular:
                return .cellular
            case .loopback:
                return .loopback
            case .other:
                return .other
            case .wifi:
                return .wifi
            case .wiredEthernet:
                return .ethernet
            @unknown default:
                return .other
            }
        }
    }

    /// Determines whether connected based on percentage of successful connectivity checks
    private func isThresholdMet(percentage: Percentage) -> Bool {
        return percentage >= successThreshold
    }

    /// Determines whether connected with the given method.
    func isConnected(with networkStatus: NetworkStatus) -> Bool {
        if #available(iOS 12.0, tvOS 12.0, *), isNetworkFramework() {
            var isNetworkInterfaceMatch: Bool = false
            if let monitor = self.pathMonitor as? NWPathMonitor, let interface = interfaceType(from: networkStatus) {
                isNetworkInterfaceMatch = monitor.currentPath.availableInterfaces.map { $0.type }.contains(interface)
                return isConnected && isNetworkInterfaceMatch
            }
            return false
        } else {
            return isConnected && reachability.currentReachabilityStatus() == networkStatus
        }
    }

    /// Determines whether connected with the given method without Internet access (no connectivity).
    func isDisconnected(with networkStatus: NetworkStatus) -> Bool {
        if #available(iOS 12.0, tvOS 12.0, *), isNetworkFramework() {
            var isNetworkInterfaceMatch: Bool = false
            if let monitor = self.pathMonitor as? NWPathMonitor, let interface = interfaceType(from: networkStatus) {
                isNetworkInterfaceMatch = monitor.currentPath.availableInterfaces.map { $0.type }.contains(interface)
                return !isConnected && isNetworkInterfaceMatch
            }
            return false
        } else {
            return !isConnected && reachability.currentReachabilityStatus() == networkStatus
        }
    }

    /// Maps a NetworkStatus to a NWInterface.InterfaceType, if possible.
    @available(iOS 12.0, tvOS 12.0, *)
    private func interfaceType(from networkStatus: NetworkStatus) -> NWInterface.InterfaceType? {
        switch networkStatus {
        case ReachableViaWiFi:
            return .wifi
        case ReachableViaWWAN:
            return .cellular
        default:
            return nil
        }
    }

    /// Determines whether enough connectivity checks have succeeded to be considered connected.
    private func isThresholdMet(_ successfulChecks: Int, outOf totalChecks: Int) -> Bool {
        let success: Percentage = percentageSuccessful(successfulChecks, outOf: totalChecks)
        return isThresholdMet(percentage: success)
    }

    /// Whether or not the we should use the Network framework on iOS 12+.
    func isNetworkFramework() -> Bool {
        return framework == .network
    }

    /// Posts notification and invokes the appropriate callback when a change in connectivity has occurred.
    private func notifyConnectivityDidChange() {
        let callback = isConnected ? whenConnected : whenDisconnected
        let currentStatus = status
        unowned let unownedSelf = self // Caller responsible for maintaining the reference
        if statusHasChanged(previousStatus: previousStatus, currentStatus: currentStatus) {
            NotificationCenter.default.post(name: .ConnectivityDidChange, object: unownedSelf)
            callback?(unownedSelf)
        }
        previousStatus = currentStatus // Update for the next connectivity check
    }

    /// Determines percentage successful connectivity checks.
    private func percentageSuccessful(_ successfulChecks: Int, outOf totalChecks: Int) -> Percentage {
        let percentageValue: Double = (Double(successfulChecks) / Double(totalChecks)) * 100.0
        return Percentage(percentageValue)
    }

    /// Checks connectivity when change in reachability observed
    @objc func reachabilityDidChange(_: NSNotification) {
        checkConnectivity()
    }

    /// Checks connectivity every <polling interval> seconds rather than waiting for changes in Reachability status
    func setPollingEnabled(_ enabled: Bool) {
        timer?.invalidate()
        guard enabled else { return }
        timer = Timer.scheduledTimer(
            timeInterval: pollingInterval,
            target: self,
            selector: #selector(reachabilityDidChange(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    /// Determines the connectivity status using info provided by `NetworkStatus`.
    func status(from networkStatus: NetworkStatus, isConnected: Bool) -> ConnectivityStatus {
        let currentStatus: ConnectivityStatus
        switch networkStatus {
        case ReachableViaWWAN:
            currentStatus = isConnected ? .connectedViaCellular : .connectedViaCellularWithoutInternet
        case ReachableViaWiFi:
            currentStatus = isConnected ? .connectedViaWiFi : .connectedViaWiFiWithoutInternet
        default: // Needed as Obj-C Int-backed enum
            currentStatus = isConnected ? .connected : .notConnected
        }
        return currentStatus
    }

    /// Determines the connectivity status using network interface info provided by `NWPath`.
    @available(iOS 12.0, tvOS 12.0, *)
    func status(from path: NWPath, isConnected: Bool) -> ConnectivityStatus {
        let currentInterface = interface(with: path)
        let currentStatus: ConnectivityStatus
        if currentInterface == .wifi {
            currentStatus = isConnected ? .connectedViaWiFi : .connectedViaWiFiWithoutInternet
        } else if currentInterface == .cellular {
            currentStatus = isConnected ? .connectedViaCellular : .connectedViaCellularWithoutInternet
        } else {
            currentStatus = isConnected ? .connected : .notConnected
        }
        return currentStatus
    }

    /// Determines whether a change in connectivity has taken place.
    private func statusHasChanged(previousStatus: ConnectivityStatus?, currentStatus: ConnectivityStatus) -> Bool {
        guard let previousStatus = previousStatus else {
            return true
        }
        return previousStatus != currentStatus
    }

    /// Updates the connectivity status using network interface info provided by `NWPath`.
    @available(iOS 12.0, tvOS 12.0, *)
    func updateStatus(from path: NWPath, isConnected: Bool) {
        availableInterfaces = interfaces(with: path)
        currentInterface = interface(with: path)
        self.isConnected = isConnected
        status = status(from: path, isConnected: isConnected)
    }

    /// Updates the connectivity status using info provided by `NetworkStatus`.
    func updateStatus(from networkStatus: NetworkStatus, isConnected: Bool) {
        let currentInterface = interface(with: networkStatus)
        availableInterfaces = [currentInterface]
        self.currentInterface = currentInterface
        self.isConnected = isConnected
        status = status(from: networkStatus, isConnected: isConnected)
    }

    /// Convenience method - updates the connectivity status using info provided by `NetworkStatus`.
    func updateStatus(isConnected: Bool) {
        switch framework {
        case .network:
            if #available(iOS 12.0, tvOS 12.0, *) {
                let monitor = (pathMonitor as? NWPathMonitor) ?? NWPathMonitor()
                updateStatus(from: monitor.currentPath, isConnected: isConnected)
            } else { // Fallback to SystemConfiguration framework.
                let networkStatus = reachability.currentReachabilityStatus()
                updateStatus(from: networkStatus, isConnected: isConnected)
            }
        case .systemConfiguration:
            let networkStatus = reachability.currentReachabilityStatus()
            updateStatus(from: networkStatus, isConnected: isConnected)
        }
    }

    /// Updates the validator when the validation mode changes.
    func updateValidator(for _: ValidationMode) {
        let validator = responseValidatorFactory.manufacture()
        responseValidator = validator
    }

    /// Returns URLSession configured with the urlSessionConfiguration property.
    func urlSession() -> URLSession {
        return URLSession(configuration: type(of: self).urlSessionConfiguration)
    }
}
