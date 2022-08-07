import Combine

public final class ObservableObjectAtomState<ObjectType: ObservableObject>: AtomState {
    private var object: ObjectType?
    private let makeObject: @MainActor (AtomRelationContext) -> ObjectType

    internal init(makeObject: @MainActor @escaping (AtomRelationContext) -> ObjectType) {
        self.makeObject = makeObject
    }

    public func value(context: Context) -> ObjectType {
        if let object = object {
            return object
        }

        let object = makeObject(context.atomContext)
        override(context: context, with: object)
        return object
    }

    public func terminate() {
        object = nil
    }

    public func override(context: Context, with object: ObjectType) {
        let cancellable = object.objectWillChange.sink { _ in
            context.notifyUpdate()
        }

        self.object = object
        context.addTermination(cancellable.cancel)
    }
}
