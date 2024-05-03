public extension Atom {
    /// Applies a modifier to an atom and returns a new atom.
    ///
    /// - Parameter modifier: The modifier to apply to this atom.
    /// - Returns: A new atom that is applied the given modifier.
    func modifier<T: AtomModifier>(_ modifier: T) -> ModifiedAtom<Self, T> {
        ModifiedAtom(atom: self, modifier: modifier)
    }
}

/// A modifier that you apply to an atom, producing a new value modified from the original value.
public protocol AtomModifier {
    /// A type representing the stable identity of this modifier.
    associatedtype Key: Hashable

    /// A type to coordinate with the atom.
    associatedtype Coordinator = Void

    /// A type of base value to be modified.
    associatedtype Base

    /// A type of modified value to provide.
    associatedtype Produced

    /// A unique value used to identify the modifier internally.
    var key: Key { get }

    /// Creates the custom coordinator instance that you use to preserve arbitrary state of
    /// the atom.
    ///
    /// It's called when the atom is initialized, and the same instance is preserved until
    /// the atom is no longer used and is deinitialized.
    ///
    /// - Returns: The atom's associated coordinator instance.
    @MainActor
    func makeCoordinator() -> Coordinator

    // --- Internal ---

    func producer(atom: some Atom<Base>) -> AtomProducer<Produced, Coordinator>
}

public extension AtomModifier {
    func makeCoordinator() -> Coordinator where Coordinator == Void {
        ()
    }
}
