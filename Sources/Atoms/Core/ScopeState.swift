@MainActor
internal final class ScopeState {
    let token = ScopeKey.Token()

    #if !hasFeature(IsolatedDefaultValues)
        nonisolated init() {}
    #endif

    #if compiler(>=6)
        var unregister: (@MainActor () -> Void)?

        // TODO: Use isolated synchronous deinit once it's available.
        // 0371-isolated-synchronous-deinit
        deinit {
            MainActor.performIsolated { [unregister] in
                unregister?()
            }
        }
    #else
        private var _unregister = UnsafeUncheckedSendable<(@MainActor () -> Void)?>(nil)

        var unregister: (@MainActor () -> Void)? {
            _read { yield _unregister.value }
            _modify { yield &_unregister.value }
        }

        deinit {
            MainActor.performIsolated { [_unregister] in
                _unregister.value?()
            }
        }
    #endif
}
