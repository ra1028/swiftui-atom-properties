internal struct SubscriptionKey: Hashable {
    private let objectIdentifier: ObjectIdentifier

    init<Object: AnyObject>(_ object: Object) {
        self.objectIdentifier = ObjectIdentifier(object)
    }
}
