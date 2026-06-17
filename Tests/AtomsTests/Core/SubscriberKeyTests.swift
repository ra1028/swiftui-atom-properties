import Testing

@testable import Atoms

struct SubscriberKeyTests {
    @MainActor
    @Test
    func testKeyHashableForSameToken() {
        let token = SubscriberKey.Token()

        #expect(token.key == token.key)
        #expect(token.key.hashValue == token.key.hashValue)
    }

    @MainActor
    @Test
    func testKeyHashableForDifferentToken() {
        let token0 = SubscriberKey.Token()
        let token1 = SubscriberKey.Token()

        #expect(token0.key != token1.key)
        #expect(token0.key.hashValue != token1.key.hashValue)
    }
}
