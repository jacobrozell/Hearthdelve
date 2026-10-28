import XCTest
@testable import HearthCore

final class RoomTests: XCTestCase {
    func testFodderDiesInTwoSwordHits() {
        var curves = BalanceCurves(through: 11)
        let power = curves.weaponPower(p0: 10, itemLevel: 11)
        let hp = curves.enemyHitPoints(hp0: 15, depth: 1)
        let hit = CombatMath.outgoing(power: power, coefficient: 1, additive: [], multipliers: [], critDamage: 0.5, isCrit: false)
        XCTAssertLessThan(hit, hp)
        XCTAssertGreaterThanOrEqual(hit * 2, hp)
    }

    func testSpawnsStandOnOpenTiles() {
        let room = RoomState(seed: 9, setup: Fixture.setup())
        for actor in room.actors {
            XCTAssertFalse(room.blockedBox(actor.x, actor.y), "\(actor.sprite) in a wall")
        }
    }

    func testGoldenSeeds() {
        let golden: [UInt64: UInt64] = [
            1: 13_948_987_823_554_681_147,
            2: 2_373_592_596_909_882_594,
            3: 9_444_094_118_426_202_281,
            42: 2_704_896_790_383_049_619,
            2026: 7_564_628_698_584_743_757,
        ]
        for seed in golden.keys.sorted() {
            let hash = RoomRun.run(seed: seed, setup: Fixture.setup(), ticks: 1200).hash
            XCTAssertEqual(hash, golden[seed], "seed \(seed)")
        }
    }

    func testRoomIsDeterministicAndClearsWaves() {
        let left = RoomRun.run(seed: 1, setup: Fixture.setup(), ticks: 2400)
        let right = RoomRun.run(seed: 1, setup: Fixture.setup(), ticks: 2400)
        XCTAssertEqual(left, right)
        XCTAssertNotEqual(left.hash, RoomRun.run(seed: 2, setup: Fixture.setup(), ticks: 2400).hash)
        XCTAssertGreaterThan(left.stats.waves, 1)
        XCTAssertNotNil(left.stats.firstWaveTick)
        XCTAssertEqual(left.stats.invariants, 0)
    }

    func testFodderDiesInAHitOrTwo() {
        let result = RoomRun.run(seed: 3, setup: Fixture.setup(relics: [], tactics: []), ticks: 2400)
        XCTAssertGreaterThan(result.stats.fodder.kills, 5)
        XCTAssertLessThanOrEqual(result.stats.fodder.meanHits, 2.1)
    }

    func testReplayMatchesALiveRunWithTaps() {
        var world = SimWorld(seed: 5, setup: Fixture.setup())
        for tick in 1...900 {
            var commands: [SimCommand] = []
            if tick == 40 { commands = [.fireRelic(slot: 0)] }
            if tick == 41 { commands = [.pause] }
            if tick == 42 { commands = [.fireRelic(slot: 1), .resume, .setSpeed(.x4)] }
            if tick == 300 { commands = [.drinkPotion, .fireRelic(slot: 1)] }
            _ = world.step(commands: commands)
        }
        let recording = world.recording(contentVersion: "test")
        XCTAssertFalse(recording.inputs.isEmpty)
        XCTAssertEqual(recording.replay(setup: Fixture.setup()), recording.endHash)
        let decoded = try? JSONDecoder().decode(RunRecording.self, from: JSONEncoder().encode(recording))
        XCTAssertEqual(decoded, recording)
    }

    func testPausedStepsDoNotAdvanceOrRecordTaps() {
        var world = SimWorld(seed: 1, setup: Fixture.setup())
        _ = world.step(commands: [])
        let frozen = world.stateHash()
        let paused = world.step(commands: [.pause, .fireRelic(slot: 0)])
        XCTAssertEqual(paused.tick, 1)
        XCTAssertEqual(world.stateHash(), frozen)
        XCTAssertTrue(world.inputs.isEmpty)
        XCTAssertEqual(paused.accepted, [.pause])
        let resumed = world.step(commands: [.resume])
        XCTAssertEqual(resumed.tick, 2)
    }

    func testBruteTelegraphPrecedesTheSlam() {
        var world = SimWorld(seed: 1, setup: Fixture.setup(relics: [], tactics: []))
        var longest = 0.0
        var landed = false
        var dodged = false
        for _ in 0..<3600 {
            let snapshot = world.step(commands: [])
            for mark in snapshot.telegraphs where mark.slam {
                longest = max(longest, mark.progress)
            }
            landed = landed || world.stats.slamsLanded > 0
            dodged = dodged || world.stats.slamsDodged > 0
            if world.heroDown { break }
        }
        XCTAssertGreaterThan(longest, 0.9)
        XCTAssertGreaterThanOrEqual(RoomNumbers(setup: Fixture.setup()).slamTicks, 12)
        XCTAssertTrue(landed || dodged)
    }

    func testRelicTapFiresOnTheNextTickAndCostsSouls() {
        var world = SimWorld(seed: 1, setup: Fixture.setup(tactics: []))
        let before = world.snapshot().souls
        let snapshot = world.step(commands: [.fireRelic(slot: 1)])
        XCTAssertEqual(snapshot.souls, before - 40 + 0, accuracy: 0.0001)
        XCTAssertGreaterThan(snapshot.shield, 0)
        XCTAssertTrue(snapshot.events.contains(.relic(slot: 1, rule: nil)))
        XCTAssertFalse(snapshot.relics[1].ready)
    }

    func testTacticsFireTopToBottom() {
        let result = RoomRun.run(seed: 7, setup: Fixture.setup(), ticks: 2400)
        XCTAssertGreaterThan(result.stats.tacticFires[2], 0, "Ember Flask rule never fired")
        XCTAssertGreaterThan(result.stats.relicCasts, 0)
    }

    func testOnKillSignatureRunsOpcodes() {
        let nova = SignatureSpec(hook: "onKill", opcodes: [OpcodeSpec(op: "damage", coefficient: 1, element: "fire", radius: 2)])
        let plain = RoomRun.run(seed: 4, setup: Fixture.setup(relics: [], tactics: []), ticks: 1200)
        let hooked = RoomRun.run(seed: 4, setup: Fixture.setup(relics: [], tactics: [], signatures: [nova]), ticks: 1200)
        XCTAssertGreaterThan(hooked.stats.damageDealt, plain.stats.damageDealt)
    }

    func testOnStunSignatureFromHammerInnate() {
        let hammer = WeaponDefinition(id: "hammer", name: "Hammer", kind: .melee, rangeTiles: 1, attacksPerSecond: 0.7, innate: InnateSpec(kind: "stunEvery", hits: 4, seconds: 1))
        let cinderfang = SignatureSpec(hook: "onStun", opcodes: Fixture.flask.opcodes)
        var world = SimWorld(seed: 2, setup: Fixture.setup(relics: [], tactics: [], signatures: [cinderfang], melee: hammer))
        var bursts = 0
        for _ in 0..<2400 {
            let snapshot = world.step(commands: [])
            bursts += snapshot.events.filter { if case .burst(_, _, 3, "fire") = $0 { true } else { false } }.count
            if world.heroDown { break }
        }
        XCTAssertGreaterThan(bursts, 0)
    }

    func testEveryOpcodeRunsWithoutInvariants() {
        let relics = [
            RelicDefinition(id: "a", name: "a", souls: 0, cooldown: 1, tags: ["untyped"], opcodes: [OpcodeSpec(op: "root", radius: 3, duration: 1)]),
            RelicDefinition(id: "b", name: "b", souls: 0, cooldown: 1, tags: ["untyped"], opcodes: [OpcodeSpec(op: "stun", radius: 2, duration: 1)]),
            RelicDefinition(id: "c", name: "c", souls: 0, cooldown: 2, tags: ["untyped"], opcodes: [OpcodeSpec(op: "dash", tiles: 4, nextCrit: true)]),
            RelicDefinition(id: "d", name: "d", souls: 0, cooldown: 5, tags: ["untyped"], opcodes: [OpcodeSpec(op: "summon", coefficient: 0.9, duration: 4, kind: "hound", taunts: true)]),
            RelicDefinition(id: "e", name: "e", souls: 0, cooldown: 3, tags: ["untyped"], opcodes: [OpcodeSpec(op: "taunt", radius: 3, duration: 2), OpcodeSpec(op: "heal", radius: 3, duration: 2, fraction: 0.04)]),
        ]
        var world = SimWorld(seed: 8, setup: Fixture.setup(relics: relics, tactics: []))
        var sawAlly = false
        for tick in 1...1200 {
            let slot = tick % relics.count
            let snapshot = world.step(commands: [.fireRelic(slot: slot)])
            sawAlly = sawAlly || snapshot.entities.contains { $0.kind == .ally }
        }
        XCTAssertTrue(sawAlly)
        XCTAssertEqual(world.stats.invariants, 0)
    }

    func testLootAndLayoutStreamsStayPutDuringCombat() {
        var world = SimWorld(seed: 1, setup: Fixture.setup())
        let loot = world.streams.loot
        let layout = world.streams.layout
        for _ in 0..<600 {
            _ = world.step(commands: [])
        }
        XCTAssertEqual(world.streams.loot, loot)
        XCTAssertEqual(world.streams.layout, layout)
    }

    func testActorMergesTicksAtSpeed() async {
        let actor = SimActor(seed: 1, setup: Fixture.setup())
        await actor.enqueue(.setSpeed(.x4))
        let snapshot = await actor.advance(ticks: 4)
        XCTAssertEqual(snapshot.tick, 4)
        XCTAssertEqual(snapshot.speed, .x4)
        var world = SimWorld(seed: 1, setup: Fixture.setup())
        for _ in 0..<4 { _ = world.step(commands: []) }
        XCTAssertEqual(snapshot.stateHash, world.stateHash())
    }
}
