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

    @available(*, deprecated, renamed: "init(storesIn:content:)")
    init(
        _ store: AtomStore,
        @ViewBuilder content: () -> Content
    ) {
        self.init(storesIn: store, content: content)
    }
}
