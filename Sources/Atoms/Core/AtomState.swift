@MainActor
internal protocol AtomStateBase {
    var transaction: Transaction? { get nonmutating set }
    var subscriptions: [SubscriptionKey: Subscription] { get nonmutating set }
}

internal final class AtomState<Coordinator>: AtomStateBase {
    let coordinator: Coordinator
    var transaction: Transaction?
    var subscriptions = [SubscriptionKey: Subscription]()

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
