import XCTest

@testable import Atoms

@MainActor
final class AtomStateContextTests: XCTestCase {
    func testAtomContext() {
        let atom = TestValueAtom(value: 100)
        let store = Store(container: StoreContainer())
        let context = AtomStateContext(atom: atom, store: store)

        XCTAssertEqual(context.atomContext.read(atom), 100)
    }

    func testNotifyUpdate() {
        let atom = TestValueAtom(value: 100)
        let storeContainer = StoreContainer()
        let store = Store(container: storeContainer)
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let context = AtomStateContext(atom: atom, store: store)
        var updateCount = 0

        _ = store.watch(atom, relationship: relationship) {
            updateCount += 1
        }

        context.notifyUpdate()
        context.notifyUpdate()
        context.notifyUpdate()

        XCTAssertEqual(updateCount, 3)
    }

    func testAddTermination() {
        let atom = TestValueAtom(value: 100)
        let storeContainer = StoreContainer()
        let store = Store(container: storeContainer)
        var relationshipContainer: RelationshipContainer? = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer!)
        let context = AtomStateContext(atom: atom, store: store)
        var terminationCount0 = 0
        var terminationCount1 = 0

        _ = store.watch(atom, relationship: relationship) {}

        context.addTermination {
            terminationCount0 += 1
        }
        context.addTermination {
            terminationCount1 += 1
        }

        relationshipContainer = nil

        XCTAssertEqual(terminationCount0, 1)
        XCTAssertEqual(terminationCount1, 1)
    }
}
