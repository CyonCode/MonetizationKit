import Foundation

// MARK: - Errors

/// Errors thrown by MonetizationKit public APIs.
public enum MonetizationError: Error, Equatable {

    /// Product loading from the App Store failed.
    case productsLoadFailed(underlying: Error)

    /// Transaction verification failed after purchase.
    case purchaseVerificationFailed(underlying: Error)

    /// StoreKit is unavailable (e.g. managed devices, restricted).
    case storeKitUnavailable

    /// `configure(requiresAppAccountToken: true)` was set but the provider
    /// returned `nil` at purchase time. The purchase is aborted before
    /// hitting StoreKit because the AttributionKit bridge would silently
    /// drop the join key, producing an unjoinable revenue record.
    case missingAppAccountToken

    public static func == (lhs: MonetizationError, rhs: MonetizationError) -> Bool {
        switch (lhs, rhs) {
        case (.storeKitUnavailable, .storeKitUnavailable):
            return true
        case (.missingAppAccountToken, .missingAppAccountToken):
            return true
        case let (.productsLoadFailed(l), .productsLoadFailed(r)):
            return (l as NSError) == (r as NSError)
        case let (.purchaseVerificationFailed(l), .purchaseVerificationFailed(r)):
            return (l as NSError) == (r as NSError)
        default:
            return false
        }
    }
}

// MARK: - Purchase Outcome

/// Result of a purchase attempt.
public enum MonetizationPurchaseOutcome {
    /// Purchase completed successfully.
    case success(transactionID: UInt64)
    /// User cancelled the purchase.
    case userCancelled
    /// Purchase is pending (e.g. Ask to Buy).
    case pending
}

// MARK: - Delegate

/// Callback protocol for entitlement changes and errors.
@available(macOS 12.0, iOS 15.0, *)
public protocol MonetizationDelegate: AnyObject {

    /// Called when the set of active entitlements changes.
    func monetization(_ kit: MonetizationKit, entitlementsDidChange entitlements: Set<String>)

    /// Called when a non-fatal error occurs.
    func monetization(_ kit: MonetizationKit, didFailWith error: MonetizationError)
}

@available(macOS 12.0, iOS 15.0, *)
public extension MonetizationDelegate {
    /// Default no-op implementation for error reporting.
    func monetization(_ kit: MonetizationKit, didFailWith error: MonetizationError) {}
}
