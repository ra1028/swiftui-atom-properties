import XCTest

@testable import Atoms

@MainActor
final class AsyncSequenceAtomTests: XCTestCase {
    struct TestAtom: AsyncSequenceAtom, Hashable {
        let value: Int

        func sequence(context: Context) -> AsyncStream<Int> {
            AsyncStream { continuation in
                continuation.yield(value)
                continuation.finish()
            }
        }
    }

    func test() async {
        let atom = TestAtom(value: 100)
        let context = AtomTestContext()

        context.watch(atom)

        let phase = await context.refresh(atom)

        XCTAssertEqual(phase.value, 100)
    }
}
