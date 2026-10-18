/// How strongly the Mac is reducing performance to cool down.
public enum ThrottleSeverity: Int, Comparable, CaseIterable, Sendable {
    /// Performance is reduced slightly.
    case moderate = 1
    /// Performance is reduced significantly.
    case heavy = 2
    /// Performance is reduced as far as the system allows.
    case critical = 3

    /// Orders severities from the least to the most severe.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
