import Combine
import Testing

@testable import Atoms

struct AtomTestContextTests {
    @MainActor
    @Test
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

        #expect(!(isCalled))

        context.watch(atom)

        #expect(!(isCalled))

        context.reset(atom)

        #expect(isCalled)
    }

    @MainActor
    @Test
    func testWaitForUpdate() async {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        Task {
            context[atom] = 1
        }

        let didUpdate0 = await context.waitForUpdate()

        #expect(didUpdate0)

        let didUpdate1 = await context.waitForUpdate(timeout: 0.1)

        #expect(!(didUpdate1))
    }

    @MainActor
    @Test
    func testWaitFor() async {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        // Already satisfied, so no update is awaited.
        let didUpdate0 = await context.wait(for: atom) {
            $0 == 0
        }

        #expect(!didUpdate0)

        // The update is delayed so it lands after the wait starts observing, and is
        // scheduled right before the wait so its timing is independent of the test's start.
        Task {
            try? await Task.sleep(seconds: 0.1)
            context[atom] = 3
        }

        let didUpdate1 = await context.wait(for: atom) {
            $0 == 3
        }

        #expect(didUpdate1)

        // Never satisfied, so it returns after the timeout elapses.
        let didUpdate2 = await context.wait(for: atom, timeout: 0.1) {
            $0 == 100
        }

        #expect(!didUpdate2)

        // Already satisfied, so no update is awaited.
        let didUpdate3 = await context.wait(for: atom) {
            $0 == 3
        }

        #expect(!didUpdate3)
    }

    @MainActor
    @Test
    func testWaitForUpdateWithinTimeout() async throws {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        Task {
            context[atom] = 1
        }

        // Returns normally once the update is observed. The timeout is generous so a
        // slow, contended CI host doesn't cause a spurious failure; it only fails if the
        // update never arrives.
        try await context.waitForUpdate(within: 10)

        // Throws when no update happens within the timeout.
        let error = await #expect(throws: AtomTestContextTimeoutError.self) {
            try await context.waitForUpdate(within: 0.1)
        }

        #expect(error?.timeout == 0.1)
    }

    @MainActor
    @Test
    func testWaitForWithinTimeout() async throws {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.watch(atom)

        // Returns immediately when the predicate is already satisfied.
        try await context.wait(for: atom, within: 1) {
            $0 == 0
        }

        Task {
            context[atom] = 1
        }

        // Returns normally when the atom reaches the expected state within the timeout.
        try await context.wait(for: atom, within: 1) {
            $0 == 1
        }

        // Throws when the atom does not reach the expected state within the timeout.
        let error = await #expect(throws: AtomTestContextTimeoutError.self) {
            try await context.wait(for: atom, within: 0.1) {
                $0 == 100
            }
        }

        #expect(error?.timeout == 0.1)
    }

    @MainActor
    @Test
    func testOverride() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestStateAtom(defaultValue: 200)
        let context = AtomTestContext()

        #expect(context.read(atom0) == 100)
        #expect(context.read(atom1) == 200)

        context.override(atom0) { _ in 300 }

        #expect(context.read(atom0) == 300)
        #expect(context.read(atom1) == 200)
    }

    @MainActor
    @Test
    func testOverrideWithType() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestValueAtom(value: 200)
        let context = AtomTestContext()

        #expect(context.read(atom0) == 100)
        #expect(context.read(atom1) == 200)

        context.override(TestValueAtom.self) { _ in 300 }

        #expect(context.read(atom0) == 300)
        #expect(context.read(atom1) == 300)
    }

    @MainActor
    @Test
    func testTerminate() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()

        #expect(context.watch(atom) == 100)

        context[atom] = 200

        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.unwatch(atom)

        #expect(context.read(atom) == 100)
        #expect(updateCount == 0)
    }

    @MainActor
    @Test
    func testSubscript() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        context.watch(atom)

        #expect(context[atom] == 100)
        #expect(updateCount == 0)

        context[atom] = 200

        #expect(context[atom] == 200)
        #expect(updateCount == 1)
    }

    @MainActor
    @Test
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let context = AtomTestContext()

        #expect(context.read(atom) == 100)
    }

    @MainActor
    @Test
    func testWatch() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        #expect(context.watch(atom) == 100)
        #expect(updateCount == 0)

        context[atom] = 200

        #expect(context.watch(atom) == 200)
        #expect(updateCount == 1)
    }

    @MainActor
    @Test
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let context = AtomTestContext()
        var updateCount = 0

        context.onUpdate = {
            updateCount += 1
        }

        #expect(context.watch(atom).isSuspending)

        let value = await context.refresh(atom).value

        #expect(value == 100)
        #expect(context.watch(atom).value == 100)
        #expect(updateCount == 1)
    }

    @MainActor
    @Test
    func testReset() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        #expect(context.watch(atom) == 0)

        context[atom] = 100

        #expect(context.read(atom) == 100)

        context.reset(atom)

        #expect(context.read(atom) == 0)
    }

}
