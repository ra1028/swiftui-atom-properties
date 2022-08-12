import XCTest

@testable import Atoms

@MainActor
final class AtomViewContextTests: XCTestCase {
//    func testSubscript() {
//        let atom = TestStateAtom(defaultValue: 100)
//        let storeContainer = StoreContainer()
//        let store = Store(container: storeContainer)
//        let relationshipContainer = RelationshipContainer()
//        let relationship = Relationship(container: relationshipContainer)
//        var updateCount = 0
//        let context = AtomViewContext(store: store, relationship: relationship) {
//            updateCount += 1
//        }
//
//        context.watch(atom)
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
//        let relationshipContainer = RelationshipContainer()
//        let relationship = Relationship(container: relationshipContainer)
//        let context = AtomViewContext(store: store, relationship: relationship) {}
//
//        XCTAssertEqual(context.read(atom), 100)
//    }
//
//    func testWatch() {
//        let atom = TestStateAtom(defaultValue: 100)
//        let storeContainer = StoreContainer()
//        let store = Store(container: storeContainer)
//        let relationshipContainer = RelationshipContainer()
//        let relationship = Relationship(container: relationshipContainer)
//        var updateCount = 0
//        let context = AtomViewContext(store: store, relationship: relationship) {
//            updateCount += 1
//        }
//
//        XCTAssertEqual(context.watch(atom), 100)
//        XCTAssertEqual(updateCount, 0)
//
//        context[atom] = 200
//
//        XCTAssertEqual(context.watch(atom), 200)
//        XCTAssertEqual(updateCount, 1)
//    }
//
//    func testRefresh() async {
//        let atom = TestTaskAtom(value: 100)
//        let storeContainer = StoreContainer()
//        let store = Store(container: storeContainer)
//        let relationshipContainer = RelationshipContainer()
//        let relationship = Relationship(container: relationshipContainer)
//        var updateCount = 0
//        let context = AtomViewContext(store: store, relationship: relationship) {
//            updateCount += 1
//        }
//
//        context.watch(atom)
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
//        var updateCount = 0
//        let context = AtomViewContext(store: store, relationship: relationship) {
//            updateCount += 1
//        }
//
//        XCTAssertEqual(context.watch(atom), 0)
//
//        context[atom] = 100
//
//        XCTAssertEqual(context.read(atom), 100)
//
//        context.reset(atom)
//
//        XCTAssertEqual(context.read(atom), 0)
//    }
}
