import AppIntents
import Foundation

enum WidgetTextSize: String, Codable, CaseIterable, AppEnum, Sendable {
    case followApp = "followApp"
    case comfortable = "comfortable"
    case large = "large"
    /// Decodes Widget configurations saved before the typography fix. It is
    /// intentionally omitted from `allCases` and resolves to Comfortable.
    case legacyExtraLarge = "extraLarge"
    case extraLarge = "extraLargeV2"

    static let allCases: [WidgetTextSize] = [.followApp, .comfortable, .large, .extraLarge]

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Text Size"

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .followApp: "Comfortable (Legacy)",
        .comfortable: "Comfortable",
        .large: "Large",
        .legacyExtraLarge: "Comfortable (Migrated)",
        .extraLarge: "Extra Large"
    ]

    static let appSelectableCases: [Self] = [.comfortable, .large, .extraLarge]

    var displayName: String {
        switch self {
        case .followApp: "舒适（旧版跟随设置）"
        case .comfortable: "舒适"
        case .large: "大"
        case .legacyExtraLarge: "舒适（已迁移）"
        case .extraLarge: "特大"
        }
    }

    func resolved(defaultSize: WidgetTextSize) -> WidgetTextSize {
        switch self {
        case .followApp:
            defaultSize.resolvedDefault
        case .legacyExtraLarge:
            .comfortable
        default:
            resolvedDefault
        }
    }

    var resolvedDefault: WidgetTextSize {
        switch self {
        case .followApp, .legacyExtraLarge:
            .comfortable
        default:
            self
        }
    }

    var wordFontSize: CGFloat {
        switch resolvedDefault {
        case .comfortable, .legacyExtraLarge: 16.5
        case .large: 18
        case .extraLarge: 20
        case .followApp: 16.5
        }
    }

    var meaningFontSize: CGFloat {
        switch resolvedDefault {
        case .comfortable, .legacyExtraLarge: 13
        case .large: 14
        case .extraLarge: 15.5
        case .followApp: 13
        }
    }

    var exampleFontSize: CGFloat {
        switch resolvedDefault {
        case .comfortable, .legacyExtraLarge: 11
        case .large: 11.5
        case .extraLarge: 12
        case .followApp: 11
        }
    }
}
