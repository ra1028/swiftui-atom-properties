import XCTest

@testable import Atoms

@MainActor
final class ObservableObjectHookTests: XCTestCase {
    final class TestObject: ObservableObject {}

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
        var updateCount = 0

        context.onUpdate = { updateCount += 1 }

        let object0 = context.watch(atom)

        XCTContext.runActivity(named: "Update") { _ in
            object0.objectWillChange.send()
            XCTAssertEqual(updateCount, 1)
        }

        XCTContext.runActivity(named: "Termination") { _ in
            context.unwatch(atom)

            object0.objectWillChange.send()
            XCTAssertEqual(updateCount, 1)
        }

        let overrideObject = TestObject()
        context.override(atom) { _ in overrideObject }

        let object1 = context.watch(atom)

        XCTContext.runActivity(named: "Override") { _ in
            XCTAssertTrue(object1 === overrideObject)

            object1.objectWillChange.send()

            XCTAssertEqual(updateCount, 2)
        }

        XCTContext.runActivity(named: "Override termination") { _ in
            context.unwatch(atom)

            object1.objectWillChange.send()

            XCTAssertEqual(updateCount, 2)
        }
    }
}
