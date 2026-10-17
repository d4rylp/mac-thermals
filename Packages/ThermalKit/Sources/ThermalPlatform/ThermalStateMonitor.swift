import Foundation
import ThermalCore

/// Observes `ProcessInfo.thermalState` through `ProcessInfo.thermalStateDidChangeNotification`.
public struct ThermalStateMonitor: ThermalStateSource {
    /// Creates a monitor.
    public init() {}

    /// A stream that yields the current state first and then every change.
    ///
    /// Cancelling iteration removes the notification observer.
    public func thermalStates() -> AsyncStream<ThermalStateLevel> {
        AsyncStream { continuation in
            let observer = ThermalStateObserver(continuation: continuation)
            NotificationCenter.default.addObserver(
                observer,
                selector: #selector(ThermalStateObserver.thermalStateDidChange(_:)),
                name: ProcessInfo.thermalStateDidChangeNotification,
                object: nil
            )
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
            observer.yieldCurrentState()
        }
    }
}

/// Forwards thermal state notifications into a stream.
///
/// Notifications arrive on arbitrary threads, so every read of the state happens on one serial queue
/// and the last value yielded always reflects the latest state.
private final class ThermalStateObserver: NSObject, Sendable {
    private static let queue = DispatchQueue(label: "io.github.d4rylp.MacThermals.ThermalStateMonitor")
    private let continuation: AsyncStream<ThermalStateLevel>.Continuation

    init(continuation: AsyncStream<ThermalStateLevel>.Continuation) {
        self.continuation = continuation
    }

    func yieldCurrentState() {
        Self.queue.async { [continuation] in
            continuation.yield(ThermalStateLevel(ProcessInfo.processInfo.thermalState))
        }
    }

    @objc func thermalStateDidChange(_ notification: Notification) {
        yieldCurrentState()
    }
}
