import XCTest
@testable import HearthCore

final class CoreTests: XCTestCase {
    func testSplitMixSeedZero() {
        var mix = SplitMix64(seed: 0)
        XCTAssertEqual(mix.next(), 0xE220A8397B1DCDAF)
    }

    func testStreamsStayIndependent() {
        var streams = RNGStreams(seed: 1)
        let layout = streams.layout
        let combat = streams.combat
        _ = streams.loot.next()
        XCTAssertEqual(streams.layout, layout)
        XCTAssertEqual(streams.combat, combat)
        XCTAssertNotEqual(streams.loot, RNGStreams(seed: 1).loot)
    }

    func testTacticsFirstMatchSkipsUnreadyRules() {
        let rules = Fixture.tactics
        var context = TacticContext(hpFraction: 0.3, souls: 100, shield: 0, enemyDistances: [1, 4, 4, 16], eliteDistances: [9], targetDistance: 1, targetElite: false)
        XCTAssertEqual(Tactics.firstMatch(rules, context, ready: { _ in true }), 0)
        XCTAssertEqual(Tactics.firstMatch(rules, context, ready: { $0.kind != "potion" }), 1)
        context.hpFraction = 0.9
        context.eliteDistances = []
        context.enemyDistances = [1, 1, 1.2, 1.4, 1.6, 16]
        XCTAssertEqual(Tactics.firstMatch(rules, context, ready: { _ in true }), 2)
        context.enemyDistances = [1, 4]
        XCTAssertNil(Tactics.firstMatch(rules, context, ready: { _ in true }))
    }

    func testTacticRuleDecodesIfThen() throws {
        let json = #"{"if":{"kind":"enemiesWithin","count":3,"tiles":3},"then":{"kind":"relic","relic":"ember_flask"}}"#
        let rule = try JSONDecoder().decode(TacticRule.self, from: Data(json.utf8))
        let flask = TacticRule(TacticCondition(kind: "enemiesWithin", count: 3, tiles: 3), TacticAction(kind: "relic", relic: "ember_flask"))
        XCTAssertEqual(rule, flask)
    }

    func testCurvePins() {
        var curves = BalanceCurves(through: 300)
        XCTAssertEqual(curves.enemyHP.value(at: 0), 0x1.0000000000000p+0)
        XCTAssertEqual(curves.enemyHP.value(at: 1), 0x1.1eb851eb851ecp+0)
        XCTAssertEqual(curves.enemyHP.value(at: 10), 0x1.8d8c6f2096dbep+1)
        XCTAssertEqual(curves.enemyHP.value(at: 50), 0x1.21008f83403ccp+8)
        XCTAssertEqual(curves.enemyHP.value(at: 150), 0x1.705185b1ccda7p+24)
        XCTAssertEqual(curves.enemyHP.value(at: 300), 0x1.08f53d2a86a51p+49)
        XCTAssertEqual(curves.enemyDamage.value(at: 50), 0x1.7736809f0ff1cp+5)
        XCTAssertEqual(curves.power.value(at: 10), 0x1.4bffc0c03023ep+1)
        XCTAssertEqual(curves.heroHP.value(at: 150), curves.enemyDamage.value(at: 150))
        XCTAssertEqual(curves.requiredBuild.value(at: 0), 0x1.0000000000000p+0)
        XCTAssertEqual(curves.requiredBuild.value(at: 1), 0x1.04a7904a7904bp+0)
        XCTAssertEqual(curves.requiredBuild.value(at: 50), 0x1.3b1ee20b681cdp+1)
        XCTAssertEqual(curves.requiredBuild.value(at: 150), 0x1.dd7997462ecc8p+3)
        XCTAssertEqual(curves.requiredBuild.value(at: 300), 0x1.bd472bbdf210fp+7)
        XCTAssertLessThan(curves.requiredBuild.value(at: 50), 2.5)

        let extended = curves.enemyHP.value(at: 301)
        XCTAssertEqual(extended, curves.enemyHP.value(at: 300) * 1.12)
    }

    func testDamageFormulas() {
        let hit = CombatMath.outgoing(
            power: 10,
            coefficient: 1,
            additive: [0.1, 0.1],
            multipliers: [2],
            critDamage: 0.5,
            isCrit: false
        )
        XCTAssertEqual(hit, 24)
        let crit = CombatMath.outgoing(
            power: 10,
            coefficient: 1,
            additive: [0.1, 0.1],
            multipliers: [2],
            critDamage: 0.5,
            isCrit: true
        )
        XCTAssertEqual(crit, 36)

        let taken = CombatMath.incoming(raw: 3050, armor: 50, resist: 0, level: 60, reductions: [])
        XCTAssertEqual(taken, 3000)
        XCTAssertEqual(CombatMath.level(depth: 10), 70)
        XCTAssertFalse(CombatRoll.dodged(roll: 1, chance: 0))
        XCTAssertTrue(CombatRoll.dodged(roll: 1, chance: 1))
    }

    func testParGearIsTheBaselineAndBetterGearChangesTheBand() {
        XCTAssertEqual(BuildForecast.multiplier(depth: 1, weapons: [], p0: 10), 1)
        XCTAssertEqual(BuildForecast.band(depth: 1, weapons: [], p0: 10), .hard)
        let strong = LootItem.plain(id: "a", name: "Sword", slot: "melee", itemLevel: 40, definition: "sword")
        let pair = [strong, LootItem.plain(id: "b", name: "Bow", slot: "ranged", itemLevel: 40, definition: "bow")]
        XCTAssertGreaterThan(BuildForecast.multiplier(depth: 1, weapons: pair, p0: 10), 1)
        XCTAssertEqual(BuildForecast.band(depth: 1, weapons: pair, p0: 10), .easy)
        XCTAssertEqual(BiomeName.display(id: "drowned_library", echo: false), "Drowned Library")
        XCTAssertEqual(BiomeName.display(id: "mossy_cellars", echo: true), "Echo Mossy Cellars")
    }

    func testDepthAdvancesOnlyOnAFrontierClear() {
        XCTAssertEqual(DepthRules.nextBest(best: 4, foughtAt: 4, delta: 3, died: false), 7)
        XCTAssertEqual(DepthRules.nextBest(best: 4, foughtAt: 4, delta: 3, died: true), 4)
        XCTAssertEqual(DepthRules.nextBest(best: 4, foughtAt: 2, delta: 3, died: false), 4)
        XCTAssertEqual(DepthRules.nextBest(best: 4, foughtAt: 4, delta: 0, died: false), 4)
        XCTAssertTrue(DepthRules.delveAllowed(depth: 30, best: 30))
        XCTAssertTrue(DepthRules.deepRiftAllowed(depth: 25, best: 30))
        XCTAssertFalse(DepthRules.deepRiftAllowed(depth: 26, best: 30))
    }

    func testPowerScaleOfOneLeavesTheFight() {
        var scaled = CellarFight.setup()
        scaled.powerScale = 1
        let plain = RoomRun.run(seed: 1, setup: CellarFight.setup(), ticks: 40).hash
        XCTAssertEqual(RoomRun.run(seed: 1, setup: scaled, ticks: 40).hash, plain)
        scaled.powerScale = 4
        XCTAssertNotEqual(RoomRun.run(seed: 1, setup: scaled, ticks: 40).hash, plain)
    }

    func testDifficultyBands() {
        XCTAssertEqual(DifficultyBand.band(buildMultiplier: 1.5, required: 1), .easy)
        XCTAssertEqual(DifficultyBand.band(buildMultiplier: 1.499, required: 1), .fair)
        XCTAssertEqual(DifficultyBand.band(buildMultiplier: 1, required: 1), .fair)
        XCTAssertEqual(DifficultyBand.band(buildMultiplier: 0.999, required: 1), .hard)
        XCTAssertEqual(DifficultyBand.band(buildMultiplier: 0.7, required: 1), .hard)
        XCTAssertEqual(DifficultyBand.band(buildMultiplier: 0.699, required: 1), .deadly)
    }

    func testNumberSuffixes() {
        XCTAssertEqual(NumberFormat.short(999), "999")
        XCTAssertEqual(NumberFormat.short(1000), "1K")
        XCTAssertEqual(NumberFormat.short(1200), "1.2K")
        XCTAssertEqual(NumberFormat.short(1_500_000), "1.5M")
        XCTAssertEqual(NumberFormat.short(2_000_000_000), "2B")
        XCTAssertEqual(NumberFormat.short(-4500), "-4.5K")
    }

    func testEmberFlaskAndWard() {
        let flask = OpcodeSpec(op: "damage", coefficient: 3.8, element: "fire", radius: 3, duration: 0, fraction: nil, tiles: nil, kind: nil, taunts: nil, nextCrit: nil)
        let resolved = EffectRunner.resolve(flask, power: 10, maxHP: 100)
        XCTAssertEqual(resolved, .damage(amount: 38, element: "fire", radius: 3))

        let ward = OpcodeSpec(op: "shield", coefficient: nil, element: nil, radius: nil, duration: 6, fraction: 0.2, tiles: nil, kind: nil, taunts: nil, nextCrit: nil)
        XCTAssertEqual(EffectRunner.resolve(ward, power: 10, maxHP: 100), .shield(amount: 20, duration: 6))
        XCTAssertNil(EffectRunner.resolve(OpcodeSpec(op: "nope", coefficient: nil, element: nil, radius: nil, duration: nil, fraction: nil, tiles: nil, kind: nil, taunts: nil, nextCrit: nil), power: 1, maxHP: 1))
    }

    func testBiomeTableNeverRewritesADepthBelowANewSegment() {
        let launch = BiomeTable(version: 1, segments: [
            BiomeSegment(
                id: "launch",
                fromDepth: 1,
                bandWidth: 10,
                echoFromDepth: 51,
                order: ["mossy_cellars", "fungal_hollows", "drowned_library", "ember_forges", "starless_vault"]
            ),
        ])
        XCTAssertEqual(launch.placement(at: 1)?.biomeID, "mossy_cellars")
        XCTAssertEqual(launch.placement(at: 10)?.biomeID, "mossy_cellars")
        XCTAssertEqual(launch.placement(at: 11)?.biomeID, "fungal_hollows")
        XCTAssertEqual(launch.placement(at: 25)?.biomeID, "drowned_library")
        XCTAssertEqual(launch.placement(at: 50)?.echo, false)
        XCTAssertEqual(launch.placement(at: 51)?.biomeID, "mossy_cellars")
        XCTAssertEqual(launch.placement(at: 51)?.echo, true)
        XCTAssertEqual(launch.placement(at: 100)?.biomeID, "starless_vault")
        XCTAssertNil(launch.placement(at: 0))

        var expanded = launch
        expanded.segments.append(
            BiomeSegment(id: "expansion", fromDepth: 201, bandWidth: 10, echoFromDepth: nil, order: ["clockwork_warren"])
        )
        XCTAssertEqual(expanded.placement(at: 50), launch.placement(at: 50))
        XCTAssertEqual(expanded.placement(at: 200), launch.placement(at: 200))
        XCTAssertEqual(expanded.placement(at: 201)?.biomeID, "clockwork_warren")
        XCTAssertEqual(expanded.placement(at: 201)?.echo, false)
    }
}
