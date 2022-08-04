public struct ModifiedHook<Node: Atom, Modifier: AtomModifier>: AtomHook where Node.Hook.Value == Modifier.Value {
    public typealias Coordinator = Modifier.Coordinator

    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    public func makeCoordinator() -> Coordinator {
        modifier.makeCoordinator()
    }

    public func value(context: Context) -> Modifier.ModifiedValue {
        modifier.get(context: context) ?? _assertingFallbackValue(context: context)
    }

    public func update(context: Context) {
        let value = context.atomContext.watch(atom)
        modifier.update(context: context, with: value)
    }

    public func updateOverride(context: Context, with value: Modifier.ModifiedValue) {
        modifier.set(value: value, context: context)
    }
}
