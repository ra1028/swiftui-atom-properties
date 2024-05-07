/// Declares that a type can produce a value that can be accessed from everywhere.
///
/// The value produced by an atom is created only when the atom is watched from somewhere,
/// and is immediately released when no longer watched.
public protocol Atom<Produced>: AtomPrimitive {
    /// The type of value that this atom produces.
    associatedtype Produced

    associatedtype Effect: AtomEffect = EmptyEffect

    @MainActor
    func effect(context: CurrentContext) -> Effect

    // Deprecated. use `Atom.effect(context: CurrentContext)` instead.
    @MainActor
    func updated(newValue: Produced, oldValue: Produced, context: AtomCurrentContext<Coordinator>)

    // --- Internal ---

    /// A producer that produces the value of this atom.
    var producer: AtomProducer<Produced, Coordinator> { get }
}

public extension Atom {
    func makeCoordinator() -> Coordinator where Coordinator == Void {
        ()
    }

    @MainActor
    func effect(context: CurrentContext) -> Effect where Effect == EmptyEffect {
        EmptyEffect()
    }

    func updated(newValue: Produced, oldValue: Produced, context: AtomCurrentContext<Coordinator>) {}
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
