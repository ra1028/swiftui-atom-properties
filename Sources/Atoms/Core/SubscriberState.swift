import Foundation

@MainActor
internal final class SubscriberState {
    let token = SubscriberKey.Token()

#if compiler(>=6)
    nonisolated(unsafe) var subscribing = Set<AtomKey>()
    nonisolated(unsafe) var unsubscribe: ((Set<AtomKey>) -> Void)?

    // TODO: Use isolated synchronous deinit once it's available.
    // 0371-isolated-synchronous-deinit
    deinit {
        if Thread.isMainThread {
            unsubscribe?(subscribing)
        }
        else {
            Task { @MainActor [unsubscribe, subscribing] in
                unsubscribe?(subscribing)
            }
        }
    }
#else
    private var _subscribing = UnsafeUncheckedSendable(Set<AtomKey>())
    private var _unsubscribe = UnsafeUncheckedSendable<((Set<AtomKey>) -> Void)?>(nil)

    var subscribing: Set<AtomKey> {
        _read { yield _subscribing.value }
        _modify { yield &_subscribing.value }
    }

    var unsubscribe: ((Set<AtomKey>) -> Void)? {
        _read { yield _unsubscribe.value }
        _modify { yield &_unsubscribe.value }
    }

    deinit {
        if Thread.isMainThread {
            _unsubscribe.value?(_subscribing.value)
        }
        else {
            Task { @MainActor [_unsubscribe, _subscribing] in
                _unsubscribe.value?(_subscribing.value)
            }
        }
    }
#endif
}
