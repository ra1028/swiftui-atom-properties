import Testing

@testable import Atoms

struct DebounceModifierTests {
    @MainActor
    @Test
    func testDebounce() async {
        let atom = TestStateAtom(defaultValue: 0)
        let debounced = atom.debounce(for: 0.05)
        let context = AtomTestContext()

        // The initial value is delivered immediately.
        #expect(context.watch(debounced) == 0)

        // While the value keeps changing, the delivered value stays the previous one.
        context[atom] = 1
        context[atom] = 2
        context[atom] = 3

        #expect(context.watch(debounced) == 0)

        // Once the value settles, the latest value is delivered.
        await context.wait(for: debounced, until: { $0 == 3 })

        #expect(context.watch(debounced) == 3)
    }

    @MainActor
    @Test
    func testDebounceDeliversOnlyTheLatestValue() async {
        let atom = TestStateAtom(defaultValue: 0)
        let debounced = atom.debounce(for: 0.05)
        let context = AtomTestContext()
        var delivered = [Int]()

        context.onUpdate = {
            delivered.append(context.read(debounced))
        }

        #expect(context.watch(debounced) == 0)

        context[atom] = 1
        context[atom] = 2
        context[atom] = 3

        await context.wait(for: debounced, until: { $0 == 3 })

        // Superseded values are never delivered; only the latest settled value is.
        #expect(!delivered.contains(1))
        #expect(!delivered.contains(2))
        #expect(delivered.last == 3)
    }

    @MainActor
    @Test
    func testResetDuringDebounce() async {
        let atom = TestStateAtom(defaultValue: 0)
        let debounced = atom.debounce(for: 0.05)
        let context = AtomTestContext()

        context.watch(atom)
        #expect(context.watch(debounced) == 0)

        // Reset while a delivery is pending; this must cancel it, re-debounce cleanly,
        // and not deliver a stale value.
        context[atom] = 1
        context.reset(debounced)

        await context.wait(for: debounced, until: { $0 == 1 })

        #expect(context.watch(debounced) == 1)
    }

    @MainActor
    @Test
    func testDebounceWithChangesSkipsRedundantUpdates() async {
        let atom = TestStateAtom(defaultValue: 0)
        let debounced = atom.debounce(for: 0.05).changes
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        // Composing with `changes` suppresses the redundant deliveries during the debounce.
        #expect(context.watch(debounced) == 0)
        #expect(updatedCount == 0)

        context[atom] = 1
        context[atom] = 2
        context[atom] = 3

        #expect(updatedCount == 0)

        await context.wait(for: debounced, until: { $0 == 3 })

        #expect(context.watch(debounced) == 3)
        #expect(updatedCount == 1)
    }

    @MainActor
    @Test
    func testUnwatchDuringDebounceCancelsDelivery() async {
        let atom = TestStateAtom(defaultValue: 0)
        let debounced = atom.debounce(for: 0.05)
        let context = AtomTestContext()

        // Keep the base alive so releasing the debounced atom doesn't reset it.
        context.watch(atom)
        #expect(context.watch(debounced) == 0)

        // Schedule a pending delivery, then release the debounced atom before it fires.
        context[atom] = 1
        context.unwatch(debounced)

        // Give the cancelled delivery time to (not) fire; this must not crash or leave
        // stale state behind.
        try? await Task.sleep(seconds: 0.15)

        // Re-watching re-initializes cleanly and delivers the current base value immediately.
        #expect(context.watch(debounced) == 1)
    }

    @MainActor
    @Test
    func testDebounceWithOptionalValue() async {
        let atom = TestStateAtom<Int?>(defaultValue: nil)
        let debounced = atom.debounce(for: 0.05)
        let context = AtomTestContext()

        // The initial nil is delivered immediately.
        #expect(context.watch(debounced) == nil)

        context[atom] = 5
        #expect(context.watch(debounced) == nil)
        await context.wait(for: debounced, until: { $0 == 5 })
        #expect(context.watch(debounced) == 5)

        // Settling back to nil must be debounced and delivered, not treated as "no value".
        context[atom] = nil
        #expect(context.watch(debounced) == 5)
        await context.wait(for: debounced, until: { $0 == nil })
        #expect(context.watch(debounced) == nil)

        // A value following the nil must still be debounced, proving the settled nil was
        // not mistaken for an uninitialized state.
        context[atom] = 9
        #expect(context.watch(debounced) == nil)
        await context.wait(for: debounced, until: { $0 == 9 })
        #expect(context.watch(debounced) == 9)
    }

    @MainActor
    @Test
    func testDebounceDeliversSettledValueToDependent() async {
        struct BaseAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct DependentAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(BaseAtom().debounce(for: 0.05)) + 1
            }
        }

        let context = AtomTestContext()

        #expect(context.watch(DependentAtom()) == 1)

        // The dependent keeps observing the previous settled value during the debounce.
        context[BaseAtom()] = 10
        context[BaseAtom()] = 20

        #expect(context.watch(DependentAtom()) == 1)

        // Once settled, the delivery propagates to the dependent.
        await context.wait(for: DependentAtom(), until: { $0 == 21 })

        #expect(context.watch(DependentAtom()) == 21)
    }

    @MainActor
    @Test
    func testDebounceWithZeroDuration() async {
        let atom = TestStateAtom(defaultValue: 0)
        let debounced = atom.debounce(for: 0)
        let context = AtomTestContext()

        #expect(context.watch(debounced) == 0)

        context[atom] = 1
        await context.wait(for: debounced, until: { $0 == 1 })

        #expect(context.watch(debounced) == 1)
    }

    @Test
    func testKey() {
        let modifier0 = DebounceModifier<Int>(duration: 0.1)
        let modifier1 = DebounceModifier<Int>(duration: 0.2)

        #expect(modifier0.key == modifier0.key)
        #expect(modifier0.key.hashValue == modifier0.key.hashValue)
        #expect(modifier0.key != modifier1.key)
        #expect(modifier0.key.hashValue != modifier1.key.hashValue)
    }
}
