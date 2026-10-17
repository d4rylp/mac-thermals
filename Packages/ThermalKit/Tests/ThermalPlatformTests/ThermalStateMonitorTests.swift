import Foundation
import Testing
import ThermalCore
import ThermalPlatform

struct ThermalStateMonitorTests {
    @Test("Yields the current ProcessInfo state as soon as iteration starts")
    func yieldsCurrentState() async throws {
        var states = ThermalStateMonitor().thermalStates().makeAsyncIterator()
        let state = try #require(await states.next())
        #expect(state == ThermalStateLevel(ProcessInfo.processInfo.thermalState))
    }

    @Test("Iteration ends when its task is cancelled")
    func endsOnCancellation() async {
        let iteration = Task {
            for await _ in ThermalStateMonitor().thermalStates() {}
        }
        iteration.cancel()
        await iteration.value
    }
}
