@MainActor
public struct AtomValueContext<Value> {
    @usableFromInline
    internal let atomContext: AtomRelationContext
    @usableFromInline
    internal let _update: (Value) -> Void
    @usableFromInline
    internal let _addTermination: (_ termination: @MainActor @escaping () -> Void) -> Void

    init(
        atomContext: AtomRelationContext,
        update: @escaping (Value) -> Void,
        addTermination: @escaping (_ termination: @MainActor @escaping () -> Void) -> Void
    ) {
        self.atomContext = atomContext
        self._update = update
        self._addTermination = addTermination
    }

    @inlinable
    internal func update(with value: Value) {
        _update(value)
    }

    @inlinable
    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _addTermination(termination)
    }
}
