import Foundation
import Testing
@testable import MonetizationKit

@Suite("AnyAsyncSequence")
struct AnyAsyncSequenceTests {

    @Test("makeAsyncIterator returns fresh iterator on each call")
    func freshIteratorEachCall() async throws {
        let counter = IteratorCounter()
        let source = CountingSequence(values: [1, 2, 3], counter: counter)
        let erased = AnyAsyncSequence(source)

        var first: [Int] = []
        for try await x in erased { first.append(x) }

        var second: [Int] = []
        for try await x in erased { second.append(x) }

        #expect(first == [1, 2, 3])
        #expect(second == [1, 2, 3])
        #expect(counter.count == 2)
    }

    @Test("makeAsyncIterator preserves underlying element order")
    func preservesOrder() async throws {
        let counter = IteratorCounter()
        let source = CountingSequence(values: [10, 20, 30, 40], counter: counter)
        let erased = AnyAsyncSequence(source)

        var collected: [Int] = []
        for try await x in erased { collected.append(x) }

        #expect(collected == [10, 20, 30, 40])
    }
}

private final class IteratorCounter: @unchecked Sendable {
    private(set) var count = 0
    func increment() { count += 1 }
}

private struct CountingSequence: AsyncSequence {
    typealias Element = Int

    let values: [Int]
    let counter: IteratorCounter

    struct AsyncIterator: AsyncIteratorProtocol {
        private var remaining: [Int]

        init(values: [Int]) {
            self.remaining = values
        }

        mutating func next() async -> Int? {
            guard !remaining.isEmpty else { return nil }
            return remaining.removeFirst()
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        counter.increment()
        return AsyncIterator(values: values)
    }
}
