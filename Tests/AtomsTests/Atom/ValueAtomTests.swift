import XCTest

@testable import Atoms

@MainActor
final class ValueAtomTests: XCTestCase {
    struct TestAtom: ValueAtom, Hashable {
        let value: Int

        func value(context: Context) -> Int {
            value
        }
    }

    func test() {
        let atom = TestValueAtom(value: 100)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 100)
    }
}
