/// DFS topological sorting.
@MainActor
internal func topologicalSort(key: AtomKey, store: AtomStore) -> (
    edges: ReversedCollection<[Edge]>,
    omitted: [Vertex: Set<AtomKey>]
) {
    var sorting = TopologicalSorting(key: key, store: store)
    sorting.sort()

    return (
        edges: sorting.edges.reversed(),
        omitted: sorting.omitted
    )
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
    private var trace = Set<Vertex>()
    private(set) var edges = [Edge]()
    private(set) var omitted = [Vertex: Set<AtomKey>]()

    init(key: AtomKey, store: AtomStore) {
        self.key = key
        self.store = store
    }

    mutating func sort() {
        traverse(key: key, isSkipping: false)
    }
}

private extension TopologicalSorting {
    mutating func traverse(key: AtomKey, isSkipping: Bool) {
        if let children = store.graph.children[key] {
            for child in ContiguousArray(children) {
                let isSkipping = isSkipping || trace.contains(.atom(key: child))
                traverse(key: child, from: key, isSkipping: isSkipping)
            }
        }

        if let subscriptions = store.state.subscriptions[key] {
            for subscriberKey in ContiguousArray(subscriptions.keys) {
                let vertex = Vertex.subscriber(key: subscriberKey)

                if isSkipping || trace.contains(.subscriber(key: subscriberKey)) {
                    omitted[vertex, default: []].insert(key)
                }
                else {
                    let edge = Edge(from: key, to: vertex)
                    edges.append(edge)
                }

                trace.insert(.subscriber(key: subscriberKey))
            }
        }
    }

    mutating func traverse(key: AtomKey, from fromKey: AtomKey, isSkipping: Bool) {
        trace.insert(.atom(key: key))
        traverse(key: key, isSkipping: isSkipping)

        let vertex = Vertex.atom(key: key)

        if isSkipping {
            omitted[vertex, default: []].insert(fromKey)
        }
        else {
            let edge = Edge(from: fromKey, to: vertex)
            edges.append(edge)
        }
    }
}
