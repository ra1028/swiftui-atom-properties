import SwiftUI

internal extension EnvironmentValues {
    var store: StoreContext {
        get { self[StoreEnvironmentKey.self] }
        set { self[StoreEnvironmentKey.self] = newValue }
    }
}

private struct StoreEnvironmentKey: EnvironmentKey {
    static var defaultValue: StoreContext {
        StoreContext(enablesAssertion: true)
    }
}
