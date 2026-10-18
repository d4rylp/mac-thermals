import Testing

@testable import ThermalCore

struct LaunchAtLoginStatusTests {
    @Test(
        "Counts approved and pending registrations as registered",
        arguments: [
            (LaunchAtLoginStatus.disabled, false),
            (.enabled, true),
            (.requiresApproval, true),
            (.unavailable, false),
        ]
    )
    func isRegistered(status: LaunchAtLoginStatus, expected: Bool) {
        #expect(status.isRegistered == expected)
    }
}
