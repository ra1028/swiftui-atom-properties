import XCTest

@testable import Atoms

final class SnapshotTests: XCTestCase {
    @MainActor
    func testLookup() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atomCache = [
            AtomKey(atom0): AtomCache(atom: atom0, value: 0)
        ]
        let snapshot = Snapshot(
            graph: Graph(),
            caches: atomCache,
            subscriptions: [:]
        )

        XCTAssertEqual(snapshot.lookup(atom0), 0)
        XCTAssertNil(snapshot.lookup(atom1))
    }

    func testEmptyGraphDescription() {
        let snapshot = Snapshot(
            graph: Graph(),
            caches: [:],
            subscriptions: [:]
        )

        XCTAssertEqual(snapshot.graphDescription(), "digraph {}")
    }

    func testGraphDescription() {
        struct Value0: Hashable {}
        struct Value1: Hashable {}
        struct Value2: Hashable {}
        struct Value3: Hashable {}
        struct Value4: Hashable {}

        let scopeToken = ScopeKey.Token()
        let scopeKey = ScopeKey(token: scopeToken)
        let atom0 = TestAtom(value: Value0())
        let atom1 = TestAtom(value: Value1())
        let atom2 = TestAtom(value: Value2())
        let atom3 = TestAtom(value: Value3())
        let atom4 = TestAtom(value: Value4())
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom2)
        let key3 = AtomKey(atom3)
        let key4 = AtomKey(atom4, scopeKey: scopeKey)
        let location = SourceLocation(fileID: "Module/View.swift", line: 10)
        let subscriberToken = SubscriberKey.Token()
        let subscriberKey = SubscriberKey(token: subscriberToken)
        let subscription = Subscription(
            location: location,
            requiresObjectUpdate: false,
            notifyUpdate: {}
        )
        let snapshot = Snapshot(
            graph: Graph(
                dependencies: [
                    key1: [key0],
                    key2: [key1],
                    key3: [key2],
                ],
                children: [
                    key0: [key1],
                    key1: [key2],
                    key2: [key3],
                ]
            ),
            caches: [
                key0: AtomCache(atom: atom0, value: Value0()),
                key1: AtomCache(atom: atom1, value: Value1()),
                key2: AtomCache(atom: atom2, value: Value2()),
                key3: AtomCache(atom: atom3, value: Value3()),
                key4: AtomCache(atom: atom4, value: Value4()),
            ],
            subscriptions: [
                key2: [subscriberKey: subscription],
                key3: [subscriberKey: subscription],
                key4: [subscriberKey: subscription],
            ]
        )

        XCTAssertEqual(
            snapshot.graphDescription(),
            """
            digraph {
              node [shape=box]
              "Module/View.swift" [style=filled]
              "TestAtom<Value0>"
              "TestAtom<Value0>" -> "TestAtom<Value1>"
              "TestAtom<Value1>"
              "TestAtom<Value1>" -> "TestAtom<Value2>"
              "TestAtom<Value2>"
              "TestAtom<Value2>" -> "Module/View.swift" [label="line:10"]
              "TestAtom<Value2>" -> "TestAtom<Value3>"
              "TestAtom<Value3>"
              "TestAtom<Value3>" -> "Module/View.swift" [label="line:10"]
              "TestAtom<Value4>-scoped:\(scopeKey.debugLabel)"
              "TestAtom<Value4>-scoped:\(scopeKey.debugLabel)" -> "Module/View.swift" [label="line:10"]
            }
            """
        )
    }
}
