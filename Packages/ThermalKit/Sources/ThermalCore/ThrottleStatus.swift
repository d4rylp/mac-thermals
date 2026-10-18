/// Whether the Mac is reducing performance to cool down.
public enum ThrottleStatus: Hashable, Comparable, Sendable {
    /// The Mac is running without thermal limits.
    case notThrottled
    /// The Mac is reducing performance with the given severity.
    case throttled(ThrottleSeverity)

    /// Orders statuses from the least to the most severe: not throttled comes first, then
    /// throttling by increasing severity.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.notThrottled, .notThrottled): false
        case (.notThrottled, .throttled): true
        case (.throttled, .notThrottled): false
        case (.throttled(let lhsSeverity), .throttled(let rhsSeverity)): lhsSeverity < rhsSeverity
        }
    }
}
