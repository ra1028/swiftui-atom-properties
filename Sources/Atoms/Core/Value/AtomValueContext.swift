@MainActor
public struct AtomValueContext<Value> {
    @usableFromInline
    internal typealias _Update = @MainActor (_ value: Value, _ updatesDependentsOnNextRunLoop: Bool) -> Void
    @usableFromInline
    internal typealias _AddTermination = @MainActor (_ termination: @MainActor @escaping () -> Void) -> Void

    @usableFromInline
    internal let _atomContext: AtomRelationContext
    @usableFromInline
    internal let _update: _Update
    @usableFromInline
    internal let _addTermination: _AddTermination
    @usableFromInline
    internal let _commitPendingDependencies: () -> Void

    internal init(
        atomContext: AtomRelationContext,
        commitPendingDependencies: @escaping () -> Void,
        update: @escaping _Update,
        addTermination: @escaping _AddTermination
    ) {
        _atomContext = atomContext
        _commitPendingDependencies = commitPendingDependencies
        _update = update
        _addTermination = addTermination
    }

    @inlinable
    internal func update(with value: Value, updatesDependentsOnNextRunLoop: Bool = false) {
        _update(value, updatesDependentsOnNextRunLoop)
    }

    @inlinable
    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _addTermination(termination)
    }

    @inlinable
    internal func withAtomContext<T>(_ body: @MainActor (AtomRelationContext) -> T) -> T {
        defer { _commitPendingDependencies() }
        return body(_atomContext)
    }

    @inlinable
    internal func withAtomContext<T>(_ body: @MainActor (AtomRelationContext) async throws -> T) async rethrows -> T {
        defer { _commitPendingDependencies() }
        return try await body(_atomContext)
    }
}
