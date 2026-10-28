public struct FNV64: Equatable, Sendable {
    public private(set) var value: UInt64

    public init() {
        value = 0xcbf29ce484222325
    }

    public mutating func add(_ byte: UInt8) {
        value ^= UInt64(byte)
        value &*= 0x100000001b3
    }

    public mutating func add(_ word: UInt64) {
        var bits = word
        for _ in 0..<8 {
            add(UInt8(truncatingIfNeeded: bits))
            bits >>= 8
        }
    }
}
