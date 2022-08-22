@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    var subscriptions = [AtomKey: Subscription]()

    deinit {
        for subscription in ContiguousArray(subscriptions.values) {
            subscription.unsubscribe()
        }
    }
}
