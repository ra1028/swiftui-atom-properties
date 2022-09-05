/// A snapshot structure that captures specific set of values of atoms and their dependency graph.
public struct Snapshot: CustomStringConvertible {
    internal let graph: Graph
    internal let caches: [AtomKey: AtomCacheBase]
    internal let subscriptions: [AtomKey: [SubscriptionKey: Subscription]]
    private let _restore: @MainActor () -> Void

    internal init(
        graph: Graph,
        caches: [AtomKey: AtomCacheBase],
        subscriptions: [AtomKey: [SubscriptionKey: Subscription]],
        restore: @MainActor @escaping () -> Void
    ) {
        self.graph = graph
        self.caches = caches
        self.subscriptions = subscriptions
        self._restore = restore
    }

    /// A textual representation of this snapshot.
    public var description: String {
        """
        Snapshot
        - graph: \(graph)
        - caches: \(caches)
        """
    }

    /// Restores the atom values that are captured in this snapshot.
    @MainActor
    public func restore() {
        _restore()
    }

    /// Lookup a value associated with the given atom from the set captured in this snapshot..
    ///
    /// - Parameter atom: An atom that associates the value.
    ///
    /// - Returns: The captured value associated with the given atom if it exists.
    @MainActor
    public func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom)
        let cache = caches[key] as? AtomCache<Node>
        return cache?.value
    }

    public func dotRepresentation() -> String {
        guard !caches.keys.isEmpty else {
            return ""
        }

        var statements = [String]()

        for key in caches.keys {
            statements.append(key.description.quoted)

            if let children = graph.children[key], !children.isEmpty {
                for child in children {
                    let edge = "\(key.description.quoted) -> \(child.description.quoted)"
                    statements.append(edge)
                }
            }

            if let subscribers = subscriptions[key]?.keys, !subscribers.isEmpty {
                for subscriber in subscribers {
                    let edge = "\(key.description.quoted) -> \(subscriber.description.quoted)"
                    statements.append(edge)
                    statements.append("\(subscriber.description.quoted) [style=filled]")
                }
            }
        }

        // Eliminate duplicated statements.
        statements = Set(statements).sorted()

        return """
            digraph {
              node [shape=box];
              \(statements.joined(separator: ";\n  "));
            }
            """
    }
}

private extension String {
    var quoted: String {
        "\"\(self)\""
    }
}
