import Combine

/// A state that is actual implementation of `ObservableObjectAtom`.
public final class ObservableObjectAtomState<ObjectType: ObservableObject>: AtomState {
    private var object: ObjectType?
    private let makeObject: @MainActor (AtomRelationContext) -> ObjectType

    internal init(makeObject: @MainActor @escaping (AtomRelationContext) -> ObjectType) {
        self.makeObject = makeObject
    }

    /// Returns a value with initiating the update process and caches the value for the next access.
    public func value(context: Context) -> ObjectType {
        if let object = object {
            return object
        }

        let object = makeObject(context.atomContext)
        override(with: object, context: context)
        return object
    }

    /// Overrides the value with an arbitrary value.
    public func override(with object: ObjectType, context: Context) {
        let cancellable = object.objectWillChange.sink { _ in
            context.notifyUpdate()
        }

        self.object = object
        context.addTermination(cancellable.cancel)
    }
}
