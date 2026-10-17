import Testing
import ThermalCore

@testable import ThermalUI

@MainActor
struct ThermalModelTests {
    @Test("Starts with no readings and no status")
    func initialState() {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .disabled))
        #expect(model.pressureLevel == nil)
        #expect(model.thermalState == nil)
        #expect(model.throttleAssessment.status == nil)
    }

    @Test(
        "Pressure levels drive the assessment",
        arguments: [
            (ThermalPressureLevel.nominal, ThrottleStatus?.some(.notThrottled)),
            (.moderate, .throttled(.moderate)),
            (.heavy, .throttled(.heavy)),
            (.trapping, .throttled(.critical)),
            (.sleeping, .throttled(.critical)),
            (.unknown(rawState: 7), nil),
        ]
    )
    func pressureDrivesAssessment(level: ThermalPressureLevel, expected: ThrottleStatus?) async {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .disabled))
        let pressure = FakePressureSource()
        pressure.continuation.yield(level)
        pressure.continuation.finish()
        await model.observe(pressure)
        #expect(model.pressureLevel == level)
        #expect(model.throttleAssessment.status == expected)
    }

    @Test("The latest pressure level replaces earlier ones")
    func latestPressureWins() async {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .disabled))
        let pressure = FakePressureSource()
        pressure.continuation.yield(.heavy)
        pressure.continuation.yield(.nominal)
        pressure.continuation.finish()
        await model.observe(pressure)
        #expect(model.pressureLevel == .nominal)
        #expect(model.throttleAssessment.status == .notThrottled)
    }

    @Test("The thermal state decides while pressure is unknown")
    func stateIsFallback() async {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .disabled))
        let pressure = FakePressureSource()
        let state = FakeStateSource()
        pressure.continuation.yield(.unknown(rawState: 7))
        pressure.continuation.finish()
        state.continuation.yield(.serious)
        state.continuation.finish()
        await model.observe(pressure)
        await model.observe(state)
        #expect(model.thermalState == .serious)
        #expect(model.throttleAssessment.status == .throttled(.heavy))
    }

    @Test("Known pressure outranks the thermal state")
    func pressureOutranksState() async {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .disabled))
        let pressure = FakePressureSource()
        let state = FakeStateSource()
        state.continuation.yield(.critical)
        state.continuation.finish()
        pressure.continuation.yield(.nominal)
        pressure.continuation.finish()
        await model.observe(state)
        await model.observe(pressure)
        #expect(model.throttleAssessment.status == .notThrottled)
    }

    @Test("Updates arrive while sources keep running")
    func liveUpdates() async {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .disabled))
        let pressure = FakePressureSource()
        let observation = Task { await model.observe(pressure) }
        pressure.continuation.yield(.moderate)
        pressure.continuation.yield(.trapping)
        pressure.continuation.finish()
        await observation.value
        #expect(model.throttleAssessment.status == .throttled(.critical))
    }

    @Test("Reads the login item status at creation")
    func initialLaunchAtLoginStatus() {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .requiresApproval))
        #expect(model.launchAtLoginStatus == .requiresApproval)
    }

    @Test(
        "Enabling launch at login reports the system's resulting status",
        arguments: [LaunchAtLoginStatus.enabled, .requiresApproval]
    )
    func enableLaunchAtLogin(resultingStatus: LaunchAtLoginStatus) {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.statusAfterRegister = resultingStatus
        let model = ThermalModel(launchAtLogin: service)
        model.setLaunchAtLogin(true)
        #expect(model.launchAtLoginStatus == resultingStatus)
        #expect(model.launchAtLoginFailure == nil)
    }

    @Test("Disabling launch at login unregisters")
    func disableLaunchAtLogin() {
        let model = ThermalModel(launchAtLogin: FakeLaunchAtLoginService(status: .enabled))
        model.setLaunchAtLogin(false)
        #expect(model.launchAtLoginStatus == .disabled)
    }

    @Test("A failed change keeps the actual status and explains the failure")
    func failedChange() throws {
        let service = FakeLaunchAtLoginService(status: .disabled)
        service.shouldFail = true
        let model = ThermalModel(launchAtLogin: service)
        model.setLaunchAtLogin(true)
        #expect(model.launchAtLoginStatus == .disabled)
        let failure = try #require(model.launchAtLoginFailure)
        #expect(!failure.isEmpty)

        service.shouldFail = false
        model.setLaunchAtLogin(true)
        #expect(model.launchAtLoginFailure == nil)
        #expect(model.launchAtLoginStatus == .enabled)
    }

    @Test("Refreshing picks up approval given in System Settings")
    func refresh() {
        let service = FakeLaunchAtLoginService(status: .requiresApproval)
        let model = ThermalModel(launchAtLogin: service)
        service.status = .enabled
        model.refreshLaunchAtLoginStatus()
        #expect(model.launchAtLoginStatus == .enabled)
    }

    @Test("Opens Login Items settings through the service")
    func openLoginItemsSettings() {
        let service = FakeLaunchAtLoginService(status: .requiresApproval)
        let model = ThermalModel(launchAtLogin: service)
        model.openLoginItemsSettings()
        #expect(service.openSystemSettingsCount == 1)
    }
}
