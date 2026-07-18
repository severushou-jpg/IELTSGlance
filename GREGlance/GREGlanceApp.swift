//
//  GREGlanceApp.swift
//  GREGlance
//
//  Created by severushou on 2026/7/16.
//

import SwiftUI

@main
struct GREGlanceApp: App {
    @State private var store = AppWordStore()

    var body: some Scene {
        WindowGroup("GRE Glance", id: "main") {
            ContentView(store: store)
        }
        .defaultSize(width: 900, height: 820)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView(store: store)
        }
    }
}
