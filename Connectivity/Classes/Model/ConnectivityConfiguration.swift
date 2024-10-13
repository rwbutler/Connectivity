//
//  ConnectivityConfiguration.swift
//  Connectivity
//
//  Created by Ross Butler on 14/05/2022.
//

import Foundation

typealias Configuration = ConnectivityConfiguration // For internal use.

@objc public class ConnectivityConfiguration: NSObject {
    private(set) var authorizationHeader: String?
    private(set) var bearerToken: String?
    let callbackQueue: DispatchQueue
    private(set) var checkWhenApplicationDidBecomeActive: Bool = true
    let connectivityQueue: DispatchQueue
    private(set) var connectivityURLRequests: [URLRequest]
    public static let defaultConnectivityURLRequests = [
        URL(string: "https://www.apple.com/library/test/success.html"),
        URL(string: "https://captive.apple.com/hotspot-detect.html")
    ]
        .compactMap {
            $0
        }
        .map {
            URLRequest(url: $0)
        }
    public static let defaultURLSessionConfiguration: URLSessionConfiguration = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .reloadIgnoringCacheData
        sessionConfiguration.urlCache = nil
        sessionConfiguration.timeoutIntervalForRequest = 5.0
        sessionConfiguration.timeoutIntervalForResource = 5.0
        return sessionConfiguration
    }()
    private(set) var framework: Connectivity.Framework = .network
    private(set) var pollingInterval: Double
    private(set) var pollingIsEnabled: Bool
    private(set) var pollWhileOfflineOnly: Bool
    private(set) var responseValidator: ResponseValidator
    
    /// % successful connections required to be deemed to have connectivity
    let successThreshold: Connectivity.Percentage
    private(set) var urlSessionConfiguration: URLSessionConfiguration
    private(set) var validationMode: Connectivity.ValidationMode?
    
    public init(
        callbackQueue: DispatchQueue = DispatchQueue.main,
        checkWhenApplicationDidBecomeActive: Bool = true,
        connectivityQueue: DispatchQueue = .global(qos: .default),
        connectivityURLRequests: [URLRequest] = defaultConnectivityURLRequests,
        pollingInterval: Double = 10.0,
        pollingIsEnabled: Bool = true,
        pollWhileOfflineOnly: Bool = true,
        responseValidator: ConnectivityResponseValidator = ConnectivityResponseStringValidator(
            validationMode: .containsExpectedResponseString,
            expectedResponse: "Success"
        ),
        successThreshold: Connectivity.Percentage = Connectivity.Percentage(50.0),
        urlSessionConfiguration: URLSessionConfiguration = defaultURLSessionConfiguration,
        validationMode: Connectivity.ValidationMode? = nil
    ) {
        self.callbackQueue = callbackQueue
        self.checkWhenApplicationDidBecomeActive = checkWhenApplicationDidBecomeActive
        self.connectivityQueue = connectivityQueue
        self.connectivityURLRequests = connectivityURLRequests
        self.pollingInterval = pollingInterval
        self.pollingIsEnabled = pollingIsEnabled
        self.pollWhileOfflineOnly = pollWhileOfflineOnly
        self.responseValidator = responseValidator
        self.successThreshold = successThreshold
        self.urlSessionConfiguration = urlSessionConfiguration
        self.validationMode = validationMode
    }
    
    // MARK: Fluent configuration API.
    
    public func configureAuthorizationHeader(with value: String?) -> Self {
        self.authorizationHeader = value
        return self
    }
    
    public func configureBearerToken(with token: String?) -> Self {
        self.bearerToken = token
        return self
    }
    
    public func configureConnectivity(urls: [URL]) -> Self {
        self.connectivityURLRequests = urls.map {
            URLRequest(url: $0)
        }
        return self
    }
    
    public func configureConnectivity(urlRequests: [URLRequest]) -> Self {
        self.connectivityURLRequests = urlRequests
        return self
    }
    
    public func configureFramework(_ framework: Connectivity.Framework) -> Self {
        self.framework = framework
        return self
    }
    
    public func configurePolling(isEnabled: Bool = true, interval: Double = 10.0, offlineOnly: Bool = true) -> Self {
        pollingIsEnabled = isEnabled
        pollingInterval = interval
        pollWhileOfflineOnly = offlineOnly
        return self
    }
    
    public func configureResponseValidation(
        _ validation: ConnectivityResponseStringValidator.ValidationMode,
        expected: String
    ) -> Self {
        responseValidator = ResponseStringValidator(validationMode: validation, expectedResponse: expected)
        return self
    }
    
    public func configureResponseValidator(_ responseValidator: ConnectivityResponseValidator) -> Self {
        self.responseValidator = responseValidator
        return self
    }
    
    public func configureShouldCheckWhenApplicationDidBecomeActive(_ enabled: Bool) {
        checkWhenApplicationDidBecomeActive = enabled
    }
    
    public func configureURLSession(_ urlSessionConfiguration: URLSessionConfiguration) -> Self {
        self.urlSessionConfiguration = urlSessionConfiguration
        return self
    }
    
    public func configureValidationMode(with validationMode: Connectivity.ValidationMode) -> Self {
        self.validationMode = validationMode
        return self
    }
}
