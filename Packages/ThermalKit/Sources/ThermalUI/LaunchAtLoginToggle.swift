import SwiftUI
import ThermalCore

/// The launch-at-login control, connected to the app model.
struct LaunchAtLoginToggle: View {
    let model: ThermalModel

    var body: some View {
        LaunchAtLoginRow(
            isOn: Binding {
                model.launchAtLoginStatus.isRegistered
            } set: { isEnabled in
                model.setLaunchAtLogin(isEnabled)
            },
            status: model.launchAtLoginStatus,
            failure: model.launchAtLoginFailure,
            openSystemSettings: model.openLoginItemsSettings
        )
    }
}

/// A launch-at-login toggle that reflects the system's actual status, built from plain values.
struct LaunchAtLoginRow: View {
    @Binding var isOn: Bool
    let status: LaunchAtLoginStatus
    let failure: String?
    let openSystemSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $isOn) {
                Text("Launch at login", bundle: .module, comment: "Toggle that registers the app as a login item")
            }
            // A grouped form lays the label out separately from the switch, which then has no
            // accessibility label of its own.
            .accessibilityLabel(
                Text("Launch at login", bundle: .module, comment: "Toggle that registers the app as a login item")
            )
            if let explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if status == .requiresApproval {
                Button(action: openSystemSettings) {
                    Text(
                        "Open Login Items Settings…",
                        bundle: .module,
                        comment: "Button that opens the Login Items pane of System Settings"
                    )
                }
            }
            if let failure {
                Label {
                    Text(failure)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .accessibilityHidden(true)
                }
                .font(.caption)
            }
        }
    }

    private var explanation: String? {
        switch status {
        case .disabled:
            nil
        case .enabled:
            String(
                localized: "Mac Thermals opens automatically when you log in.",
                bundle: .module,
                comment: "Explanation when the app is registered as a login item"
            )
        case .requiresApproval:
            String(
                localized: "Mac Thermals needs your approval in System Settings before it can open at login.",
                bundle: .module,
                comment: "Explanation when the login item awaits the user's approval"
            )
        case .unavailable:
            String(
                localized: """
                    macOS can’t register Mac Thermals as a login item. Move the app to the Applications \
                    folder and try again.
                    """,
                bundle: .module,
                comment: "Explanation when the system can't find the app to register it as a login item"
            )
        }
    }
}

#Preview("Disabled") {
    Form {
        LaunchAtLoginRow(isOn: .constant(false), status: .disabled, failure: nil) {}
    }
    .formStyle(.grouped)
}

#Preview("Enabled") {
    Form {
        LaunchAtLoginRow(isOn: .constant(true), status: .enabled, failure: nil) {}
    }
    .formStyle(.grouped)
}

#Preview("Requires approval") {
    Form {
        LaunchAtLoginRow(isOn: .constant(true), status: .requiresApproval, failure: nil) {}
    }
    .formStyle(.grouped)
}

#Preview("Unavailable") {
    Form {
        LaunchAtLoginRow(
            isOn: .constant(false),
            status: .unavailable,
            failure: "The operation couldn’t be completed. Operation not permitted"
        ) {}
    }
    .formStyle(.grouped)
}
