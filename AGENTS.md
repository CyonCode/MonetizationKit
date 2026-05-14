# AGENTS.md — MonetizationKit

## Module boundaries

| File | Visibility | Purpose |
|---|---|---|
| `MonetizationKit.swift` | public | `@MainActor` facade singleton + configure/purchase/restore/loadProducts/refreshEntitlements |
| `MonetizationDelegate.swift` | public | Delegate protocol, `MonetizationError`, `MonetizationPurchaseOutcome` |
| `MonetizationEvent.swift` | public | 11-case enum with `.name` and `.properties` |
| `MonetizationEngine.swift` | internal | `@MainActor` orchestrator: catalog, observer, purchase/restore flows |
| `TransactionObserver.swift` | internal | `@MainActor` listener for `Transaction.updates`, computes entitlements |
| `ProductCatalog.swift` | internal | `@MainActor` product loader + cache (`ProductLoading` protocol) |
| `MonetizationConfig.swift` | internal | `productIDs` + `appAccountTokenProvider` + `requiresAppAccountToken` |
| `Internal/ProductLoading.swift` | internal | Protocol wrapping `Product.products(for:)` + `RealProductLoader` |
| `Internal/TransactionStreaming.swift` | internal | Protocol wrapping `Transaction.updates`/`currentEntitlements` + `RealTransactionStream` |
| `Internal/AnyTransactionStream.swift` | internal | Type erasure for `TransactionStreaming` (factory pattern, multi-iteration safe) |
| `Internal/PurchaseClient.swift` | internal | Protocol wrapping `Product.purchase(options:)` + `RealPurchaseClient` — abstracts the only StoreKit call site that can't be mocked otherwise |
| `Internal/MonetizationLog.swift` | internal | `OSLog` wrapper (never `print`) |

## Concurrency model

All mutating state lives on the main actor:

- `MonetizationKit` (facade), `MonetizationEngine`, `TransactionObserver`, `ProductCatalog` — all `@MainActor`.
- The background listener task in `TransactionObserver.startListening()` runs as `Task { @MainActor [weak self] in ... }` so even the `Transaction.updates` consumer is main-thread.
- Delegate callbacks (`entitlementsDidChange`, `didFailWith`) and the `eventListener` closure are invoked on the main actor.
- Zero `@unchecked Sendable` in production code as of 0.2.0.

If you spawn a `Task` from outside that needs to call `MonetizationKit.shared`, wrap in `Task { @MainActor in ... }`.

## Why protocol-driven

`ProductLoading`, `TransactionStreaming`, and `PurchaseClient` wrap StoreKit 2 APIs behind protocols. Tests inject `MockProductLoader`, `MockTransactionStream`, and `MockPurchaseClient` instead of requiring a StoreKit testing environment. This matches AttributionKit's pattern and allows full unit test coverage of purchase/restore/entitlement flows without the `StoreKitTest` framework (which requires Xcode test targets, not SPM).

`PurchaseClient` was added in 0.2.0 specifically to cover the `Product.purchase(options:)` code path that could not be tested in 0.1.0.

## IDFV bridge to AttributionKit

The single most important design decision: this SDK does NOT import AttributionKit. Instead, the host wires both kits together at runtime:

1. Host calls `AttributionKit.shared.configure(...)` → server records `Attribution.idfv`.
2. Host calls `MonetizationKit.shared.configure(productIDs: [...], appAccountTokenProvider: { UIDevice.current.identifierForVendor }, requiresAppAccountToken: true)`.
3. Every `purchase(...)` inserts `.appAccountToken(IDFV)` into the StoreKit purchase options.
4. Apple's ASSN V2 webhook carries that `appAccountToken` to the Attribution server, which joins it back to `Attribution.idfv`.

With `requiresAppAccountToken: true`, the SDK throws `.missingAppAccountToken` if IDFV is nil at purchase time — preventing the silent-unjoinable-revenue failure mode.

## Test invocation

```bash
swift test
```

All tests use Swift Testing (`import Testing`, `@Test`, `@Suite`, `#expect`).

## Future work

- ASSN V2 server endpoint coordination (out of scope for client SDK).
- Offer code redemption support.
- Win-back offer handling.
- Subscription status check via `AppStore.sync()` + status mapping.
- Event semantics improvements (deferred to 0.3.0): expose `recordPaywallView(placement:)`, emit `subscriptionExpired` on actual expiration, branch `subscriptionRenewed` by product type (renewal vs receipt re-validation), distinguish `restore_success` from "sync OK but nothing restored".
