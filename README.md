# MonetizationKit

Native StoreKit 2 subscription SDK for iOS. Handles product loading, purchase, restore, entitlement tracking, and analytics event emission — all with zero external dependencies. Pairs with [AttributionKit](https://github.com/CyonCode/AttributionKit) via IDFV/appAccountToken at the host layer for revenue attribution.

| | |
|---|---|
| **Platform** | iOS 17+ |
| **Swift** | 5.9 |
| **Dependencies** | none |

---

## Install

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/CyonCode/MonetizationKit", from: "0.2.0"),
],
targets: [
    .target(name: "YourApp", dependencies: ["MonetizationKit"]),
]
```

## Quick start

```swift
import MonetizationKit
import OSLog

let log = Logger(subsystem: "com.yourapp", category: "monetization")

// At app launch (must run on the main actor; @main App.init is fine).
MonetizationKit.shared.configure(
    productIDs: ["pro_monthly", "pro_yearly"],
    appAccountTokenProvider: { UIDevice.current.identifierForVendor },
    requiresAppAccountToken: true  // fail fast if IDFV is nil instead of silently breaking attribution
)
MonetizationKit.shared.delegate = self
MonetizationKit.shared.eventListener = { event in
    log.info("\(event.name) \(String(describing: event.properties))")
    // Forward to your analytics provider (PostHog/Mixpanel/Firebase/etc).
}
await MonetizationKit.shared.loadProducts()
```

---

## How revenue events join to attribution

AttributionKit records `Attribution.idfv` at install time. MonetizationKit passes the same IDFV as `appAccountToken` on every purchase. The server joins `Revenue.appAccountToken` to `Attribution.idfv`.

```
[Your App]                                              [Attribution Server]

AttributionKit.performAttributionIfNeeded()  →   Attribution.idfv = <IDFV>
                                                          ↕   (join key)
MonetizationKit.configure(                               Revenue.appAccountToken
  appAccountTokenProvider: { UIDevice.current             = <IDFV>
    .identifierForVendor },
  requiresAppAccountToken: true
)
```

If these two values don't match, revenue events are still recorded but tagged `attribution_source = 'unknown'` and you lose LTV-by-source resolution.

### `requiresAppAccountToken: true` (recommended)

`UIDevice.current.identifierForVendor` can return `nil` (very early launch, restored-from-backup edge cases). With `requiresAppAccountToken: true` the SDK throws `MonetizationError.missingAppAccountToken` instead of letting the purchase reach Apple without the join key. Without that flag, missing-IDFV purchases proceed silently and become permanently unjoinable on the server.

### Server-side: Apple App Store Server Notifications V2

```
POST /v1/webhook/appstore/<appId>
```

Register this endpoint in App Store Connect → App → App Store Server Notifications. The server decodes the JWS-signed notification, extracts `appAccountToken` (= IDFV) from the signed transaction info, and joins it to `Attribution.idfv`. Fall back to `originalTransactionId` for renewals after reinstall when IDFV has rotated.

---

## Event reference

| Event | Name | Properties |
|---|---|---|
| paywallView | `paywall_view` | `placement` |
| purchaseInitiated | `purchase_initiated` | `product_id` |
| purchaseSuccess | `purchase_success` | `product_id`, `transaction_id`, `is_trial` |
| purchaseCancelled | `purchase_cancelled` | `product_id` |
| purchaseFailed | `purchase_failed` | `product_id`, `error_message` |
| restoreInitiated | `restore_initiated` | — |
| restoreSuccess | `restore_success` | `restored_product_ids` (sorted) |
| restoreFailed | `restore_failed` | `error_message` |
| subscriptionRenewed | `subscription_renewed` | `product_id`, `transaction_id` |
| subscriptionExpired | `subscription_expired` | `product_id` |
| subscriptionRevoked | `subscription_revoked` | `product_id`, `reason?` |

All `transaction_id` values are strings (UInt64 serialized as decimal).

---

## Notes & gotchas

- **IDFV resets on app reinstall.** Renewals after reinstall produce a new appAccountToken that no longer matches the original Attribution.idfv. Server-side fallback: look up original attribution via `original_transaction_id`.
- **ATT prompt.** IDFV is available without ATT consent.
- **Sandbox vs Production.** Transaction.environment distinguishes them. Filter sandbox out of LTV queries.
- **Paywall is host responsibility.** MonetizationKit provides products and purchase API; the host app owns the paywall UI.
- **No A/B testing.** Price testing is out of scope; use App Store pricing or a server-side experiment framework.
- **Main actor.** All public APIs are `@MainActor`-isolated. Call them from the main actor (SwiftUI views, `@main App.init`, or `Task { @MainActor in ... }`).
- **Testing.** Inject `MockPurchaseClient` to drive purchase outcomes without StoreKit. See `Tests/MonetizationKitTests/Mocks/MockPurchaseClient.swift`.

## File map

```
MonetizationKit/
├── Sources/MonetizationKit/
│   ├── MonetizationKit.swift              # Public facade
│   ├── MonetizationDelegate.swift         # Protocol + errors + outcome
│   ├── MonetizationEvent.swift            # 11 analytics events
│   ├── MonetizationConfig.swift           # Internal config
│   ├── MonetizationEngine.swift           # Orchestrator
│   ├── TransactionObserver.swift          # Background transaction listener
│   ├── ProductCatalog.swift               # Product loading + cache
│   └── Internal/
│       ├── MonetizationLog.swift          # OSLog wrapper
│       ├── ProductLoading.swift           # Protocol + real impl
│       ├── TransactionStreaming.swift     # Protocol + real impl
│       ├── AnyTransactionStream.swift     # Type erasure (multi-iteration safe)
│       └── PurchaseClient.swift           # Protocol + real impl (mockable purchase)
├── Tests/MonetizationKitTests/
│   ├── MonetizationEventTests.swift
│   ├── MonetizationConfigTests.swift
│   ├── ProductCatalogTests.swift
│   ├── TransactionObserverTests.swift
│   ├── MonetizationEngineTests.swift
│   ├── MonetizationKitFacadeTests.swift
│   ├── AnyAsyncSequenceTests.swift
│   └── Mocks/
│       ├── MockProductLoader.swift
│       ├── MockTransactionStream.swift
│       └── MockPurchaseClient.swift
├── Examples/
│   └── PaywallIntegration.swift
├── Package.swift
├── README.md                              # ← you are here
├── AGENTS.md
└── docs/PROJECT_STATUS.md
```
