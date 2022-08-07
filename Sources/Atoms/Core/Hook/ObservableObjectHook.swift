import Combine

/// Internal use, a hook type that determines behavioral details of corresponding atoms.
@MainActor
public struct ObservableObjectHook<ObjectType: ObservableObject>: AtomObservableObjectHook {
    /// A reference type object to manage internal state.
    public final class Coordinator {
        internal var object: ObjectType?
    }

    private let object: @MainActor (AtomRelationContext) -> ObjectType

    internal init(object: @MainActor @escaping (AtomRelationContext) -> ObjectType) {
        self.object = object
    }

    /// Creates a coordinator instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Gets and returns the observable object with the given context.
    public func value(context: Context) -> ObjectType {
        context.coordinator.object ?? _assertingFallbackValue(context: context)
    }

    /// Instantiates and caches the observable object, and then subscribes to it.
    public func update(context: Context) {
        let object = object(context.atomContext)
        updateOverride(context: context, with: object)
    }

    /// Overrides with the given observable object.
    public func updateOverride(context: Context, with value: ObjectType) {
        let cancellable = value.objectWillChange.sink { _ in
            context.notifyUpdate()
        }

        context.coordinator.object = value
        context.addTermination(cancellable.cancel)
    }
}
