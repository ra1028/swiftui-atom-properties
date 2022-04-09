import Atoms
import SwiftUI

struct TodoStats: View {
    @Watch(StatsAtom())
    var stats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            stat("Total", "\(stats.total)")
            stat("Completed", "\(stats.totalCompleted)")
            stat("Uncompleted", "\(stats.totalUncompleted)")
            stat("Percent Completed", "\(Int(stats.percentCompleted * 100))%")
        }
        .padding(.vertical)
    }

    func stat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title) + Text(":")
            Spacer()
            Text(value)
        }
    }
}

struct TodoFilters: View {
    @WatchState(FilterAtom())
    var filter

    var body: some View {
        Picker("Filter", selection: $filter) {
            ForEach(Filter.allCases, id: \.self) { filter in
                switch filter {
                case .all:
                    Text("All")

                case .completed:
                    Text("Completed")

                case .uncompleted:
                    Text("Uncompleted")
                }
            }
        }
        .padding(.vertical)

        #if !os(watchOS)
            .pickerStyle(.segmented)
        #endif
    }
}

struct TodoCreator: View {
    @WatchState(TodosAtom())
    var todos

    @State
    var text = ""

    var body: some View {
        HStack {
            TextField("Enter your todo", text: $text)

            #if os(iOS) || os(macOS)
                .textFieldStyle(.roundedBorder)
            #endif

            Button("Add", action: addTodo)
                .disabled(text.isEmpty)
        }
        .padding(.vertical)
    }

    func addTodo() {
        let todo = Todo(id: UUID(), text: text, isCompleted: false)
        todos.append(todo)
        text = ""
    }
}

struct TodoItem: View {
    @WatchState(TodosAtom())
    var allTodos

    @State
    var text: String

    @State
    var isCompleted: Bool

    let todo: Todo

    init(todo: Todo) {
        self.todo = todo
        self._text = State(initialValue: todo.text)
        self._isCompleted = State(initialValue: todo.isCompleted)
    }

    var index: Int {
        allTodos.firstIndex { $0.id == todo.id }!
    }

    var body: some View {
        Toggle(isOn: $isCompleted) {
            TextField("", text: $text) {
                allTodos[index].text = text
            }

            #if os(iOS) || os(macOS)
                .textFieldStyle(.roundedBorder)
            #endif
        }
        .padding(.vertical, 4)
        .onChange(of: isCompleted) { isCompleted in
            allTodos[index].isCompleted = isCompleted
        }
    }
}
