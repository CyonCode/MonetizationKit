import StoreKit

@available(macOS 12.0, iOS 15.0, *)
protocol ProductLoading: Sendable {
    func loadProducts(productIDs: [String]) async throws -> [Product]
}

@available(macOS 12.0, iOS 15.0, *)
struct RealProductLoader: ProductLoading {
    func loadProducts(productIDs: [String]) async throws -> [Product] {
        try await Product.products(for: productIDs)
    }
}
