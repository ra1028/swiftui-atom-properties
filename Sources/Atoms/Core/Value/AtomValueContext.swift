@MainActor
public struct AtomValueContext<Value> {
    @usableFromInline
    internal typealias _Update = @MainActor (_ value: Value, _ updatesDependentsOnNextRunLoop: Bool) -> Void
    @usableFromInline
    internal typealias _AddTermination = @MainActor (_ termination: @MainActor @escaping () -> Void) -> Void

    @usableFromInline
    internal let atomContext: AtomRelationContext
    @usableFromInline
    internal let _update: _Update
    @usableFromInline
    internal let _addTermination: _AddTermination

    internal init(
        atomContext: AtomRelationContext,
        update: @escaping _Update,
        addTermination: @escaping _AddTermination
    ) {
        self.atomContext = atomContext
        self._update = update
        self._addTermination = addTermination
    }

    @inlinable
    internal func update(with value: Value, updatesDependentsOnNextRunLoop: Bool = false) {
        _update(value, updatesDependentsOnNextRunLoop)
    }

    @inlinable
    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _addTermination(termination)
    }
}
