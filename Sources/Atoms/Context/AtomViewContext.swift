import SwiftUI

/// A context structure to read, watch, and otherwise interact with atoms.
///
/// When an atom is watched through this context, and that atom is updated,
/// the view where this context is used will be rebuilt.
@MainActor
public struct AtomViewContext: AtomWatchableContext {
    @usableFromInline
    internal let _store: StoreContext
    @usableFromInline
    internal let _subscriber: Subscriber
    @usableFromInline
    internal let _subscription: Subscription

    internal init(
        store: StoreContext,
        subscriber: Subscriber,
        subscription: Subscription
    ) {
        _store = store
        _subscriber = subscriber
        _subscription = subscription
    }

    /// Accesses the value associated with the given atom without watching it.
    ///
    /// This method returns a value for the given atom. Accessing the atom value with this method
    /// does not initiate watching the atom, so if none of the other atoms or views are watching,
    /// the value will not be cached.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.read(TextAtom()))  // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom to read.
    ///
    /// - Returns: The value associated with the given atom.
    @inlinable
    public func read<Node: Atom>(_ atom: Node) -> Node.Produced {
        _store.read(atom)
    }

    /// Sets the new value for the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assigns a new value for the atom.
    /// When you assign a new value, it immediately notifies downstream atoms and views.
    ///
    /// - SeeAlso: ``AtomContext/subscript(_:)``
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context.set("New text", for: TextAtom())
    /// print(context.read(TextAtom()))  // Prints "New text"
    /// ```
    ///
    /// - Parameters:
    ///   - value: A value to be set.
    ///   - atom: A writable atom to update.
    @inlinable
    public func set<Node: StateAtom>(_ value: Node.Produced, for atom: Node) {
        _store.set(value, for: atom)
    }

    /// Modifies the cached value of the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assigns a new value for the atom.
    /// When you modify the value, it notifies downstream atoms and views after all
    /// modifications are completed.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context.modify(TextAtom()) { text in
    ///     text.append(" modified")
    /// }
    /// print(context.read(TextAtom()))  // Prints "Text modified"
    /// ```
    ///
    /// - Parameters:
    ///   - atom: A writable atom to modify.
    ///   - body: A value modification body.
    @inlinable
    public func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Produced) -> Void) {
        _store.modify(atom, body: body)
    }

    /// Refreshes and then returns the value associated with the given refreshable atom.
    ///
    /// This method accepts only asynchronous atoms such as types conforming to:
    /// ``TaskAtom``, ``ThrowingTaskAtom``, ``AsyncSequenceAtom``, ``PublisherAtom``.
    /// It refreshes the value for the given atom and then returns, so the caller can await until
    /// the atom completes the update.
    /// Note that it can be used only in a context that supports concurrency.
    ///
    /// ```swift
    /// let context = ...
    /// let image = await context.refresh(AsyncImageDataAtom()).value
    /// print(image) // Prints the data obtained through the network.
    /// ```
    ///
    /// - Parameter atom: An atom to refresh.
    ///
    /// - Returns: The value after the refreshing associated with the given atom is completed.
    @inlinable
    @_disfavoredOverload
    @discardableResult
    public func refresh<Node: AsyncAtom>(_ atom: Node) async -> Node.Produced {
        await _store.refresh(atom)
    }

    /// Refreshes and then returns the value associated with the given refreshable atom.
    ///
    /// This method only accepts atoms that conform to ``Refreshable`` protocol.
    /// It refreshes the value with the custom refresh behavior, so the caller can await until
    /// the atom completes the update.
    /// Note that it can be used only in a context that supports concurrency.
    ///
    /// ```swift
    /// let context = ...
    /// let value = await context.refresh(CustomRefreshableAtom())
    /// print(value)
    /// ```
    ///
    /// - Parameter atom: An atom to refresh.
    ///
    /// - Returns: The value after the refreshing associated with the given atom is completed.
    @available(*, deprecated, message: "`Refreshable` is deprecated. Use a custom refresh function or other alternatives instead.")
    @inlinable
    @discardableResult
    public func refresh<Node: Refreshable>(_ atom: Node) async -> Node.Produced {
        await _store.refresh(atom)
    }

    /// Resets the value associated with the given atom, and then notifies.
    ///
    /// This method resets the value for the given atom and then notifies downstream
    /// atoms and views. Thereafter, if any other atoms or views are watching the atom, a newly
    /// generated value will be produced.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context[TextAtom()] = "New text"
    /// print(context.read(TextAtom())) // Prints "New text"
    /// context.reset(TextAtom())
    /// print(context.read(TextAtom())) // Prints "Text"
    /// ```
    ///
    /// - Parameter atom: An atom to reset.
    @inlinable
    @_disfavoredOverload
    public func reset(_ atom: some Atom) {
        _store.reset(atom)
    }

    /// Calls arbitrary reset function of the given atom.
    ///
    /// This method only accepts atoms that conform to ``Resettable`` protocol.
    /// Calls custom reset function of the given atom. Hence, it does not generate any new cache value or notify subscribers.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(ResettableTextAtom()) // Prints "Text"
    /// context[ResettableTextAtom()] = "New text"
    /// print(context.read(ResettableTextAtom())) // Prints "New text"
    /// context.reset(ResettableTextAtom()) // Calls the custom reset function
    /// print(context.read(ResettableTextAtom())) // Prints "New text"
    /// ```
    ///
    /// - Parameter atom: An atom to reset.
    @available(*, deprecated, message: "`Resettable` is deprecated. Use a custom reset function or other alternatives instead.")
    @inlinable
    public func reset(_ atom: some Resettable) {
        _store.reset(atom)
    }

    /// Accesses the value associated with the given atom for reading and initiates watch to
    /// receive its updates.
    ///
    /// This method returns a value for the given atom and initiates watching the atom so that
    /// the current context gets updated when the atom notifies updates.
    /// The value associated with the atom is cached until it is no longer watched or until
    /// it is updated with a new value.
    ///
    /// ```swift
    /// let context = ...
    /// let text = context.watch(TextAtom())
    /// print(text) // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom to watch.
    ///
    /// - Returns: The value associated with the given atom.
    @discardableResult
    @inlinable
    public func watch<Node: Atom>(_ atom: Node) -> Node.Produced {
        _store.watch(
            atom,
            subscriber: _subscriber,
            subscription: _subscription
        )
    }

    /// Creates a `Binding` that accesses the value of the given read-write atom.
    ///
    /// This method only accepts read-write atoms such as ones conforming to ``StateAtom``,
    /// and returns a binding that accesses the value or set a new value for the atom.
    /// When you set a new value to the `wrappedValue` of the returned binding, it assigns the value
    /// to the atom, and immediately notifies downstream atoms and views.
    /// Note that the binding initiates watching the given atom when the value is accessed through the
    /// `wrappedValue`.
    ///
    /// ```swift
    /// let context = ...
    /// let binding = context.binding(TextAtom())
    /// binding.wrappedValue = "New text"
    /// binding.wrappedValue.append(" is mutated!")
    /// print(binding.wrappedValue) // Prints "New text is mutated!"
    /// ```
    ///
    /// - Parameter atom: An atom to create binding to.
    ///
    /// - Returns: A binding to the atom value.
    @inlinable
    public func binding<Node: StateAtom>(_ atom: Node) -> Binding<Node.Produced> {
        Binding(
            get: { watch(atom) },
            set: { set($0, for: atom) }
        )
    }

    /// Takes a snapshot of an atom hierarchy for debugging purposes.
    ///
    /// This method captures all of the atom values and dependencies currently in use in
    /// the descendants of `AtomRoot` and returns a `Snapshot` that allows you to analyze
    /// or rollback to a specific state.
    ///
    /// - Returns: A snapshot that contains values of atoms.
    @inlinable
    public func snapshot() -> Snapshot {
        _store.snapshot()
    }

    /// Restores atom values and the dependency graph captured at a point in time in the given snapshot for debugging purposes.
    ///
    /// Any atoms and their dependencies that are no longer subscribed to will be released.
    ///
    /// - Parameter snapshot: A snapshot that contains values of atoms.
    @inlinable
    public func restore(_ snapshot: Snapshot) {
        _store.restore(snapshot)
    }
}
