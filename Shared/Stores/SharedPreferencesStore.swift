import Foundation

final class SharedPreferencesStore: @unchecked Sendable {
    private let storage: SharedJSONFileStorage<IELTSGlancePreferences>

    init(defaults: UserDefaults? = nil) {
        let resolvedDefaults = defaults ?? SharedConstants.stateDefaults()
        if defaults == nil {
            SharedConstants.migrateJSONFileToDefaultsIfNeeded(
                fileName: "preferences-v1.json",
                defaultsKey: SharedConstants.preferencesDefaultsKey,
                defaults: resolvedDefaults
            )
        }
        storage = SharedJSONFileStorage(
            fileName: "preferences-v1.json",
            defaultsKey: SharedConstants.preferencesDefaultsKey,
            defaults: resolvedDefaults,
            lockURL: defaults == nil ? SharedConstants.defaultsStorageLockURL() : nil
        )
    }

    func load(availablePackIDs: [String]) -> IELTSGlancePreferences {
        storage.update { stored in
            (stored ?? .initial(availablePackIDs: availablePackIDs))
                .repaired(availablePackIDs: availablePackIDs)
        }
    }

    @discardableResult
    func update(
        availablePackIDs: [String],
        _ transform: (inout IELTSGlancePreferences) -> Void
    ) -> IELTSGlancePreferences {
        storage.update { stored in
            var preferences = (stored ?? .initial(availablePackIDs: availablePackIDs))
                .repaired(availablePackIDs: availablePackIDs)
            transform(&preferences)
            return preferences.repaired(availablePackIDs: availablePackIDs)
        }
    }
}
