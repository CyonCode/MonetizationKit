import Foundation
import Testing
@testable import MonetizationKit

@Suite("MonetizationConfig")
struct MonetizationConfigTests {

    @Test("Stores productIDs")
    func storesProductIDs() {
        let config = MonetizationConfig(productIDs: ["a", "b", "c"])
        #expect(config.productIDs == ["a", "b", "c"])
    }

    @Test("appAccountTokenProvider defaults to nil")
    func defaultTokenProvider() {
        let config = MonetizationConfig(productIDs: ["x"])
        #expect(config.appAccountTokenProvider == nil)
    }

    @Test("appAccountTokenProvider stores closure")
    func storesTokenProvider() {
        let uuid = UUID()
        let config = MonetizationConfig(
            productIDs: ["x"],
            appAccountTokenProvider: { uuid }
        )
        #expect(config.appAccountTokenProvider?() == uuid)
    }

    @Test("Empty productIDs is valid")
    func emptyProductIDs() {
        let config = MonetizationConfig(productIDs: [])
        #expect(config.productIDs.isEmpty)
    }
}
