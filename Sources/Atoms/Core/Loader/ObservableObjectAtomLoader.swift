import Combine
import Foundation

/// A loader protocol that represents an actual implementation of `ObservableObjectAtom`.
public struct ObservableObjectAtomLoader<Node: ObservableObjectAtom>: AtomLoader {
    /// A type of value to provide.
    public typealias Value = Node.ObjectType

    /// A type to coordinate with the atom.
    public typealias Coordinator = Node.Coordinator

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    /// Returns a new value for the corresponding atom.
    public func value(context: Context) -> Value {
        let object = context.transaction(atom.object)
        return associateOverridden(value: object, context: context)
    }

    /// Associates given value and handle updates and cancellations.
    public func associateOverridden(value: Value, context: Context) -> Value {
        let cancellable = value.objectWillChange.sink { [weak value] _ in
            guard let value else {
                return
            }

            context.update(with: value, order: .objectWillChange)
        }

        context.addTermination(cancellable.cancel)

        return value
    }
}
