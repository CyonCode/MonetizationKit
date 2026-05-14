import StoreKit

@available(macOS 12.0, iOS 15.0, *)
struct AnyTransactionStream: TransactionStreaming {
    typealias UpdateSequence = AnyAsyncSequence<VerificationResult<Transaction>>
    typealias EntitlementSequence = AnyAsyncSequence<VerificationResult<Transaction>>

    private let _updates: @Sendable () -> AnyAsyncSequence<VerificationResult<Transaction>>
    private let _entitlements: @Sendable () -> AnyAsyncSequence<VerificationResult<Transaction>>

    init<S: TransactionStreaming>(_ wrapped: S) {
        self._updates = { AnyAsyncSequence(wrapped.updates) }
        self._entitlements = { AnyAsyncSequence(wrapped.currentEntitlements) }
    }

    var updates: AnyAsyncSequence<VerificationResult<Transaction>> {
        _updates()
    }

    var currentEntitlements: AnyAsyncSequence<VerificationResult<Transaction>> {
        _entitlements()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AnyAsyncSequence<Element>: AsyncSequence {
    private let _makeIterator: () -> AsyncIterator

    init<S: AsyncSequence>(_ wrapped: S) where S.Element == Element {
        var wrappedIterator = wrapped.makeAsyncIterator()
        self._makeIterator = {
            AsyncIterator {
                try await wrappedIterator.next()
            }
        }
    }

    struct AsyncIterator: AsyncIteratorProtocol {
        private let _next: () async throws -> Element?

        init(next: @escaping () async throws -> Element?) {
            self._next = next
        }

        mutating func next() async throws -> Element? {
            try await _next()
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        _makeIterator()
    }
}
