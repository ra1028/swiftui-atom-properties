@usableFromInline
@MainActor
internal struct StoreContext {
    private let store: AtomStore
    private let scopeKey: ScopeKey
    private let inheritedScopeKeys: [ScopeID: ScopeKey]
    private let observers: [Observer]
    private let overrides: [OverrideKey: any AtomOverrideProtocol]

    let scopedObservers: [Observer]
    let scopedOverrides: [OverrideKey: any AtomOverrideProtocol]

    init(
        store: AtomStore,
        scopeKey: ScopeKey,
        inheritedScopeKeys: [ScopeID: ScopeKey],
        observers: [Observer],
        scopedObservers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol],
        scopedOverrides: [OverrideKey: any AtomOverrideProtocol]
    ) {
        self.store = store
        self.scopeKey = scopeKey
        self.inheritedScopeKeys = inheritedScopeKeys
        self.observers = observers
        self.scopedObservers = scopedObservers
        self.overrides = overrides
        self.scopedOverrides = scopedOverrides
    }

    func inherited(
        scopedObservers: [Observer],
        scopedOverrides: [OverrideKey: any AtomOverrideProtocol]
    ) -> StoreContext {
        StoreContext(
            store: store,
            scopeKey: scopeKey,
            inheritedScopeKeys: inheritedScopeKeys,
            observers: observers,
            scopedObservers: scopedObservers,
            overrides: overrides,
            scopedOverrides: scopedOverrides
        )
    }

    func scoped(
        scopeKey: ScopeKey,
        scopeID: ScopeID,
        observers: [Observer],
        overrides: [OverrideKey: any AtomOverrideProtocol]
    ) -> StoreContext {
        StoreContext(
            store: store,
            scopeKey: scopeKey,
            inheritedScopeKeys: mutating(inheritedScopeKeys) { $0[scopeID] = scopeKey },
            observers: self.observers,
            scopedObservers: observers,
            overrides: self.overrides,
            scopedOverrides: overrides
        )
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Loader.Value {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            return cache.value
        }
        else {
            let cache = makeCache(of: atom, for: key, override: override)
            checkAndRelease(for: key)
            return cache.value
        }
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Loader.Value, for atom: Node) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            update(atom: atom, for: key, newValue: value, oldValue: cache.value)
        }
    }

    @usableFromInline
    func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Loader.Value) -> Void) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            let newValue = mutating(cache.value, body)
            update(atom: atom, for: key, newValue: newValue, oldValue: cache.value)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transaction: Transaction) -> Node.Loader.Value {
        guard !transaction.isTerminated else {
            return read(atom)
        }

        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let cache = getCache(of: atom, for: key, override: override)

        // Add an `Edge` from the upstream to downstream.
        store.graph.dependencies[transaction.key, default: []].insert(key)
        store.graph.children[key, default: []].insert(transaction.key)

        return cache.value
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        subscriber: Subscriber,
        subscription: Subscription
    ) -> Node.Loader.Value {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let cache = getCache(of: atom, for: key, override: override)
        let isNewSubscription = subscriber.subscribingKeys.insert(key).inserted

        store.state.subscriptions[key, default: [:]].updateValue(subscription, forKey: subscriber.key)
        subscriber.unsubscribe = { keys in
            unsubscribe(keys, for: subscriber.key)
        }

        if isNewSubscription {
            notifyUpdateToObservers()
        }

        return cache.value
    }

    @usableFromInline
    @_disfavoredOverload
    func refresh<Node: Atom>(_ atom: Node) async -> Node.Loader.Value where Node.Loader: RefreshableAtomLoader {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let context = prepareForTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = await atom._loader.refresh(overridden: override.value(atom), context: context)
        }
        else {
            value = await atom._loader.refresh(context: context)
        }

        guard let cache = lookupCache(of: atom, for: key) else {
            checkAndRelease(for: key)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !context.isTerminated {
            update(atom: atom, for: key, newValue: value, oldValue: cache.value)
        }

        return value
    }

    @usableFromInline
    func refresh<Node: Refreshable>(_ atom: Node) async -> Node.Loader.Value {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let state = getState(of: atom, for: key)
        let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
        let value = await atom.refresh(context: context)

        guard let transaction = state.transaction, let cache = lookupCache(of: atom, for: key) else {
            checkAndRelease(for: key)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !transaction.isTerminated {
            update(atom: atom, for: key, newValue: value, oldValue: cache.value)
        }

        return value
    }

    @usableFromInline
    @_disfavoredOverload
    func reset<Node: Atom>(_ atom: Node) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            let newCache = makeCache(of: atom, for: key, override: override)
            update(atom: atom, for: key, newValue: newCache.value, oldValue: cache.value)
        }
    }

    @usableFromInline
    func reset<Node: Resettable>(_ atom: Node) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)

        if let state = lookupState(of: atom, for: key) {
            let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
            atom.reset(context: context)
        }
    }

    @usableFromInline
    func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)
        let cache = lookupCache(of: atom, for: key)

        return cache?.value
    }

    @usableFromInline
    func unwatch(_ atom: some Atom, subscriber: Subscriber) {
        let override = lookupOverride(of: atom)
        let scopeKey = lookupScopeKey(of: atom, isScopedOverriden: override?.isScoped ?? false)
        let key = AtomKey(atom, scopeKey: scopeKey)

        subscriber.subscribingKeys.remove(key)
        unsubscribe([key], for: subscriber.key)
    }

    @usableFromInline
    func snapshot() -> Snapshot {
        Snapshot(
            graph: store.graph,
            caches: store.state.caches,
            subscriptions: store.state.subscriptions
        )
    }

    @usableFromInline
    func restore(_ snapshot: Snapshot) {
        let keys = ContiguousArray(snapshot.caches.keys)
        var obsoletedDependencies = [AtomKey: Set<AtomKey>]()

        for key in keys {
            let oldDependencies = store.graph.dependencies[key]
            let newDependencies = snapshot.graph.dependencies[key]

            // Update atom values and the graph.
            store.state.caches[key] = snapshot.caches[key]
            store.graph.dependencies[key] = newDependencies
            store.graph.children[key] = snapshot.graph.children[key]
            obsoletedDependencies[key] = oldDependencies?.subtracting(newDependencies ?? [])
        }

        for key in keys {
            // Release if the atom is no longer used.
            checkAndRelease(for: key)

            // Release dependencies that are no longer dependent.
            if let dependencies = obsoletedDependencies[key] {
                for dependency in ContiguousArray(dependencies) {
                    store.graph.children[dependency]?.remove(key)
                    checkAndRelease(for: dependency)
                }
            }

            // Notify updates only for the subscriptions of restored atoms.
            if let subscriptions = store.state.subscriptions[key] {
                for subscription in ContiguousArray(subscriptions.values) {
                    subscription.update()
                }
            }
        }

        notifyUpdateToObservers()
    }
}

private extension StoreContext {
    func prepareForTransaction<Node: Atom>(
        of atom: Node,
        for key: AtomKey
    ) -> AtomLoaderContext<Node.Loader.Value, Node.Loader.Coordinator> {
        let state = getState(of: atom, for: key)

        // Terminate the ongoing transaction first.
        state.transaction?.terminate()

        // Remove current dependencies.
        let oldDependencies = store.graph.dependencies.removeValue(forKey: key) ?? []

        // Detatch the atom from its dependencies.
        for dependency in ContiguousArray(oldDependencies) {
            store.graph.children[dependency]?.remove(key)
        }

        let transaction = Transaction(key: key) {
            let dependencies = store.graph.dependencies[key] ?? []
            let obsoletedDependencies = oldDependencies.subtracting(dependencies)
            let newDependencies = dependencies.subtracting(oldDependencies)

            for dependency in ContiguousArray(obsoletedDependencies) {
                checkAndRelease(for: dependency)
            }

            if !obsoletedDependencies.isEmpty || !newDependencies.isEmpty {
                notifyUpdateToObservers()
            }
        }

        // Register the transaction state so it can be terminated from anywhere.
        state.transaction = transaction

        return AtomLoaderContext(
            store: self,
            transaction: transaction,
            coordinator: state.coordinator
        ) { newValue in
            if let cache = lookupCache(of: atom, for: key) {
                update(atom: atom, for: key, newValue: newValue, oldValue: cache.value)
            }
        }
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        newValue: Node.Loader.Value,
        oldValue: Node.Loader.Value
    ) {
        store.state.caches[key] = AtomCache(atom: atom, value: newValue)

        // Check if the atom should propagate the update to downstream.
        guard atom._loader.shouldPropagateUpdate(newValue: newValue, oldValue: oldValue) else {
            return
        }

        // Perform side effecbts first.
        let state = getState(of: atom, for: key)
        let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
        atom.updated(newValue: newValue, oldValue: oldValue, context: context)

        // Calculate topological order for updating downstream efficiently.
        let (edges, omitted) = topologicalSort(key: key, store: store)
        var skippingFrom = Set<AtomKey>()

        // Updates the given atom.
        func update(atom: some Atom, for key: AtomKey) {
            guard let cache = lookupCache(of: atom, for: key) else {
                // Here is usually unreachable.
                return
            }

            let override = lookupOverride(of: atom)
            let newCache = makeCache(of: atom, for: key, override: override)

            // Skip if the atom should not propagate update to downstream.
            guard atom._loader.shouldPropagateUpdate(newValue: newCache.value, oldValue: cache.value) else {
                // Record the atom to avoid downstream from being update.
                skippingFrom.insert(key)
                return
            }

            // Perform side effecbts before updating downstream.
            let state = getState(of: atom, for: key)
            let context = AtomCurrentContext(store: self, coordinator: state.coordinator)
            atom.updated(newValue: newCache.value, oldValue: cache.value, context: context)
        }

        // Performs update of the given atom with the parent's context.
        func performUpdate(atom: some Atom, for key: AtomKey, dependency: some Atom) {
            dependency._loader.performPropagativeUpdate {
                update(atom: atom, for: key)
            }
        }

        // Performs update of the given subscription with the parent's context.
        func performUpdate(subscription: Subscription, dependency: some Atom) {
            dependency._loader.performPropagativeUpdate(subscription.update)
        }

        // Do not transitively update atoms that have parent recorded not to update downstream.
        // However, if the topological sorting has already skipped the vertex as a redundant update,
        // it should be performed.
        func convertToValidEdge(_ edge: Edge) -> Edge? {
            guard skippingFrom.contains(edge.from) else {
                return edge
            }

            guard let omittedFrom = omitted[edge.to] else {
                return nil
            }

            guard let fromKey = omittedFrom.subtracting(skippingFrom).first else {
                return nil
            }

            // Switch atom update transaction context (e.g. animation) to a non-skipped one on
            // a best-effort basis.
            // Topological sorting itself does not always produce an idempotent result when multiple
            // dependencies of an atom update simultaneously and there's no valid update order rule to
            // determine which atom produced the transitive update, and thus here chooses a random
            // dependent atom from omitted ones.
            return Edge(from: fromKey, to: edge.to)
        }

        // Performs atom updates ahead of notifying updates to subscriptions.
        for edge in edges {
            switch edge.to {
            case .atom(let key):
                guard let edge = convertToValidEdge(edge) else {
                    // Record the atom to avoid downstream from being update.
                    skippingFrom.insert(key)
                    continue
                }

                if let cache = store.state.caches[key], let dependencyCache = store.state.caches[edge.from] {
                    performUpdate(atom: cache.atom, for: key, dependency: dependencyCache.atom)
                }

            case .subscriber(let key):
                guard let edge = convertToValidEdge(edge) else {
                    continue
                }

                if let subscription = store.state.subscriptions[edge.from]?[key], let dependencyCache = store.state.caches[edge.from] {
                    performUpdate(subscription: subscription, dependency: dependencyCache.atom)
                }
            }
        }

        // Notify the observers after all updates are complete.
        notifyUpdateToObservers()
    }

    func unsubscribe<Keys: Sequence<AtomKey>>(_ keys: Keys, for subscriberKey: SubscriberKey) {
        for key in ContiguousArray(keys) {
            store.state.subscriptions[key]?.removeValue(forKey: subscriberKey)
            checkAndRelease(for: key)
        }

        notifyUpdateToObservers()
    }

    func checkAndRelease(for key: AtomKey) {
        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`, is marked as `Scoped`, or is scoped by override.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        lazy var shouldKeepAlive = !key.isScoped && store.state.caches[key].map { $0.atom is any KeepAlive } ?? false
        lazy var isChildrenEmpty = store.graph.children[key]?.isEmpty ?? true
        lazy var isSubscriptionEmpty = store.state.subscriptions[key]?.isEmpty ?? true
        lazy var shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

        guard shouldRelease else {
            return
        }

        release(for: key)
    }

    func release(for key: AtomKey) {
        // Invalidate transactions, dependencies, and the atom state.
        let dependencies = store.graph.dependencies.removeValue(forKey: key)
        let state = store.state.states.removeValue(forKey: key)
        store.graph.children.removeValue(forKey: key)
        store.state.caches.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)
        state?.transaction?.terminate()

        if let dependencies {
            for dependency in ContiguousArray(dependencies) {
                store.graph.children[dependency]?.remove(key)
                checkAndRelease(for: dependency)
            }
        }
    }

    func getState<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomState<Node.Coordinator> {
        if let state = lookupState(of: atom, for: key) {
            return state
        }

        let coordinator = atom.makeCoordinator()
        let state = AtomState(coordinator: coordinator)
        store.state.states[key] = state
        return state
    }

    func lookupState<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomState<Node.Coordinator>? {
        guard let baseState = store.state.states[key] else {
            return nil
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
            release(for: key)
            return nil
        }

        return state
    }

    func getCache<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: AtomOverride<Node>?
    ) -> AtomCache<Node> {
        lookupCache(of: atom, for: key) ?? makeCache(of: atom, for: key, override: override)
    }

    func makeCache<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: AtomOverride<Node>?
    ) -> AtomCache<Node> {
        let context = prepareForTransaction(of: atom, for: key)
        let value: Node.Loader.Value

        if let override {
            value = atom._loader.manageOverridden(value: override.value(atom), context: context)
        }
        else {
            value = atom._loader.value(context: context)
        }

        let cache = AtomCache(atom: atom, value: value)
        store.state.caches[key] = cache

        return cache
    }

    func lookupCache<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomCache<Node>? {
        guard let baseCache = store.state.caches[key] else {
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
            release(for: key)
            return nil
        }

        return cache
    }

    func lookupOverride<Node: Atom>(of atom: Node) -> AtomOverride<Node>? {
        lazy var overrideKey = OverrideKey(atom)
        lazy var typeOverrideKey = OverrideKey(Node.self)

        // OPTIMIZE: Desirable to reduce the number of dictionary lookups which is currently 4 times.
        let baseScopedOverride = scopedOverrides[overrideKey] ?? scopedOverrides[typeOverrideKey]
        let baseOverride = baseScopedOverride ?? overrides[overrideKey] ?? overrides[typeOverrideKey]

        guard let baseOverride else {
            return nil
        }

        guard let override = baseOverride as? AtomOverride<Node> else {
            assertionFailure(
                """
                [Atoms]
                Detected an illegal override.
                There might be duplicate keys or logic failure.
                Detected: \(type(of: baseOverride))
                Expected: AtomOverride<\(Node.self)>
                """
            )

            return nil
        }

        return override
    }

    func lookupScopeKey<Node: Atom>(of atom: Node, isScopedOverriden: Bool) -> ScopeKey? {
        if isScopedOverriden {
            return scopeKey
        }
        else if let atom = atom as? any Scoped {
            let scopeID = ScopeID(atom.scopeID)
            return inheritedScopeKeys[scopeID]
        }
        else {
            return nil
        }
    }

    func notifyUpdateToObservers() {
        guard !observers.isEmpty || !scopedObservers.isEmpty else {
            return
        }

        let snapshot = snapshot()

        for observer in observers + scopedObservers {
            observer.onUpdate(snapshot)
        }
    }
}
