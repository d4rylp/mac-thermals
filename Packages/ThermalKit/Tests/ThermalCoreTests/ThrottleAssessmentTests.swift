import Testing

@testable import ThermalCore

struct ThrottleAssessmentTests {
    @Test(
        "Pressure decides whenever it is known",
        arguments: [
            (ThermalPressureLevel.nominal, ThermalStateLevel.fair, ThrottleStatus.notThrottled),
            (.nominal, .critical, .notThrottled),
            (.moderate, .nominal, .throttled(.moderate)),
            (.heavy, .fair, .throttled(.heavy)),
            (.trapping, .serious, .throttled(.critical)),
            (.sleeping, .nominal, .throttled(.critical)),
        ]
    )
    func pressureIsPrimary(pressure: ThermalPressureLevel, state: ThermalStateLevel, expected: ThrottleStatus) {
        let evidence: [any ThrottleEvidence] = [pressure, state]
        #expect(ThrottleAssessment(evidence: evidence).status == expected)
        #expect(ThrottleAssessment(evidence: evidence.reversed()).status == expected)
    }

    @Test(
        "The thermal state decides when pressure is unknown",
        arguments: [
            (ThermalStateLevel.nominal, ThrottleStatus.notThrottled),
            (.fair, .throttled(.moderate)),
            (.serious, .throttled(.heavy)),
            (.critical, .throttled(.critical)),
        ]
    )
    func stateIsFallback(state: ThermalStateLevel, expected: ThrottleStatus) {
        let evidence: [any ThrottleEvidence] = [ThermalPressureLevel.unknown(rawState: 9), state]
        #expect(ThrottleAssessment(evidence: evidence).status == expected)
    }

    @Test("The thermal state decides when there is no pressure evidence")
    func stateAlone() {
        let evidence: [any ThrottleEvidence] = [ThermalStateLevel.serious]
        #expect(ThrottleAssessment(evidence: evidence).status == .throttled(.heavy))
    }

    @Test("No informative evidence gives no status")
    func noInformation() {
        let unknown: [any ThrottleEvidence] = [
            ThermalPressureLevel.unknown(rawState: 9),
            ThermalStateLevel.unknown(rawValue: 9),
        ]
        #expect(ThrottleAssessment(evidence: unknown).status == nil)
        #expect(ThrottleAssessment(evidence: [any ThrottleEvidence]()).status == nil)
    }

    @Test("The most severe status wins among evidence of equal authority")
    func mostSevereAmongEqualAuthority() {
        let evidence: [any ThrottleEvidence] = [
            ThermalPressureLevel.moderate,
            ThermalPressureLevel.trapping,
            ThermalPressureLevel.nominal,
        ]
        #expect(ThrottleAssessment(evidence: evidence).status == .throttled(.critical))
    }

    @Test(
        "Titles and explanations describe the status",
        arguments: [
            (
                [any ThrottleEvidence](), "Status unavailable",
                "macOS isn’t reporting thermal pressure or thermal state right now."
            ),
            ([ThermalPressureLevel.nominal], "Not throttling", "Your Mac is running at full performance."),
            (
                [ThermalPressureLevel.moderate], "Throttling",
                "Your Mac is reducing performance slightly to cool down."
            ),
            (
                [ThermalPressureLevel.heavy], "Throttling",
                "Your Mac is reducing performance significantly to cool down."
            ),
            (
                [ThermalPressureLevel.sleeping], "Throttling",
                "Your Mac is reducing performance as much as it can to cool down."
            ),
        ]
    )
    func wording(evidence: [any ThrottleEvidence], title: String, explanation: String) {
        let assessment = ThrottleAssessment(evidence: evidence)
        #expect(assessment.title == title)
        #expect(assessment.explanation == explanation)
    }
}
