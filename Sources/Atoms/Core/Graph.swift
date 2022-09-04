internal struct Graph: Equatable {
    var dependencies = [AtomKey: Set<AtomKey>]()
    var children = [AtomKey: Set<AtomKey>]()
}
