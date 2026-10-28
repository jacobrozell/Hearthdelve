import Foundation

public enum SoulRules {
    public static let perKill = 1.0
    public static let perElite = 5.0
    public static let cap = 100.0
}

public enum CombatMath {
    public static func outgoing(
        power: Double,
        coefficient: Double,
        additive: [Double],
        multipliers: [Double],
        critDamage: Double,
        isCrit: Bool
    ) -> Double {
        let added = additive.reduce(0, +)
        let product = multipliers.reduce(1, *)
        let crit = isCrit ? (1 + critDamage) : 1
        return power * coefficient * (1 + added) * product * crit
    }

    public static func incoming(
        raw: Double,
        armor: Double,
        resist: Double,
        level: Double,
        reductions: [Double]
    ) -> Double {
        let armorFactor = mitigation(numerator: armor, constant: 50, level: level)
        let resistFactor = mitigation(numerator: resist, constant: 5, level: level)
        let reduction = reductions.reduce(1) { $0 * (1 - $1) }
        return raw * armorFactor * resistFactor * reduction
    }

    public static func level(depth: Int) -> Double {
        Double(depth + 60)
    }

    private static func mitigation(numerator: Double, constant: Double, level: Double) -> Double {
        let denominator = numerator + constant * level
        if denominator == 0 { return 1 }
        return 1 - numerator / denominator
    }
}

public enum CombatRoll {
    public static func unitInterval(_ bits: UInt64) -> Double {
        Double(bits >> 11) / Double(1 << 53)
    }

    public static func dodged(roll: UInt64, chance: Double) -> Bool {
        unitInterval(roll) < chance
    }
}

public enum DifficultyBand: String, Sendable, Equatable {
    case easy
    case fair
    case hard
    case deadly

    public static func band(buildMultiplier: Double, required: Double) -> DifficultyBand {
        let ratio = required == 0 ? buildMultiplier : buildMultiplier / required
        if ratio >= 1.5 { return .easy }
        if ratio >= 1 { return .fair }
        if ratio >= 0.7 { return .hard }
        return .deadly
    }

    public var label: String {
        switch self {
        case .easy: "Easy"
        case .fair: "Fair"
        case .hard: "Hard"
        case .deadly: "Deadly"
        }
    }
}

/// Loadout damage divided by a par weapon at this Depth, then compared with B(d).
/// An empty weapon list is par, so a fresh hero forecasts at 1.
public enum BuildForecast {
    public static func multiplier(depth: Int, weapons: [LootItem], p0: Double) -> Double {
        let par = LootScore.damage(itemLevel: depth + 10, affixes: [], p0: p0)
        guard par > 0 else { return 1 }
        let slots = weapons.filter { $0.slot == "melee" || $0.slot == "ranged" }
        if slots.isEmpty { return 1 }
        let dealt = slots.reduce(0.0) { total, item in
            total + LootScore.damage(itemLevel: item.itemLevel, affixes: item.affixes, p0: p0)
        }
        let missing = Double(max(0, 2 - slots.count)) * par
        return ((dealt + missing) / 2) / par
    }

    public static func band(depth: Int, weapons: [LootItem], p0: Double) -> DifficultyBand {
        var curves = BalanceCurves(through: max(depth, 0))
        let required = curves.requiredBuild.value(at: max(0, depth))
        return DifficultyBand.band(buildMultiplier: multiplier(depth: depth, weapons: weapons, p0: p0), required: required)
    }
}

public enum NumberFormat {
    public static func short(_ value: Double) -> String {
        if !value.isFinite { return "0" }
        let sign = value < 0 ? "-" : ""
        var magnitude = abs(value)
        let suffixes = ["", "K", "M", "B", "T", "aa", "ab", "ac"]
        var index = 0
        while magnitude >= 1000, index < suffixes.count - 1 {
            magnitude /= 1000
            index += 1
        }
        return sign + digits(magnitude) + suffixes[index]
    }

    private static func digits(_ value: Double) -> String {
        if value >= 100 || value == value.rounded() {
            return String(Int(value.rounded()))
        }
        let places = value >= 10 ? 1 : 2
        var text = String(format: "%.\(places)f", value)
        while text.contains("."), text.hasSuffix("0") {
            text.removeLast()
        }
        if text.hasSuffix(".") {
            text.removeLast()
        }
        return text
    }
}
