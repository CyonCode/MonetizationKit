import Foundation
import StoreKit

@available(macOS 12.0, iOS 15.0, *)
@MainActor
public final class MonetizationKit {
    public static let shared = MonetizationKit()
    public weak var delegate: MonetizationDelegate?
    public var eventListener: ((MonetizationEvent) -> Void)?

    private let engine: MonetizationEngine

    public init() {
        engine = MonetizationEngine(
            productLoader: RealProductLoader(),
            transactionStream: RealTransactionStream()
        )
        wireEngine()
    }

    init(productLoader: any ProductLoading, transactionStream: any TransactionStreaming) {
        engine = MonetizationEngine(
            productLoader: productLoader,
            transactionStream: transactionStream
        )
        wireEngine()
    }

    private func wireEngine() {
        engine.onEvent = { [weak self] event in
            self?.eventListener?(event)
        }
        engine.onEntitlementsChange = { [weak self] entitlements in
            guard let self else { return }
            self.delegate?.monetization(self, entitlementsDidChange: entitlements)
        }
    }

    public func configure(
        productIDs: [String],
        appAccountTokenProvider: (() -> UUID?)? = nil
    ) {
        engine.configure(
            productIDs: productIDs,
            appAccountTokenProvider: appAccountTokenProvider
        )
    }

    public func loadProducts() async {
        await engine.loadProducts()
    }

    @discardableResult
    public func purchase(_ product: Product) async throws -> MonetizationPurchaseOutcome {
        do {
            return try await engine.purchase(product)
        } catch {
            delegate?.monetization(self, didFailWith: error as? MonetizationError ?? .purchaseVerificationFailed(underlying: error))
            throw error
        }
    }

    public func restore() async throws {
        do {
            try await engine.restore()
        } catch {
            delegate?.monetization(self, didFailWith: error as? MonetizationError ?? .purchaseVerificationFailed(underlying: error))
            throw error
        }
    }

    public func refreshEntitlements() async {
        await engine.refreshEntitlements()
    }

    public var products: [Product] {
        engine.products
    }

    public var activeEntitlements: Set<String> {
        engine.activeEntitlements
    }

    public var isSubscribed: Bool {
        engine.isSubscribed
    }
}
