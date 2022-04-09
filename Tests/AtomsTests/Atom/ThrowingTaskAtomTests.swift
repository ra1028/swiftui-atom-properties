import XCTest

@testable import Atoms

@MainActor
final class ThrowingTaskAtomTests: XCTestCase {
    struct TestAtom: ThrowingTaskAtom, Hashable {
        let value: Int

        func value(context: Context) async throws -> Int {
            value
        }
    }

    func test() async throws {
        let atom = TestAtom(value: 100)
        let context = AtomTestContext()
        let value = try await context.watch(atom).value

        XCTAssertEqual(value, 100)
    }
}
