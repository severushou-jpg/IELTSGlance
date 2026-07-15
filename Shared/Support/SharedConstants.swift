import Foundation
import Security

enum SharedConstants {
    static let widgetKind = "GREGlanceWidget"
    static let displayedWordCount = 5
    static let stateDefaultsKey = "greGlance.currentWidgetDisplayState.v1"

    static var appGroupIdentifier: String? {
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

    static var stateModeDescription: String {
        usesAppGroup ? "App Group 共享状态" : "本地独立状态"
    }
}
