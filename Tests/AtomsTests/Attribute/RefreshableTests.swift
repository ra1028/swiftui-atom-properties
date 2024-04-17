import Combine
import XCTest

@testable import Atoms

final class RefreshableTests: XCTestCase {
    @MainActor
    func testCustomRefresh() async {
        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom = TestCustomRefreshableAtom {
            Just(0)
        } refresh: {
            .success(1)
        }
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        let phase0 = await context.refresh(atom)
        XCTAssertEqual(phase0.value, 1)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
        XCTAssertTrue(snapshots.isEmpty)

        var updateCount = 0
        let phase1 = context.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {
            updateCount += 1
        }

        XCTAssertTrue(phase1.isSuspending)

        snapshots.removeAll()

        let phase2 = await context.refresh(atom)
        XCTAssertEqual(phase2.value, 1)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestCustomRefreshableAtom<Just<Int>>>)?.value, .success(1))
        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? AsyncPhase<Int, Never> } },
            [[key: .success(1)]]
        )

        let scopeKey = ScopeKey(token: ScopeKey.Token())
        let overrideAtomKey = AtomKey(atom, scopeKey: scopeKey)
        let scopedContext = context.scoped(
            scopeKey: scopeKey,
            scopeID: ScopeID(DefaultScopeID()),
            observers: [],
            overrides: [
                OverrideKey(atom): AtomOverride<TestCustomRefreshableAtom<Just<Int>>> { _ in .success(2) }
            ]
        )

        let phase3 = scopedContext.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {}
        XCTAssertEqual(phase3.value, 2)

        let phase4 = await scopedContext.refresh(atom)
        XCTAssertEqual(phase4.value, 2)
        XCTAssertNotNil(store.state.states[overrideAtomKey])
        XCTAssertEqual(
            (store.state.caches[overrideAtomKey] as? AtomCache<TestCustomRefreshableAtom<Just<Int>>>)?.value,
            .success(2)
        )
    }
}
