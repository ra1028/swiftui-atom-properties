import XCTest

@testable import Atoms

final class PreviousModifierTests: XCTestCase {
    @MainActor
    func testPrevious() {
        let atom = TestStateAtom(defaultValue: "initial")
        let context = AtomTestContext()

        XCTAssertNil(context.watch(atom.previous))

        // Update the atom value
        context[atom] = "second"

        // Now previous should return the initial value
        XCTAssertEqual(context.watch(atom.previous), "initial")

        // Update again
        context[atom] = "third"

        // Previous should now return "second"
        XCTAssertEqual(context.watch(atom.previous), "second")

        // Another update
        context[atom] = "fourth"

        // Previous should now return "third"
        XCTAssertEqual(context.watch(atom.previous), "third")
    }

    @MainActor
    func testPreviousWithMultipleWatchers() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()

        // Watch both current and previous
        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertNil(context.watch(atom.previous))

        // Update the value
        context[atom] = 200

        // Check both watchers
        XCTAssertEqual(context.watch(atom), 200)
        XCTAssertEqual(context.watch(atom.previous), 100)

        // Update again
        context[atom] = 300

        XCTAssertEqual(context.watch(atom), 300)
        XCTAssertEqual(context.watch(atom.previous), 200)
    }

    @MainActor
    func testPreviousUpdatesDownstream() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        // Initial watch
        XCTAssertEqual(updatedCount, 0)
        XCTAssertNil(context.watch(atom.previous))

        // First update
        context[atom] = 1
        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.previous), 0)

        // Second update
        context[atom] = 2
        XCTAssertEqual(updatedCount, 2)
        XCTAssertEqual(context.watch(atom.previous), 1)
    }

    @MainActor
    func testKey() {
        let modifier = PreviousModifier<Int>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }

    @MainActor
    func testPreviousIsolatedPerScope() {
        struct ScopedIntAtom: StateAtom, Scoped, Hashable, @unchecked Sendable {
            let key = UniqueKey()
            let scopeID = DefaultScopeID()

            func defaultValue(context: Context) -> Int { 0 }
        }

        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scope1 = context.scoped(scopeID: ScopeID(DefaultScopeID()), scopeKey: scope1Token.key)
        let scope2 = context.scoped(scopeID: ScopeID(DefaultScopeID()), scopeKey: scope2Token.key)
        let subscriber1 = Subscriber(SubscriberState())
        let subscriber2 = Subscriber(SubscriberState())
        let atom = ScopedIntAtom()

        // Drive `previous` in scope1 so its StorageAtom holds the latest value.
        XCTAssertNil(scope1.watch(atom.previous, subscriber: subscriber1, subscription: Subscription()))
        scope1.set(1, for: atom)
        XCTAssertEqual(scope1.watch(atom.previous, subscriber: subscriber1, subscription: Subscription()), 0)

        // First read of `previous` in scope2. With un-scoped storage this would
        // leak scope1's value; with per-scope storage it must be nil.
        XCTAssertNil(scope2.watch(atom.previous, subscriber: subscriber2, subscription: Subscription()))
    }

    @MainActor
    func testPreviousIsolatedPerBaseAtomInstance() {
        struct ItemAtom: StateAtom, Hashable {
            let id: Int

            func defaultValue(context: Context) -> String {
                "initial-\(id)"
            }
        }

        let context = AtomTestContext()
        let a = ItemAtom(id: 1)
        let b = ItemAtom(id: 2)

        // Drive `a.previous` so that — under the shared-storage bug —
        // the StorageAtom's `previous` now holds `"a-new"`.
        XCTAssertNil(context.watch(a.previous))
        context[a] = "a-new"
        XCTAssertEqual(context.watch(a.previous), "initial-1")

        // First read of `b.previous`. With shared storage this would leak
        // `"a-new"`; with per-base storage it must be nil.
        XCTAssertNil(context.watch(b.previous))
    }
}
