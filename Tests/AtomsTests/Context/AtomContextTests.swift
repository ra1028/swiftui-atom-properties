import XCTest

@testable import Atoms

final class AtomContextTests: XCTestCase {
    @MainActor
    func testSubscript() {
        let atom = TestStateAtom(defaultValue: 0)
        let context: AtomWatchableContext = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context[atom], 100)
    }
}
