/// Declares that a type can produce a value that can be accessed from everywhere.
///
/// In summary, this protocol declares a hook that determines the behavioral details
/// of this atom and a key determines the value uniqueness.
/// The value produced by an atom is created only when the atom is watched from somewhere,
/// and is immediately released when no longer watched to.
///
/// If the atom value needs to be preserved even if no longer watched to, you can consider
/// conform the ``KeepAlive`` protocol to the atom.
public protocol Atom {
    /// A type representing the stable identity of this atom.
    associatedtype Key: Hashable

    /// A type of the hook that determines behavioral details.
    associatedtype Hook: AtomHook

    /// A type of the context structure that to read, watch, and otherwise interacting
    /// with other atoms.
    typealias Context = AtomRelationContext

    /// A boolean value indicating whether the atom value should be preserved even if
    /// no longer watched to.
    ///
    /// It's recommended to conform the ``KeepAlive`` to this atom, instead of overriding
    /// this property to return `true`.
    /// The default is `false`.
    @MainActor
    static var shouldKeepAlive: Bool { get }

    /// A unique value used to identify the atom internally.
    ///
    /// This key don't have to be unique with respect to other atoms in the entire application
    /// because it is identified respecting the metatype of this atom.
    /// If this atom conforms to `Hashable`, it will adopt itself as the `key` by default.
    var key: Key { get }

    /// Internal use, the hook for managing the state of this atom.
    @MainActor
    var hook: Hook { get }

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
    func shouldNotifyUpdate(newValue: Hook.Value, oldValue: Hook.Value) -> Bool
}

public extension Atom {
    @MainActor
    func shouldNotifyUpdate(newValue: Hook.Value, oldValue: Hook.Value) -> Bool {
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
