import Combine
import XCTest

@testable import Atoms

final class AtomTestContextTests: XCTestCase {
    @MainActor
    func testOnUpdate() {
        let atom = TestValueAtom(value: 100)
        let context = AtomTestContext()
        var isCalled = false

        context.onUpdate = {
            isCalled = false
        }

        // Override.
        context.onUpdate = {
            isCalled = true
        }

        context.reset(atom)

        XCTAssertFalse(isCalled)

        context.watch(atom)

        XCTAssertFalse(isCalled)

        context.reset(atom)

        XCTAssertTrue(isCalled)
    }

    @MainActor
    func testWaitForUpdate() async {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        Task {
            context[atom] = 1
        }

        let didUpdate0 = await context.waitForUpdate()

        XCTAssertTrue(didUpdate0)

        let didUpdate1 = await context.waitForUpdate(timeout: 0.1)

        XCTAssertFalse(didUpdate1)
    }

    @MainActor
    func testWaitFor() async {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        for i in 1...3 {
            Task {
                try? await Task.sleep(seconds: Double(i) / 100)
                context[atom] += 1
            }
        }

        let didUpdate0 = await context.wait(for: atom) {
            $0 == 0
        }

        XCTAssertFalse(didUpdate0)

        let didUpdate1 = await context.wait(for: atom) {
            $0 == 3
        }

        XCTAssertTrue(didUpdate1)

        let didUpdate2 = await context.wait(for: atom, timeout: 0.1) {
            $0 == 100
        }

        XCTAssertFalse(didUpdate2)

        let didUpdate3 = await context.wait(for: atom) {
            $0 == 3
        }

        XCTAssertFalse(didUpdate3)
    }

    @MainActor
    func testOverride() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestStateAtom(defaultValue: 200)
        let context = AtomTestContext()

        XCTAssertEqual(context.read(atom0), 100)
        XCTAssertEqual(context.read(atom1), 200)

        context.override(atom0) { _ in 300 }

        XCTAssertEqual(context.read(atom0), 300)
        XCTAssertEqual(context.read(atom1), 200)
    }

    @MainActor
    func testOverrideWithType() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestValueAtom(value: 200)
        let context = AtomTestContext()

        XCTAssertEqual(context.read(atom0), 100)
        XCTAssertEqual(context.read(atom1), 200)

        context.override(TestValueAtom.self) { _ in 300 }

        XCTAssertEqual(context.read(atom0), 300)
        XCTAssertEqual(context.read(atom1), 300)
    }

    @MainActor
    func testTerminate() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom), 100)

        context[atom] = 200

        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.unwatch(atom)

        XCTAssertEqual(context.read(atom), 100)
        XCTAssertEqual(updateCount, 0)
    }

    @MainActor
    func testSubscript() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.watch(atom)

        XCTAssertEqual(context[atom], 100)
        XCTAssertEqual(updateCount, 0)

        context[atom] = 200

        XCTAssertEqual(context[atom], 200)
        XCTAssertEqual(updateCount, 1)
    }

    @MainActor
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let context = AtomTestContext()

        XCTAssertEqual(context.read(atom), 100)
    }

    @MainActor
    func testWatch() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertEqual(updateCount, 0)

        context[atom] = 200

        XCTAssertEqual(context.watch(atom), 200)
        XCTAssertEqual(updateCount, 1)
    }

    @MainActor
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertTrue(context.watch(atom).isSuspending)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
        XCTAssertEqual(context.watch(atom).value, 100)
        XCTAssertEqual(updateCount, 1)
    }

    @MainActor
    func testCustomRefresh() async {
        let atom = TestCustomRefreshableAtom {
            Just(100)
        } refresh: {
            .success(200)
        }
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertTrue(context.watch(atom).isSuspending)

        await context.waitForUpdate()

        XCTAssertEqual(context.watch(atom).value, 100)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 200)
        XCTAssertEqual(context.watch(atom).value, 200)
        XCTAssertEqual(updateCount, 2)
    }

    @MainActor
    func testReset() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context.read(atom), 100)

        context.reset(atom)

        XCTAssertEqual(context.read(atom), 0)
    }
}
