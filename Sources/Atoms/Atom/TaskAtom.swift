/// An atom type that provides a nonthrowing `Task` from the given asynchronous function.
///
/// This atom guarantees that the task to be identical instance and its state can be shared
/// at anywhere even when they are accessed simultaneously from multiple locations.
///
/// - SeeAlso: ``ThrowingTaskAtom``
/// - SeeAlso: ``Suspense``
///
/// ## Output Value
///
/// Task<Self.Value, Never>
///
/// ## Example
///
/// ```swift
/// struct AsyncTextAtom: TaskAtom, Hashable {
///     func value(context: Context) async -> String {
///         try? await Task.sleep(nanoseconds: 1_000_000_000)
///         return "Swift"
///     }
/// }
///
/// struct DelayedTitleView: View {
///     @Watch(AsyncTextAtom())
///     var text
///
///     var body: some View {
///         Suspense(text) { text in
///             Text(text)
///         } suspending: {
///             Text("Loading...")
///         }
///     }
/// }
/// ```
///
public protocol TaskAtom: AsyncAtom where Produced == Task<Success, Never> {
    /// The type of success value that this atom produces.
    associatedtype Success: Sendable

    /// Asynchronously produces a value to be provided via this atom.
    ///
    /// This asynchronous method is converted to a `Task` internally, and if it will be
    /// cancelled by downstream atoms or views, this method will also be cancelled.
    ///
    /// - Parameter context: A context structure to read, watch, and otherwise
    ///                      interact with other atoms.
    ///
    /// - Returns: The process's result.
    @MainActor
    func value(context: Context) async -> Success
}

public extension TaskAtom {
    var producer: AtomProducer<Produced> {
        AtomProducer { context in
            Task {
                await context.transaction(value)
            }
        } manageValue: { task, context in
            context.onTermination = task.cancel
        }
    }

    var refreshProducer: AtomRefreshProducer<Produced> {
        AtomRefreshProducer { context in
            Task {
                await context.transaction(value)
            }
        } refreshValue: { task, context in
            context.onTermination = task.cancel

            await withTaskCancellationHandler {
                _ = await task.result
            } onCancel: {
                task.cancel()
            }
        }
    }
}
