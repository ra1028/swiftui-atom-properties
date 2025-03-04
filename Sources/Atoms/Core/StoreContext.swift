@usableFromInline
@MainActor
internal struct StoreContext {
    private let store: AtomStore
    private let rootScopeKey: ScopeKey
    private let currentScopeKey: ScopeKey?

    static func registerRoot(
        store: AtomStore,
        scopeKey: ScopeKey,
        overrides: [OverrideKey: any OverrideProtocol],
        observers: [Observer]
    ) -> StoreContext {
        store.state.scopes[scopeKey] = Scope(
            overrides: overrides,
            observers: observers,
            inheritedScopeKeys: [:]
        )

        return StoreContext(
            store: store,
            rootScopeKey: scopeKey,
            currentScopeKey: nil
        )
    }

    func registerScope(
        scopeID: ScopeID,
        scopeKey: ScopeKey,
        overrides: [OverrideKey: any OverrideProtocol],
        observers: [Observer]
    ) -> StoreContext {
        let parentScope = currentScopeKey.flatMap { store.state.scopes[$0] }
        let parentInheritedScopeKeys = parentScope?.inheritedScopeKeys ?? [:]

        store.state.scopes[scopeKey] = Scope(
            overrides: overrides,
            observers: observers,
            inheritedScopeKeys: mutating(parentInheritedScopeKeys) { scopeKeys in
                scopeKeys[scopeID] = scopeKey
            }
        )

        return StoreContext(
            store: store,
            rootScopeKey: rootScopeKey,
            currentScopeKey: scopeKey
        )
    }

    func unregister(scopeKey: ScopeKey) {
        store.state.scopes.removeValue(forKey: scopeKey)
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node, transactionScopeKey: ScopeKey? = nil) -> Node.Produced {
        let (key, override) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            return cache.value
        }
        else {
            let value = initialize(of: atom, for: key, transactionScopeKey: transactionScopeKey, override: override)
            checkAndRelease(for: key, transactionScopeKey: transactionScopeKey)
            return value
        }
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Produced, for atom: Node, transactionScopeKey: ScopeKey? = nil) {
        let (key, _) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            update(atom: atom, for: key, transactionScopeKey: transactionScopeKey, oldValue: cache.value, newValue: value)
        }
    }

    @usableFromInline
    func modify<Node: StateAtom>(_ atom: Node, transactionScopeKey: ScopeKey? = nil, body: (inout Node.Produced) -> Void) {
        let (key, _) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            let newValue = mutating(cache.value, body)
            update(atom: atom, for: key, transactionScopeKey: transactionScopeKey, oldValue: cache.value, newValue: newValue)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transactionState: TransactionState) -> Node.Produced {
        guard !transactionState.isTerminated else {
            return read(atom, transactionScopeKey: transactionState.scopeKey)
        }

        let (key, override) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionState.scopeKey)
        let cache = lookupCache(of: atom, for: key)
        let value = cache?.value ?? initialize(of: atom, for: key, transactionScopeKey: transactionState.scopeKey, override: override)

        // Add an `Edge` from the upstream to downstream.
        store.graph.dependencies[transactionState.key, default: []].insert(key)
        store.graph.children[key, default: []].insert(transactionState.key)

        return value
    }

    @usableFromInline
    func watch<Node: Atom>(
        _ atom: Node,
        subscriber: Subscriber,
        subscription: Subscription
    ) -> Node.Produced {
        let (key, override) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: nil)
        let cache = lookupCache(of: atom, for: key)
        let value = cache?.value ?? initialize(of: atom, for: key, transactionScopeKey: nil, override: override)
        let isNewSubscription = subscriber.subscribing.insert(key).inserted

        if isNewSubscription {
            store.state.subscriptions[key, default: [:]][subscriber.key] = subscription
            subscriber.unsubscribe = { keys in
                unsubscribe(keys, for: subscriber.key)
            }
            notifyUpdateToObservers(transactionScopeKey: nil)
        }

        return value
    }

    @usableFromInline
    @_disfavoredOverload
    func refresh<Node: AsyncAtom>(_ atom: Node, transactionScopeKey: ScopeKey? = nil) async -> Node.Produced {
        let (key, override) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)
        let context = prepareForTransaction(of: atom, for: key, scopeKey: transactionScopeKey)
        let value: Node.Produced

        if let override {
            value = override.getValue(atom)
        }
        else {
            value = await atom.refreshProducer.getValue(context)
        }

        await atom.refreshProducer.refreshValue(value, context)

        guard let cache = lookupCache(of: atom, for: key) else {
            checkAndRelease(for: key, transactionScopeKey: transactionScopeKey)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !context.isTerminated {
            update(atom: atom, for: key, transactionScopeKey: transactionScopeKey, oldValue: cache.value, newValue: value)
        }

        return value
    }

    @usableFromInline
    func refresh<Node: Refreshable>(_ atom: Node, transactionScopeKey: ScopeKey? = nil) async -> Node.Produced {
        let (key, _) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)
        let state = getState(of: atom, for: key, transactionScopeKey: transactionScopeKey)
        let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)

        // Detach the dependencies once to delay updating the downstream until
        // this atom's value refresh is complete.
        let dependencies = detachDependencies(for: key)
        let value = await atom.refresh(context: context)

        // Restore dependencies when the refresh is completed.
        attachDependencies(dependencies, for: key)

        guard let transactionState = state.transactionState, let cache = lookupCache(of: atom, for: key) else {
            checkAndRelease(for: key, transactionScopeKey: transactionScopeKey)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !transactionState.isTerminated {
            update(atom: atom, for: key, transactionScopeKey: transactionScopeKey, oldValue: cache.value, newValue: value)
        }

        return value
    }

    @usableFromInline
    @_disfavoredOverload
    func reset<Node: Atom>(_ atom: Node, transactionScopeKey: ScopeKey? = nil) {
        let (key, override) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)

        if let cache = lookupCache(of: atom, for: key) {
            let newValue = getValue(of: atom, for: key, transactionScopeKey: transactionScopeKey, override: override)
            update(atom: atom, for: key, transactionScopeKey: transactionScopeKey, oldValue: cache.value, newValue: newValue)
        }
    }

    @usableFromInline
    func reset<Node: Resettable>(_ atom: Node, transactionScopeKey: ScopeKey? = nil) {
        let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)
        atom.reset(context: context)
    }

    @usableFromInline
    func lookup<Node: Atom>(_ atom: Node, transactionScopeKey: ScopeKey? = nil) -> Node.Produced? {
        let (key, _) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: transactionScopeKey)
        let cache = lookupCache(of: atom, for: key)

        return cache?.value
    }

    @usableFromInline
    func unwatch(_ atom: some Atom, subscriber: Subscriber) {
        let (key, _) = lookupAtomKeyAndOverrides(of: atom, transactionScopeKey: nil)

        subscriber.subscribing.remove(key)
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
        let keys = snapshot.caches.keys
        var disusedDependencies = [AtomKey: Set<AtomKey>]()

        for key in keys {
            let oldDependencies = store.graph.dependencies[key]
            let newDependencies = snapshot.graph.dependencies[key]

            // Update atom values and the graph.
            store.state.caches[key] = snapshot.caches[key]
            store.graph.dependencies[key] = newDependencies
            store.graph.children[key] = snapshot.graph.children[key]
            disusedDependencies[key] = oldDependencies?.subtracting(newDependencies ?? [])
        }

        for key in keys {
            // Release if the atom is no longer used.
            checkAndRelease(for: key, transactionScopeKey: nil)

            // Release dependencies that are no longer dependent.
            if let dependencies = disusedDependencies[key] {
                for dependency in dependencies {
                    store.graph.children[dependency]?.remove(key)
                    checkAndRelease(for: dependency, transactionScopeKey: nil)
                }
            }

            // Notify updates only for the subscriptions of restored atoms.
            if let subscriptions = store.state.subscriptions[key] {
                for subscription in subscriptions.values {
                    subscription.update()
                }
            }
        }

        notifyUpdateToObservers(transactionScopeKey: nil)
    }
}

private extension StoreContext {
    func initialize<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        transactionScopeKey: ScopeKey?,
        override: Override<Node>?
    ) -> Node.Produced {
        let value = getValue(of: atom, for: key, transactionScopeKey: transactionScopeKey, override: override)
        let state = getState(of: atom, for: key, transactionScopeKey: transactionScopeKey)

        store.state.caches[key] = AtomCache(atom: atom, value: value)

        let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)
        state.effect.initialized(context: context)

        return value
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        transactionScopeKey: ScopeKey?,
        oldValue: Node.Produced,
        newValue: Node.Produced
    ) {
        store.state.caches[key] = AtomCache(atom: atom, value: newValue)

        // Check whether if the dependent atoms should be updated transitively.
        guard atom.producer.shouldUpdate(oldValue, newValue) else {
            return
        }

        // Perform side effects first.
        let state = getState(of: atom, for: key, transactionScopeKey: transactionScopeKey)
        let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)
        state.effect.updated(context: context)

        // Calculate topological order for updating downstream efficiently.
        let (edges, redundantDependencies) = store.topologicalSorted(key: key)
        var skippedDependencies = Set<AtomKey>()
        var updatedScopeKeys = Set<ScopeKey>()

        if let scopeKey = transactionScopeKey ?? currentScopeKey {
            updatedScopeKeys.insert(scopeKey)
        }

        // Updates the given atom.
        func update(for key: AtomKey, cache: some AtomCacheProtocol) {
            guard let state = lookupState(of: cache.atom, for: key) else {
                return
            }

            // Dependants are updated with the scope at which they were initialised.
            let transactionScopeKey = state.initializedScopeKey
            // Overridden atoms don't get updated.
            let newValue = getValue(of: cache.atom, for: key, transactionScopeKey: transactionScopeKey, override: nil)

            store.state.caches[key] = AtomCache(atom: cache.atom, value: newValue)

            // Check whether if the dependent atoms should be updated transitively.
            guard cache.atom.producer.shouldUpdate(cache.value, newValue) else {
                // Record the atom to avoid downstream from being update.
                skippedDependencies.insert(key)
                return
            }

            if let transactionScopeKey {
                updatedScopeKeys.insert(transactionScopeKey)
            }

            // Perform side effects before updating downstream.
            let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)
            state.effect.updated(context: context)
        }

        // Performs update of the given atom with the dependency's context.
        func performUpdate(for key: AtomKey, cache: some AtomCacheProtocol, dependency: some Atom) {
            dependency.producer.performUpdate {
                update(for: key, cache: cache)
            }
        }

        // Performs update of the given subscription with the dependency's context.
        func performUpdate(subscription: Subscription, dependency: some Atom) {
            dependency.producer.performUpdate(subscription.update)
        }

        func validEdge(_ edge: Edge) -> Edge? {
            // Do not transitively update atoms that have dependency recorded not to update downstream.
            guard skippedDependencies.contains(edge.from) else {
                return edge
            }

            // If the topological sorting has marked the vertex as a redundant, the update still performed.
            guard let fromKey = redundantDependencies[edge.to]?.first(where: { !skippedDependencies.contains($0) }) else {
                return nil
            }

            // Convert edge's `from`, which represents a dependency atom, to a non-skipped one to
            // change the update transaction context (e.g. animation).
            return Edge(from: fromKey, to: edge.to)
        }

        // Perform transitive update for dependent atoms ahead of notifying updates to subscriptions.
        for edge in edges {
            switch edge.to {
            case .atom(let key):
                guard let edge = validEdge(edge) else {
                    // Record the atom to avoid downstream from being update.
                    skippedDependencies.insert(key)
                    continue
                }

                let cache = store.state.caches[key]
                let dependencyCache = store.state.caches[edge.from]

                if let cache, let dependencyCache {
                    performUpdate(for: key, cache: cache, dependency: dependencyCache.atom)
                }

            case .subscriber(let key):
                guard let edge = validEdge(edge) else {
                    continue
                }

                let subscription = store.state.subscriptions[edge.from]?[key]
                let dependencyCache = store.state.caches[edge.from]

                if let subscription, let dependencyCache {
                    performUpdate(subscription: subscription, dependency: dependencyCache.atom)
                }
            }
        }

        // Notify the observers after all updates are completed.
        notifyUpdateToObservers(scopeKeys: updatedScopeKeys)
    }

    func release(for key: AtomKey, transactionScopeKey: ScopeKey?) {
        let dependencies = store.graph.dependencies.removeValue(forKey: key)
        let state = store.state.states.removeValue(forKey: key)

        store.graph.children.removeValue(forKey: key)
        store.state.caches.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)

        if let dependencies {
            for dependency in dependencies {
                store.graph.children[dependency]?.remove(key)
                checkAndRelease(for: dependency, transactionScopeKey: transactionScopeKey)
            }
        }

        state?.transactionState?.terminate()

        let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)
        state?.effect.released(context: context)
    }

    func checkAndRelease(for key: AtomKey, transactionScopeKey: ScopeKey?) {
        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`, is marked as `Scoped`, or is scoped by override.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        lazy var shouldKeepAlive = key.scopeKey == nil && store.state.caches[key].map { $0.atom is any KeepAlive } ?? false
        lazy var isChildrenEmpty = store.graph.children[key]?.isEmpty ?? true
        lazy var isSubscriptionEmpty = store.state.subscriptions[key]?.isEmpty ?? true
        let shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

        guard shouldRelease else {
            return
        }

        release(for: key, transactionScopeKey: transactionScopeKey)
    }

    func detachDependencies(for key: AtomKey) -> Set<AtomKey> {
        // Remove current dependencies.
        let dependencies = store.graph.dependencies.removeValue(forKey: key) ?? []

        // Detatch the atom from its children.
        for dependency in dependencies {
            store.graph.children[dependency]?.remove(key)
        }

        return dependencies
    }

    func attachDependencies(_ dependencies: Set<AtomKey>, for key: AtomKey) {
        // Set dependencies.
        store.graph.dependencies[key] = dependencies

        // Attach the atom to its children.
        for dependency in dependencies {
            store.graph.children[dependency]?.insert(key)
        }
    }

    func unsubscribe<Keys: Sequence<AtomKey>>(_ keys: Keys, for subscriberKey: SubscriberKey) {
        for key in keys {
            store.state.subscriptions[key]?.removeValue(forKey: subscriberKey)
            checkAndRelease(for: key, transactionScopeKey: nil)
        }

        notifyUpdateToObservers(transactionScopeKey: nil)
    }

    func prepareForTransaction<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        scopeKey: ScopeKey?
    ) -> AtomProducerContext<Node.Produced> {
        let transactionState = TransactionState(key: key, scopeKey: scopeKey) {
            let oldDependencies = detachDependencies(for: key)

            return {
                let dependencies = store.graph.dependencies[key] ?? []
                let disusedDependencies = oldDependencies.subtracting(dependencies)

                // Release disused dependencies if no longer used.
                for dependency in disusedDependencies {
                    checkAndRelease(for: dependency, transactionScopeKey: scopeKey)
                }
            }
        }

        let state = getState(of: atom, for: key, transactionScopeKey: scopeKey)
        // Terminate the ongoing transaction first.
        state.transactionState?.terminate()
        // Register the transaction state so it can be terminated from anywhere.
        state.transactionState = transactionState

        return AtomProducerContext(store: self, transactionState: transactionState) { newValue in
            guard let cache = lookupCache(of: atom, for: key) else {
                return
            }

            update(
                atom: atom,
                for: key,
                transactionScopeKey: scopeKey,
                oldValue: cache.value,
                newValue: newValue
            )
        }
    }

    func getValue<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        transactionScopeKey: ScopeKey?,
        override: Override<Node>?
    ) -> Node.Produced {
        let context = prepareForTransaction(of: atom, for: key, scopeKey: transactionScopeKey)
        let value: Node.Produced

        if let override {
            value = override.getValue(atom)
        }
        else {
            value = atom.producer.getValue(context)
        }

        atom.producer.manageValue(value, context)
        return value
    }

    func getState<Node: Atom>(of atom: Node, for key: AtomKey, transactionScopeKey: ScopeKey?) -> AtomState<Node.Effect> {
        if let state = lookupState(of: atom, for: key) {
            return state
        }

        let context = AtomCurrentContext(store: self, transactionScopeKey: transactionScopeKey)
        let effect = atom.effect(context: context)
        let state = AtomState(effect: effect, initializedScopeKey: transactionScopeKey ?? currentScopeKey)
        store.state.states[key] = state
        return state
    }

    func lookupState<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomState<Node.Effect>? {
        guard let baseState = store.state.states[key] else {
            return nil
        }

        guard let state = baseState as? AtomState<Node.Effect> else {
            assertionFailure(
                """
                [Atoms]
                The type of the given atom's value and the state did not match.
                There might be duplicate keys, make sure that the keys for all atom types are unique.

                Atom: \(Node.self)
                Key: \(type(of: atom.key))
                Detected: \(type(of: baseState))
                Expected: AtomState<\(Node.Effect.self)>
                """
            )

            // Release the invalid registration as a fallback.
            release(for: key, transactionScopeKey: nil)
            return nil
        }

        return state
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
            release(for: key, transactionScopeKey: nil)
            return nil
        }

        return cache
    }

    func lookupAtomKeyAndOverrides<Node: Atom>(of atom: Node, transactionScopeKey: ScopeKey?) -> (atomKey: AtomKey, override: Override<Node>?) {
        let scopeKey = transactionScopeKey ?? currentScopeKey
        lazy var overrideKey = OverrideKey(atom)
        lazy var typeOverrideKey = OverrideKey(Node.self)

        func lookupOverride(for scopeKey: ScopeKey) -> Override<Node>? {
            let overrides = store.state.scopes[scopeKey]?.overrides
            let baseOverride = overrides?[overrideKey] ?? overrides?[typeOverrideKey]

            guard let baseOverride else {
                return nil
            }

            guard let override = baseOverride as? Override<Node> else {
                assertionFailure(
                    """
                    [Atoms]
                    Detected an illegal override.
                    There might be duplicate keys or logic failure.
                    Detected: \(type(of: baseOverride))
                    Expected: Override<\(Node.self)>
                    """
                )

                return nil
            }

            return override
        }

        if let scopeKey, let override = lookupOverride(for: scopeKey) {
            let atomKey = AtomKey(atom, scopeKey: scopeKey)
            return (atomKey: atomKey, override: override)
        }
        else if let override = lookupOverride(for: rootScopeKey) {
            // The scopeKey should be nil if it's overridden from the root.
            let atomKey = AtomKey(atom, scopeKey: nil)
            return (atomKey: atomKey, override: override)
        }
        else if let atom = atom as? any Scoped {
            let scopeID = ScopeID(atom.scopeID)
            let scope = scopeKey.flatMap { store.state.scopes[$0] }
            let scopeKey = scope?.inheritedScopeKeys[scopeID]
            let atomKey = AtomKey(atom, scopeKey: scopeKey)
            return (atomKey: atomKey, override: nil)
        }
        else {
            let atomKey = AtomKey(atom, scopeKey: nil)
            return (atomKey: atomKey, override: nil)
        }
    }

    func notifyUpdateToObservers(transactionScopeKey: ScopeKey?) {
        let scopeKey = transactionScopeKey ?? currentScopeKey
        notifyUpdateToObservers(scopeKeys: scopeKey.map { [$0] } ?? [])
    }

    func notifyUpdateToObservers<Keys: Sequence<ScopeKey>>(scopeKeys: Keys) {
        let observers = store.state.scopes[rootScopeKey]?.observers ?? []
        let scopedObservers = scopeKeys.flatMap { store.state.scopes[$0]?.observers ?? [] }

        guard !observers.isEmpty || !scopedObservers.isEmpty else {
            return
        }

        let snapshot = snapshot()

        for observer in observers + scopedObservers {
            observer.onUpdate(snapshot)
        }
    }
}
