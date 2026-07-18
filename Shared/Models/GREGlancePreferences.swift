import Foundation

struct GREGlancePreferences: Codable, Equatable, Sendable {
    var selectedPackIDs: [String]
    var defaultTextSize: WidgetTextSize
    var synonymLimit: Int

    static func initial(availablePackIDs: [String]) -> GREGlancePreferences {
        GREGlancePreferences(
            selectedPackIDs: Array(availablePackIDs.prefix(1)),
            defaultTextSize: .extraLarge,
            synonymLimit: 3
        )
    }

    func repaired(availablePackIDs: [String]) -> GREGlancePreferences {
        let available = Set(availablePackIDs)
        var seen = Set<String>()
        var selected = selectedPackIDs.filter {
            available.contains($0) && seen.insert($0).inserted
        }
        if selected.isEmpty, let first = availablePackIDs.first {
            selected = [first]
        }

        return GREGlancePreferences(
            selectedPackIDs: selected,
            defaultTextSize: defaultTextSize.resolvedDefault,
            synonymLimit: min(max(synonymLimit, 1), 3)
        )
    }
}
