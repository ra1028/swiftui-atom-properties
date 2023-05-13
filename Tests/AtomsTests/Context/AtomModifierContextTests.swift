import XCTest

@testable import Atoms

@MainActor
final class AtomModifierContextTests: XCTestCase {
    func testUpdate() {
        let atom = TestValueAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom)) {}
        var updatedValue: Int?
        let context = AtomModifierContext<Int>(transaction: transaction) { value in
            updatedValue = value
        }

        context.update(with: 1)

        XCTAssertEqual(updatedValue, 1)
    }

    func testAddTermination() {
        let atom = TestValueAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomModifierContext<Int>(transaction: transaction) { _ in }

        context.addTermination {}
        context.addTermination {}

        XCTAssertEqual(transaction.terminations.count, 2)

        transaction.terminate()
        context.addTermination {}

        XCTAssertTrue(transaction.terminations.isEmpty)
    }
}
