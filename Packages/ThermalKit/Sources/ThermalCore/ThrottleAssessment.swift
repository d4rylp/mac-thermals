import Foundation

/// A combined verdict on whether the Mac is throttling, with wording for people.
///
/// The assessment uses the informative evidence with the highest ``ThrottleEvidenceAuthority`` and
/// reports the most severe status among it. The result doesn't depend on the order of the evidence.
public struct ThrottleAssessment: Hashable, Sendable {
    /// The combined status, or `nil` when no evidence is informative.
    public let status: ThrottleStatus?

    /// Combines evidence into a single assessment.
    ///
    /// - Parameter evidence: The latest evidence of each kind.
    public init(evidence: some Sequence<any ThrottleEvidence>) {
        let informative = evidence.compactMap { item in
            item.throttleStatus.map { (authority: type(of: item).authority, status: $0) }
        }
        let strongestAuthority = informative.map(\.authority).max()
        status = informative.filter { $0.authority == strongestAuthority }.map(\.status).max()
    }

    /// A short headline, such as "Not throttling".
    public var title: String {
        switch status {
        case nil:
            String(
                localized: "Status unavailable",
                bundle: .module,
                comment: "Headline when macOS isn't reporting any thermal information"
            )
        case .notThrottled:
            String(
                localized: "Not throttling",
                bundle: .module,
                comment: "Headline when the Mac runs at full performance"
            )
        case .throttled:
            String(
                localized: "Throttling",
                bundle: .module,
                comment: "Headline when the Mac reduces performance to cool down"
            )
        }
    }

    /// A plain-language sentence that explains the status.
    public var explanation: String {
        switch status {
        case nil:
            String(
                localized: "macOS isn’t reporting thermal pressure or thermal state right now.",
                bundle: .module,
                comment: "Explanation when no thermal information is available"
            )
        case .notThrottled:
            String(
                localized: "Your Mac is running at full performance.",
                bundle: .module,
                comment: "Explanation when the Mac isn't throttling"
            )
        case .throttled(.moderate):
            String(
                localized: "Your Mac is reducing performance slightly to cool down.",
                bundle: .module,
                comment: "Explanation for moderate throttling"
            )
        case .throttled(.heavy):
            String(
                localized: "Your Mac is reducing performance significantly to cool down.",
                bundle: .module,
                comment: "Explanation for heavy throttling"
            )
        case .throttled(.critical):
            String(
                localized: "Your Mac is reducing performance as much as it can to cool down.",
                bundle: .module,
                comment: "Explanation for critical throttling"
            )
        }
    }
}
