import XCTest

@testable import Atoms

@available(*, deprecated)
final class RefreshableTests: XCTestCase {
    @MainActor
    func testCustomRefresh() async {
        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom = TestCustomRefreshableAtom { _ in
            0
        } refresh: { _ in
            1
        }
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        do {
            // Should call custom refresh behavior

            let value0 = await context.refresh(atom)
            XCTAssertEqual(value0, 1)
            XCTAssertNil(store.caches[key])
            XCTAssertNil(store.states[key])
            XCTAssertTrue(snapshots.isEmpty)

            var updateCount = 0
            let value1 = context.watch(
                atom,
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )

            XCTAssertEqual(value1, 0)

            snapshots.removeAll()
            let value2 = await context.refresh(atom)
            XCTAssertEqual(value2, 1)
            XCTAssertNotNil(store.states[key])
            XCTAssertEqual((store.caches[key] as? AtomCache<TestCustomRefreshableAtom<Int>>)?.value, 1)
            XCTAssertEqual(updateCount, 1)
            XCTAssertEqual(
                snapshots.map { $0.caches.mapValues { $0.value as? Int } },
                [[key: 1]]
            )

            context.unwatch(atom, subscriber: subscriber)
        }

        do {
            // Custom refresh behavior should not be overridden

            let scopeKey = ScopeKey.Token().key
            let overrideAtomKey = AtomKey(atom, scopeKey: scopeKey)
            let scopedContext = context.scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeKey,
                observers: [],
                overrideContainer: OverrideContainer()
                    .addingOverride(for: atom) { _ in
                        2
                    }
            )

            let value0 = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
            XCTAssertEqual(value0, 2)

            let value1 = await scopedContext.refresh(atom)
            XCTAssertEqual(value1, 1)
            XCTAssertNotNil(store.states[overrideAtomKey])
            XCTAssertEqual(
                (store.caches[overrideAtomKey] as? AtomCache<TestCustomRefreshableAtom<Int>>)?.value,
                1
            )
        }

        do {
            // Should not make new state and cache

            let value = await context.refresh(atom)

            XCTAssertEqual(value, 1)
            XCTAssertNil(store.states[key])
            XCTAssertNil(store.caches[key])
        }
    }

    @MainActor
    func testCustomRefreshNotCached() async {
        let store = AtomStore()
        let dependencyAtom = TestValueAtom(value: 1)
        let atom = TestCustomRefreshableAtom { _ in
            0
        } refresh: { context in
            context.read(dependencyAtom)
        }
        let rootScopeToken = ScopeKey.Token()
        let scopeToken = ScopeKey.Token()
        let scopedContext =
            StoreContext
            .root(store: store, scopeKey: rootScopeToken.key)
            .scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeToken.key,
                observers: [],
                overrideContainer: OverrideContainer()
                    .addingOverride(for: dependencyAtom) { _ in
                        2
                    }
            )

        let value = await scopedContext.refresh(atom)
        XCTAssertEqual(value, 2)
    }

    @MainActor
    func testTransitiveRefresh() async {
        let parentAtom = TestTaskAtom { 0 }
        let atom = TestCustomRefreshableAtom { context in
            context.watch(parentAtom.phase)
        } refresh: { context in
            await context.refresh(parentAtom.phase)
        }
        let context = AtomTestContext()

        var updateCount = 0
        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertTrue(context.watch(atom).isSuspending)

        await context.waitForUpdate()
        XCTAssertEqual(context.watch(atom).value, 0)
        XCTAssertEqual(updateCount, 1)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 0)
        XCTAssertEqual(context.watch(atom).value, 0)
        XCTAssertEqual(updateCount, 2)
    }
}
