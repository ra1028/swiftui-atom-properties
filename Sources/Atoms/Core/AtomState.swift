@MainActor
internal protocol AtomStateProtocol: AnyObject {
    associatedtype Effect: AtomEffect

    var effect: Effect { get }
    var transactionState: TransactionState? { get set }
}

@MainActor
internal final class AtomState<Effect: AtomEffect>: AtomStateProtocol {
    let effect: Effect
    var transactionState: TransactionState?

    init(effect: Effect) {
        self.effect = effect
    }
}
