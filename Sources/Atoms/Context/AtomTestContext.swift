import Combine
import Foundation

/// A context structure that to read, watch, and otherwise interacting with atoms in testing.
///
/// This context has an internal Store that manages atoms, so it can be used to test individual
/// atoms or their interactions with other atoms without depending on the SwiftUI view tree.
/// Furthermore, unlike other contexts, it is possible to override or observe changes in atoms
/// by this itself.
@MainActor
public struct AtomTestContext: AtomWatchableContext {
    private let state: State

    /// Creates a new test context instance with fresh internal state.
    public init(fileID: String = #fileID, line: UInt = #line) {
        let location = SourceLocation(fileID: fileID, line: line)
        state = State(location: location)
    }

    /// A callback to perform when any of atoms watched by this context is updated.
    public var onUpdate: (() -> Void)? {
        get { state.onUpdate }
        nonmutating set { state.onUpdate = newValue }
    }

    /// Waits until any of atoms watched through this context is updated for up to
    /// the specified timeout, and then return a boolean value indicating whether an update is done.
    ///
    /// ```swift
    /// func testAsyncUpdate() async {
    ///     let context = AtomTestContext()
    ///
    ///     let initialPhase = context.watch(AsyncCalculationAtom().phase)
    ///     XCTAssertEqual(initialPhase, .suspending)
    ///
    ///     let didUpdate = await context.waitUntilNextUpdate()
    ///     let currentPhase = context.watch(AsyncCalculationAtom().phase)
    ///
    ///     XCTAssertTure(didUpdate)
    ///     XCTAssertEqual(currentPhase, .success(123))
    /// }
    /// ```
    ///
    /// - Parameter interval: The maximum timeout interval that this function can wait until
    ///                      the next update. The default timeout interval is `60`.
    /// - Returns: A boolean value indicating whether an update is done.
    @discardableResult
    public func waitUntilNextUpdate(timeout interval: TimeInterval = 60) async -> Bool {
        let updates = AsyncStream<Void> { continuation in
            let cancellable = state.notifier.sink(
                receiveCompletion: { completion in
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

        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = updates.makeAsyncIterator()
                await iterator.next()
                return true
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                return false
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
    public func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        state.store.read(atom)
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
    public func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        state.store.set(value, for: atom)
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
    public func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        await state.store.refresh(atom)
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
    public func reset(_ atom: some Atom) {
        state.store.reset(atom)
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
    public func watch<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        state.store.watch(atom, container: state.container) { [weak state] in
            state?.notifyUpdate()
        }
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
    @discardableResult
    public func watch<Node: ObservableObjectAtom>(_ atom: Node) -> Node.Loader.Value {
        state.store.watch(atom, container: state.container) { [weak state] in
            // Ensures that the observable object is updated before notifying updates.
            RunLoop.current.perform { [weak state] in
                state?.notifyUpdate()
            }
        }
    }

    /// Unwatches the given atom and do not receive any more updates of it.
    ///
    /// It simulates cases where other atoms or views no longer watches to the atom.
    ///
    /// - Parameter atom: An atom that associates the value.
    public func unwatch<Node: Atom>(_ atom: Node) {
        let key = AtomKey(atom)
        state.container.subscriptions.removeValue(forKey: key)?.unsubscribe()
    }

    /// Overrides the atom value with the given value.
    ///
    /// When accessing the overridden atom, this context will create and return the given value
    /// instead of the atom value.
    ///
    /// - Parameters:
    ///   - atom: An atom that to be overridden.
    ///   - value: A value that to be used instead of the atom's value.
    public func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Loader.Value) {
        state.overrides.insert(atom, with: value)
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
    public func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Loader.Value) {
        state.overrides.insert(atomType, with: value)
    }
}

private extension AtomTestContext {
    final class State {
        private let _store = Store()
        private let _container = SubscriptionContainer()

        let location: SourceLocation
        let notifier = PassthroughSubject<Void, Never>()
        var overrides = Overrides()
        var onUpdate: (() -> Void)?

        init(location: SourceLocation) {
            self.location = location
        }

        var store: StoreContext {
            StoreContext(_store, overrides: overrides)
        }

        @MainActor
        var container: SubscriptionContainer.Wrapper {
            _container.wrapper(location: location)
        }

        func notifyUpdate() {
            onUpdate?()
            notifier.send()
        }
    }
}
