import XCTest

@testable import Atoms

final class ResettableTests: XCTestCase {
    @MainActor
    func testCustomReset() {
        struct Counter: Equatable {
            var value = 0
            var update = 0
            var reset = 0
        }

        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        var counter = Counter()
        let atom = TestCustomResettableAtom(
            defaultValue: { _ in
                counter.value += 1
                return 0
            },
            reset: { _ in
                counter.reset += 1
            }
        )
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer {
            snapshots.append($0)
        }
        let context = StoreContext(store: store, observers: [observer])
        let value0 = context.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {
            counter.update += 1
        }

        snapshots.removeAll()
        context.set(1, for: atom)

        XCTAssertEqual(value0, 0)
        XCTAssertEqual(counter, Counter(value: 1, update: 1, reset: 0))
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 1]]
        )

        snapshots.removeAll()
        context.reset(atom)

        XCTAssertEqual(counter, Counter(value: 1, update: 1, reset: 1))
        XCTAssertTrue(snapshots.isEmpty)

        context.unwatch(atom, subscriber: subscriber)
        counter = Counter()

        let scopeKey = ScopeKey(token: ScopeKey.Token())
        let overrideAtomKey = AtomKey(atom, scopeKey: scopeKey)
        let scopedContext = context.scoped(
            scopeKey: scopeKey,
            scopeID: ScopeID(DefaultScopeID()),
            observers: [],
            overrides: [
                OverrideKey(atom): AtomOverride<TestCustomResettableAtom<Int>>(isScoped: true) { _ in 2 }
            ]
        )
        let value1 = scopedContext.watch(atom, subscriber: subscriber, requiresObjectUpdate: false) {
            counter.update += 1
        }

        XCTAssertEqual(value1, 2)
        XCTAssertEqual(counter, Counter(value: 0, update: 0, reset: 0))

        scopedContext.reset(atom)

        XCTAssertEqual(scopedContext.read(atom), 2)
        XCTAssertEqual(counter, Counter(value: 0, update: 1, reset: 0))
        XCTAssertNotNil(store.state.states[overrideAtomKey])
        XCTAssertEqual((store.state.caches[overrideAtomKey] as? AtomCache<TestCustomResettableAtom<Int>>)?.value, 2)
    }
}
