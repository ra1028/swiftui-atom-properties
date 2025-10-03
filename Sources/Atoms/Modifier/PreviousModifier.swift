public extension Atom {
    /// Provides the previous value of the atom instead of the current value.
    ///
    /// ```swift
    /// struct CounterAtom: StateAtom, Hashable {
    ///     func defaultValue(context: Context) -> Int {
    ///         0
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(CounterAtom())
    ///     var currentValue
    ///
    ///     @Watch(CounterAtom().previous)
    ///     var previousValue
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Current: \(currentValue)")
    ///             Text("Previous: \(previousValue ?? 0)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    var previous: ModifiedAtom<Self, PreviousModifier<Produced>> {
        modifier(PreviousModifier())
    }
}

/// A modifier that provides the previous value of the atom instead of the current value.
///
/// Use ``Atom/previous`` instead of using this modifier directly.
public struct PreviousModifier<Base>: AtomModifier {
    /// A type of base value to be modified.
    public typealias Base = Base

    /// A type of value the modified atom produces.
    public typealias Produced = Base?

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable, Sendable {}

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// A producer that produces the value of this atom.
    public func producer(atom: some Atom<Base>) -> AtomProducer<Produced> {
        AtomProducer { context in
            context.transaction { context in
                let value = context.watch(atom)
                let storage = context.watch(StorageAtom())
                let previous = storage.previous
                storage.previous = value
                return previous
            }
        }
    }
}

private extension PreviousModifier {
    @MainActor
    final class Storage {
        var previous: Base?
    }

    struct StorageAtom: ValueAtom, Hashable {
        func value(context: Context) -> Storage {
            Storage()
        }
    }
}
