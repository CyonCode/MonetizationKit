import OSLog

@available(macOS 10.14, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
enum MonetizationLog {
    private static let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "monetization-kit",
        category: "monetization"
    )

    static func debug(_ message: String) {
        os_log(.debug, log: log, "%{public}@", message)
    }

    static func info(_ message: String) {
        os_log(.info, log: log, "%{public}@", message)
    }

    static func error(_ message: String) {
        os_log(.error, log: log, "%{public}@", message)
    }
}
