import StoreKit

@available(macOS 12.0, iOS 15.0, *)
@MainActor
final class ProductCatalog {
    private let productLoader: any ProductLoading
    private var loadedIDs: Set<String>?
    private(set) var products: [Product] = []

    init(productLoader: any ProductLoading) {
        self.productLoader = productLoader
    }

    func load(productIDs: [String]) async {
        let requested = Set(productIDs)
        guard requested != loadedIDs else { return }

        do {
            let loaded = try await productLoader.loadProducts(productIDs: productIDs)
            products = loaded.sorted { $0.price < $1.price }
            loadedIDs = requested
            MonetizationLog.info("Loaded \(products.count) products")
        } catch {
            MonetizationLog.error("Failed to load products: \(error.localizedDescription)")
        }
    }
}
