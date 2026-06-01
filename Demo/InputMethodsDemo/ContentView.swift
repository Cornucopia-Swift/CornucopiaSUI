//
//  ContentView.swift
//  InputMethodsDemo
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 1

    var body: some View {
        TabView(selection: $selection) {
            HexKeyboardDemoView()
                .tabItem {
                    Label("Hex", systemImage: "number")
                }
                .tag(0)

            VINKeyboardDemoView()
                .tabItem {
                    Label("VIN", systemImage: "car")
                }
                .tag(1)

            NetworkKeyboardDemoView()
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
