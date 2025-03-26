@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()

    #if !hasFeature(IsolatedDefaultValues)
        nonisolated init() {}
    #endif

    #if compiler(>=6)
        nonisolated(unsafe) var unsubscribe: (@MainActor () -> Void)?

        // TODO: Use isolated synchronous deinit once it's available.
        // 0371-isolated-synchronous-deinit
        deinit {
            MainActor.performIsolated { [unsubscribe] in
                unsubscribe?()
            }
        }
    #else
        private var _unsubscribe = UnsafeUncheckedSendable<(@MainActor () -> Void)?>(nil)

        var unsubscribe: (@MainActor () -> Void)? {
            _read { yield _unsubscribe.value }
            _modify { yield &_unsubscribe.value }
        }

        deinit {
            MainActor.performIsolated { [_unsubscribe] in
                _unsubscribe.value?()
            }
        }
    #endif
}
