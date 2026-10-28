import XCTest
@testable import HearthContent
import HearthCore

final class ContentTests: XCTestCase {
    func testLaunchCatalogValidates() throws {
        let catalog = try ContentCatalog.load(from: try contentRoot())
        XCTAssertNoThrow(try catalog.validate(artEntries: try artEntries()))
        XCTAssertEqual(catalog.biomes.version, 1)
        XCTAssertEqual(catalog.biomes.placement(at: 1)?.biomeID, "mossy_cellars")
        XCTAssertEqual(catalog.biomes.placement(at: 25)?.biomeID, "drowned_library")
        XCTAssertEqual(catalog.biomes.placement(at: 51)?.echo, true)
        XCTAssertFalse(catalog.affixSetIsLegal(["frozen", "jailer"]))
        XCTAssertTrue(catalog.affixSetIsLegal(["frozen", "molten"]))
        let ratio = catalog.tuning.combat.hp0 / catalog.tuning.combat.p0
        XCTAssertGreaterThanOrEqual(ratio, 1)
        XCTAssertLessThanOrEqual(ratio, 2)
    }

    func testLaunchCounts() throws {
        let catalog = try ContentCatalog.load(from: try contentRoot())
        XCTAssertEqual(catalog.weapons.count, 9)
        XCTAssertEqual(catalog.affixes.count, 12)
        XCTAssertEqual(catalog.events.count, 7)
        XCTAssertEqual(catalog.modifiers.count, 8)
        XCTAssertEqual(catalog.relics.count, 30)
        for element in EffectCatalog.relicElements {
            XCTAssertEqual(catalog.relics.filter { $0.tags.contains(element) }.count, 5, element)
        }
        XCTAssertEqual(catalog.charms.count, 24)
        XCTAssertEqual(catalog.uniques.count, 60)
        XCTAssertEqual(catalog.uniques.filter { $0.slot == "melee" || $0.slot == "ranged" }.count, 20)
        XCTAssertEqual(catalog.uniques.filter { ["helm", "chest", "legs", "boots"].contains($0.slot) }.count, 25)
        XCTAssertEqual(catalog.uniques.filter { $0.slot == "relic" }.count, 15)
        XCTAssertEqual(catalog.sets.count, 6)
        XCTAssertEqual(catalog.families.count, 15)
        XCTAssertEqual(catalog.mobs.count, 60)
        XCTAssertEqual(catalog.guardians.count, 15)
        XCTAssertEqual(catalog.wardens.count, 2)
        XCTAssertEqual(catalog.wanderers.count, 12)
        XCTAssertEqual(catalog.buildings.count, 12)
        XCTAssertEqual(catalog.bestiary().count, 77)
        for biome in catalog.biomes.segments[0].order {
            XCTAssertEqual(catalog.families.filter { $0.biome == biome }.count, 3, biome)
            XCTAssertEqual(catalog.guardians.filter { $0.biome == biome }.count, 3, biome)
        }
    }

    func testEveryKenneyCreatureAnchorsAFamily() throws {
        let catalog = try ContentCatalog.load(from: try contentRoot())
        let kenney = ["creature.slime", "creature.cyclops", "creature.crab_demon", "creature.bat", "creature.ghost",
                      "creature.spider", "creature.brown_rat", "creature.grey_rat"]
        for sprite in kenney {
            XCTAssertTrue(catalog.mobs.contains { $0.sprite == sprite }, sprite)
        }
        XCTAssertFalse(catalog.mobs.contains { $0.sprite.hasPrefix("wanderer.") })
    }

    func testM0SliceResolves() throws {
        let catalog = try ContentCatalog.load(from: try contentRoot())
        let setup = try catalog.m0Setup()
        XCTAssertEqual(setup.melee.id, "sword")
        XCTAssertEqual(setup.ranged.id, "bow")
        XCTAssertEqual(setup.relics.map(\.id), ["ember_flask", "lantern_ward"])
        XCTAssertEqual(setup.tactics.count, 3)
        XCTAssertEqual(setup.fodder.sprite, "creature.slime")
        XCTAssertEqual(setup.brute.sprite, "creature.cyclops")
        XCTAssertEqual(setup.shooter.sprite, "creature.bat")
        XCTAssertGreaterThanOrEqual(setup.brute.telegraphSeconds ?? 0, 0.6)
        XCTAssertEqual(setup.room.width, 16)
    }

    func testCinderfangEnqueuesEmberFlaskOpcodes() throws {
        let catalog = try ContentCatalog.load(from: try contentRoot())
        let setup = try catalog.setup(loadout: "ember_bruiser", depth: 25)
        XCTAssertEqual(setup.signatures.first?.hook, "onStun")
        XCTAssertEqual(setup.signatures.first?.opcodes, catalog.relics.first { $0.id == "ember_flask" }?.opcodes)
    }

    func testContentVersionIsStable() throws {
        let left = try ContentCatalog.load(from: try contentRoot())
        let right = try ContentCatalog.load(from: try contentRoot())
        XCTAssertEqual(left.version, right.version)
        XCTAssertFalse(left.version.isEmpty)
    }

    func testBestiaryEdgesComeFromRole() throws {
        let catalog = try ContentCatalog.load(from: try contentRoot())
        let cards = catalog.bestiary()
        XCTAssertEqual(Set(cards.map(\.id)).count, cards.count)
        let brute = try XCTUnwrap(cards.first { $0.creature == "cellar_cyclops" })
        XCTAssertEqual(brute.edges, [6, 2, 4, 2])
        let swarm = try XCTUnwrap(cards.first { $0.creature == "grey_rat" })
        XCTAssertEqual(Set(swarm.edges).count, 1)
        XCTAssertEqual(cards.filter { $0.kind == .guardian }.count, 15)
    }

    func testMissingRelicFailsTheBuild() throws {
        var catalog = try ContentCatalog.load(from: try contentRoot())
        catalog.loadouts[0].relics.append("not_a_relic")
        XCTAssertThrowsError(try catalog.validate()) { error in
            let validation = error as? ContentValidation
            XCTAssertEqual(validation?.issues.contains { $0.domain == "hd.content" && $0.code == "missing_definition" }, true)
        }
    }

    func testRulesCatchBadRows() throws {
        var catalog = try ContentCatalog.load(from: try contentRoot())
        catalog.mobs[0].sprite = "wanderer.smith"
        catalog.uniques[0].effect = SignatureSpec(hook: "onNothing")
        catalog.relics.removeAll { $0.tags.contains("frost") && $0.opcodes.contains { $0.op == "root" } }
        XCTAssertThrowsError(try catalog.validate()) { error in
            let messages = (error as? ContentValidation)?.issues.map(\.message) ?? []
            XCTAssertTrue(messages.contains { $0.contains("Wanderer sprite") })
            XCTAssertTrue(messages.contains { $0.contains("unknown hook") })
            XCTAssertTrue(messages.contains { $0.contains("No frost Relic offers control") })
        }
    }

    private func artEntries() throws -> Set<String> {
        let url = try contentRoot().deletingLastPathComponent().appendingPathComponent("docs/art/kenney-map.json")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        return Set((object?["entries"] as? [String: Any])?.keys.map { $0 } ?? [])
    }

    private func contentRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.path != "/" {
            let candidate = url.appendingPathComponent("Content/tuning.json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return url.appendingPathComponent("Content")
            }
            url.deleteLastPathComponent()
        }
        throw ContentError.missing("Content/tuning.json")
    }
}
