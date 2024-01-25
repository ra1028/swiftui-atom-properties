/// A context structure to read, set, and otherwise interact with atoms.
@MainActor
public struct AtomCurrentContext<Coordinator>: AtomContext {
    @usableFromInline
    internal let _store: StoreContext

    /// The atom's associated coordinator.
    public let coordinator: Coordinator

    internal init(
        store: StoreContext,
        coordinator: Coordinator
    ) {
        self._store = store
        self.coordinator = coordinator
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
    public func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        _store.read(atom)
    }

    /// Sets the new value for the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assigns a new value for the atom.
    /// When you assign a new value, it immediately notifies downstream atoms and views.
    ///
    /// - SeeAlso: ``AtomViewContext/subscript``
    ///
    /// ```swift
    /// let context = ...
    /// context.set("New text", for: TextAtom())
    /// print(context.read(TextAtom()))  // Prints "New text"
    /// ```
    ///
    /// - Parameters:
    ///   - value: A value to be set.
    ///   - atom: A writable atom to update.
    @inlinable
    public func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
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
    public func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Loader.Value) -> Void) {
        _store.modify(atom, body: body)
    }

    /// Refreshes and then returns the value associated with the given refreshable atom.
    ///
    /// This method only accepts refreshable atoms such as types conforming to:
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
    public func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
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
    @inlinable
    @discardableResult
    public func refresh<Node: Refreshable>(_ atom: Node) async -> Node.Loader.Value {
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
    /// context[TextAtom()] = "New text"
    /// print(context.read(TextAtom())) // Prints "New text"
    /// context.reset(TextAtom())
    /// print(context.read(TextAtom())) // Prints "Text"
    /// ```
    ///
    /// - Parameter atom: An atom to reset.
    @inlinable
    public func reset(_ atom: some Atom) {
        _store.reset(atom)
    }
}
