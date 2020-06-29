//
//  ViewController.swift
//  Connectivity_Example_macOS
//
//  Created by Philip Dukhov on 6/29/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Cocoa
import Connectivity

class ViewController: NSViewController {
    private let connectivity = Connectivity(shouldUseHTTPS: false)

    override func viewDidLoad() {
        super.viewDidLoad()

        connectivity.framework = .network
        connectivity.whenConnected = { connectivity in
            print("connectivity11", connectivity.status.description)
        }
        connectivity.whenDisconnected = { connectivity in
            print("connectivity12", connectivity.status.description)
        }
        connectivity.startNotifier()
    }
}
