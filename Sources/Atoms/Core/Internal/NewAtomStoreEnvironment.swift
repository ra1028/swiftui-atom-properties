import SwiftUI

internal extension EnvironmentValues {
    var atomStoreInteractor: AtomStoreInteractor {
        get { self[AtomStoreInteractorEnvironmentKey.self] }
        set { self[AtomStoreInteractorEnvironmentKey.self] = newValue }
    }
}

private struct AtomStoreInteractorEnvironmentKey: EnvironmentKey {
    static var defaultValue: AtomStoreInteractor {
        DefaultAtomStoreInteractor()
    }
}
