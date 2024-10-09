import XCTest

@testable import Atoms

final class AsyncPhaseAtomTests: XCTestCase {
    @MainActor
    func test() async {
        var result = Result<Int, URLError>.success(0)
        let atom = TestAsyncPhaseAtom { result }
        let context = AtomTestContext()

        do {
            // Initial value
            let phase = context.watch(atom)
            XCTAssertTrue(phase.isSuspending)
        }

        do {
            // Value
            await context.wait(for: atom, until: \.isSuccess)
            let phase = context.watch(atom)
            XCTAssertEqual(phase.value, 0)
        }

        do {
            // Failure
            context.unwatch(atom)
            result = .failure(URLError(.badURL))
            context.watch(atom)
            await context.wait(for: atom, until: \.isFailure)

            let phase = context.watch(atom)

            #if compiler(>=6)
                XCTAssertEqual(phase.error, URLError(.badURL))
            #else
                XCTAssertEqual(phase.error as? URLError, URLError(.badURL))
            #endif
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in .success(200) }

            let phase = context.watch(atom)
            XCTAssertEqual(phase.value, 200)
        }
    }

    @MainActor
    func testRefresh() async {
        let atom = TestAsyncPhaseAtom<Int, any Error> { .success(0) }
        let context = AtomTestContext()

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.watch(atom)

            let phase0 = await context.refresh(atom)
            XCTAssertEqual(phase0.value, 0)
            XCTAssertEqual(updateCount, 1)
        }

        do {
            // Cancellation
            let refreshTask = Task {
                await context.refresh(atom)
            }

            Task {
                refreshTask.cancel()
            }

            let phase = await refreshTask.value
            XCTAssertTrue(phase.isSuspending)
        }

        do {
            // Override
            context.override(atom) { _ in .success(300) }

            let phase = await context.refresh(atom)
            XCTAssertEqual(phase.value, 300)
        }
    }

    @MainActor
    func testReleaseDependencies() async {
        struct DependencyAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: AsyncPhaseAtom, Hashable {
            func value(context: Context) async throws -> Int {
                let dependency = context.watch(DependencyAtom())
                return dependency
            }
        }

        let atom = TestAtom()
        let context = AtomTestContext()

        context.watch(atom)
        await context.wait(for: atom, until: \.isSuccess)

        let phase0 = context.watch(atom)
        XCTAssertEqual(phase0.value, 0)

        context[DependencyAtom()] = 100
        await context.wait(for: atom, until: \.isSuccess)

        let phase1 = context.watch(atom)
        // Dependencies should not be released until task value is returned.
        XCTAssertEqual(phase1.value, 100)

        context.unwatch(atom)

        let dependencyValue = context.read(DependencyAtom())
        XCTAssertEqual(dependencyValue, 0)
    }

    @MainActor
    func testEffect() {
        let effect = TestEffect()
        let atom = TestAsyncPhaseAtom<Int, any Error>(effect: effect) { .success(0) }
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 0)
        XCTAssertEqual(effect.releasedCount, 0)

        context.reset(atom)
        context.reset(atom)
        context.reset(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 0)

        context.unwatch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 1)
    }
}
