import XCTest

@testable import Atoms

@MainActor
final class StateAtomTests: XCTestCase {
    func testValue() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        do {
            // Value
            XCTAssertEqual(context.watch(atom), 0)
        }

        do {
            // Override
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
        let atom = TestStateAtom(
            defaultValue: 0,
            willSet: { newValue, oldValue in
                willSetNewValues.append(newValue)
                willSetOldValues.append(oldValue)
            },
            didSet: { newValue, oldValue in
                didSetNewValues.append(newValue)
                didSetOldValues.append(oldValue)
            }
        )
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
        let atom = TestStateAtom(
            defaultValue: 0,
            willSet: { _, _ in willSetCount += 1 },
            didSet: { _, _ in didSetCount += 1 }
        )
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
