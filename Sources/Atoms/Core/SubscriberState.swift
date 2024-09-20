import Foundation

@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()
    var subscribing = LockSendable(Set<AtomKey>())
    var unsubscribe = LockSendable<((Set<AtomKey>) -> Void)?>(nil)

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
