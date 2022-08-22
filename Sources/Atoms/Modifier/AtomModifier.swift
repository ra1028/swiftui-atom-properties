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

    /// A type of original value to be modified.
    associatedtype Value

    /// A type of modified value to provide.
    associatedtype ModifiedValue

    /// A type of the context structure that to interact with an atom store.
    typealias Context = AtomLoaderContext<ModifiedValue>

    /// A unique value used to identify the modifier internally.
    var key: Key { get }

    /// Returns a new value for the corresponding atom.
    @MainActor
    func value(context: Context, with value: Value) -> ModifiedValue

    /// Handles updates or cancellation of the passed value.
    @MainActor
    func handle(context: Context, with value: ModifiedValue) -> ModifiedValue

    /// Returns a boolean value indicating whether it should notify updates to downstream
    /// by checking the equivalence of the given old value and new value.
    @MainActor
    func shouldNotifyUpdate(newValue: ModifiedValue, oldValue: ModifiedValue) -> Bool
}

public extension AtomModifier {
    func shouldNotifyUpdate(newValue: ModifiedValue, oldValue: ModifiedValue) -> Bool {
        true
    }
}
