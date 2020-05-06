//
//  Publishers.swift
//  Connectivity
//
//  Created by Ross Butler on 05/05/2020.
//

#if canImport(Combine)

import Combine
import Foundation

@available(iOS 13.0, tvOS 13.0, *)
public extension Publishers {
    typealias Connectivity = ConnectivityPublisher
}

#endif
