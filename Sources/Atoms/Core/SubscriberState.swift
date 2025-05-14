@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()

    #if !hasFeature(IsolatedDefaultValues)
        nonisolated init() {}
    #endif

    nonisolated(unsafe) var unsubscribe: (@MainActor () -> Void)?

    // TODO: Use isolated synchronous deinit once it's available.
    // 0371-isolated-synchronous-deinit
    deinit {
        MainActor.performIsolated { [unsubscribe] in
            unsubscribe?()
        }
    }
}
