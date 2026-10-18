import Observation
import ThermalCore
import os

/// The app's single source of truth, read by the menu bar label, the dashboard panel and Settings.
///
/// Each source feeds the model through its own `observe(_:)` overload, which the app starts once at
/// launch. Views read the model's members and change it only through its intent methods.
@MainActor
@Observable
public final class ThermalModel {
    private static let logger = Logger(subsystem: Log.subsystem, category: "ThermalModel")

    /// The latest thermal pressure level, or `nil` if no level has been reported.
    public private(set) var pressureLevel: ThermalPressureLevel?

    /// The latest `ProcessInfo` thermal state, or `nil` if no state has been reported.
    public private(set) var thermalState: ThermalStateLevel?

    /// Whether the app is registered to open at login, as last read from the system.
    public private(set) var launchAtLoginStatus: LaunchAtLoginStatus

    /// A description of the last failed attempt to change the login item, cleared by the next
    /// successful one.
    public private(set) var launchAtLoginFailure: String?

    private var throttleEvidence = ThrottleEvidenceSet()

    @ObservationIgnored private let launchAtLogin: any LaunchAtLoginService

    /// Creates a model.
    ///
    /// - Parameter launchAtLogin: The service that registers the app as a login item.
    public init(launchAtLogin: any LaunchAtLoginService) {
        self.launchAtLogin = launchAtLogin
        launchAtLoginStatus = launchAtLogin.status
    }

    /// Whether the Mac is throttling, combined from all current evidence.
    public var throttleAssessment: ThrottleAssessment {
        throttleEvidence.assessment
    }

    /// Records every thermal pressure level the source reports, until its stream ends.
    ///
    /// - Parameter source: The source of thermal pressure levels.
    public func observe(_ source: some ThermalPressureSource) async {
        for await level in source.pressureLevels() {
            pressureLevel = level
            throttleEvidence.update(level)
        }
    }

    /// Records every thermal state the source reports, until its stream ends.
    ///
    /// - Parameter source: The source of thermal states.
    public func observe(_ source: some ThermalStateSource) async {
        for await state in source.thermalStates() {
            thermalState = state
            throttleEvidence.update(state)
        }
    }

    /// Registers or unregisters the app as a login item, then reads the resulting status.
    ///
    /// - Parameter isEnabled: Whether the app should open at login.
    public func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try launchAtLogin.register()
            } else {
                try launchAtLogin.unregister()
            }
            launchAtLoginFailure = nil
        } catch {
            Self.logger.error("Changing the login item failed: \(error.localizedDescription, privacy: .public)")
            launchAtLoginFailure = error.localizedDescription
        }
        refreshLaunchAtLoginStatus()
    }

    /// Reads the login item status again, for example after the user returns from System Settings.
    public func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLogin.status
    }

    /// Opens the Login Items pane of System Settings, where the user approves login items.
    public func openLoginItemsSettings() {
        launchAtLogin.openSystemSettings()
    }
}
