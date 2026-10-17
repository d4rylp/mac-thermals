import Darwin
import Dispatch
import ThermalCore
import os

/// Observes the system thermal pressure level through Darwin notify.
///
/// The monitor reads the `com.apple.system.thermalpressurelevel` notify key, declared as
/// `kOSThermalNotificationPressureLevelName` in `<libkern/OSThermalNotification.h>`. It doesn't poll:
/// the current level comes from `notify_register_check` and `notify_get_state`, and changes are
/// pushed by `notify_register_dispatch`.
public struct ThermalPressureMonitor: ThermalPressureSource {
    private static let logger = Logger(subsystem: Log.subsystem, category: "ThermalPressureMonitor")
    private static let queue = DispatchQueue(label: "io.github.d4rylp.MacThermals.ThermalPressureMonitor")

    /// Creates a monitor.
    public init() {}

    /// A stream that yields the current level first and then every change.
    ///
    /// The stream ends immediately if the system refuses the registration; the failure is logged.
    /// Cancelling iteration cancels the notify registration.
    public func pressureLevels() -> AsyncStream<ThermalPressureLevel> {
        AsyncStream { continuation in
            var dispatchToken: Int32 = NOTIFY_TOKEN_INVALID
            let registration = notify_register_dispatch(
                kOSThermalNotificationPressureLevelName,
                &dispatchToken,
                Self.queue
            ) { token in
                if let level = Self.level(token: token) {
                    continuation.yield(level)
                }
            }
            guard registration == NOTIFY_STATUS_OK else {
                Self.logger.error("notify_register_dispatch failed with status \(registration)")
                continuation.finish()
                return
            }
            let registeredToken = dispatchToken
            continuation.onTermination = { _ in
                notify_cancel(registeredToken)
            }
            // Read the initial level on the same serial queue as the change handler, so the last
            // value yielded always reflects the latest state.
            Self.queue.async {
                if let level = Self.currentLevel() {
                    continuation.yield(level)
                }
            }
        }
    }

    /// Reads the current level with a short-lived check registration.
    private static func currentLevel() -> ThermalPressureLevel? {
        var checkToken: Int32 = NOTIFY_TOKEN_INVALID
        let registration = notify_register_check(kOSThermalNotificationPressureLevelName, &checkToken)
        guard registration == NOTIFY_STATUS_OK else {
            logger.error("notify_register_check failed with status \(registration)")
            return nil
        }
        defer { notify_cancel(checkToken) }
        return level(token: checkToken)
    }

    /// Reads the state attached to a registration token.
    private static func level(token: Int32) -> ThermalPressureLevel? {
        var state: UInt64 = 0
        let status = notify_get_state(token, &state)
        guard status == NOTIFY_STATUS_OK else {
            logger.error("notify_get_state failed with status \(status)")
            return nil
        }
        return ThermalPressureLevel(rawState: state)
    }
}
