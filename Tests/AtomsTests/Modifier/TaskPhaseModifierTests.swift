import Combine
import XCTest

@testable import Atoms

@MainActor
final class TaskPhaseModifierTests: XCTestCase {
    func testPhase() async {
        let atom = TestTaskAtom(value: 0)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom.phase), .suspending)

        await context.waitUntilNextUpdate(timeout: 1)

        XCTAssertEqual(context.watch(atom.phase), .success(0))
    }

    func testKey() {
        let modifier = TaskPhaseModifier<Int, Never>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }

    func testValue() {
        let atom = TestValueAtom(value: 0)
        let modifier = TaskPhaseModifier<Int, Never>()
        let container = StoreContainer()
        let store = Store(container: container)
        let context = AtomStateContext(atom: atom, store: store)
        let host = AtomHost<TestValueAtom<Int>.State>()
        let expectation = expectation(description: "testUpdate")
        let state = atom.makeState()

        host.state = state
        host.onUpdate = { _ in expectation.fulfill() }
        container.entries[AtomKey(atom.key)] = WeakStoreEntry(host: host)

        var phase: AsyncPhase<Int, Never>?
        let task = Task { 100 }
        let initialPhase = modifier.value(
            context: context,
            with: task,
            setValue: { phase = $0 }
        )

        XCTAssertEqual(initialPhase, .suspending)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(phase, .success(100))
    }
}
