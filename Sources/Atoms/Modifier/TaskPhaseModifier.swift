public extension Atom where Hook: AtomTaskHook {
    /// Converts the `Task` that the original atom provides into ``AsyncPhase`` that
    /// changes overtime.
    ///
    /// ```swift
    /// struct AsyncIntAtom: TaskAtom, Hashable {
    ///     func value(context: Context) async -> Int {
    ///         try? await Task.sleep(nanoseconds: 1_000_000_000)
    ///         return 12345
    ///     }
    /// }
    ///
    /// struct ExampleView: View {
    ///     @Watch(AsyncIntAtom().phase)
    ///     var intPhase
    ///
    ///     var body: some View {
    ///         switch intPhase {
    ///         case .success(let value):
    ///             Text("Value is \(value)")
    ///
    ///         case .suspending:
    ///             Text("Loading")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// This modifier converts the `Task` that the original atom provides into ``AsyncPhase``
    /// and notifies its changes to downstream atoms and views.
    @MainActor
    var phase: TaskPhaseModifierAtom<Self> {
        TaskPhaseModifierAtom(base: self)
    }
}

/// An atom that provides a sequential value of the base atom as an enum
/// representation ``AsyncPhase`` that changes overtime.
///
/// You can also use ``Atom/phase`` to constract this atom.
public struct TaskPhaseModifierAtom<Base: Atom>: Atom where Base.Hook: AtomTaskHook {
    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {
        private let base: Base.Key

        fileprivate init(_ base: Base.Key) {
            self.base = base
        }
    }

    private let base: Base

    /// Creates a new atom instance with given base atom.
    public init(base: Base) {
        self.base = base
    }

    /// A unique value used to identify the atom internally.
    public var key: Key {
        Key(base.key)
    }

    /// The hook for managing the state of this atom internally.
    public var hook: TaskPhaseModifierHook<Base> {
        Hook(base: base)
    }
}
