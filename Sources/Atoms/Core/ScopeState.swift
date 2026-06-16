@usableFromInline
@MainActor
internal final class ScopeState {
    let token = ScopeKey.Token()

    nonisolated(unsafe) var unregister: (@MainActor () -> Void)?

    // TODO: Replace with `isolated deinit` (SE-0371) once swiftlang/swift#85663 is fixed.
    deinit {
        MainActor.performIsolated { [unregister] in
            unregister?()
        }
    }
}
