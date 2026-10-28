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
}
