import XCTest

@testable import Atoms

@MainActor
final class ObservableObjectHookTests: XCTestCase {
    @MainActor
    final class TestObject: ObservableObject {
        @Published
        private(set) var updatedCount = 0

        func update() {
            updatedCount += 1
        }
    }

    func testMakeCoordinator() {
        let object = TestObject()
        let hook = ObservableObjectHook { _ in object }
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.object)
    }

    func testValue() {
        let object = TestObject()
        let hook = ObservableObjectHook { _ in object }
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.object = object

        XCTAssertTrue(hook.value(context: context) === object)
    }

    func testUpdate() async {
        let hook = ObservableObjectHook { _ in TestObject() }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        do {
            // Update
            let object = context.watch(atom)
            var updateCount = 0

            context.onUpdate = {
                updateCount = object.updatedCount
            }
            object.update()
            await context.waitUntilNextUpdate()

            XCTAssertEqual(updateCount, 1)
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
            await context.waitUntilNextUpdate()

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
            await context.waitUntilNextUpdate()

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
            await context.waitUntilNextUpdate()

            XCTAssertTrue(object === overrideObject)
            XCTAssertEqual(updateCount, 1)
        }
    }
}
