import XCTest

@testable import Atoms

@MainActor
final class StateHookTests: XCTestCase {
    func testMakeCoordinator() {
        let hook = StateHook(
            defaultValue: { _ in 0 },
            willSet: { _, _, _ in },
            didSet: { _, _, _ in }
        )
        let coordinator = hook.makeCoordinator()

        XCTAssertNil(coordinator.value)
    }

    func testValue() {
        let hook = StateHook(
            defaultValue: { _ in 0 },
            willSet: { _, _, _ in },
            didSet: { _, _, _ in }
        )
        let coordinator = hook.makeCoordinator()
        let context = AtomHookContext(
            atom: TestAtom(key: 0, hook: hook),
            coordinator: coordinator,
            store: Store(container: StoreContainer())
        )

        coordinator.value = 100

        XCTAssertEqual(hook.value(context: context), 100)
    }

    func testUpdate() {
        let hook = StateHook(
            defaultValue: { _ in 100 },
            willSet: { _, _, _ in },
            didSet: { _, _, _ in }
        )
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        XCTContext.runActivity(named: "Value") { _ in
            XCTAssertEqual(context.watch(atom), 100)
        }

        XCTContext.runActivity(named: "Override") { _ in
            context.unwatch(atom)
            context.override(atom) { _ in 200 }

            XCTAssertEqual(context.watch(atom), 200)
        }
    }

    func testSet() {
        var willSetNewValues = [Int]()
        var willSetOldValues = [Int]()
        var didSetNewValues = [Int]()
        var didSetOldValues = [Int]()
        let hook = StateHook(
            defaultValue: { _ in 0 },
            willSet: { newValue, oldValue, _ in
                willSetNewValues.append(newValue)
                willSetOldValues.append(oldValue)
            },
            didSet: { newValue, oldValue, _ in
                didSetNewValues.append(newValue)
                didSetOldValues.append(oldValue)
            }
        )
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 0)
        XCTAssertTrue(willSetNewValues.isEmpty)
        XCTAssertTrue(willSetOldValues.isEmpty)
        XCTAssertTrue(didSetNewValues.isEmpty)
        XCTAssertTrue(didSetOldValues.isEmpty)

        context.onUpdate = {
            XCTAssertEqual(willSetNewValues, [100])
            XCTAssertEqual(willSetOldValues, [0])
            XCTAssertTrue(didSetNewValues.isEmpty)
            XCTAssertTrue(didSetOldValues.isEmpty)
        }

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertEqual(willSetNewValues, [100])
        XCTAssertEqual(willSetOldValues, [0])
        XCTAssertEqual(didSetNewValues, [100])
        XCTAssertEqual(didSetOldValues, [0])
    }

    func testSetOverride() {
        var willSetCount = 0
        var didSetCount = 0
        let hook = StateHook(
            defaultValue: { _ in 0 },
            willSet: { _, _, _ in willSetCount += 1 },
            didSet: { _, _, _ in didSetCount += 1 }
        )
        let atom = TestAtom(key: 0, hook: hook)
        let context = AtomTestContext()

        context.override(atom) { _ in 200 }

        XCTAssertEqual(context.watch(atom), 200)
        XCTAssertEqual(willSetCount, 0)
        XCTAssertEqual(didSetCount, 0)

        context.onUpdate = {
            XCTAssertEqual(willSetCount, 1)
            XCTAssertEqual(didSetCount, 0)
        }

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertEqual(willSetCount, 1)
        XCTAssertEqual(didSetCount, 1)
    }
}
