/// An attribute protocol allows an atom to have a custom refresh ability.
///
/// Note that the custom refresh ability is not triggered when the atom is overridden.
///
/// ```swift
/// struct RandomIntAtom: ValueAtom, Refreshable, Hashable {
///     func value(context: Context) -> Int {
///         0
///     }
///
///     func refresh(context: RefreshContext) async -> Int {
///         try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
///         return .random(in: 0..<100)
///     }
/// }
/// ```
///
public protocol Refreshable where Self: Atom {
    /// A type of the context structure that to read, set, and otherwise interacting
    /// with other atoms.
    typealias RefreshContext = AtomCurrentContext<Loader.Coordinator>

    /// Refreshes and then return a result value.
    ///
    /// The value returned by this method will be cached as a new value when
    /// this atom is refreshed.
    ///
    /// - Parameter context: A context structure that to read, set, and otherwise interacting
    ///                      with other atoms.
    ///
    /// - Returns: A refreshed value.
    @MainActor
    func refresh(context: RefreshContext) async -> Loader.Value
}
