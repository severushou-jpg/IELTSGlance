//
//  GREGlanceApp.swift
//  GREGlance
//
//  Created by severushou on 2026/7/16.
//

import SwiftUI
import WidgetKit

@main
struct GREGlanceApp: App {
    @State private var store = AppWordStore()

    init() {
        // Refresh the desktop Widget when a newly built app replaces an older
        // locally registered extension.
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
    }

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
