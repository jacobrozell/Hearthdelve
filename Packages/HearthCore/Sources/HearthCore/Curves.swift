public struct ScalingCurve: Sendable {
    public let ratio: Double
    private var values: [Double]

    init(ratio: Double, through index: Int) {
        precondition(index >= 0)
        self.ratio = ratio
        var values = [Double]()
        values.reserveCapacity(index + 1)
        var value = 1.0
        for _ in 0...index {
            values.append(value)
            value *= ratio
        }
        self.values = values
    }

    public mutating func value(at index: Int) -> Double {
        precondition(index >= 0, "curve index")
        while values.count <= index {
            values.append(values[values.count - 1] * ratio)
        }
        return values[index]
    }
}

public struct BalanceCurves: Sendable {
    public var enemyHP: ScalingCurve
    public var enemyDamage: ScalingCurve
    public var power: ScalingCurve
    public var heroHP: ScalingCurve
    public var requiredBuild: ScalingCurve

    public init(through depth: Int = 300) {
        enemyHP = ScalingCurve(ratio: 1.12, through: depth)
        enemyDamage = ScalingCurve(ratio: 1.08, through: depth)
        power = ScalingCurve(ratio: 1.10, through: depth)
        heroHP = ScalingCurve(ratio: 1.08, through: depth)
        requiredBuild = ScalingCurve(ratio: 1.12 / 1.10, through: depth)
    }

    public mutating func enemyHitPoints(hp0: Double, depth: Int) -> Double {
        hp0 * enemyHP.value(at: depth)
    }

    public mutating func enemyDamageAmount(dmg0: Double, depth: Int) -> Double {
        dmg0 * enemyDamage.value(at: depth)
    }

    public mutating func weaponPower(p0: Double, itemLevel: Int) -> Double {
        p0 * power.value(at: itemLevel - 10)
    }

    public mutating func heroHitPoints(h0: Double, itemLevel: Int) -> Double {
        h0 * heroHP.value(at: itemLevel - 10)
    }
}
