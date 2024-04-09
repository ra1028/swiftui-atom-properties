public extension Atom {
    @available(*, deprecated, renamed: "changes(of:)")
    func select<Selected: Equatable>(
        _ keyPath: KeyPath<Loader.Value, Selected>
    ) -> ModifiedAtom<Self, ChangesOfModifier<Loader.Value, Selected>> {
        changes(of: keyPath)
    }
}
