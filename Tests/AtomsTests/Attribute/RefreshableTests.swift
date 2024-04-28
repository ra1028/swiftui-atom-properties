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
        let context = StoreContext(store: store, observers: [observer])

        do {
            // Should call custom refresh behavior

            let phase0 = await context.refresh(atom)
            XCTAssertEqual(phase0.value, 1)
            XCTAssertNil(store.state.caches[key])
            XCTAssertNil(store.state.states[key])
            XCTAssertTrue(snapshots.isEmpty)

            var updateCount = 0
            let phase1 = context.watch(
                atom,
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )

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

            context.unwatch(atom, subscriber: subscriber)
        }

        do {
            // Custom refresh behavior should not be overridden

            let scopeKey = ScopeKey(token: ScopeKey.Token())
            let overrideAtomKey = AtomKey(atom, scopeKey: scopeKey)
            let scopedContext = context.scoped(
                scopeKey: scopeKey,
                scopeID: ScopeID(DefaultScopeID()),
                observers: [],
                overrides: [
                    OverrideKey(atom): Override<TestCustomRefreshableAtom<Just<Int>>>(isScoped: true) { _ in .success(2) }
                ]
            )

            let phase0 = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertEqual(phase0.value, 2)

            let phase1 = await scopedContext.refresh(atom)
            XCTAssertEqual(phase1.value, 1)
            XCTAssertNotNil(store.state.states[overrideAtomKey])
            XCTAssertEqual(
                (store.state.caches[overrideAtomKey] as? AtomCache<TestCustomRefreshableAtom<Just<Int>>>)?.value,
                .success(1)
            )
        }

        do {
            // Should not make new state and cache

            let phase = await context.refresh(atom)

            XCTAssertEqual(phase.value, 1)
            XCTAssertNil(store.state.states[key])
            XCTAssertNil(store.state.caches[key])
        }
    }
}
