/// An attribute protocol that allows an atom to have a custom refresh behavior.
///
/// It is useful when creating a wrapper atom and you want to transparently refresh the atom underneath.
/// Note that the custom refresh will not be triggered when the atom is overridden.
///
/// ```swift
/// struct UserAtom: ValueAtom, Refreshable, Hashable {
///     func value(context: Context) -> AsyncPhase<User?, Never> {
///         context.watch(FetchUserAtom().phase)
///     }
///
///     func refresh(context: RefreshContext) async -> AsyncPhase<User?, Never> {
///         await context.refresh(FetchUserAtom().phase)
///     }
/// }
///
/// private struct FetchUserAtom: TaskAtom, Hashable {
///     func value(context: Context) async -> User? {
///         await fetchUser()
///     }
/// }
/// ```
///
public protocol Refreshable where Self: Atom {
    /// A type of the context structure to read, set, and otherwise interact
    /// with other atoms.
    typealias RefreshContext = AtomCurrentContext<Loader.Coordinator>

    /// Refreshes and then return a result value.
    ///
    /// The value returned by this method will be cached as a new value when
    /// this atom is refreshed.
    ///
    /// - Parameter context: A context structure to read, set, and otherwise interact
    ///                      with other atoms.
    ///
    /// - Returns: A refreshed value.
    @MainActor
    func refresh(context: RefreshContext) async -> Loader.Value
}
