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
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key
        )

        context.register(
            scopeKey: rootScopeToken.key,
            overrides: [:],
            observers: [observer]
        )

        XCTContext.runActivity(named: "Should call custom reset behavior") { _ in
            let value0 = context.watch(
                atom,
                subscriber: subscriber,
                subscription: Subscription {
                    counter.update += 1
                }
            )

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
        }

        XCTContext.runActivity(named: "Custom reset behavior should not be overridden") { _ in
            let scopeKey = ScopeKey.Token().key
            let overrideAtomKey = AtomKey(atom, scopeKey: scopeKey)
            let scopedContext = context.scoped(
                scopeKey: scopeKey,
                scopeID: ScopeID(DefaultScopeID())
            )

            scopedContext.register(
                scopeKey: scopeKey,
                overrides: [
                    OverrideKey(atom): Override<TestCustomResettableAtom<Int>> { _ in
                        2
                    }
                ],
                observers: []
            )

            let value = scopedContext.watch(
                atom,
                subscriber: subscriber,
                subscription: Subscription {
                    counter.update += 1
                }
            )

            XCTAssertEqual(value, 2)
            XCTAssertEqual(counter, Counter(value: 0, update: 0, reset: 0))

            scopedContext.reset(atom)

            XCTAssertEqual(scopedContext.read(atom), 2)
            XCTAssertEqual(counter, Counter(value: 0, update: 0, reset: 1))
            XCTAssertNotNil(store.state.states[overrideAtomKey])
            XCTAssertEqual((store.state.caches[overrideAtomKey] as? AtomCache<TestCustomResettableAtom<Int>>)?.value, 2)
        }

        XCTContext.runActivity(named: "Should not make new state and cache") { _ in
            context.reset(atom)

            XCTAssertNil(store.state.states[key])
            XCTAssertNil(store.state.caches[key])
        }
    }

    @MainActor
    func testTransitiveReset() {
        let parentAtom = TestValueAtom(value: 0)
        let atom = TestCustomResettableAtom { context in
            context.watch(parentAtom)
        } reset: { context in
            context.reset(parentAtom)
        }
        let context = AtomTestContext()

        var updateCount = 0
        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertEqual(context.watch(atom), 0)
        XCTAssertEqual(updateCount, 0)

        context.reset(atom)

        XCTAssertEqual(context.watch(atom), 0)
        XCTAssertEqual(updateCount, 1)
    }
}
