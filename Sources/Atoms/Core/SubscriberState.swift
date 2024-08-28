import Foundation

@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()
    var subscribing = Set<AtomKey>()
    var unsubscribe: ((Set<AtomKey>) -> Void)?

    // TODO: Use isolated synchronous deinit once it's available.
    // 0371-isolated-synchronous-deinit
    deinit {
        if Thread.isMainThread {
            unsubscribe?(subscribing)
        }
        else {
            Task(priority: .high) { @MainActor [unsubscribe, subscribing] in
                unsubscribe?(subscribing)
            }
        }
    }
}
