import Testing

@testable import ThermalCore

struct ThrottleEvidenceSetTests {
    @Test("An empty set has no status")
    func empty() {
        #expect(ThrottleEvidenceSet().assessment.status == nil)
    }

    @Test("New evidence replaces earlier evidence of the same kind")
    func replacesSameKind() {
        var set = ThrottleEvidenceSet()
        set.update(ThermalPressureLevel.heavy)
        set.update(ThermalPressureLevel.nominal)
        #expect(set.assessment.status == .notThrottled)
    }

    @Test("Uninformative evidence stops older evidence of its kind from counting")
    func unknownReplacesKnown() {
        var set = ThrottleEvidenceSet()
        set.update(ThermalPressureLevel.heavy)
        set.update(ThermalStateLevel.nominal)
        set.update(ThermalPressureLevel.unknown(rawState: 9))
        #expect(set.assessment.status == .notThrottled)
    }

    @Test("Evidence of different kinds is combined")
    func combinesKinds() {
        var set = ThrottleEvidenceSet()
        set.update(ThermalStateLevel.critical)
        #expect(set.assessment.status == .throttled(.critical))
        set.update(ThermalPressureLevel.moderate)
        #expect(set.assessment.status == .throttled(.moderate))
    }
}
