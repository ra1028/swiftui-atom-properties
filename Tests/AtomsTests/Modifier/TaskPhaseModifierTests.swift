import Combine
import XCTest

@testable import Atoms

@MainActor
final class TaskPhaseModifierTests: XCTestCase {
    func testPhase() async {
        let atom = TestTaskAtom(value: 0).phase
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), .suspending)

        await context.wait(for: atom, until: \.isSuccess)

        XCTAssertEqual(context.watch(atom), .success(0))
    }

    func testKey() {
        let modifier = TaskPhaseModifier<Int, Never>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }

    func testModify() {
        let atom = TestValueAtom(value: 0)
        let modifier = TaskPhaseModifier<Int, Never>()
        let transaction = Transaction(key: AtomKey(atom)) {}
        var phase: AsyncPhase<Int, Never>?
        let expectation = expectation(description: "testValue")
        let context = AtomModifierContext<AsyncPhase<Int, Never>>(transaction: transaction) { newPhase in
            phase = newPhase
            expectation.fulfill()
        }
        let task = Task { 100 }
        let initialPhase = modifier.modify(value: task, context: context)

        XCTAssertEqual(initialPhase, .suspending)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(phase, .success(100))
    }

    func testAssociateOverridden() {
        let atom = TestValueAtom(value: 0)
        let modifier = TaskPhaseModifier<Int, Never>()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomModifierContext<AsyncPhase<Int, Never>>(transaction: transaction) { _ in }
        let phase = modifier.associateOverridden(value: .success(100), context: context)

        XCTAssertEqual(phase, .success(100))
    }

    func testRefresh() async {
        let atom = TestTaskAtom(value: 0).phase
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), .suspending)

        let phase = await context.refresh(atom)

        XCTAssertEqual(phase, .success(0))
        XCTAssertEqual(context.watch(atom), .success(0))
    }
}
