@usableFromInline
@MainActor
internal struct StoreContext {
    private let store: AtomStore
    private let rootScope: Scope
    private let currentScope: Scope?

    private init(
        store: AtomStore,
        rootScope: Scope,
        currentScope: Scope? = nil
    ) {
        self.store = store
        self.rootScope = rootScope
        self.currentScope = currentScope
    }

    static func root(
        store: AtomStore,
        scopeKey: ScopeKey,
        observers: [Observer],
        overrideContainer: OverrideContainer
    ) -> StoreContext {
        StoreContext(
            store: store,
            rootScope: Scope(
                key: scopeKey,
                observers: observers,
                overrideContainer: overrideContainer,
                ancestorScopeKeys: [:]
            )
        )
    }

    func scoped(
        scopeID: ScopeID,
        scopeKey: ScopeKey,
        observers: [Observer],
        overrideContainer: OverrideContainer
    ) -> StoreContext {
        StoreContext(
            store: store,
            rootScope: rootScope,
            currentScope: Scope(
                key: scopeKey,
                observers: observers,
                overrideContainer: overrideContainer,
                ancestorScopeKeys: mutating(currentScope?.ancestorScopeKeys ?? [:]) { scopeKeys in
                    scopeKeys[scopeID] = scopeKey
                }
            )
        )
    }

    @usableFromInline
    func read<Node: Atom>(_ atom: Node) -> Node.Produced {
        let (key, override) = lookupAtomKeyAndOverride(of: atom)

        if let cache = lookupCache(of: atom, for: key) {
            return cache.value
        }
        else {
            let value = initialize(of: atom, for: key, override: override)
            checkAndRelease(for: key)
            return value
        }
    }

    @usableFromInline
    func set<Node: StateAtom>(_ value: Node.Produced, for atom: Node) {
        let (key, _) = lookupAtomKeyAndOverride(of: atom)

        if let cache = lookupCache(of: atom, for: key) {
            update(atom: atom, for: key, cache: cache, newValue: value)
        }
    }

    @usableFromInline
    func modify<Node: StateAtom>(_ atom: Node, body: (inout Node.Produced) -> Void) {
        let (key, _) = lookupAtomKeyAndOverride(of: atom)

        if let cache = lookupCache(of: atom, for: key) {
            let newValue = mutating(cache.value, body)
            update(atom: atom, for: key, cache: cache, newValue: newValue)
        }
    }

    @usableFromInline
    func watch<Node: Atom>(_ atom: Node, in transactionState: TransactionState) -> Node.Produced {
        guard !transactionState.isTerminated else {
            return read(atom)
        }

        let (key, override) = lookupAtomKeyAndOverride(of: atom)
        let cache = lookupCache(of: atom, for: key)
        let value = cache?.value ?? initialize(of: atom, for: key, override: override)

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
        let (key, override) = lookupAtomKeyAndOverride(of: atom)
        let cache = lookupCache(of: atom, for: key)
        let value = cache?.value ?? initialize(of: atom, for: key, override: override)
        let isNewSubscription = subscriber.subscribing.insert(key).inserted

        if isNewSubscription {
            store.state.subscriptions[key, default: [:]][subscriber.key] = subscription
            subscriber.unsubscribe = { keys in
                unsubscribe(keys, for: subscriber.key)
            }
            notifyUpdateToObservers()
        }

        return value
    }

    @usableFromInline
    @_disfavoredOverload
    func refresh<Node: AsyncAtom>(_ atom: Node) async -> Node.Produced {
        let (key, override) = lookupAtomKeyAndOverride(of: atom)
        let context = prepareForTransaction(of: atom, for: key)
        let value: Node.Produced

        if let override {
            value = override.getValue(atom)
        }
        else {
            value = await atom.refreshProducer.getValue(context)
        }

        await atom.refreshProducer.refreshValue(value, context)

        guard let cache = lookupCache(of: atom, for: key) else {
            checkAndRelease(for: key)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !context.isTerminated {
            update(atom: atom, for: key, cache: cache, newValue: value)
        }

        return value
    }

    @usableFromInline
    func refresh<Node: Refreshable>(_ atom: Node) async -> Node.Produced {
        let (key, _) = lookupAtomKeyAndOverride(of: atom)
        let state = getState(of: atom, for: key)
        let currentContext = AtomCurrentContext(store: self)

        // Detach the dependencies once to delay updating the downstream until
        // this atom's value refresh is complete.
        let dependencies = detachDependencies(for: key)
        let value = await atom.refresh(context: currentContext)

        // Restore dependencies when the refresh is completed.
        attachDependencies(dependencies, for: key)

        guard let transactionState = state.transactionState, let cache = lookupCache(of: atom, for: key) else {
            checkAndRelease(for: key)
            return value
        }

        // Notify update unless it's cancelled or terminated by other operations.
        if !Task.isCancelled && !transactionState.isTerminated {
            update(atom: atom, for: key, cache: cache, newValue: value)
        }

        return value
    }

    @usableFromInline
    @_disfavoredOverload
    func reset(_ atom: some Atom) {
        let (key, override) = lookupAtomKeyAndOverride(of: atom)

        if let cache = lookupCache(of: atom, for: key) {
            let newValue = getValue(of: atom, for: key, override: override)
            update(atom: atom, for: key, cache: cache, newValue: newValue)
        }
    }

    @usableFromInline
    func reset(_ atom: some Resettable) {
        let currentContext = AtomCurrentContext(store: self)
        atom.reset(context: currentContext)
    }

    @usableFromInline
    func lookup<Node: Atom>(_ atom: Node) -> Node.Produced? {
        let (key, _) = lookupAtomKeyAndOverride(of: atom)
        let cache = lookupCache(of: atom, for: key)

        return cache?.value
    }

    @usableFromInline
    func unwatch(_ atom: some Atom, subscriber: Subscriber) {
        let (key, _) = lookupAtomKeyAndOverride(of: atom)

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
            checkAndRelease(for: key)

            // Release dependencies that are no longer dependent.
            if let dependencies = disusedDependencies[key] {
                for dependency in dependencies {
                    store.graph.children[dependency]?.remove(key)
                    checkAndRelease(for: dependency)
                }
            }

            // Notify updates only for the subscriptions of restored atoms.
            if let subscriptions = store.state.subscriptions[key] {
                for subscription in subscriptions.values {
                    subscription.update()
                }
            }
        }

        notifyUpdateToObservers()
    }
}

private extension StoreContext {
    func initialize<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: Override<Node>?
    ) -> Node.Produced {
        let value = getValue(of: atom, for: key, override: override)
        let state = getState(of: atom, for: key)

        store.state.caches[key] = AtomCache(atom: atom, value: value, initializedScope: currentScope)

        let currentContext = AtomCurrentContext(store: self)
        state.effect.initialized(context: currentContext)

        return value
    }

    func update<Node: Atom>(
        atom: Node,
        for key: AtomKey,
        cache: AtomCache<Node>,
        newValue: Node.Produced
    ) {
        store.state.caches[key] = cache.updated(value: newValue)

        // Check whether if the dependent atoms should be updated transitively.
        guard atom.producer.shouldUpdate(cache.value, newValue) else {
            return
        }

        // Perform side effects first.
        let state = getState(of: atom, for: key)
        let currentContext = AtomCurrentContext(store: self)
        state.effect.updated(context: currentContext)

        // Calculate topological order for updating downstream efficiently.
        let (edges, redundantDependencies) = store.topologicalSorted(key: key)
        var skippedDependencies = Set<AtomKey>()
        var updatedScopes = [ScopeKey: Scope]()

        if let currentScope {
            updatedScopes[currentScope.key] = currentScope
        }

        func transitiveUpdate(for key: AtomKey, cache: some AtomCacheProtocol) {
            // Dependents must be updated with the scope at which they were initialised.
            let localContext = StoreContext(
                store: store,
                rootScope: rootScope,
                currentScope: cache.initializedScope
            )

            let didUpdate = localContext.transitiveUpdate(for: key, cache: cache)

            guard didUpdate else {
                // Record the atom to avoid downstream from being update.
                skippedDependencies.insert(key)
                return
            }

            if let scope = cache.initializedScope {
                updatedScopes[scope.key] = scope
            }
        }

        func performUpdate(dependency: some Atom, body: @MainActor () -> Void) {
            dependency.producer.performUpdate(body)
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
                    performUpdate(dependency: dependencyCache.atom) {
                        transitiveUpdate(for: key, cache: cache)
                    }
                }

            case .subscriber(let key):
                guard let edge = validEdge(edge) else {
                    continue
                }

                let subscription = store.state.subscriptions[edge.from]?[key]
                let dependencyCache = store.state.caches[edge.from]

                if let subscription, let dependencyCache {
                    performUpdate(dependency: dependencyCache.atom, body: subscription.update)
                }
            }
        }

        // Notify the observers after all updates are completed.
        notifyUpdateToObservers(scopes: updatedScopes.values)
    }

    func transitiveUpdate(for key: AtomKey, cache: some AtomCacheProtocol) -> Bool {
        // Overridden atoms don't get updated transitively.
        let newValue = getValue(of: cache.atom, for: key, override: nil)

        store.state.caches[key] = cache.updated(value: newValue)

        // Check whether if the dependent atoms should be updated transitively.
        guard cache.atom.producer.shouldUpdate(cache.value, newValue) else {
            return false
        }

        // Perform side effects before updating downstream.
        let state = getState(of: cache.atom, for: key)
        let currentContext = AtomCurrentContext(store: self)
        state.effect.updated(context: currentContext)
        return true
    }

    func release(for key: AtomKey) {
        let dependencies = store.graph.dependencies.removeValue(forKey: key)
        let state = store.state.states.removeValue(forKey: key)

        store.graph.children.removeValue(forKey: key)
        store.state.caches.removeValue(forKey: key)
        store.state.subscriptions.removeValue(forKey: key)

        if let dependencies {
            for dependency in dependencies {
                store.graph.children[dependency]?.remove(key)
                checkAndRelease(for: dependency)
            }
        }

        state?.transactionState?.terminate()

        let currentContext = AtomCurrentContext(store: self)
        state?.effect.released(context: currentContext)
    }

    func checkAndRelease(for key: AtomKey) {
        // The condition under which an atom may be released are as follows:
        //     1. It's not marked as `KeepAlive`, is marked as `Scoped`, or is scoped by override.
        //     2. It has no downstream atoms.
        //     3. It has no subscriptions from views.
        lazy var shouldKeepAlive = !key.isScoped && store.state.caches[key].map { $0.atom is any KeepAlive } ?? false
        lazy var isChildrenEmpty = store.graph.children[key]?.isEmpty ?? true
        lazy var isSubscriptionEmpty = store.state.subscriptions[key]?.isEmpty ?? true
        let shouldRelease = !shouldKeepAlive && isChildrenEmpty && isSubscriptionEmpty

        guard shouldRelease else {
            return
        }

        release(for: key)
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

    func unsubscribe(_ keys: some Sequence<AtomKey>, for subscriberKey: SubscriberKey) {
        for key in keys {
            store.state.subscriptions[key]?.removeValue(forKey: subscriberKey)
            checkAndRelease(for: key)
        }

        notifyUpdateToObservers()
    }

    func prepareForTransaction<Node: Atom>(
        of atom: Node,
        for key: AtomKey
    ) -> AtomProducerContext<Node.Produced> {
        let transactionState = TransactionState(key: key) {
            let oldDependencies = detachDependencies(for: key)

            return {
                let dependencies = store.graph.dependencies[key] ?? []
                let disusedDependencies = oldDependencies.subtracting(dependencies)

                // Release disused dependencies if no longer used.
                for dependency in disusedDependencies {
                    checkAndRelease(for: dependency)
                }
            }
        }

        let state = getState(of: atom, for: key)
        // Terminate the ongoing transaction first.
        state.transactionState?.terminate()
        // Register the transaction state so it can be terminated from anywhere.
        state.transactionState = transactionState

        return AtomProducerContext(store: self, transactionState: transactionState) { newValue in
            if let cache = lookupCache(of: atom, for: key) {
                update(atom: atom, for: key, cache: cache, newValue: newValue)
            }
        }
    }

    func getValue<Node: Atom>(
        of atom: Node,
        for key: AtomKey,
        override: Override<Node>?
    ) -> Node.Produced {
        let context = prepareForTransaction(of: atom, for: key)
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

    func getState<Node: Atom>(of atom: Node, for key: AtomKey) -> AtomState<Node.Effect> {
        if let state = lookupState(of: atom, for: key) {
            return state
        }

        let currentContext = AtomCurrentContext(store: self)
        let effect = atom.effect(context: currentContext)
        let state = AtomState(effect: effect)
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
            release(for: key)
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
            release(for: key)
            return nil
        }

        return cache
    }

    func lookupAtomKeyAndOverride<Node: Atom>(of atom: Node) -> (atomKey: AtomKey, override: Override<Node>?) {
        func lookupOverride(for scope: Scope) -> Override<Node>? {
            scope.overrideContainer.getOverride(for: atom)
        }

        if let currentScope, let override = lookupOverride(for: currentScope) {
            let atomKey = AtomKey(atom, scopeKey: currentScope.key)
            return (atomKey: atomKey, override: override)
        }
        else if let override = lookupOverride(for: rootScope) {
            // The scopeKey should be nil if it's overridden from the root.
            let atomKey = AtomKey(atom, scopeKey: nil)
            return (atomKey: atomKey, override: override)
        }
        else if let atom = atom as? any Scoped {
            let scopeID = ScopeID(atom.scopeID)
            let scopeKey = currentScope?.ancestorScopeKeys[scopeID]
            let atomKey = AtomKey(atom, scopeKey: scopeKey)
            return (atomKey: atomKey, override: nil)
        }
        else {
            let atomKey = AtomKey(atom, scopeKey: nil)
            return (atomKey: atomKey, override: nil)
        }
    }

    func notifyUpdateToObservers() {
        let scopes = currentScope.map { [$0] } ?? []
        notifyUpdateToObservers(scopes: scopes)
    }

    func notifyUpdateToObservers(scopes: some Sequence<Scope>) {
        let observers = rootScope.observers
        let scopedObservers = scopes.flatMap(\.observers)

        guard !observers.isEmpty || !scopedObservers.isEmpty else {
            return
        }

        let snapshot = snapshot()

        for observer in observers + scopedObservers {
            observer.onUpdate(snapshot)
        }
    }
}
