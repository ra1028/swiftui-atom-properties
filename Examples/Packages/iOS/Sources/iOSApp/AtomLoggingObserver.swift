import Atoms

final class AtomLoggingObserver: AtomObserver {
    private var debugAtomNames = [String]()

    func atomAssigned<Node: Atom>(atom: Node) {
        debugAtomNames.append(Node.debugName)

        print("Assigned \(Node.debugName)")
        dump(debugAtomNames, name: "Aliving")
    }

    func atomUnassigned<Node: Atom>(atom: Node) {
        if let index = debugAtomNames.firstIndex(of: Node.debugName) {
            debugAtomNames.remove(at: index)
        }

        print("Unassigned \(Node.debugName)")
        dump(debugAtomNames, name: "Aliving")
    }

    func atomChanged<Node: Atom>(snapshot: Snapshot<Node>) {
        dump(snapshot.value, name: "Changed: \(Node.debugName)")
    }
}

@MainActor
private extension Atom {
    static var debugName: String {
        String(describing: self) + (shouldKeepAlive ? "[KeepAlive]" : "")
    }
}
