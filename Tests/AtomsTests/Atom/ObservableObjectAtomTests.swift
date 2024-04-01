import XCTest

@testable import Atoms

final class ObservableObjectAtomTests: XCTestCase {
    @MainActor
    final class TestObject: ObservableObject {
        @Published
        private(set) var updatedCount = 0

        func update() {
            updatedCount += 1
        }
    }

    struct TestAtom: ObservableObjectAtom {
        var onUpdated: ((TestObject, TestObject) -> Void)?

        var key: UniqueKey {
            UniqueKey()
        }

        func object(context: Context) -> TestObject {
            TestObject()
        }

        func updated(newValue: TestObject, oldValue: TestObject, context: UpdatedContext) {
            onUpdated?(newValue, oldValue)
        }
    }

    @MainActor
    func test() async {
        let atom = TestAtom()
        let context = AtomTestContext()

        do {
            // Initial value
            let object = context.watch(atom)
            XCTAssertEqual(object.updatedCount, 0)
        }

        do {
            // Update
            let object = context.watch(atom)
            var snapshot: Int?

            context.onUpdate = {
                // @Published property should be updated before notified
                snapshot = object.updatedCount
            }

            object.update()
            await context.waitForUpdate()

            XCTAssertEqual(snapshot, 1)
        }

        do {
            // Termination
            context.unwatch(atom)

            let object = context.watch(atom)
            var updateCount = 0

            context.onUpdate = {
                updateCount = object.updatedCount
            }

            object.update()
            await context.waitForUpdate()

            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Override
            let overrideObject = TestObject()
            context.unwatch(atom)
            context.override(atom) { _ in overrideObject }

            let object = context.watch(atom)
            var updateCount = 0

            context.onUpdate = {
                updateCount = object.updatedCount
            }
            object.update()
            await context.waitForUpdate()

            XCTAssertTrue(object === overrideObject)
            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Override termination
            let overrideObject = TestObject()
            context.unwatch(atom)
            context.override(atom) { _ in overrideObject }

            let object = context.watch(atom)
            var updateCount = 0

            context.onUpdate = {
                updateCount = object.updatedCount
            }
            object.update()
            await context.waitForUpdate()

            XCTAssertTrue(object === overrideObject)
            XCTAssertEqual(updateCount, 1)
        }
    }

    @MainActor
    func testUpdated() async {
        var updatedObjects = [TestObject]()
        let atom = TestAtom { object, _ in
            updatedObjects.append(object)
        }
        let context = AtomTestContext()
        let object = context.watch(atom)

        XCTAssertTrue(updatedObjects.isEmpty)
        object.update()

        await context.waitForUpdate()

        XCTAssertEqual(updatedObjects.last?.updatedCount, 1)
    }
}
