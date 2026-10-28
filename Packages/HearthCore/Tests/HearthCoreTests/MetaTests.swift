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

    func testTheHamletIsTwoScreensWideAndNamesTheCottages() {
        let map = VillageHamlet.make()
        XCTAssertGreaterThanOrEqual(map.columns, 24)
        XCTAssertEqual(map.tileset, "tiny-town")
        XCTAssertEqual(map.ground.count, map.columns * map.rows)
        XCTAssertEqual(map.props.count, map.ground.count)
        XCTAssertTrue(map.ground.allSatisfy { $0 > 0 })
        XCTAssertEqual(map.buildings.map(\.id), ["apothecary", "blacksmith", "well", "library", "map_room"])
        let well = map.buildings.first { $0.id == "well" }!
        XCTAssertEqual(well.accessibilityLabel, "The well")
        XCTAssertEqual(map.buildings.first { $0.id == "blacksmith" }?.accessibilityLabel, "Blacksmith")
        XCTAssertNil(map.buildings.first { $0.id == "blacksmith" }?.unlockDepth)
        XCTAssertEqual(map.buildings.first { $0.id == "apothecary" }?.unlockDepth, 2)
        XCTAssertEqual(map.buildings.first { $0.id == "library" }?.unlockDepth, 3)
        XCTAssertEqual(map.buildings.first { $0.id == "map_room" }?.unlockDepth, 5)
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
