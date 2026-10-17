import AppKit
import SwiftUI
import ThermalCore

/// The first-launch window: what the app does, where it lives, and an optional login item.
public struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    private let model: ThermalModel

    /// Creates the welcome content.
    ///
    /// - Parameter model: The app model.
    public init(model: ThermalModel) {
        self.model = model
    }

    /// The welcome content.
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "thermometer.medium")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Welcome to Mac Thermals", bundle: .module, comment: "Welcome window headline")
                .font(.title)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
            Text(
                "Mac Thermals tells you when your Mac is throttling: reducing its performance to cool down.",
                bundle: .module,
                comment: "Welcome window: what the app does"
            )
            .fixedSize(horizontal: false, vertical: true)
            Text(
                """
                It lives in the menu bar as a thermometer icon. If your menu bar is full, the icon \
                may be in the menu bar’s overflow. You can always open Mac Thermals again from the \
                Applications folder to show its settings.
                """,
                bundle: .module,
                comment: "Welcome window: where the app lives"
            )
            .fixedSize(horizontal: false, vertical: true)
            LaunchAtLoginToggle(model: model)
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Continue", bundle: .module, comment: "Welcome window button that closes the window")
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            NSApplication.shared.activate()
        }
    }
}
