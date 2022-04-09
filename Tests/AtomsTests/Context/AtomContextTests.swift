import XCTest

@testable import Atoms

@MainActor
final class AtomContextTests: XCTestCase {
    func testSubscript() {
        let atom = TestStateAtom(defaultValue: 0)
        let context: AtomWatchableContext = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context[atom], 100)
    }

    func testState() {
        let atom = TestStateAtom(defaultValue: 0)
        let context: AtomWatchableContext = AtomTestContext()
        let state = context.state(atom)

        XCTAssertEqual(context.read(atom), 0)

        state.wrappedValue = 100

        XCTAssertEqual(state.wrappedValue, 100)
        XCTAssertEqual(context.read(atom), 100)
    }
}
