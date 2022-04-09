import XCTest

@testable import Atoms

@MainActor
final class TaskAtomTests: XCTestCase {
    struct TestAtom: TaskAtom, Hashable {
        let value: Int

        func value(context: Context) async -> Int {
            value
        }
    }

    func test() async {
        let atom = TestAtom(value: 100)
        let context = AtomTestContext()
        let value = await context.watch(atom).value

        XCTAssertEqual(value, 100)
    }
}
