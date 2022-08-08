import XCTest

@testable import Atoms

@MainActor
final class ValueAtomTests: XCTestCase {
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
}
