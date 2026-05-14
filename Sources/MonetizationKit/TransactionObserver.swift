import StoreKit

@available(macOS 12.0, iOS 15.0, *)
// `@unchecked Sendable`: state is mutated from the background `Task` started in
// `startListening` AND from external `refreshEntitlements()` calls. Today both paths
// converge on the same instance owned by a `@MainActor` facade, so observed races are
// serialized in practice. Track in AGENTS.md to migrate to an `actor` under Swift 6.
final class TransactionObserver<Stream: TransactionStreaming>: @unchecked Sendable {
    private let transactionStream: Stream
    private var backgroundTask: Task<Void, Never>?

    var onEvent: ((MonetizationEvent) -> Void)?
    var onEntitlementsChange: ((Set<String>) -> Void)?

    private(set) var activeEntitlements: Set<String> = []

    init(transactionStream: Stream) {
        self.transactionStream = transactionStream
    }

    func startListening() {
        backgroundTask?.cancel()
        backgroundTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await result in self.transactionStream.updates {
                    await self.handleUpdate(result)
                }
            } catch {
                MonetizationLog.error("Transaction updates stream error: \(error.localizedDescription)")
            }
        }
        MonetizationLog.info("Transaction observer started")
    }

    func stopListening() {
        backgroundTask?.cancel()
        backgroundTask = nil
        MonetizationLog.info("Transaction observer stopped")
    }

    func refreshEntitlements() async {
        var newEntitlements: Set<String> = []

        do {
            for try await result in transactionStream.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if transaction.revocationDate != nil { continue }
                if let expiry = transaction.expirationDate, expiry < Date() { continue }
                newEntitlements.insert(transaction.productID)
            }
        } catch {
            MonetizationLog.error("Entitlements refresh error: \(error.localizedDescription)")
        }

        if newEntitlements != activeEntitlements {
            activeEntitlements = newEntitlements
            onEntitlementsChange?(newEntitlements)
        }
    }

    private func handleUpdate(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            MonetizationLog.error("Unverified transaction update ignored")
            return
        }

        await transaction.finish()

        if transaction.revocationDate != nil {
            onEvent?(.subscriptionRevoked(
                productID: transaction.productID,
                reason: nil
            ))
        } else {
            onEvent?(.subscriptionRenewed(
                productID: transaction.productID,
                transactionID: transaction.id
            ))
        }

        await refreshEntitlements()
    }
}