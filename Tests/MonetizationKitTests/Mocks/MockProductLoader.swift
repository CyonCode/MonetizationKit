import StoreKit
@testable import MonetizationKit

final class MockProductLoader: ProductLoading, @unchecked Sendable {
    var loadResult: Result<[Product], Error> = .success([])
    private(set) var loadCallCount = 0
    var lastRequestedIDs: [String]?

    func loadProducts(productIDs: [String]) async throws -> [Product] {
        loadCallCount += 1
        lastRequestedIDs = productIDs
        return try loadResult.get()
    }
}
