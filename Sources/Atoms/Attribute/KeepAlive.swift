/// An attribute protocol to allow the value of an atom to continue being retained
/// even after they are no longer watched.
///
/// ## Note
///
/// Atoms that conform to this attribute and are either scoped using the ``Scoped`` attribute
/// or overridden via ``AtomScope/scopedOverride(_:with:)-5jen3`` are retained until their scope
/// is dismantled from the view tree, after which they are released.
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
