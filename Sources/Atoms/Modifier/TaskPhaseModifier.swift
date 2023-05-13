public extension Atom where Loader: AsyncAtomLoader {
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
    var phase: ModifiedAtom<Self, TaskPhaseModifier<Loader.Success, Loader.Failure>> {
        modifier(TaskPhaseModifier())
    }
}

/// An atom that provides a sequential value of the base atom as an enum
/// representation ``AsyncPhase`` that changes overtime.
///
/// Use ``Atom/phase`` instead of using this modifier directly.
public struct TaskPhaseModifier<Success, Failure: Error>: AtomModifier {
    /// A type of base value to be modified.
    public typealias BaseValue = Task<Success, Failure>

    /// A type of modified value to provide.
    public typealias Value = AsyncPhase<Success, Failure>

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {}

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// Returns a new value for the corresponding atom.
    public func modify(value: BaseValue, context: Context) -> Value {
        let task = Task {
            let phase = await AsyncPhase(value.result)

            if !Task.isCancelled {
                context.update(with: phase)
            }
        }

        context.addTermination(task.cancel)

        return .suspending
    }

    /// Associates given value and handle updates and cancellations.
    public func associateOverridden(value: Value, context: Context) -> Value {
        value
    }
}
