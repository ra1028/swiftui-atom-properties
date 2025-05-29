@usableFromInline
@MainActor
internal final class ScopeState {
    let token = ScopeKey.Token()

    #if !hasFeature(IsolatedDefaultValues)
        nonisolated init() {}
    #endif

    nonisolated(unsafe) var unregister: (@MainActor () -> Void)?

    // TODO: Use isolated synchronous deinit once it's available.
    // 0371-isolated-synchronous-deinit
    deinit {
        MainActor.performIsolated { [unregister] in
            unregister?()
        }
    }
}
