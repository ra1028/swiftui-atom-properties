import XCTest

@testable import Atoms

@MainActor
final class SelectModifierHookTests: XCTestCase {
    func testMakeCoordinator() {
        let base = TestValueAtom(value: 0)
        let hook = SelectModifierHook(base: base, keyPath: \.description)
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.value)
    }

    func testValue() {
        let base = TestValueAtom(value: 100)
        let hook = SelectModifierHook(base: base, keyPath: \.description)
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.value = "test"

        XCTAssertEqual(hook.value(context: context), "test")
    }

    func testUpdate() {
        let base = TestValueAtom(value: 100)
        let hook = SelectModifierHook(base: base, keyPath: \.description)
        let atom = TestAtom(key: 1, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Value") { _ in
            XCTAssertEqual(context.watch(atom), "100")
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.unwatch(atom)
            context.override(atom) { _ in "override" }

            XCTAssertEqual(context.watch(atom), "override")
        }
    }
}
