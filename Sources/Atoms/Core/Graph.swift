internal struct Graph: Equatable {
    var dependencies = [AtomKey: Set<AtomKey>]()
    var children = [AtomKey: Set<AtomKey>]()
    var subscribed = [SubscriberKey: Set<AtomKey>]()
}
