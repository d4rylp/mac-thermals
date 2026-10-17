import Foundation
import Testing

@testable import ThermalCore

struct ThermalStateLevelTests {
    @Test(
        "Wraps the ProcessInfo thermal states",
        arguments: [
            (ProcessInfo.ThermalState.nominal, ThermalStateLevel.nominal),
            (.fair, .fair),
            (.serious, .serious),
            (.critical, .critical),
        ]
    )
    func wrapsKnownStates(state: ProcessInfo.ThermalState, expected: ThermalStateLevel) {
        #expect(ThermalStateLevel(state) == expected)
    }

    @Test(
        "Reports throttling from the fair state upwards",
        arguments: [
            (ThermalStateLevel.nominal, ThrottleStatus?.some(.notThrottled)),
            (.fair, .throttled(.moderate)),
            (.serious, .throttled(.heavy)),
            (.critical, .throttled(.critical)),
            (.unknown(rawValue: 9), nil),
        ]
    )
    func throttleStatus(level: ThermalStateLevel, expected: ThrottleStatus?) {
        #expect(level.throttleStatus == expected)
    }

    @Test("Is fallback evidence")
    func authority() {
        #expect(ThermalStateLevel.authority == .fallback)
    }

    @Test(
        "Names each state",
        arguments: [
            (ThermalStateLevel.nominal, "Nominal"),
            (.fair, "Fair"),
            (.serious, "Serious"),
            (.critical, "Critical"),
            (.unknown(rawValue: 9), "Unrecognized (9)"),
        ]
    )
    func localizedName(level: ThermalStateLevel, expected: String) {
        #expect(level.localizedName == expected)
    }
}
