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
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: Status
    fileprivate var isCheckingConnectivity: Bool = false

    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        switch connectivity.framework {
        case .network:
            segmentedControl.selectedSegmentIndex = 1
        case .systemConfiguration:
            segmentedControl.selectedSegmentIndex = 0
        }
        performSingleConnectivityCheck()
        configureConnectivityNotifier()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        connectivity.stopNotifier()
    }

    deinit {
        connectivity.stopNotifier()
    }
}

// IB Actions
extension ViewController {
    @IBAction func notifierButtonTapped(_ sender: UIButton) {
        isCheckingConnectivity ? stopConnectivityChecks() : startConnectivityChecks()
    }

    @IBAction func segmentedControlTapped(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            connectivity.framework = .systemConfiguration
        } else {
            connectivity.framework = .network
        }
    }
}

// Private API
private extension ViewController {
    func configureConnectivityNotifier() {
        let connectivityChanged: (Connectivity) -> Void = { [weak self] connectivity in
            self?.updateConnectionStatus(connectivity.status)
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
    }

    func performSingleConnectivityCheck() {
        connectivity.checkConnectivity { connectivity in
            self.updateConnectionStatus(connectivity.status)
        }
    }

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
        case .connectedViaWiFi, .connectedViaWWAN, .connected:
            statusLabel.textColor = UIColor.darkGreen
        case .connectedViaWiFiWithoutInternet, .connectedViaWWANWithoutInternet, .notConnected:
            statusLabel.textColor = UIColor.red
        }
        statusLabel.text = status.description
        segmentedControl.tintColor = statusLabel.textColor
    }

    func updateNotifierButton(isCheckingConnectivity: Bool) {
        let buttonText = isCheckingConnectivity ? "Stop notifier" : "Start notifier"
        let buttonTextColor = isCheckingConnectivity ? UIColor.red : UIColor.darkGreen
        notifierButton.setTitle(buttonText, for: .normal)
        notifierButton.setTitleColor(buttonTextColor, for: .normal)
    }
}
