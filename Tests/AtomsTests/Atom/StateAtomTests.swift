import XCTest

@testable import Atoms

@MainActor
final class StateAtomTests: XCTestCase {
    struct TestAtom: StateAtom, Hashable {
        let defaultValue: Int

        func defaultValue(context: Context) -> Int {
            defaultValue
        }
    }

    func test() {
        let atom = TestAtom(defaultValue: 100)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 100)

        context[atom] = 200

        XCTAssertEqual(context.watch(atom), 200)
    }
}
