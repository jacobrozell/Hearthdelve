import Foundation

/// Hero level from the tuning curve. A Rift grants the XP the current level needs, so one clear
/// moves the level. The curve is repeated multiplication. Nothing here runs inside a sim tick.
/// Levels stop at 100. Paragon is a later slice.
public enum HeroProgress {
    public static let maxLevel = 100

    /// XP required to leave `level`. Level 1 costs `base`. Each further level multiplies by `growth` once.
    public static func xpToAdvance(from level: Int, curve: XPCurveTuning) -> Double {
        let steps = max(0, level - 1)
        var cost = curve.base
        for _ in 0..<steps {
            cost *= curve.growth
        }
        return cost
    }

    /// XP a finished Rift grants at this level. Zero once the hero is at the level cap.
    public static func riftXP(level: Int, curve: XPCurveTuning) -> Double {
        guard level < maxLevel else { return 0 }
        return xpToAdvance(from: max(1, level), curve: curve)
    }

    public struct Grant: Equatable, Sendable {
        public var level: Int
        public var xp: Double
        public var glyphPoints: Int
        public var levelsGained: Int
    }

    /// Adds rift XP, spends it on levels, and banks one Glyph Point per level gained.
    public static func apply(xp award: Double, level: Int, xp: Double, glyphPoints: Int, curve: XPCurveTuning) -> Grant {
        var level = min(max(1, level), maxLevel)
        var xp = xp + max(0, award)
        var points = glyphPoints
        var gained = 0
        while level < maxLevel {
            let need = xpToAdvance(from: level, curve: curve)
            if xp + 0.000_001 < need { break }
            xp -= need
            level += 1
            points += 1
            gained += 1
        }
        if level >= maxLevel { xp = 0 }
        return Grant(level: level, xp: xp, glyphPoints: points, levelsGained: gained)
    }

    /// Extra max HP for the next fight. Level 1 adds none. Wired through `RoomSetup.bonusHP`.
    public static func bonusHP(level: Int, perLevel: Double) -> Double {
        Double(max(0, level - 1)) * perLevel
    }
}

public struct SalvageYield: Equatable, Sendable {
    public var dust: Double
    public var shards: Double
    public var embers: Double
    /// Unique definition id to record in the Codex. Nil for Common and Rare.
    public var codexSignature: String?
}

public enum SalvageDecision: Equatable, Sendable {
    case granted(SalvageYield)
    case needsConfirmation
    case refused(String)
}

public enum RaiseDecision: Equatable, Sendable {
    case raised(itemLevel: Int, dust: Double, gold: Double)
    case refused(String)
}

/// Blacksmith salvage and item-level raises. Uniques are never salvaged without an explicit confirm.
public enum SmithRules {
    /// Highest item level the smith will reach. Par at your best Depth is `best + 10`.
    public static func cap(bestDepth: Int) -> Int {
        max(1, bestDepth) + 10
    }

    /// Dust and gold to raise an item from this level. The first step, item level 11, is the starting cost.
    public static func raiseCost(itemLevel: Int, tuning: SmithTuning) -> (dust: Double, gold: Double) {
        var dust = tuning.raiseDust
        var gold = tuning.raiseGold
        let steps = max(0, itemLevel - 11)
        guard tuning.raiseGrowth > 0 else { return (dust, gold) }
        for _ in 0..<steps {
            dust *= tuning.raiseGrowth
            gold *= tuning.raiseGrowth
        }
        return (dust, gold)
    }

    public static func salvage(rarity: String, signature: String?, equipped: Bool, confirmed: Bool, tuning: SmithTuning) -> SalvageDecision {
        if equipped { return .refused("equipped") }
        switch rarity {
        case "unique":
            if confirmed == false { return .needsConfirmation }
            return .granted(SalvageYield(dust: 0, shards: 0, embers: tuning.uniqueEmbers, codexSignature: signature))
        case "rare":
            return .granted(SalvageYield(dust: 0, shards: tuning.rareShards, embers: 0, codexSignature: nil))
        default:
            return .granted(SalvageYield(dust: tuning.commonDust, shards: 0, embers: 0, codexSignature: nil))
        }
    }

    public static func raise(itemLevel: Int, bestDepth: Int, dust: Double, gold: Double, tuning: SmithTuning) -> RaiseDecision {
        let cap = cap(bestDepth: bestDepth)
        if itemLevel >= cap { return .refused("cap") }
        let cost = raiseCost(itemLevel: itemLevel, tuning: tuning)
        if dust + 0.000_001 < cost.dust || gold + 0.000_001 < cost.gold { return .refused("cost") }
        return .raised(itemLevel: itemLevel + 1, dust: cost.dust, gold: cost.gold)
    }

    /// Records a salvaged Unique once. Repeats do not add a second line.
    public static func record(signature: String?, codex: inout [String]) {
        guard let signature, signature.isEmpty == false, codex.contains(signature) == false else { return }
        codex.append(signature)
    }
}
