import SwiftUI
import ThermalCore

/// How a throttle status looks: its SF Symbol, its semantic colour and its menu bar wording.
///
/// Every status has its own symbol and wording, so colour is never the only cue.
struct ThrottleStatusAppearance {
    /// Every status the app can show; `nil` means no evidence is informative.
    static let allStatuses: [ThrottleStatus?] = [nil, .notThrottled] + ThrottleSeverity.allCases.map { .throttled($0) }

    /// The name of a `thermometer` SF Symbol that identifies the status.
    let symbolName: String

    /// A semantic system colour that reinforces the status.
    let tint: Color

    /// The menu bar item's accessibility label, such as "Mac Thermals, not throttling".
    let menuBarAccessibilityLabel: String

    init(status: ThrottleStatus?) {
        switch status {
        case nil:
            symbolName = "thermometer.medium.slash"
            tint = .secondary
            menuBarAccessibilityLabel = String(
                localized: "Mac Thermals, status unavailable",
                bundle: .module,
                comment: "Menu bar accessibility label when no thermal information is available"
            )
        case .notThrottled:
            symbolName = "thermometer.low"
            tint = .green
            menuBarAccessibilityLabel = String(
                localized: "Mac Thermals, not throttling",
                bundle: .module,
                comment: "Menu bar accessibility label when the Mac isn't throttling"
            )
        case .throttled(.moderate):
            symbolName = "thermometer.medium"
            tint = .yellow
            menuBarAccessibilityLabel = String(
                localized: "Mac Thermals, throttling slightly",
                bundle: .module,
                comment: "Menu bar accessibility label for moderate throttling"
            )
        case .throttled(.heavy):
            symbolName = "thermometer.high"
            tint = .orange
            menuBarAccessibilityLabel = String(
                localized: "Mac Thermals, throttling significantly",
                bundle: .module,
                comment: "Menu bar accessibility label for heavy throttling"
            )
        case .throttled(.critical):
            symbolName = "thermometer.sun.fill"
            tint = .red
            menuBarAccessibilityLabel = String(
                localized: "Mac Thermals, throttling as much as possible",
                bundle: .module,
                comment: "Menu bar accessibility label for critical throttling"
            )
        }
    }
}
