/// An attribute protocol allows an atom to have a custom reset ability.
///
/// Note that the custom reset ability is possible even when the atom is overridden.
///
/// ```swift
/// struct RandomIntAtom: ValueAtom, Resettable, Hashable {
///     func value(context: Context) -> Int {
///          context.watch(RandomSeedAtom()).integer()
///     }
///
///     func reset(context: ResetContext) {
///          context.reset(RandomSeedAtom())
///     }
/// }
/// ```
///
public protocol Resettable where Self: Atom {
    /// A type of the context structure to read, set, and otherwise interact
    /// with other atoms.
    typealias ResetContext = AtomCurrentContext<Loader.Coordinator>

    /// Resets the atom value.
    ///
    /// The value after reset will be cached as a new value.
    ///
    /// - Parameter context: A context structure to read, set, and otherwise interact
    ///                      with other atoms.
    @MainActor
    func reset(context: ResetContext)
}
