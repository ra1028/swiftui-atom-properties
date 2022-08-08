public extension Atom where State: AsyncAtomState {
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
    var phase: ModifiedAtom<Self, TaskPhaseModifier<State.Success, State.Failure>> {
        modifier(TaskPhaseModifier())
    }
}

/// An atom that provides a sequential value of the base atom as an enum
/// representation ``AsyncPhase`` that changes overtime.
///
/// Use ``Atom/phase`` instead of using this modifier directly.
public struct TaskPhaseModifier<Success, Failure: Error>: AtomModifier {
    /// A type of modified value to provide.
    public typealias ModifiedValue = AsyncPhase<Success, Failure>

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {}

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// Returns a value with initiating the update process and caches the value for
    /// the next access.
    public func value(context: Context, with task: Task<Success, Failure>, setValue: @escaping SetValue) -> ModifiedValue {
        let task = Task {
            let phase = await AsyncPhase(task.result)

            if !Task.isCancelled {
                setValue(phase)
                context.notifyUpdate()
            }
        }
        context.addTermination(task.cancel)

        let phase = ModifiedValue.suspending
        setValue(phase)

        return phase
    }
}
