@MainActor
internal struct StoreState {
    var atomStates = [AtomKey: AtomState]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var currentTransaction = [AtomKey: Transaction]()

    nonisolated init() {}

    func hasSubscriptions(for key: AtomKey) -> Bool {
        guard let subscriptions = subscriptions[key] else {
            return false
        }
        return !subscriptions.isEmpty
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
}
