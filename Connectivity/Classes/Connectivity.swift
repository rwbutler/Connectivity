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
    public struct Percentage {
        let value: Double
        init?(_ value: Double) {
            guard (0.0...100.0).contains(value) else {
                return nil
            }
            self.value = value
        }
    }
    public typealias NetworkConnected = (Connectivity) -> ()
    public typealias NetworkDisconnected = (Connectivity) -> ()
    
    public private(set) var isConnected: Bool = false
    public static var connectivityThreshold: Connectivity.Percentage = Connectivity.Percentage(75.0)!
    public static var connectivityURLs: [URL] = {
        var result: [URL] = []
        var useHTTP = false
        if let bundleInfo = Bundle.main.infoDictionary,
            let appTransportSecurity = bundleInfo["NSAppTransportSecurity"] as? [String: Any],
            let allowsArbitraryLoads = appTransportSecurity["NSAllowsArbitraryLoads"] as? Bool {
            useHTTP = allowsArbitraryLoads
        }
        let connectivityDomains: [String] = (useHTTP)
            ? [
                "www.apple.com",
                "apple.com",
                "www.appleiphonecell.com",
                "www.itools.info",
                "www.ibook.info",
                "www.airport.us",
                "www.thinkdifferent.us"
                ]
            : [ "www.apple.com" ] // Recommended supplementing with your own URLs
        let connectivityPath = "/library/test/success.html"
        let httpProtocol = (useHTTP) ? "http" : "https"
        for domain in connectivityDomains {
            if let connectivityURL = URL(string: "\(httpProtocol)://\(domain)\(connectivityPath)") {
                result.append(connectivityURL)
            }
        }
        return result
    }()
    public static var urlSessionConfiguration: URLSessionConfiguration = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 5.0
        sessionConfiguration.timeoutIntervalForResource = 5.0
        return sessionConfiguration
    }()
    public var notificationCenter: NotificationCenter = NotificationCenter.default
    
    public enum ConnectivityStatus: CustomStringConvertible {
        case notConnected, connectedViaWiFi, connectedViaWWAN, connectedViaWiFiWithoutInternet, connectedViaWWANWithoutInternet
        
        public var description: String {
            switch self {
            case .connectedViaWWAN: return "Cellular"
            case .connectedViaWWANWithoutInternet: return "Cellular without Internet access"
            case .connectedViaWiFi: return "WiFi"
            case .connectedViaWiFiWithoutInternet: return "WiFi without Internet access"
            case .notConnected: return "No Connection"
            }
        }
    }
    public var whenConnected: NetworkConnected?
    public var whenDisconnected: NetworkDisconnected?
    
    public var currentConnectivityString: String {
        return "\(currentConnectivityStatus)"
    }
    
    public var currentConnectivityStatus: ConnectivityStatus {
        if isConnectedViaWiFi {
            return .connectedViaWiFi
        }
        if isConnectedViaWWAN
        {
            return .connectedViaWWAN
        }
        if isConnectedViaWiFiWithoutInternet {
            return .connectedViaWiFiWithoutInternet
        }
        if isConnectedViaWWANWithoutInternet
        {
            return .connectedViaWWANWithoutInternet
        }
        return .notConnected
    }
    let reachability: Reachability
    private static let expectedResponse = "Success"
    private var timer: Timer? = nil
    fileprivate var reachabilityPolling = false
    public var aggressivePolling: Bool = false {
        didSet {
            aggressivePolling(enabled: aggressivePolling)
        }
    }
    
    public func aggressivePolling(enabled: Bool) {
        if #available(iOS 10.0, *) {
            timer?.invalidate()
            if aggressivePolling && reachabilityPolling {
                timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { timer in
                    self.performConnectivityChecks()
                })
            }
        }
    }
    
    public init() {
        reachability = Reachability.forInternetConnection()
        performConnectivityChecks()
    }
    
    public func performConnectivityChecks() {
        let connectivityURLs = type(of: self).connectivityURLs
        let connectivityDomainCount: Double = Double(connectivityURLs.count)
        var successfulConnectivityChecks: Double = 0
        var failedConnectivityChecks: Double = 0
        
        for connectivityURL in connectivityURLs {
            let urlSession = URLSession(configuration: type(of: self).urlSessionConfiguration)
            let task = urlSession.dataTask(with: connectivityURL, completionHandler: { [weak self] (data, response, error) in
                guard let strongSelf = self else {
                    return
                }
                if let data = data,
                    let responseString = String(data: data, encoding: .utf8),
                    responseString.contains(type(of: strongSelf).expectedResponse) {
                    successfulConnectivityChecks += 1
                } else {
                    failedConnectivityChecks += 1
                }
                
                if connectivityDomainCount == (successfulConnectivityChecks + failedConnectivityChecks) {
                    let percentageSuccessful = (successfulConnectivityChecks / connectivityDomainCount) * 100.0
                    strongSelf.isConnected = (percentageSuccessful >= type(of: strongSelf).connectivityThreshold.value)
                        ? true : false
                    unowned let unownedSelf = strongSelf // Caller responsible for maintaining the reference
                    strongSelf.notificationCenter.post(name: .ConnectivityDidChange, object: unownedSelf)
                    DispatchQueue.main.async {
                        let callback = strongSelf.isConnected ? strongSelf.whenConnected : strongSelf.whenDisconnected
                        callback?(unownedSelf)
                    }
                }
            })
            task.resume()
        }
    }
    
    @objc fileprivate func reachabilityDidChange(_ notification: NSNotification) {
        performConnectivityChecks()
    }
    
    deinit {
        stopNotifier()
    }
}

public extension Connectivity {
    var isConnectedViaWWAN: Bool {
        return isConnected && reachability.currentReachabilityStatus() == ReachableViaWWAN
    }
    
    var isConnectedViaWiFi: Bool {
        return isConnected && reachability.currentReachabilityStatus() == ReachableViaWiFi
    }
    
    var isConnectedViaWWANWithoutInternet: Bool {
        return reachability.currentReachabilityStatus() == ReachableViaWWAN
    }
    
    var isConnectedViaWiFiWithoutInternet: Bool {
        return reachability.currentReachabilityStatus() == ReachableViaWiFi
    }
    
    var description: String {
        return "\(reachability.description)"
    }
    
    func startNotifier() {
        reachability.startNotifier()
        reachabilityPolling = true
        aggressivePolling(enabled: aggressivePolling)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityDidChange(_:)),
                                               name: NSNotification.Name.ReachabilityDidChange,
                                               object: nil)
    }
    
    func stopNotifier() {
        reachability.stopNotifier()
        reachabilityPolling = false
        notificationCenter.removeObserver(self)
    }
}
