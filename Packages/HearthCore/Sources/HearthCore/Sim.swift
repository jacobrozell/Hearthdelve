public enum SimVersion {
    /// Bump when a change to the tick would make an old recording replay differently.
    public static let current = 1
}

public enum AnimID: String, Codable, Sendable, Equatable {
    case idle
    case walk
    case windup
    case attack
    case hit
    case death
}

public struct EntityPose: Sendable, Equatable {
    public var id: UInt32
    public var kind: ActorKind
    public var x: Double
    public var y: Double
    public var facing: Int8
    public var anim: AnimID
    public var phase: Double
    public var hp: Double
    public var maxHP: Double
    public var sprite: String
    public var elite: Bool
    public var rooted: Bool
    public var stunned: Bool
    public var hostile: Bool
    public var dx: Double
    public var dy: Double
}

/// A ground warning: fills from the center as `progress` goes from 0 to 1, then the attack lands.
public struct TelegraphSnapshot: Sendable, Equatable {
    public var id: UInt32
    public var x: Double
    public var y: Double
    public var radius: Double
    public var progress: Double
    public var slam: Bool
}

public struct GroundSnapshot: Sendable, Equatable {
    public var id: UInt32
    public var x: Double
    public var y: Double
    public var radius: Double
    public var element: String
    public var life: Double
}

public struct RelicSlotSnapshot: Sendable, Equatable {
    public var id: String
    public var name: String
    public var souls: Double
    public var cooldown: Double
    public var ready: Bool
}

/// Things that happened during a tick. The renderer turns these into numbers, flashes, and bursts.
public enum SimEvent: Sendable, Equatable {
    case hit(id: UInt32, x: Double, y: Double, amount: Double, crit: Bool, onHero: Bool)
    case death(id: UInt32, x: Double, y: Double, elite: Bool)
    case burst(x: Double, y: Double, radius: Double, element: String)
    case cleave(x: Double, y: Double, radius: Double)
    case shield(amount: Double)
    case heal(amount: Double)
    case relic(slot: Int, rule: Int?)
    case potion(rule: Int?)
    case wave(number: Int, champions: Bool)
    case heroDown
    case invariant(code: String)
}

public enum SimSpeed: Int, Codable, Sendable, Equatable {
    case x1 = 1
    case x2 = 2
    case x4 = 4
}

public enum SimCommand: Codable, Sendable, Equatable {
    case fireRelic(slot: Int)
    case drinkPotion
    case setSpeed(SimSpeed)
    case pause
    case resume

    /// Only these change the fight. Pause and speed only change how fast wall time feeds ticks.
    public var affectsSim: Bool {
        switch self {
        case .fireRelic, .drinkPotion: true
        case .setSpeed, .pause, .resume: false
        }
    }
}

public struct SimSnapshot: Sendable, Equatable {
    public var tick: UInt64
    public var seed: UInt64
    public var paused: Bool
    public var speed: SimSpeed
    public var entities: [EntityPose]
    public var telegraphs: [TelegraphSnapshot]
    public var grounds: [GroundSnapshot]
    public var events: [SimEvent]
    public var heroHP: Double
    public var heroMaxHP: Double
    public var shield: Double
    public var souls: Double
    public var soulCap: Double
    public var lantern: Double
    public var relics: [RelicSlotSnapshot]
    public var potionCharges: Int
    public var potionMax: Int
    public var potionCooldown: Double
    public var wave: Int
    public var kills: Int
    public var heroDown: Bool
    public var tacticFires: [Int]
    public var accepted: [SimCommand]
    public var stateHash: UInt64
}

public struct RecordedInput: Codable, Sendable, Equatable {
    public var tick: UInt64
    public var command: SimCommand

    public init(tick: UInt64, command: SimCommand) {
        self.tick = tick
        self.command = command
    }
}

/// Enough to replay a run in HearthSimCLI: seed, versions, and every input with the tick it applied on.
public struct RunRecording: Codable, Sendable, Equatable {
    public var simVersion: Int
    public var contentVersion: String
    public var seed: UInt64
    public var endTick: UInt64
    public var endHash: UInt64
    public var inputs: [RecordedInput]

    public init(simVersion: Int = SimVersion.current, contentVersion: String, seed: UInt64, endTick: UInt64, endHash: UInt64, inputs: [RecordedInput]) {
        self.simVersion = simVersion
        self.contentVersion = contentVersion
        self.seed = seed
        self.endTick = endTick
        self.endHash = endHash
        self.inputs = inputs
    }

    /// Re-runs the recording headlessly and returns the end-state hash.
    public func replay(setup: RoomSetup) -> UInt64 {
        var world = SimWorld(seed: seed, setup: setup)
        var cursor = 0
        while world.tick < endTick {
            let next = world.tick + 1
            var commands: [SimCommand] = []
            while cursor < inputs.count, inputs[cursor].tick == next {
                commands.append(inputs[cursor].command)
                cursor += 1
            }
            _ = world.step(commands: commands)
        }
        return world.stateHash()
    }
}

public struct SimWorld: Sendable {
    public let seed: UInt64
    public private(set) var paused = false
    public private(set) var speed = SimSpeed.x1
    public private(set) var inputs: [RecordedInput] = []
    var room: RoomState

    public init(seed: UInt64, setup: RoomSetup) {
        self.seed = seed
        room = RoomState(seed: seed, setup: setup)
    }

    public var tick: UInt64 { UInt64(room.tick) }
    public var stats: RoomStats { room.stats }
    public var heroDown: Bool { room.heroDown }
    public var setup: RoomSetup { room.setup }
    var streams: RNGStreams { room.streams }

    /// Applies commands, then advances one tick unless paused. Fight commands sent while paused are dropped.
    public mutating func step(commands: [SimCommand]) -> SimSnapshot {
        var accepted: [SimCommand] = []
        var fight: [SimCommand] = []
        for command in commands {
            switch command {
            case .pause:
                paused = true
                accepted.append(command)
            case .resume:
                paused = false
                accepted.append(command)
            case .setSpeed(let next):
                speed = next
                accepted.append(command)
            case .fireRelic, .drinkPotion:
                if paused == false { fight.append(command) }
            }
        }
        guard paused == false else { return snapshot(events: [], accepted: accepted) }
        room.events.removeAll(keepingCapacity: true)
        room.advance(fight)
        for command in fight {
            inputs.append(RecordedInput(tick: tick, command: command))
            accepted.append(command)
        }
        return snapshot(events: room.events, accepted: accepted)
    }

    public func snapshot(events: [SimEvent] = [], accepted: [SimCommand] = []) -> SimSnapshot {
        let hero = room.actors[0]
        return SimSnapshot(
            tick: tick,
            seed: seed,
            paused: paused,
            speed: speed,
            entities: room.entities(),
            telegraphs: room.telegraphs(),
            grounds: room.grounds(),
            events: events,
            heroHP: max(0, hero.hp),
            heroMaxHP: hero.maxHP,
            shield: room.shield,
            souls: room.souls,
            soulCap: SoulRules.cap,
            lantern: 1,
            relics: room.setup.relics.enumerated().map { slot, relic in
                RelicSlotSnapshot(
                    id: relic.id,
                    name: relic.name,
                    souls: relic.souls,
                    cooldown: Double(room.relicWait[slot]) / Double(room.numbers.relicPeriods[slot]),
                    ready: room.relicReady(slot)
                )
            },
            potionCharges: room.potionCharges,
            potionMax: room.setup.tuning.room.potionCharges,
            potionCooldown: room.potionWait == 0 ? 0 : Double(room.potionWait) / Double(max(1, room.numbers.potionPeriod)),
            wave: room.wave,
            kills: room.kills,
            heroDown: room.heroDown,
            tacticFires: room.stats.tacticFires,
            accepted: accepted,
            stateHash: stateHash()
        )
    }

    /// Hash of everything that decides the fight. Pause and speed are left out so a replay matches a live run.
    public func stateHash() -> UInt64 {
        var hash = FNV64()
        hash.add(seed)
        room.feed(&hash)
        return hash.value
    }

    public func recording(contentVersion: String) -> RunRecording {
        RunRecording(contentVersion: contentVersion, seed: seed, endTick: tick, endHash: stateHash(), inputs: inputs)
    }
}

public actor SimActor {
    private var world: SimWorld
    private var pending: [SimCommand] = []

    public init(seed: UInt64, setup: RoomSetup) {
        world = SimWorld(seed: seed, setup: setup)
    }

    public func enqueue(_ command: SimCommand) {
        pending.append(command)
    }

    public func snapshot() -> SimSnapshot {
        world.snapshot()
    }

    /// Runs up to `ticks` ticks (more than one at 2× and 4×). Events from every tick are merged.
    public func advance(ticks: Int) -> SimSnapshot {
        var commands = pending
        pending.removeAll(keepingCapacity: true)
        var events: [SimEvent] = []
        var accepted: [SimCommand] = []
        var last = world.snapshot()
        for _ in 0..<max(1, ticks) {
            last = world.step(commands: commands)
            commands = []
            events.append(contentsOf: last.events)
            accepted.append(contentsOf: last.accepted)
            if world.paused { break }
        }
        last.events = events
        last.accepted = accepted
        return last
    }

    public func recording(contentVersion: String) -> RunRecording {
        world.recording(contentVersion: contentVersion)
    }
}

public struct RoomRunResult: Sendable, Equatable {
    public var hash: UInt64
    public var ticks: UInt64
    public var kills: Int
    public var stats: RoomStats
}

public enum RoomRun {
    /// Headless run for tests and the CLI. Stops early if the hero goes down.
    public static func run(seed: UInt64, setup: RoomSetup, ticks: Int, inputs: [RecordedInput] = []) -> RoomRunResult {
        var world = SimWorld(seed: seed, setup: setup)
        var cursor = 0
        for _ in 0..<ticks {
            let next = world.tick + 1
            var commands: [SimCommand] = []
            while cursor < inputs.count, inputs[cursor].tick <= next {
                commands.append(inputs[cursor].command)
                cursor += 1
            }
            _ = world.step(commands: commands)
            if world.heroDown, world.room.actors[0].death == 0 { break }
        }
        return RoomRunResult(hash: world.stateHash(), ticks: world.tick, kills: world.room.kills, stats: world.stats)
    }
}
