internal struct ScopeValues {
    let key: ScopeKey
    let observers: [Observer]
    let overrideContainer: OverrideContainer
    let ancestorScopeKeys: [ScopeID: ScopeKey]
}
