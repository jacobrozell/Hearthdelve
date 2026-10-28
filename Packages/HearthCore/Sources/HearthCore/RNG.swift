public struct SplitMix64: Sendable, Equatable {
    public private(set) var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public struct Xoshiro256StarStar: Sendable, Equatable {
    public private(set) var s0: UInt64
    public private(set) var s1: UInt64
    public private(set) var s2: UInt64
    public private(set) var s3: UInt64

    public init(s0: UInt64, s1: UInt64, s2: UInt64, s3: UInt64) {
        self.s0 = s0
        self.s1 = s1
        self.s2 = s2
        self.s3 = s3
    }

    public mutating func next() -> UInt64 {
        let result = rotl(s1 &* 5, 7) &* 9
        let t = s1 << 17
        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3
        s2 ^= t
        s3 = rotl(s3, 45)
        return result
    }

    public func feed(_ hash: inout FNV64) {
        hash.add(s0)
        hash.add(s1)
        hash.add(s2)
        hash.add(s3)
    }
}

public struct RNGStreams: Sendable, Equatable {
    public var layout: Xoshiro256StarStar
    public var population: Xoshiro256StarStar
    public var combat: Xoshiro256StarStar
    public var loot: Xoshiro256StarStar

    public init(seed: UInt64) {
        var mix = SplitMix64(seed: seed)
        layout = Self.stream(from: &mix)
        population = Self.stream(from: &mix)
        combat = Self.stream(from: &mix)
        loot = Self.stream(from: &mix)
    }

    private static func stream(from mix: inout SplitMix64) -> Xoshiro256StarStar {
        Xoshiro256StarStar(s0: mix.next(), s1: mix.next(), s2: mix.next(), s3: mix.next())
    }
}

private func rotl(_ value: UInt64, _ shift: Int) -> UInt64 {
    (value << shift) | (value >> (64 - shift))
}
