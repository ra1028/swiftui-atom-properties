public extension Atom where Produced: Equatable {
    /// Prevents the atom from updating its downstream when its new value is equivalent to old value.
    ///
    /// ```swift
    /// struct FlagAtom: StateAtom, Hashable {
    ///     func defaultValue(context: Context) -> Bool {
    ///         true
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(FlagAtom().changes)
    ///     var flag
    ///
    ///     var body: some View {
    ///         if flag {
    ///             Text("true")
    ///         }
    ///         else {
    ///             Text("false")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    var changes: ModifiedAtom<Self, ChangesModifier<Produced>> {
        modifier(ChangesModifier())
    }
}

/// A modifier that prevents the atom from updating its child views or atoms when
/// its new value is the same as its old value.
///
/// Use ``Atom/changes`` instead of using this modifier directly.
public struct ChangesModifier<Produced: Equatable>: AtomModifier {
    /// A type of base value to be modified.
    public typealias Base = Produced

    /// A type of value the modified atom produces.
    public typealias Produced = Produced

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable, Sendable {}

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// A producer that produces the value of this atom.
    public func producer(atom: some Atom<Base>) -> AtomProducer<Produced> {
        AtomProducer { context in
            context.transaction { $0.watch(atom) }
        } shouldUpdate: { oldValue, newValue in
            oldValue != newValue
        }
    }
}
