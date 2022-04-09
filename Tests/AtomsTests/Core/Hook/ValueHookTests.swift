import XCTest

@testable import Atoms

@MainActor
final class ValueHookTests: XCTestCase {
    func testMakeCoordinator() {
        let hook = ValueHook { _ in 0 }
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.value)
    }

    func testValue() {
        let hook = ValueHook { _ in 0 }
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.value = 100

        XCTAssertEqual(hook.value(context: context), 100)
    }

    func testUpdate() {
        let hook = ValueHook { _ in 100 }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Value") { _ in
            XCTAssertEqual(context.watch(atom), 100)
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.unwatch(atom)
            context.override(atom) { _ in 200 }

            XCTAssertEqual(context.watch(atom), 200)
        }
    }
}
