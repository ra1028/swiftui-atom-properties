@MainActor
internal protocol AtomStateProtocol: AnyObject {
    associatedtype Coordinator

    var coordinator: Coordinator { get }
    var transaction: Transaction? { get set }
}

internal final class AtomState<Coordinator>: AtomStateProtocol {
    let coordinator: Coordinator
    var transaction: Transaction?

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
