/// DFS topological sorting.
@MainActor
internal func topologicalSort(key: AtomKey, store: AtomStore) -> (
    edges: some Collection<Edge<AtomKey>>,
    subscriptions: some Collection<Edge<Subscription>>
) {
    var sorting = TopologicalSorting(key: key, store: store)
    sorting.sort()

    return (
        edges: sorting.reversedEdges.reversed(),
        subscriptions: sorting.reversedSubscriptions.reversed()
    )
}

internal struct Edge<To> {
    let from: AtomKey
    let to: To
}

@MainActor
private struct TopologicalSorting {
    private let key: AtomKey
    private let store: AtomStore
    private(set) var reversedEdges = ContiguousArray<Edge<AtomKey>>()
    private(set) var reversedSubscriptions = ContiguousArray<Edge<Subscription>>()
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
    enum Vertex: Hashable {
        case atom(key: AtomKey)
        case subscriber(key: SubscriberKey)
    }

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
            for (subscriberKey, subscription) in ContiguousArray(subscriptions) {
                guard !trace.contains(.subscriber(key: subscriberKey)) else {
                    continue
                }

                let edge = Edge(from: key, to: subscription)
                reversedSubscriptions.append(edge)
                trace.insert(.subscriber(key: subscriberKey))
            }
        }
    }

    mutating func traverse(key: AtomKey, from fromKey: AtomKey) {
        let edge = Edge(from: fromKey, to: key)

        trace.insert(.atom(key: key))
        traverse(key: key)
        reversedEdges.append(edge)
    }
}
