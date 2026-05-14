import Testing
@testable import MonetizationKit

@Suite("MonetizationEvent")
struct MonetizationEventTests {

    // MARK: - .name

    @Test("paywallView name")
    func paywallViewName() {
        let event = MonetizationEvent.paywallView(placement: "main_paywall")
        #expect(event.name == "paywall_view")
    }

    @Test("purchaseInitiated name")
    func purchaseInitiatedName() {
        let event = MonetizationEvent.purchaseInitiated(productID: "pro_monthly")
        #expect(event.name == "purchase_initiated")
    }

    @Test("purchaseSuccess name")
    func purchaseSuccessName() {
        let event = MonetizationEvent.purchaseSuccess(
            productID: "pro_monthly",
            transactionID: 1234567890,
            isTrial: false
        )
        #expect(event.name == "purchase_success")
    }

    @Test("purchaseCancelled name")
    func purchaseCancelledName() {
        let event = MonetizationEvent.purchaseCancelled(productID: "pro_monthly")
        #expect(event.name == "purchase_cancelled")
    }

    @Test("purchaseFailed name")
    func purchaseFailedName() {
        let event = MonetizationEvent.purchaseFailed(
            productID: "pro_monthly",
            error: MonetizationError.storeKitUnavailable
        )
        #expect(event.name == "purchase_failed")
    }

    @Test("restoreInitiated name")
    func restoreInitiatedName() {
        let event = MonetizationEvent.restoreInitiated
        #expect(event.name == "restore_initiated")
    }

    @Test("restoreSuccess name")
    func restoreSuccessName() {
        let event = MonetizationEvent.restoreSuccess(restoredProductIDs: ["pro_monthly"])
        #expect(event.name == "restore_success")
    }

    @Test("restoreFailed name")
    func restoreFailedName() {
        let event = MonetizationEvent.restoreFailed(
            error: MonetizationError.storeKitUnavailable
        )
        #expect(event.name == "restore_failed")
    }

    @Test("subscriptionRenewed name")
    func subscriptionRenewedName() {
        let event = MonetizationEvent.subscriptionRenewed(
            productID: "pro_monthly",
            transactionID: 9876543210
        )
        #expect(event.name == "subscription_renewed")
    }

    @Test("subscriptionExpired name")
    func subscriptionExpiredName() {
        let event = MonetizationEvent.subscriptionExpired(productID: "pro_monthly")
        #expect(event.name == "subscription_expired")
    }

    @Test("subscriptionRevoked name")
    func subscriptionRevokedName() {
        let event = MonetizationEvent.subscriptionRevoked(
            productID: "pro_monthly",
            reason: "refund"
        )
        #expect(event.name == "subscription_revoked")
    }

    // MARK: - .properties

    @Test("paywallView properties")
    func paywallViewProperties() {
        let event = MonetizationEvent.paywallView(placement: "main_paywall")
        let props = event.properties
        #expect(props["placement"] as? String == "main_paywall")
        #expect(props.count == 1)
    }

    @Test("purchaseInitiated properties")
    func purchaseInitiatedProperties() {
        let event = MonetizationEvent.purchaseInitiated(productID: "pro_monthly")
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props.count == 1)
    }

    @Test("purchaseSuccess properties")
    func purchaseSuccessProperties() {
        let event = MonetizationEvent.purchaseSuccess(
            productID: "pro_monthly",
            transactionID: 1234567890,
            isTrial: true
        )
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props["transaction_id"] as? String == "1234567890")
        #expect(props["is_trial"] as? Bool == true)
        #expect(props.count == 3)
    }

    @Test("purchaseCancelled properties")
    func purchaseCancelledProperties() {
        let event = MonetizationEvent.purchaseCancelled(productID: "pro_monthly")
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props.count == 1)
    }

    @Test("purchaseFailed properties")
    func purchaseFailedProperties() {
        let event = MonetizationEvent.purchaseFailed(
            productID: "pro_monthly",
            error: MonetizationError.storeKitUnavailable
        )
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props["error_message"] as? String != nil)
        #expect(props.count == 2)
    }

    @Test("restoreInitiated properties — empty dict")
    func restoreInitiatedProperties() {
        let event = MonetizationEvent.restoreInitiated
        #expect(event.properties.isEmpty)
    }

    @Test("restoreSuccess properties — sorted array")
    func restoreSuccessProperties() {
        let event = MonetizationEvent.restoreSuccess(
            restoredProductIDs: ["pro_yearly", "pro_monthly", "basic"]
        )
        let props = event.properties
        let ids = props["restored_product_ids"] as? [String]
        #expect(ids == ["basic", "pro_monthly", "pro_yearly"])
        #expect(props.count == 1)
    }

    @Test("restoreFailed properties")
    func restoreFailedProperties() {
        let event = MonetizationEvent.restoreFailed(
            error: MonetizationError.storeKitUnavailable
        )
        let props = event.properties
        #expect(props["error_message"] as? String != nil)
        #expect(props.count == 1)
    }

    @Test("subscriptionRenewed properties")
    func subscriptionRenewedProperties() {
        let event = MonetizationEvent.subscriptionRenewed(
            productID: "pro_monthly",
            transactionID: 9876543210
        )
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props["transaction_id"] as? String == "9876543210")
        #expect(props.count == 2)
    }

    @Test("subscriptionExpired properties")
    func subscriptionExpiredProperties() {
        let event = MonetizationEvent.subscriptionExpired(productID: "pro_monthly")
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props.count == 1)
    }

    @Test("subscriptionRevoked properties with reason")
    func subscriptionRevokedPropertiesWithReason() {
        let event = MonetizationEvent.subscriptionRevoked(
            productID: "pro_monthly",
            reason: "refund"
        )
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props["reason"] as? String == "refund")
        #expect(props.count == 2)
    }

    @Test("subscriptionRevoked properties without reason — reason key omitted")
    func subscriptionRevokedPropertiesWithoutReason() {
        let event = MonetizationEvent.subscriptionRevoked(
            productID: "pro_monthly",
            reason: nil
        )
        let props = event.properties
        #expect(props["product_id"] as? String == "pro_monthly")
        #expect(props["reason"] == nil)
        #expect(props.count == 1)
    }
}
