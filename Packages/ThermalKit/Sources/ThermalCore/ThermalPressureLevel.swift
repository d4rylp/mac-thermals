import Foundation

/// The system-wide thermal pressure level that macOS publishes through Darwin notify.
///
/// macOS posts the level under the `com.apple.system.thermalpressurelevel` notify key, declared in
/// `<libkern/OSThermalNotification.h>`. On macOS the state values are 0 (nominal), 1 (moderate),
/// 2 (heavy), 3 (trapping) and 4 (sleeping). iOS uses a different scale (0, 10, 20, 30, 40, 50), so
/// this mapping must not be reused for other platforms.
///
/// Thermal pressure is the primary evidence of throttling: macOS reduces performance from the
/// moderate level upwards.
public enum ThermalPressureLevel: Hashable, Sendable {
    /// No thermal pressure: the system runs without thermal limits.
    case nominal
    /// The system has started limiting performance to manage heat.
    case moderate
    /// The system is significantly limiting performance.
    case heavy
    /// The system is limiting performance as much as it can while still running.
    case trapping
    /// The system is about to sleep to protect itself from heat.
    case sleeping
    /// A state value this version of the app doesn't recognise.
    case unknown(rawState: UInt64)

    /// Creates a level from the raw state of the thermal pressure notify key.
    ///
    /// - Parameter rawState: The value returned by `notify_get_state` for the key.
    public init(rawState: UInt64) {
        switch rawState {
        case 0: self = .nominal
        case 1: self = .moderate
        case 2: self = .heavy
        case 3: self = .trapping
        case 4: self = .sleeping
        default: self = .unknown(rawState: rawState)
        }
    }

    /// The level's name as shown in secondary text, such as "Moderate".
    public var localizedName: String {
        switch self {
        case .nominal:
            String(localized: "Nominal", bundle: .module, comment: "Thermal pressure level or thermal state name")
        case .moderate:
            String(localized: "Moderate", bundle: .module, comment: "Thermal pressure level name")
        case .heavy:
            String(localized: "Heavy", bundle: .module, comment: "Thermal pressure level name")
        case .trapping:
            String(localized: "Trapping", bundle: .module, comment: "Thermal pressure level name")
        case .sleeping:
            String(localized: "Sleeping", bundle: .module, comment: "Thermal pressure level name")
        case .unknown(let rawState):
            String(
                localized: "Unrecognized (\(rawState))",
                bundle: .module,
                comment: "Thermal pressure level the app doesn't recognise; the number is the raw level"
            )
        }
    }
}

extension ThermalPressureLevel: ThrottleEvidence {
    /// Thermal pressure is the most direct signal macOS gives about throttling.
    public static var authority: ThrottleEvidenceAuthority { .primary }

    /// Nominal pressure means no throttling; moderate and above mean throttling. An unrecognised
    /// level carries no information.
    public var throttleStatus: ThrottleStatus? {
        switch self {
        case .nominal: .notThrottled
        case .moderate: .throttled(.moderate)
        case .heavy: .throttled(.heavy)
        case .trapping, .sleeping: .throttled(.critical)
        case .unknown: nil
        }
    }
}
