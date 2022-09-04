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

        let separator = ";\n  "

        func quoted(_ string: String) -> String {
            "\"\(string)\""
        }

        func edges<Nodes: Collection>(from key: AtomKey, to nodes: Nodes) -> String where Nodes.Element: CustomStringConvertible {
            nodes.lazy
                .map { "\(quoted(key.description)) -> \(quoted($0.description))" }
                .sorted()
                .joined(separator: separator)
        }

        func edges(for key: AtomKey) -> String {
            var statements = quoted(key.description)

            if let children = graph.children[key], !children.isEmpty {
                statements += separator + edges(from: key, to: children)
            }

            if let subscriptions = subscriptions[key]?.keys, !subscriptions.isEmpty {
                statements += separator + edges(from: key, to: subscriptions)
            }

            return statements
        }

        var statements = caches.keys.lazy
            .map(edges)
            .sorted()
            .joined(separator: separator)

        if !subscriptions.isEmpty {
            let subscribers = Set(subscriptions.values.lazy.flatMap(\.keys))
            statements += separator
            statements += subscribers.lazy
                .map { "\(quoted($0.description)) [shape=ellipse, style=filled]" }
                .sorted()
                .joined(separator: separator)
        }

        return """
            digraph {
              node [shape=box];
              \(statements);
            }
            """
    }
}
