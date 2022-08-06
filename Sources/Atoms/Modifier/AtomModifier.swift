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
    associatedtype Coordinator
    associatedtype Value
    associatedtype ModifiedValue

    /// A type of the context structure that to interact with internal store.
    typealias Context = AtomHookContext<Coordinator>

    /// A unique value used to identify the modifier internally.
    var key: Key { get }

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    ///
    /// - Parameters:
    ///   - newValue: The new value after update.
    ///   - oldValue: The old value before update.
    ///
    /// - Returns: A boolean value that determines whether it should notify the value update
    ///            to watchers.
    @MainActor
    func shouldNotifyUpdate(newValue: ModifiedValue, oldValue: ModifiedValue) -> Bool

    /// Creates a coordinator instance.
    @MainActor
    func makeCoordinator() -> Coordinator

    /// Gets the value with the given context.
    @MainActor
    func get(context: Context) -> ModifiedValue?

    /// Sets a value with the given context.
    @MainActor
    func set(value: ModifiedValue, context: Context)

    /// Starts updating the current value by modifying the given value.
    @MainActor
    func update(context: Context, with value: Value)
}

public extension AtomModifier {
    @MainActor
    func shouldNotifyUpdate(newValue: ModifiedValue, oldValue: ModifiedValue) -> Bool {
        true
    }
}
