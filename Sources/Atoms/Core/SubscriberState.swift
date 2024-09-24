import Foundation

@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()
    let subscribing = LockSendable(Set<AtomKey>())
    let unsubscribe = LockSendable<((Set<AtomKey>) -> Void)?>(nil)

    // TODO: Use isolated synchronous deinit once it's available.
    // 0371-isolated-synchronous-deinit
    deinit {
        if Thread.isMainThread {
            unsubscribe.value?(subscribing.value)
        }
        else {
            Task(priority: .high) { @MainActor [unsubscribe, subscribing] in
                unsubscribe.value?(subscribing.value)
            }
        }
    }
}
