@preconcurrency import Combine

/// A context structure to read, watch, and otherwise interact with atoms in testing.
///
/// This context has a store that manages the state of atoms, so it can be used to test individual
/// atoms or their interactions with other atoms without depending on the SwiftUI view tree.
/// Furthermore, unlike other contexts, it is possible to override atoms through this context.
@MainActor
public struct AtomTestContext: AtomWatchableContext {
    private let location: SourceLocation

    @usableFromInline
    internal let _state = State()

    /// Creates a new test context instance with a fresh internal state.
    public init(fileID: String = #fileID, line: UInt = #line) {
        location = SourceLocation(fileID: fileID, line: line)
    }

    /// A callback to perform when any of the atoms watched by this context is updated.
    @inlinable
    public var onUpdate: (() -> Void)? {
        get { _state.onUpdate }
        nonmutating set { _state.onUpdate = newValue }
    }

    /// Waits until any of the atoms watched through this context have been updated up to the
    /// specified timeout, and then returns a boolean value indicating whether an update has happened.
    ///
    /// ```swift
    /// func testAsyncUpdate() async {
    ///     let context = AtomTestContext()
    ///
    ///     let initialPhase = context.watch(AsyncCalculationAtom().phase)
    ///     XCTAssertEqual(initialPhase, .suspending)
    ///
    ///     let didUpdate = await context.waitForUpdate()
    ///     let currentPhase = context.watch(AsyncCalculationAtom().phase)
    ///
    ///     XCTAssertTure(didUpdate)
    ///     XCTAssertEqual(currentPhase, .success(123))
    /// }
    /// ```
    ///
    /// - Parameter duration: The maximum duration that this function can wait until
    ///                       the next update. The default timeout interval is `nil`
    ///                       which indicates no timeout.
    /// - Returns: A boolean value indicating whether an update has happened.
    @inlinable
    @discardableResult
    public func waitForUpdate(timeout duration: Double? = nil) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            let updates = _state.makeUpdateStream()

            group.addTask { @MainActor @Sendable in
                for await _ in updates {
                    return true
                }
                return false
            }

            if let duration {
                group.addTask {
                    try? await Task.sleep(seconds: duration)
                    return false
                }
            }

            for await didUpdate in group {
                group.cancelAll()
                return didUpdate
            }

            return false
        }
    }

    /// Waits for the given atom until it will be in a certain state within a specified timeout,
    /// and then returns a boolean value indicating whether an update has happened.
    ///
    /// ```swift
    /// func testAsyncUpdate() async {
    ///     let context = AtomTestContext()
    ///
    ///     let initialPhase = context.watch(AsyncCalculationAtom().phase)
    ///     XCTAssertEqual(initialPhase, .suspending)
    ///
    ///     let didUpdate = await context.wait(for: AsyncCalculationAtom().phase, until: \.isSuccess)
    ///     let currentPhase = context.watch(AsyncCalculationAtom().phase)
    ///
    ///     XCTAssertTure(didUpdate)
    ///     XCTAssertEqual(currentPhase, .success(123))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - atom: An atom expecting an update to a certain state.
    ///   - duration: The maximum duration that this function can wait until
    ///               the next update. The default timeout interval is `nil`
    ///               which indicates no timeout.
    ///   - predicate: A predicate that determines when to stop waiting.
    ///
    /// - Returns: A boolean value indicating whether an update is done.
    ///
    @inlinable
    @discardableResult
    public func wait<Node: Atom>(
        for atom: Node,
        timeout duration: Double? = nil,
        until predicate: @escaping (Node.Produced) -> Bool
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            @MainActor
            func check() -> Bool {
                guard let value = lookup(atom) else {
                    return false
                }

                return predicate(value)
            }

            let updates = _state.makeUpdateStream()

            group.addTask { @MainActor @Sendable in
                guard !check() else {
                    return false
                }

                for await _ in updates {
                    if check() {
                        return true
                    }
                }

                return false
            }

            if let duration {
                group.addTask {
                    try? await Task.sleep(seconds: duration)
                    return false
                }
            }

            for await didUpdate in group {
                group.cancelAll()
                return didUpdate
            }

            return false
        }
    }

    /// Accesses the value associated with the given atom without watching it.
    ///
    /// This method returns a value for the given atom. Accessing the atom value with this method
    /// does not initiate watching the atom, so if none of the other atoms or views are watching,
    /// the value will not be cached.
    ///
    /// ```swift
    /// let context = AtomTestContext()
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
    /// let context = AtomTestContext()
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
    /// let context = AtomTestContext()
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
    /// let context = AtomTestContext()
    /// let value = await context.refresh(CustomRefreshableAtom())
    /// print(value)
    /// ```
    ///
    /// - Parameter atom: An atom to refresh.
    ///
    /// - Returns: The value after the refreshing associated with the given atom is completed.
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
    /// let context = AtomTestContext()
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
    /// let context = AtomTestContext()
    /// let text = context.watch(TextAtom())
    /// print(text) // Prints the current value associated with `TextAtom`.
    /// ```
    ///
    /// - Parameter atom: An atom to watch.
    ///
    /// - Returns: The value associated with the given atom.
    @inlinable
    @discardableResult
    public func watch<Node: Atom>(_ atom: Node) -> Node.Produced {
        _store.watch(
            atom,
            subscriber: _subscriber,
            subscription: _subscription
        )
    }

    /// Returns the already cached value associated with a given atom without side effects.
    ///
    /// This method returns the value only when it is already cached, otherwise, it returns `nil`.
    /// It has no side effects such as the creation of new values or watching atoms.
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// if let text = context.lookup(TextAtom()) {
    ///     print(text)  // Prints the cached value associated with `TextAtom`.
    /// }
    /// ```
    ///
    /// - Parameter atom: An atom to lookup.
    ///
    /// - Returns: The already cached value associated with the given atom.
    @inlinable
    public func lookup<Node: Atom>(_ atom: Node) -> Node.Produced? {
        _store.lookup(atom)
    }

    /// Unwatches the given atom and do not receive any more updates of it.
    ///
    /// It simulates cases where other atoms or views no longer watches to the atom.
    ///
    /// - Parameter atom: An atom to unwatch.
    @inlinable
    public func unwatch(_ atom: some Atom) {
        _store.unwatch(atom, subscriber: _subscriber)
    }

    /// Overrides the atom value with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atom: An atom to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    @inlinable
    public func override<Node: Atom>(_ atom: Node, with value: @MainActor @escaping (Node) -> Node.Produced) {
        _state.overrides[OverrideKey(atom)] = Override(getValue: value)
    }

    /// Overrides the atom value with the given value.
    ///
    /// Instead of overriding the particular instance of atom, this method overrides any atom that
    /// has the same metatype.
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atomType: An atom type to be overridden.
    ///   - value: A value to be used instead of the atom's value.
    @inlinable
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @MainActor @escaping (Node) -> Node.Produced) {
        _state.overrides[OverrideKey(atomType)] = Override(getValue: value)
    }
}

internal extension AtomTestContext {
    @usableFromInline
    @MainActor
    final class State {
        @usableFromInline
        let store = AtomStore()
        let token = ScopeKey.Token()
        let subscriberState = SubscriberState()

        @usableFromInline
        var overrides = [OverrideKey: any OverrideProtocol]()

        @usableFromInline
        var onUpdate: (() -> Void)?

        private let notifier = PassthroughSubject<Void, Never>()

        @usableFromInline
        func makeUpdateStream() -> AsyncStream<Void> {
            AsyncStream { continuation in
                let cancellable = notifier.sink(
                    receiveCompletion: { _ in
                        continuation.finish()
                    },
                    receiveValue: {
                        continuation.yield()
                    }
                )

                continuation.onTermination = { termination in
                    if case .cancelled = termination {
                        cancellable.cancel()
                    }
                }
            }
        }

        @usableFromInline
        func update() {
            onUpdate?()
            notifier.send()
        }
    }

    @usableFromInline
    var _store: StoreContext {
        .registerRoot(
            in: _state.store,
            scopeKey: _state.token.key,
            overrides: _state.overrides,
            observers: []
        )
    }

    @usableFromInline
    var _subscriber: Subscriber {
        Subscriber(_state.subscriberState)
    }

    @usableFromInline
    var _subscription: Subscription {
        Subscription(location: location) { [weak _state] in
            _state?.update()
        }
    }
}
