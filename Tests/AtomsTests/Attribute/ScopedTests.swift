import XCTest

@testable import Atoms

final class ScopedTests: XCTestCase {
    @MainActor
    func testScopedAtoms() {
        struct ScopedAtom<ID: Hashable, T: Hashable>: ValueAtom, Scoped, Equatable {
            let key = UniqueKey()
            let scopeID: ID
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        XCTContext.runActivity(named: "Should be scoped") { _ in
            let store = AtomStore()
            let context = StoreContext(store)
            let scope1Token = ScopeKey.Token()
            let scope1Key = ScopeKey(token: scope1Token)
            let scope2Token = ScopeKey.Token()
            let scope2Key = ScopeKey(token: scope2Token)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)
            let scoped1Context = context.scoped(
                scopeKey: scope1Key,
                scopeID: ScopeID(DefaultScopeID()),
                observers: [],
                overrides: [:]
            )
            let scoped2Context = scoped1Context.scoped(
                scopeKey: scope2Key,
                scopeID: ScopeID(DefaultScopeID()),
                observers: [],
                overrides: [:]
            )
            let atom = ScopedAtom(scopeID: DefaultScopeID(), value: 0)
            let atomScope1Key = AtomKey(atom, scopeKey: scope1Key)
            let atomScope2Key = AtomKey(atom, scopeKey: scope2Key)

            XCTAssertEqual(
                scoped1Context.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {},
                0
            )
            XCTAssertEqual(
                store.state.caches[atomScope1Key] as? AtomCache<ScopedAtom<DefaultScopeID, Int>>,
                AtomCache(atom: atom, value: 0)
            )
            XCTAssertNil(store.state.caches[atomScope2Key])

            scoped1Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[atomScope1Key])

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {},
                0
            )
            XCTAssertEqual(
                store.state.caches[atomScope2Key] as? AtomCache<ScopedAtom<DefaultScopeID, Int>>,
                AtomCache(atom: atom, value: 0)
            )

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[atomScope2Key])
        }

        XCTContext.runActivity(named: "Should be scoped in particular scope") { _ in
            let store = AtomStore()
            let context = StoreContext(store)
            let scope1Token = ScopeKey.Token()
            let scope1Key = ScopeKey(token: scope1Token)
            let scope2Token = ScopeKey.Token()
            let scope2Key = ScopeKey(token: scope2Token)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)
            let scopeID = "Scope 1"
            let scoped1Context = context.scoped(
                scopeKey: scope1Key,
                scopeID: ScopeID(scopeID),
                observers: [],
                overrides: [:]
            )
            let scoped2Context = scoped1Context.scoped(
                scopeKey: scope2Key,
                scopeID: ScopeID(DefaultScopeID()),
                observers: [],
                overrides: [:]
            )
            let atom = ScopedAtom(scopeID: scopeID, value: 0)
            let atomScope1Key = AtomKey(atom, scopeKey: scope1Key)
            let atomScope2Key = AtomKey(atom, scopeKey: scope2Key)

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {},
                0
            )
            XCTAssertEqual(
                store.state.caches[atomScope1Key] as? AtomCache<ScopedAtom<String, Int>>,
                AtomCache(atom: atom, value: 0)
            )
            XCTAssertNil(store.state.caches[atomScope2Key])

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[atomScope1Key])
        }
    }
}
