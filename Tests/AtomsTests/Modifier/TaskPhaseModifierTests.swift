import Combine
import XCTest

@testable import Atoms

final class TaskPhaseModifierTests: XCTestCase {
    @MainActor
    func testPhase() async {
        let atom = TestTaskAtom { 0 }.phase
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), .suspending)

        await context.wait(for: atom, until: \.isSuccess)

        XCTAssertEqual(context.watch(atom), .success(0))
    }

    @MainActor
    func testRefresh() async {
        let atom = TestTaskAtom { 0 }.phase
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), .suspending)

        let phase = await context.refresh(atom)
        XCTAssertEqual(phase, .success(0))
        XCTAssertEqual(context.watch(atom), .success(0))
    }

    func testKey() {
        let modifier = TaskPhaseModifier<Int, Never>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }
}
