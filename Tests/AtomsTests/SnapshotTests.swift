import XCTest

@testable import Atoms

@MainActor
final class SnapshotTests: XCTestCase {
    func testRestore() {
        var isRestoreCalled = false
        let snapshot = Snapshot(
            graph: Graph(),
            caches: [:],
            subscriptions: [:],
            overrides: [:]
        ) {
            isRestoreCalled = true
        }

        snapshot.restore()

        XCTAssertTrue(isRestoreCalled)
    }

    func testLookup() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let atom3 = TestAtom(value: 3)
        let token = ScopeKey.Token()
        let scopeKey = ScopeKey(token: token)
        let atomCache = [
            AtomKey(atom0): AtomCache(atom: atom0, value: 0),
            AtomKey(atom2, overrideScopeKey: scopeKey): AtomCache(atom: atom2, value: 20),
        ]
        let overrides = [
            OverrideKey(atom2): AtomScopedOverride<TestAtom<Int>>(scopeKey: scopeKey) { _ in 0 }
        ]
        let snapshot = Snapshot(
            graph: Graph(),
            caches: atomCache,
            subscriptions: [:],
            overrides: overrides
        ) {}

        XCTAssertEqual(snapshot.lookup(atom0), 0)
        XCTAssertNil(snapshot.lookup(atom1))
        XCTAssertEqual(snapshot.lookup(atom2), 20)
        XCTAssertNil(snapshot.lookup(atom3))
    }

    func testEmptyGraphDescription() {
        let snapshot = Snapshot(
            graph: Graph(),
            caches: [:],
            subscriptions: [:],
            overrides: [:]
        ) {}

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
        let scopeID = String(scopeKey.hashValue, radix: 36, uppercase: false)
        let atom0 = TestAtom(value: Value0())
        let atom1 = TestAtom(value: Value1())
        let atom2 = TestAtom(value: Value2())
        let atom3 = TestAtom(value: Value3())
        let atom4 = TestAtom(value: Value4())
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom2)
        let key3 = AtomKey(atom3)
        let key4 = AtomKey(atom4, overrideScopeKey: scopeKey)
        let location = SourceLocation(fileID: "Module/View.swift", line: 10)
        let subscriptionToken = SubscriptionKey.Token()
        let subscriber = SubscriptionKey(token: subscriptionToken)
        let subscription = Subscription(location: location, notifyUpdate: {}, unsubscribe: {})
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
                key2: [subscriber: subscription],
                key3: [subscriber: subscription],
                key4: [subscriber: subscription],
            ],
            overrides: [:]
        ) {}

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
              "TestAtom<Value4>-override:\(scopeID)"
              "TestAtom<Value4>-override:\(scopeID)" -> "Module/View.swift" [label="line:10"]
            }
            """
        )
    }
}
