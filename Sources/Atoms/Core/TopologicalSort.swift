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
    edges: ReversedCollection<ContiguousArray<Edge>>,
    redundants: [Vertex: ContiguousArray<AtomKey>]  // key = vertex, value = dependencies
) {
    var trace = Set<Vertex>()
    var edges = ContiguousArray<Edge>()
    var redundants = [Vertex: ContiguousArray<AtomKey>]()

    func traverse(key: AtomKey, isRedundant: Bool) {
        if let children = store.graph.children[key] {
            for child in children {
                traverse(key: child, from: key, isRedundant: isRedundant)
            }
        }

        if let subscriptions = store.state.subscriptions[key] {
            for subscriberKey in subscriptions.keys {
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
            redundants[vertex, default: []].append(fromKey)
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
            redundants[vertex, default: []].append(fromKey)
        }
        else {
            let edge = Edge(from: fromKey, to: vertex)
            edges.append(edge)
        }
    }

    traverse(key: key, isRedundant: false)

    return (edges: edges.reversed(), redundants: redundants)
}
