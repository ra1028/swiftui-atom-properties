@MainActor
internal protocol AtomStateProtocol: AnyObject {
    associatedtype Effect: AtomEffect

    var effect: Effect { get }
    var initializedScopeKey: ScopeKey? { get }
    var transactionState: TransactionState? { get set }
}

@MainActor
internal final class AtomState<Effect: AtomEffect>: AtomStateProtocol {
    let effect: Effect
    let initializedScopeKey: ScopeKey?
    var transactionState: TransactionState?

    init(effect: Effect, initializedScopeKey: ScopeKey?) {
        self.effect = effect
        self.initializedScopeKey = initializedScopeKey
    }
}
