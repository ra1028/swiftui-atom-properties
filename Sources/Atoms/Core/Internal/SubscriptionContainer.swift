@MainActor
internal final class SubscriptionContainer {
    var subscriptions = [AtomKey: Subscription]()

    deinit {
        for subscription in subscriptions.values {
            subscription.unsubscribe()
        }
    }
}
