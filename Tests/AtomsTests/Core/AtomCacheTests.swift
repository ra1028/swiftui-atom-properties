import Testing

@testable import Atoms

struct AtomCacheTests {
    @MainActor
    @Test
    func testUpdated() {
        let atom = TestAtom(value: 0)
        let scopeToken = ScopeKey.Token()
        let scopeValues = ScopeValues(
            key: scopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer(),
            ancestorScopeKeys: [:]
        )
        let cache = AtomCache(atom: atom, value: 0, scopeValues: scopeValues)
        let updated = cache.updated(value: 1)

        #expect(updated.atom == atom)
        #expect(updated.value == 1)
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
