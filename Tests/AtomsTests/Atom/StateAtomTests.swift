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

    func testDependency() async {
        struct Dependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct Dependency2Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct Dependency3Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                context.watch(Dependency1Atom())
            }

            func willSet(newValue: Int, oldValue: Int, context: Context) {
                context.watch(Dependency2Atom())
            }

            func didSet(newValue: Int, oldValue: Int, context: Context) {
                context.watch(Dependency3Atom())
            }
        }

        let context = AtomTestContext()

        let value0 = context.watch(TestAtom())
        XCTAssertEqual(value0, 0)

        context[TestAtom()] = 1

        let value1 = context.watch(TestAtom())
        XCTAssertEqual(value1, 1)

        // Updated by the depenency update.

        Task {
            context[Dependency1Atom()] = 0
        }

        await context.waitUntilNextUpdate()

        let value2 = context.watch(TestAtom())
        XCTAssertEqual(value2, 0)

        // Updated by the depenency update that is started to watch by `willSet`.

        Task {
            context[Dependency2Atom()] = 100
        }

        context[TestAtom()] = 1
        await context.waitUntilNextUpdate()

        let value3 = context.watch(TestAtom())
        XCTAssertEqual(value3, 0)

        // Updated by the depenency update that is started to watch by `didSet`.

        Task {
            context[Dependency3Atom()] = 200
        }

        context[TestAtom()] = 1
        await context.waitUntilNextUpdate()

        let value4 = context.watch(TestAtom())
        XCTAssertEqual(value4, 0)
    }
}
