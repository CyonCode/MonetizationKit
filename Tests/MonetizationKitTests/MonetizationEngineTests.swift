import Foundation
import Testing
@testable import MonetizationKit

@Suite("MonetizationEngine")
@MainActor
struct MonetizationEngineTests {

    private func makeEngine(
        loader: MockProductLoader = MockProductLoader(),
        stream: MockTransactionStream = MockTransactionStream(),
        client: MockPurchaseClient = MockPurchaseClient()
    ) -> (MonetizationEngine, MockPurchaseClient) {
        let engine = MonetizationEngine(
            productLoader: loader,
            transactionStream: stream,
            purchaseClient: client
        )
        return (engine, client)
    }

    @Test("configure stores config")
    func configureStoresConfig() {
        let (engine, _) = makeEngine()
        engine.configure(productIDs: ["a", "b"])
        #expect(engine.isConfigured)
    }

    @Test("products empty before configure")
    func productsEmptyBeforeConfigure() {
        let (engine, _) = makeEngine()
        #expect(engine.products.isEmpty)
    }

    @Test("activeEntitlements empty initially")
    func activeEntitlementsEmpty() {
        let (engine, _) = makeEngine()
        #expect(engine.activeEntitlements.isEmpty)
    }

    @Test("isSubscribed false when no entitlements")
    func isSubscribedFalse() {
        let (engine, _) = makeEngine()
        #expect(!engine.isSubscribed)
    }

    @Test("loadProducts calls catalog")
    func loadProductsCallsCatalog() async {
        let loader = MockProductLoader()
        loader.loadResult = .success([])
        let (engine, _) = makeEngine(loader: loader)
        engine.configure(productIDs: ["x"])
        await engine.loadProducts()
        #expect(loader.loadCallCount == 1)
    }

    @Test("events captured via callback")
    func eventsCaptured() {
        let (engine, _) = makeEngine()
        var capturedEvents: [MonetizationEvent] = []
        engine.onEvent = { capturedEvents.append($0) }
        engine.configure(productIDs: ["x"])
        #expect(capturedEvents.isEmpty)
    }

    // MARK: - Purchase flow (via injected PurchaseClient)

    @Test("purchase success emits purchaseInitiated then purchaseSuccess and returns transactionID")
    func purchaseSuccessFlow() async throws {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.success(transactionID: 42, productID: "x", isTrial: false))
        engine.configure(productIDs: ["x"])
        var events: [MonetizationEvent] = []
        engine.onEvent = { events.append($0) }

        let outcome = try await engine.purchase(productID: "x")

        guard case .success(let txID) = outcome else {
            Issue.record("Expected success, got \(outcome)")
            return
        }
        #expect(txID == 42)
        #expect(events.map(\.name) == ["purchase_initiated", "purchase_success"])
    }

    @Test("purchase userCancelled emits purchaseCancelled and returns .userCancelled")
    func purchaseUserCancelled() async throws {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.userCancelled)
        engine.configure(productIDs: ["x"])
        var events: [MonetizationEvent] = []
        engine.onEvent = { events.append($0) }

        let outcome = try await engine.purchase(productID: "x")

        guard case .userCancelled = outcome else {
            Issue.record("Expected userCancelled, got \(outcome)")
            return
        }
        #expect(events.last?.name == "purchase_cancelled")
    }

    @Test("purchase pending returns .pending without throwing or emitting failure")
    func purchasePending() async throws {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.pending)
        engine.configure(productIDs: ["x"])
        var events: [MonetizationEvent] = []
        engine.onEvent = { events.append($0) }

        let outcome = try await engine.purchase(productID: "x")

        guard case .pending = outcome else {
            Issue.record("Expected pending, got \(outcome)")
            return
        }
        #expect(!events.contains(where: { $0.name == "purchase_failed" }))
    }

    @Test("purchase unverified throws purchaseVerificationFailed and emits purchaseFailed")
    func purchaseUnverified() async {
        let (engine, client) = makeEngine()
        let underlying = NSError(domain: "test", code: 99)
        client.nextResult = .success(.unverified(underlying: underlying))
        engine.configure(productIDs: ["x"])
        var events: [MonetizationEvent] = []
        engine.onEvent = { events.append($0) }

        await #expect(throws: MonetizationError.purchaseVerificationFailed(underlying: underlying)) {
            try await engine.purchase(productID: "x")
        }
        #expect(events.last?.name == "purchase_failed")
    }

    @Test("purchase passes appAccountToken option when provider returns UUID")
    func purchasePassesAppAccountToken() async throws {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.success(transactionID: 1, productID: "x", isTrial: false))
        let uuid = UUID()
        engine.configure(productIDs: ["x"], appAccountTokenProvider: { uuid })

        _ = try? await engine.purchase(productID: "x")

        #expect(client.lastOptions?.contains(.appAccountToken(uuid)) == true)
    }

    @Test("purchase omits appAccountToken when provider is nil (optional mode)")
    func purchaseNoTokenWhenOptional() async throws {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.success(transactionID: 1, productID: "x", isTrial: false))
        engine.configure(productIDs: ["x"], appAccountTokenProvider: { nil })

        _ = try? await engine.purchase(productID: "x")

        #expect(client.lastOptions?.isEmpty == true)
    }

    @Test("purchase throws missingAppAccountToken when required but provider returns nil")
    func purchaseRequiresTokenButGotNil() async {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.success(transactionID: 1, productID: "x", isTrial: false))
        engine.configure(
            productIDs: ["x"],
            appAccountTokenProvider: { nil },
            requiresAppAccountToken: true
        )
        var events: [MonetizationEvent] = []
        engine.onEvent = { events.append($0) }

        await #expect(throws: MonetizationError.missingAppAccountToken) {
            try await engine.purchase(productID: "x")
        }
        #expect(events.contains(where: { $0.name == "purchase_failed" }))
        #expect(client.callCount == 0)
    }

    @Test("purchase proceeds when required and provider returns UUID")
    func purchaseRequiredAndProvided() async throws {
        let (engine, client) = makeEngine()
        client.nextResult = .success(.success(transactionID: 7, productID: "x", isTrial: false))
        let uuid = UUID()
        engine.configure(
            productIDs: ["x"],
            appAccountTokenProvider: { uuid },
            requiresAppAccountToken: true
        )

        let outcome = try await engine.purchase(productID: "x")

        guard case .success(let txID) = outcome else {
            Issue.record("Expected success, got \(outcome)")
            return
        }
        #expect(txID == 7)
        #expect(client.lastOptions?.contains(.appAccountToken(uuid)) == true)
    }
}
