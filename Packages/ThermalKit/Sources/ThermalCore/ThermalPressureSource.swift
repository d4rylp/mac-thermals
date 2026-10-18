/// A source of thermal pressure levels.
public protocol ThermalPressureSource: Sendable {
    /// A stream that yields the current level first and then every change.
    ///
    /// The stream ends if the source can't observe the level; cancelling iteration releases the
    /// underlying registration.
    func pressureLevels() -> AsyncStream<ThermalPressureLevel>
}
