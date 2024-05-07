@MainActor
public protocol AtomEffect {
    typealias Context = AtomEffectContext

    func initialized(context: Context)
    func updated(context: Context)
    func released(context: Context)
}

public extension AtomEffect {
    func initialized(context: Context) {}
    func updated(context: Context) {}
    func released(context: Context) {}
}
