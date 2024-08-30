/// Declares that a type can produce a value that can be accessed from everywhere.
///
/// The value produced by an atom is created only when the atom is watched from somewhere,
/// and is immediately released when no longer watched.
public protocol Atom<Produced> {
    /// A type representing the stable identity of this atom.
    associatedtype Key: Hashable

    /// The type of value that this atom produces.
    associatedtype Produced

    /// The type of effect for managing side effects.
    associatedtype Effect: AtomEffect = EmptyEffect

    /// A type of the context structure to read, watch, and otherwise interact
    /// with other atoms.
    typealias Context = AtomTransactionContext

    /// A type of the context structure to read, set, and otherwise interact
    /// with other atoms.
    typealias CurrentContext = AtomCurrentContext

    /// A unique value used to identify the atom.
    ///
    /// This key don't have to be unique with respect to other atoms in the entire application
    /// because it is identified respecting the metatype of this atom.
    /// If this atom conforms to `Hashable`, it will adopt itself as the `key` by default.
    var key: Key { get }

    /// An effect for managing side effects that are synchronized with this atom's lifecycle.
    ///
    /// - Parameter context: A context structure to read, set, and otherwise
    ///                      interact with other atoms.
    ///
    /// - Returns: An effect for managing side effects.
    @MainActor
    func effect(context: CurrentContext) -> Effect

    /// Deprecated. use `Atom.effect(context:)` instead.
    @MainActor
    func updated(newValue: Produced, oldValue: Produced, context: CurrentContext)

    // --- Internal ---

    /// A producer that produces the value of this atom.
    var producer: AtomProducer<Produced> { get }
}

public extension Atom {
    @MainActor
    func effect(context: CurrentContext) -> Effect where Effect == EmptyEffect {
        EmptyEffect()
    }

    @MainActor
    func updated(newValue: Produced, oldValue: Produced, context: CurrentContext) {}
}

public extension Atom where Self == Key {
    var key: Self {
        self
    }
}
