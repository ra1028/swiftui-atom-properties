import Atoms
import XCTest

@testable import ExampleTimeTravel

final class ExampleTimeTravelTests: XCTestCase {
    @MainActor
    func testTextAtom() {
        let context = AtomTestContext()
        let atom = InputStateAtom()

        XCTAssertEqual(context.watch(atom), InputState())

        context[atom].text = "modified"
        context[atom].latestInput = 1

        XCTAssertEqual(context.watch(atom), InputState(text: "modified", latestInput: 1))
    }
}
