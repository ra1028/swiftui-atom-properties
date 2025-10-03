public extension Atom {
    #if hasFeature(InferSendableFromCaptures)
        /// Provides the latest value that matches the specified condition instead of the current value.
        ///
        /// ## Example
        ///
        /// ```swift
        /// struct Item {
        ///     let id: Int
        ///     let isValid: Bool
        /// }
        ///
        /// struct ItemAtom: StateAtom, Hashable {
        ///     func defaultValue(context: Context) -> Item {
        ///         Item(id: 0, isValid: false)
        ///     }
        /// }
        ///
        /// struct ExampleView: View {
        ///     @Watch(ItemAtom())
        ///     var currentItem
        ///
        ///     @Watch(ItemAtom().latest(\.isValid))
        ///     var latestValidItem
        ///
        ///     var body: some View {
        ///         VStack {
        ///             Text("Current ID: \(currentItem.id)")
        ///             Text("Latest Valid ID: \(latestValidItem?.id ?? 0)")
        ///         }
        ///     }
        /// }
        /// ```
        ///
        /// - Parameter keyPath: A key path to a `Bool` property of the atom value that determines whether the value should be retained as the latest.
        ///
        /// - Returns: An atom that provides the latest value that matches the specified condition, or `nil` if no value has matched yet.
        func latest(_ keyPath: any KeyPath<Produced, Bool> & Sendable) -> ModifiedAtom<Self, LatestModifier<Produced>> {
            modifier(LatestModifier(keyPath: keyPath))
        }
    #else
        /// Provides the latest value that matches the specified condition instead of the current value.
        ///
        /// ## Example
        ///
        /// ```swift
        /// struct Item {
        ///     let id: Int
        ///     let isValid: Bool
        /// }
        ///
        /// struct ItemAtom: StateAtom, Hashable {
        ///     func defaultValue(context: Context) -> Item {
        ///         Item(id: 0, isValid: false)
        ///     }
        /// }
        ///
        /// struct ExampleView: View {
        ///     @Watch(ItemAtom())
        ///     var currentItem
        ///
        ///     @Watch(ItemAtom().latest(\.isValid))
        ///     var latestValidItem
        ///
        ///     var body: some View {
        ///         VStack {
        ///             Text("Current ID: \(currentItem.id)")
        ///             Text("Latest Valid ID: \(latestValidItem?.id ?? 0)")
        ///         }
        ///     }
        /// }
        /// ```
        ///
        /// - Parameter keyPath: A key path to a `Bool` property of the atom value that determines whether the value should be retained as the latest.
        ///
        /// - Returns: An atom that provides the latest value that matches the specified condition, or `nil` if no value has matched yet.
        func latest(_ keyPath: KeyPath<Produced, Bool>) -> ModifiedAtom<Self, LatestModifier<Produced>> {
            modifier(LatestModifier(keyPath: keyPath))
        }
    #endif
}

/// A modifier that provides the latest value that matches the specified condition instead of the current value.
///
/// Use ``Atom/latest(_:)`` instead of using this modifier directly.
public struct LatestModifier<Base>: AtomModifier {
    /// A type of base value to be modified.
    public typealias Base = Base

    /// A type of value the modified atom produces.
    public typealias Produced = Base?

    #if hasFeature(InferSendableFromCaptures)
        /// A type representing the stable identity of this modifier.
        public struct Key: Hashable, Sendable {
            private let keyPath: any KeyPath<Base, Bool> & Sendable

            fileprivate init(keyPath: any KeyPath<Base, Bool> & Sendable) {
                self.keyPath = keyPath
            }
        }

        private let keyPath: any KeyPath<Base, Bool> & Sendable

        internal init(keyPath: any KeyPath<Base, Bool> & Sendable) {
            self.keyPath = keyPath
        }

        /// A unique value used to identify the modifier internally.
        public var key: Key {
            Key(keyPath: keyPath)
        }
    #else
        public struct Key: Hashable, Sendable {
            private let keyPath: UnsafeUncheckedSendable<KeyPath<Base, Bool>>

            fileprivate init(keyPath: UnsafeUncheckedSendable<KeyPath<Base, Bool>>) {
                self.keyPath = keyPath
            }
        }

        private let _keyPath: UnsafeUncheckedSendable<KeyPath<Base, Bool>>
        private var keyPath: KeyPath<Base, Bool> {
            _keyPath.value
        }

        internal init(keyPath: KeyPath<Base, Bool>) {
            _keyPath = UnsafeUncheckedSendable(keyPath)
        }

        /// A unique value used to identify the modifier internally.
        public var key: Key {
            Key(keyPath: _keyPath)
        }
    #endif

    /// A producer that produces the value of this atom.
    public func producer(atom: some Atom<Base>) -> AtomProducer<Produced> {
        AtomProducer { context in
            context.transaction { context in
                let value = context.watch(atom)
                let storage = context.watch(StorageAtom())

                if value[keyPath: keyPath] {
                    storage.latest = value
                }

                return storage.latest
            }
        }
    }
}

private extension LatestModifier {
    @MainActor
    final class Storage {
        var latest: Base?
    }

    struct StorageAtom: ValueAtom, Hashable {
        func value(context: Context) -> Storage {
            Storage()
        }
    }
}
