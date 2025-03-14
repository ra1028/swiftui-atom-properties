import SwiftUI

#if compiler(>=6)
    internal extension EnvironmentValues {
        @Entry
        var store: StoreContext? = nil
    }
#else
    internal extension EnvironmentValues {
        var store: StoreContext? {
            get { self[StoreEnvironmentKey.self] }
            set { self[StoreEnvironmentKey.self] = newValue }
        }
    }

    private struct StoreEnvironmentKey: EnvironmentKey {
        static var defaultValue: StoreContext? {
            nil
        }
    }
#endif
