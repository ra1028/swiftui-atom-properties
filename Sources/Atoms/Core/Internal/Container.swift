@usableFromInline
internal typealias StoreContainer = Container<AtomKey, StoreEntry>

@usableFromInline
internal typealias RelationshipContainer = Container<AtomKey, Relation>

@usableFromInline
internal final class Container<Key: Hashable, Value> {
    var entries = [Key: Value]()
}
