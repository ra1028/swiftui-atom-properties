import XCTest

@testable import Atoms

final class ValueAtomTests: XCTestCase {
    @MainActor
    func testValue() {
        let atom = TestValueAtom(value: 0)
        let context = AtomTestContext()

        do {
            // Initial value
            let value = context.watch(atom)
            XCTAssertEqual(value, 0)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in 1 }

            XCTAssertEqual(context.watch(atom), 1)
        }
    }

    @MainActor
    func testUpdated() async {
        var updatedValues = [Pair<Int>]()
        let atom = TestValueAtom(value: 0) { new, old in
            let values = Pair(first: new, second: old)
            updatedValues.append(values)
        }
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertTrue(updatedValues.isEmpty)

        context.reset(atom)

        XCTAssertEqual(updatedValues, [Pair(first: 0, second: 0)])
    }
}
