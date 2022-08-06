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
        let modifier = TaskPhaseModifier<Int, Never>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }

    func testMakeCoordinator() {
        let modifier = TaskPhaseModifier<Int, Never>()
        let coordinator = modifier.makeCoordinator()

        XCTAssertNil(coordinator.phase)
    }

    func testGet() {
        let modifier = TaskPhaseModifier<Int, Never>()
        let coordinator = modifier.makeCoordinator()
        let context = AtomHookContext(
            atom: TestValueAtom(value: 0),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.phase = .success(100)

        XCTAssertEqual(modifier.get(context: context), .success(100))
    }

    func testSet() {
        let modifier = TaskPhaseModifier<Int, Never>()
        let coordinator = modifier.makeCoordinator()
        let context = AtomHookContext(
            atom: TestValueAtom(value: 0),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        modifier.set(value: .success(100), context: context)

        XCTAssertEqual(coordinator.phase, .success(100))
    }

    func testUpdate() {
        let modifier = TaskPhaseModifier<Int, Never>()
        let atom = TestValueAtom(value: 0)
        let container = StoreContainer()
        let coordinator = modifier.makeCoordinator()
        let context = AtomHookContext(
            atom: atom,
            coordinator: coordinator,
            store: Store(container: container)
        )
        let task = Task { 100 }
        let host = AtomHost<TestValueAtom<Int>.Hook.Coordinator>()
        let expectation = expectation(description: "testUpdate")

        host.coordinator = atom.hook.makeCoordinator()
        host.onUpdate = { _ in expectation.fulfill() }
        container.entries[AtomKey(atom.key)] = WeakStoreEntry(host: host)
        modifier.update(context: context, with: task)

        XCTAssertEqual(coordinator.phase, .suspending)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(coordinator.phase, .success(100))
    }
}
