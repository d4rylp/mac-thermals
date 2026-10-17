import ServiceManagement
import ThermalCore
import os

/// Registers the app as a login item with `SMAppService.mainApp`.
public struct LaunchAtLoginController: LaunchAtLoginService {
    private static let logger = Logger(subsystem: Log.subsystem, category: "LaunchAtLoginController")

    /// Creates a controller for the main app.
    public init() {}

    /// The main app's registration status as the system reports it now.
    public var status: LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered: .disabled
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .unavailable
        @unknown default: .unavailable
        }
    }

    /// Registers the main app so it opens at login.
    ///
    /// - Throws: The error from `SMAppService.register()`.
    public func register() throws {
        try SMAppService.mainApp.register()
        Self.logger.info("Registered as a login item")
    }

    /// Unregisters the main app so it no longer opens at login.
    ///
    /// - Throws: The error from `SMAppService.unregister()`.
    public func unregister() throws {
        try SMAppService.mainApp.unregister()
        Self.logger.info("Unregistered as a login item")
    }

    /// Opens the Login Items pane of System Settings.
    public func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
