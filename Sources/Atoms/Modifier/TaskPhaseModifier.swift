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
/// Use ``TaskAtom/phase`` or ``ThrowingTaskAtom/phase`` instead of using this modifier directly.
public struct TaskPhaseModifier<Success: Sendable, Failure: Error>: AsyncAtomModifier {
    /// A type of base value to be modified.
    public typealias Base = Task<Success, Failure>

    /// A type of value the modified atom produces.
    public typealias Produced = AsyncPhase<Success, Failure>

    /// A type representing the stable identity of this atom associated with an instance.
    public struct Key: Hashable {}

    /// A unique value used to identify the modifier internally.
    public var key: Key {
        Key()
    }

    /// A producer that produces the value of this atom.
    public func producer(atom: some Atom<Base>) -> AtomProducer<Produced, Coordinator> {
        AtomProducer { context in
            let baseTask = context.transaction { $0.watch(atom) }
            let task = Task {
                let phase = await AsyncPhase(baseTask.result)

                if !Task.isCancelled {
                    context.update(with: phase)
                }
            }

            context.onTermination = task.cancel
            return .suspending
        }
    }

    /// A producer that produces the refreshable value of this atom.
    public func refreshProducer(atom: some AsyncAtom<Base>) -> AtomRefreshProducer<Produced, Coordinator> {
        AtomRefreshProducer { context in
            let task = await context.transaction { context in
                await context.refresh(atom)
                return context.watch(atom)
            }

            return await AsyncPhase(task.result)
        }
    }
}
