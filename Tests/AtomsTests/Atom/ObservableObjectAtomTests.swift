import XCTest

@testable import Atoms

final class ObservableObjectAtomTests: XCTestCase {
    @MainActor
    func test() async {
        let atom = TestObservableObjectAtom()
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
            let overrideObject = TestObservableObject()
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
            let overrideObject = TestObservableObject()
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
    func testEffect() async {
        let effect = TestEffect()
        let atom = TestObservableObjectAtom(effect: effect)
        let context = AtomTestContext()
        let object = context.watch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 0)
        XCTAssertEqual(effect.releasedCount, 0)

        object.update()
        await context.waitForUpdate()

        object.update()
        await context.waitForUpdate()

        object.update()
        await context.waitForUpdate()

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 0)

        context.unwatch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 1)
    }

    @MainActor
    func testUpdateMultipletimes() async {
        final class TestObject: ObservableObject {
            @Published
            var value0 = 0
            @Published
            var value1 = 0

            func update() {
                value0 += 1
                value1 += 1
            }
        }

        struct TestAtom: ObservableObjectAtom, Hashable {
            func object(context: Context) -> TestObject {
                TestObject()
            }
        }

        let atom = TestAtom()
        let context = AtomTestContext()
        let object = context.watch(atom)
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        object.update()

        await context.wait(for: atom) {
            $0.value0 == 1 && $0.value1 == 1
        }

        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(object.value0, 1)
        XCTAssertEqual(object.value1, 1)
    }
}
