import AppKit
import Observation
import ThermalPlatform
import ThermalUI

/// Wires the system sources into the app model and handles the app being opened again.
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The app's single source of truth.
    let model = ThermalModel(launchAtLogin: LaunchAtLoginController())

    /// Counts the times the user opened the app again while it was running; each one opens Settings.
    private(set) var settingsRequestCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { await model.observe(ThermalPressureMonitor()) }
        Task { await model.observe(ThermalStateMonitor()) }
    }

    /// Opening the app from Finder or Spotlight while it runs shows Settings, because the menu bar
    /// item may be hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsRequestCount += 1
        return false
    }
}
