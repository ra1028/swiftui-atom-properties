import XCTest

@testable import Atoms

@MainActor
final class AtomNodeContextTests: XCTestCase {
    //    func testAddTermination() {
    //        let atom = TestValueAtom(value: 100)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let relationshipContainer = RelationshipContainer()
    //        let relationship = Relationship(container: relationshipContainer)
    //        let context = AtomNodeContext(atom: atom, store: store)
    //        var terminationCount0 = 0
    //        var terminationCount1 = 0
    //
    //        _ = store.watch(atom, relationship: relationship) {}
    //
    //        context.addTermination {
    //            terminationCount0 += 1
    //        }
    //        context.addTermination {
    //            terminationCount1 += 1
    //        }
    //
    //        context.reset(atom)
    //
    //        XCTAssertEqual(terminationCount0, 1)
    //        XCTAssertEqual(terminationCount1, 1)
    //    }
    //
    //    func testKeepUntilTermination() {
    //        let atom = TestValueAtom(value: 100)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let relationshipContainer = RelationshipContainer()
    //        let relationship = Relationship(container: relationshipContainer)
    //        let context = AtomNodeContext(atom: atom, store: store)
    //        var object: Object? = Object()
    //        var isDeinitialized = false
    //
    //        object?.onDeinit = {
    //            isDeinitialized = true
    //        }
    //
    //        _ = store.watch(atom, relationship: relationship) {}
    //
    //        context.keepUntilTermination(object!)
    //
    //        object = nil
    //        XCTAssertFalse(isDeinitialized)
    //
    //        context.reset(atom)
    //        XCTAssertTrue(isDeinitialized)
    //    }
    //
    //    func testSubscript() {
    //        let atom = TestStateAtom(defaultValue: 100)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let relationshipContainer = RelationshipContainer()
    //        let relationship = Relationship(container: relationshipContainer)
    //        let context = AtomNodeContext(atom: atom, store: store)
    //        var updateCount = 0
    //
    //        _ = store.watch(atom, relationship: relationship) {
    //            updateCount += 1
    //        }
    //
    //        XCTAssertEqual(context[atom], 100)
    //        XCTAssertEqual(updateCount, 0)
    //
    //        context[atom] = 200
    //
    //        XCTAssertEqual(context[atom], 200)
    //        XCTAssertEqual(updateCount, 1)
    //    }
    //
    //    func testRead() {
    //        let atom = TestValueAtom(value: 100)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let context = AtomNodeContext(atom: atom, store: store)
    //
    //        XCTAssertEqual(context.read(atom), 100)
    //    }
    //
    //    func testWatch() {
    //        let atom0 = TestValueAtom(value: 100)
    //        let atom1 = TestStateAtom(defaultValue: 200)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let relationshipContainer = RelationshipContainer()
    //        let relationship = Relationship(container: relationshipContainer)
    //        let context = AtomNodeContext(atom: atom0, store: store)
    //        var updateCount = 0
    //
    //        _ = store.watch(atom0, relationship: relationship) {
    //            updateCount += 1
    //        }
    //
    //        XCTAssertEqual(context.watch(atom1), 200)
    //        XCTAssertEqual(updateCount, 0)
    //
    //        // Resetting atom1 triggers atom0 update.
    //        context.reset(atom1)
    //
    //        XCTAssertEqual(updateCount, 1)
    //    }
    //
    //    func testRefresh() async {
    //        let atom = TestTaskAtom(value: 100)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let relationshipContainer = RelationshipContainer()
    //        let relationship = Relationship(container: relationshipContainer)
    //        let context = AtomNodeContext(atom: atom, store: store)
    //        var updateCount = 0
    //
    //        _ = store.watch(atom, relationship: relationship) {
    //            updateCount += 1
    //        }
    //
    //        let value = await context.refresh(atom).value
    //
    //        XCTAssertEqual(value, 100)
    //        XCTAssertEqual(updateCount, 1)
    //    }
    //
    //    func testReset() {
    //        let atom = TestStateAtom(defaultValue: 0)
    //        let storeContainer = StoreContainer()
    //        let store = Store(container: storeContainer)
    //        let relationshipContainer = RelationshipContainer()
    //        let relationship = Relationship(container: relationshipContainer)
    //        let context = AtomNodeContext(atom: atom, store: store)
    //        var updateCount = 0
    //
    //        _ = store.watch(atom, relationship: relationship) {
    //            updateCount += 1
    //        }
    //
    //        context[atom] = 100
    //
    //        XCTAssertEqual(context.read(atom), 100)
    //        XCTAssertEqual(updateCount, 1)
    //
    //        context.reset(atom)
    //
    //        XCTAssertEqual(context.read(atom), 0)
    //        XCTAssertEqual(updateCount, 2)
    //    }
}
