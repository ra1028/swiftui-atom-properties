import XCTest

@testable import Atoms

final class KeepAliveTests: XCTestCase {
    @MainActor
    func testKeepAliveAtoms() {
        struct KeepAliveAtom<T: Hashable & Sendable>: ValueAtom, KeepAlive, Hashable {
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        struct ScopedKeepAliveAtom<T: Hashable & Sendable>: ValueAtom, KeepAlive, Scoped, Hashable {
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        XCTContext.runActivity(named: "Should not be released") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let atom = KeepAliveAtom(value: 0)
            let key = AtomKey(atom)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            context.unwatch(atom, subscriber: subscriber)
            XCTAssertNotNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should not be released when not scoped") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let atom = ScopedKeepAliveAtom(value: 0)
            let key = AtomKey(atom, scopeKey: nil)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            context.unwatch(atom, subscriber: subscriber)
            XCTAssertNotNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should not be released until scope is released when overridden in scope") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let atom = KeepAliveAtom(value: 0)
            var scopeState: ScopeState! = ScopeState()
            let key = AtomKey(atom, scopeKey: scopeState.token.key)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)
            let scopedContext = context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeState.token.key,
                observers: [],
                overrideContainer: OverrideContainer()
                    .addingOverride(for: atom) { _ in
                        10
                    }
            )

            scopedContext.registerScope(state: scopeState)

            _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            scopedContext.unwatch(atom, subscriber: subscriber)
            XCTAssertNotNil(store.state.caches[key])

            scopeState = nil
            XCTAssertNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should not be released until scope is released when scoped") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let atom = ScopedKeepAliveAtom(value: 0)
            var scopeState: ScopeState! = ScopeState()
            let key = AtomKey(atom, scopeKey: scopeState.token.key)
            let scopedContext = context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeState.token.key
            )
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            scopedContext.registerScope(state: scopeState)

            _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            scopedContext.unwatch(atom, subscriber: subscriber)
            XCTAssertNotNil(store.state.caches[key])

            scopeState = nil
            XCTAssertNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should be released when scope is already released when scoped") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let atom = ScopedKeepAliveAtom(value: 0)
            var scopeState: ScopeState! = ScopeState()
            let key = AtomKey(atom, scopeKey: scopeState.token.key)
            let scopedContext = context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeState.token.key
            )
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            scopedContext.registerScope(state: scopeState)
            scopeState = nil

            _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            scopedContext.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[key])
        }
    }
}
