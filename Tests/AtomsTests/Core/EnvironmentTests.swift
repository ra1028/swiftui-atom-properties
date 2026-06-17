import SwiftUI
import Testing

@testable import Atoms

struct EnvironmentTests {
    @MainActor
    @Test
    func testStore() {
        let store = AtomStore()
        let scopeToken = ScopeKey.Token()
        let atom = TestValueAtom(value: 0)
        var environment = EnvironmentValues()

        store.caches = [AtomKey(atom): AtomCache(atom: atom, value: 100)]
        environment.store = .root(store: store, scopeKey: scopeToken.key)

        #expect(environment.store?.read(atom) == 100)
    }
}
