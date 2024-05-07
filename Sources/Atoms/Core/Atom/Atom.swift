/// Declares that a type can produce a value that can be accessed from everywhere.
///
/// The value produced by an atom is created only when the atom is watched from somewhere,
/// and is immediately released when no longer watched.
public protocol Atom<Produced>: AtomPrimitive {
    /// The type of value that this atom produces.
    associatedtype Produced

    /// Notifies the atom that the associated value is updated.
    ///
    /// Use it to manage arbitrary side-effects of value updates, such as state persistence,
    /// state synchronization, logging, and etc.
    /// You can also access other atom values via `context` passed as a parameter.
    ///
    /// - Parameters:
    ///   - newValue: A new value after update.
    ///   - oldValue: An old value before update.
    ///   - context: A context structure to read, set, and otherwise
    ///              interact with other atoms.
    @MainActor
    func updated(newValue: Produced, oldValue: Produced, context: UpdatedContext)

    // --- Internal ---

    /// A producer that produces the value of this atom.
    var producer: AtomProducer<Produced, Coordinator> { get }
}

public extension Atom {
    func makeCoordinator() -> Coordinator where Coordinator == Void {
        ()
    }

    func updated(newValue: Produced, oldValue: Produced, context: UpdatedContext) {}
}

public extension Atom where Self == Key {
    var key: Self {
        self
    }
}

/// Declares primitive components of an atom.
public protocol AtomPrimitive {
    /// A type representing the stable identity of this atom.
    associatedtype Key: Hashable

    /// A type of the coordinator that you use to preserve arbitrary state of this atom.
    associatedtype Coordinator = Void

    /// A type of the context structure to read, watch, and otherwise interact
    /// with other atoms.
    typealias Context = AtomTransactionContext<Coordinator>

    /// A type of the context structure to read, set, and otherwise interact
    /// with other atoms.
    typealias CurrentContext = AtomCurrentContext<Coordinator>

    /// A type of the context structure to read, set, and otherwise interact
    /// with other atoms.
    typealias UpdatedContext = AtomCurrentContext<Coordinator>

    /// A unique value used to identify the atom.
    ///
    /// This key don't have to be unique with respect to other atoms in the entire application
    /// because it is identified respecting the metatype of this atom.
    /// If this atom conforms to `Hashable`, it will adopt itself as the `key` by default.
    var key: Key { get }

    /// Creates a coordinator instance that you use to preserve arbitrary state of this atom.
    ///
    /// It's called when the atom is initialized, and the same instance is preserved until
    /// the atom is no longer used and is deinitialized.
    ///
    /// - Returns: The atom's associated coordinator instance.
    @MainActor
    func makeCoordinator() -> Coordinator
}