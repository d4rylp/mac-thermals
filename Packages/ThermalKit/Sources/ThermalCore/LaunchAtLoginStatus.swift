/// Whether the app opens automatically when the user logs in.
public enum LaunchAtLoginStatus: Hashable, Sendable {
    /// The app isn't registered as a login item.
    case disabled
    /// The app is registered and opens at login.
    case enabled
    /// The app is registered, but the user must approve it in System Settings before it opens at
    /// login.
    case requiresApproval
    /// The system can't register the app as a login item, for example because it can't find the
    /// app's bundle.
    case unavailable

    /// Whether the app is registered as a login item, approved or not.
    public var isRegistered: Bool {
        switch self {
        case .enabled, .requiresApproval: true
        case .disabled, .unavailable: false
        }
    }
}
