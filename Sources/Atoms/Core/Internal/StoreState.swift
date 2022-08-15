@MainActor
internal struct StoreState {
    private var atomStates = [AtomKey: AtomState]()
    private var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    private var pendingDependencies = [AtomKey: Set<AtomKey>]()

    nonisolated init() {}

    func hasSubscriptions(for key: AtomKey) -> Bool {
        subscriptions[key].map { !$0.isEmpty } ?? false
    }

    func subscriptions(for key: AtomKey) -> ContiguousArray<Subscription> {
        subscriptions[key].map { ContiguousArray($0.values) } ?? []
    }

    func atomState(for key: AtomKey) -> AtomState? {
        atomStates[key]
    }

    mutating func addAtomStateIfAbsent(for key: AtomKey, _ makeAtomState: () -> AtomState) -> Bool {
        withUnsafeMutablePointer(to: &atomStates[key]) { pointer in
            guard pointer.pointee == nil else {
                return false
            }

            pointer.pointee = makeAtomState()
            return true
        }
    }

    mutating func insert(subscription: Subscription, for subscriptionKey: SubscriptionKey, subscribeFor key: AtomKey) {
        subscriptions[key, default: [:]].updateValue(subscription, forKey: subscriptionKey)
    }

    mutating func insert(pendingDependency dependency: AtomKey, for key: AtomKey) {
        pendingDependencies[key, default: []].insert(dependency)
    }

    mutating func removeSubscription(for subscriptionKey: SubscriptionKey, subscribedFor key: AtomKey) {
        subscriptions[key]?.removeValue(forKey: subscriptionKey)
    }

    mutating func removeSubscriptions(for key: AtomKey) {
        subscriptions.removeValue(forKey: key)
    }

    @discardableResult
    mutating func removePendingDependencies(for key: AtomKey) -> Set<AtomKey> {
        pendingDependencies.removeValue(forKey: key) ?? []
    }

    @discardableResult
    mutating func removeAtomState(for key: AtomKey) -> AtomState? {
        atomStates.removeValue(forKey: key)
    }
}
