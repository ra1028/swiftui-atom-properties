import XCTest

@testable import Atoms

@MainActor
final class ModifiedHookTests: XCTestCase {
    func testMakeCoordinator() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let hook = ModifiedHook(atom: atom, modifier: modifier)
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.selected)
    }

    func testValue() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let hook = ModifiedHook(atom: atom, modifier: modifier)
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: atom,
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.selected = "test"

        XCTAssertEqual(hook.value(context: context), modifier.get(context: context))
    }

    func testUpdate() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let hook = ModifiedHook(atom: atom, modifier: modifier)
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: atom,
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        hook.update(context: context)

        XCTAssertEqual(coordinator.selected, "0")
    }

    func testUpdateOverride() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let hook = ModifiedHook(atom: atom, modifier: modifier)
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: atom,
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        hook.updateOverride(context: context, with: "test")

        XCTAssertEqual(coordinator.selected, "test")
    }
}
