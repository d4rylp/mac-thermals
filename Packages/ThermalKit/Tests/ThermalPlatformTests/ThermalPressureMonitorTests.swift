import Testing
import ThermalCore
import ThermalPlatform

struct ThermalPressureMonitorTests {
    @Test("Yields a recognised macOS level as soon as iteration starts")
    func yieldsCurrentLevel() async throws {
        var levels = ThermalPressureMonitor().pressureLevels().makeAsyncIterator()
        let level = try #require(await levels.next())
        let recognised: [ThermalPressureLevel] = [.nominal, .moderate, .heavy, .trapping, .sleeping]
        #expect(recognised.contains(level))
    }

    @Test("Iteration ends when its task is cancelled")
    func endsOnCancellation() async {
        let iteration = Task {
            for await _ in ThermalPressureMonitor().pressureLevels() {}
        }
        iteration.cancel()
        await iteration.value
    }
}
