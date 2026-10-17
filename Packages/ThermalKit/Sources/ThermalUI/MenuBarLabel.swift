import SwiftUI
import ThermalCore

/// The menu bar item: a monochrome template SF Symbol that changes with the throttle status.
public struct MenuBarLabel: View {
    private let model: ThermalModel

    /// Creates the label.
    ///
    /// - Parameter model: The app model.
    public init(model: ThermalModel) {
        self.model = model
    }

    /// The label's content.
    public var body: some View {
        let appearance = ThrottleStatusAppearance(status: model.throttleAssessment.status)
        Image(systemName: appearance.symbolName)
            .accessibilityLabel(Text(appearance.menuBarAccessibilityLabel))
    }
}
