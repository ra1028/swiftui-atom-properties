import Combine
import Foundation

public struct ObservableObjectAtomValue<ObjectType: ObservableObject>: AtomValue {
    public typealias Value = ObjectType

    private let makeObject: @MainActor (AtomRelationContext) -> ObjectType

    internal init(makeObject: @MainActor @escaping (AtomRelationContext) -> ObjectType) {
        self.makeObject = makeObject
    }

    public func get(context: Context) -> ObjectType {
        let object = makeObject(context.atomContext)
        return lookup(context: context, with: object)
    }

    public func lookup(context: Context, with object: ObjectType) -> ObjectType {
        let cancellable = object.objectWillChange.sink { [weak object] _ in
            guard let object = object else {
                return
            }

            // At the timing when `ObservableObject/objectWillChange` emits,
            // its properties have not yet been updated and is old when
            // the downstream atom reads it.
            // As a workaround, the update is executed in the next run loop
            // so that the downstream atoms can receive the updated value.
            RunLoop.current.perform {
                context.update(with: object)
            }
        }

        context.addTermination(cancellable.cancel)
        return object
    }
}
