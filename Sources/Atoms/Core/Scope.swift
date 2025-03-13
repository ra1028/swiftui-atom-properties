internal struct Scope {
    let overrides: [OverrideKey: any OverrideProtocol]
    let observers: [Observer]
    let ancestorScopeKeys: [ScopeID: ScopeKey]
}
