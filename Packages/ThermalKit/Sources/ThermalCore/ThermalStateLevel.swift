import Foundation

/// The coarse thermal state that `ProcessInfo` reports.
///
/// The thermal state is less precise than ``ThermalPressureLevel``: on some Macs both moderate and
/// heavy pressure report as ``fair``. It is used as fallback evidence when the pressure level carries
/// no information.
public enum ThermalStateLevel: Hashable, Sendable {
    /// The thermal state is within normal limits.
    case nominal
    /// The thermal state is slightly elevated.
    case fair
    /// The thermal state is high.
    case serious
    /// The thermal state is significantly impacting the performance of the system.
    case critical
    /// A thermal state this version of the app doesn't recognise.
    case unknown(rawValue: Int)

    /// Creates a level from the state `ProcessInfo` reports.
    ///
    /// - Parameter state: The value of `ProcessInfo.processInfo.thermalState`.
    public init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .unknown(rawValue: state.rawValue)
        }
    }

    /// The state's name as shown in secondary text, such as "Fair".
    public var localizedName: String {
        switch self {
        case .nominal:
            String(localized: "Nominal", bundle: .module, comment: "Thermal pressure level or thermal state name")
        case .fair:
            String(localized: "Fair", bundle: .module, comment: "Thermal state name")
        case .serious:
            String(localized: "Serious", bundle: .module, comment: "Thermal state name")
        case .critical:
            String(localized: "Critical", bundle: .module, comment: "Thermal state name")
        case .unknown(let rawValue):
            String(
                localized: "Unrecognized (\(rawValue))",
                bundle: .module,
                comment: "Thermal state the app doesn't recognise; the number is the raw state"
            )
        }
    }
}

extension ThermalStateLevel: ThrottleEvidence {
    /// The thermal state is coarse, so it only decides when no primary evidence is informative.
    public static var authority: ThrottleEvidenceAuthority { .fallback }

    /// Nominal means no throttling; fair and above mean throttling. An unrecognised state carries no
    /// information.
    public var throttleStatus: ThrottleStatus? {
        switch self {
        case .nominal: .notThrottled
        case .fair: .throttled(.moderate)
        case .serious: .throttled(.heavy)
        case .critical: .throttled(.critical)
        case .unknown: nil
        }
    }
}
