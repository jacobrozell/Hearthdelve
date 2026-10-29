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

    /// The price `raise` spends. Whole numbers stay whole. A grown cost keeps two decimals so the caption matches the charge.
    public static func raiseCaption(itemLevel: Int, bestDepth: Int, tuning: SmithTuning) -> String {
        if itemLevel >= cap(bestDepth: bestDepth) { return "Needs Depth \(max(1, bestDepth) + 1)" }
        let cost = raiseCost(itemLevel: itemLevel, tuning: tuning)
        return "\(price(cost.dust)) Dust, \(price(cost.gold)) Anula"
    }

    public static func price(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.000_001 { return String(Int(value.rounded())) }
        let cents = Int((value * 100).rounded())
        let whole = cents / 100
        let fraction = abs(cents % 100)
        return "\(whole).\(fraction < 10 ? "0" : "")\(fraction)"
    }

    public static let salvageCommon = "salvage:common"
    public static let salvageRare = "salvage:rare"

    public struct SalvageCandidate: Equatable, Sendable {
        public var id: String
        public var rarity: String
        public var signature: String?
        public var equipped: Bool
        public var locked: Bool
        public var favorite: Bool

        public init(id: String, rarity: String, signature: String?, equipped: Bool, locked: Bool, favorite: Bool) {
            self.id = id
            self.rarity = rarity
            self.signature = signature
            self.equipped = equipped
            self.locked = locked
            self.favorite = favorite
        }
    }

    /// Commons and Rares the loot rule will break down. Worn, locked, favorite, and Unique pieces stay.
    public static func autoSalvage(items: [SalvageCandidate], rules: [String], tuning: SmithTuning) -> [(id: String, yield: SalvageYield)] {
        items.compactMap { item in
            guard item.equipped == false, item.locked == false, item.favorite == false else { return nil }
            guard matches(rarity: item.rarity, rules: rules) else { return nil }
            guard case .granted(let yield) = salvage(rarity: item.rarity, signature: item.signature, equipped: false, confirmed: true, tuning: tuning) else { return nil }
            return (item.id, yield)
        }
    }

    public static func salvageNote(commons: Int, rares: Int) -> String? {
        switch (commons, rares) {
        case (0, 0): return nil
        case (let count, 0): return "Salvaged \(count) \(count == 1 ? "Common" : "Commons")."
        case (0, let count): return "Salvaged \(count) \(count == 1 ? "Rare" : "Rares")."
        default: return "Salvaged \(commons) Commons and \(rares) Rares."
        }
    }

    private static func matches(rarity: String, rules: [String]) -> Bool {
        switch rarity {
        case "common": rules.contains(salvageCommon)
        case "rare": rules.contains(salvageRare)
        default: false
        }
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

    /// Shards for a Rare, Embers for a Unique. `times` is how many re-rolls this item has already taken.
    /// The next one costs twice as much. Commons have no re-roll.
    public static func rerollCost(rarity: String, times: Int, tuning: SmithTuning) -> (shards: Double, embers: Double)? {
        let steps = max(0, times)
        switch rarity {
        case "rare": return (doubled(tuning.rerollRareShards, times: steps), 0)
        case "unique": return (0, doubled(tuning.rerollUniqueEmbers, times: steps))
        default: return nil
        }
    }

    public static func rerollCaption(rarity: String, times: Int, tuning: SmithTuning) -> String? {
        guard let cost = rerollCost(rarity: rarity, times: times, tuning: tuning) else { return nil }
        if cost.embers > 0 { return "\(price(cost.embers)) Echoes" }
        return "\(price(cost.shards)) Facets"
    }

    /// Replaces one affix. Every other affix keeps its id and its value. The price doubles with `times`.
    public static func reroll(
        rarity: String, slot: String, affixes: [LootAffixRoll], index: Int, times: Int,
        shards: Double, embers: Double, pool: [ItemAffixDefinition], tuning: SmithTuning,
        rng: inout Xoshiro256StarStar
    ) -> RerollDecision {
        guard let cost = rerollCost(rarity: rarity, times: times, tuning: tuning) else { return .refused("rarity") }
        guard affixes.indices.contains(index) else { return .refused("affix") }
        if shards + 0.000_001 < cost.shards || embers + 0.000_001 < cost.embers { return .refused("cost") }
        let locked = Set(affixes.enumerated().compactMap { $0.offset == index ? nil : $0.element.id })
        let choices = pool.filter { $0.slots.contains(slot) && locked.contains($0.id) == false }.sorted { $0.id < $1.id }
        guard choices.isEmpty == false else { return .refused("pool") }
        let definition = choices[Int(rng.next() % UInt64(choices.count))]
        var next = affixes
        next[index] = roll(definition, rng: &rng)
        return .rerolled(affixes: next, shards: cost.shards, embers: cost.embers)
    }

    public static func craftCaption(tuning: SmithTuning) -> String {
        "\(price(tuning.craftRareShards)) Facets"
    }

    public static func transmuteCaption(tuning: SmithTuning) -> String {
        "\(price(tuning.transmuteEmbers)) Echoes"
    }

    /// A Rare of the chosen slot and type. A full bag is refused before any Facets are spent.
    public static func craft(
        slot: String, typeID: String, bases: [LootBase], affixes: [ItemAffixDefinition],
        shards: Double, bagCount: Int, bagCapacity: Int, itemLevel: Int, tuning: SmithTuning,
        rng: inout Xoshiro256StarStar, id: String
    ) -> CraftDecision {
        if bagCount >= bagCapacity { return .refused("bag") }
        if shards + 0.000_001 < tuning.craftRareShards { return .refused("cost") }
        guard let base = bases.first(where: { $0.id == typeID && $0.slot == slot }) else { return .refused("type") }
        let rolls = rollAffixes(slot: slot, count: 2, pool: affixes, rng: &rng)
        let item = LootItem(
            id: id, definition: base.id, name: base.name, slot: slot, itemLevel: itemLevel,
            rarity: "rare", affixes: rolls, signature: nil, damageArrow: 0, toughnessArrow: 0
        )
        return .crafted(item, shards: tuning.craftRareShards)
    }

    /// Another Unique of the same slot. The Ember price does not double.
    public static func transmute(
        rarity: String, slot: String, currentID: String, uniques: [LootUnique],
        embers: Double, tuning: SmithTuning, rng: inout Xoshiro256StarStar
    ) -> TransmuteDecision {
        guard rarity == "unique" else { return .refused("rarity") }
        if embers + 0.000_001 < tuning.transmuteEmbers { return .refused("cost") }
        let pool = uniques.filter { $0.slot == slot && $0.id != currentID }.sorted { $0.id < $1.id }
        guard pool.isEmpty == false else { return .refused("pool") }
        return .transmuted(pool[Int(rng.next() % UInt64(pool.count))], embers: tuning.transmuteEmbers)
    }

    private static func doubled(_ base: Double, times: Int) -> Double {
        var cost = base
        for _ in 0..<times { cost *= 2 }
        return cost
    }

    private static func rollAffixes(slot: String, count: Int, pool: [ItemAffixDefinition], rng: inout Xoshiro256StarStar) -> [LootAffixRoll] {
        var choices = pool.filter { $0.slots.contains(slot) }.sorted { $0.id < $1.id }
        var rolls: [LootAffixRoll] = []
        for _ in 0..<count where choices.isEmpty == false {
            let definition = choices.remove(at: Int(rng.next() % UInt64(choices.count)))
            rolls.append(roll(definition, rng: &rng))
        }
        return rolls
    }

    private static func roll(_ definition: ItemAffixDefinition, rng: inout Xoshiro256StarStar) -> LootAffixRoll {
        let span = max(0, definition.max - definition.min)
        let value = definition.min + span * CombatRoll.unitInterval(rng.next())
        return LootAffixRoll(id: definition.id, stat: definition.stat, value: value)
    }
}

public enum RerollDecision: Equatable, Sendable {
    case rerolled(affixes: [LootAffixRoll], shards: Double, embers: Double)
    case refused(String)
}

public enum CraftDecision: Equatable, Sendable {
    case crafted(LootItem, shards: Double)
    case refused(String)
}

public enum TransmuteDecision: Equatable, Sendable {
    case transmuted(LootUnique, embers: Double)
    case refused(String)
}

/// The stash holds 100. Equipped pieces stay equipped. A full bag stays full.
public enum StashRules {
    public static let capacity = 100
    public static let bagFull = "The bag is full."
    public static let stashFull = "The stash is full."

    /// Nil when the move is allowed. `toStash` false means the item is coming back to the bag.
    public static func refusal(equipped: Bool, stashCount: Int, bagCount: Int, bagCapacity: Int, toStash: Bool) -> String? {
        if toStash {
            if equipped { return "equipped" }
            if stashCount >= capacity { return "stash" }
            return nil
        }
        if bagCount >= bagCapacity { return "bag" }
        return nil
    }

    public static func note(for refusal: String) -> String? {
        switch refusal {
        case "bag": bagFull
        case "stash": stashFull
        default: nil
        }
    }
}
