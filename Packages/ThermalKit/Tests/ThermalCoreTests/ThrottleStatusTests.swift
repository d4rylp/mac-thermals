import Testing

@testable import ThermalCore

struct ThrottleStatusTests {
    @Test("Orders statuses from not throttled to critical")
    func ordering() {
        let ascending: [ThrottleStatus] = [
            .notThrottled,
            .throttled(.moderate),
            .throttled(.heavy),
            .throttled(.critical),
        ]
        #expect(ascending.shuffled().sorted() == ascending)
    }
}
