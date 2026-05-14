import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
private struct MonetizationKitEnvironmentKey: EnvironmentKey {
    /// SwiftUI materializes the environment on the main thread, so
    /// `MainActor.assumeIsolated` is safe here and lets the nonisolated
    /// `EnvironmentKey` requirement reach `@MainActor`-isolated `shared`.
    static let defaultValue: MonetizationKit = MainActor.assumeIsolated {
        MonetizationKit.shared
    }
}

@available(macOS 12.0, iOS 15.0, *)
public extension EnvironmentValues {
    var monetization: MonetizationKit {
        get { self[MonetizationKitEnvironmentKey.self] }
        set { self[MonetizationKitEnvironmentKey.self] = newValue }
    }
}
