public struct ModifiedAtom<Modifier: AtomModifier>: Atom {
    private let modifier: Modifier

    internal init(modifier: Modifier) {
        self.modifier = modifier
    }

    public var key: Modifier.Key {
        modifier.key
    }

    public var hook: Modifier {
        modifier
    }

    public func shouldNotifyUpdate(newValue: Hook.Value, oldValue: Hook.Value) -> Bool {
        modifier.shouldNotifyUpdate(newValue: newValue, oldValue: oldValue)
    }
}
