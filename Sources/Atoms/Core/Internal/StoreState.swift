internal struct StoreState {
    var atomStates = [AtomKey: AtomStateBase]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var scheduledReleaseTasks = [AtomKey: Task<Void, Never>]()
}

internal final class AtomState<Node: Atom>: AtomStateBase {
    var value: Node.State.Value?
    var terminations = ContiguousArray<Termination>()

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }
}

internal protocol AtomStateBase {
    var shouldKeepAlive: Bool { get }
    var terminations: ContiguousArray<Termination> { get set }
}
