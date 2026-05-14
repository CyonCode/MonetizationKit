//
//  PaywallIntegration.swift
//  MonetizationKit / Examples
//
//  Reference integration showing how MonetizationKit and AttributionKit
//  work together. The join key is IDFV:
//
//    Attribution.idfv  ←  AttributionKit auto-collects this
//                       ↕  (server-side join at webhook insert time)
//    Revenue.appAccountToken  ←  MonetizationKit passes this on every purchase
//
//  Usage: call `MonetizationBootstrap.setup()` once at app launch, before
//  any purchase or paywall flow runs.
//

import Foundation
import UIKit
import AttributionKit
import MonetizationKit

enum MonetizationBootstrap {

    // MARK: - Public entry point

    /// Single entry point. Call from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
    /// or your `@main App` initializer.
    static func setup() {
        configureAttributionKit()
        configureMonetizationKit()
    }

    // MARK: - AttributionKit

    private static func configureAttributionKit() {
        AttributionKit.shared.configure(
            apiKey:  "<product api_key from server /admin>",
            appId:   "<product app_id from server /admin>",
            baseURL: "https://attribution.your-domain.com"
        )
        AttributionKit.shared.performAttributionIfNeeded()
    }

    // MARK: - MonetizationKit

    private static func configureMonetizationKit() {
        MonetizationKit.shared.configure(
            productIDs: ["pro_monthly", "pro_yearly"],

            // ───────────────────────────────────────────────────────────────
            // CRITICAL: pass IDFV as appAccountToken so the server can join
            // revenue events to install attribution. Without this, every
            // Revenue document the server inserts is tagged
            // attribution_source = 'unknown' and LTV-by-source queries
            // return nothing.
            // ───────────────────────────────────────────────────────────────
            appAccountTokenProvider: { UIDevice.current.identifierForVendor }
        )

        // Listen for events (optional — for analytics)
        MonetizationKit.shared.eventListener = { event in
            // Forward to your analytics provider
            print("[monetization] \(event.name) \(event.properties)")
        }

        // Observe entitlement changes
        MonetizationKit.shared.delegate = EntitlementDelegate.shared

        // Load products for the paywall
        Task {
            await MonetizationKit.shared.loadProducts()
        }
    }
}

// MARK: - Entitlement Delegate

@MainActor
final class EntitlementDelegate: MonetizationDelegate {
    static let shared = EntitlementDelegate()

    func monetization(_ kit: MonetizationKit, entitlementsDidChange entitlements: Set<String>) {
        // Update UI state — e.g. show/hide paywall, unlock features
        print("[monetization] entitlements changed: \(entitlements)")
    }

    func monetization(_ kit: MonetizationKit, didFailWith error: MonetizationError) {
        print("[monetization] error: \(error)")
    }
}
