import Foundation

enum SharedConstants {
    static let widgetKind = "GREGlanceWidget"
    static let displayedWordCount = 5
    static let stateDefaultsKey = "ieltsGlance.currentWidgetDisplayState.v1"
    static let stateFileDefaultsKey = "ieltsGlance.currentWidgetDisplayState.v2"
    static let preferencesDefaultsKey = "ieltsGlance.preferences.v1"

    static let usesAppGroup = false

    static func stateDefaults() -> UserDefaults {
        return .standard
    }

    static func defaultsStorageLockURL() -> URL? {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first
        return baseURL?.appendingPathComponent(
            "IELTSGlance-local-defaults.lock",
            isDirectory: false
        )
    }

    static func migrateJSONFileToDefaultsIfNeeded(
        fileName: String,
        defaultsKey: String,
        defaults: UserDefaults
    ) {
        guard defaults.data(forKey: defaultsKey) == nil,
              let directory = applicationSupportDirectoryURL(),
              let data = try? Data(contentsOf: directory.appendingPathComponent(fileName)) else {
            return
        }
        defaults.set(data, forKey: defaultsKey)
        defaults.synchronize()
    }

    static func applicationSupportDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        let baseURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first

        guard let directory = baseURL?.appendingPathComponent(
            "IELTSGlance",
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
