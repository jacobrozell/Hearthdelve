import XCTest
@testable import HearthCore

final class LayoutTests: XCTestCase {
    func testTwoSeedsStayInsideTheMossyGraph() {
        let kit = mossyKit()
        for seed in [UInt64(1), 2] {
            var rng = RNGStreams(seed: seed).layout
            let plan = FloorLayout.generate(rng: &rng, templates: kit, lastFloor: false)
            XCTAssertTrue((4...8).contains(plan.rooms.count), "seed \(seed) rooms \(plan.rooms.count)")
            XCTAssertTrue((0...2).contains(plan.loops), "seed \(seed) loops \(plan.loops)")
            XCTAssertEqual(plan.entry, 0)
            XCTAssertNotEqual(plan.exit, plan.entry)
            XCTAssertEqual(plan.rooms.filter { $0.tag == "entry" }.count, 1)
            XCTAssertLessThanOrEqual(plan.rooms.filter { $0.tag == "side" }.count, 1)
            XCTAssertEqual(plan.rooms[plan.exit].tag, "stairs")
            XCTAssertNotNil(plan.nextHop(from: plan.entry))
            var again = RNGStreams(seed: seed).layout
            XCTAssertEqual(FloorLayout.generate(rng: &again, templates: kit, lastFloor: false), plan)
        }
        var last = RNGStreams(seed: 1).layout
        let arena = FloorLayout.generate(rng: &last, templates: kit, lastFloor: true)
        XCTAssertEqual(arena.rooms[arena.exit].tag, "arena")
    }

    func testAClearedRoomOpensTheNextRoomBeforeTheNextFloor() {
        var setup = Fixture.setup(relics: [], tactics: [])
        setup.rift = RiftConfig(mode: .delve, floors: 2, guardian: nil, templates: mossyKit())
        var world = RiftWorld(seed: 1, setup: setup)
        let first = world.snapshot().roomID
        XCTAssertEqual(world.plan?.rooms[world.roomIndex].tag, "entry")
        XCTAssertEqual(world.floor, 1)
        world.sim.room.actors.removeAll { $0.team == 1 }
        _ = world.step(commands: [])
        XCTAssertNotNil(world.sim.room.stairs)
        XCTAssertEqual(world.floor, 1)
        if let stairs = world.sim.room.stairs {
            world.sim.room.actors[0].x = stairs.x
            world.sim.room.actors[0].y = stairs.y
        }
        let moved = world.step(commands: [])
        XCTAssertEqual(world.floor, 1)
        XCTAssertNotEqual(moved.roomID, first)
        XCTAssertEqual(moved.roomID, world.sim.setup.room.id)
    }

    private func mossyKit() -> [RoomTemplate] {
        ["entry", "corridor", "small", "large", "side", "arena", "stairs", "alcove"].map { tag in
            var room = RoomTemplate.ascii(Self.rows, id: "mossy_\(tag)")
            room.tag = tag
            return room
        }
    }

    private static let rows = [
        "################",
        "#..S....S....S.#",
        "#..............#",
        "#S............S#",
        "#....#....#....#",
        "#....#....#....#",
        "#..............#",
        "#..............#",
        "#..............#",
        "#..............#",
        "#....#....#....#",
        "#....#....#....#",
        "#..............#",
        "#..............#",
        "#......H.......#",
        "################",
    ]
}
