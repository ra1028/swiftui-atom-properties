/// DFS topological sorting.
@MainActor
internal func topologicalSort(key: AtomKey, store: AtomStore) -> (
    edges: some Collection<Edge<AtomKey>>,
    subscriptionEdges: some Collection<Edge<Subscription>>
) {
    var sorting = TopologicalSorting(key: key, store: store)
    sorting.sort()

    return (
        edges: sorting.edges.reversed(),
        subscriptionEdges: sorting.subscriptionEdges.reversed()
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
    private(set) var edges = ContiguousArray<Edge<AtomKey>>()
    private(set) var subscriptionEdges = ContiguousArray<Edge<Subscription>>()
    private var atomTrace = Set<AtomKey>()
    private var subscriberTrace = Set<SubscriberKey>()

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
                guard !atomTrace.contains(child) else {
                    continue
                }

                traverse(key: child, from: key)
            }
        }

        if let subscriptions = store.state.subscriptions[key] {
            for (subscriberKey, subscription) in ContiguousArray(subscriptions) {
                guard !subscriberTrace.contains(subscriberKey) else {
                    continue
                }

                let edge = Edge(from: key, to: subscription)
                subscriptionEdges.append(edge)
                subscriberTrace.insert(subscriberKey)
            }
        }
    }

    mutating func traverse(key: AtomKey, from fromKey: AtomKey) {
        let edge = Edge(from: fromKey, to: key)

        atomTrace.insert(key)
        traverse(key: key)
        edges.append(edge)
    }
}
