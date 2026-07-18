import Foundation
import Security

enum SharedConstants {
    static let widgetKind = "GREGlanceWidget"
    static let displayedWordCount = 5
    static let stateDefaultsKey = "greGlance.currentWidgetDisplayState.v1"
    static let stateFileDefaultsKey = "greGlance.currentWidgetDisplayState.v2"
    static let preferencesDefaultsKey = "greGlance.preferences.v1"

    static var appGroupIdentifier: String? {
        if let configured = Bundle.main.object(
            forInfoDictionaryKey: "GREGlanceAppGroupIdentifier"
        ) as? String,
           !configured.isEmpty {
            return configured
        }

        guard var bundleIdentifier = Bundle.main.bundleIdentifier, !bundleIdentifier.isEmpty else {
            return nil
        }

        if bundleIdentifier.hasSuffix(".GREGlanceWidget") {
            bundleIdentifier.removeLast(".GREGlanceWidget".count)
        }
        return "group.\(bundleIdentifier).shared"
    }

    static var usesAppGroup: Bool {
        guard let identifier = appGroupIdentifier,
              let task = SecTaskCreateFromSelf(nil),
              let groups = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.security.application-groups" as CFString,
                nil
              ) as? [String] else {
            return false
        }
        return groups.contains(identifier)
    }

    static func stateDefaults() -> UserDefaults {
        if usesAppGroup,
           let identifier = appGroupIdentifier,
           let sharedDefaults = UserDefaults(suiteName: identifier) {
            return sharedDefaults
        }
        return .standard
    }

    static func applicationSupportDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        let baseURL: URL?

        if usesAppGroup,
           let identifier = appGroupIdentifier,
           let groupURL = fileManager.containerURL(
               forSecurityApplicationGroupIdentifier: identifier
           ) {
            baseURL = groupURL
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
        } else {
            baseURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        }

        guard let directory = baseURL?.appendingPathComponent(
            "GREGlance",
            isDirectory: true
        ) else {
            return nil
        }

        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            return directory
        } catch {
            return nil
        }
    }

    static var stateModeDescription: String {
        usesAppGroup ? "App Group 共享状态" : "本地独立状态"
    }
}
