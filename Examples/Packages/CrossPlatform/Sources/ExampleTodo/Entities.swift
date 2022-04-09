import Foundation

struct Todo: Hashable {
    var id: UUID
    var text: String
    var isCompleted: Bool
}

enum Filter: CaseIterable, Hashable {
    case all
    case completed
    case uncompleted
}

struct Stats: Equatable {
    let total: Int
    let totalCompleted: Int
    let totalUncompleted: Int
    let percentCompleted: Double
}
