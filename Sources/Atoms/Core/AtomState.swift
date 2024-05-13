@MainActor
internal protocol AtomStateProtocol: AnyObject {
    associatedtype Coordinator
    associatedtype Effect: AtomEffect

    var coordinator: Coordinator { get }
    var effect: Effect { get }
    var transaction: Transaction? { get set }
}

internal final class AtomState<Coordinator, Effect: AtomEffect>: AtomStateProtocol {
    let coordinator: Coordinator
    let effect: Effect
    var transaction: Transaction?

    init(coordinator: Coordinator, effect: Effect) {
        self.coordinator = coordinator
        self.effect = effect
    }
}
