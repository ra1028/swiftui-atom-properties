/// A snapshot structure that captures specific set of values of atoms and their dependency graph.
public struct Snapshot: CustomStringConvertible {
    internal let graph: Graph
    internal let caches: [AtomKey: any AtomCacheProtocol]
    internal let subscriptions: [AtomKey: [SubscriberKey: Subscription]]

    internal init(
        graph: Graph,
        caches: [AtomKey: any AtomCacheProtocol],
        subscriptions: [AtomKey: [SubscriberKey: Subscription]]
    ) {
        self.graph = graph
        self.caches = caches
        self.subscriptions = subscriptions
    }

    /// A textual representation of this snapshot.
    public var description: String {
        """
        Snapshot
        - graph: \(graph)
        - caches: \(caches)
        """
    }

    /// Lookup a value associated with the given atom from the set captured in this snapshot..
    ///
    /// Note that this does not look up a overridden atom.
    ///
    /// - Parameter atom: An atom to lookup.
    ///
    /// - Returns: The captured value associated with the given atom if it exists.
    @MainActor
    public func lookup<Node: Atom>(_ atom: Node) -> Node.Loader.Value? {
        let key = AtomKey(atom, scopeKey: nil)
        let cache = caches[key] as? AtomCache<Node>
        return cache?.value
    }

    /// Returns a DOT language representation of the dependency graph.
    ///
    /// This method generates a string that represents
    /// the [DOT the graph description language](https://graphviz.org/doc/info/lang.html)
    /// for the dependency graph of atoms clipped in this snapshot and views that use them.
    /// The generated strings can be converted into images that visually represent dependencies
    /// graph using [Graphviz](https://graphviz.org) for debugging and analysis.
    ///
    /// ## Example
    ///
    /// ```dot
    /// digraph {
    ///   node [shape=box]
    ///   "AAtom"
    ///   "AAtom" -> "BAtom"
    ///   "BAtom"
    ///   "BAtom" -> "CAtom"
    ///   "CAtom"
    ///   "CAtom" -> "Module/View.swift" [label="line:3"]
    ///   "Module/View.swift" [style=filled]
    /// }
    /// ```
    ///
    /// - Returns: A dependency graph represented in DOT the graph description language.
    public func graphDescription() -> String {
        guard !caches.keys.isEmpty else {
            return "digraph {}"
        }

        var statements = Set<String>()

        for key in caches.keys {
            statements.insert(key.description.quoted)

            if let children = graph.children[key] {
                for child in children {
                    statements.insert("\(key.description.quoted) -> \(child.description.quoted)")
                }
            }

            if let subscriptions = subscriptions[key]?.values {
                for subscription in subscriptions {
                    let label = "line:\(subscription.location.line)".quoted
                    statements.insert("\(subscription.location.fileID.quoted) [style=filled]")
                    statements.insert("\(key.description.quoted) -> \(subscription.location.fileID.quoted) [label=\(label)]")
                }
            }
        }

        return """
            digraph {
              node [shape=box]
              \(statements.sorted().joined(separator: "\n  "))
            }
            """
    }
}

private extension String {
    var quoted: String {
        "\"\(self)\""
    }
}
