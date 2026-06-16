import Atoms
import Foundation
import Testing

@testable import ExampleTodo

struct ExampleTodoTests {
    let completedTodos = [
        Todo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            text: "Test 0",
            isCompleted: true
        )
    ]

    let uncompleteTodos = [
        Todo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            text: "Test 1",
            isCompleted: false
        ),
        Todo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            text: "Test 2",
            isCompleted: false
        ),
    ]

    var allTodos: [Todo] {
        completedTodos + uncompleteTodos
    }

    @MainActor
    @Test
    func testFilteredTodosAtom() {
        let context = AtomTestContext()
        let atom = FilteredTodosAtom()

        context.watch(atom)

        context[TodosAtom()] = []

        #expect(context.watch(atom) == [])

        context[TodosAtom()] = allTodos

        #expect(context.watch(atom) == allTodos)

        context[FilterAtom()] = .completed

        #expect(context.watch(atom) == completedTodos)

        context[FilterAtom()] = .uncompleted

        #expect(context.watch(atom) == uncompleteTodos)
    }

    @MainActor
    @Test
    func testStatsAtom() {
        let context = AtomTestContext()
        let atom = StatsAtom()

        context.watch(atom)

        context[TodosAtom()] = []

        #expect(
            context.watch(atom)
                == Stats(
                    total: 0,
                    totalCompleted: 0,
                    totalUncompleted: 0,
                    percentCompleted: 0
                )
        )

        context[TodosAtom()] = completedTodos

        #expect(
            context.watch(atom)
                == Stats(
                    total: 1,
                    totalCompleted: 1,
                    totalUncompleted: 0,
                    percentCompleted: 1
                )
        )

        context[TodosAtom()] = uncompleteTodos

        #expect(
            context.watch(atom)
                == Stats(
                    total: 2,
                    totalCompleted: 0,
                    totalUncompleted: 2,
                    percentCompleted: 0
                )
        )

        context[TodosAtom()] = allTodos

        #expect(
            context.watch(atom)
                == Stats(
                    total: 3,
                    totalCompleted: 1,
                    totalUncompleted: 2,
                    percentCompleted: 1 / 3
                )
        )
    }
}
