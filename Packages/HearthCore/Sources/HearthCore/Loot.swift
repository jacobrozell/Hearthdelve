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

/// How a rolled affix reads on a piece. 0.0644 is "6.4%".
public enum AffixFormat {
    public static func percent(_ value: Double) -> String {
        let tenths = (value * 1_000).rounded() / 10
        if abs(tenths - tenths.rounded()) < 0.001 {
            return "\(Int(tenths.rounded()))%"
        }
        return String(format: "%.1f%%", tenths)
    }

    public static func line(name: String, value: Double) -> String {
        "\(name) +\(percent(value))"
    }

    public static func perSecond(_ value: Double) -> String {
        let tenths = (value * 10).rounded() / 10
        if abs(tenths - tenths.rounded()) < 0.001 {
            return "\(Int(tenths.rounded()))/s"
        }
        return String(format: "%.1f/s", tenths)
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

/// The seven pieces a level-1 hero can wear.
public enum GearSlots {
    public static let order = ["melee", "ranged", "relic", "helm", "chest", "legs", "boots"]

    public static func name(_ slot: String) -> String {
        switch slot {
        case "melee": "Melee"
        case "ranged": "Ranged"
        case "relic": "Relic"
        case "helm": "Helm"
        case "chest": "Chest"
        case "legs": "Legs"
        case "boots": "Boots"
        default: slot.prefix(1).uppercased() + slot.dropFirst()
        }
    }

    public static func isArmor(_ slot: String) -> Bool {
        slot == "helm" || slot == "chest" || slot == "legs" || slot == "boots"
    }
}

/// Fills an empty slot with the strongest piece that fits. A slot that already has gear is left alone.
public enum GearEquip {
    public static func fill(slot: String, wornID: String?, choices: [LootItem], p0: Double, h0: Double) -> String? {
        guard wornID == nil else { return nil }
        let fits = choices.filter { $0.slot == slot }
        return fits.max { worse($0, than: $1, slot: slot, p0: p0, h0: h0) }?.id
    }

    private static func worse(_ lhs: LootItem, than rhs: LootItem, slot: String, p0: Double, h0: Double) -> Bool {
        let left = score(lhs, slot: slot, p0: p0, h0: h0)
        let right = score(rhs, slot: slot, p0: p0, h0: h0)
        if abs(left - right) > 0.000_001 { return left < right }
        if lhs.itemLevel != rhs.itemLevel { return lhs.itemLevel < rhs.itemLevel }
        let ranks = ["common": 0, "rare": 1, "unique": 2]
        let leftRank = ranks[lhs.rarity] ?? 0
        let rightRank = ranks[rhs.rarity] ?? 0
        if leftRank != rightRank { return leftRank < rightRank }
        return lhs.id > rhs.id
    }

    private static func score(_ item: LootItem, slot: String, p0: Double, h0: Double) -> Double {
        if GearSlots.isArmor(slot) {
            return LootScore.toughness(itemLevel: item.itemLevel, affixes: item.affixes, h0: h0)
        }
        return LootScore.damage(itemLevel: item.itemLevel, affixes: item.affixes, p0: p0)
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

    /// Marks against the piece actually worn in this slot. An empty slot is level, not an upgrade over a phantom.
    public static func marks(for item: LootItem, worn: LootItem?, p0: Double, h0: Double) -> (Int, Int) {
        guard let worn, worn.id != item.id else { return (0, 0) }
        return (
            arrow(new: damage(itemLevel: item.itemLevel, affixes: item.affixes, p0: p0), old: damage(itemLevel: worn.itemLevel, affixes: worn.affixes, p0: p0)),
            arrow(new: toughness(itemLevel: item.itemLevel, affixes: item.affixes, h0: h0), old: toughness(itemLevel: worn.itemLevel, affixes: worn.affixes, h0: h0))
        )
    }
}

/// Armor rolls become bonus hit points and an armor rating. Weapon power stays on `BuildForecast`.
public enum WornArmor {
    public static func contribution(pieces: [(itemLevel: Int, affixes: [LootAffixRoll])], h0: Double) -> (bonusHP: Double, armor: Double) {
        var curves = BalanceCurves()
        var bonus = 0.0
        var rating = 0.0
        for piece in pieces {
            let hp = curves.heroHitPoints(h0: h0, itemLevel: piece.itemLevel)
            bonus += hp * piece.affixes.filter { $0.stat == "maxHP" }.reduce(0) { $0 + $1.value }
            rating += hp * piece.affixes.filter { $0.stat == "armor" }.reduce(0) { $0 + $1.value }
        }
        return (bonus, rating)
    }
}

public struct SheetLine: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var value: String

    public init(id: String, name: String, value: String) {
        self.id = id
        self.name = name
        self.value = value
    }
}

/// The numbers the next fight uses from the worn loadout.
/// Weapon affixes raise that weapon's power. Crit on a piece does the same; the crit roll stays the base, plus a melee innate.
public enum HeroSheet {
    public static func lines(
        melee: LootItem?, ranged: LootItem?, relicAffixes: [LootAffixRoll],
        armor: [(itemLevel: Int, affixes: [LootAffixRoll])],
        level: Int, perLevelHP: Double, p0: Double, h0: Double,
        baseCrit: Double, innateCrit: Double, meleeRate: Double?, rangedRate: Double?
    ) -> [SheetLine] {
        var rows = [
            SheetLine(id: "melee", name: "Melee", value: power(melee, p0: p0)),
            SheetLine(id: "ranged", name: "Ranged", value: power(ranged, p0: p0)),
        ]
        let worn = WornArmor.contribution(pieces: armor, h0: h0)
        let bonus = worn.bonusHP + HeroProgress.bonusHP(level: level, perLevel: perLevelHP)
        rows.append(SheetLine(id: "hp", name: "Bonus HP", value: NumberFormat.short(bonus)))
        rows.append(SheetLine(id: "armor", name: "Armor", value: NumberFormat.short(worn.armor)))
        rows.append(SheetLine(id: "crit", name: "Crit", value: AffixFormat.percent(baseCrit)))
        if innateCrit > 0.000_001 {
            rows.append(SheetLine(id: "meleeCrit", name: "Melee crit", value: AffixFormat.percent(baseCrit + innateCrit)))
        }
        if let meleeRate {
            rows.append(SheetLine(id: "meleeRate", name: "Melee speed", value: AffixFormat.perSecond(meleeRate)))
        }
        if let rangedRate {
            rows.append(SheetLine(id: "rangedRate", name: "Ranged speed", value: AffixFormat.perSecond(rangedRate)))
        }
        let relicDamage = relicAffixes.reduce(0.0) { $1.stat == "relicDamage" ? $0 + $1.value : $0 }
        let haste = relicAffixes.reduce(0.0) { $1.stat == "cooldownReduction" ? $0 + $1.value : $0 }
        if relicDamage > 0.000_001 {
            rows.append(SheetLine(id: "relic", name: "Relic damage", value: "+\(AffixFormat.percent(relicDamage))"))
        }
        if haste > 0.000_001 {
            rows.append(SheetLine(id: "cooldown", name: "Cooldown", value: "-\(AffixFormat.percent(haste))"))
        }
        return rows
    }

    private static func power(_ item: LootItem?, p0: Double) -> String {
        guard let item else { return "—" }
        return NumberFormat.short(LootScore.damage(itemLevel: item.itemLevel, affixes: item.affixes, p0: p0))
    }
}

public extension RelicDefinition {
    /// Scales damage opcodes by `relicDamage` and shortens cooldown by `cooldownReduction`. Other stats are left alone.
    func tuned(by affixes: [LootAffixRoll]) -> RelicDefinition {
        var relic = self
        let damage = affixes.reduce(0.0) { $1.stat == "relicDamage" ? $0 + $1.value : $0 }
        let haste = affixes.reduce(0.0) { $1.stat == "cooldownReduction" ? $0 + $1.value : $0 }
        if damage != 0 {
            relic.opcodes = relic.opcodes.map { spec in
                var spec = spec
                if let coefficient = spec.coefficient, spec.op == "damage" || spec.op == "zone" {
                    spec.coefficient = coefficient * (1 + damage)
                }
                return spec
            }
        }
        if haste != 0 {
            relic.cooldown *= max(0, 1 - haste)
        }
        return relic
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

    /// Pity after the items that fit. Dropped rolls do not move the streak.
    public static func pity(starting: Int, kept: [LootItem]) -> Int {
        var pity = starting
        for item in kept {
            _ = applyPity(rolled: item.rarity, pity: &pity)
        }
        return pity
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
        let rolled = LootItem(
            id: "\(table.idPrefix)-\(index)",
            definition: definition,
            name: name,
            slot: slot,
            itemLevel: itemLevel,
            rarity: rarity,
            affixes: affixes,
            signature: unique?.id,
            damageArrow: 0,
            toughnessArrow: 0
        )
        let marks = LootScore.marks(for: rolled, worn: worn, p0: p0, h0: h0)
        return LootItem(
            id: rolled.id, definition: definition, name: name, slot: slot, itemLevel: itemLevel, rarity: rarity,
            affixes: affixes, signature: unique?.id, damageArrow: marks.0, toughnessArrow: marks.1
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
