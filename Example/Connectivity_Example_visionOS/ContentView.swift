//
//  ContentView.swift
//  Connectivity_Example_visionOS
//
//  Created by Zandor Smith on 25/09/2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI
import Connectivity

struct ContentView: View {
    private let connectivity = Connectivity(shouldUseHTTPS: false)
    
    var body: some View {
        VStack {
            Text("Hello, world!")
        }
        .padding()
        .onAppear(perform: {
            connectivity.framework = .network
            connectivity.whenConnected = { connectivity in
                print("connectivity11", connectivity.status.description)
            }
            connectivity.whenDisconnected = { connectivity in
                print("connectivity12", connectivity.status.description)
            }
            connectivity.startNotifier()
        })
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
