import Testing

@testable import ThermalCore

struct ThermalPressureLevelTests {
    @Test(
        "Maps the macOS notify states",
        arguments: [
            (UInt64(0), ThermalPressureLevel.nominal),
            (1, .moderate),
            (2, .heavy),
            (3, .trapping),
            (4, .sleeping),
        ]
    )
    func mapsKnownStates(rawState: UInt64, expected: ThermalPressureLevel) {
        #expect(ThermalPressureLevel(rawState: rawState) == expected)
    }

    @Test("Keeps unrecognised states, including the iOS scale", arguments: [UInt64(5), 10, 20, 30, 40, 50, .max])
    func keepsUnknownStates(rawState: UInt64) {
        #expect(ThermalPressureLevel(rawState: rawState) == .unknown(rawState: rawState))
    }

    @Test(
        "Reports throttling from moderate pressure upwards",
        arguments: [
            (ThermalPressureLevel.nominal, ThrottleStatus?.some(.notThrottled)),
            (.moderate, .throttled(.moderate)),
            (.heavy, .throttled(.heavy)),
            (.trapping, .throttled(.critical)),
            (.sleeping, .throttled(.critical)),
            (.unknown(rawState: 7), nil),
        ]
    )
    func throttleStatus(level: ThermalPressureLevel, expected: ThrottleStatus?) {
        #expect(level.throttleStatus == expected)
    }

    @Test("Is primary evidence")
    func authority() {
        #expect(ThermalPressureLevel.authority == .primary)
    }

    @Test(
        "Names each level",
        arguments: [
            (ThermalPressureLevel.nominal, "Nominal"),
            (.moderate, "Moderate"),
            (.heavy, "Heavy"),
            (.trapping, "Trapping"),
            (.sleeping, "Sleeping"),
            (.unknown(rawState: 7), "Unrecognized (7)"),
        ]
    )
    func localizedName(level: ThermalPressureLevel, expected: String) {
        #expect(level.localizedName == expected)
    }
}
