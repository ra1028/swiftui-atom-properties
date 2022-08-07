/// Internal use, a hook type that determines behavioral details of corresponding atoms.
public struct ModifiedHook<Node: Atom, Modifier: AtomModifier>: AtomHook where Node.Hook.Value == Modifier.Value {
    /// A reference type object to manage internal state.
    public typealias Coordinator = Modifier.Coordinator

    private let atom: Node
    private let modifier: Modifier

    internal init(atom: Node, modifier: Modifier) {
        self.atom = atom
        self.modifier = modifier
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        modifier.makeCoordinator()
    }

    /// Gets and returns the observable object with the given context.
    public func value(context: Context) -> Modifier.ModifiedValue {
        modifier.get(context: context) ?? _assertingFallbackValue(context: context)
    }

    /// Instantiates and caches the observable object, and then subscribes to it.
    public func update(context: Context) {
        let value = context.atomContext.watch(atom)
        modifier.update(context: context, with: value)
    }

    /// Overrides with the given observable object.
    public func updateOverride(context: Context, with value: Modifier.ModifiedValue) {
        modifier.set(value: value, context: context)
    }
}
