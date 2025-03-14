import XCTest

@testable import Atoms

final class KeepAliveTests: XCTestCase {
    @MainActor
    func testKeepAliveAtoms() {
        struct KeepAliveAtom<T: Hashable>: ValueAtom, KeepAlive, Hashable, @unchecked Sendable {
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        struct ScopedKeepAliveAtom<T: Hashable>: ValueAtom, KeepAlive, Scoped, Hashable, @unchecked Sendable {
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        XCTContext.runActivity(named: "Should not be released") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.registerRoot(in: store, scopeKey: rootScopeToken.key)
            let atom = KeepAliveAtom(value: 0)
            let key = AtomKey(atom)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            context.unwatch(atom, subscriber: subscriber)
            XCTAssertNotNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should be released when overridden") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.registerRoot(in: store, scopeKey: rootScopeToken.key)
            let atom = KeepAliveAtom(value: 0)
            let scopeToken = ScopeKey.Token()
            let key = AtomKey(atom, scopeKey: scopeToken.key)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)
            let scopedContext = context.registerScope(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeToken.key,
                observers: [],
                overrideContainer: OverrideContainer()
                    .addingOverride(for: atom) { _ in
                        10
                    }
            )

            _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            scopedContext.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should be released when scoped") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.registerRoot(in: store, scopeKey: rootScopeToken.key)
            let atom = ScopedKeepAliveAtom(value: 0)
            let scopeToken = ScopeKey.Token()
            let key = AtomKey(atom, scopeKey: scopeToken.key)
            let scopedContext = context.registerScope(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeToken.key
            )
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            scopedContext.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[key])
        }
    }
}
