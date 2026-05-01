import XCTest

@testable import Atoms

final class LatestModifierTests: XCTestCase {
    struct Item {
        var id: Int
        var isValid: Bool
        var isUnique = false
    }

    @MainActor
    func testLatest() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: false))
        let context = AtomTestContext()

        // Initially nil because isValid is false
        XCTAssertNil(context.watch(atom.latest(\.isValid)))

        // Update with valid item
        context[atom] = Item(id: 2, isValid: true)

        // Should return the valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with invalid item
        context[atom] = Item(id: 3, isValid: false)

        // Should still return the last valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with another valid item
        context[atom] = Item(id: 4, isValid: true)

        // Should return the new valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 4)

        // Update with invalid item again
        context[atom] = Item(id: 5, isValid: false)

        // Should still return the last valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 4)
    }

    @MainActor
    func testLatestWithMultipleWatchers() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: false))
        let context = AtomTestContext()

        // Watch both current and latest
        XCTAssertEqual(context.watch(atom).id, 1)
        XCTAssertNil(context.watch(atom.latest(\.isValid)))

        // Update with valid item
        context[atom] = Item(id: 2, isValid: true)

        XCTAssertEqual(context.watch(atom).id, 2)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with invalid item
        context[atom] = Item(id: 3, isValid: false)

        XCTAssertEqual(context.watch(atom).id, 3)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)
    }

    @MainActor
    func testLatestUpdatesDownstream() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: false))
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        // Initial watch
        XCTAssertEqual(updatedCount, 0)
        XCTAssertNil(context.watch(atom.latest(\.isValid)))

        // Update with valid item - should trigger update
        context[atom] = Item(id: 2, isValid: true)
        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with invalid item - should still trigger update
        context[atom] = Item(id: 3, isValid: false)
        XCTAssertEqual(updatedCount, 2)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with another valid item - should trigger update
        context[atom] = Item(id: 4, isValid: true)
        XCTAssertEqual(updatedCount, 3)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 4)
    }

    @MainActor
    func testKey() {
        let modifier1 = LatestModifier<Item>(keyPath: \.isValid)
        let modifier2 = LatestModifier<Item>(keyPath: \.isValid)

        XCTAssertEqual(modifier1.key, modifier2.key)
        XCTAssertEqual(modifier1.key.hashValue, modifier2.key.hashValue)
    }

    @MainActor
    func testLatestWithBoolValue() {
        let atom = TestStateAtom(defaultValue: true)
        let context = AtomTestContext()

        // Initially should return the value if it's true
        XCTAssertEqual(context.watch(atom.latest(\.self)), true)

        // Update to false
        context[atom] = false

        // Should still return the last true value
        XCTAssertEqual(context.watch(atom.latest(\.self)), true)

        // Update to true again
        context[atom] = true

        // Should return the new true value
        XCTAssertEqual(context.watch(atom.latest(\.self)), true)
    }

    @MainActor
    func testLatestIsolatedPerScope() {
        struct ScopedItemAtom: StateAtom, Scoped, Hashable, @unchecked Sendable {
            let key = UniqueKey()
            let scopeID = DefaultScopeID()

            func defaultValue(context: Context) -> Item {
                Item(id: 0, isValid: false)
            }
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
        let atom = ScopedItemAtom()

        // Drive `latest` in scope1 so its StorageAtom retains a valid item.
        XCTAssertNil(scope1.watch(atom.latest(\.isValid), subscriber: subscriber1, subscription: Subscription()))
        scope1.set(Item(id: 10, isValid: true), for: atom)
        XCTAssertEqual(
            scope1.watch(atom.latest(\.isValid), subscriber: subscriber1, subscription: Subscription())?.id,
            10
        )

        // First read of `latest` in scope2. With un-scoped storage this would
        // leak scope1's id=10; with per-scope storage it must be nil.
        XCTAssertNil(scope2.watch(atom.latest(\.isValid), subscriber: subscriber2, subscription: Subscription()))
    }

    @MainActor
    func testLatestIsolatedPerKeyPath() {
        let atom = TestStateAtom(defaultValue: Item(id: 0, isValid: false, isUnique: false))
        let context = AtomTestContext()

        // Drive A through a valid emission so any shared storage now retains id=10.
        XCTAssertNil(context.watch(atom.latest(\.isValid)))
        context[atom] = Item(id: 10, isValid: true, isUnique: false)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 10)

        // First read of B — has never seen a B-valid value. With shared storage
        // it would leak A's id=10; with per-(base, keyPath) storage it must be nil.
        XCTAssertNil(context.watch(atom.latest(\.isUnique)))
    }

    @MainActor
    func testLatestIsolatedPerBaseAtomInstance() {
        struct ItemAtom: StateAtom, Hashable {
            let id: Int

            func defaultValue(context: Context) -> Item {
                Item(id: id, isValid: false)
            }
        }

        let context = AtomTestContext()
        let a = ItemAtom(id: 1)
        let b = ItemAtom(id: 2)

        // Drive `a.latest` so that — under the shared-storage bug —
        // the StorageAtom now retains `Item(id: 10, isValid: true)`.
        XCTAssertNil(context.watch(a.latest(\.isValid)))
        context[a] = Item(id: 10, isValid: true)
        XCTAssertEqual(context.watch(a.latest(\.isValid))?.id, 10)

        // First read of `b.latest`. With shared storage this would leak
        // `a`'s last valid item; with per-base storage it must be nil.
        XCTAssertNil(context.watch(b.latest(\.isValid)))
    }

    @MainActor
    func testLatestWithInitialValidValue() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: true))
        let context = AtomTestContext()

        // Should immediately return the initial valid value
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 1)

        // Update with invalid item
        context[atom] = Item(id: 2, isValid: false)

        // Should still return the initial valid value
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 1)
    }
}
