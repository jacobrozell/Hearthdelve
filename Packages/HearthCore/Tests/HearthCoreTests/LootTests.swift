import XCTest
@testable import HearthCore

final class LootTests: XCTestCase {
    func testSharesMatchTheDepthTable() {
        let early = LootRoller.shares(depth: 1, elite: false)
        XCTAssertEqual(early.common, 6_000)
        XCTAssertEqual(early.rare, 3_200)
        XCTAssertEqual(early.unique, 800)
        let late = LootRoller.shares(depth: 100, elite: false)
        XCTAssertEqual(late.common, 4_500)
        XCTAssertEqual(late.rare, 4_000)
        XCTAssertEqual(late.unique, 1_500)
        let capped = LootRoller.shares(depth: 250, elite: false)
        XCTAssertEqual(capped.common, late.common)
        let elite = LootRoller.shares(depth: 1, elite: true)
        XCTAssertEqual(elite.common, 0)
        XCTAssertEqual(elite.rare, 7_500)
        XCTAssertEqual(elite.unique, 2_500)
        for depth in 1...120 {
            let shares = LootRoller.shares(depth: depth, elite: false)
            XCTAssertEqual(shares.common + shares.rare + shares.unique, 10_000)
        }
    }

    func testFortyRaresUpgradeTheNext() {
        var pity = 0
        for _ in 0..<40 {
            XCTAssertEqual(LootRoller.applyPity(rolled: "rare", pity: &pity), "rare")
        }
        XCTAssertEqual(pity, 40)
        XCTAssertEqual(LootRoller.applyPity(rolled: "rare", pity: &pity), "unique")
        XCTAssertEqual(pity, 0)
        pity = 12
        XCTAssertEqual(LootRoller.applyPity(rolled: "common", pity: &pity), "common")
        XCTAssertEqual(pity, 0)
        pity = 12
        XCTAssertEqual(LootRoller.applyPity(rolled: "unique", pity: &pity), "unique")
        XCTAssertEqual(pity, 0)
    }

    func testItemLevelAndGuardianUnique() {
        var rng = RNGStreams(seed: 3).loot
        let rolled = LootRoller.roll(depth: 4, normalKills: 2, eliteKills: 1, guardian: true, table: sampleTable(pity: 0), rng: &rng, p0: 10, h0: 15)
        XCTAssertEqual(rolled.items.count, 6)
        XCTAssertTrue(rolled.items.allSatisfy { $0.itemLevel == 14 })
        XCTAssertTrue(rolled.items.contains { $0.rarity == "unique" && $0.signature != nil })
        XCTAssertTrue(rolled.items.allSatisfy { $0.markedLine.suffix(2).allSatisfy { "+-=".contains($0) } })
        var again = RNGStreams(seed: 3).loot
        XCTAssertEqual(LootRoller.roll(depth: 4, normalKills: 2, eliteKills: 1, guardian: true, table: sampleTable(pity: 0), rng: &again, p0: 10, h0: 15), rolled)
    }

    func testAHigherItemLevelPointsUp() {
        let worn = LootItem.plain(id: "worn", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")
        let found = LootAffixRoll(id: "melee_damage", stat: "meleeDamage", value: 0.05)
        let damage = LootScore.damage(itemLevel: 21, affixes: [found], p0: 10)
        let old = LootScore.damage(itemLevel: worn.itemLevel, affixes: [], p0: 10)
        XCTAssertEqual(LootScore.arrow(new: damage, old: old), 1)
        XCTAssertEqual(LootScore.arrow(new: old, old: old), 0)
    }

    func testTheBagKeepsUniquesWhenItIsNearlyFull() {
        let common = LootItem.plain(id: "c", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")
        var unique = common
        unique.id = "u"
        unique.rarity = "unique"
        let kept = LootRoller.admit([common, unique], room: 1)
        XCTAssertEqual(kept.map(\.id), ["u"])
        XCTAssertEqual(LootRoller.pity(starting: 12, kept: kept), 0)
        XCTAssertEqual(LootRoller.pity(starting: 12, kept: LootRoller.admit([common, unique], room: 0)), 12)
    }

    func testAnEmptySlotTakesTheStrongerPieceAndAFilledSlotStays() {
        let weak = LootItem.plain(id: "weak", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")
        var strong = weak
        strong.id = "strong"
        strong.itemLevel = 20
        XCTAssertEqual(GearEquip.fill(slot: "melee", wornID: nil, choices: [weak, strong], p0: 10, h0: 100), "strong")
        XCTAssertNil(GearEquip.fill(slot: "melee", wornID: "weak", choices: [strong], p0: 10, h0: 100))
        XCTAssertNil(GearEquip.fill(slot: "ranged", wornID: nil, choices: [weak, strong], p0: 10, h0: 100))
        var tough = LootItem.plain(id: "tough", name: "Helm", slot: "helm", itemLevel: 11, definition: "helm")
        tough.affixes = [LootAffixRoll(id: "ar", stat: "armor", value: 0.2)]
        let plain = LootItem.plain(id: "plain", name: "Helm", slot: "helm", itemLevel: 11, definition: "helm")
        XCTAssertEqual(GearEquip.fill(slot: "helm", wornID: nil, choices: [plain, tough], p0: 10, h0: 100), "tough")
    }

    func testAnEmptySlotIsNotAnUpgrade() {
        let found = LootItem.plain(id: "new", name: "Sword", slot: "melee", itemLevel: 20, definition: "sword")
        XCTAssertEqual(LootScore.marks(for: found, worn: nil, p0: 10, h0: 100).0, 0)
        let worn = LootItem.plain(id: "old", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")
        XCTAssertEqual(LootScore.marks(for: found, worn: worn, p0: 10, h0: 100).0, 1)
    }

    func testRelicAffixesReachTheFlask() {
        let rolls = [
            LootAffixRoll(id: "relic_damage", stat: "relicDamage", value: 0.5),
            LootAffixRoll(id: "cooldown", stat: "cooldownReduction", value: 0.5),
        ]
        let tuned = CellarFight.flask.tuned(by: rolls)
        XCTAssertEqual(tuned.cooldown, CellarFight.flask.cooldown * 0.5, accuracy: 0.000_001)
        XCTAssertEqual(tuned.opcodes[0].coefficient ?? 0, (CellarFight.flask.opcodes[0].coefficient ?? 0) * 1.5, accuracy: 0.000_001)
        XCTAssertEqual(tuned.opcodes[1].coefficient ?? 0, (CellarFight.flask.opcodes[1].coefficient ?? 0) * 1.5, accuracy: 0.000_001)
    }

    func testADeathStillRollsTheKills() {
        var setup = Fixture.setup(relics: [], tactics: [])
        setup.rift = RiftConfig(mode: .delve, floors: 1, guardian: nil, loot: sampleTable(pity: 0))
        var world = RiftWorld(seed: 9, setup: setup)
        world.absorb([KillCredit(kind: .fodder, elite: false, rare: false)])
        world.sim.room.heroDown = true
        world.sim.room.actors[0].hp = 0
        let snapshot = world.step(commands: [])
        let result = snapshot.riftResult
        XCTAssertEqual(result?.died, true)
        XCTAssertEqual(result?.keptLoot, true)
        XCTAssertEqual(result?.items.count, 1)
        XCTAssertEqual(result?.items.first?.itemLevel, setup.depth + 10)
        XCTAssertEqual(result?.loot, result?.items.map(\.markedLine))
    }

    func testARolledAffixReadsAsAPercentAndRaisesWeaponPower() {
        XCTAssertEqual(AffixFormat.percent(0.06), "6%")
        XCTAssertEqual(AffixFormat.percent(0.0644), "6.4%")
        XCTAssertEqual(AffixFormat.line(name: "Ranged Damage", value: 0.0644), "Ranged Damage +6.4%")
        XCTAssertEqual(AffixFormat.perSecond(1), "1/s")
        XCTAssertEqual(AffixFormat.perSecond(1.3), "1.3/s")

        let plain = LootItem.plain(id: "sling", name: "Sling", slot: "ranged", itemLevel: 11, definition: "sling")
        var rolled = plain
        rolled.affixes = [LootAffixRoll(id: "ranged_damage", stat: "rangedDamage", value: 0.06)]
        var critPiece = LootItem.plain(id: "sword", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")
        critPiece.affixes = [LootAffixRoll(id: "crit_chance", stat: "critChance", value: 0.05)]
        let bare = HeroSheet.lines(
            melee: nil, ranged: plain, relicAffixes: [], armor: [],
            level: 1, perLevelHP: 8, p0: 10, h0: 160, baseCrit: 0.05, innateCrit: 0, meleeRate: nil, rangedRate: 1.3
        )
        let buffed = HeroSheet.lines(
            melee: critPiece, ranged: rolled, relicAffixes: [
                LootAffixRoll(id: "relic_damage", stat: "relicDamage", value: 0.08),
                LootAffixRoll(id: "cooldown", stat: "cooldownReduction", value: 0.04),
            ],
            armor: [(itemLevel: 11, affixes: [LootAffixRoll(id: "max_hp", stat: "maxHP", value: 0.1)])],
            level: 3, perLevelHP: 8, p0: 10, h0: 160, baseCrit: 0.05, innateCrit: 0.15, meleeRate: 0.7, rangedRate: 1.3
        )
        XCTAssertEqual(bare.first { $0.id == "melee" }?.value, "—")
        XCTAssertEqual(bare.first { $0.id == "ranged" }?.value, NumberFormat.short(LootScore.damage(itemLevel: 11, affixes: [], p0: 10)))
        XCTAssertEqual(bare.first { $0.id == "crit" }?.value, "5%")
        XCTAssertNil(bare.first { $0.id == "meleeCrit" })
        XCTAssertNotEqual(buffed.first { $0.id == "ranged" }?.value, bare.first { $0.id == "ranged" }?.value)
        XCTAssertEqual(buffed.first { $0.id == "crit" }?.value, "5%")
        XCTAssertEqual(buffed.first { $0.id == "meleeCrit" }?.value, "20%")
        XCTAssertEqual(buffed.first { $0.id == "meleeRate" }?.value, "0.7/s")
        XCTAssertEqual(buffed.first { $0.id == "relic" }?.value, "+8%")
        XCTAssertEqual(buffed.first { $0.id == "cooldown" }?.value, "-4%")
        let worn = WornArmor.contribution(pieces: [(itemLevel: 11, affixes: [LootAffixRoll(id: "max_hp", stat: "maxHP", value: 0.1)])], h0: 160)
        XCTAssertEqual(buffed.first { $0.id == "hp" }?.value, NumberFormat.short(worn.bonusHP + 16))
        XCTAssertNotEqual(buffed.first { $0.id == "melee" }?.value, NumberFormat.short(LootScore.damage(itemLevel: 11, affixes: [], p0: 10)))
    }

    private func sampleTable(pity: Int) -> LootTable {
        let affix = ItemAffixDefinition(id: "melee_damage", name: "Melee Damage", stat: "meleeDamage", min: 0.04, max: 0.08, slots: ["melee"])
        return LootTable(
            bases: [LootBase(id: "sword", name: "Sword", slot: "melee")],
            affixes: [affix],
            uniques: [LootUnique(id: "cinderfang", name: "Cinderfang", slot: "melee")],
            equipped: [LootItem.plain(id: "worn-melee", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")],
            pity: pity,
            idPrefix: "test"
        )
    }
}
