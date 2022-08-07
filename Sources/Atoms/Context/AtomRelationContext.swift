/// A context structure that to read, watch, and otherwise interacting with atoms.
///
/// Through this context, watching of an atom is initiated, and when that atom is updated,
/// the value of the atom to which this context is provided will be updated transitively.
@MainActor
public struct AtomRelationContext: AtomWatchableContext {
    @usableFromInline
    internal let _box: _AnyAtomRelationContextBox

    internal init<Node: Atom>(atom: Node, store: AtomStore) {
        _box = _AtomRelationContextBox(caller: atom, store: store)
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
    public func read<Node: Atom>(_ atom: Node) -> Node.Hook.Value {
        _box.store.read(atom)
    }

    /// Sets the new value for the given writable atom.
    ///
    /// This method only accepts writable atoms such as types conforming to ``StateAtom``,
    /// and assign a new value for the atom.
    /// When you assign a new value, it notifies update immediately to downstream atoms or views.
    ///
    /// - SeeAlso: ``AtomRelationContext/subscript``
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
    ///   - atom: An atom that associates the value.
    @inlinable
    public func set<Node: Atom>(_ value: Node.Hook.Value, for atom: Node) where Node.Hook: AtomStateHook {
        _box.store.set(value, for: atom)
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
    @inlinable
    @discardableResult
    public func refresh<Node: Atom>(_ atom: Node) async -> Node.Hook.Value where Node.Hook: AtomRefreshableHook {
        await _box.store.refresh(atom)
    }

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
    @inlinable
    public func reset<Node: Atom>(_ atom: Node) {
        _box.store.reset(atom)
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
    /// let context = ...
    /// let text = context.watch(TextAtom())
    /// print(text) // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value associated with the given atom.
    @inlinable
    @discardableResult
    public func watch<Node: Atom>(_ atom: Node) -> Node.Hook.Value {
        _box.watch(atom, shouldNotifyAfterUpdates: false)
    }

    /// Accesses the observable object associated with the given atom for reading and initialing watch to
    /// receive its updates.
    ///
    /// This method returns an observable object for the given atom and initiate watching the atom so that
    /// the current context to get updated when the atom notifies updates.
    /// The observable object associated with the atom is cached until it is no longer watched to or until
    /// it is updated.
    ///
    /// ```swift
    /// let context = ...
    /// let store = context.watch(AccountStoreAtom())
    /// print(store.currentUser) // Prints the user value after update.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the observable object.
    ///
    /// - Returns: The observable object associated with the given atom.
    @inlinable
    @discardableResult
    public func watch<Node: Atom>(_ atom: Node) -> Node.Hook.Value where Node.Hook: AtomObservableObjectHook {
        _box.watch(atom, shouldNotifyAfterUpdates: true)
    }

    /// Add the termination action that will be performed when the atom will no longer be watched to
    /// or upstream atoms are updated.
    ///
    /// ```swift
    /// struct QuakeMonitorAtom: ValueAtom, Hashable {
    ///     func value(context: Context) -> QuakeMonitor {
    ///         let monitor = QuakeMonitor()
    ///         monitor.quakeHandler = { quake in
    ///             print("Quake: \(quake.date)")
    ///         }
    ///         context.addTermination {
    ///             monitor.stopMonitoring()
    ///         }
    ///         monitor.startMonitoring()
    ///         return monitor
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter termination: A termination action.
    @inlinable
    public func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _box.addTermination(termination)
    }

    /// Add the given object to the storage that to be retained until the atom will no longer be watched
    /// to or upstream atoms are updated.
    ///
    /// ```swift
    /// struct LocationManagerAtom: ValueAtom, Hashable {
    ///     func value(context: Context) -> LocationManagerProtocol {
    ///         let manager = CLLocationManager()
    ///         let delegate = LocationManagerDelegate()
    ///
    ///         manager.delegate = delegate
    ///         context.keepUntilTermination(delegate)
    ///         context.addTermination(manager.stopUpdatingLocation)
    ///
    ///         return manager
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter object: An object that to be retained.
    @inlinable
    public func keepUntilTermination<Object: AnyObject>(_ object: Object) {
        _box.keepUntilTermination(object)
    }
}

@usableFromInline
@MainActor
internal protocol _AnyAtomRelationContextBox {
    var store: AtomStore { get }

    func watch<Node: Atom>(_ atom: Node, shouldNotifyAfterUpdates: Bool) -> Node.Hook.Value
    func addTermination(_ termination: @MainActor @escaping () -> Void)
    func keepUntilTermination<Object: AnyObject>(_ object: Object)
}

@usableFromInline
internal struct _AtomRelationContextBox<Caller: Atom>: _AnyAtomRelationContextBox {
    final class Retainer<Object: AnyObject> {
        private var object: Object?

        init(_ object: Object) {
            self.object = object
        }

        func release() {
            object = nil
        }
    }

    let caller: Caller

    @usableFromInline
    let store: AtomStore

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, shouldNotifyAfterUpdates: Bool) -> Node.Hook.Value {
        store.watch(
            atom,
            belongTo: caller,
            shouldNotifyAfterUpdates: shouldNotifyAfterUpdates
        )
    }

    @usableFromInline
    func addTermination(_ termination: @MainActor @escaping () -> Void) {
        store.addTermination(caller, termination: termination)
    }

    @usableFromInline
    func keepUntilTermination<Object: AnyObject>(_ object: Object) {
        let retainer = Retainer(object)
        store.addTermination(caller, termination: retainer.release)
    }
}
