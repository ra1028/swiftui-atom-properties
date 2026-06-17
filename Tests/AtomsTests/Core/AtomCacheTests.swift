import Testing

@testable import Atoms

struct AtomCacheTests {
    @MainActor
    @Test
    func testUpdated() {
        let atom = TestAtom(value: 0)
        let rootScopeToken = ScopeKey.Token()
        let scopeToken = ScopeKey.Token()
        let rootScopeValues = ScopeValues(
            key: rootScopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer(),
            ancestorScopeKeys: [:]
        )
        let scopeValues = ScopeValues(
            key: scopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer(),
            ancestorScopeKeys: [:]
        )
        let cache = AtomCache(atom: atom, value: 0, rootScopeValues: rootScopeValues, scopeValues: scopeValues)
        let updated = cache.updated(value: 1)

        #expect(updated.atom == atom)
        #expect(updated.value == 1)
        #expect(updated.rootScopeValues.key == rootScopeToken.key)
        #expect(updated.scopeValues?.key == scopeToken.key)
    }

    @MainActor
    @Test
    func testDescription() {
        let atom = TestAtom(value: 0)
        let cache = AtomCache(atom: atom, value: 0)

        #expect(cache.description == "0")
    }
}
