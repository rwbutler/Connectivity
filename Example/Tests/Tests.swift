import UIKit
import XCTest
import OHHTTPStubs
@testable import Connectivity

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }
    
    func testSuccessfulConnectivityCheckUsingSysConfig() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("success-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.framework = .systemConfiguration
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFi)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
    func testSuccessfulConnectivityCheckUsingNetwork() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("success-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity check succeeds")
        let connectivity = Connectivity()
        connectivity.framework = .systemConfiguration
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFi)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
    func testFailedConnectivityCheckUsingSysConfig() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("failure-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity checks fails")
        let connectivity = Connectivity()
        connectivity.framework = .network
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFiWithoutInternet)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
    func testFailedConnectivityCheckUsingNetwork() {
        stub(condition: isHost("www.apple.com")) { _ in
            let stubPath = OHPathForFile("failure-response.html", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "text/html"])
        }
        let expectation = XCTestExpectation(description: "Connectivity checks fails")
        let connectivity = Connectivity()
        connectivity.framework = .network
        let connectivityChanged: (Connectivity) -> Void = { connectivity in
            XCTAssert(connectivity.status == .connectedViaWiFiWithoutInternet)
            expectation.fulfill()
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
        connectivity.startNotifier()
        wait(for: [expectation], timeout: 1.0)
        connectivity.stopNotifier()
    }
    
}
