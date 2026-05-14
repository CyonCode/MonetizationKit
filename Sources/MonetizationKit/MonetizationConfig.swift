import Foundation

struct MonetizationConfig {
    let productIDs: [String]
    let appAccountTokenProvider: (() -> UUID?)?
    /// When `true`, `purchase(...)` throws `.missingAppAccountToken` if the
    /// provider returns `nil`. Default `false` preserves opt-in semantics.
    let requiresAppAccountToken: Bool

    init(
        productIDs: [String],
        appAccountTokenProvider: (() -> UUID?)? = nil,
        requiresAppAccountToken: Bool = false
    ) {
        self.productIDs = productIDs
        self.appAccountTokenProvider = appAccountTokenProvider
        self.requiresAppAccountToken = requiresAppAccountToken
    }
}
