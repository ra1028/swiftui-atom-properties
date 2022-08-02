import Combine
import XCTest

@testable import Atoms

@MainActor
final class TaskPhaseModifierTests: XCTestCase {
    func testPhase() {
        let atom = TestTaskAtom(value: 0)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom.phase), .suspending)

        let expectation = expectation(description: "testPhase")
        context.onUpdate = expectation.fulfill

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(context.watch(atom.phase), .success(0))
    }

    func testKey() {
        let atom = TestTaskAtom(value: 0)
        let modifier = TaskPhaseModifier(atom: atom)

        XCTAssertEqual(atom.key.hashValue, modifier.key.hashValue)
        XCTAssertNotEqual(
            ObjectIdentifier(type(of: atom.key)),
            ObjectIdentifier(type(of: modifier.key))
        )
    }

    func testShouldNotifyUpdate() {
        let atom = TestTaskAtom(value: 0)
        let modifier = TaskPhaseModifier(atom: atom)

        XCTAssertTrue(modifier.shouldNotifyUpdate(newValue: .suspending, oldValue: .suspending))
        XCTAssertTrue(modifier.shouldNotifyUpdate(newValue: .success(100), oldValue: .success(200)))
    }

    func testMakeCoordinator() {
        let atom = TestTaskAtom(value: 0)
        let modifier = TaskPhaseModifier(atom: atom)
        let coordinator = modifier.makeCoordinator()

        XCTAssertNil(coordinator.phase)
    }

    func testValue() {
        let atom = TestTaskAtom(value: 0)
        let modifier = TaskPhaseModifier(atom: atom)
        let coordinator = modifier.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: modifier),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.phase = .success(100)

        XCTAssertEqual(modifier.value(context: context).value, 100)
    }

    func testUpdate() {
        var getValue: () async throws -> Int = { 0 }
        let atom = TestAtom(
            key: 0,
            hook: ThrowingTaskHook { _ in try await getValue() }
        )
        let modifier = TaskPhaseModifier(atom: atom)
        let modified = ModifiedAtom(modifier: modifier)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Initially suspending") { _ in
            XCTAssertTrue(context.watch(modified).isSuspending)
        }

        XCTContext.runActivity(named: "Value") { _ in
            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(context.watch(modified).value, 0)
        }

        XCTContext.runActivity(named: "Error") { _ in
            getValue = { throw URLError(.badURL) }
            context.onUpdate = nil
            context.unwatch(modified)
            context.watch(modified)

            let expectation = expectation(description: "Update")
            context.onUpdate = expectation.fulfill

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(
                context.watch(modified).error as? URLError,
                URLError(.badURL)
            )
        }

        XCTContext.runActivity(named: "Termination") { _ in
            getValue = { 0 }
            context.unwatch(modified)
            context.watch(modified)
            context.unwatch(modified)

            let expectation = expectation(description: "Update")
            expectation.isInverted = true
            context.onUpdate = expectation.fulfill

            wait(for: [expectation], timeout: 1)
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.override(modified) { _ in .success(100) }

            XCTAssertEqual(context.watch(modified).value, 100)
        }
    }
}
