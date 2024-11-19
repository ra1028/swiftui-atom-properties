public extension Atom {
    /// Derives a partial property with the specified key path from the original atom and prevent it
    /// from updating its downstream when its new value is equivalent to old value.
    ///
    /// ```swift
    /// struct IntAtom: ValueAtom, Hashable {
    ///     func value(context: Context) -> Int {
    ///         12345
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(IntAtom().changes(of: \.description))
    ///     var description
    ///
    ///     var body: some View {
    ///         Text(description)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A key path for the property of the original atom value.
    ///
    /// - Returns: An atom that provides the partial property of the original atom value.
    #if swift(>=6) || hasFeature(InferSendableFromCaptures)
        func changes<T: Equatable>(
            of keyPath: any KeyPath<Produced, T> & Sendable
        ) -> ModifiedAtom<Self, ChangesOfModifier<Produced, T>> {
            modifier(ChangesOfModifier(keyPath: keyPath))
        }
    #else
        func changes<T: Equatable>(
            of keyPath: KeyPath<Produced, T>
        ) -> ModifiedAtom<Self, ChangesOfModifier<Produced, T>> {
            modifier(ChangesOfModifier(keyPath: keyPath))
        }
    #endif
}

/// A modifier that derives a partial property with the specified key path from the original atom
/// and prevent it from updating its downstream when its new value is equivalent to old value.
///
/// Use ``Atom/changes(of:)`` instead of using this modifier directly.
public struct ChangesOfModifier<Base, Produced: Equatable>: AtomModifier {
    /// A type of base value to be modified.
    public typealias Base = Base

    /// A type of value the modified atom produces.
    public typealias Produced = Produced

    #if swift(>=6) || hasFeature(InferSendableFromCaptures)
        /// A type representing the stable identity of this modifier.
        public struct Key: Hashable, Sendable {
            private let keyPath: any KeyPath<Base, Produced> & Sendable

            fileprivate init(keyPath: any KeyPath<Base, Produced> & Sendable) {
                self.keyPath = keyPath
            }
        }

        private let keyPath: any KeyPath<Base, Produced> & Sendable

        internal init(keyPath: any KeyPath<Base, Produced> & Sendable) {
            self.keyPath = keyPath
        }

        /// A unique value used to identify the modifier internally.
        public var key: Key {
            Key(keyPath: keyPath)
        }
    #else
        public struct Key: Hashable, Sendable {
            private let keyPath: UnsafeUncheckedSendable<KeyPath<Base, Produced>>

            fileprivate init(keyPath: UnsafeUncheckedSendable<KeyPath<Base, Produced>>) {
                self.keyPath = keyPath
            }
        }

        private let _keyPath: UnsafeUncheckedSendable<KeyPath<Base, Produced>>
        private var keyPath: KeyPath<Base, Produced> {
            _keyPath.value
        }

        internal init(keyPath: KeyPath<Base, Produced>) {
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
            let value = context.transaction { $0.watch(atom) }
            return value[keyPath: keyPath]
        } shouldUpdate: { oldValue, newValue in
            oldValue != newValue
        }
    }
}
