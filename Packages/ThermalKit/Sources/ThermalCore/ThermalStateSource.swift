/// A source of `ProcessInfo` thermal states.
public protocol ThermalStateSource: Sendable {
    /// A stream that yields the current state first and then every change.
    ///
    /// Cancelling iteration releases the underlying observation.
    func thermalStates() -> AsyncStream<ThermalStateLevel>
}
