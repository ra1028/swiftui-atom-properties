import SwiftUI

public extension AtomPrimitive {
    @available(*, deprecated, message: "`Atom.updated(newValue:oldValue:context:)` is also deprecated. Use `Atom.effect(context:)` instead.")
    typealias UpdatedContext = AtomCurrentContext<Coordinator>
}

public extension Atom {
    @available(*, deprecated, renamed: "changes(of:)")
    func select<Selected: Equatable>(
        _ keyPath: KeyPath<Produced, Selected>
    ) -> ModifiedAtom<Self, ChangesOfModifier<Produced, Selected>> {
        changes(of: keyPath)
    }
}

public extension AtomWatchableContext {
    @available(*, deprecated, renamed: "AtomViewContext.binding(_:)")
    func state<Node: StateAtom>(_ atom: Node) -> Binding<Node.Produced> {
        Binding(
            get: { watch(atom) },
            set: { set($0, for: atom) }
        )
    }
}

public extension Resettable {
    @available(*, deprecated, renamed: "CurrentContext")
    typealias ResetContext = AtomCurrentContext<Coordinator>
}

public extension Refreshable {
    @available(*, deprecated, renamed: "CurrentContext")
    typealias RefreshContext = AtomCurrentContext<Coordinator>
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
    func observe(_ onUpdate: @escaping @MainActor @Sendable (Snapshot) -> Void) -> Self {
        scopedObserve(onUpdate)
    }

    @available(*, deprecated, renamed: "scopedOverride(_:with:)")
    func override<Node: Atom>(_ atom: Node, with value: @escaping @MainActor @Sendable (Node) -> Node.Produced) -> Self {
        scopedOverride(atom, with: value)
    }

    @available(*, deprecated, renamed: "scopedOverride(_:with:)")
    func override<Node: Atom>(_ atomType: Node.Type, with value: @escaping @MainActor @Sendable (Node) -> Node.Produced) -> Self {
        scopedOverride(atomType, with: value)
    }
}
