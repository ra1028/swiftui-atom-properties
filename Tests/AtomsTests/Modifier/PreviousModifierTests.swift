import Testing

@testable import Atoms

struct PreviousModifierTests {
    @MainActor
    @Test
    func testPrevious() {
        let atom = TestStateAtom(defaultValue: "initial")
        let context = AtomTestContext()

        #expect(context.watch(atom.previous) == nil)

        // Update the atom value
        context[atom] = "second"

        // Now previous should return the initial value
        #expect(context.watch(atom.previous) == "initial")

        // Update again
        context[atom] = "third"

        // Previous should now return "second"
        #expect(context.watch(atom.previous) == "second")

        // Another update
        context[atom] = "fourth"

        // Previous should now return "third"
        #expect(context.watch(atom.previous) == "third")
    }

    @MainActor
    @Test
    func testPreviousWithMultipleWatchers() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()

        // Watch both current and previous
        #expect(context.watch(atom) == 100)
        #expect(context.watch(atom.previous) == nil)

        // Update the value
        context[atom] = 200

        // Check both watchers
        #expect(context.watch(atom) == 200)
        #expect(context.watch(atom.previous) == 100)

        // Update again
        context[atom] = 300

        #expect(context.watch(atom) == 300)
        #expect(context.watch(atom.previous) == 200)
    }

    @MainActor
    @Test
    func testPreviousUpdatesDownstream() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        // Initial watch
        #expect(updatedCount == 0)
        #expect(context.watch(atom.previous) == nil)

        // First update
        context[atom] = 1
        #expect(updatedCount == 1)
        #expect(context.watch(atom.previous) == 0)

        // Second update
        context[atom] = 2
        #expect(updatedCount == 2)
        #expect(context.watch(atom.previous) == 1)
    }

    @MainActor
    @Test
    func testKey() {
        let modifier = PreviousModifier<Int>()

        #expect(modifier.key == modifier.key)
        #expect(modifier.key.hashValue == modifier.key.hashValue)
    }

    @MainActor
    @Test
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
        #expect(scope1.watch(atom.previous, subscriber: subscriber1, subscription: Subscription()) == nil)
        scope1.set(1, for: atom)
        #expect(scope1.watch(atom.previous, subscriber: subscriber1, subscription: Subscription()) == 0)

        // First read of `previous` in scope2. With un-scoped storage this would
        // leak scope1's value; with per-scope storage it must be nil.
        #expect(scope2.watch(atom.previous, subscriber: subscriber2, subscription: Subscription()) == nil)
    }

    @MainActor
    @Test
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
        #expect(context.watch(a.previous) == nil)
        context[a] = "a-new"
        #expect(context.watch(a.previous) == "initial-1")

        // First read of `b.previous`. With shared storage this would leak
        // `"a-new"`; with per-base storage it must be nil.
        #expect(context.watch(b.previous) == nil)
    }
}
