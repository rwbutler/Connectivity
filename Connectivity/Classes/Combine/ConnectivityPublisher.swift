//
//  ConnectivityPublisher.swift
//  Connectivity
//
//  Created by Ross Butler on 05/05/2020.
//

#if canImport(Combine)

import Combine
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public struct ConnectivityPublisher: Publisher {
    public typealias Output = Connectivity
    public typealias Failure = Never
    private let configuration: ConnectivityConfiguration
    
    public init(configuration: ConnectivityConfiguration = ConnectivityConfiguration()) {
        self.configuration = configuration
    }
    
    public func receive<S: Subscriber>(subscriber: S)
        where ConnectivityPublisher.Failure == S.Failure, ConnectivityPublisher.Output == S.Input {
            let subscription = ConnectivitySubscription(configuration: configuration, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

#endif
