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

    /// A type of base value to be modified.
    associatedtype Base

    /// A type of value the modified atom produces.
    associatedtype Produced

    /// A unique value used to identify the modifier internally.
    var key: Key { get }

    // --- Internal ---

    /// A producer that produces the value of this atom.
    func producer(atom: some Atom<Base>) -> AtomProducer<Produced>
}
