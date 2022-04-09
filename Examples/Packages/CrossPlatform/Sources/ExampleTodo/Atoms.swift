import Atoms
import Foundation

struct TodosAtom: StateAtom, Hashable, KeepAlive {
    func defaultValue(context: Context) -> [Todo] {
        [
            Todo(id: UUID(), text: "Add a new todo", isCompleted: true),
            Todo(id: UUID(), text: "Complete a todo", isCompleted: false),
            Todo(id: UUID(), text: "Swipe to delete a todo", isCompleted: false),
        ]
    }
}

struct FilterAtom: StateAtom, Hashable {
    func defaultValue(context: Context) -> Filter {
        .all
    }
}

struct FilteredTodosAtom: ValueAtom, Hashable {
    func value(context: Context) -> [Todo] {
        let filter = context.watch(FilterAtom())
        let todos = context.watch(TodosAtom())

        switch filter {
        case .all:
            return todos

        case .completed:
            return todos.filter(\.isCompleted)

        case .uncompleted:
            return todos.filter { !$0.isCompleted }
        }
    }
}

struct StatsAtom: ValueAtom, Hashable {
    func value(context: Context) -> Stats {
        let todos = context.watch(TodosAtom())
        let total = todos.count
        let totalCompleted = todos.filter(\.isCompleted).count
        let totalUncompleted = todos.filter { !$0.isCompleted }.count
        let percentCompleted = total <= 0 ? 0 : (Double(totalCompleted) / Double(total))

        return Stats(
            total: total,
            totalCompleted: totalCompleted,
            totalUncompleted: totalUncompleted,
            percentCompleted: percentCompleted
        )
    }
}
