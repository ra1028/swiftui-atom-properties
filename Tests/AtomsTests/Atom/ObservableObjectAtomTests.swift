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

    func test() async {
        let atom = TestAtom(value: 100)
        let context = AtomTestContext()
        let object = context.watch(atom)
        var updatedValue: Int?

        context.onUpdate = {
            updatedValue = object.value
        }

        object.value = 200
        await context.waitUntilNextUpdate()

        XCTAssertEqual(updatedValue, 200)
    }
}
