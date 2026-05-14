import Foundation
import StoreKit
@testable import MonetizationKit

/// Test double for `PurchaseClient`. Records the last call's arguments and
/// returns a configurable outcome.
@available(macOS 12.0, iOS 15.0, *)
final class MockPurchaseClient: PurchaseClient, @unchecked Sendable {
    /// What `purchase(...)` should return / throw. Default: user cancellation.
    var nextResult: Result<PurchaseClientOutcome, Error> = .success(.userCancelled)

    /// Captured arguments from the most recent call.
    private(set) var callCount = 0
    private(set) var lastProductID: String?
    private(set) var lastOptions: Set<Product.PurchaseOption>?

    @MainActor
    func purchase(
        productID: String,
        options: Set<Product.PurchaseOption>,
        catalog: ProductCatalog
    ) async throws -> PurchaseClientOutcome {
        callCount += 1
        lastProductID = productID
        lastOptions = options
        return try nextResult.get()
    }
}
