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

    func testAMissingRerollCountStartsAtZero() throws {
        var save = SaveGame.newGame()
        XCTAssertTrue(save.inventory.store(sampleItem("a")))
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(save)) as! [String: Any]
        var inventory = object["inventory"] as! [String: Any]
        var bag = inventory["bag"] as! [[String: Any]]
        bag[0].removeValue(forKey: "rerolls")
        inventory["bag"] = bag
        object["inventory"] = inventory
        let loaded = try SaveMigrator.load(JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(loaded.inventory.bag[0].rerolls, 0)
        XCTAssertEqual(loaded.schemaVersion, 1)
    }

    func testAnOlderTacticStringStillDecodes() throws {
        let save = SaveGame.newGame()
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(save)) as! [String: Any]
        var loadouts = object["loadouts"] as! [[String: Any]]
        var first = loadouts[0]
        first["tactics"] = [["condition": "selfHPBelow", "action": "potion"]]
        loadouts[0] = first
        object["loadouts"] = loadouts
        let loaded = try SaveMigrator.load(JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(loaded.loadouts[0].tactics.count, 1)
        XCTAssertEqual(loaded.loadouts[0].tactics[0].kind, "selfHPBelow")
        XCTAssertEqual(loaded.loadouts[0].tactics[0].action, "potion")
        XCTAssertNil(loaded.loadouts[0].tactics[0].value)
    }

    func testTheStashCapsAtOneHundredAndMovesBothWays() throws {
        var inventory = SaveGame.newGame().inventory
        inventory.bag = [sampleItem("worn"), sampleItem("loose")]
        XCTAssertEqual(inventory.moveToStash(id: "worn", equipped: true), "equipped")
        XCTAssertEqual(inventory.bag.map(\.id), ["worn", "loose"])
        XCTAssertNil(inventory.moveToStash(id: "loose", equipped: false))
        XCTAssertEqual(inventory.stash.map(\.id), ["loose"])
        XCTAssertFalse(inventory.bag.contains { $0.id == "loose" })
        XCTAssertNil(inventory.moveToBag(id: "loose"))
        XCTAssertTrue(inventory.bag.contains { $0.id == "loose" })
        XCTAssertTrue(inventory.stash.isEmpty)
        inventory.stash = (0..<InventorySave.stashCapacity).map { sampleItem("s\($0)") }
        XCTAssertEqual(inventory.moveToStash(id: "loose", equipped: false), "stash")
        XCTAssertEqual(inventory.stash.count, 100)
        inventory.bag = (0..<InventorySave.bagCapacity).map { sampleItem("b\($0)") }
        inventory.stash = [sampleItem("kept")]
        XCTAssertEqual(inventory.moveToBag(id: "kept"), "bag")
        XCTAssertEqual(inventory.bag.count, 40)
        XCTAssertEqual(inventory.stash.map(\.id), ["kept"])
        var save = SaveGame.newGame()
        save.inventory.stash = (0..<101).map { sampleItem("over\($0)") }
        let loaded = try SaveMigrator.load(JSONEncoder().encode(save))
        XCTAssertEqual(loaded.inventory.stash.count, 100)
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

    func testAMissingSaveLoadsThePreviousCopy() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("hearth-save-\(UUID().uuidString)", isDirectory: true)
        let store = SaveStore(directory: directory)
        var save = SaveGame.newGame()
        try store.write(save)
        save.hero.level = 4
        try store.write(save)
        try FileManager.default.removeItem(at: directory.appendingPathComponent("save.json"))
        XCTAssertEqual(try store.load().hero.level, 1)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("save.json"))
        XCTAssertEqual(try store.load().hero.level, 1)
    }

    func testLoadClampsTheBagAndJoinsTheGlyphBanks() throws {
        var save = SaveGame.newGame()
        save.inventory.bag = (0..<45).map { sampleItem("\($0)") }
        save.hero.bankedGlyphPoints = 3
        let loaded = try SaveMigrator.load(try JSONEncoder().encode(save))
        XCTAssertEqual(loaded.inventory.bag.count, 40)
        XCTAssertEqual(loaded.inventory.bag.last?.id, "39")
        XCTAssertEqual(loaded.hero.bankedGlyphPoints, 3)
        XCTAssertEqual(loaded.glyphs.bankedPoints, 3)
    }

    private func sampleItem(_ id: String) -> ItemSave {
        ItemSave(id: id, definition: "sword", itemLevel: 11, rarity: "common", quality: "standard", affixes: [], signature: nil, locked: false, favorite: false, glyphSockets: [])
    }
}
