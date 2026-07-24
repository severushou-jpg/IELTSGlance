import Foundation

struct IELTSGlancePreferences: Codable, Equatable, Sendable {
    var schemaVersion: Int? = 4
    var selectedExamID: String?
    var selectedPackIDs: [String]
    var defaultTextSize: WidgetTextSize
    var synonymLimit: Int

    static func initial(defaultExamID: String?, availablePackIDs: [String]) -> IELTSGlancePreferences {
        IELTSGlancePreferences(
            selectedExamID: defaultExamID,
            selectedPackIDs: Array(availablePackIDs.prefix(1)),
            defaultTextSize: .comfortable,
            synonymLimit: 3
        )
    }

    func repaired(
        availableExamIDs: [String],
        defaultExamID: String?,
        availablePackIDs: [String]
    ) -> IELTSGlancePreferences {
        let repairedExamID: String?
        if let selectedExamID, availableExamIDs.contains(selectedExamID) {
            repairedExamID = selectedExamID
        } else {
            repairedExamID = defaultExamID ?? availableExamIDs.first
        }

        let available = Set(availablePackIDs)
        var seen = Set<String>()
        var selected = selectedPackIDs.filter {
            available.contains($0) && seen.insert($0).inserted
        }
        if selected.isEmpty, let first = availablePackIDs.first {
            selected = [first]
        }

        var repairedTextSize = defaultTextSize == .followApp ? .comfortable : defaultTextSize
        if repairedTextSize == .legacyExtraLarge {
            repairedTextSize = .comfortable
        }

        return IELTSGlancePreferences(
            schemaVersion: 4,
            selectedExamID: repairedExamID,
            selectedPackIDs: selected,
            defaultTextSize: repairedTextSize,
            synonymLimit: min(max(synonymLimit, 1), 3)
        )
    }
}
