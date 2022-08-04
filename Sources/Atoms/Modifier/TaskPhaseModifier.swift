public extension Atom where Hook: AtomTaskHook {
    @MainActor
    var phase: ModifiedAtom<Self, TaskPhaseModifier<Hook.Success, Hook.Failure>> {
        modifier(TaskPhaseModifier())
    }
}

public struct TaskPhaseModifier<Success, Failure: Error>: AtomModifier {
    public typealias Phase = AsyncPhase<Success, Failure>

    public struct Key: Hashable {}

    public final class Coordinator {
        internal var phase: Phase?
    }

    public var key: Key {
        Key()
    }

    public func shouldNotifyUpdate(newValue: Phase, oldValue: Phase) -> Bool {
        true
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func get(context: Context) -> Phase? {
        context.coordinator.phase
    }

    public func set(value: Phase, context: Context) {
        context.coordinator.phase = value
    }

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
