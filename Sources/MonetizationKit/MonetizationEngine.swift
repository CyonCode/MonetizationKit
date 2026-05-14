import Foundation
import StoreKit

@available(macOS 12.0, iOS 15.0, *)
// `@unchecked Sendable`: held exclusively by `MonetizationKit` (`@MainActor`); all
// mutating entry points are reached via that facade, so writes are main-thread serialized.
// Migrate to `@MainActor` together with collaborators when adopting Swift 6 strict mode.
final class MonetizationEngine: @unchecked Sendable {
    private let productCatalog: ProductCatalog
    private let observer: TransactionObserver<AnyTransactionStream>
    private var config: MonetizationConfig?

    var onEvent: ((MonetizationEvent) -> Void)?
    var onEntitlementsChange: ((Set<String>) -> Void)?

    var isConfigured: Bool { config != nil }
    var isObserverListening: Bool { observer.activeEntitlements.count >= 0 }
    var products: [Product] { productCatalog.products }
    var activeEntitlements: Set<String> { observer.activeEntitlements }
    var isSubscribed: Bool { !activeEntitlements.isEmpty }

    init(productLoader: any ProductLoading, transactionStream: any TransactionStreaming) {
        self.productCatalog = ProductCatalog(productLoader: productLoader)
        self.observer = TransactionObserver(transactionStream: AnyTransactionStream(transactionStream))

        observer.onEvent = { [weak self] event in
            self?.onEvent?(event)
        }
        observer.onEntitlementsChange = { [weak self] entitlements in
            self?.onEntitlementsChange?(entitlements)
        }
    }

    func configure(productIDs: [String], appAccountTokenProvider: (() -> UUID?)?) {
        config = MonetizationConfig(
            productIDs: productIDs,
            appAccountTokenProvider: appAccountTokenProvider
        )
        observer.startListening()
        MonetizationLog.info("Engine configured with \(productIDs.count) product IDs")
    }

    func loadProducts() async {
        guard let config else { return }
        await productCatalog.load(productIDs: config.productIDs)
    }

    func purchase(_ product: Product) async throws -> MonetizationPurchaseOutcome {
        onEvent?(.purchaseInitiated(productID: product.id))

        var options: Set<Product.PurchaseOption> = []
        if let uuid = config?.appAccountTokenProvider?() {
            options.insert(.appAccountToken(uuid))
        }

        do {
            let result = try await product.purchase(options: options)

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                onEvent?(.purchaseSuccess(
                    productID: product.id,
                    transactionID: transaction.id,
                    isTrial: transaction.offerType == .introductory
                ))
                return .success(transactionID: transaction.id)

            case .userCancelled:
                onEvent?(.purchaseCancelled(productID: product.id))
                return .userCancelled

            case .pending:
                return .pending

            @unknown default:
                return .pending
            }
        } catch {
            onEvent?(.purchaseFailed(productID: product.id, error: error))
            throw MonetizationError.purchaseVerificationFailed(underlying: error)
        }
    }

    func restore() async throws {
        onEvent?(.restoreInitiated)
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            onEvent?(.restoreSuccess(restoredProductIDs: activeEntitlements))
        } catch {
            onEvent?(.restoreFailed(error: error))
            throw error
        }
    }

    func refreshEntitlements() async {
        await observer.refreshEntitlements()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw MonetizationError.purchaseVerificationFailed(
                underlying: NSError(domain: "MonetizationKit", code: -1)
            )
        }
    }
}