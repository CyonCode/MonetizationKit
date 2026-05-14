import Foundation

/// Events emitted by MonetizationKit for analytics / logging.
public enum MonetizationEvent {

    /// A paywall was shown to the user.
    case paywallView(placement: String)

    /// User initiated a purchase flow.
    case purchaseInitiated(productID: String)

    /// Purchase completed and verified successfully.
    case purchaseSuccess(productID: String, transactionID: UInt64, isTrial: Bool)

    /// User cancelled the purchase.
    case purchaseCancelled(productID: String)

    /// Purchase failed with an error.
    case purchaseFailed(productID: String, error: Error)

    /// Restore purchases was initiated.
    case restoreInitiated

    /// Restore completed with a set of restored product IDs.
    case restoreSuccess(restoredProductIDs: Set<String>)

    /// Restore failed with an error.
    case restoreFailed(error: Error)

    /// A subscription automatically renewed.
    case subscriptionRenewed(productID: String, transactionID: UInt64)

    /// A subscription expired.
    case subscriptionExpired(productID: String)

    /// A subscription was revoked (e.g. refund).
    case subscriptionRevoked(productID: String, reason: String?)
}

// MARK: - Analytics helpers

public extension MonetizationEvent {

    /// Snake_case event name for analytics.
    var name: String {
        switch self {
        case .paywallView:          return "paywall_view"
        case .purchaseInitiated:    return "purchase_initiated"
        case .purchaseSuccess:      return "purchase_success"
        case .purchaseCancelled:    return "purchase_cancelled"
        case .purchaseFailed:       return "purchase_failed"
        case .restoreInitiated:     return "restore_initiated"
        case .restoreSuccess:       return "restore_success"
        case .restoreFailed:        return "restore_failed"
        case .subscriptionRenewed:  return "subscription_renewed"
        case .subscriptionExpired:  return "subscription_expired"
        case .subscriptionRevoked:  return "subscription_revoked"
        }
    }

    /// Snake_case properties dictionary for analytics.
    var properties: [String: Any] {
        switch self {
        case .paywallView(let placement):
            return ["placement": placement]

        case .purchaseInitiated(let productID):
            return ["product_id": productID]

        case .purchaseSuccess(let productID, let transactionID, let isTrial):
            return [
                "product_id": productID,
                "transaction_id": String(transactionID),
                "is_trial": isTrial,
            ]

        case .purchaseCancelled(let productID):
            return ["product_id": productID]

        case .purchaseFailed(let productID, let error):
            return [
                "product_id": productID,
                "error_message": error.localizedDescription,
            ]

        case .restoreInitiated:
            return [:]

        case .restoreSuccess(let restoredProductIDs):
            return ["restored_product_ids": restoredProductIDs.sorted()]

        case .restoreFailed(let error):
            return ["error_message": error.localizedDescription]

        case .subscriptionRenewed(let productID, let transactionID):
            return [
                "product_id": productID,
                "transaction_id": String(transactionID),
            ]

        case .subscriptionExpired(let productID):
            return ["product_id": productID]

        case .subscriptionRevoked(let productID, let reason):
            var props: [String: Any] = ["product_id": productID]
            if let reason {
                props["reason"] = reason
            }
            return props
        }
    }
}
