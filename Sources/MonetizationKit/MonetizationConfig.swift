import Foundation

struct MonetizationConfig {
    let productIDs: [String]
    let appAccountTokenProvider: (() -> UUID?)?

    init(productIDs: [String], appAccountTokenProvider: (() -> UUID?)? = nil) {
        self.productIDs = productIDs
        self.appAccountTokenProvider = appAccountTokenProvider
    }
}
