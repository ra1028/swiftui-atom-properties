public extension TaskAtom {
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
    var phase: ModifiedAtom<Self, TaskPhaseModifier<Success, Never>> {
        modifier(TaskPhaseModifier())
    }
}

public extension ThrowingTaskAtom {
    /// Converts the `Task` that the original atom provides into ``AsyncPhase`` that
    /// changes overtime.
    ///
    /// ```swift
    /// struct AsyncIntAtom: ThrowingTaskAtom, Hashable {
    ///     func value(context: Context) async throws -> Int {
    ///         try await Task.sleep(nanoseconds: 1_000_000_000)
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
    ///         case .failure(let error):
    ///             Text("Error is \(error)")
    ///
    ///         case .suspending:
    ///             Text("Loading")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    var phase: ModifiedAtom<Self, TaskPhaseModifier<Success, Error>> {
        modifier(TaskPhaseModifier())
    }
}

/// An atom that provides a sequential value of the base atom as an enum
/// representation ``AsyncPhase`` that changes overtime.
///
/// Use ``Atom/phase`` instead of using this modifier directly.
public struct TaskPhaseModifier<Success, Failure: Error>: RefreshableAtomModifier {
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

        context.onTermination = task.cancel

        return .suspending
    }

    /// Manage given overridden value updates and cancellations.
    public func manageOverridden(value: Value, context: Context) -> Value {
        value
    }

    /// Refreshes and waits for the passed original value to finish outputting values
    /// and returns a final value.
    public func refresh(modifying value: BaseValue, context: Context) async -> Value {
        context.onTermination = value.cancel

        return await withTaskCancellationHandler {
            await AsyncPhase(value.result)
        } onCancel: {
            value.cancel()
        }
    }

    /// Refreshes and waits for the passed value to finish outputting values
    /// and returns a final value.
    public func refresh(overridden value: Value, context: Context) async -> Value {
        value
    }
}
