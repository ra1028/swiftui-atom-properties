internal struct Scope {
    let observers: [Observer]
    let overrideContainer: OverrideContainer
    let ancestorScopeKeys: [ScopeID: ScopeKey]
}
