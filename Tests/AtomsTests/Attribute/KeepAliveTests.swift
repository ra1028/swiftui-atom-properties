import XCTest

@testable import Atoms

final class KeepAliveTests: XCTestCase {
    @MainActor
    func testKeepAliveAtoms() {
        struct KeepAliveAtom<T: Hashable>: ValueAtom, KeepAlive, Hashable {
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        struct ScopedKeepAliveAtom<T: Hashable>: ValueAtom, KeepAlive, Scoped, Hashable {
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        XCTContext.runActivity(named: "Should not be released") { _ in
            let store = AtomStore()
            let context = StoreContext(store: store)
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
            let context = StoreContext(store: store)
            let atom = KeepAliveAtom(value: 0)
            let scopeToken = ScopeKey.Token()
            let scopeKey = ScopeKey(token: scopeToken)
            let key = AtomKey(atom, scopeKey: scopeKey)
            let scopedContext = context.scoped(
                scopeKey: scopeKey,
                scopeID: ScopeID(DefaultScopeID()),
                observers: [],
                overrides: [
                    OverrideKey(atom): AtomOverride<KeepAliveAtom<Int>>(isScoped: true) { _ in 10 }
                ]
            )
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertNotNil(store.state.caches[key])

            scopedContext.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Should be released when scoped") { _ in
            let store = AtomStore()
            let context = StoreContext(store: store)
            let atom = ScopedKeepAliveAtom(value: 0)
            let scopeToken = ScopeKey.Token()
            let scopeKey = ScopeKey(token: scopeToken)
            let key = AtomKey(atom, scopeKey: scopeKey)
            let scopedContext = context.scoped(
                scopeKey: scopeKey,
                scopeID: ScopeID(DefaultScopeID()),
                observers: [],
                overrides: [:]
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
