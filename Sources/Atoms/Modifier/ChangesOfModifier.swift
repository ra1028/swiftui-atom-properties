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
    func changes<T: Equatable>(
        of keyPath: KeyPath<Produced, T>
    ) -> ModifiedAtom<Self, ChangesOfModifier<Produced, T>> {
        modifier(ChangesOfModifier(keyPath: keyPath))
    }
}

/// A modifier that derives a partial property with the specified key path from the original atom
/// and prevent it from updating its downstream when its new value is equivalent to old value.
///
/// Use ``Atom/changes(of:)`` instead of using this modifier directly.
public struct ChangesOfModifier<Base, Produced: Equatable>: AtomModifier {
    public typealias Base = Base
    public typealias Produced = Produced

    /// A type representing the stable identity of this modifier.
    public struct Key: Hashable {
        private let keyPath: KeyPath<Base, Produced>

        fileprivate init(keyPath: KeyPath<Base, Produced>) {
            self.keyPath = keyPath
        }
    }

    private let keyPath: KeyPath<Base, Produced>

    internal init(keyPath: KeyPath<Base, Produced>) {
        self.keyPath = keyPath
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key(keyPath: keyPath)
    }

    public func producer(atom: some Atom<Base>) -> AtomProducer<Produced, Coordinator> {
        AtomProducer { context in
            let value = context.transaction { $0.watch(atom) }
            return value[keyPath: keyPath]
        } manageValue: { value, _ in
            value
        } shouldUpdate: { oldValue, newValue in
            oldValue != newValue
        } performUpdate: { update in
            update()
        }
    }
}
