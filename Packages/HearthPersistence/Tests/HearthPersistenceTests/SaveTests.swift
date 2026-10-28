import XCTest
@testable import HearthPersistence

final class SaveTests: XCTestCase {
    func testRoundTripKeepsReservedSlots() throws {
        let save = SaveGame.newGame()
        XCTAssertEqual(save.schemaVersion, 1)
        XCTAssertFalse(save.glyphs.wired)
        XCTAssertEqual(save.soulCap(), 100)
        XCTAssertNil(save.seasonID)
        XCTAssertTrue(save.bestiary.isEmpty)
        XCTAssertTrue(save.companions.isEmpty)
        let data = try JSONEncoder().encode(save)
        let loaded = try SaveMigrator.load(data)
        XCTAssertEqual(loaded, save)
    }

    func testStoreKeepsThreeCopies() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("hearth-save-\(UUID().uuidString)", isDirectory: true)
        let store = SaveStore(directory: directory)
        var save = SaveGame.newGame()
        try store.write(save)
        save.hero.level = 2
        try store.write(save)
        save.hero.level = 3
        try store.write(save)
        XCTAssertEqual(try store.load().hero.level, 3)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        XCTAssertEqual(names, ["save.1.json", "save.2.json", "save.json"])
        let previous = try Data(contentsOf: directory.appendingPathComponent("save.1.json"))
        XCTAssertEqual(try SaveMigrator.load(previous).hero.level, 2)
    }

    func testOlderSchemaOneSaveKeepsDepthAtOne() throws {
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(SaveGame.newGame())) as! [String: Any]
        object.removeValue(forKey: "bestDepth")
        object.removeValue(forKey: "runSeed")
        var loaded = try SaveMigrator.load(try JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(loaded.bestDepth, 1)
        XCTAssertEqual(loaded.runSeed, 1)
        loaded.bestDepth = 6
        let again = try SaveMigrator.load(JSONEncoder().encode(loaded))
        XCTAssertEqual(again.bestDepth, 6)
    }

    func testOlderSchemaOneSaveStartsPityAtZero() throws {
        var save = SaveGame.newGame()
        XCTAssertTrue(save.inventory.store(sampleItem("a")))
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(save)) as! [String: Any]
        var inventory = object["inventory"] as! [String: Any]
        inventory.removeValue(forKey: "lootPity")
        object["inventory"] = inventory
        let loaded = try SaveMigrator.load(JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(loaded.inventory.lootPity, 0)
        XCTAssertEqual(loaded.inventory.bag.count, 1)
    }

    func testAMissingGlyphPointFieldStillLoads() throws {
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(SaveGame.newGame())) as! [String: Any]
        var hero = object["hero"] as! [String: Any]
        hero.removeValue(forKey: "bankedGlyphPoints")
        object["hero"] = hero
        let loaded = try SaveMigrator.load(try JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(loaded.hero.bankedGlyphPoints, 0)
        XCTAssertEqual(loaded.hero.level, 1)
        XCTAssertEqual(loaded.schemaVersion, 1)
    }

    func testTheBagStopsAtForty() {
        var inventory = SaveGame.newGame().inventory
        for index in 0..<InventorySave.bagCapacity {
            XCTAssertTrue(inventory.store(sampleItem("\(index)")))
        }
        XCTAssertFalse(inventory.store(sampleItem("overflow")))
        XCTAssertEqual(inventory.bag.count, 40)
    }

    private func sampleItem(_ id: String) -> ItemSave {
        ItemSave(id: id, definition: "sword", itemLevel: 11, rarity: "common", quality: "standard", affixes: [], signature: nil, locked: false, favorite: false, glyphSockets: [])
    }
}
