import Combine
import XCTest

@testable import Atoms

@MainActor
final class TaskPhaseModifierHookTests: XCTestCase {
    func testMakeCoordinator() {
        let base = TestTaskAtom(value: 0)
        let hook = TaskPhaseModifierHook(base: base)
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.phase)
    }

    func testValue() {
        let base = TestTaskAtom(value: 0)
        let hook = TaskPhaseModifierHook(base: base)
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.phase = .success(100)

        XCTAssertEqual(hook.value(context: context).value, 100)
    }

    func testUpdate() {
        var getValue: () async throws -> Int = { 0 }
        let base = TestAtom(
            key: 0,
            hook: ThrowingTaskHook { _ in try await getValue() }
        )
        let hook = TaskPhaseModifierHook(base: base)
        let atom = TestAtom(key: 1, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Initially suspending") { _ in
            XCTAssertTrue(context.watch(atom).isSuspending)
        }

        XCTContext.runActivity(named: "Value") { _ in
            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(atom).value, 0)
        }

        XCTContext.runActivity(named: "Error") { _ in
            getValue = { throw URLError(.badURL) }
            context.onUpdate = nil
            context.unwatch(atom)
            context.watch(atom)

            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(
                context.watch(atom).error as? URLError,
                URLError(.badURL)
            )
        }

        XCTContext.runActivity(named: "Termination") { _ in
            getValue = { 0 }
            context.unwatch(atom)
            context.watch(atom)
            context.unwatch(atom)

            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill

            wait(for: [expectation], timeout: 1)
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.override(atom) { _ in .success(100) }

            XCTAssertEqual(context.watch(atom).value, 100)
        }
    }
}
