//
//  ViewController.swift
//  Connectivity
//
//  Created by Ross Butler on 07/15/2017.
//  Copyright (c) 2017 Ross Butler. All rights reserved.
//

import Connectivity
import UIKit

class OriginalExampleViewController: UIViewController {
    // MARK: Dependencies

    fileprivate let connectivity: Connectivity = Connectivity()

    // MARK: Outlets

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var notifierButton: UIButton!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var statusLabel: UILabel!

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
extension OriginalExampleViewController {
    @IBAction func notifierButtonTapped(_: UIButton) {
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
private extension OriginalExampleViewController {
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
        segmentedControl.isEnabled = false
        updateNotifierButton(isCheckingConnectivity: isCheckingConnectivity)
    }

    func stopConnectivityChecks() {
        activityIndicator.stopAnimating()
        connectivity.stopNotifier()
        isCheckingConnectivity = false
        segmentedControl.isEnabled = true
        updateNotifierButton(isCheckingConnectivity: isCheckingConnectivity)
    }

    func updateConnectionStatus(_ status: Connectivity.Status) {
        switch status {
        case .connectedViaWiFi, .connectedViaCellular, .connected:
            statusLabel.textColor = UIColor.darkGreen
        case .connectedViaWiFiWithoutInternet, .connectedViaCellularWithoutInternet, .notConnected:
            statusLabel.textColor = UIColor.red
        case .determining:
            statusLabel.textColor = UIColor.black
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
