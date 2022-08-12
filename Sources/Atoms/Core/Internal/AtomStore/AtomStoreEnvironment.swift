import SwiftUI

internal extension EnvironmentValues {
    var atomStore: AtomStore {
        get { self[AtomStoreEnvironmentKey.self] }
        set { self[AtomStoreEnvironmentKey.self] = newValue }
    }
}

private struct AtomStoreEnvironmentKey: EnvironmentKey {
    static var defaultValue: AtomStore {
        DefaultAtomStore()
    }
}
