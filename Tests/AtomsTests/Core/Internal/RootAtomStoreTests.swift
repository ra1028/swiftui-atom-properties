import XCTest

@testable import Atoms

@MainActor
final class RootAtomStoreTests: XCTestCase {
    func testComplexDependencies() async throws {
        enum Phase {
            case first
            case second
            case third
        }

        struct PhaseAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Phase {
                .first
            }
        }

        struct AAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct BAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct CAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct DAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: TaskAtom {
            let pipe: AsyncThrowingStreamPipe<Void>

            var key: UniqueKey {
                UniqueKey()
            }

            func value(context: Context) async -> Int {
                let phase = context.watch(PhaseAtom())
                // - Dependencies (`|` means a suspention point)
                //   - first:  [A, B, C |]
                //   - second: [A, D | B]
                //   - third:  [B | C, D]
                switch phase {
                case .first:
                    let a = context.watch(AAtom())
                    let b = context.watch(BAtom())
                    let c = context.watch(CAtom())

                    context.addTermination {}

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    return a + b + c

                case .second:
                    let a = context.watch(AAtom())
                    let d = context.watch(DAtom())

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    context.addTermination {}

                    let b = context.watch(BAtom())
                    return a + d + b

                case .third:
                    let b = context.watch(BAtom())

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    let c = context.watch(CAtom())
                    let d = context.watch(DAtom())
                    return b + c + d
                }
            }
        }

        let store = Store()
        let atomStore = RootAtomStore(store: store)
        let container = SubscriptionContainer()
        let pipe = AsyncThrowingStreamPipe<Void>()
        let atom = TestAtom(pipe: pipe)
        let a = AAtom()
        let b = BAtom()
        let c = CAtom()
        let d = DAtom()
        let phase = PhaseAtom()

        func watch() async -> Int {
            await atomStore.watch(atom, container: container.wrapper, notifyUpdate: {}).value
        }

        do {
            // first

            Task {
                await pipe.stream.next()
                pipe.continuation.yield()
            }

            let firstValue = await watch()

            XCTAssertEqual(firstValue, 0)
            XCTAssertFalse(store.graph.hasChildren(for: AtomKey(d)))
            XCTAssertEqual(
                store.graph.dependencies(for: AtomKey(atom)),
                [AtomKey(phase), AtomKey(a), AtomKey(b), AtomKey(c)]
            )

            // Should be 1 (TestAtom's Task cancellation + first phase)
            XCTAssertEqual(store.state.terminations[AtomKey(atom)]?.count, 2)
        }

        do {
            // second

            Task {
                await pipe.stream.next()
                atomStore.set(1, for: b)
                pipe.continuation.yield()
            }

            atomStore.set(.second, for: phase)
            let secondValue = await watch()

            XCTAssertEqual(secondValue, 1)
            XCTAssertFalse(store.graph.hasChildren(for: AtomKey(c)))
            XCTAssertEqual(
                store.graph.dependencies(for: AtomKey(atom)),
                [AtomKey(phase), AtomKey(a), AtomKey(d), AtomKey(b)]
            )

            // Should be 1 (TestAtom's Task cancellation + second phase)
            XCTAssertEqual(store.state.terminations[AtomKey(atom)]?.count, 2)
        }

        do {
            // third

            Task {
                await pipe.stream.next()
                atomStore.set(2, for: d)
                pipe.continuation.yield()
            }

            atomStore.set(.third, for: phase)
            let thirdValue = await watch()

            XCTAssertEqual(thirdValue, 3)
            XCTAssertFalse(store.graph.hasChildren(for: AtomKey(a)))
            XCTAssertEqual(
                store.graph.dependencies(for: AtomKey(atom)),
                [AtomKey(phase), AtomKey(b), AtomKey(c), AtomKey(d)]
            )

            // Should be 1 (TestAtom's Task cancellation)
            XCTAssertEqual(store.state.terminations[AtomKey(atom)]?.count, 1)
        }
    }
}

private extension AsyncSequence {
    func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return try? await iterator.next()
    }
}
