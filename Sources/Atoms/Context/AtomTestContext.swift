/// A context structure that to read, watch, and otherwise interacting with atoms in testing.
///
/// This context has an internal Store that manages atoms, so it can be used to test individual
/// atoms or their interactions with other atoms without depending on the SwiftUI view tree.
/// Furthermore, unlike other contexts, it is possible to override or observe changes in atoms
/// by this itself.
@MainActor
public struct AtomTestContext: AtomWatchableContext {
    private let container: Container

    /// Creates a new test context instance with fresh internal state.
    public init() {
        container = Container()
    }

    /// A callback to perform when any of atoms watched by this context is updated.
    public var onUpdate: (() -> Void)? {
        get { container.onUpdate }
        nonmutating set { container.onUpdate = newValue }
    }

    /// Accesses the value associated with the given atom without watching to it.
    ///
    /// This method returns a value for the given atom. Even if you access to a value with this method,
    /// it doesn't initiating watch the atom, so if none of other atoms or views is watching as well,
    /// the value will not be cached.
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// print(context.read(TextAtom()))  // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    public func read<Node: Atom>(_ atom: Node) -> Node.Hook.Value {
        container.store.read(atom)
    }

    /// Sets the new value for the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assign a new value for the atom.
    /// When you assign a new value, it notifies update immediately to downstream atoms or views.
    ///
    /// - SeeAlso: ``AtomTestContext/subscript``
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context.set("New text", for: TextAtom())
    /// print(context.read(TextAtom()))  // Prints "New text"
    /// ```
    ///
    /// - Parameters
    ///   - value: A value to be set.
    ///   - atom: An atom that associates the value.
    public func set<Node: Atom>(_ value: Node.Hook.Value, for atom: Node) where Node.Hook: AtomStateHook {
        container.store.set(value, for: atom)
    }

    /// Refreshes and then return the value associated with the given refreshable atom.
    ///
    /// This method only accepts refreshable atoms such as types conforming to:
    /// ``TaskAtom``, ``ThrowingTaskAtom``, ``AsyncSequenceAtom``, ``PublisherAtom``.
    /// It refreshes the value for the given atom and then return, so the caller can await until
    /// the value completes the update.
    /// Note that it can be used only in a context that supports concurrency.
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// let image = await context.refresh(AsyncImageDataAtom()).value
    /// print(image) // Prints the data obtained through network.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value which completed refreshing associated with the given atom.
    @discardableResult
    public func refresh<Node: Atom>(_ atom: Node) async -> Node.Hook.Value where Node.Hook: AtomRefreshableHook {
        await container.store.refresh(atom)
    }

    /// Resets the value associated with the given atom, and then notify.
    ///
    /// This method resets a value for the given atom, and then notify update to the downstream
    /// atoms and views. Thereafter, if any of other atoms or views is watching the atom, a newly
    /// generated value will be produced.
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context[TextAtom()] = "New text"
    /// print(context.read(TextAtom())) // Prints "New text"
    /// context.reset(TextAtom())
    /// print(context.read(TextAtom())) // Prints "Text"
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    public func reset<Node: Atom>(_ atom: Node) {
        container.store.reset(atom)
    }

    /// Accesses the value associated with the given atom for reading and initialing watch to
    /// receive its updates.
    ///
    /// This method returns a value for the given atom and initiate watching the atom so that
    /// the current context to get updated when the atom notifies updates.
    /// The value associated with the atom is cached until it is no longer watched to or until
    /// it is updated.
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// let text = context.watch(TextAtom())
    /// print(text) // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    @discardableResult
    public func watch<Node: Atom>(_ atom: Node) -> Node.Hook.Value {
        container.store.watch(atom, relationship: container.relationship) {
            container.onUpdate?()
        }
    }

    /// Unwatches the given atom and do not receive any more updates of it.
    ///
    /// It simulates cases where other atoms or views no longer watches to the atom.
    ///
    /// - Parameter atom: An atom that associates the value.
    public func unwatch<Node: Atom>(_ atom: Node) {
        container.relationship[atom] = nil
    }

    /// Overrides the atom value with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atom: An atom that to be overridden.
    ///   - value: A value that to be used instead of the atom's value.
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Hook.Value) {
        container.overrides.insert(atom, with: value)
    }

    /// Overrides the atom value with the given value.
    ///
    /// Instead of overriding the particular instance of atom, this method overrides any atom that
    /// has the same metatype.
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atomType: An atom type that to be overridden.
    ///   - value: A value that to be used instead of the atom's value.
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Hook.Value) {
        container.overrides.insert(atomType, with: value)
    }

    /// Observes changes of any atom values and its lifecycles.
    ///
    /// This method registers the given observer to notify changes of any atom values.
    /// It would be useful for monitoring and debugging the atoms and for producing side effects in
    /// the changes of particular atom.
    ///
    /// - SeeAlso: ``AtomObserver``
    ///
    /// - Parameter observer: A observer value to observe atom changes.
    public func observe<Observer: AtomObserver>(_ observer: Observer) {
        container.observers.append(observer)
    }
}

private extension AtomTestContext {
    @MainActor
    final class Container {
        private let storeContainer = StoreContainer()
        private var relationshipContainer = RelationshipContainer()

        var overrides: AtomOverrides
        var observers = [AtomObserver]()
        var onUpdate: (() -> Void)?

        init() {
            overrides = AtomOverrides()
        }

        var store: AtomStore {
            Store(
                container: storeContainer,
                overrides: overrides,
                observers: observers
            )
        }

        var relationship: Relationship {
            Relationship(container: relationshipContainer)
        }
    }
}
