import Combine
import Foundation

public struct ObservableObjectAtomLoader<ObjectType: ObservableObject>: AtomLoader {
    public typealias Value = ObjectType

    private let makeObject: @MainActor (AtomTransactionContext) -> ObjectType

    internal init(makeObject: @MainActor @escaping (AtomTransactionContext) -> ObjectType) {
        self.makeObject = makeObject
    }

    public func get(context: Context) -> ObjectType {
        let object = context.transaction(makeObject)
        return handle(context: context, with: object)
    }

    public func handle(context: Context, with object: ObjectType) -> ObjectType {
        let cancellable = object.objectWillChange.sink { [weak object] _ in
            guard let object = object else {
                return
            }

            context.update(with: object, updatesChildrenOnNextRunLoop: true)
        }

        context.addTermination(cancellable.cancel)
        return object
    }
}
