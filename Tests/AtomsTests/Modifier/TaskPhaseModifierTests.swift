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
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}

        var phase: AsyncPhase<Int, Never>?
        let expectation = expectation(description: "testValue")
        let context = AtomLoaderContext<AsyncPhase<Int, Never>>(
            store: StoreContext(store),
            transaction: transaction,
            update: { newPhase, _ in
                phase = newPhase
                expectation.fulfill()
            }
        )

        let task = Task { 100 }
        let initialPhase = modifier.value(context: context, with: task)

        XCTAssertEqual(initialPhase, .suspending)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(phase, .success(100))
    }

    func testHandle() {
        let atom = TestValueAtom(value: 0)
        let modifier = TaskPhaseModifier<Int, Never>()
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomLoaderContext<AsyncPhase<Int, Never>>(
            store: StoreContext(store),
            transaction: transaction,
            update: { _, _ in }
        )

        let phase = modifier.handle(context: context, with: .success(100))
        XCTAssertEqual(phase, .success(100))
    }
}
