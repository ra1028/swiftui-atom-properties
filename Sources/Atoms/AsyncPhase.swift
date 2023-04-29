/// A value that represents a success, a failure, or a state in which the result of
/// asynchronous process has not yet been determined.
public enum AsyncPhase<Success, Failure: Error> {
    /// A suspending phase in which the result has not yet been determined.
    case suspending

    /// A success, storing a `Success` value.
    case success(Success)

    /// A failure, storing a `Failure` value.
    case failure(Failure)

    /// Creates a new phase with the given result by mapping either of a `success` or
    /// a `failure`.
    ///
    /// - Parameter result: A result value to be mapped.
    public init(_ result: Result<Success, Failure>) {
        switch result {
        case .success(let value):
            self = .success(value)

        case .failure(let error):
            self = .failure(error)
        }
    }

    /// Creates a new phase by evaluating a async throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A async throwing closure to evaluate.
    public init(catching body: () async throws -> Success) async where Failure == Error {
        do {
            let value = try await body()
            self = .success(value)
        }
        catch {
            self = .failure(error)
        }
    }

    /// A boolean value indicating whether `self` is ``AsyncPhase/suspending``.
    public var isSuspending: Bool {
        guard case .suspending = self else {
            return false
        }

        return true
    }

    /// A boolean value indicating whether `self` is ``AsyncPhase/success(_:)``.
    public var isSuccess: Bool {
        guard case .success = self else {
            return false
        }

        return true
    }

    /// A boolean value indicating whether `self` is ``AsyncPhase/failure(_:)``.
    public var isFailure: Bool {
        guard case .failure = self else {
            return false
        }

        return true
    }

    /// Returns the success value if `self` is ``AsyncPhase/success(_:)``, otherwise returns `nil`.
    public var value: Success? {
        guard case .success(let value) = self else {
            return nil
        }

        return value
    }

    /// Returns the error value if `self` is ``AsyncPhase/failure(_:)``, otherwise returns `nil`.
    public var error: Failure? {
        guard case .failure(let error) = self else {
            return nil
        }

        return error
    }

    /// Returns a new phase, mapping any success value using the given transformation.
    ///
    /// - Parameter transform: A closure that takes the success value of this instance.
    ///
    /// - Returns: An ``AsyncPhase`` instance with the result of evaluating `transform`
    ///   as the new success value if this instance represents a success.
    public func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> AsyncPhase<NewSuccess, Failure> {
        flatMap { .success(transform($0)) }
    }

    /// Returns a new phase, mapping any failure value using the given transformation.
    ///
    /// - Parameter transform: A closure that takes the failure value of the instance.
    ///
    /// - Returns: An ``AsyncPhase`` instance with the result of evaluating `transform` as
    ///            the new failure value if this instance represents a failure.
    public func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> AsyncPhase<Success, NewFailure> {
        flatMapError { .failure(transform($0)) }
    }

    /// Returns a new phase, mapping any success value using the given transformation
    /// and unwrapping the produced result.
    ///
    /// - Parameter transform: A closure that takes the success value of the instance.
    ///
    /// - Returns: An ``AsyncPhase`` instance, either from the closure or the previous
    ///            ``AsyncPhase/failure(_:)``.
    public func flatMap<NewSuccess>(_ transform: (Success) -> AsyncPhase<NewSuccess, Failure>) -> AsyncPhase<NewSuccess, Failure> {
        switch self {
        case .suspending:
            return .suspending

        case .success(let value):
            return transform(value)

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Returns a new phase, mapping any failure value using the given transformation
    /// and unwrapping the produced result.
    ///
    /// - Parameter transform: A closure that takes the failure value of the instance.
    ///
    /// - Returns: An ``AsyncPhase`` instance, either from the closure or the previous
    ///            ``AsyncPhase/success(_:)``.
    public func flatMapError<NewFailure>(_ transform: (Failure) -> AsyncPhase<Success, NewFailure>) -> AsyncPhase<Success, NewFailure> {
        switch self {
        case .suspending:
            return .suspending

        case .success(let value):
            return .success(value)

        case .failure(let error):
            return transform(error)
        }
    }
}

extension AsyncPhase: Sendable where Success: Sendable {}
extension AsyncPhase: Equatable where Success: Equatable, Failure: Equatable {}
extension AsyncPhase: Hashable where Success: Hashable, Failure: Hashable {}
