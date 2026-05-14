# AGENTS.md — MonetizationKit

## Module boundaries

| File | Visibility | Purpose |
|---|---|---|
| `MonetizationKit.swift` | public | Facade singleton + configure/purchase/restore/loadProducts/refreshEntitlements |
| `MonetizationDelegate.swift` | public | Delegate protocol, MonetizationError, MonetizationPurchaseOutcome |
| `MonetizationEvent.swift` | public | 11-case enum with .name and .properties |
| `EnvironmentSupport.swift` | public | SwiftUI EnvironmentValues extension |
| `MonetizationEngine.swift` | internal | Orchestrates catalog, observer, purchase/restore flows |
| `TransactionObserver.swift` | internal | Listens to Transaction.updates, computes entitlements |
| `ProductCatalog.swift` | internal | Loads + caches products via ProductLoading protocol |
| `Internal/ProductLoading.swift` | internal | Protocol wrapping Product.products(for:) |
| `Internal/TransactionStreaming.swift` | internal | Protocol wrapping Transaction.updates/currentEntitlements |
| `Internal/AnyTransactionStream.swift` | internal | Type erasure for TransactionStreaming |
| `Internal/MonetizationLog.swift` | internal | OSLog wrapper (never print) |
| `MonetizationConfig.swift` | internal | Stores productIDs + appAccountTokenProvider |

## Why protocol-driven

`ProductLoading` and `TransactionStreaming` wrap StoreKit 2 APIs behind protocols. Tests inject `MockProductLoader` and `MockTransactionStream` instead of requiring a StoreKit testing environment. This matches AttributionKit's pattern and allows full unit test coverage without `StoreKitTest` framework (which requires Xcode test targets, not SPM).

## Test invocation

```bash
swift test
```

All tests use Swift Testing (`import Testing`, `@Test`, `@Suite`, `#expect`).

## Known limitations

- `TransactionObserver` and `MonetizationEngine` are generic over `TransactionStreaming` to enable mocking; the facade type-erases via `AnyTransactionStream`.
- `MonetizationKit` is `@MainActor` — all public API must be called from the main actor.
- `@available(macOS 12.0, iOS 15.0, *)` required on most types due to StoreKit 2 availability. Package targets iOS 17+ but SPM builds for macOS host.
- SwiftUI `EnvironmentSupport` requires iOS 17+ for modern `EnvironmentKey` pattern.

## Future work

- ASSN V2 server endpoint coordination (out of scope for client SDK)
- Offer code redemption support
- Win-back offer handling
- Subscription status check via AppStore.sync() + status mapping
- **Swift 6 strict concurrency migration:** `ProductCatalog`, `TransactionObserver`, and `MonetizationEngine` use `@unchecked Sendable` because they are reached only through the `@MainActor` facade. Migrate them to `@MainActor` (catalog/engine) and an `actor` (observer, due to background transaction loop) when adopting Swift 6 strict mode.
