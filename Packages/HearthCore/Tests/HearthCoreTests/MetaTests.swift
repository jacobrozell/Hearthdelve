import XCTest
@testable import HearthCore

final class MetaTests: XCTestCase {
    private let curve = XPCurveTuning(base: 100, growth: 1.08)
    private let smith = SmithTuning(commonDust: 5, rareShards: 2, uniqueEmbers: 1, raiseDust: 8, raiseGold: 10, raiseGrowth: 1.12)

    func testOneClearAdvancesALevelAndBanksAGlyphPoint() {
        let first = HeroProgress.xpToAdvance(from: 1, curve: curve)
        let second = HeroProgress.xpToAdvance(from: 2, curve: curve)
        XCTAssertEqual(first, 100)
        XCTAssertEqual(second, first * curve.growth)
        let grant = HeroProgress.apply(xp: HeroProgress.riftXP(level: 1, curve: curve), level: 1, xp: 0, glyphPoints: 0, curve: curve)
        XCTAssertEqual(grant.level, 2)
        XCTAssertEqual(grant.levelsGained, 1)
        XCTAssertEqual(grant.glyphPoints, 1)
        XCTAssertEqual(grant.xp, 0, accuracy: 0.000_001)
        XCTAssertEqual(HeroProgress.bonusHP(level: 1, perLevel: 8), 0)
        XCTAssertEqual(HeroProgress.bonusHP(level: grant.level, perLevel: 8), 8)
        XCTAssertEqual(CellarFight.tuning.riftGold, 25)
        let common = LootItem.plain(id: "c", name: "Sword", slot: "melee", itemLevel: 11, definition: "sword")
        var unique = common
        unique.id = "u"
        unique.rarity = "unique"
        let kept = LootRoller.admit([common, unique], room: 1)
        XCTAssertEqual(kept.map(\.id), ["u"])
        XCTAssertEqual(LootRoller.pity(starting: 7, kept: kept), 0)
    }

    func testRaiseCaptionMatchesTheCharge() {
        XCTAssertEqual(SmithRules.raiseCaption(itemLevel: 11, bestDepth: 2, tuning: smith), "8 Dust, 10 Anula")
        XCTAssertEqual(SmithRules.raiseCaption(itemLevel: 12, bestDepth: 3, tuning: smith), "8.96 Dust, 11.20 Anula")
        XCTAssertEqual(SmithRules.rerollCaption(rarity: "rare", times: 0, tuning: smith), "4 Facets")
        XCTAssertEqual(SmithRules.rerollCaption(rarity: "unique", times: 0, tuning: smith), "2 Echoes")
        XCTAssertEqual(SmithRules.craftCaption(tuning: smith), "8 Facets")
        XCTAssertEqual(SmithRules.transmuteCaption(tuning: smith), "12 Echoes")
        XCTAssertEqual(TacticLibrary.kindLabel("soulsAtLeast"), "Charge")
        XCTAssertEqual(TacticLibrary.caption(TacticCondition(kind: "soulsAtLeast", value: 30)), "Charge ≥ 30")
        XCTAssertEqual(SmithRules.raiseCaption(itemLevel: 11, bestDepth: 1, tuning: smith), "Needs Depth 2")
    }

    func testArmorRollsSplitHitPointsAndRating() {
        let pieces = [(itemLevel: 11, affixes: [
            LootAffixRoll(id: "hp", stat: "maxHP", value: 0.1),
            LootAffixRoll(id: "ar", stat: "armor", value: 0.2),
        ])]
        let worn = WornArmor.contribution(pieces: pieces, h0: 100)
        XCTAssertGreaterThan(worn.bonusHP, 0)
        XCTAssertEqual(worn.armor, worn.bonusHP * 2, accuracy: 0.000_001)
    }

    func testLevelOneHundredDoesNotBecomeParagon() {
        let grant = HeroProgress.apply(xp: 1_000_000, level: 100, xp: 0, glyphPoints: 99, curve: curve)
        XCTAssertEqual(grant.level, 100)
        XCTAssertEqual(grant.levelsGained, 0)
        XCTAssertEqual(grant.glyphPoints, 99)
        XCTAssertEqual(HeroProgress.riftXP(level: 100, curve: curve), 0)
    }

    func testLevelHitPointsArriveThroughBonusHP() async {
        var raised = CellarFight.setup()
        raised.bonusHP = HeroProgress.bonusHP(level: 2, perLevel: CellarFight.tuning.heroHPPerLevel)
        let withLevel = await RiftActor(seed: 1, setup: raised).advance(ticks: 1)
        let plain = await RiftActor(seed: 1, setup: CellarFight.setup()).advance(ticks: 1)
        XCTAssertEqual(withLevel.heroMaxHP, plain.heroMaxHP + 8)
    }

    func testAutoSalvageKeepsWornRaresAndUniques() {
        let rules = [SmithRules.salvageCommon]
        let items = [
            SmithRules.SalvageCandidate(id: "c", rarity: "common", signature: nil, equipped: false, locked: false, favorite: false),
            SmithRules.SalvageCandidate(id: "worn", rarity: "common", signature: nil, equipped: true, locked: false, favorite: false),
            SmithRules.SalvageCandidate(id: "locked", rarity: "common", signature: nil, equipped: false, locked: true, favorite: false),
            SmithRules.SalvageCandidate(id: "rare", rarity: "rare", signature: nil, equipped: false, locked: false, favorite: false),
            SmithRules.SalvageCandidate(id: "unique", rarity: "unique", signature: "cinderfang", equipped: false, locked: false, favorite: false),
        ]
        let picks = SmithRules.autoSalvage(items: items, rules: rules, tuning: smith)
        XCTAssertEqual(picks.map(\.id), ["c"])
        XCTAssertEqual(picks[0].yield.dust, 5)
        let both = SmithRules.autoSalvage(items: items, rules: [SmithRules.salvageCommon, SmithRules.salvageRare], tuning: smith)
        XCTAssertEqual(both.map(\.id), ["c", "rare"])
        XCTAssertEqual(SmithRules.salvageNote(commons: 2, rares: 0), "Salvaged 2 Commons.")
        XCTAssertNil(SmithRules.salvageNote(commons: 0, rares: 0))
    }

    func testSalvageYieldsMatchTuning() {
        let common = SmithRules.salvage(rarity: "common", signature: nil, equipped: false, confirmed: false, tuning: smith)
        let rare = SmithRules.salvage(rarity: "rare", signature: nil, equipped: false, confirmed: false, tuning: smith)
        XCTAssertEqual(common, .granted(SalvageYield(dust: 5, shards: 0, embers: 0, codexSignature: nil)))
        XCTAssertEqual(rare, .granted(SalvageYield(dust: 0, shards: 2, embers: 0, codexSignature: nil)))
        let equipped = SmithRules.salvage(rarity: "common", signature: nil, equipped: true, confirmed: true, tuning: smith)
        XCTAssertEqual(equipped, .refused("equipped"))
    }

    func testUniqueSalvageAsksBeforeItRecords() {
        let asked = SmithRules.salvage(rarity: "unique", signature: "cinderfang", equipped: false, confirmed: false, tuning: smith)
        XCTAssertEqual(asked, .needsConfirmation)
        let granted = SmithRules.salvage(rarity: "unique", signature: "cinderfang", equipped: false, confirmed: true, tuning: smith)
        XCTAssertEqual(granted, .granted(SalvageYield(dust: 0, shards: 0, embers: 1, codexSignature: "cinderfang")))
        var codex: [String] = []
        SmithRules.record(signature: "cinderfang", codex: &codex)
        SmithRules.record(signature: "cinderfang", codex: &codex)
        XCTAssertEqual(codex, ["cinderfang"])
    }

    func testItemLevelStopsAtBestDepthPlusTen() {
        XCTAssertEqual(SmithRules.cap(bestDepth: 1), 11)
        XCTAssertEqual(SmithRules.cap(bestDepth: 4), 14)
        let blocked = SmithRules.raise(itemLevel: 11, bestDepth: 1, dust: 100, gold: 100, tuning: smith)
        XCTAssertEqual(blocked, .refused("cap"))
        let raised = SmithRules.raise(itemLevel: 11, bestDepth: 2, dust: 8, gold: 10, tuning: smith)
        XCTAssertEqual(raised, .raised(itemLevel: 12, dust: 8, gold: 10))
        let next = SmithRules.raiseCost(itemLevel: 12, tuning: smith)
        XCTAssertEqual(next.dust, 8 * 1.12)
        XCTAssertEqual(next.gold, 10 * 1.12)
        let poor = SmithRules.raise(itemLevel: 11, bestDepth: 2, dust: 7, gold: 10, tuning: smith)
        XCTAssertEqual(poor, .refused("cost"))
    }

    func testRerollCostDoublesOnTheSameItem() {
        XCTAssertEqual(SmithRules.rerollCost(rarity: "rare", times: 0, tuning: smith)?.shards, 4)
        XCTAssertEqual(SmithRules.rerollCost(rarity: "rare", times: 1, tuning: smith)?.shards, 8)
        XCTAssertEqual(SmithRules.rerollCost(rarity: "rare", times: 2, tuning: smith)?.shards, 16)
        XCTAssertEqual(SmithRules.rerollCost(rarity: "unique", times: 0, tuning: smith)?.embers, 2)
        XCTAssertEqual(SmithRules.rerollCost(rarity: "unique", times: 1, tuning: smith)?.embers, 4)
        XCTAssertNil(SmithRules.rerollCost(rarity: "common", times: 0, tuning: smith))
        let pool = [
            ItemAffixDefinition(id: "a", name: "A", stat: "critChance", min: 0.1, max: 0.1, slots: ["melee"]),
            ItemAffixDefinition(id: "b", name: "B", stat: "meleeDamage", min: 0.2, max: 0.2, slots: ["melee"]),
            ItemAffixDefinition(id: "c", name: "C", stat: "attackSpeed", min: 0.3, max: 0.3, slots: ["melee"]),
        ]
        let affixes = [
            LootAffixRoll(id: "a", stat: "critChance", value: 0.1),
            LootAffixRoll(id: "b", stat: "meleeDamage", value: 0.2),
        ]
        var rng = RNGStreams(seed: 1).loot
        let poor = SmithRules.reroll(
            rarity: "rare", slot: "melee", affixes: affixes, index: 0, times: 1,
            shards: 7, embers: 0, pool: pool, tuning: smith, rng: &rng
        )
        XCTAssertEqual(poor, .refused("cost"))
        let decision = SmithRules.reroll(
            rarity: "rare", slot: "melee", affixes: affixes, index: 0, times: 1,
            shards: 8, embers: 0, pool: pool, tuning: smith, rng: &rng
        )
        guard case .rerolled(let next, let shards, _) = decision else {
            return XCTFail("\(decision)")
        }
        XCTAssertEqual(shards, 8)
        XCTAssertEqual(next[1], affixes[1])
        XCTAssertNotEqual(next[0].id, "b")
        XCTAssertEqual(next.count, 2)
    }

    func testCraftRareUsesTheChosenSlotAndRefusesAFullBag() {
        let bases = [
            LootBase(id: "sword", name: "Sword", slot: "melee"),
            LootBase(id: "bow", name: "Bow", slot: "ranged"),
        ]
        let pool = [ItemAffixDefinition(id: "a", name: "A", stat: "critChance", min: 0.03, max: 0.06, slots: ["melee"])]
        var rng = RNGStreams(seed: 2).loot
        let full = SmithRules.craft(
            slot: "melee", typeID: "sword", bases: bases, affixes: pool, shards: 0,
            bagCount: 40, bagCapacity: 40, itemLevel: 11, tuning: smith, rng: &rng, id: "craft-full"
        )
        XCTAssertEqual(full, .refused("bag"))
        let broke = SmithRules.craft(
            slot: "melee", typeID: "sword", bases: bases, affixes: pool, shards: 7,
            bagCount: 0, bagCapacity: 40, itemLevel: 11, tuning: smith, rng: &rng, id: "craft-broke"
        )
        XCTAssertEqual(broke, .refused("cost"))
        let wrong = SmithRules.craft(
            slot: "ranged", typeID: "sword", bases: bases, affixes: pool, shards: 8,
            bagCount: 0, bagCapacity: 40, itemLevel: 11, tuning: smith, rng: &rng, id: "craft-wrong"
        )
        XCTAssertEqual(wrong, .refused("type"))
        let made = SmithRules.craft(
            slot: "melee", typeID: "sword", bases: bases, affixes: pool, shards: 8,
            bagCount: 39, bagCapacity: 40, itemLevel: 18, tuning: smith, rng: &rng, id: "craft-1"
        )
        guard case .crafted(let item, let shards) = made else { return XCTFail("\(made)") }
        XCTAssertEqual(shards, 8)
        XCTAssertEqual(item.rarity, "rare")
        XCTAssertEqual(item.definition, "sword")
        XCTAssertEqual(item.slot, "melee")
        XCTAssertEqual(item.itemLevel, 18)
        XCTAssertEqual(item.affixes.count, 1)
        XCTAssertNil(item.signature)
    }

    func testTransmuteBecomesAnotherUniqueOfTheSameSlot() {
        let uniques = [
            LootUnique(id: "cinderfang", name: "Cinderfang", slot: "melee"),
            LootUnique(id: "hearthguard", name: "Hearthguard", slot: "melee"),
            LootUnique(id: "thornwrap", name: "Thornwrap", slot: "chest"),
        ]
        var rng = RNGStreams(seed: 3).loot
        let rare = SmithRules.transmute(rarity: "rare", slot: "melee", currentID: "cinderfang", uniques: uniques, embers: 12, tuning: smith, rng: &rng)
        XCTAssertEqual(rare, .refused("rarity"))
        let poor = SmithRules.transmute(rarity: "unique", slot: "melee", currentID: "cinderfang", uniques: uniques, embers: 11, tuning: smith, rng: &rng)
        XCTAssertEqual(poor, .refused("cost"))
        let alone = SmithRules.transmute(rarity: "unique", slot: "chest", currentID: "thornwrap", uniques: uniques, embers: 12, tuning: smith, rng: &rng)
        XCTAssertEqual(alone, .refused("pool"))
        let decision = SmithRules.transmute(rarity: "unique", slot: "melee", currentID: "cinderfang", uniques: uniques, embers: 12, tuning: smith, rng: &rng)
        guard case .transmuted(let unique, let embers) = decision else { return XCTFail("\(decision)") }
        XCTAssertEqual(embers, 12)
        XCTAssertEqual(unique.id, "hearthguard")
        XCTAssertEqual(unique.slot, "melee")
    }

    func testLibraryEditsOneRuleAndRefusesAFourthSlot() {
        let start = TacticLibrary.resolved([], fallback: CellarFight.tactics)
        XCTAssertEqual(start.count, 3)
        XCTAssertEqual(
            TacticLibrary.line(index: 0, rule: start[0], relicName: { _ in "" }),
            "Tactic 1: HP below 35% → Potion"
        )
        XCTAssertEqual(
            TacticLibrary.line(index: 1, rule: start[1], relicName: { $0 == "lantern_ward" ? "Lantern Ward" : $0 }),
            "Tactic 2: elite within 4 → Lantern Ward"
        )
        let edited = TacticLibrary.replace(start, index: 0, condition: TacticCondition(kind: "always"), fallback: CellarFight.tactics)
        XCTAssertEqual(TacticLibrary.caption(edited![0].condition), "always")
        XCTAssertEqual(edited?[0].action, start[0].action)
        XCTAssertEqual(edited?[1], start[1])
        XCTAssertEqual(
            TacticLibrary.line(index: 0, rule: edited![0], relicName: { _ in "" }),
            "Tactic 1: always → Potion"
        )
        XCTAssertNil(TacticLibrary.replace(start, index: 3, condition: TacticCondition(kind: "always"), fallback: CellarFight.tactics))
        XCTAssertNil(TacticLibrary.replace(start, index: 0, condition: TacticCondition(kind: "and"), fallback: CellarFight.tactics))
        let nudged = TacticLibrary.nudge(start, index: 0, delta: 1, fallback: CellarFight.tactics)
        XCTAssertEqual(TacticLibrary.caption(nudged![0].condition), "HP below 40%")
        XCTAssertEqual(nudged?[0].action, start[0].action)
    }

    func testStashRefusesEquippedPiecesAndTheHundredAndFirst() {
        XCTAssertEqual(StashRules.capacity, 100)
        XCTAssertEqual(StashRules.refusal(equipped: true, stashCount: 0, bagCount: 1, bagCapacity: 40, toStash: true), "equipped")
        XCTAssertEqual(StashRules.refusal(equipped: false, stashCount: 100, bagCount: 1, bagCapacity: 40, toStash: true), "stash")
        XCTAssertNil(StashRules.refusal(equipped: false, stashCount: 99, bagCount: 1, bagCapacity: 40, toStash: true))
        XCTAssertEqual(StashRules.refusal(equipped: false, stashCount: 1, bagCount: 40, bagCapacity: 40, toStash: false), "bag")
        XCTAssertEqual(StashRules.note(for: "bag"), "The bag is full.")
        XCTAssertEqual(StashRules.note(for: "stash"), "The stash is full.")
    }

    func testTheHamletIsTwoScreensWideAndNamesTheCottages() {
        let map = VillageHamlet.make()
        XCTAssertGreaterThanOrEqual(map.columns, 24)
        XCTAssertEqual(map.tileset, "tiny-town")
        XCTAssertEqual(map.ground.count, map.columns * map.rows)
        XCTAssertEqual(map.props.count, map.ground.count)
        XCTAssertTrue(map.ground.allSatisfy { $0 > 0 })
        XCTAssertEqual(map.buildings.map(\.id), ["apothecary", "blacksmith", "well", "library", "map_room", "stash_house"])
        let well = map.buildings.first { $0.id == "well" }!
        XCTAssertEqual(well.accessibilityLabel, "The well")
        XCTAssertEqual(map.buildings.first { $0.id == "blacksmith" }?.accessibilityLabel, "Blacksmith")
        XCTAssertNil(map.buildings.first { $0.id == "blacksmith" }?.unlockDepth)
        XCTAssertEqual(map.buildings.first { $0.id == "apothecary" }?.unlockDepth, 2)
        XCTAssertEqual(map.buildings.first { $0.id == "library" }?.unlockDepth, 3)
        XCTAssertEqual(map.buildings.first { $0.id == "map_room" }?.unlockDepth, 5)
        XCTAssertEqual(map.buildings.first { $0.id == "stash_house" }?.unlockDepth, 8)
        XCTAssertEqual(map.buildings.first { $0.id == "library" }?.name, "Library")
        XCTAssertEqual(map.buildings.first { $0.id == "stash_house" }?.accessibilityLabel, "Stash House")
        XCTAssertEqual(map.props[well.row * map.columns + well.column], 105)
        let view = CGSize(width: 390, height: 844)
        let camera = VillageFrame.sceneCenter(building: well, rows: map.rows, tile: 32)
        let rect = VillageFrame.viewRect(building: well, rows: map.rows, camera: camera, viewSize: view, tile: 32)
        XCTAssertEqual(rect.midX, view.width / 2, accuracy: 0.5)
        XCTAssertEqual(rect.midY, view.height / 2, accuracy: 0.5)
        for building in map.buildings {
            XCTAssertGreaterThanOrEqual(building.column, 0)
            XCTAssertGreaterThanOrEqual(building.row, 0)
            XCTAssertLessThanOrEqual(building.column + building.width, map.columns)
            XCTAssertLessThanOrEqual(building.row + building.height, map.rows)
        }
    }
}
