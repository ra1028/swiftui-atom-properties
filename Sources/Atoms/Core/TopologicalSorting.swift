/// DFS topological sorting.
@MainActor
internal func topologicalSort(key: AtomKey, store: AtomStore) -> ReversedCollection<[Edge]> {
    var sorting = TopologicalSorting(key: key, store: store)
    sorting.sort()

    return sorting.edges.reversed()
}

internal enum Vertex: Hashable {
    case atom(key: AtomKey)
    case subscriber(key: SubscriberKey)
}

internal struct Edge: Hashable {
    let from: AtomKey
    let to: Vertex
}

@MainActor
private struct TopologicalSorting {
    private let key: AtomKey
    private let store: AtomStore
    private(set) var edges = [Edge]()
    private var trace = Set<Vertex>()

    init(key: AtomKey, store: AtomStore) {
        self.key = key
        self.store = store
    }

    mutating func sort() {
        traverse(key: key)
    }
}

private extension TopologicalSorting {
    mutating func traverse(key: AtomKey) {
        if let children = store.graph.children[key] {
            for child in ContiguousArray(children) {
                guard !trace.contains(.atom(key: child)) else {
                    continue
                }

                traverse(key: child, from: key)
            }
        }

        if let subscriptions = store.state.subscriptions[key] {
            for subscriberKey in ContiguousArray(subscriptions.keys) {
                guard !trace.contains(.subscriber(key: subscriberKey)) else {
                    continue
                }

                let edge = Edge(from: key, to: .subscriber(key: subscriberKey))
                edges.append(edge)
                trace.insert(.subscriber(key: subscriberKey))
            }
        }
    }

    mutating func traverse(key: AtomKey, from fromKey: AtomKey) {
        let edge = Edge(from: fromKey, to: .atom(key: key))

        trace.insert(.atom(key: key))
        traverse(key: key)
        edges.append(edge)
    }
}
