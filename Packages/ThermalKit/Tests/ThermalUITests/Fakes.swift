import ThermalCore

/// A pressure source whose levels the test sends.
struct FakePressureSource: ThermalPressureSource {
    let stream: AsyncStream<ThermalPressureLevel>
    let continuation: AsyncStream<ThermalPressureLevel>.Continuation

    init() {
        (stream, continuation) = AsyncStream<ThermalPressureLevel>.makeStream()
    }

    func pressureLevels() -> AsyncStream<ThermalPressureLevel> {
        stream
    }
}

/// A thermal state source whose states the test sends.
struct FakeStateSource: ThermalStateSource {
    let stream: AsyncStream<ThermalStateLevel>
    let continuation: AsyncStream<ThermalStateLevel>.Continuation

    init() {
        (stream, continuation) = AsyncStream<ThermalStateLevel>.makeStream()
    }

    func thermalStates() -> AsyncStream<ThermalStateLevel> {
        stream
    }
}

/// The error a fake login item service throws when told to fail.
struct FakeLaunchAtLoginError: Error {}

/// A login item service that records calls and follows a scripted status.
@MainActor
final class FakeLaunchAtLoginService: LaunchAtLoginService {
    var status: LaunchAtLoginStatus
    var statusAfterRegister = LaunchAtLoginStatus.enabled
    var shouldFail = false
    private(set) var openSystemSettingsCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        if shouldFail { throw FakeLaunchAtLoginError() }
        status = statusAfterRegister
    }

    func unregister() throws {
        if shouldFail { throw FakeLaunchAtLoginError() }
        status = .disabled
    }

    func openSystemSettings() {
        openSystemSettingsCount += 1
    }
}
