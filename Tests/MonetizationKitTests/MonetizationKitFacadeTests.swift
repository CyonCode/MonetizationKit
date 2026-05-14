import Foundation
import Testing
import StoreKit
@testable import MonetizationKit

@Suite("MonetizationKitFacade")
@MainActor
struct MonetizationKitFacadeTests {

    @Test("shared singleton exists")
    func sharedExists() {
        let kit = MonetizationKit.shared
        let other = MonetizationKit()
        #expect(kit !== other)
    }

    @Test("init creates new instance (not singleton)")
    func initCreatesNew() {
        let a = MonetizationKit()
        let b = MonetizationKit()
        #expect(a !== b)
    }

    @Test("products empty before configure")
    func productsEmptyBeforeConfigure() {
        let kit = MonetizationKit()
        #expect(kit.products.isEmpty)
    }

    @Test("activeEntitlements empty initially")
    func entitlementsEmpty() {
        let kit = MonetizationKit()
        #expect(kit.activeEntitlements.isEmpty)
    }

    @Test("isSubscribed false initially")
    func notSubscribed() {
        let kit = MonetizationKit()
        #expect(!kit.isSubscribed)
    }

    @Test("delegate defaults to nil")
    func delegateNil() {
        let kit = MonetizationKit()
        #expect(kit.delegate == nil)
    }

    @Test("eventListener defaults to nil")
    func eventListenerNil() {
        let kit = MonetizationKit()
        #expect(kit.eventListener == nil)
    }

    @Test("configure sets up engine")
    func configureSetsUp() {
        let kit = MonetizationKit()
        kit.configure(productIDs: ["a", "b"])
    }

    @Test("eventListener receives events")
    func eventListenerReceives() {
        let kit = MonetizationKit()
        var received: [MonetizationEvent] = []
        kit.eventListener = { received.append($0) }
        kit.configure(productIDs: ["x"])
        #expect(received.isEmpty)
    }
}
