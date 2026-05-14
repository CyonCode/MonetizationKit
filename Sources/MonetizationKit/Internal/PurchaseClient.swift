import Foundation
import StoreKit

/// Typed result of a low-level purchase attempt.
///
/// Mirrors the four possible outcomes of `Product.purchase(options:)` but with
/// raw values that can be constructed in tests (unlike `StoreKit.Transaction`).
@available(macOS 12.0, iOS 15.0, *)
enum PurchaseClientOutcome: Sendable {
    case success(transactionID: UInt64, productID: String, isTrial: Bool)
    case unverified(underlying: Error)
    case userCancelled
    case pending
}

/// Abstracts `Product.purchase(options:)` so tests can inject outcomes without
/// needing to construct a real StoreKit `Product` or `Transaction`.
///
/// `productID` is passed instead of `Product` because tests cannot construct
/// `Product`. `RealPurchaseClient` resolves the product via the injected
/// `ProductCatalog`.
@available(macOS 12.0, iOS 15.0, *)
protocol PurchaseClient: Sendable {
    @MainActor
    func purchase(
        productID: String,
        options: Set<Product.PurchaseOption>,
        catalog: ProductCatalog
    ) async throws -> PurchaseClientOutcome
}

/// Real StoreKit-backed implementation.
@available(macOS 12.0, iOS 15.0, *)
struct RealPurchaseClient: PurchaseClient {
    @MainActor
    func purchase(
        productID: String,
        options: Set<Product.PurchaseOption>,
        catalog: ProductCatalog
    ) async throws -> PurchaseClientOutcome {
        guard let product = catalog.products.first(where: { $0.id == productID }) else {
            throw MonetizationError.productsLoadFailed(
                underlying: NSError(
                    domain: "MonetizationKit",
                    code: -10,
                    userInfo: [NSLocalizedDescriptionKey: "Product \(productID) not in catalog (call loadProducts first)"]
                )
            )
        }

        let result = try await product.purchase(options: options)
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return .success(
                    transactionID: transaction.id,
                    productID: transaction.productID,
                    isTrial: transaction.offerType == .introductory
                )
            case .unverified(_, let error):
                return .unverified(underlying: error)
            }
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }
}
