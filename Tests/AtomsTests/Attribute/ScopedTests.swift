import XCTest

@testable import Atoms

final class ScopedTests: XCTestCase {
    @MainActor
    func testScopedAtoms() {
        struct ScopedAtom<ID: Hashable & Sendable, T: Hashable & Sendable>: ValueAtom, Scoped, Equatable {
            let key = UniqueKey()
            let scopeID: ID
            let value: T

            func value(context: Context) -> T {
                value
            }
        }

        let scope1Token = ScopeKey.Token()
        let scope1Key = ScopeKey(token: scope1Token)
        let scope2Token = ScopeKey.Token()
        let scope2Key = ScopeKey(token: scope2Token)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        XCTContext.runActivity(named: "Should be scoped") { _ in
            let store = AtomStore()
            let context = StoreContext(store: store)
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
            let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Key)
            let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Key)

            XCTAssertEqual(
                scoped1Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                store.state.caches[scoped1AtomKey] as? AtomCache<ScopedAtom<DefaultScopeID, Int>>,
                AtomCache(atom: atom, value: 0)
            )
            XCTAssertNil(store.state.caches[scoped2AtomKey])

            scoped1Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[scoped1AtomKey])

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                store.state.caches[scoped2AtomKey] as? AtomCache<ScopedAtom<DefaultScopeID, Int>>,
                AtomCache(atom: atom, value: 0)
            )

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[scoped2AtomKey])
        }

        XCTContext.runActivity(named: "Should be scoped in particular scope") { _ in
            let store = AtomStore()
            let context = StoreContext(store: store)
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
            let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Key)
            let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Key)

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                store.state.caches[scoped1AtomKey] as? AtomCache<ScopedAtom<String, Int>>,
                AtomCache(atom: atom, value: 0)
            )
            XCTAssertNil(store.state.caches[scoped2AtomKey])

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[scoped1AtomKey])
        }

        XCTContext.runActivity(named: "Modified atoms should also be scoped") { _ in
            let store = AtomStore()
            let context = StoreContext(store: store)
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
            let baseAtom = ScopedAtom(scopeID: scopeID, value: 0)
            let atom = baseAtom.changes
            let baseAtomKey = AtomKey(baseAtom, scopeKey: nil)
            let atomKey = AtomKey(atom, scopeKey: nil)
            let scoped1BaseAtomKey = AtomKey(baseAtom, scopeKey: scope1Key)
            let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Key)
            let scoped2BaseAtomKey = AtomKey(baseAtom, scopeKey: scope2Key)
            let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Key)

            XCTAssertEqual(
                scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()),
                0
            )
            XCTAssertEqual(
                (store.state.caches[scoped1BaseAtomKey] as? AtomCache<ScopedAtom<String, Int>>)?.value,
                0
            )
            XCTAssertEqual(
                (store.state.caches[scoped1AtomKey] as? AtomCache<ModifiedAtom<ScopedAtom<String, Int>, ChangesModifier<Int>>>)?.value,
                0
            )
            XCTAssertNil(store.state.caches[scoped2BaseAtomKey])
            XCTAssertNil(store.state.caches[scoped2AtomKey])
            XCTAssertNil(store.state.caches[baseAtomKey])
            XCTAssertNil(store.state.caches[atomKey])

            scoped2Context.unwatch(atom, subscriber: subscriber)
            XCTAssertNil(store.state.caches[scoped1BaseAtomKey])
            XCTAssertNil(store.state.caches[scoped1AtomKey])
        }
    }
}
