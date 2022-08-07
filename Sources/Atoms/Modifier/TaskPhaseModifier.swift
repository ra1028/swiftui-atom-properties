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
    var phase: ModifiedAtom<Self, TaskPhaseModifier<Hook.Success, Hook.Failure>> {
        modifier(TaskPhaseModifier())
    }
}

/// An atom that provides a sequential value of the base atom as an enum
/// representation ``AsyncPhase`` that changes overtime.
///
/// Use ``Atom/phase`` instead of using this modifier directly.
public struct TaskPhaseModifier<Success, Failure: Error>: AtomModifier {
    /// A type of value that this modifier provides.
    public typealias ModifiedValue = AsyncPhase<Success, Failure>

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {}

    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var phase: ModifiedValue?
    }

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets the value with the given context.
    public func get(context: Context) -> ModifiedValue? {
        context.coordinator.phase
    }

    /// Sets a value with the given context.
    public func set(value: ModifiedValue, context: Context) {
        context.coordinator.phase = value
    }

    /// Starts updating the current value by modifying the given value.
    public func update(context: Context, with value: Task<Success, Failure>) {
        let task = Task {
            let phase = await AsyncPhase(value.result)

            if !Task.isCancelled {
                context.coordinator.phase = phase
                context.notifyUpdate()
            }
        }

        context.coordinator.phase = .suspending
        context.addTermination(task.cancel)
    }
}
