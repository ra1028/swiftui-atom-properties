import Combine
import Foundation

/// A loader protocol that represents an actual implementation of `ObservableObjectAtom`.
public struct ObservableObjectAtomLoader<ObjectType: ObservableObject>: AtomLoader {
    /// A type of value to provide.
    public typealias Value = ObjectType

    private let makeObject: @MainActor (AtomTransactionContext) -> ObjectType

    internal init(makeObject: @MainActor @escaping (AtomTransactionContext) -> ObjectType) {
        self.makeObject = makeObject
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> ObjectType {
        let object = context.transaction(makeObject)
        return handle(context: context, with: object)
    }

    /// Handles updates or cancellation of the passed value.
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
