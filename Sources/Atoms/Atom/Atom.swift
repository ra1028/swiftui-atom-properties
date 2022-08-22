/// Declares that a type can produce a value that can be accessed from everywhere.
///
/// The value produced by an atom is created only when the atom is watched from somewhere,
/// and is immediately released when no longer watched to.
///
/// If the atom value needs to be preserved even if no longer watched to, you can consider
/// conform the ``KeepAlive`` protocol to the atom.
public protocol Atom {
    /// A type representing the stable identity of this atom.
    associatedtype Key: Hashable

    /// A loader type that represents an actual implementation of the corresponding atom.
    associatedtype Loader: AtomLoader

    /// A type of the context structure that to read, watch, and otherwise interacting
    /// with other atoms.
    typealias Context = AtomTransactionContext

    /// A boolean value indicating whether the atom value should be preserved even if
    /// no longer watched to.
    ///
    /// It's recommended to conform the ``KeepAlive`` to this atom, instead of overriding
    /// this property to return `true`.
    /// The default is `false`.
    static var shouldKeepAlive: Bool { get }

    /// A unique value used to identify the atom internally.
    ///
    /// This key don't have to be unique with respect to other atoms in the entire application
    /// because it is identified respecting the metatype of this atom.
    /// If this atom conforms to `Hashable`, it will adopt itself as the `key` by default.
    var key: Key { get }

    /// A loader that represents an actual implementation of the corresponding atom.
    @MainActor
    var _loader: Loader { get }
}

public extension Atom {
    static var shouldKeepAlive: Bool {
        false
    }
}

public extension Atom where Self == Key {
    var key: Self { self }
}
