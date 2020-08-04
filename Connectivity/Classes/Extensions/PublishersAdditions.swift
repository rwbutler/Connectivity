//
//  Publishers.swift
//  Connectivity
//
//  Created by Ross Butler on 05/05/2020.
//

#if canImport(Combine)

import Combine
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public extension Publishers {
    typealias Connectivity = ConnectivityPublisher
}

#endif
