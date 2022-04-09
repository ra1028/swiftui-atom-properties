import Atoms
import SwiftUI

struct TodoListScreen: View {
    @Watch(FilteredTodosAtom())
    var filteredTodos

    @ViewContext
    var context

    var body: some View {
        List {
            Section {
                TodoStats()
                TodoCreator()
            }

            Section {
                TodoFilters()

                ForEach(filteredTodos, id: \.id) { todo in
                    TodoItem(todo: todo)
                }
                .onDelete { indexSet in
                    let todos = TodosAtom()
                    let indices = indexSet.compactMap { index in
                        context[todos].firstIndex(of: filteredTodos[index])
                    }
                    context[todos].remove(atOffsets: IndexSet(indices))
                }
            }
        }
        .navigationTitle("Todo")

        #if os(iOS)
            .listStyle(.insetGrouped)
                .buttonStyle(.borderless)
        #elseif !os(tvOS)
            .buttonStyle(.borderless)
        #endif
    }
}

struct TodoListScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            TodoListScreen()
        }
    }
}
