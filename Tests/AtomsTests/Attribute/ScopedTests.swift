import XCTest

@testable import Atoms

final class ScopedTests: XCTestCase {
    @MainActor
    func testScopedAtoms() {
        struct ScopedAtom<ID: Hashable, T: Hashable>: ValueAtom, Scoped, Equatable, @unchecked Sendable {
            let key = UniqueKey()
            let scopeID: ID
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        XCTContext.runActivity(named: "Should be scoped") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let scoped1Context = context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scope1Token.key
            )
            let scoped2Context = scoped1Context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scope2Token.key
            )
            let atom = ScopedAtom(scopeID: DefaultScopeID(), value: 0)
            let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Token.key)
            let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Token.key)

            XCTAssertEqual(
                scoped1Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                store.caches[scoped1AtomKey] as? AtomCache<ScopedAtom<DefaultScopeID, Int>>,
                AtomCache(atom: atom, value: 0)
            )
            XCTAssertNil(store.caches[scoped2AtomKey])

            scoped1Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.caches[scoped1AtomKey])

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                store.caches[scoped2AtomKey] as? AtomCache<ScopedAtom<DefaultScopeID, Int>>,
                AtomCache(atom: atom, value: 0)
            )

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.caches[scoped2AtomKey])
        }

        XCTContext.runActivity(named: "Should be scoped in particular scope") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let scopeID = "Scope 1"
            let scoped1Context = context.scoped(
                scopeID: ScopeID(scopeID),
                scopeKey: scope1Token.key
            )
            let scoped2Context = scoped1Context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scope2Token.key
            )
            let atom = ScopedAtom(scopeID: scopeID, value: 0)
            let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Token.key)
            let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Token.key)

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                store.caches[scoped1AtomKey] as? AtomCache<ScopedAtom<String, Int>>,
                AtomCache(atom: atom, value: 0)
            )
            XCTAssertNil(store.caches[scoped2AtomKey])

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.caches[scoped1AtomKey])
        }

        XCTContext.runActivity(named: "Modified atoms should also be scoped") { _ in
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let scopeID = "Scope 1"
            let scoped1Context = context.scoped(
                scopeID: ScopeID(scopeID),
                scopeKey: scope1Token.key
            )
            let scoped2Context = scoped1Context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scope2Token.key
            )
            let baseAtom = ScopedAtom(scopeID: scopeID, value: 0)
            let atom = baseAtom.changes
            let baseAtomKey = AtomKey(baseAtom, scopeKey: nil)
            let atomKey = AtomKey(atom, scopeKey: nil)
            let scoped1BaseAtomKey = AtomKey(baseAtom, scopeKey: scope1Token.key)
            let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Token.key)
            let scoped2BaseAtomKey = AtomKey(baseAtom, scopeKey: scope2Token.key)
            let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Token.key)

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                (store.caches[scoped1BaseAtomKey] as? AtomCache<ScopedAtom<String, Int>>)?.value,
                0
            )
            XCTAssertEqual(
                (store.caches[scoped1AtomKey] as? AtomCache<ModifiedAtom<ScopedAtom<String, Int>, ChangesModifier<Int>>>)?.value,
                0
            )
            XCTAssertNil(store.caches[scoped2BaseAtomKey])
            XCTAssertNil(store.caches[scoped2AtomKey])
            XCTAssertNil(store.caches[baseAtomKey])
            XCTAssertNil(store.caches[atomKey])

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.caches[scoped1BaseAtomKey])
            XCTAssertNil(store.caches[scoped1AtomKey])
        }
    }
}
