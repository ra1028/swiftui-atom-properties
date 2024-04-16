/// An attribute protocol to allow the value of an atom to continue being retained
/// even after they are no longer watched.
///
/// Note that overridden or scoped atoms are not retained even with this attribute.
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
