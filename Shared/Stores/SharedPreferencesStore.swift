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

    func load(
        availableExamIDs: [String],
        defaultExamID: String?,
        availablePackIDs: [String]
    ) -> IELTSGlancePreferences {
        storage.update { stored in
            (stored ?? .initial(defaultExamID: defaultExamID, availablePackIDs: availablePackIDs))
                .repaired(
                    availableExamIDs: availableExamIDs,
                    defaultExamID: defaultExamID,
                    availablePackIDs: availablePackIDs
                )
        }
    }

    @discardableResult
    func update(
        availableExamIDs: [String],
        defaultExamID: String?,
        availablePackIDs: [String],
        _ transform: (inout IELTSGlancePreferences) -> Void
    ) -> IELTSGlancePreferences {
        storage.update { stored in
            var preferences = (stored ?? .initial(defaultExamID: defaultExamID, availablePackIDs: availablePackIDs))
                .repaired(
                    availableExamIDs: availableExamIDs,
                    defaultExamID: defaultExamID,
                    availablePackIDs: availablePackIDs
                )
            transform(&preferences)
            return preferences.repaired(
                availableExamIDs: availableExamIDs,
                defaultExamID: defaultExamID,
                availablePackIDs: availablePackIDs
            )
        }
    }
}
