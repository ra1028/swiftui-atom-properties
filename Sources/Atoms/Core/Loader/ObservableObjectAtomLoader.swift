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
        return manageOverridden(value: object, context: context)
    }

    /// Manage given overridden value updates and cancellations.
    public func manageOverridden(value: Value, context: Context) -> Value {
        let cancellable = value
            .objectWillChange
            .sink { [weak value] _ in
                // Wait until the object's property is set, because `objectWillChange`
                // emits an event before the property is updated.
                RunLoop.main.perform(inModes: [.common]) {
                    if !context.isTerminated, let value {
                        context.update(with: value)
                    }
                }
            }

        context.addTermination(cancellable.cancel)

        return value
    }
}
