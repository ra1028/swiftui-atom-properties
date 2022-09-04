@MainActor
internal protocol AtomStateBase {
    var transaction: Transaction? { get nonmutating set }
}

internal final class AtomState<Coordinator>: AtomStateBase {
    let coordinator: Coordinator
    var transaction: Transaction?

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
