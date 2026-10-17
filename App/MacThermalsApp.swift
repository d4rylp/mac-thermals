import SwiftUI
import ThermalUI

/// Mac Thermals: a menu bar agent that tells you whether your Mac is thermally throttled.
@main
struct MacThermalsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false

    var body: some Scene {
        MenuBarExtra {
            DashboardView(model: appDelegate.model)
        } label: {
            MenuBarLabel(model: appDelegate.model)
                .modifier(SettingsRequestHandler(requestCount: appDelegate.settingsRequestCount))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: appDelegate.model)
        }

        Window(Text("Welcome to Mac Thermals", comment: "Title of the first-launch window"), id: "welcome") {
            WelcomeView(model: appDelegate.model)
                .onDisappear {
                    hasCompletedWelcome = true
                }
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(hasCompletedWelcome ? .suppressed : .presented)
    }
}

/// Opens Settings whenever the app delegate receives a new reopen request.
///
/// `openSettings` is only available inside the SwiftUI view hierarchy, and the menu bar label is the
/// one view that exists for the app's whole lifetime, so it hosts this modifier.
private struct SettingsRequestHandler: ViewModifier {
    let requestCount: Int
    @Environment(\.openSettings) private var openSettings

    func body(content: Content) -> some View {
        content.onChange(of: requestCount) {
            NSApplication.shared.activate()
            openSettings()
        }
    }
}
