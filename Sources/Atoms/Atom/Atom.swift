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

    // TODO: Rename
    associatedtype State: AtomValue

    /// A type of the context structure that to read, watch, and otherwise interacting
    /// with other atoms.
    typealias Context = AtomRelationContext

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

    /// Creates a new state that is an actual implementation of this atom.
    ///
    /// - Returns: A state object that handles internal process and a value.
    @MainActor
    var value: State { get }

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
    func shouldNotifyUpdate(newValue: State.Value, oldValue: State.Value) -> Bool
}

public extension Atom {
    @MainActor
    func shouldNotifyUpdate(newValue: State.Value, oldValue: State.Value) -> Bool {
        true
    }
}

public extension Atom {
    @MainActor
    static var shouldKeepAlive: Bool {
        false
    }
}

public extension Atom where Self == Key {
    var key: Self { self }
}
