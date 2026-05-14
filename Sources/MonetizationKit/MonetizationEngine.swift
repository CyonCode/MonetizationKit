import Foundation
import StoreKit

@available(macOS 12.0, iOS 15.0, *)
@MainActor
final class MonetizationEngine {
    private let productCatalog: ProductCatalog
    private let observer: TransactionObserver<AnyTransactionStream>
    private let purchaseClient: any PurchaseClient
    private var config: MonetizationConfig?

    var onEvent: ((MonetizationEvent) -> Void)?
    var onEntitlementsChange: ((Set<String>) -> Void)?

    var isConfigured: Bool { config != nil }
    var products: [Product] { productCatalog.products }
    var activeEntitlements: Set<String> { observer.activeEntitlements }
    var isSubscribed: Bool { !activeEntitlements.isEmpty }

    init(
        productLoader: any ProductLoading,
        transactionStream: any TransactionStreaming,
        purchaseClient: any PurchaseClient = RealPurchaseClient()
    ) {
        self.productCatalog = ProductCatalog(productLoader: productLoader)
        self.observer = TransactionObserver(transactionStream: AnyTransactionStream(transactionStream))
        self.purchaseClient = purchaseClient

        observer.onEvent = { [weak self] event in self?.onEvent?(event) }
        observer.onEntitlementsChange = { [weak self] entitlements in self?.onEntitlementsChange?(entitlements) }
    }

    func configure(
        productIDs: [String],
        appAccountTokenProvider: (() -> UUID?)? = nil,
        requiresAppAccountToken: Bool = false
    ) {
        config = MonetizationConfig(
            productIDs: productIDs,
            appAccountTokenProvider: appAccountTokenProvider,
            requiresAppAccountToken: requiresAppAccountToken
        )
        observer.startListening()
        MonetizationLog.info("Engine configured with \(productIDs.count) product IDs")
    }

    func loadProducts() async {
        guard let config else { return }
        await productCatalog.load(productIDs: config.productIDs)
    }

    func purchase(productID: String) async throws -> MonetizationPurchaseOutcome {
        onEvent?(.purchaseInitiated(productID: productID))

        var options: Set<Product.PurchaseOption> = []
        if let token = config?.appAccountTokenProvider?() {
            options.insert(.appAccountToken(token))
        } else if config?.requiresAppAccountToken == true {
            let error = MonetizationError.missingAppAccountToken
            onEvent?(.purchaseFailed(productID: productID, error: error))
            throw error
        }

        do {
            let outcome = try await purchaseClient.purchase(
                productID: productID,
                options: options,
                catalog: productCatalog
            )
            switch outcome {
            case .success(let txID, let pID, let isTrial):
                await refreshEntitlements()
                onEvent?(.purchaseSuccess(productID: pID, transactionID: txID, isTrial: isTrial))
                return .success(transactionID: txID)
            case .unverified(let error):
                let wrapped = MonetizationError.purchaseVerificationFailed(underlying: error)
                onEvent?(.purchaseFailed(productID: productID, error: wrapped))
                throw wrapped
            case .userCancelled:
                onEvent?(.purchaseCancelled(productID: productID))
                return .userCancelled
            case .pending:
                return .pending
            }
        } catch let error as MonetizationError {
            throw error
        } catch {
            onEvent?(.purchaseFailed(productID: productID, error: error))
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
}
