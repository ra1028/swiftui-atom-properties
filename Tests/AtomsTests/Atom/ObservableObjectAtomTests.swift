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
        var state = EffectState()
        let effect = TestEffect(
            onInitialize: { state.initialized += 1 },
            onUpdate: { state.updated += 1 },
            onRelease: { state.released += 1 }
        )
        let atom = TestObservableObjectAtom(effect: effect)
        let context = AtomTestContext()
        let object = context.watch(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 0,
                released: 0
            )
        )

        object.update()
        await context.waitForUpdate()

        object.update()
        await context.waitForUpdate()

        object.update()
        await context.waitForUpdate()

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 3,
                released: 0
            )
        )

        context.unwatch(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 3,
                released: 1
            )
        )
    }
}
