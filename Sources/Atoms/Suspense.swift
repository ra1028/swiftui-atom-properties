import SwiftUI

/// A view that lets the content wait for the given task to provide a resulting value
/// or an error.
///
/// ``Suspense`` manages the given task internally until the task instance is changed.
/// While the specified task is in process to provide a resulting value, it displays the
/// `suspending` content that is empty by default.
/// When the task eventually provides a resulting value, it updates the view to display
/// the given content. If the task fails, it falls back to show the `catch` content that
/// is also empty as default.
///
/// ## Example
///
/// ```swift
/// let fetchImageTask: Task<UIImage, Error> = ...
///
/// Suspense(fetchImageTask) { uiImage in
///     // Displays content when the task successfully provides a value.
///     Image(uiImage: uiImage)
/// } suspending: {
///     // Optionally displays a suspending content.
///     ProgressView()
/// } catch: { error in
///     // Optionally displays a failure content.
///     Text(error.localizedDescription)
/// }
/// ```
///
public struct Suspense<Value, Failure: Error, Content: View, Suspending: View, FailureContent: View>: View {
    private let task: Task<Value, Failure>
    private let content: (Value) -> Content
    private let suspending: () -> Suspending
    private let failureContent: (Failure) -> FailureContent

    @StateObject
    private var state = State()

    /// Waits for the given task to provide a resulting value and display the content
    /// accordingly.
    ///
    /// ```swift
    /// let fetchImageTask: Task<UIImage, Error> = ...
    ///
    /// Suspense(fetchImageTask) { uiImage in
    ///     Image(uiImage: uiImage)
    /// } suspending: {
    ///     ProgressView()
    /// } catch: { error in
    ///     Text(error.localizedDescription)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - task: A task that provides a resulting value to be displayed.
    ///   - content: A content that displays when the task successfully provides a value.
    ///   - suspending: A suspending content that displays while the task is in process.
    ///   - catch: A failure content that displays if the task fails.
    public init(
        _ task: Task<Value, Failure>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder suspending: @escaping () -> Suspending,
        @ViewBuilder catch: @escaping (Failure) -> FailureContent
    ) {
        self.task = task
        self.content = content
        self.suspending = suspending
        self.failureContent = `catch`
    }

    /// Waits for the given task to provide a resulting value and display the content
    /// accordingly.
    ///
    /// ```swift
    /// let fetchImageTask: Task<UIImage, Error> = ...
    ///
    /// Suspense(fetchImageTask) { uiImage in
    ///     Image(uiImage: uiImage)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - task: A task that provides a resulting value to be displayed.
    ///   - content: A content that displays when the task successfully provides a value.
    public init(
        _ task: Task<Value, Failure>,
        @ViewBuilder content: @escaping (Value) -> Content
    ) where Suspending == EmptyView, FailureContent == EmptyView {
        self.init(
            task,
            content: content,
            suspending: EmptyView.init,
            catch: { _ in EmptyView() }
        )
    }

    /// Waits for the given task to provide a resulting value and display the content
    /// accordingly.
    ///
    /// ```swift
    /// let fetchImageTask: Task<UIImage, Error> = ...
    ///
    /// Suspense(fetchImageTask) { uiImage in
    ///     Image(uiImage: uiImage)
    /// } suspending: {
    ///     ProgressView()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - task: A task that provides a resulting value to be displayed.
    ///   - content: A content that displays when the task successfully provides a value.
    ///   - suspending: A suspending content that displays while the task is in process.
    public init(
        _ task: Task<Value, Failure>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder suspending: @escaping () -> Suspending
    ) where FailureContent == EmptyView {
        self.init(
            task,
            content: content,
            suspending: suspending,
            catch: { _ in EmptyView() }
        )
    }

    /// Waits for the given task to provide a resulting value and display the content
    /// accordingly.
    ///
    /// ```swift
    /// let fetchImageTask: Task<UIImage, Error> = ...
    ///
    /// Suspense(fetchImageTask) { uiImage in
    ///     Image(uiImage: uiImage)
    /// } catch: { error in
    ///     Text(error.localizedDescription)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - task: A task that provides a resulting value to be displayed.
    ///   - content: A content that displays when the task successfully provides a value.
    ///   - catch: A failure content that displays if the task fails.
    public init(
        _ task: Task<Value, Failure>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder catch: @escaping (Failure) -> FailureContent
    ) where Suspending == EmptyView {
        self.init(
            task,
            content: content,
            suspending: EmptyView.init,
            catch: `catch`
        )
    }

    /// The content and behavior of the view.
    public var body: some View {
        state.task = task

        return Group {
            switch state.phase {
            case .success(let value):
                content(value)

            case .suspending:
                suspending()

            case .failure(let error):
                failureContent(error)
            }
        }
    }
}

private extension Suspense {
    @MainActor
    final class State: ObservableObject {
        @Published
        private(set) var phase = AsyncPhase<Value, Failure>.suspending

        private var suspensionTask: Task<Void, Never>? {
            didSet { oldValue?.cancel() }
        }

        var task: Task<Value, Failure>? {
            didSet {
                guard task != oldValue else {
                    return
                }

                guard let task else {
                    phase = .suspending
                    return suspensionTask = nil
                }

                suspensionTask = Task { [weak self] in
                    self?.phase = .suspending

                    let result = await task.result

                    if !Task.isCancelled {
                        self?.phase = AsyncPhase(result)
                    }
                }
            }
        }

        deinit {
            suspensionTask?.cancel()
        }
    }
}
