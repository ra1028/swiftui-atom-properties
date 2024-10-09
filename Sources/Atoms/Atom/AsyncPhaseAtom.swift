public protocol AsyncPhaseAtom: AsyncAtom where Produced == AsyncPhase<Success, Failure> {
    associatedtype Success

    #if compiler(>=6)
        associatedtype Failure: Error

        @MainActor
        func value(context: Context) async throws(Failure) -> Success
    #else
        typealias Failure = any Error

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
