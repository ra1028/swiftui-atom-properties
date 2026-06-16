import Combine
import Testing

@testable import Atoms

struct ObservableObjectAtomTests {
    @MainActor
    @Test
    func test() async {
        let atom = TestObservableObjectAtom()
        let context = AtomTestContext()

        do {
            // Initial value
            let object = context.watch(atom)
            #expect(object.updatedCount == 0)
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

            #expect(snapshot == 1)
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

            #expect(updateCount == 1)
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

            #expect(object === overrideObject)
            #expect(updateCount == 1)
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

            #expect(object === overrideObject)
            #expect(updateCount == 1)
        }
    }

    @MainActor
    @Test
    func testEffect() async {
        let effect = TestEffect()
        let atom = TestObservableObjectAtom(effect: effect)
        let context = AtomTestContext()
        let object = context.watch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        object.update()
        await context.waitForUpdate()

        object.update()
        await context.waitForUpdate()

        object.update()
        await context.waitForUpdate()

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 0)

        context.unwatch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 1)
    }

    @MainActor
    @Test
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
        await context.waitForUpdate()

        #expect(updatedCount == 1)
        #expect(object.value0 == 1)
        #expect(object.value1 == 1)
    }

    @MainActor
    @Test
    func testUpdateOnNonIsolatedContext() async {
        final class TestObject: ObservableObject, @unchecked Sendable {
            @Published
            var value = 0

            func update() {
                value += 1
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

        Task.detached {
            object.update()
        }

        await context.waitForUpdate()

        #expect(updatedCount == 1)
        #expect(object.value == 1)
    }
}
