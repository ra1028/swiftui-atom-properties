@usableFromInline
internal final class ObjectRetainer<Object: AnyObject> {
    private var object: Object?

    @usableFromInline
    init(_ object: Object) {
        self.object = object
    }

    @usableFromInline
    func release() {
        object = nil
    }
}
