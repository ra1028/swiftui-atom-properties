/// An atom type that provides a throwing `Task` from the given asynchronous, throwing function.
///
/// This atom guarantees that the task to be identical instance and its state can be shared
/// at anywhere even when they are accessed simultaneously from multiple locations.
///
/// - SeeAlso: ``TaskAtom``
/// - SeeAlso: ``Suspense``
///
/// ## Output Value
///
/// Task<Self.Value, any Error>
///
/// ## Example
///
/// ```swift
/// struct AsyncTextAtom: ThrowingTaskAtom, Hashable {
///     func value(context: Context) async throws -> String {
///         try await Task.sleep(nanoseconds: 1_000_000_000)
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
///             Text("Loading")
///         } catch: {
///             Text("Failed")
///         }
///     }
/// }
/// ```
///
public protocol ThrowingTaskAtom: AsyncAtom where Produced == Task<Success, any Error> {
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
    /// - Throws: The error that occurred during the process of creating the resulting value.
    ///
    /// - Returns: A throwing `Task` that produces asynchronous value.
    @MainActor
    func value(context: Context) async throws -> Success
}

public extension ThrowingTaskAtom {
    var producer: AtomProducer<Produced> {
        AtomProducer { context in
            Task {
                try await context.transaction(value)
            }
        } manageValue: { task, context in
            context.onTermination = task.cancel
        }
    }

    var refreshProducer: AtomRefreshProducer<Produced> {
        AtomRefreshProducer { context in
            Task {
                try await context.transaction(value)
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
