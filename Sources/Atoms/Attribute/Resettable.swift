/// An attribute protocol allows an atom to have a custom reset override.
///
/// Note that the custom reset will be triggered even when the atom is overridden.
///
/// ```swift
/// struct UserAtom: ValueAtom, Resettable, Hashable {
///     func value(context: Context) -> User? {
///          context.watch(FetchUserAtom()).phase.value
///     }
///
///     func reset(context: ResetContext) {
///          context.reset(FetchUserAtom())
///     }
/// }
///
/// private struct FetchUserAtom: TaskAtom, Hashable {
///     func value(context: Context) async -> User? {
///          await fetchUser()
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
