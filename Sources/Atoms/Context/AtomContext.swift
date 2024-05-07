import SwiftUI

/// A context structure to read, write, and otherwise interact with atoms.
///
/// - SeeAlso: ``AtomWatchableContext``
@MainActor
public protocol AtomContext {
    /// Accesses the value associated with the given atom without watching it.
    ///
    /// This method returns a value for the given atom. Accessing the atom value with this method
    /// does not initiate watching the atom, so if none of the other atoms or views are watching,
    /// the value will not be cached.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.read(TextAtom()))  // Prints the current value associated with ``TextAtom``.
    /// ```
    ///
    /// - Parameter atom: An atom to read.
    ///
    /// - Returns: The value associated with the given atom.
    func read<Node: Atom>(_ atom: Node) -> Node.Produced

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
    func set<Node: StateAtom>(_ value: Node.Produced, for atom: Node)

    /// Modifies the cached value of the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assigns a new value for the atom.
    /// When you modify the value, it notifies downstream atoms or views after all
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
    func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Produced) -> Void)

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
    @_disfavoredOverload
    @discardableResult
    func refresh<Node: AsyncAtom>(_ atom: Node) async -> Node.Produced

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
    @discardableResult
    func refresh<Node: Refreshable>(_ atom: Node) async -> Node.Produced

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
    @_disfavoredOverload
    func reset<Node: Atom>(_ atom: Node)

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
    func reset<Node: Resettable>(_ atom: Node)
}

public extension AtomContext {
    /// Accesses the value associated with the given read-write atom for mutating.
    ///
    /// This subscript only accepts read-write atoms such as types conforming to ``StateAtom``,
    /// and returns the value or assigns a new value for the atom.
    /// When you assign a new value, it immediately notifies downstream atoms and views,
    /// but it doesn't start watching the atom.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context[TextAtom()] = "New text"
    /// context[TextAtom()].append(" is mutated!")
    /// print(context[TextAtom()])       // Prints "New text is mutated!"
    /// ```
    ///
    /// - Parameter atom: An atom to read or write.
    ///
    /// - Returns: The value associated with the given atom.
    subscript<Node: StateAtom>(_ atom: Node) -> Node.Produced {
        get { read(atom) }
        nonmutating set { set(newValue, for: atom) }
    }
}

/// A context structure to read, watch, and otherwise interact with atoms.
///
/// - SeeAlso: ``AtomViewContext``
/// - SeeAlso: ``AtomTransactionContext``
/// - SeeAlso: ``AtomTestContext``
@MainActor
public protocol AtomWatchableContext: AtomContext {
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
    /// print(context.watch(TextAtom())) // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom to watch.
    ///
    /// - Returns: The value associated with the given atom.
    @discardableResult
    func watch<Node: Atom>(_ atom: Node) -> Node.Produced
}
