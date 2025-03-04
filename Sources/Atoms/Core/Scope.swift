internal struct Scope {
    let overrides: [OverrideKey: any OverrideProtocol]
    let observers: [Observer]
    let inheritedScopeKeys: [ScopeID: ScopeKey]
}
