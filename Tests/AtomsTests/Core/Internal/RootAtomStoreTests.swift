import XCTest

@testable import Atoms

@MainActor
final class RootAtomStoreTests: XCTestCase {
    func testAtomStore() async {
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

        struct FlagAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Bool {
                false
            }
        }

        struct TestAtom: TaskAtom {
            let suspension: AsyncThrowingStreamPipe<Void>
            let callback: AsyncThrowingStreamPipe<Void>

            var key: UniqueKey {
                UniqueKey()
            }

            func value(context: Context) async -> Int {
                let flag = context.watch(FlagAtom())
                // - Dependencies (`|` means a suspention point)
                //   - Before: [A, B, C |]
                //   - After:  [A, D | B]
                if !flag {
                    let a = context.watch(AAtom())
                    let b = context.watch(BAtom())
                    let c = context.watch(CAtom())

                    callback.continuation.finish()
                    await suspension.stream.next()

                    return a + b + c
                }
                else {
                    let a = context.watch(AAtom())
                    let d = context.watch(DAtom())

                    callback.continuation.finish()
                    await suspension.stream.next()

                    let b = context.watch(BAtom())
                    print("B value:", b)
                    return a + d + b
                }
            }
        }

        let store = Store()
        let atomStore = RootAtomStore(store: store)
        let container = SubscriptionContainer()
        let suspension = AsyncThrowingStreamPipe<Void>()
        let callback = AsyncThrowingStreamPipe<Void>()
        let atom = TestAtom(suspension: suspension, callback: callback)
        let a = AAtom()
        let b = BAtom()
        let c = CAtom()
        let d = DAtom()
        let flag = FlagAtom()

        func watch() async -> Int {
            await atomStore.watch(atom, container: container.wrapper, notifyUpdate: {}).value
        }

        Task {
            await callback.stream.next()
            suspension.continuation.yield()
        }

        let valueBefore = await watch()

        XCTAssertEqual(valueBefore, 0)
        XCTAssertEqual(
            store.graph.dependencies(for: AtomKey(atom)),
            [AtomKey(flag), AtomKey(a), AtomKey(b), AtomKey(c)]
        )
        XCTAssertFalse(store.graph.hasChildren(for: AtomKey(d)))

        Task {
            await callback.stream.next()
            atomStore.set(1, for: b)
            suspension.continuation.yield()
        }

        suspension.reset()
        callback.reset()
        atomStore.set(true, for: flag)
        let valueAfter = await watch()

        XCTAssertEqual(valueAfter, 1)
        XCTAssertEqual(
            store.graph.dependencies(for: AtomKey(atom)),
            [AtomKey(flag), AtomKey(a), AtomKey(d), AtomKey(b)]
        )
        XCTAssertFalse(store.graph.hasChildren(for: AtomKey(c)))
    }
}

private extension AsyncSequence {
    func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return try? await iterator.next()
    }
}
