import XCTest

@testable import Atoms

@MainActor
final class ObservableObjectAtomTests: XCTestCase {
    final class TestObject: ObservableObject {
        @Published
        var value: Int

        init(value: Int) {
            self.value = value
        }
    }

    struct TestAtom: ObservableObjectAtom, Hashable {
        let value: Int

        func object(context: Context) -> TestObject {
            TestObject(value: value)
        }
    }

    func test() {
        let atom = TestAtom(value: 100)
        let context = AtomTestContext()
        let object = context.watch(atom)
        var isUpdated = false

        XCTAssertEqual(object.value, 100)
        XCTAssertFalse(isUpdated)

        context.onUpdate = { isUpdated = true }
        object.value = 200

        XCTAssertEqual(object.value, 200)
        XCTAssertTrue(isUpdated)
    }
}
