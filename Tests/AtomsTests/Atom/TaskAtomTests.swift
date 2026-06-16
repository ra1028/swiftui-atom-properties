import Testing

@testable import Atoms

struct TaskAtomTests {
    @MainActor
    @Test
    func testValue() async {
        let atom = TestTaskAtom { 0 }
        let context = AtomTestContext()

        do {
            // Initial value
            let value = await context.watch(atom).value
            #expect(value == 0)
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

            let value1 = await context.watch(atom).value
            #expect(value1 == 200)
        }

        do {
            // Override termination
            context.override(atom) { _ in Task { 300 } }

            let task = context.watch(atom)
            context.unwatch(atom)

            #expect(task.isCancelled)
        }
    }

    @MainActor
    @Test
    func testRefresh() async {
        var value = 0
        let atom = TestTaskAtom<Int> { value }
        let context = AtomTestContext()

        do {
            // Refresh
            var updateCount = 0
            context.onUpdate = { updateCount += 1 }
            context.watch(atom)

            let value0 = await context.refresh(atom).value
            #expect(value0 == 0)
            #expect(updateCount == 1)

            value = 1

            let value1 = await context.refresh(atom).value
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

            let value = await context.refresh(atom).value
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
    func testReleaseDependencies() async {
        struct DependencyAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: TaskAtom, Hashable {
            func value(context: Context) async -> Int {
                let dependency = context.watch(DependencyAtom())
                return dependency
            }
        }

        let context = AtomTestContext()

        let value0 = await context.watch(TestAtom()).value

        #expect(value0 == 0)

        context[DependencyAtom()] = 100

        let value1 = await context.watch(TestAtom()).value

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
        let atom = TestTaskAtom(effect: effect) { 0 }
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
