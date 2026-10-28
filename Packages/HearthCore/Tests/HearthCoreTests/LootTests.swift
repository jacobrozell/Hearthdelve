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
