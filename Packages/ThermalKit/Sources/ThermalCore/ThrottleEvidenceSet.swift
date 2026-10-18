/// The latest evidence of each kind, from which the current ``ThrottleAssessment`` is derived.
///
/// Updating the set with a value replaces the previous value of the same type, so evidence never
/// accumulates and a source that becomes uninformative stops influencing the assessment.
public struct ThrottleEvidenceSet: Sendable {
    private var evidenceByKind: [ObjectIdentifier: any ThrottleEvidence] = [:]

    /// Creates an empty set.
    public init() {}

    /// Records the latest evidence of its kind, replacing any earlier evidence of the same type.
    ///
    /// - Parameter evidence: The newest evidence.
    public mutating func update<Evidence: ThrottleEvidence>(_ evidence: Evidence) {
        evidenceByKind[ObjectIdentifier(Evidence.self)] = evidence
    }

    /// The assessment derived from the evidence currently in the set.
    public var assessment: ThrottleAssessment {
        ThrottleAssessment(evidence: evidenceByKind.values)
    }
}
