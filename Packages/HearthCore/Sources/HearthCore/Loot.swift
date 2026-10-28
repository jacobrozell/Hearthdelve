/// Item level, rarity, pity, and the two arrows. The loot stream is read only when a Rift ends.
public struct ItemAffixDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var stat: String
    public var min: Double
    public var max: Double
    public var slots: [String]

    public init(id: String, name: String, stat: String, min: Double, max: Double, slots: [String]) {
        self.id = id
        self.name = name
        self.stat = stat
        self.min = min
        self.max = max
        self.slots = slots
    }
}

public struct LootAffixRoll: Sendable, Equatable {
    public var id: String
    public var stat: String
    public var value: Double

    public init(id: String, stat: String, value: Double) {
        self.id = id
        self.stat = stat
        self.value = value
    }

    /// `id=basisPoints`, where 450 means 0.0450. Integers so a saved affix scores the same after a relaunch.
    public var saved: String { "\(id)=\(Int((value * 10_000).rounded()))" }

    public static func parse(_ saved: [String], definitions: [ItemAffixDefinition]) -> [LootAffixRoll] {
        saved.compactMap { raw in
            let parts = raw.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, let points = Int(parts[1]), let definition = definitions.first(where: { $0.id == parts[0] }) else { return nil }
            return LootAffixRoll(id: definition.id, stat: definition.stat, value: Double(points) / 10_000)
        }
    }
}

public struct LootBase: Sendable, Equatable {
    public var id: String
    public var name: String
    public var slot: String

    public init(id: String, name: String, slot: String) {
        self.id = id
        self.name = name
        self.slot = slot
    }
}

public struct LootUnique: Sendable, Equatable {
    public var id: String
    public var name: String
    public var slot: String

    public init(id: String, name: String, slot: String) {
        self.id = id
        self.name = name
        self.slot = slot
    }
}

public struct LootItem: Sendable, Equatable, Identifiable {
    public var id: String
    public var definition: String
    public var name: String
    public var slot: String
    public var itemLevel: Int
    public var rarity: String
    public var affixes: [LootAffixRoll]
    public var signature: String?
    /// 1 up, -1 down, 0 level with the equipped piece in this slot.
    public var damageArrow: Int
    public var toughnessArrow: Int

    public init(
        id: String, definition: String, name: String, slot: String, itemLevel: Int, rarity: String,
        affixes: [LootAffixRoll], signature: String?, damageArrow: Int, toughnessArrow: Int
    ) {
        self.id = id
        self.definition = definition
        self.name = name
        self.slot = slot
        self.itemLevel = itemLevel
        self.rarity = rarity
        self.affixes = affixes
        self.signature = signature
        self.damageArrow = damageArrow
        self.toughnessArrow = toughnessArrow
    }

    public static func plain(id: String, name: String, slot: String, itemLevel: Int, definition: String) -> LootItem {
        LootItem(id: id, definition: definition, name: name, slot: slot, itemLevel: itemLevel, rarity: "common", affixes: [], signature: nil, damageArrow: 0, toughnessArrow: 0)
    }

    /// Name, item level, then damage and toughness marks. `+` up, `-` down, `=` level.
    public var markedLine: String {
        "\(rarityName) \(name) \(itemLevel) \(Self.mark(damageArrow))\(Self.mark(toughnessArrow))"
    }

    public var rarityName: String {
        switch rarity {
        case "rare": "Rare"
        case "unique": "Unique"
        default: "Common"
        }
    }

    public static func mark(_ arrow: Int) -> String {
        if arrow > 0 { return "+" }
        if arrow < 0 { return "-" }
        return "="
    }
}

public struct LootTable: Sendable, Equatable {
    public var bases: [LootBase]
    public var affixes: [ItemAffixDefinition]
    public var uniques: [LootUnique]
    public var equipped: [LootItem]
    public var pity: Int
    public var idPrefix: String

    public init(bases: [LootBase], affixes: [ItemAffixDefinition], uniques: [LootUnique], equipped: [LootItem], pity: Int, idPrefix: String) {
        self.bases = bases
        self.affixes = affixes
        self.uniques = uniques
        self.equipped = equipped
        self.pity = pity
        self.idPrefix = idPrefix
    }
}

public struct LootRoll: Sendable, Equatable {
    public var items: [LootItem]
    public var pity: Int

    public init(items: [LootItem], pity: Int) {
        self.items = items
        self.pity = pity
    }
}

public enum LootScore {
    private static let offense: Set<String> = ["meleeDamage", "rangedDamage", "relicDamage", "critChance", "attackSpeed"]
    private static let defense: Set<String> = ["maxHP", "armor"]

    public static func damage(itemLevel: Int, affixes: [LootAffixRoll], p0: Double) -> Double {
        var curves = BalanceCurves(through: max(itemLevel, 1))
        let bonus = affixes.reduce(0.0) { total, roll in offense.contains(roll.stat) ? total + roll.value : total }
        return curves.weaponPower(p0: p0, itemLevel: max(10, itemLevel)) * (1 + bonus)
    }

    public static func toughness(itemLevel: Int, affixes: [LootAffixRoll], h0: Double) -> Double {
        var curves = BalanceCurves(through: max(itemLevel, 1))
        let bonus = affixes.reduce(0.0) { total, roll in defense.contains(roll.stat) ? total + roll.value : total }
        return curves.heroHitPoints(h0: h0, itemLevel: max(10, itemLevel)) * (1 + bonus)
    }

    public static func arrow(new: Double, old: Double) -> Int {
        if new > old + 0.000_001 { return 1 }
        if new < old - 0.000_001 { return -1 }
        return 0
    }
}

public enum LootRoller {
    /// Basis points. Depth 1 is 60/32/8. Depth 100 and above is 45/40/15. An elite pack is 0/75/25.
    public static func shares(depth: Int, elite: Bool) -> (common: Int, rare: Int, unique: Int) {
        if elite { return (0, 7_500, 2_500) }
        let span = min(99, max(0, depth - 1))
        let common = 6_000 + (4_500 - 6_000) * span / 99
        let rare = 3_200 + (4_000 - 3_200) * span / 99
        return (common, rare, 10_000 - common - rare)
    }

    /// Forty Rares in a row, with no Unique and no Common between them, upgrade the next Rare.
    public static func applyPity(rolled: String, pity: inout Int) -> String {
        switch rolled {
        case "unique":
            pity = 0
            return "unique"
        case "rare":
            if pity >= 40 {
                pity = 0
                return "unique"
            }
            pity += 1
            return "rare"
        default:
            pity = 0
            return "common"
        }
    }

    /// One item per normal or elite kill, then the Guardian's guaranteed Unique and two 50/50 rolls.
    public static func roll(
        depth: Int, normalKills: Int, eliteKills: Int, guardian: Bool, table: LootTable,
        rng: inout Xoshiro256StarStar, p0: Double, h0: Double
    ) -> LootRoll {
        var pity = table.pity
        var items: [LootItem] = []
        func add(_ source: DropSource) {
            let rarity = rarity(source, depth: depth, rng: &rng, pity: &pity)
            if let item = finish(depth: depth, rarity: rarity, table: table, rng: &rng, index: items.count, p0: p0, h0: h0) {
                items.append(item)
            }
        }
        for _ in 0..<max(0, normalKills) { add(.normal) }
        for _ in 0..<max(0, eliteKills) { add(.elite) }
        if guardian {
            add(.guardianUnique)
            add(.guardianExtra)
            add(.guardianExtra)
        }
        return LootRoll(items: items, pity: pity)
    }

    /// Uniques first, then the rest in drop order, until the bag has room.
    public static func admit(_ items: [LootItem], room: Int) -> [LootItem] {
        guard room > 0 else { return [] }
        var kept: [String] = []
        let ordered = items.filter { $0.rarity == "unique" } + items.filter { $0.rarity != "unique" }
        for item in ordered where kept.count < room && kept.contains(item.id) == false {
            kept.append(item.id)
        }
        return items.filter { kept.contains($0.id) }
    }

    private enum DropSource {
        case normal
        case elite
        case guardianUnique
        case guardianExtra
    }

    private static func rarity(_ source: DropSource, depth: Int, rng: inout Xoshiro256StarStar, pity: inout Int) -> String {
        switch source {
        case .guardianUnique:
            return applyPity(rolled: "unique", pity: &pity)
        case .guardianExtra:
            let rolled = Int(rng.next() % 2) == 0 ? "rare" : "unique"
            return applyPity(rolled: rolled, pity: &pity)
        case .normal, .elite:
            let shares = shares(depth: depth, elite: source == .elite)
            let roll = Int(rng.next() % 10_000)
            let rolled = roll < shares.common ? "common" : roll < shares.common + shares.rare ? "rare" : "unique"
            return applyPity(rolled: rolled, pity: &pity)
        }
    }

    private static func finish(
        depth: Int, rarity: String, table: LootTable, rng: inout Xoshiro256StarStar, index: Int, p0: Double, h0: Double
    ) -> LootItem? {
        let itemLevel = depth + 10
        let unique = rarity == "unique" ? pickUnique(table, rng: &rng) : nil
        let base = unique == nil ? pickBase(table, rng: &rng) : nil
        guard unique != nil || base != nil else { return nil }
        let slot = unique?.slot ?? base?.slot ?? "melee"
        let affixCount = rarity == "common" ? 1 : 2
        let affixes = pickAffixes(slot: slot, count: affixCount, table: table, rng: &rng)
        let name = unique?.name ?? base?.name ?? "Gear"
        let definition = unique?.id ?? base?.id ?? name
        let worn = table.equipped.first { $0.slot == slot }
        let damage = LootScore.damage(itemLevel: itemLevel, affixes: affixes, p0: p0)
        let toughness = LootScore.toughness(itemLevel: itemLevel, affixes: affixes, h0: h0)
        let oldDamage = worn.map { LootScore.damage(itemLevel: $0.itemLevel, affixes: $0.affixes, p0: p0) } ?? 0
        let oldToughness = worn.map { LootScore.toughness(itemLevel: $0.itemLevel, affixes: $0.affixes, h0: h0) } ?? 0
        return LootItem(
            id: "\(table.idPrefix)-\(index)",
            definition: definition,
            name: name,
            slot: slot,
            itemLevel: itemLevel,
            rarity: rarity,
            affixes: affixes,
            signature: unique?.id,
            damageArrow: LootScore.arrow(new: damage, old: oldDamage),
            toughnessArrow: LootScore.arrow(new: toughness, old: oldToughness)
        )
    }

    private static func pickBase(_ table: LootTable, rng: inout Xoshiro256StarStar) -> LootBase? {
        let slots = Array(Set(table.bases.map(\.slot))).sorted()
        guard slots.isEmpty == false else { return nil }
        let slot = slots[Int(rng.next() % UInt64(slots.count))]
        let pool = table.bases.filter { $0.slot == slot }.sorted { $0.id < $1.id }
        guard pool.isEmpty == false else { return nil }
        return pool[Int(rng.next() % UInt64(pool.count))]
    }

    private static func pickUnique(_ table: LootTable, rng: inout Xoshiro256StarStar) -> LootUnique? {
        let pool = table.uniques.sorted { $0.id < $1.id }
        guard pool.isEmpty == false else { return nil }
        return pool[Int(rng.next() % UInt64(pool.count))]
    }

    private static func pickAffixes(slot: String, count: Int, table: LootTable, rng: inout Xoshiro256StarStar) -> [LootAffixRoll] {
        var pool = table.affixes.filter { $0.slots.contains(slot) }.sorted { $0.id < $1.id }
        var rolls: [LootAffixRoll] = []
        for _ in 0..<count where pool.isEmpty == false {
            let index = Int(rng.next() % UInt64(pool.count))
            let definition = pool.remove(at: index)
            let span = max(0, definition.max - definition.min)
            let value = definition.min + span * CombatRoll.unitInterval(rng.next())
            rolls.append(LootAffixRoll(id: definition.id, stat: definition.stat, value: value))
        }
        return rolls
    }
}
