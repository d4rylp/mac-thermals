import SwiftUI
import ThermalCore

/// The dropdown panel shown from the menu bar item.
public struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    private let model: ThermalModel

    /// Creates the panel.
    ///
    /// - Parameter model: The app model.
    public init(model: ThermalModel) {
        self.model = model
    }

    /// The panel's content.
    public var body: some View {
        DashboardContent(
            assessment: model.throttleAssessment,
            pressureLevel: model.pressureLevel,
            thermalState: model.thermalState
        )
        .onExitCommand { dismiss() }
    }
}
