/// An attribute protocol to allow the value of an atom to continue being retained
/// even after they are no longer watched to.
///
/// Note that overridden atoms are not retained even with this attribute.
///
/// ## Example
///
/// ```swift
/// struct SharedPollingServiceAtom: ValueAtom, KeepAlive, Hashable {
///     func value(context: Context) -> PollingService {
///         PollingService()
///     }
/// }
/// ```
///
public protocol KeepAlive where Self: Atom {}
