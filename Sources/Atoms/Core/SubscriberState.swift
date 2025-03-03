@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()

    #if !hasFeature(IsolatedDefaultValues)
        nonisolated init() {}
    #endif

    #if compiler(>=6)
        var subscribing = Set<AtomKey>()
        var unsubscribe: (@MainActor (Set<AtomKey>) -> Void)?

        // TODO: Use isolated synchronous deinit once it's available.
        // 0371-isolated-synchronous-deinit
        deinit {
            MainActor.performIsolated { [unsubscribe, subscribing] in
                unsubscribe?(subscribing)
            }
        }
    #else
        private var _subscribing = UnsafeUncheckedSendable(Set<AtomKey>())
        private var _unsubscribe = UnsafeUncheckedSendable<(@MainActor (Set<AtomKey>) -> Void)?>(nil)

        var subscribing: Set<AtomKey> {
            _read { yield _subscribing.value }
            _modify { yield &_subscribing.value }
        }

        var unsubscribe: (@MainActor (Set<AtomKey>) -> Void)? {
            _read { yield _unsubscribe.value }
            _modify { yield &_unsubscribe.value }
        }

        deinit {
            MainActor.performIsolated { [_unsubscribe, _subscribing] in
                _unsubscribe.value?(_subscribing.value)
            }
        }
    #endif
}
