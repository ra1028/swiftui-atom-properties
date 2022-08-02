public extension Atom where Hook: AtomTaskHook {
    @MainActor
    var phase: ModifiedAtom<TaskPhaseModifier<Self>> {
        ModifiedAtom(modifier: TaskPhaseModifier(atom: self))
    }
}

public struct TaskPhaseModifier<Node: Atom>: AtomModifier where Node.Hook: AtomTaskHook {
    public typealias Value = AsyncPhase<Node.Hook.Success, Node.Hook.Failure>

    public struct Key: Hashable {
        private let atomKey: Node.Key

        fileprivate init(_ atomKey: Node.Key) {
            self.atomKey = atomKey
        }
    }

    public final class Coordinator {
        internal var phase: Value?
    }

    private let atom: Node

    internal init(atom: Node) {
        self.atom = atom
    }

    public var key: Key {
        Key(atom.key)
    }

    public func shouldNotifyUpdate(newValue: AsyncPhase<Node.Hook.Success, Node.Hook.Failure>, oldValue: AsyncPhase<Node.Hook.Success, Node.Hook.Failure>) -> Bool {
        true
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func value(context: Context) -> Value {
        context.coordinator.phase ?? _assertingFallbackValue(context: context)
    }

    public func update(context: Context) {
        let task = Task {
            let phase = await AsyncPhase(context.atomContext.watch(atom).result)

            if !Task.isCancelled {
                context.coordinator.phase = phase
                context.notifyUpdate()
            }
        }

        context.coordinator.phase = .suspending
        context.addTermination(task.cancel)
    }

    public func updateOverride(context: Context, with value: Value) {
        context.coordinator.phase = value
    }
}
