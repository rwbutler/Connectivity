//
//  CombineViewController.swift
//  Connectivity
//
//  Created by Ross Butler on 05/05/2020.
//  Copyright © 2020 Ross Butler. All rights reserved.
//

#if canImport(Combine)

import Combine
import Connectivity
import UIKit

@available(iOS 13.0, *)
class CombineViewController: UIViewController {
    // MARK: Outlets
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var notifierButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    
    // MARK: Status
    
    fileprivate var isCheckingConnectivity: Bool = false
    private var cancellable: AnyCancellable?
}

// IB Actions
@available(iOS 13.0, *)
extension CombineViewController {
    @IBAction func notifierButtonTapped(_: UIButton) {
        isCheckingConnectivity ? stopConnectivityChecks() : startConnectivityChecks()
    }
}

// Private API
@available(iOS 13.0, *)
private extension CombineViewController {
    func startConnectivityChecks() {
        activityIndicator.startAnimating()
        let publisher = Connectivity.Publisher(
            configuration:
                    .init()
                    .configureURLSession(.default)
        ).eraseToAnyPublisher()
        cancellable = publisher.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.activityIndicator.stopAnimating()
                strongSelf.isCheckingConnectivity = false
                strongSelf.updateNotifierButton(isCheckingConnectivity: strongSelf.isCheckingConnectivity)
            }, receiveValue: { [weak self] connectivity in
                self?.updateConnectionStatus(connectivity.status)
            })
        isCheckingConnectivity = true
        updateNotifierButton(isCheckingConnectivity: isCheckingConnectivity)
    }
    
    func stopConnectivityChecks() {
        activityIndicator.stopAnimating()
        cancellable?.cancel()
        isCheckingConnectivity = false
        updateNotifierButton(isCheckingConnectivity: isCheckingConnectivity)
    }
    
    func updateConnectionStatus(_ status: Connectivity.Status) {
        switch status {
        case .connectedViaWiFi, .connectedViaCellular, .connected, .connectedViaEthernet:
            statusLabel.textColor = UIColor.darkGreen
        case .connectedViaWiFiWithoutInternet, .connectedViaCellularWithoutInternet, .connectedViaEthernetWithoutInternet, .notConnected:
            statusLabel.textColor = UIColor.red
        case .determining:
            statusLabel.textColor = UIColor.black
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

#endif
