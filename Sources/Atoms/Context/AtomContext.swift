import SwiftUI

/// A context structure that to read, write, and otherwise interacting with atoms.
///
/// - SeeAlso: ``AtomWatchableContext``
@MainActor
public protocol AtomContext {
    /// Accesses the value associated with the given atom without watching to it.
    ///
    /// This method returns a value for the given atom. Even if you access to a value with this method,
    /// it doesn't initiating watch the atom, so if none of other atoms or views is watching as well,
    /// the value will not be cached.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.read(TextAtom()))  // Prints the current value associated with ``TextAtom``.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value

    /// Sets the new value for the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assign a new value for the atom.
    /// When you assign a new value, it notifies update immediately to downstream atoms or views.
    ///
    /// - SeeAlso: ``AtomContext/subscript``
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context.set("New text", for: TextAtom())
    /// print(context.read(TextAtom()))  // Prints "New text"
    /// ```
    ///
    /// - Parameters
    ///   - value: A value to be set.
    ///   - atom: An atom that associates the value.
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node)

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
    func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Loader.Value) -> Void)

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
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader

    /// Resets the value associated with the given atom, and then notify.
    ///
    /// This method resets a value for the given atom, and then notify update to the downstream
    /// atoms and views. Thereafter, if any of other atoms or views is watching the atom, a newly
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
    /// - Parameter atom: An atom that associates the value.
    func reset(_ atom: some Atom)
}

public extension AtomContext {
    /// Accesses the value associated with the given read-write atom for mutating.
    ///
    /// This subscript only accepts read-write atoms such as types conforming to ``StateAtom``,
    /// and returns the value or assign a new value for the atom.
    /// When you assign a new value, it notifies update immediately to downstream atoms or views,
    /// but it doesn't start watching the given atom only by getting the value.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints "Text"
    /// context[TextAtom()] = "New text"
    /// context[TextAtom()].append(" is mutated!")
    /// print(context[TextAtom()])       // Prints "New text is mutated!"
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    subscript<Node: StateAtom>(_ atom: Node) -> Node.Loader.Value {
        get { read(atom) }
        nonmutating set { set(newValue, for: atom) }
    }
}

/// A context structure that to read, watch, and otherwise interacting with atoms.
///
/// - SeeAlso: ``AtomViewContext``
/// - SeeAlso: ``AtomTransactionContext``
/// - SeeAlso: ``AtomTestContext``
@MainActor
public protocol AtomWatchableContext: AtomContext {
    /// Accesses the value associated with the given atom for reading and initialing watch to
    /// receive its updates.
    ///
    /// This method returns a value for the given atom and initiate watching the atom so that
    /// the current context to get updated when the atom notifies updates.
    /// The value associated with the atom is cached until it is no longer watched to or until
    /// it is updated.
    ///
    /// ```swift
    /// let context = ...
    /// print(context.watch(TextAtom())) // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    @discardableResult
    func watch<Node: Atom>(_ atom: Node) -> Node.Loader.Value
}

public extension AtomWatchableContext {
    /// Creates a `Binding` that accesses the value associated with the given read-write atom.
    ///
    /// This method only accepts read-write atoms such as types conforming to ``StateAtom``,
    /// and returns a binding that accesses the value or assign a new value for the atom.
    /// When you set a new value to the `wrappedValue` property of the binding, it assigns the value
    /// to the atom, and then notifies update immediately to downstream atoms or views.
    /// Note that the binding initiates wathing the given atom when you get a value through the
    /// `wrappedValue` property.
    ///
    /// ```swift
    /// let context = ...
    /// let binding = context.state(TextAtom())
    /// binding.wrappedValue = "New text"
    /// binding.wrappedValue.append(" is mutated!")
    /// print(binding.wrappedValue) // Prints "New text is mutated!"
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    @inlinable
    func state<Node: StateAtom>(_ atom: Node) -> Binding<Node.Loader.Value> {
        Binding(
            get: { watch(atom) },
            set: { self[atom] = $0 }
        )
    }
}
