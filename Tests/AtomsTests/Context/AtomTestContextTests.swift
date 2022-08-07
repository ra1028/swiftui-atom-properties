import XCTest

@testable import Atoms

@MainActor
final class AtomTestContextTests: XCTestCase {
    func testOnUpdate() {
        let atom = TestValueAtom(value: 100)
        let context = AtomTestContext()
        var isCalled = false

        context.onUpdate = {
            isCalled = false
        }

        // Override.
        context.onUpdate = {
            isCalled = true
        }

        context.reset(atom)

        XCTAssertFalse(isCalled)

        context.watch(atom)

        XCTAssertFalse(isCalled)

        context.reset(atom)

        XCTAssertTrue(isCalled)
    }

    func testWaitUntilNextUpdate() async {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        Task {
            context[atom] = 1
        }

        let didUpdate0 = await context.waitUntilNextUpdate()

        XCTAssertTrue(didUpdate0)

        let didUpdate1 = await context.waitUntilNextUpdate(timeout: 1)

        XCTAssertFalse(didUpdate1)
    }

    func testOverride() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestValueAtom(value: 200)
        let context = AtomTestContext()

        XCTAssertEqual(context.read(atom0), 100)
        XCTAssertEqual(context.read(atom1), 200)

        context.override(atom0) { _ in 300 }

        XCTAssertEqual(context.read(atom0), 300)
        XCTAssertEqual(context.read(atom1), 200)
    }

    func testOverrideWithType() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestValueAtom(value: 200)
        let context = AtomTestContext()

        XCTAssertEqual(context.read(atom0), 100)
        XCTAssertEqual(context.read(atom1), 200)

        context.override(TestValueAtom.self) { _ in 300 }

        XCTAssertEqual(context.read(atom0), 300)
        XCTAssertEqual(context.read(atom1), 300)
    }

    func testObserve() {
        final class TestObserver: AtomObserver {
            var asignedAtomKeys = [AtomKey]()
            var unassignedAtomKeys = [AtomKey]()
            var changedAtomKeys = [AtomKey]()

            func atomAssigned<Node: Atom>(atom: Node) {
                asignedAtomKeys.append(AtomKey(atom))
            }

            func atomUnassigned<Node: Atom>(atom: Node) {
                unassignedAtomKeys.append(AtomKey(atom))
            }

            func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
                changedAtomKeys.append(AtomKey(snapshot.atom))
            }
        }

        let atom = TestStateAtom(defaultValue: 100)
        let key = AtomKey(atom)
        let observers = [TestObserver(), TestObserver()]
        let context = AtomTestContext()

        for observer in observers {
            context.observe(observer)
        }

        context.watch(atom)

        for observer in observers {
            XCTAssertEqual(observer.asignedAtomKeys, [key])
            XCTAssertEqual(observer.unassignedAtomKeys, [])
            XCTAssertEqual(observer.changedAtomKeys, [key])
        }

        context[atom] = 200

        for observer in observers {
            XCTAssertEqual(observer.asignedAtomKeys, [key])
            XCTAssertEqual(observer.unassignedAtomKeys, [])
            XCTAssertEqual(observer.changedAtomKeys, [key, key])
        }

        context.unwatch(atom)

        for observer in observers {
            XCTAssertEqual(observer.asignedAtomKeys, [key])
            XCTAssertEqual(observer.unassignedAtomKeys, [key])
            XCTAssertEqual(observer.changedAtomKeys, [key, key])
        }
    }

    func testTerminate() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 100)

        context[atom] = 200

        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.unwatch(atom)

        XCTAssertEqual(context.read(atom), 100)
        XCTAssertEqual(updateCount, 0)
    }

    func testSubscript() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.watch(atom)

        XCTAssertEqual(context[atom], 100)
        XCTAssertEqual(updateCount, 0)

        context[atom] = 200

        XCTAssertEqual(context[atom], 200)
        XCTAssertEqual(updateCount, 1)
    }

    func testRead() {
        let atom = TestValueAtom(value: 100)
        let context = AtomTestContext()

        XCTAssertEqual(context.read(atom), 100)
    }

    func testWatch() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertEqual(updateCount, 0)

        context[atom] = 200

        XCTAssertEqual(context.watch(atom), 200)
        XCTAssertEqual(updateCount, 1)
    }

    func testRefresh() async {
        let atom = TestTaskAtom(value: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.watch(atom)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
        XCTAssertEqual(updateCount, 1)
    }

    func testReset() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context.read(atom), 100)

        context.reset(atom)

        XCTAssertEqual(context.read(atom), 0)
    }
}
