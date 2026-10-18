/// A piece of information about whether the Mac is throttling.
///
/// Each kind of evidence (thermal pressure, thermal state, and in later versions clock speeds)
/// conforms to this protocol. ``ThrottleAssessment`` combines evidence without knowing the concrete
/// types, so a new kind of evidence is added by adding a new conforming type.
public protocol ThrottleEvidence: Sendable {
    /// How much weight this kind of evidence carries relative to other kinds.
    static var authority: ThrottleEvidenceAuthority { get }

    /// What this evidence says about throttling, or `nil` when it carries no information right now.
    var throttleStatus: ThrottleStatus? { get }
}

/// How much weight a kind of ``ThrottleEvidence`` carries.
///
/// Only the informative evidence with the highest authority decides the assessment; evidence with a
/// lower authority is consulted when nothing more authoritative is informative.
public enum ThrottleEvidenceAuthority: Int, Comparable, Sendable {
    /// Coarse evidence used when no primary evidence is informative.
    case fallback = 0
    /// Direct evidence of throttling.
    case primary = 1

    /// Orders authorities from the least to the most authoritative.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
