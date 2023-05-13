public extension Atom {
    /// Applies a modifier to an atom and returns a new atom.
    ///
    /// - Parameter modifier: The modifier to apply to this atom.
    /// - Returns: A new atom that is applied the given modifier.
    func modifier<T: AtomModifier>(_ modifier: T) -> ModifiedAtom<Self, T> {
        ModifiedAtom(atom: self, modifier: modifier)
    }
}

/// A modifier that you apply to an atom, producing a  different version
/// of the original value.
public protocol AtomModifier {
    /// A type representing the stable identity of this modifier.
    associatedtype Key: Hashable

    /// A type of base value to be modified.
    associatedtype BaseValue

    /// A type of modified value to provide.
    associatedtype Value

    /// A type of the context structure for notifying modifier value updates.
    typealias Context = AtomModifierContext<Value>

    /// A unique value used to identify the modifier internally.
    var key: Key { get }

    /// Returns a new value for the corresponding atom.
    @MainActor
    func modify(value: BaseValue, context: Context) -> Value

    /// Associates given value and handle updates and cancellations.
    @MainActor
    func associateOverridden(value: Value, context: Context) -> Value

    /// Returns a boolean value indicating whether it should notify updates to downstream
    /// by checking the equivalence of the given old value and new value.
    @MainActor
    func shouldUpdate(newValue: Value, oldValue: Value) -> Bool
}

public extension AtomModifier {
    func shouldUpdate(newValue: Value, oldValue: Value) -> Bool {
        true
    }
}
