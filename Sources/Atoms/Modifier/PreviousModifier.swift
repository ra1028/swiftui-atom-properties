public extension Atom {
    /// Provides the previous value of the atom instead of the current value.
    ///
    /// ## Example
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
                let storage = context.watch(StorageAtom(base: atom, modifier: self))
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

    struct StorageAtom<Node: Atom>: ValueAtom {
        struct Key: Hashable, Sendable {
            private let baseKey: Node.Key
            private let modifierKey: PreviousModifier.Key

            init(baseKey: Node.Key, modifierKey: PreviousModifier.Key) {
                self.baseKey = baseKey
                self.modifierKey = modifierKey
            }
        }

        private let base: Node
        private let modifier: PreviousModifier

        var key: Key {
            Key(baseKey: base.key, modifierKey: modifier.key)
        }

        init(base: Node, modifier: PreviousModifier) {
            self.base = base
            self.modifier = modifier
        }

        func value(context: Context) -> Storage {
            Storage()
        }
    }
}
