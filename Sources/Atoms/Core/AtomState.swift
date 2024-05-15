@MainActor
internal protocol AtomStateProtocol: AnyObject {
    associatedtype Effect: AtomEffect

    var effect: Effect { get }
    var transaction: Transaction? { get set }
}

internal final class AtomState<Effect: AtomEffect>: AtomStateProtocol {
    let effect: Effect
    var transaction: Transaction?

    init(effect: Effect) {
        self.effect = effect
    }
}
