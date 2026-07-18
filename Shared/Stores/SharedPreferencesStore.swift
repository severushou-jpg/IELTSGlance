import Foundation

final class SharedPreferencesStore: @unchecked Sendable {
    private let storage: SharedJSONFileStorage<GREGlancePreferences>

    init(defaults: UserDefaults? = nil) {
        storage = SharedJSONFileStorage(
            fileName: "preferences-v1.json",
            defaultsKey: SharedConstants.preferencesDefaultsKey,
            defaults: defaults
        )
    }

    func load(availablePackIDs: [String]) -> GREGlancePreferences {
        storage.update { stored in
            (stored ?? .initial(availablePackIDs: availablePackIDs))
                .repaired(availablePackIDs: availablePackIDs)
        }
    }

    @discardableResult
    func update(
        availablePackIDs: [String],
        _ transform: (inout GREGlancePreferences) -> Void
    ) -> GREGlancePreferences {
        storage.update { stored in
            var preferences = (stored ?? .initial(availablePackIDs: availablePackIDs))
                .repaired(availablePackIDs: availablePackIDs)
            transform(&preferences)
            return preferences.repaired(availablePackIDs: availablePackIDs)
        }
    }
}
