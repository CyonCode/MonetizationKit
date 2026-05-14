import Foundation
import Testing
import StoreKit
@testable import MonetizationKit

@Suite("ProductCatalog")
@MainActor
struct ProductCatalogTests {

    @Test("load calls loader with correct product IDs")
    func loadCallsLoader() async {
        let loader = MockProductLoader()
        loader.loadResult = .success([])
        let catalog = ProductCatalog(productLoader: loader)

        await catalog.load(productIDs: ["a", "b"])

        #expect(loader.loadCallCount == 1)
        #expect(loader.lastRequestedIDs == ["a", "b"])
    }

    @Test("load caches products — second call does not reload")
    func loadCaches() async {
        let loader = MockProductLoader()
        loader.loadResult = .success([])
        let catalog = ProductCatalog(productLoader: loader)

        await catalog.load(productIDs: ["x"])
        await catalog.load(productIDs: ["x"])

        #expect(loader.loadCallCount == 1)
    }

    @Test("load reloads when product IDs change")
    func loadReloadsOnIDChange() async {
        let loader = MockProductLoader()
        loader.loadResult = .success([])
        let catalog = ProductCatalog(productLoader: loader)

        await catalog.load(productIDs: ["a"])
        await catalog.load(productIDs: ["b"])

        #expect(loader.loadCallCount == 2)
    }

    @Test("products empty before first load")
    func productsEmptyBeforeLoad() {
        let loader = MockProductLoader()
        let catalog = ProductCatalog(productLoader: loader)

        #expect(catalog.products.isEmpty)
    }

    @Test("load swallows error and logs — products stay empty")
    func loadSwallowsError() async {
        let loader = MockProductLoader()
        loader.loadResult = .failure(MonetizationError.storeKitUnavailable)
        let catalog = ProductCatalog(productLoader: loader)

        await catalog.load(productIDs: ["x"])

        #expect(catalog.products.isEmpty)
        #expect(loader.loadCallCount == 1)
    }
}
