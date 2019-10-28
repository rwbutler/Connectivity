//
//  Factory.swift
//  Connectivity
//
//  Created by Ross Butler on 25/10/2019.
//

import Foundation

protocol Factory {
    associatedtype T
    func manufacture() -> T
}
