import Foundation
import Testing
import StoreKit
@testable import MonetizationKit

@Suite("TransactionObserver")
@MainActor
struct TransactionObserverTests {

    @Test("Initial entitlements are empty")
    func initialEntitlementsEmpty() {
        let stream = MockTransactionStream()
        let observer = TransactionObserver(transactionStream: stream)
        #expect(observer.activeEntitlements.isEmpty)
    }

    @Test("startListening does not crash with empty stream")
    func startListeningNoCrash() {
        let stream = MockTransactionStream()
        let observer = TransactionObserver(transactionStream: stream)
        observer.startListening()
        observer.stopListening()
    }

    @Test("refreshEntitlements with empty stream — entitlements stay empty")
    func refreshEntitlementsEmpty() async {
        let stream = MockTransactionStream()
        stream.stubbedEntitlements = []
        let observer = TransactionObserver(transactionStream: stream)

        await observer.refreshEntitlements()

        #expect(observer.activeEntitlements.isEmpty)
    }

    @Test("onEntitlementsChange not called when entitlements unchanged")
    func noChangeNoCallback() async {
        let stream = MockTransactionStream()
        stream.stubbedEntitlements = []
        let observer = TransactionObserver(transactionStream: stream)
        var callCount = 0
        observer.onEntitlementsChange = { _ in callCount += 1 }

        await observer.refreshEntitlements()

        #expect(callCount == 0)
    }

    @Test("stopListening cancels background task")
    func stopListeningCancels() {
        let stream = MockTransactionStream()
        let observer = TransactionObserver(transactionStream: stream)
        observer.startListening()
        observer.stopListening()
    }
}
