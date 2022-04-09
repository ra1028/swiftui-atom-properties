import XCTest

@testable import Atoms

@MainActor
final class StoreTests: XCTestCase {
    final class TestObserver: AtomObserver {
        var assignedAtomKeys = [AnyHashable]()
        var unassignedAtomKeys = [AnyHashable]()
        var changedKeys = [AnyHashable]()

        func atomAssigned<Node: Atom>(atom: Node) {
            assignedAtomKeys.append(atom.key)
        }

        func atomUnassigned<Node: Atom>(atom: Node) {
            unassignedAtomKeys.append(atom.key)
        }

        func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
            changedKeys.append(snapshot.atom.key)
        }
    }

    func testRead() {
        let container = StoreContainer()
        let observer = TestObserver()
        let atom = TestValueAtom(value: 0)
        let store = Store(container: container, observers: [observer])

        XCTAssertEqual(store.read(atom), 0)
        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.unassignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.changedKeys, [atom.key])
    }

    func testReadOverride() {
        let container = StoreContainer()
        var overrides = AtomOverrides()
        let atom = TestValueAtom(value: 0)

        overrides.insert(atom) { _ in 100 }

        let store = Store(container: container, overrides: overrides)

        XCTAssertEqual(store.read(atom), 100)
    }

    func testSet() {
        let container = StoreContainer()
        let observer = TestObserver()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestStateAtom(defaultValue: 0)
        let store = Store(container: container, observers: [observer])

        store.set(1, for: atom)

        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.changedKeys.isEmpty)

        // Emits change event of value initiation.
        XCTAssertEqual(store.read(atom), 0)

        // Start watching, emits change event of value initiation.
        _ = store.watch(atom, relationship: relationship) {}

        // Emits update.
        store.set(1, for: atom)

        XCTAssertEqual(observer.assignedAtomKeys, [atom.key, atom.key])
        XCTAssertEqual(observer.unassignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.changedKeys, [atom.key, atom.key, atom.key])
        XCTAssertEqual(store.read(atom), 1)
    }

    func testSetOverride() {
        let container = StoreContainer()
        var overrides = AtomOverrides()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestStateAtom(defaultValue: 0)

        overrides.insert(atom) { _ in 100 }

        let store = Store(container: container, overrides: overrides)

        // Start watching.
        _ = store.watch(atom, relationship: relationship) {}

        XCTAssertEqual(store.read(atom), 100)

        store.set(200, for: atom)

        XCTAssertEqual(store.read(atom), 200)
    }

    func testRefresh() async {
        let container = StoreContainer()
        let observer = TestObserver()
        let atom = TestTaskAtom(value: 0)
        let store = Store(container: container, observers: [observer])
        let value = await store.refresh(atom).value

        XCTAssertEqual(value, 0)
        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.unassignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.changedKeys, [atom.key])
    }

    func testRefreshOverride() async {
        let container = StoreContainer()
        var overrides = AtomOverrides()
        let atom = TestTaskAtom(value: 0)

        overrides.insert(atom) { _ in Task { 100 } }

        let store = Store(container: container, overrides: overrides)
        let value = await store.refresh(atom).value

        XCTAssertEqual(value, 100)
    }

    func testReset() {
        let container = StoreContainer()
        let observer = TestObserver()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        let store = Store(container: container, observers: [observer])

        // NOP.
        store.reset(atom)

        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.changedKeys.isEmpty)

        // Start watching, emits change event of value initiation.
        _ = store.watch(atom, relationship: relationship) {}

        // Emits update.
        store.reset(atom)

        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [atom.key])
    }

    func testWatch() {
        let container = StoreContainer()
        let observer = TestObserver()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        let store = Store(container: container, observers: [observer])
        var updateCount = 0

        // Start watching, emits change event of value initiation.
        let value = store.watch(atom, relationship: relationship) {
            updateCount += 1
        }

        XCTAssertEqual(value, 0)
        XCTAssertEqual(updateCount, 0)
        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [atom.key])

        // Emits change event of value initiation.
        store.notifyUpdate(atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [atom.key, atom.key])
    }

    func testWatchOverride() {
        let container = StoreContainer()
        var overrides = AtomOverrides()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        var updateCount = 0

        overrides.insert(atom) { _ in 100 }

        let store = Store(container: container, overrides: overrides)
        let value = store.watch(atom, relationship: relationship) {
            updateCount += 1
        }

        XCTAssertEqual(value, 100)
        XCTAssertEqual(updateCount, 0)

        store.notifyUpdate(atom)

        XCTAssertEqual(updateCount, 1)
    }

    func testWatchBelongTo() {
        let container = StoreContainer()
        let observer = TestObserver()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        let caller = TestValueAtom(value: 1)
        let store = Store(container: container, observers: [observer])
        var callerUpdateCount = 0
        var updateCount = 0

        // Emits change event of value initiation for caller.
        _ = store.watch(caller, relationship: relationship) {
            callerUpdateCount += 1
        }

        // Emits change event of value initiation for atom.
        _ = store.watch(atom, relationship: relationship) {
            updateCount += 1
        }

        let value = store.watch(atom, belongTo: caller)

        XCTAssertEqual(value, 0)
        XCTAssertEqual(updateCount, 0)
        XCTAssertEqual(callerUpdateCount, 0)
        XCTAssertEqual(observer.assignedAtomKeys, [caller.key, atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [caller.key, atom.key])

        store.notifyUpdate(atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(callerUpdateCount, 1)
        XCTAssertEqual(observer.assignedAtomKeys, [caller.key, atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [caller.key, atom.key, caller.key, caller.key, atom.key])
    }

    func testWatchBelongToOverride() {
        let container = StoreContainer()
        var overrides = AtomOverrides()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        let caller = TestValueAtom(value: 1)
        var callerUpdateCount = 0
        var updateCount = 0

        overrides.insert(atom) { _ in 100 }

        let store = Store(container: container, overrides: overrides)

        _ = store.watch(caller, relationship: relationship) {
            callerUpdateCount += 1
        }
        _ = store.watch(atom, relationship: relationship) {
            updateCount += 1
        }

        let value = store.watch(atom, belongTo: caller)

        XCTAssertEqual(value, 100)
        XCTAssertEqual(updateCount, 0)
        XCTAssertEqual(callerUpdateCount, 0)

        store.notifyUpdate(atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(callerUpdateCount, 1)
    }

    func testNotifyUpdate() {
        let container = StoreContainer()
        let observer = TestObserver()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        let store = Store(container: container, observers: [observer])

        store.notifyUpdate(atom)

        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.changedKeys.isEmpty)

        // Start watching, emits change event of value initiation.
        _ = store.watch(atom, relationship: relationship) {}

        // Emits update.
        store.notifyUpdate(atom)

        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [atom.key, atom.key])
    }

    func testAddTermination() {
        let container = StoreContainer()
        var relationshipContainer: RelationshipContainer? = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer!)
        let atom = TestValueAtom(value: 0)
        let store = Store(container: container)
        var terminationCount = 0

        store.addTermination(atom) {
            terminationCount += 1
        }

        // Run termination immediately.
        XCTAssertEqual(terminationCount, 1)

        // Start watching.
        _ = store.watch(atom, relationship: relationship) {}

        store.addTermination(atom) {
            terminationCount += 1
        }

        // Unwatch.
        relationshipContainer = nil

        XCTAssertEqual(terminationCount, 2)
    }

    func testRestore() {
        let container = StoreContainer()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let atom = TestValueAtom(value: 0)
        let store = Store(container: container)
        var updateCount = 0

        // Start watching.
        let value = store.watch(
            atom,
            relationship: relationship,
            notifyUpdate: { updateCount += 1 }
        )

        XCTAssertEqual(value, 0)
        XCTAssertEqual(updateCount, 0)

        let snapshot = Snapshot(atom: atom, value: 100, store: store)
        store.restore(snapshot: snapshot)
        let newValue = store.read(atom)

        XCTAssertEqual(newValue, 100)
        XCTAssertEqual(updateCount, 1)
    }

    func testKeepAlive() {
        struct TestAtom: ValueAtom, Hashable, KeepAlive {
            func value(context: Context) -> Int {
                0
            }
        }

        var container: StoreContainer? = StoreContainer()
        let observer = TestObserver()
        let atom = TestAtom()
        let store = Store(container: container!, observers: [observer])

        XCTAssertEqual(store.read(atom), 0)
        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedKeys, [atom.key])

        container = nil

        XCTAssertEqual(observer.assignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.unassignedAtomKeys, [atom.key])
        XCTAssertEqual(observer.changedKeys, [atom.key])
    }

    func testSnapshots() {
        final class TestObserver: AtomObserver {
            var snapshots = [Snapshot<TestStateAtom<Int>>]()

            func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
                if let snapshot = snapshot as? Snapshot<TestStateAtom<Int>> {
                    snapshots.append(snapshot)
                }
            }
        }

        let observer = TestObserver()
        let context = AtomTestContext()
        let atom = TestStateAtom(defaultValue: 0)

        context.observe(observer)

        XCTAssertEqual(context.watch(atom), 0)
        XCTAssertEqual(observer.snapshots.map(\.value), [0])

        context[atom] = 1

        XCTAssertEqual(observer.snapshots.map(\.value), [0, 1])

        context.unwatch(atom)

        XCTAssertEqual(observer.snapshots.map(\.value), [0, 1])
    }
}
