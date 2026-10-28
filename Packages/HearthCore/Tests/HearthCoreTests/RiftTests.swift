import XCTest
@testable import HearthCore

final class RiftTests: XCTestCase {
    func testMeterFillUsesThePackTable() {
        XCTAssertEqual(RiftMeter.gain(kind: .fodder, elite: false, rare: false), RiftMeter.fodder)
        XCTAssertEqual(RiftMeter.fraction(RiftMeter.fodder), 0.01)
        // 5% is the midpoint of the 4–6% elite band and the champion-pack row.
        XCTAssertEqual(RiftMeter.gain(kind: .fodder, elite: true, rare: false), RiftMeter.elite)
        XCTAssertEqual(RiftMeter.fraction(RiftMeter.elite), 0.05)
        // 10% is the rare-pack row, inside the 8–10% band.
        XCTAssertEqual(RiftMeter.gain(kind: .brute, elite: false, rare: true), RiftMeter.rare)
        XCTAssertEqual(RiftMeter.fraction(RiftMeter.rare), 0.10)
        XCTAssertEqual(RiftMeter.gain(kind: .brute, elite: false, rare: false), RiftMeter.role)
        XCTAssertEqual(RiftMeter.gain(kind: .shooter, elite: false, rare: false), RiftMeter.role)
        XCTAssertEqual(RiftMeter.fraction(100 * RiftMeter.fodder), 1)
        XCTAssertEqual(RiftMeter.fraction(20 * RiftMeter.elite), 1)
        XCTAssertEqual(RiftMeter.fraction(10 * RiftMeter.rare), 1)
    }

    func testMeterStopsAtFullAndDoesNotCountTheGuardianPhase() {
        var world = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: nil))
        world.absorb(Array(repeating: KillCredit(kind: .fodder, elite: false, rare: false), count: 150))
        XCTAssertEqual(world.meterPoints, RiftMeter.full)
        XCTAssertEqual(world.meter, 1)
        world.presentGuardianIfReady()
        world.absorb([KillCredit(kind: .fodder, elite: false, rare: false)])
        XCTAssertEqual(world.meterPoints, RiftMeter.full)
        XCTAssertEqual(world.phase, .guardian)
        XCTAssertNil(world.sim.room.actors.first { $0.kind == .guardian })
    }

    func testLanternJumps() {
        XCTAssertEqual(LanternRules.burnTicks, 7_200)
        XCTAssertEqual(LanternRules.remaining(ticks: 0), 1)
        XCTAssertEqual(LanternRules.remaining(ticks: LanternRules.burnTicks / 2), 0.5)
        XCTAssertEqual(LanternRules.remaining(ticks: LanternRules.burnTicks), 0)
        XCTAssertEqual(LanternRules.depthJump(remaining: 0.51), 3)
        XCTAssertEqual(LanternRules.depthJump(remaining: 0.5), 2)
        XCTAssertEqual(LanternRules.depthJump(remaining: 0.25), 2)
        XCTAssertEqual(LanternRules.depthJump(remaining: 0.249), 1)
        XCTAssertEqual(LanternRules.depthJump(remaining: 0), 0)
    }

    func testDelveDoesNotAdvanceOrLightTheLantern() {
        let clear = RiftOutcome.resolve(mode: .delve, died: false, lanternRemaining: 1, depth: 4)
        XCTAssertEqual(clear.depthDelta, 0)
        XCTAssertTrue(clear.keptLoot)
        XCTAssertEqual(clear.loot, [])

        var world = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: GuardianCatalog.oldLintel()))
        XCTAssertFalse(world.snapshot().lanternOn)
        XCTAssertEqual(world.snapshot().lantern, 0)
        for _ in 0..<40 { _ = world.step(commands: []) }
        XCTAssertFalse(world.snapshot().lanternOn)
        XCTAssertEqual(world.snapshot().lantern, 0)

        world.meterPoints = RiftMeter.full
        world.presentGuardianIfReady()
        killGuardian(&world)
        _ = world.step(commands: [])
        let result = world.snapshot().riftResult
        XCTAssertEqual(result?.died, false)
        XCTAssertEqual(result?.depthDelta, 0)
        XCTAssertEqual(result?.loot, [])
        XCTAssertEqual(result?.keptLoot, true)
    }

    func testDeepRiftLanternBurnsAndPauseHoldsIt() {
        var world = RiftWorld(seed: 1, setup: riftSetup(mode: .deepRift, floors: 1, guardian: nil))
        XCTAssertTrue(world.snapshot().lanternOn)
        XCTAssertEqual(world.snapshot().lantern, 1)
        _ = world.step(commands: [])
        XCTAssertEqual(world.snapshot().lantern, LanternRules.remaining(ticks: 1))
        _ = world.step(commands: [.pause])
        let held = world.snapshot().lantern
        _ = world.step(commands: [])
        XCTAssertEqual(world.snapshot().lantern, held)
    }

    func testDeathGrantsNoDepthAndKeepsLoot() {
        var world = RiftWorld(seed: 2, setup: riftSetup(mode: .deepRift, floors: 1, guardian: GuardianCatalog.oldLintel()))
        world.lanternTicks = 100
        world.sim.room.heroDown = true
        world.sim.room.actors[0].hp = 0
        _ = world.step(commands: [])
        let result = world.snapshot().riftResult
        XCTAssertEqual(result?.died, true)
        XCTAssertEqual(result?.depthDelta, 0)
        XCTAssertEqual(result?.loot, [])
        XCTAssertEqual(result?.keptLoot, true)
        XCTAssertEqual(result?.message, RiftCopy.hearth)
    }

    func testEmptyLanternKeepsLootAndGrantsNoDepth() {
        var world = RiftWorld(seed: 4, setup: riftSetup(mode: .deepRift, floors: 1, guardian: GuardianCatalog.oldLintel()))
        world.lanternTicks = LanternRules.burnTicks
        world.meterPoints = RiftMeter.full
        world.presentGuardianIfReady()
        killGuardian(&world)
        _ = world.step(commands: [])
        let result = world.snapshot().riftResult
        XCTAssertEqual(result?.died, false)
        XCTAssertEqual(result?.depthDelta, 0)
        XCTAssertEqual(result?.loot, [])
        XCTAssertEqual(result?.keptLoot, true)
        XCTAssertEqual(result?.lanternRemaining, 0)
    }

    func testGuardianHitPointsAreOneHundredTwentyTimesFodder() {
        let boss = GuardianCatalog.oldLintel()
        XCTAssertEqual(boss.hpMultiplier, 120)
        XCTAssertEqual(boss.enrageAt, 0.3)
        XCTAssertEqual(boss.mechanics.count, 2)
        XCTAssertGreaterThanOrEqual(boss.mechanics.map(\.telegraphSeconds).min() ?? 0, 0.6)

        var world = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: boss, depth: 1))
        let fodder = world.sim.room.numbers.fodderHP
        XCTAssertEqual(GuardianRules.hitPoints(fodderHP: fodder, multiplier: boss.hpMultiplier), fodder * 120)
        world.meterPoints = RiftMeter.full
        world.presentGuardianIfReady()
        let spawned = world.sim.room.actors.first { $0.kind == .guardian }
        XCTAssertEqual(spawned?.maxHP, fodder * 120)
        XCTAssertEqual(spawned?.sprite, "guardian.old_lintel")
    }

    func testEnrageThreshold() {
        XCTAssertFalse(GuardianRules.isEnraged(hp: 31, maxHP: 100, at: 0.3))
        XCTAssertTrue(GuardianRules.isEnraged(hp: 30, maxHP: 100, at: 0.3))
        XCTAssertTrue(GuardianRules.isEnraged(hp: 0, maxHP: 100, at: 0.3))

        var calm = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: GuardianCatalog.oldLintel()))
        calm.meterPoints = RiftMeter.full
        calm.presentGuardianIfReady()
        _ = calm.step(commands: [])
        XCTAssertEqual(calm.snapshot().entities.first { $0.kind == .guardian }?.enraged, false)

        var raging = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: GuardianCatalog.oldLintel()))
        raging.meterPoints = RiftMeter.full
        raging.presentGuardianIfReady()
        let index = raging.sim.room.actors.firstIndex { $0.kind == .guardian }
        XCTAssertNotNil(index)
        if let index {
            let maxHP = raging.sim.room.actors[index].maxHP
            raging.sim.room.actors[index].hp = maxHP * 0.3
        }
        _ = raging.step(commands: [])
        XCTAssertEqual(raging.snapshot().entities.first { $0.kind == .guardian }?.enraged, true)
    }

    func testGuardianTelegraphUsesTheOpcodeShape() {
        var world = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: GuardianCatalog.oldLintel()))
        world.meterPoints = RiftMeter.full
        world.presentGuardianIfReady()
        _ = world.step(commands: [])
        let mark = world.snapshot().telegraphs.first
        XCTAssertEqual(mark?.shape, "square")
        XCTAssertGreaterThanOrEqual(mark?.radius ?? 0, 1.5)
        let wind = world.sim.room.actors.first { $0.kind == .guardian }?.windupTotal ?? 0
        XCTAssertGreaterThanOrEqual(wind, RoomMath.ticks(0.6))
        XCTAssertEqual(wind, RoomMath.ticks(1))
    }

    func testStairsAdvanceTheFloorOnlyWhileTheMeterIsOpen() {
        var world = RiftWorld(seed: 8, setup: riftSetup(mode: .delve, floors: 2, guardian: GuardianCatalog.oldLintel()))
        world.sim.room.actors.removeAll { $0.team == 1 }
        _ = world.step(commands: [])
        XCTAssertNotNil(world.sim.room.stairs)
        XCTAssertEqual(world.floor, 1)
        if let stairs = world.sim.room.stairs {
            world.sim.room.actors[0].x = stairs.x
            world.sim.room.actors[0].y = stairs.y
        }
        _ = world.step(commands: [])
        XCTAssertEqual(world.floor, 2)
        XCTAssertLessThan(world.meter, 1)

        var full = RiftWorld(seed: 8, setup: riftSetup(mode: .delve, floors: 3, guardian: nil))
        full.sim.room.actors.removeAll { $0.team == 1 }
        full.meterPoints = RiftMeter.full
        _ = full.step(commands: [])
        XCTAssertEqual(full.phase, .guardian)
        XCTAssertNil(full.sim.room.stairs)
        XCTAssertEqual(full.floor, 1)
    }

    func testARealKillFillsTheMeter() {
        var world = RiftWorld(seed: 1, setup: riftSetup(mode: .delve, floors: 1, guardian: GuardianCatalog.oldLintel()))
        for _ in 0..<800 {
            _ = world.step(commands: [])
            if world.meter > 0 { break }
        }
        XCTAssertGreaterThan(world.meter, 0)
    }

    func testRiftRecordingReplays() {
        var world = RiftWorld(seed: 3, setup: riftSetup(mode: .deepRift, floors: 2, guardian: GuardianCatalog.oldLintel()))
        for _ in 0..<40 { _ = world.step(commands: []) }
        let recording = world.recording(contentVersion: "test")
        XCTAssertEqual(recording.riftMode, RiftMode.deepRift.rawValue)
        XCTAssertEqual(recording.guardianID, "old_lintel")
        XCTAssertEqual(recording.replay(setup: world.setup), recording.endHash)
    }

    private func riftSetup(mode: RiftMode, floors: Int, guardian: GuardianDefinition?, depth: Int = 1) -> RoomSetup {
        var setup = Fixture.setup(relics: [], tactics: [])
        setup.depth = depth
        setup.rift = RiftConfig(mode: mode, floors: floors, guardian: guardian)
        return setup
    }

    private func killGuardian(_ world: inout RiftWorld) {
        guard let index = world.sim.room.actors.firstIndex(where: { $0.kind == .guardian }) else { return }
        world.sim.room.actors[index].hp = 0
        world.sim.room.actors[index].death = 8
    }
}
