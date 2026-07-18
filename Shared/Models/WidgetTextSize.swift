import AppIntents
import Foundation

enum WidgetTextSize: String, Codable, CaseIterable, AppEnum, Sendable {
    case followApp
    case comfortable
    case large
    case extraLarge

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Text Size"

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .followApp: "Follow App Setting",
        .comfortable: "Comfortable",
        .large: "Large",
        .extraLarge: "Extra Large"
    ]

    static let appSelectableCases: [Self] = [.comfortable, .large, .extraLarge]

    var displayName: String {
        switch self {
        case .followApp: "跟随 App 设置"
        case .comfortable: "舒适"
        case .large: "大"
        case .extraLarge: "特大"
        }
    }

    func resolved(defaultSize: WidgetTextSize) -> WidgetTextSize {
        self == .followApp ? defaultSize.resolvedDefault : resolvedDefault
    }

    var resolvedDefault: WidgetTextSize {
        self == .followApp ? .extraLarge : self
    }

    var wordFontSize: CGFloat {
        switch resolvedDefault {
        case .comfortable: 16.5
        case .large: 18
        case .extraLarge, .followApp: 20
        }
    }

    var meaningFontSize: CGFloat {
        switch resolvedDefault {
        case .comfortable: 13
        case .large: 14
        case .extraLarge, .followApp: 15.5
        }
    }

    var exampleFontSize: CGFloat {
        switch resolvedDefault {
        case .comfortable: 11
        case .large: 11.5
        case .extraLarge, .followApp: 12
        }
    }
}
