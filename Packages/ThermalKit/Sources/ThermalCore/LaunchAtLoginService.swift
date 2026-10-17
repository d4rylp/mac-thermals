/// Registers and unregisters the app as a login item.
///
/// The service is driven by controls in Settings and the welcome window, so it is isolated to the
/// main actor.
@MainActor
public protocol LaunchAtLoginService {
    /// The current registration status, read from the system each time.
    var status: LaunchAtLoginStatus { get }

    /// Registers the app so it opens at login.
    ///
    /// - Throws: The system's error if registration fails.
    func register() throws

    /// Unregisters the app so it no longer opens at login.
    ///
    /// - Throws: The system's error if unregistration fails.
    func unregister() throws

    /// Opens the Login Items pane of System Settings, where the user approves login items.
    func openSystemSettings()
}
