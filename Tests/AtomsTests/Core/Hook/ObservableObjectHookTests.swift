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

    func testUpdate() {
        let hook = ObservableObjectHook { _ in TestObject() }
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Update") { _ in
            let object = context.watch(atom)
            var updateCount = 0
            let expectation = expectation(description: "Update")

            context.onUpdate = {
                updateCount = object.updatedCount
                expectation.fulfill()
            }
            object.update()

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(updateCount, 1)
        }

        XCTContext.runActivity(named: "Termination") { _ in
            context.unwatch(atom)

            let object = context.watch(atom)
            var updateCount = 0
            let expectation = expectation(description: "Termination")

            context.onUpdate = {
                updateCount = object.updatedCount
                expectation.fulfill()
            }
            object.update()

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(updateCount, 1)
        }

        XCTContext.runActivity(named: "Override") { _ in
            let overrideObject = TestObject()
            context.unwatch(atom)
            context.override(atom) { _ in overrideObject }

            let object = context.watch(atom)
            var updateCount = 0
            let expectation = expectation(description: "Override")

            context.onUpdate = {
                updateCount = object.updatedCount
                expectation.fulfill()
            }
            object.update()

            XCTAssertTrue(object === overrideObject)
            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(updateCount, 1)
        }

        XCTContext.runActivity(named: "Override termination") { _ in
            let overrideObject = TestObject()
            context.unwatch(atom)
            context.override(atom) { _ in overrideObject }

            let object = context.watch(atom)
            var updateCount = 0
            let expectation = expectation(description: "Override termination")

            context.onUpdate = {
                updateCount = object.updatedCount
                expectation.fulfill()
            }
            object.update()

            XCTAssertTrue(object === overrideObject)
            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(updateCount, 1)
        }
    }
}
