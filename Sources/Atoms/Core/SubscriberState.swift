import Foundation

@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()
    var subscribing = UnsafeUncheckedSendable(Set<AtomKey>())
    var unsubscribe = UnsafeUncheckedSendable<((Set<AtomKey>) -> Void)?>(nil)

    // TODO: Use isolated synchronous deinit once it's available.
    // 0371-isolated-synchronous-deinit
    deinit {
        if Thread.isMainThread {
            unsubscribe.value?(subscribing.value)
        }
        else {
            Task { @MainActor [unsubscribe, subscribing] in
                unsubscribe.value?(subscribing.value)
            }
        }
    }
}
