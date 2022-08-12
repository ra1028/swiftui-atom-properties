@MainActor
internal struct StoreState {
    var atomStates = [AtomKey: AtomStateBase]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var scheduledReleaseTasks = [AtomKey: Task<Void, Never>]()

    nonisolated init() {}
}

@MainActor
internal final class AtomState<Node: Atom>: AtomStateBase {
    var atom: Node
    var value: Node.State.Value?
    var terminations = ContiguousArray<Termination>()

    var shouldKeepAlive: Bool {
        Node.shouldKeepAlive
    }

    init(atom: Node) {
        self.atom = atom
    }

    func notifyUnassigned(to observers: [AtomObserver]) {
        for observer in observers {
            observer.atomUnassigned(atom: atom)
        }
    }
}

@MainActor
internal protocol AtomStateBase {
    var shouldKeepAlive: Bool { get }
    var terminations: ContiguousArray<Termination> { get set }

    func notifyUnassigned(to observers: [AtomObserver])
}
