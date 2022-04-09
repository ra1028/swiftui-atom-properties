import Atoms
import XCTest

@testable import ExampleCounter

@MainActor
final class ExampleCounterTests: XCTestCase {
    func testCounterAtom() {
        let context = AtomTestContext()
        let atom = CounterAtom()

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 1

        XCTAssertEqual(context.watch(atom), 1)
    }
}
