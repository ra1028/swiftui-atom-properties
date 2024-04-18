import SwiftUI

public extension Atom {
    @available(*, deprecated, renamed: "changes(of:)")
    func select<Selected: Equatable>(
        _ keyPath: KeyPath<Loader.Value, Selected>
    ) -> ModifiedAtom<Self, ChangesOfModifier<Loader.Value, Selected>> {
        changes(of: keyPath)
    }
}

public extension AtomScope {
    @available(*, deprecated, renamed: "init(inheriting:content:)")
    init(
        _ context: AtomViewContext,
        @ViewBuilder content: () -> Content
    ) {
        self.init(inheriting: context, content: content)
    }

    @available(*, deprecated, renamed: "AtomRoot.init(storesIn:content:)")
    init<Root: View>(
        _ store: AtomStore,
        @ViewBuilder content: () -> Root
    ) where Content == AtomRoot<Root> {
        self.init {
            AtomRoot(storesIn: store, content: content)
        }
    }

    @available(*, deprecated, renamed: "scopedObserve(_:)")
    func observe(_ onUpdate: @escaping @MainActor (Snapshot) -> Void) -> Self {
        scopedObserve(onUpdate)
    }

    @available(*, deprecated, renamed: "scopedOverride(_:with:)")
    func override<Node: Atom>(_ atom: Node, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        scopedOverride(atom, with: value)
    }

    @available(*, deprecated, renamed: "scopedOverride(_:with:)")
    func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping (Node) -> Node.Loader.Value) -> Self {
        scopedOverride(atomType, with: value)
    }
}
