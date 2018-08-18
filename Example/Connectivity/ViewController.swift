//
//  ViewController.swift
//  Connectivity
//
//  Created by Ross Butler on 07/15/2017.
//  Copyright (c) 2017 Ross Butler. All rights reserved.
//

import UIKit
import Connectivity

class ViewController: UIViewController {
    // MARK: Dependencies
    fileprivate let connectivity: Connectivity = Connectivity()

    // MARK: Outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var notifierButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: Status
    fileprivate var isCheckingConnectivity: Bool = false

    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let connectivityChanged: (Connectivity) -> Void = { [weak self] connectivity in
            self?.updateConnectionStatus(connectivity.currentConnectivityStatus)
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        startConnectivityChecks()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        connectivity.stopNotifier()
    }

    deinit {
        connectivity.stopNotifier()
    }
}

// Button actions
extension ViewController {
    @IBAction func notifierButtonTapped(_ sender: UIButton) {
        isCheckingConnectivity ? stopConnectivityChecks() : startConnectivityChecks()
    }
}

// Private API
private extension ViewController {
    func startConnectivityChecks() {
        activityIndicator.startAnimating()
        connectivity.startNotifier()
        isCheckingConnectivity = true
        updateNotifierButton(isCheckingConnectivity: isCheckingConnectivity)
    }
    func stopConnectivityChecks() {
        activityIndicator.stopAnimating()
        connectivity.stopNotifier()
        isCheckingConnectivity = false
        updateNotifierButton(isCheckingConnectivity: isCheckingConnectivity)
    }
    func updateConnectionStatus(_ status: Connectivity.ConnectivityStatus) {
        switch status {
        case .connectedViaWiFi, .connectedViaWWAN:
            statusLabel.textColor = UIColor.darkGreen
        case .connectedViaWiFiWithoutInternet, .connectedViaWWANWithoutInternet, .notConnected:
            statusLabel.textColor = UIColor.red
        }
        statusLabel.text = status.description
    }
    func updateNotifierButton(isCheckingConnectivity: Bool) {
        let buttonText = isCheckingConnectivity ? "Stop notifier" : "Start notifier"
        let buttonTextColor = isCheckingConnectivity ? UIColor.red : UIColor.darkGreen
        notifierButton.setTitle(buttonText, for: .normal)
        notifierButton.setTitleColor(buttonTextColor, for: .normal)
    }
}
