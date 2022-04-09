import Combine
import XCTest

@testable import Atoms

@MainActor
final class PublisherAtomTests: XCTestCase {
    struct TestAtom: PublisherAtom, Hashable {
        let value: Int

        func publisher(context: Context) -> Just<Int> {
            Just(value)
        }
    }

    func test() async {
        let atom = TestAtom(value: 100)
        let context = AtomTestContext()
        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
    }
}
