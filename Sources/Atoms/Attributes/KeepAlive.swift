/// A marker protocol that indicates that the value of atoms conform with this protocol
/// will continue to be retained even after they are no longer watched to.
///
/// Note that this protocol doesn't apply to overridden atoms.
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
