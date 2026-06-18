public extension Atom {
    /// Delays delivering the value of the atom until it stops changing for the specified
    /// duration.
    ///
    /// Each time the original atom updates, the previously delivered value is kept until
    /// no further updates occur for `duration` seconds, at which point the latest value is
    /// delivered. This is useful to defer reacting to a value that changes rapidly, such as
    /// debouncing a search query while the user is typing. The initial value is delivered
    /// immediately without being debounced.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct QueryAtom: StateAtom, Hashable {
    ///     func defaultValue(context: Context) -> String {
    ///         ""
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(QueryAtom().debounce(for: 0.3))
    ///     var query
    ///
    ///     var body: some View {
    ///         Text(query)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter duration: The duration, in seconds, that the value must remain unchanged
    ///                       before an update is delivered.
    ///
    /// - Returns: An atom that delivers the original value after it settles.
    func debounce(for duration: Double) -> ModifiedAtom<Self, DebounceModifier<Produced>> {
        modifier(DebounceModifier(duration: duration))
    }
}

/// A modifier that delays delivering the value of the atom until it stops changing for the
/// specified duration.
///
/// Use ``Atom/debounce(for:)`` instead of using this modifier directly.
public struct DebounceModifier<Produced>: AtomModifier {
    /// A type of base value to be modified.
    public typealias Base = Produced

    /// A type of value the modified atom produces.
    public typealias Produced = Produced

    /// A type representing the stable identity of this modifier.
    public struct Key: Hashable, Sendable {
        private let duration: Double

        fileprivate init(duration: Double) {
            self.duration = duration
        }
    }

    private let duration: Double

    internal init(duration: Double) {
        self.duration = duration
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key(duration: duration)
    }

    /// A producer that produces the value of this atom.
    public func producer(atom: some Atom<Base>) -> AtomProducer<Produced> {
        AtomProducer { context in
            context.transaction { inner in
                let value = inner.watch(atom)
                let storage = inner.watch(StorageAtom(base: atom, modifier: self))

                // Deliver the first value immediately without debouncing.
                guard case .settled(let settledValue) = storage.state else {
                    storage.state = .settled(value)
                    return value
                }

                // Deliver the latest value once it stays unchanged for the duration. A
                // pending delivery is cancelled when the atom is recomputed or released.
                let task = Task {
                    try? await Task.sleep(seconds: duration)

                    if !Task.isCancelled {
                        storage.state = .settled(value)
                        context.update(with: value)
                    }
                }

                context.onTermination = task.cancel
                return settledValue
            }
        }
    }
}

private extension DebounceModifier {
    @MainActor
    final class Storage {
        // Holds `Base` directly to avoid a double-optional when `Base` is itself optional.
        enum State {
            case empty
            case settled(Base)
        }

        var state = State.empty
    }

    struct StorageAtom<Node: Atom>: ValueAtom {
        struct Key: Hashable, Sendable {
            private let baseKey: Node.Key
            private let modifierKey: DebounceModifier.Key

            init(baseKey: Node.Key, modifierKey: DebounceModifier.Key) {
                self.baseKey = baseKey
                self.modifierKey = modifierKey
            }
        }

        private let base: Node
        private let modifier: DebounceModifier

        var key: Key {
            Key(baseKey: base.key, modifierKey: modifier.key)
        }

        init(base: Node, modifier: DebounceModifier) {
            self.base = base
            self.modifier = modifier
        }

        func value(context: Context) -> Storage {
            Storage()
        }
    }
}

extension DebounceModifier.StorageAtom: Scoped where Node: Scoped {
    var scopeID: Node.ScopeID {
        base.scopeID
    }
}
