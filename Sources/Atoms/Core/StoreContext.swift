import Foundation

@usableFromInline
@MainActor
internal struct StoreContext {
    private let current: Scope
    private let observers: [Observer]

    nonisolated init(
        _ store: AtomStore? = nil,
        overrides: Overrides = Overrides(),
        observers: [Observer] = [],
        enablesAssertion: Bool = false
    ) {
        self.init(
            current: Scope(
                store: store,
                overrides: overrides,
                parent: nil,
                enablesAssertion: enablesAssertion
            ),
            observers: observers
        )
    }

    nonisolated private init(
        current: Scope,
        observers: [Observer] = []
    ) {
        self.current = current
        self.observers = observers
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        read(atom, scope: current)
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        set(value, for: atom, scope: current)
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        watch(atom, in: transaction, scope: current)
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void
    ) -> Node.Loader.Value {
        watch(atom, container: container, notifyUpdate: notifyUpdate, scope: current)
    }

    @usableFromInline
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        await refresh(atom, scope: current)
    }

    @usableFromInline
    func reset(_ atom: some Atom) {
        reset(atom, scope: current)
    }

    @usableFromInline
    func snapshot() -> Snapshot {
        snapshot(scope: current)
    }

    func scoped(
        store: AtomStore,
        overrides: Overrides,
        observers: [Observer]
    ) -> Self {
        Self(
            current: Scope(
                store: store,
                overrides: overrides,
                parent: current,
                enablesAssertion: current.enablesAssertion
            ),
            observers: self.observers + observers
        )
    }
}

private extension StoreContext {
    func read<Node: Atom>(_ atom: Node, scope: Scope) -> Node.Loader.Value {
        let key = AtomKey(atom)
        let override: Node.Loader.Value?

        if let cache = peekCache(of: atom, for: key, scope: scope) {
            return cache.value
        }
        else if let value = scope.overrides.value(atom, for: key) {
            override = value
        }
        else if let parent = scope.parent {
            return read(atom, scope: parent)
        }
        else {
            override = nil
        }

        let cache = makeNewCache(of: atom, for: key, override: override, scope: scope)
        notifyUpdateToObservers(scope: scope)
        checkRelease(for: key, scope: scope)
        return cache.value
    }

    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node, scope: Scope) {
        let key = AtomKey(atom)

        if let cache = peekCache(of: atom, for: key, scope: scope) {
            update(atom: atom, for: key, value: value, cache: cache, scope: scope)
            checkRelease(for: key, scope: scope)
        }
        else if scope.overrides.hasValue(for: key) {
            // Do nothing if the atom is overridden.
            return
        }
        else if let parent = scope.parent {
            return set(value, for: atom, scope: parent)
        }
    }

    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction, scope: Scope) -> Node.Loader.Value {
        guard !transaction.isTerminated else {
            return read(atom)
        }

        let key = AtomKey(atom)
        let cache: AtomCache<Node>?
        let override: Node.Loader.Value?

        if let oldCache = peekCache(of: atom, for: key, scope: scope) {
            cache = oldCache
            override = nil
        }
        else if let value = scope.overrides.value(atom, for: key) {
            cache = nil
            override = value
        }
        else if let parent = scope.parent {
            return watch(atom, in: transaction, scope: parent)
        }
        else {
            cache = nil
            override = nil
        }

        let newCache = cache ?? makeNewCache(of: atom, for: key, override: override, scope: scope)
        let isInserted = scope.store.graph.children[key, default: []].insert(transaction.key).inserted

        // Add an `Edge` from the upstream to downstream.
        scope.store.graph.dependencies[transaction.key, default: []].insert(key)

        if isInserted || cache == nil {
            notifyUpdateToObservers(scope: scope)
        }

        return newCache.value
    }

    func watch<Node: Atom>(
        _ atom: Node,
        container: SubscriptionContainer.Wrapper,
        notifyUpdate: @escaping () -> Void,
        scope: Scope
    ) -> Node.Loader.Value {
        let key = AtomKey(atom)
        let cache: AtomCache<Node>?
        let override: Node.Loader.Value?

        if let oldCache = peekCache(of: atom, for: key, scope: scope) {
            cache = oldCache
            override = nil
        }
        else if let value = scope.overrides.value(atom, for: key) {
            cache = nil
            override = value
        }
        else if let parent = scope.parent {
            return watch(atom, container: container, notifyUpdate: notifyUpdate, scope: parent)
        }
        else {
            cache = nil
            override = nil
        }

        let newCache = cache ?? makeNewCache(of: atom, for: key, override: override, scope: scope)
        let subscription = Subscription(notifyUpdate: notifyUpdate) {
            // Unsubscribe and release if it's no longer used.
            scope.store.state.subscriptions[key]?.removeValue(forKey: container.key)
            notifyUpdateToObservers(scope: scope)
            checkRelease(for: key, scope: scope)
        }
        let isInserted = scope.store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: container.key) == nil

        // Register the subscription to both the store and the container.
        container.subscriptions[key] = subscription

        if isInserted || cache == nil {
            notifyUpdateToObservers(scope: scope)
        }

        return newCache.value
    }

    func refresh<Node: Atom>(_ atom: Node, scope: Scope) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let key = AtomKey(atom)
        let cache: AtomCache<Node>?
        let override: Node.Loader.Value?

        if let oldCache = peekCache(of: atom, for: key, scope: scope) {
            cache = oldCache
            override = scope.overrides.value(atom, for: key)
        }
        else if let value = scope.overrides.value(atom, for: key) {
            cache = nil
            override = value
        }
        else if let parent = scope.parent {
            return await refresh(atom, scope: parent)
        }
        else {
            cache = nil
            override = nil
        }

        let context = prepareTransaction(of: atom, for: key, scope: scope)
        let value: Node.Loader.Value

        if let override {
            value = await atom._loader.refresh(context: context, with: override)
        }
        else {
            value = await atom._loader.refresh(context: context)
        }

        if let cache {
            update(atom: atom, for: key, value: value, cache: cache, scope: scope)
        }

        checkRelease(for: key, scope: scope)
        return value
    }

    func reset(_ atom: some Atom, scope: Scope) {
        let key = AtomKey(atom)

        if let cache = peekCache(of: atom, for: key, scope: scope) {
            let override = scope.overrides.value(atom, for: key)
            let newCache = makeNewCache(of: atom, for: key, override: override, scope: scope)
            update(atom: atom, for: key, value: newCache.value, cache: cache, scope: scope)
            checkRelease(for: key, scope: scope)
        }
        else if scope.overrides.hasValue(for: key) {
            // Do nothing if the atom is overridden.
            return
        }
        else if let parent = scope.parent {
            reset(atom, scope: parent)
        }
    }

    func reset(for key: AtomKey, scope: Scope) {
        if let cache = scope.store.state.caches[key] {
            reset(cache.atom, scope: scope)
        }
        else if scope.overrides.hasValue(for: key) {
            // Do nothing if the atom is overridden.
            return
        }
        else if let parent = scope.parent {
            reset(for: key, scope: parent)
        }
    }

    func makeNewCache<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: Node.Loader.Value?,
        scope: Scope
    ) -> AtomCache<Node> {
        let context = prepareTransaction(of: atom, for: key, scope: scope)
        let value: Node.Loader.Value

        if let override {
            value = atom._loader.handle(context: context, with: override)
        }
        else {
            value = atom._loader.get(context: context)
        }

        let cache = AtomCache(atom: atom, value: value)
        scope.store.state.caches[key] = cache

        return cache
    }

    func prepareTransaction<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        scope: Scope
    ) -> AtomLoaderContext<Node.Loader.Value, Node.Loader.Coordinator> {
        let state = getState(of: atom, for: key, scope: scope)

        // Invalidate dependencies and an ongoing transaction.
        let oldDependencies = invalidate(for: key, scope: scope)
        let transaction = Transaction(key: key) {
            let dependencies = scope.store.graph.dependencies[key] ?? []
            let obsoletedDependencies = oldDependencies.subtracting(dependencies)

            // Check if the dependencies that are no longer used and release them if possible.
            checkReleaseDependencies(obsoletedDependencies, for: key, scope: scope)
        }

        // Register the transaction state so it can be terminated from anywhere.
        state.transaction = transaction

        return AtomLoaderContext(
            store: self,
            transaction: transaction,
            coordinator: state.coordinator
        ) { value, needsEnsureValueUpdate in
            guard let cache = peekCache(of: atom, for: key, scope: scope) else {
                return
            }

            update(
                atom: atom,
                for: key,
                value: value,
                cache: cache,
                needsEnsureValueUpdate: needsEnsureValueUpdate,
                scope: scope
            )
        }
    }

    func getState<Node: Atom>(of atom: Node, for key: AtomKey, scope: Scope) -> AtomState<Node.Coordinator> {
        func makeState() -> AtomState<Node.Coordinator> {
            let coordinator = atom.makeCoordinator()
            let state = AtomState(coordinator: coordinator)
            scope.store.state.states[key] = state
            return state
        }

        guard let baseState = scope.store.state.states[key] else {
            return makeState()
        }

        guard let state = baseState as? AtomState<Node.Coordinator> else {
            assertionFailure(
                """
                [Atoms]
                The type of the given atom's value and the state did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom: \(Node.self)
                Key: \(type(of: atom.key))
                Detected: \(type(of: baseState))
                Expected: AtomState<\(Node.Coordinator.self)>
                """
            )

            // Release the invalid registration as a fallback.
            release(for: key, scope: scope)
            return makeState()
        }

        return state
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        value: Node.Loader.Value,
        cache: AtomCache<Node>,
        needsEnsureValueUpdate: Bool = false,
        scope: Scope
    ) {
        let oldValue = cache.value
        var cache = cache

        // Update the current value with the new value.
        cache.value = value
        scope.store.state.caches[key] = cache

        // Do not notify update if the new value and the old value are equivalent.
        if !atom._loader.shouldNotifyUpdate(newValue: value, oldValue: oldValue) {
            return
        }

        // Notify update to the downstream atoms or views.
        notifyUpdate(for: key, needsEnsureValueUpdate: needsEnsureValueUpdate, scope: scope)

        // Notify value update to observers.
        notifyUpdateToObservers(scope: scope)

        func notifyUpdated() {
            let state = getState(of: atom, for: key, scope: scope)
            let context = AtomUpdatedContext(store: self, coordinator: state.coordinator)
            atom.updated(newValue: value, oldValue: oldValue, context: context)
        }

        // Ensures the value is updated.
        if needsEnsureValueUpdate {
            RunLoop.current.perform {
                notifyUpdated()
            }
        }
        else {
            notifyUpdated()
        }
    }

    func notifyUpdate(
        for key: AtomKey,
        needsEnsureValueUpdate: Bool,
        scope: Scope
    ) {
        // Notifying update to view subscriptions first.
        if let subscriptions = scope.store.state.subscriptions[key], !subscriptions.isEmpty {
            for subscription in ContiguousArray(subscriptions.values) {
                subscription.notifyUpdate()
            }
        }

        guard let children = scope.store.graph.children[key], !children.isEmpty else {
            return
        }

        func notifyUpdate() {
            for child in children {
                // Reset the atom value and then notify update to downstream atoms.
                reset(for: child, scope: scope)
            }
        }

        // At the timing when `ObservableObject/objectWillChange` emits, its properties
        // have not yet been updated and are still old when dependent atoms read it.
        // As a workaround, the update is executed in the next run loop
        // so that the downstream atoms can receive the object that's already updated.
        if needsEnsureValueUpdate {
            RunLoop.current.perform {
                notifyUpdate()
            }
        }
        else {
            notifyUpdate()
        }
    }

    func peekCache<Node: Atom>(of atom: Node, for key: AtomKey, scope: Scope) -> AtomCache<Node>? {
        guard let baseCache = scope.store.state.caches[key] else {
            return nil
        }

        guard let cache = baseCache as? AtomCache<Node> else {
            assertionFailure(
                """
                [Atoms]
                The type of the given atom's value and the cache did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom: \(Node.self)
                Key: \(type(of: atom.key))
                Detected: \(type(of: baseCache))
                Expected: AtomCache<\(Node.self)>
                """
            )

            // Release the invalid registration as a fallback.
            release(for: key, scope: scope)
            return nil
        }

        return cache
    }

    func invalidate(for key: AtomKey, scope: Scope) -> Set<AtomKey> {
        // Remove the current transaction and then terminate to prevent it to watch new atoms
        // or add new terminations.
        // Then, temporarily remove dependencies but do not release them recursively here.
        scope.store.state.states[key]?.transaction?.terminate()
        return scope.store.graph.dependencies.removeValue(forKey: key) ?? []
    }

    func release(for key: AtomKey, scope: Scope) {
        // Invalidate transactions, dependencies, and the atom state.
        let dependencies = invalidate(for: key, scope: scope)
        scope.store.graph.children.removeValue(forKey: key)
        scope.store.state.caches.removeValue(forKey: key)
        scope.store.state.states.removeValue(forKey: key)
        scope.store.state.subscriptions.removeValue(forKey: key)

        // Check if the dependencies are releasable.
        checkReleaseDependencies(dependencies, for: key, scope: scope)

        // Notify release.
        notifyUpdateToObservers(scope: scope)
    }

    func checkRelease(for key: AtomKey, scope: Scope) {
        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        let shouldKeepAlive = scope.store.state.caches[key].map { $0.atom is any KeepAlive } ?? false
        let isChildrenEmpty = scope.store.graph.children[key]?.isEmpty ?? true
        let isSubscriptionEmpty = scope.store.state.subscriptions[key]?.isEmpty ?? true
        let shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

        guard shouldRelease else {
            return
        }

        release(for: key, scope: scope)
    }

    func checkReleaseDependencies(_ dependencies: Set<AtomKey>, for key: AtomKey, scope: Scope) {
        // Recursively release dependencies while unlinking the dependent.
        for dependency in dependencies {
            scope.store.graph.children[dependency]?.remove(key)
            checkRelease(for: dependency, scope: scope)
        }
    }

    func notifyUpdateToObservers(scope: Scope) {
        guard !observers.isEmpty else {
            return
        }

        let snapshot = snapshot(scope: scope)

        for observer in observers {
            observer.onUpdate(snapshot)
        }
    }

    func snapshot(scope: Scope) -> Snapshot {
        let graph = scope.store.graph
        let caches = scope.store.state.caches
        let subscriptions = scope.store.state.subscriptions

        return Snapshot(
            graph: graph,
            caches: caches,
            subscriptions: subscriptions
        ) {
            let keys = ContiguousArray(caches.keys)
            var obsoletedDependencies = [AtomKey: Set<AtomKey>]()

            for key in keys {
                let oldDependencies = scope.store.graph.dependencies[key]
                let newDependencies = graph.dependencies[key]

                // Update atom values and the graph.
                scope.store.state.caches[key] = caches[key]
                scope.store.graph.dependencies[key] = newDependencies
                scope.store.graph.children[key] = graph.children[key]
                obsoletedDependencies[key] = oldDependencies?.subtracting(newDependencies ?? [])
            }

            for key in keys {
                // Release if the atom is no longer used.
                checkRelease(for: key, scope: scope)

                // Release dependencies that are no longer dependent.
                if let dependencies = obsoletedDependencies[key] {
                    checkReleaseDependencies(dependencies, for: key, scope: scope)
                }

                // Notify updates only for the subscriptions of restored atoms.
                if let subscriptions = scope.store.state.subscriptions[key] {
                    for subscription in ContiguousArray(subscriptions.values) {
                        subscription.notifyUpdate()
                    }
                }
            }
        }
    }
}

private final class Scope {
    private(set) weak var weakStore: AtomStore?
    let overrides: Overrides
    let parent: Scope?
    let enablesAssertion: Bool

    init(
        store: AtomStore?,
        overrides: Overrides,
        parent: Scope?,
        enablesAssertion: Bool
    ) {
        self.weakStore = store
        self.overrides = overrides
        self.parent = parent
        self.enablesAssertion = enablesAssertion
    }

    var store: AtomStore {
        if let store = weakStore {
            return store
        }

        assert(
            !enablesAssertion,
            """
            [Atoms]
            There is no store provided on the current view tree.
            Make sure that this application has an `AtomRoot` as a root ancestor of any view.

            ```
            struct ExampleApp: App {
                var body: some Scene {
                    WindowGroup {
                        AtomRoot {
                            ExampleView()
                        }
                    }
                }
            }
            ```

            If for some reason the view tree is formed that does not inherit from `EnvironmentValues`,
            consider using `AtomScope` to pass it.
            That happens when using SwiftUI view wrapped with `UIHostingController`.

            ```
            struct ExampleView: View {
                @ViewContext
                var context

                var body: some View {
                    UIViewWrappingView {
                        AtomScope(context) {
                            WrappedView()
                        }
                    }
                }
            }
            ```

            The modal screen presented by the `.sheet` modifier or etc, inherits from the environment values,
            but only in iOS14, there is a bug where the environment values will be dismantled during it is
            dismissing. This also can be avoided by using `AtomScope` to explicitly inherit from it.

            ```
            .sheet(isPresented: ...) {
                AtomScope(context) {
                    ExampleView()
                }
            }
            ```
            """
        )

        return AtomStore()
    }
}
