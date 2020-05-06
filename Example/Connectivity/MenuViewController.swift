//
//  MenuViewController.swift
//  Connectivity_Example
//
//  Created by Ross Butler on 05/05/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController: UIViewController {
    @IBOutlet var combineExampleButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            combineExampleButton.isHidden = false
        }
    }
}
