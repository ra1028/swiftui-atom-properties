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
    redundants: [Vertex: Set<AtomKey>]  // key = vertex, value = dependencies
) {
    var trace = Set<Vertex>()
    var edges = [Edge]()
    var redundants = [Vertex: Set<AtomKey>]()

    func traverse(key: AtomKey, isRedundant: Bool) {
        if let children = store.graph.children[key] {
            for child in ContiguousArray(children) {
                traverse(key: child, from: key, isRedundant: isRedundant)
            }
        }

        if let subscriptions = store.state.subscriptions[key] {
            for subscriberKey in ContiguousArray(subscriptions.keys) {
                traverse(key: subscriberKey, from: key, isRedundant: isRedundant)
            }
        }
    }

    func traverse(key: AtomKey, from fromKey: AtomKey, isRedundant: Bool) {
        let vertex = Vertex.atom(key: key)
        let isRedundant = isRedundant || trace.contains(vertex)

        trace.insert(vertex)

        // Do not stop traversing downstream even when edges are already traced
        // to analyze the redundant edges later.
        traverse(key: key, isRedundant: isRedundant)

        if isRedundant {
            redundants[vertex, default: []].insert(fromKey)
        }
        else {
            let edge = Edge(from: fromKey, to: vertex)
            edges.append(edge)
        }
    }

    func traverse(key: SubscriberKey, from fromKey: AtomKey, isRedundant: Bool) {
        let vertex = Vertex.subscriber(key: key)
        let isRedundant = isRedundant || trace.contains(vertex)

        trace.insert(vertex)

        if isRedundant {
            redundants[vertex, default: []].insert(fromKey)
        }
        else {
            let edge = Edge(from: fromKey, to: vertex)
            edges.append(edge)
        }
    }

    traverse(key: key, isRedundant: false)

    return (edges: edges.reversed(), redundants: redundants)
}
