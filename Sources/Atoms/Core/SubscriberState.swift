@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()

    nonisolated(unsafe) var unsubscribe: (@MainActor () -> Void)?

    // TODO: Replace with `isolated deinit` (SE-0371) once swiftlang/swift#85663 is fixed.
    deinit {
        MainActor.performIsolated { [unsubscribe] in
            unsubscribe?()
        }
    }
}
