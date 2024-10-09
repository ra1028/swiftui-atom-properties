/// An atom that provides an ``AsyncPhase`` value from the asynchronous throwable function.
///
/// The value produced by the given asynchronous throwable function will be converted into
/// an enum representation ``AsyncPhase`` that changes when the process is done or thrown an error.
///
/// ## Output Value
///
/// ``AsyncPhase``<Self.Success, Self.Failure>
///
/// ## Example
///
/// ```swift
/// struct AsyncTextAtom: AsyncPhaseAtom, Hashable {
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
///         switch text {
///         case .success(let text):
///             Text(text)
///
///         case .suspending:
///             Text("Loading")
///
///         case .failure:
///             Text("Failed")
///     }
/// }
/// ```
///
public protocol AsyncPhaseAtom: AsyncAtom where Produced == AsyncPhase<Success, Failure> {
    /// The type of success value that this atom produces.
    associatedtype Success

    #if compiler(>=6)
        /// The type of errors that this atom produces.
        associatedtype Failure: Error

        /// Asynchronously produces a value to be provided via this atom.
        ///
        /// Values provided or errors thrown by this method are converted to the unified enum
        /// representation ``AsyncPhase``.
        ///
        /// - Parameter context: A context structure to read, watch, and otherwise
        ///                      interact with other atoms.
        ///
        /// - Throws: The error that occurred during the process of creating the resulting value.
        ///
        /// - Returns: The process's result.
        @MainActor
        func value(context: Context) async throws(Failure) -> Success
    #else
        /// The type of errors that this atom produces.
        typealias Failure = any Error

        /// Asynchronously produces a value to be provided via this atom.
        ///
        /// Values provided or errors thrown by this method are converted to the unified enum
        /// representation ``AsyncPhase``.
        ///
        /// - Parameter context: A context structure to read, watch, and otherwise
        ///                      interact with other atoms.
        ///
        /// - Throws: The error that occurred during the process of creating the resulting value.
        ///
        /// - Returns: The process's result.
        @MainActor
        func value(context: Context) async throws -> Success
    #endif
}

public extension AsyncPhaseAtom {
    var producer: AtomProducer<Produced> {
        AtomProducer { context in
            let task = Task {
                #if compiler(>=6)
                    do throws(Failure) {
                        let value = try await context.transaction(value)

                        if !Task.isCancelled {
                            context.update(with: .success(value))
                        }
                    }
                    catch {
                        if !Task.isCancelled {
                            context.update(with: .failure(error))
                        }
                    }
                #else
                    do {
                        let value = try await context.transaction(value)

                        if !Task.isCancelled {
                            context.update(with: .success(value))
                        }
                    }
                    catch {
                        if !Task.isCancelled {
                            context.update(with: .failure(error))
                        }
                    }
                #endif
            }

            context.onTermination = task.cancel
            return .suspending
        }
    }

    var refreshProducer: AtomRefreshProducer<Produced> {
        AtomRefreshProducer { context in
            var phase = Produced.suspending

            let task = Task {
                #if compiler(>=6)
                    do throws(Failure) {
                        let value = try await context.transaction(value)

                        if !Task.isCancelled {
                            phase = .success(value)
                        }
                    }
                    catch {
                        if !Task.isCancelled {
                            phase = .failure(error)
                        }
                    }
                #else
                    do {
                        let value = try await context.transaction(value)

                        if !Task.isCancelled {
                            phase = .success(value)
                        }
                    }
                    catch {
                        if !Task.isCancelled {
                            phase = .failure(error)
                        }
                    }
                #endif
            }

            return await withTaskCancellationHandler {
                await task.value
                return phase
            } onCancel: {
                task.cancel()
            }
        }
    }
}
