/// A context structure that to read, set, and otherwise interacting with atoms.
@MainActor
public struct AtomUpdatedContext<Coordinator>: AtomContext {
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

    /// Accesses the value associated with the given atom without watching to it.
    ///
    /// This method returns a value for the given atom. Even if you access to a value with this method,
    /// it doesn't initiating watch the atom, so if none of other atoms or views is watching as well,
    /// the value will not be cached.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.read(TextAtom()))  // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    @inlinable
    public func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        _store.read(atom)
    }

    /// Sets the new value for the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assign a new value for the atom.
    /// When you assign a new value, it notifies update immediately to downstream atoms or views.
    ///
    /// - SeeAlso: ``AtomViewContext/subscript``
    ///
    /// ```swift
    /// let context = ...
    /// context.set("New text", for: TextAtom())
    /// print(context.read(TextAtom()))  // Prints "New text"
    /// ```
    ///
    /// - Parameters
    ///   - value: A value to be set.
    ///   - atom: An atom that associates the value.
    @inlinable
    public func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        _store.set(value, for: atom)
    }

    /// Modifies the cached value of the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assign a new value for the atom.
    /// When you modify value, it notifies update to downstream atoms or views after all
    /// the modification completed.
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
    /// - Parameters
    ///   - atom: An atom that associates the value.
    ///   - body: A value modification body.
    @inlinable
    public func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Loader.Value) -> Void) {
        _store.modify(atom, body: body)
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
    /// let context = ...
    /// let image = await context.refresh(AsyncImageDataAtom()).value
    /// print(image) // Prints the data obtained through network.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value which completed refreshing associated with the given atom.
    @discardableResult
    @inlinable
    public func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        await _store.refresh(atom)
    }

    /// Resets the value associated with the given atom, and then notify.
    ///
    /// This method resets a value for the given atom, and then notify update to the downstream
    /// atoms and views. Thereafter, if any of other atoms or views is watching the atom, a newly
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
    /// - Parameter atom: An atom that associates the value.
    @inlinable
    public func reset(_ atom: some Atom) {
        _store.reset(atom)
    }
}
