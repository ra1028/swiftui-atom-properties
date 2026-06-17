/// An error indicating that an awaited condition was not met within the specified timeout
/// while interacting with atoms through ``AtomTestContext``.
///
/// This error is thrown by the throwing `within:` variants of the wait functions on
/// ``AtomTestContext`` such as ``AtomTestContext/waitForUpdate(within:)`` and
/// ``AtomTestContext/wait(for:within:until:)`` when the timeout elapses before the
/// expected update or state is observed.
public struct AtomTestContextTimeoutError: Error, CustomStringConvertible {
    /// The timeout duration, in seconds, that the wait was allowed before timing out.
    public let timeout: Double

    /// Creates a new timeout error with the given timeout duration.
    ///
    /// - Parameter timeout: The timeout duration, in seconds, that elapsed before timing out.
    public init(timeout: Double) {
        self.timeout = timeout
    }

    public var description: String {
        "The wait timed out after \(timeout) second(s)."
    }
}
