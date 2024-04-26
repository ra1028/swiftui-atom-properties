import XCTest

@testable import Atoms

final class TopologicalSortTests: XCTestCase {
    @MainActor
    func testSort() {
        let store = AtomStore()
        let key0 = AtomKey(TestAtom(value: 0))
        let key1 = AtomKey(TestAtom(value: 1))
        let key2 = AtomKey(TestAtom(value: 2))
        let key3 = AtomKey(TestAtom(value: 3))
        let subscriberKey = SubscriberKey(token: SubscriberKey.Token())

        store.graph = Graph(
            dependencies: [
                key1: [key0],
                key2: [key0, key1],
                key3: [key2],
            ],
            children: [
                key0: [key1, key2],
                key1: [key2],
                key2: [key3],
            ]
        )
        store.state.subscriptions = [
            key2: [subscriberKey: Subscription()],
            key3: [subscriberKey: Subscription()],
        ]

        let sorted = topologicalSort(key: key0, store: store)
        let expectedEdges = [
            [
                Edge(
                    from: key0,
                    to: .atom(key: key1)
                ),
                Edge(
                    from: key1,
                    to: .atom(key: key2)
                ),
                Edge(
                    from: key2,
                    to: .atom(key: key3)
                ),
                Edge(
                    from: key3,
                    to: .subscriber(key: subscriberKey)
                ),
            ],
            [
                Edge(
                    from: key0,
                    to: .atom(key: key1)
                ),
                Edge(
                    from: key0,
                    to: .atom(key: key2)
                ),
                Edge(
                    from: key2,
                    to: .atom(key: key3)
                ),
                Edge(
                    from: key3,
                    to: .subscriber(key: subscriberKey)
                ),
            ],
        ]
        let expectedRedundants: [[Vertex: ContiguousArray<AtomKey>]] = [
            [
                .atom(key: key2): [key0],
                .atom(key: key3): [key2],
                .subscriber(key: subscriberKey): [key2, key3, key2],
            ],
            [
                .atom(key: key2): [key1],
                .atom(key: key3): [key2],
                .subscriber(key: subscriberKey): [key2, key3, key2],
            ],
        ]

        XCTAssertTrue(expectedEdges.contains(Array(sorted.edges)))
        XCTAssertTrue(expectedRedundants.contains(sorted.redundants))
    }
}
