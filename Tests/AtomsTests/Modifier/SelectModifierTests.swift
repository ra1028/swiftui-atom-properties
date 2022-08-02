import XCTest

@testable import Atoms

@MainActor
final class SelectModifierTests: XCTestCase {
    func testSelect() {
        let atom = TestStateAtom(defaultValue: "")
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        XCTAssertEqual(updatedCount, 0)
        XCTAssertEqual(context.watch(atom.select(\.count)), 0)

        context[atom] = "modified"

        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.select(\.count)), 8)
        context[atom] = "modified"

        // Should not be updated with an equivalent value.
        XCTAssertEqual(updatedCount, 1)
    }

    func testKey() {
        let atom = TestStateAtom(defaultValue: "")
        let modifier = SelectModifier(atom: atom, keyPath: \.count)

        XCTAssertNotEqual(ObjectIdentifier(type(of: atom.key)), ObjectIdentifier(type(of: modifier.key)))
        XCTAssertNotEqual(atom.key.hashValue, modifier.key.hashValue)
    }

    func testShouldNotifyUpdate() {
        let atom = TestStateAtom(defaultValue: "")
        let modifier = SelectModifier(atom: atom, keyPath: \.count)

        XCTAssertFalse(modifier.shouldNotifyUpdate(newValue: 100, oldValue: 100))
        XCTAssertTrue(modifier.shouldNotifyUpdate(newValue: 100, oldValue: 200))
    }

    func testMakeCoordinator() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier(atom: atom, keyPath: \.description)
        let coordinator = modifier.makeCoordinator()

        XCTAssertNil(coordinator.value)
    }

    func testValue() {
        let atom = TestValueAtom(value: 100)
        let modifier = SelectModifier(atom: atom, keyPath: \.description)
        let coordinator = modifier.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: modifier),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.value = "test"

        XCTAssertEqual(modifier.value(context: context), "test")
    }

    func testUpdate() {
        let atom = TestValueAtom(value: 100)
        let modifier = SelectModifier(atom: atom, keyPath: \.description)
        let modified = ModifiedAtom(modifier: modifier)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Value") { _ in
            XCTAssertEqual(context.watch(modified), "100")
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.unwatch(modified)
            context.override(modified) { _ in "override" }

            XCTAssertEqual(context.watch(modified), "override")
        }
    }
}
