import AppKit
import Combine
import SwiftUI
import ThermalCore

/// The Settings window: General and About.
public struct SettingsView: View {
    private let model: ThermalModel

    /// Creates the Settings content.
    ///
    /// - Parameter model: The app model.
    public init(model: ThermalModel) {
        self.model = model
    }

    /// The Settings form.
    public var body: some View {
        Form {
            Section {
                LaunchAtLoginToggle(model: model)
                Text(
                    """
                    Mac Thermals lives in the menu bar as a thermometer icon. If you can’t see it, your \
                    menu bar may be full: look in the menu bar’s overflow, or open Mac Thermals again \
                    from the Applications folder to show this window.
                    """,
                    bundle: .module,
                    comment: "Settings note on finding the menu bar icon"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("General", bundle: .module, comment: "Settings section title")
            }
            Section {
                LabeledContent {
                    Text("\(Self.version) (\(Self.build))", bundle: .module, comment: "App version and build number")
                } label: {
                    Text("Version", bundle: .module, comment: "Settings label for the app version")
                }
                LabeledContent {
                    Text(
                        "[github.com/d4rylp/mac-thermals](https://github.com/d4rylp/mac-thermals)",
                        bundle: .module,
                        comment: "Link to the source code repository"
                    )
                } label: {
                    Text("Source code", bundle: .module, comment: "Settings label for the repository link")
                }
                LabeledContent {
                    Text(
                        "[MIT License](https://github.com/d4rylp/mac-thermals/blob/main/LICENSE)",
                        bundle: .module,
                        comment: "Link to the license text"
                    )
                } label: {
                    Text("License", bundle: .module, comment: "Settings label for the license")
                }
            } header: {
                Text("About", bundle: .module, comment: "Settings section title")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            NSApplication.shared.activate()
            model.refreshLaunchAtLoginStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshLaunchAtLoginStatus()
        }
    }

    private static var version: String {
        infoString(for: "CFBundleShortVersionString")
    }

    private static var build: String {
        infoString(for: "CFBundleVersion")
    }

    private static func infoString(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
            ?? String(localized: "Unknown", bundle: .module, comment: "Shown when the app's version can't be read")
    }
}
