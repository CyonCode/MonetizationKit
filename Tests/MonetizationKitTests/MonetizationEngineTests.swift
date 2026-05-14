import Foundation
import Testing
@testable import MonetizationKit

@Suite("MonetizationEngine")
struct MonetizationEngineTests {

    @Test("configure stores config")
    func configureStoresConfig() {
        let loader = MockProductLoader()
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )

        engine.configure(productIDs: ["a", "b"], appAccountTokenProvider: nil)

        #expect(engine.isConfigured)
    }

    @Test("products empty before configure")
    func productsEmptyBeforeConfigure() {
        let loader = MockProductLoader()
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )

        #expect(engine.products.isEmpty)
    }

    @Test("activeEntitlements empty initially")
    func activeEntitlementsEmpty() {
        let loader = MockProductLoader()
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )

        #expect(engine.activeEntitlements.isEmpty)
    }

    @Test("isSubscribed false when no entitlements")
    func isSubscribedFalse() {
        let loader = MockProductLoader()
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )

        #expect(!engine.isSubscribed)
    }

    @Test("loadProducts calls catalog")
    func loadProductsCallsCatalog() async {
        let loader = MockProductLoader()
        loader.loadResult = .success([])
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )
        engine.configure(productIDs: ["x"], appAccountTokenProvider: nil)

        await engine.loadProducts()

        #expect(loader.loadCallCount == 1)
    }

    @Test("configure starts observer listening")
    func configureStartsObserver() {
        let loader = MockProductLoader()
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )

        engine.configure(productIDs: ["x"], appAccountTokenProvider: nil)

        #expect(engine.isObserverListening)
    }

    @Test("events captured via callback")
    func eventsCaptured() {
        let loader = MockProductLoader()
        let stream = MockTransactionStream()
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream
        )

        var capturedEvents: [MonetizationEvent] = []
        engine.onEvent = { capturedEvents.append($0) }

        engine.configure(productIDs: ["x"], appAccountTokenProvider: nil)

        // configure should not emit events
        #expect(capturedEvents.isEmpty)
    }
}
