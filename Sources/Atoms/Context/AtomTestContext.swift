import Combine
import Foundation

/// A context structure that to read, watch, and otherwise interacting with atoms in testing.
///
/// This context has a store that manages the state of atoms, so it can be used to test individual
/// atoms or their interactions with other atoms without depending on the SwiftUI view tree.
/// Furthermore, unlike other contexts, it is possible to override or observe changes in atoms
/// by this itself.
@MainActor
public struct AtomTestContext: AtomWatchableContext {
    private let location: SourceLocation

    @usableFromInline
    internal let _state = State()

    /// Creates a new test context instance with fresh internal state.
    public init(fileID: String = #fileID, line: UInt = #line) {
        location = SourceLocation(fileID: fileID, line: line)
    }

    /// A callback to perform when any of atoms watched by this context is updated.
    @inlinable
    public var onUpdate: (() -> Void)? {
        get { _state.onUpdate }
        nonmutating set { _state.onUpdate = newValue }
    }

    /// Waits until any of the atoms watched through this context have been updated up to the
    /// specified timeout, and then returns a boolean value indicating whether an update is done.
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
    ///                       the next update. The default timeout interval is nil.
    /// - Returns: A boolean value indicating whether an update is done.
    @inlinable
    @discardableResult
    public func waitForUpdate(timeout duration: TimeInterval? = nil) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            let updates = _state.makeUpdateStream()

            group.addTask { @MainActor in
                var iterator = updates.makeAsyncIterator()
                await iterator.next()
                return true
            }

            if let duration {
                group.addTask {
                    try? await Task.sleep(seconds: duration)
                    return false
                }
            }

            let didUpdate = await group.next() ?? false
            group.cancelAll()

            return didUpdate
        }
    }

    /// Waits for the given atom until it will be a certain state up to the specified timeout,
    /// and then returns a boolean value indicating whether an update is done.
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
    ///   - atom: An atom that this method waits updating to a certain state.
    ///   - duration: The maximum duration that this function can wait until
    ///               the next update. The default timeout interval is nil.
    ///   - predicate: A predicate that determines when to stop waiting.
    ///
    /// - Returns: A boolean value indicating whether an update is done.
    ///
    @inlinable
    @discardableResult
    public func wait<Node: Atom>(
        for atom: Node,
        timeout duration: TimeInterval? = nil,
        until predicate: @escaping (Node.Loader.Value) -> Bool
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

            group.addTask { @MainActor in
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

            let didUpdate = await group.next() ?? false
            group.cancelAll()

            return didUpdate
        }
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
    /// let context = AtomTestContext()
    /// let image = await context.refresh(AsyncImageDataAtom()).value
    /// print(image) // Prints the data obtained through network.
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The value which completed refreshing associated with the given atom.
    @inlinable
    @discardableResult
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
    /// let context = AtomTestContext()
    /// print(context.watch(TextAtom())) // Prints "Text"
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
    @inlinable
    @discardableResult
    public func watch<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        _store.watch(atom, container: _container, requiresObjectUpdate: true) { [weak _state] in
            _state?.notifyUpdate()
        }
    }

    /// Returns the already cached value associated with a given atom without side effects.
    ///
    /// This method returns the value only when it is already cached, otherwise, it returns `nil`.
    /// It has no side effects such as the creation of new values or watching to atoms.
    ///
    /// ```swift
    /// let context = AtomTestContext()
    /// if let text = context.lookup(TextAtom()) {
    ///     print(text)  // Prints the cached value associated with `TextAtom`.
    /// }
    /// ```
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The already cached value associated with the given atom.
    @inlinable
    public func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        _store.lookup(atom)
    }

    /// Unwatches the given atom and do not receive any more updates of it.
    ///
    /// It simulates cases where other atoms or views no longer watches to the atom.
    ///
    /// - Parameter atom: An atom that associates the value.
    @inlinable
    public func unwatch(_ atom: some Atom) {
        _store.unwatch(atom, container: _container)
    }

    /// Overrides the atom value with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atom: An atom that to be overridden.
    ///   - value: A value that to be used instead of the atom's value.
    @inlinable
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Loader.Value) {
        _state.overrides[OverrideKey(atom)] = AtomOverride(value: value)
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
    @inlinable
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Loader.Value) {
        _state.overrides[OverrideKey(atomType)] = AtomOverride(value: value)
    }
}

internal extension AtomTestContext {
    @usableFromInline
    @MainActor
    final class State {
        @usableFromInline
        let store = AtomStore()
        let token = ScopeKey.Token()
        let container = SubscriptionContainer()

        @usableFromInline
        var overrides = [OverrideKey: any AtomOverrideProtocol]()

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
                    switch termination {
                    case .cancelled:
                        cancellable.cancel()

                    case .finished:
                        break

                    @unknown default:
                        break
                    }
                }
            }
        }

        @usableFromInline
        func notifyUpdate() {
            onUpdate?()
            notifier.send()
        }
    }

    @usableFromInline
    var _store: StoreContext {
        .scoped(
            key: ScopeKey(token: _state.token),
            store: _state.store,
            observers: [],
            overrides: _state.overrides
        )
    }

    @usableFromInline
    var _container: SubscriptionContainer.Wrapper {
        _state.container.wrapper(location: location)
    }
}
