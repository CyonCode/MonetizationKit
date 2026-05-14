import StoreKit
@testable import MonetizationKit

@available(macOS 12.0, iOS 15.0, *)
final class MockTransactionStream: TransactionStreaming, @unchecked Sendable {
    var stubbedUpdates: [VerificationResult<Transaction>] = []
    var stubbedEntitlements: [VerificationResult<Transaction>] = []

    var updates: MockTransactionResultSequence {
        MockTransactionResultSequence(results: stubbedUpdates)
    }

    var currentEntitlements: MockTransactionResultSequence {
        MockTransactionResultSequence(results: stubbedEntitlements)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct MockTransactionResultSequence: AsyncSequence {
    typealias Element = VerificationResult<Transaction>
    let results: [VerificationResult<Transaction>]

    struct AsyncIterator: AsyncIteratorProtocol {
        var index = 0
        let results: [VerificationResult<Transaction>]

        mutating func next() async -> VerificationResult<Transaction>? {
            guard index < results.count else { return nil }
            let item = results[index]
            index += 1
            return item
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(results: results)
    }
}
