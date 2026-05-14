import StoreKit

@available(macOS 12.0, iOS 15.0, *)
protocol TransactionStreaming: Sendable {
    associatedtype UpdateSequence: AsyncSequence where UpdateSequence.Element == VerificationResult<Transaction>
    associatedtype EntitlementSequence: AsyncSequence where EntitlementSequence.Element == VerificationResult<Transaction>

    var updates: UpdateSequence { get }
    var currentEntitlements: EntitlementSequence { get }
}

@available(macOS 12.0, iOS 15.0, *)
struct RealTransactionStream: TransactionStreaming {
    typealias UpdateSequence = Transaction.Transactions
    typealias EntitlementSequence = Transaction.Transactions

    var updates: Transaction.Transactions {
        Transaction.updates
    }

    var currentEntitlements: Transaction.Transactions {
        Transaction.currentEntitlements
    }
}
