//
//  ConnectivityStatusTests.swift
//  Connectivity
//
//  Created by Ross Butler on 10/05/2020.
//  Copyright © 2020 Ross Butler. All rights reserved.
//

@testable import Connectivity
import XCTest

class ConnectivityStatusTests: XCTestCase {
    func testDescriptionForConnectedIsCorrect() {
        let sut = ConnectivityStatus.connected
        XCTAssertEqual(sut.description, "Internet access")
    }

    func testDescriptionForCellularWithInternetIsCorrect() {
        let sut = ConnectivityStatus.connectedViaCellular
        XCTAssertEqual(sut.description, "Cellular with Internet access")
    }

    func testDescriptionForCellularWithoutInternetIsCorrect() {
        let sut = ConnectivityStatus.connectedViaCellularWithoutInternet
        XCTAssertEqual(sut.description, "Cellular without Internet access")
    }

    func testDescriptionForWiFiWithInternetIsCorrect() {
        let sut = ConnectivityStatus.connectedViaWiFi
        XCTAssertEqual(sut.description, "Wi-Fi with Internet access")
    }

    func testDescriptionForWiFiWithoutInternetIsCorrect() {
        let sut = ConnectivityStatus.connectedViaWiFiWithoutInternet
        XCTAssertEqual(sut.description, "Wi-Fi without Internet access")
    }

    func testDescriptionForDeterminingIsCorrect() {
        let sut = ConnectivityStatus.determining
        XCTAssertEqual(sut.description, "Connectivity checks pending")
    }

    func testDescriptionForNoConnectionIsCorrect() {
        let sut = ConnectivityStatus.notConnected
        XCTAssertEqual(sut.description, "No Connection")
    }
}
