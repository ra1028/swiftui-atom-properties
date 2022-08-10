import SwiftUI

internal extension EnvironmentValues {
//    var atomStore: AtomStore {
//        get { self[StoreEnvironmentKey.self] }
//        set { self[StoreEnvironmentKey.self] = newValue }
//    }
}

private struct StoreEnvironmentKey: EnvironmentKey {
    static var defaultValue: AtomStore {
        DefaultStore()
    }
}
