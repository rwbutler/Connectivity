//
//  ConnectivityPercentageTests.swift
//  Connectivity
//
//  Created by Ross Butler on 10/05/2020.
//  Copyright © 2020 Ross Butler. All rights reserved.
//

@testable import Connectivity
import XCTest

class ConnectivityPercentageTests: XCTestCase {
    func testMidRangeValueApplied() {
        let sut = ConnectivityPercentage(50.0)
        XCTAssertEqual(sut.value, 50.0)
    }

    func testLowerBoundaryValueApplied() {
        let sut = ConnectivityPercentage(0.0)
        XCTAssertEqual(sut.value, 0.0)
    }

    func testUpperBoundaryValueApplied() {
        let sut = ConnectivityPercentage(100.0)
        XCTAssertEqual(sut.value, 100.0)
    }

    func testOutOfLowerBoundValueNotApplied() {
        let sut = ConnectivityPercentage(-0.1)
        XCTAssertEqual(sut.value, 0.0)
    }

    func testOutOfUpperBoundValueNotApplied() {
        let sut = ConnectivityPercentage(100.1)
        XCTAssertEqual(sut.value, 100.0)
    }

    func testConnectivityPercentageCalculatedWithMidRangeUIntValues() {
        let sut = ConnectivityPercentage(UInt(2), outOf: UInt(10))
        XCTAssertEqual(sut.value, 20.0)
    }

    func testConnectivityPercentageCalculatedWithLowerBoundaryUIntValues() {
        let sut = ConnectivityPercentage(UInt(0), outOf: UInt(1))
        XCTAssertEqual(sut.value, 0.0)
    }

    func testConnectivityPercentageCalculatedIsZeroWhenDivisorIsZero() {
        let sut = ConnectivityPercentage(UInt(1), outOf: UInt(0))
        XCTAssertEqual(sut.value, 0.0)
    }

    func testConnectivityPercentageNotLessThanSameValue() {
        XCTAssertFalse(ConnectivityPercentage(0.0) < ConnectivityPercentage(0.0))
    }

    func testConnectivityPercentageIsLessThanGreaterValue() {
        XCTAssertTrue(ConnectivityPercentage(0.0) < ConnectivityPercentage(0.1))
    }
}
