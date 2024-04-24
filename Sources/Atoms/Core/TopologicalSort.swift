internal enum Vertex: Hashable {
    case atom(key: AtomKey)
    case subscriber(key: SubscriberKey)
}

internal struct Edge: Hashable {
    let from: AtomKey
    let to: Vertex
}

/// DFS topological sorting.
@MainActor
internal func topologicalSort(key: AtomKey, store: AtomStore) -> (
    edges: ReversedCollection<[Edge]>,
    redundant: [Vertex: Set<AtomKey>]  // key = vertex, value = dependencies
) {
    var trace = Set<Vertex>()
    var edges = [Edge]()
    var redundant = [Vertex: Set<AtomKey>]()

    func traverse(key: AtomKey, isRedundant: Bool) {
        if let children = store.graph.children[key] {
            for child in ContiguousArray(children) {
                // Do not stop traversing downstream even when edges are already traced
                // to analyze the redundant edges later.
                let isRedundant = isRedundant || trace.contains(.atom(key: child))
                traverse(key: child, from: key, isRedundant: isRedundant)
            }
        }

        if let subscriptions = store.state.subscriptions[key] {
            for subscriberKey in ContiguousArray(subscriptions.keys) {
                let vertex = Vertex.subscriber(key: subscriberKey)

                if isRedundant || trace.contains(.subscriber(key: subscriberKey)) {
                    redundant[vertex, default: []].insert(key)
                }
                else {
                    let edge = Edge(from: key, to: vertex)
                    edges.append(edge)
                }

                trace.insert(.subscriber(key: subscriberKey))
            }
        }
    }

    func traverse(key: AtomKey, from fromKey: AtomKey, isRedundant: Bool) {
        trace.insert(.atom(key: key))
        traverse(key: key, isRedundant: isRedundant)

        let vertex = Vertex.atom(key: key)

        if isRedundant {
            redundant[vertex, default: []].insert(fromKey)
        }
        else {
            let edge = Edge(from: fromKey, to: vertex)
            edges.append(edge)
        }
    }

    traverse(key: key, isRedundant: false)

    return (
        edges: edges.reversed(),
        redundant: redundant
    )
}
