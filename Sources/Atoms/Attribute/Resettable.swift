/// An attribute protocol that allows an atom to have a custom reset behavior.
///
/// It is useful when creating a wrapper atom and you want to transparently reset the atom underneath.
/// Note that the custom reset will not be triggered when the atom is overridden.
///
/// ```swift
/// struct UserAtom: ValueAtom, Resettable, Hashable {
///     func value(context: Context) -> AsyncPhase<User?, Never> {
///         context.watch(FetchUserAtom().phase)
///     }
///
///     func reset(context: ResetContext) {
///         context.reset(FetchUserAtom())
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
public protocol Resettable where Self: Atom {
    /// A type of the context structure to read, set, and otherwise interact
    /// with other atoms.
    typealias ResetContext = AtomCurrentContext<Loader.Coordinator>

    /// Arbitrary reset method to be executed on atom reset.
    ///
    /// This is arbitrary custom reset method that replaces regular atom reset functionality.
    ///
    /// - Parameter context: A context structure to read, set, and otherwise interact
    ///                      with other atoms.
    @MainActor
    func reset(context: ResetContext)
}
