import Foundation
import Testing

@testable import Atoms

struct ThrowingTaskAtomTests {
    @MainActor
    @Test
    func test() async throws {
        var result = Result<Int, any Error>.success(0)
        let atom = TestThrowingTaskAtom { result }
        let context = AtomTestContext()

        do {
            // Initial value
            let value = try await context.watch(atom).value
            #expect(value == 0)
        }

        do {
            // Error
            do {
                context.unwatch(atom)
                result = .failure(URLError(.badURL))

                _ = try await context.watch(atom).value

                Issue.record("Accessing to value should throw an error")
            }
            catch {
                #expect(error as? URLError == URLError(.badURL))
            }
        }

        do {
            // Termination
            let task = context.watch(atom)
            context.unwatch(atom)

            #expect(task.isCancelled)
        }

        do {
            // Override
            context.override(atom) { _ in Task { 200 } }

            let value = try await context.watch(atom).value
            #expect(value == 200)

            // Override termination

            context.override(atom) { _ in Task { 300 } }

            let task = context.watch(atom)
            context.unwatch(atom)

            #expect(task.isCancelled)
        }
    }

    @MainActor
    @Test
    func testRefresh() async throws {
        var result = Result<Int, any Error>.success(0)
        let atom = TestThrowingTaskAtom { result }
        let context = AtomTestContext()

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.watch(atom)

            let value0 = try await context.refresh(atom).value
            #expect(value0 == 0)
            #expect(updateCount == 1)

            result = .success(1)

            let value1 = try await context.refresh(atom).value
            #expect(value1 == 1)
            #expect(updateCount == 2)
        }

        do {
            // Cancellation
            let refreshTask = Task {
                await context.refresh(atom)
            }

            refreshTask.cancel()

            let task = await refreshTask.value
            #expect(task.isCancelled)
        }

        do {
            // Override
            context.override(atom) { _ in Task { 300 } }

            let value = try await context.refresh(atom).value
            #expect(value == 300)
        }

        do {
            // Override cancellation
            context.override(atom) { _ in Task { 400 } }

            let refreshTask = Task {
                await context.refresh(atom)
            }

            refreshTask.cancel()

            let task = await refreshTask.value
            #expect(task.isCancelled)
        }
    }

    @MainActor
    @Test
    func testReleaseDependencies() async throws {
        struct DependencyAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: ThrowingTaskAtom, Hashable {
            func value(context: Context) async throws -> Int {
                let dependency = context.watch(DependencyAtom())
                return dependency
            }
        }

        let context = AtomTestContext()

        let value0 = try await context.watch(TestAtom()).value

        #expect(value0 == 0)

        context[DependencyAtom()] = 100

        let value1 = try await context.watch(TestAtom()).value

        // Dependencies should not be released until task value is returned.
        #expect(value1 == 100)

        context.unwatch(TestAtom())

        let dependencyValue = context.read(DependencyAtom())

        #expect(dependencyValue == 0)
    }

    @MainActor
    @Test
    func testEffect() {
        let effect = TestEffect()
        let atom = TestThrowingTaskAtom(effect: effect) { .success(0) }
        let context = AtomTestContext()

        context.watch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        context.reset(atom)
        context.reset(atom)
        context.reset(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 0)

        context.unwatch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 1)
    }
}
