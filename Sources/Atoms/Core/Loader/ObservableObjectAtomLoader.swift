import Combine
import Foundation

/// A loader protocol that represents an actual implementation of `ObservableObjectAtom`.
public struct ObservableObjectAtomLoader<Node: ObservableObjectAtom>: AtomLoader {
    /// A type of value to provide.
    public typealias Value = Node.ObjectType

    public typealias Coordinator = Node.Coordinator

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> Value {
        let object = context.transaction(atom.object)
        return handle(context: context, with: object)
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with object: Value) -> Value {
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
