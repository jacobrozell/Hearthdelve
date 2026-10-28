/// A Rift is 1–3 floors of the existing room. This file keeps the meter, the Lantern,
/// stairs, and the result. Combat stays in `RoomState`.
public enum RiftMode: String, Codable, Sendable, Equatable {
    case delve
    case deepRift
}

public enum RiftPhase: Int, Sendable, Equatable {
    case floors
    case guardian
    case cleared
    case failed
}

public enum RiftFloors {
    /// A run is 1, 2, or 3 floors. The seed picks which, so a recording can rebuild it.
    public static func count(for seed: UInt64) -> Int {
        1 + Int(seed % 3)
    }
}

public struct RiftConfig: Sendable, Equatable {
    public var mode: RiftMode
    public var floors: Int
    public var guardian: GuardianDefinition?
    /// Mossy templates. Empty keeps the single cellar on every floor.
    public var templates: [RoomTemplate]
    /// Nil keeps the result's loot empty. The fight does not read this until it ends.
    public var loot: LootTable?

    public init(mode: RiftMode, floors: Int, guardian: GuardianDefinition?, templates: [RoomTemplate] = [], loot: LootTable? = nil) {
        self.mode = mode
        self.floors = min(3, max(1, floors))
        self.guardian = guardian
        self.templates = templates
        self.loot = loot
    }
}

public enum RiftCopy {
    public static let hearth = "You wake by the hearth. Everything you found came home with you."
}

/// Basis points. 10_000 is a full meter. Integers so 100 fodder land on 100% exactly.
public enum RiftMeter {
    public static let full = 10_000
    /// Fodder, 1% each.
    public static let fodder = 100
    /// Champion elites. The summary band is 4–6%; the pack table pins them at 5%, the midpoint.
    public static let elite = 500
    /// A rare. The summary band is 8–10%; the pack table pins the rare at 10%.
    public static let rare = 1_000
    /// Brute, caster, and ranged, from the pack table: 2% each.
    public static let role = 200

    public static func gain(kind: ActorKind, elite: Bool, rare: Bool) -> Int {
        if rare { return Self.rare }
        if elite { return Self.elite }
        switch kind {
        case .fodder:
            return fodder
        case .brute, .shooter:
            return role
        default:
            return 0
        }
    }

    public static func fraction(_ points: Int) -> Double {
        Double(min(full, max(0, points))) / Double(full)
    }
}

public enum DepthRules {
    /// A Deep Rift past this Depth waits on the unlock. A Delve at any reached Depth still starts.
    public static let freeDeepRiftLimit = 25

    /// Depth moves only when a clear happens at the current best. A lower Deep Rift keeps its loot and leaves the frontier.
    public static func nextBest(best: Int, foughtAt: Int, delta: Int, died: Bool) -> Int {
        let best = max(1, best)
        guard died == false, foughtAt == best, delta > 0 else { return best }
        return best + delta
    }

    public static func delveAllowed(depth: Int, best: Int) -> Bool {
        depth >= 1 && depth <= max(1, best)
    }

    public static func deepRiftAllowed(depth: Int, best: Int) -> Bool {
        delveAllowed(depth: depth, best: best) && depth <= freeDeepRiftLimit
    }
}

public enum LanternRules {
    /// Six minutes at 20 ticks a second.
    public static let burnTicks = 20 * 6 * 60

    public static func remaining(ticks: Int) -> Double {
        if ticks <= 0 { return 1 }
        if ticks >= burnTicks { return 0 }
        return 1 - Double(ticks) / Double(burnTicks)
    }

    /// More than half the Lantern left is +3. 25–50% is +2. Under 25% is +1. Empty is +0.
    public static func depthJump(remaining: Double) -> Int {
        if remaining <= 0 { return 0 }
        if remaining > 0.5 { return 3 }
        if remaining >= 0.25 { return 2 }
        return 1
    }
}

public enum GuardianRules {
    public static func hitPoints(fodderHP: Double, multiplier: Double = 120) -> Double {
        fodderHP * multiplier
    }

    /// Enrage begins at the threshold and stays on through the last point of health.
    public static func isEnraged(hp: Double, maxHP: Double, at threshold: Double) -> Bool {
        maxHP > 0 && hp <= maxHP * threshold
    }
}

public struct RiftResult: Sendable, Equatable {
    public var died: Bool
    public var keptLoot: Bool
    public var loot: [String]
    public var items: [LootItem]
    public var pity: Int
    public var depth: Int
    public var depthDelta: Int
    public var lanternRemaining: Double
    public var message: String
}

public enum RiftOutcome {
    public static func resolve(mode: RiftMode, died: Bool, lanternRemaining: Double, depth: Int) -> RiftResult {
        let remaining = mode == .deepRift ? max(0, lanternRemaining) : 0
        let delta = died || mode == .delve ? 0 : LanternRules.depthJump(remaining: remaining)
        return RiftResult(
            died: died,
            keptLoot: true,
            loot: [],
            items: [],
            pity: 0,
            depth: depth,
            depthDelta: delta,
            lanternRemaining: remaining,
            message: died ? RiftCopy.hearth : "The Guardian falls."
        )
    }
}

/// Old Lintel, the Mossy guardian with two opcodes the catalogs already accept.
/// The app prefers the catalog row when content loads. This copy is the fallback and the unit-test boss.
public enum GuardianCatalog {
    public static func oldLintel() -> GuardianDefinition {
        GuardianDefinition(
            id: "old_lintel",
            name: "Old Lintel",
            biome: "mossy_cellars",
            family: "rubble_folk",
            sprite: "guardian.old_lintel",
            hpMultiplier: 120,
            enrageAt: 0.3,
            mechanics: [
                MechanicSpec(
                    id: "ceiling_drop",
                    name: "Ceiling Drop",
                    telegraphSeconds: 1.0,
                    shape: "square",
                    opcodes: [OpcodeSpec(op: "damage", coefficient: 3.5, element: "untyped", radius: 1.5)]
                ),
                MechanicSpec(
                    id: "rubble_ring",
                    name: "Rubble Ring",
                    telegraphSeconds: 0.9,
                    shape: "ring",
                    opcodes: [OpcodeSpec(op: "root", radius: 3, duration: 1.2)]
                ),
            ]
        )
    }
}

struct KillCredit: Sendable {
    var kind: ActorKind
    var elite: Bool
    var rare: Bool
}

/// One Rift. A floor is a graph of Mossy rooms when templates are set, and the cellar otherwise.
/// The shell watches kills, opens the door, and asks the room to spawn the guardian.
public struct RiftWorld: Sendable {
    public let seed: UInt64
    public let setup: RoomSetup
    public private(set) var phase = RiftPhase.floors
    public private(set) var floor = 1
    public private(set) var result: RiftResult?
    var sim: SimWorld
    var meterPoints = 0
    var lanternTicks = 0
    var plan: FloorPlan?
    var roomIndex = 0
    var layoutRNG: Xoshiro256StarStar
    var normalKills = 0
    var eliteKills = 0
    let templates: [RoomTemplate]

    public init(seed: UInt64, setup: RoomSetup) {
        self.seed = seed
        self.setup = setup
        let templates = (setup.rift?.templates ?? []).filter { $0.width == 16 && $0.height == 16 }
        self.templates = templates
        var layout = RNGStreams(seed: seed).layout
        var starting = setup
        if templates.isEmpty == false {
            let generated = FloorLayout.generate(rng: &layout, templates: templates, lastFloor: (setup.rift?.floors ?? 1) <= 1)
            plan = generated
            roomIndex = generated.entry
            if let room = templates.first(where: { $0.id == generated.rooms[generated.entry].templateID }) {
                starting.room = room
            }
        }
        layoutRNG = layout
        sim = SimWorld(seed: seed, setup: starting)
    }

    public var mode: RiftMode { setup.rift?.mode ?? .delve }
    public var floors: Int { setup.rift?.floors ?? 1 }
    public var meter: Double { RiftMeter.fraction(meterPoints) }
    var depth: Int { setup.depth }

    public mutating func step(commands: [SimCommand]) -> SimSnapshot {
        let before = sim.tick
        let snap = sim.step(commands: commands)
        let advanced = sim.tick != before
        if result == nil, advanced, sim.paused == false {
            if mode == .deepRift { lanternTicks += 1 }
            absorb(sim.room.killCredits)
            sim.room.killCredits.removeAll(keepingCapacity: true)
            if sim.heroDown {
                finish(died: true)
            } else {
                presentGuardianIfReady()
                if guardianFell() {
                    finish(died: false)
                } else if phase == .floors, sim.room.tookStairs {
                    takePassage()
                } else if phase == .floors, shouldOpenStairs() {
                    sim.room.openStairs()
                }
            }
        }
        return decorate(sim.snapshot(events: snap.events, accepted: snap.accepted))
    }

    public func snapshot() -> SimSnapshot {
        decorate(sim.snapshot())
    }

    public func stateHash() -> UInt64 {
        var hash = FNV64()
        hash.add(sim.stateHash())
        hash.add(UInt64(meterPoints))
        hash.add(UInt64(lanternTicks))
        hash.add(UInt64(floor))
        hash.add(UInt64(roomIndex))
        hash.add(UInt64(normalKills))
        hash.add(UInt64(eliteKills))
        hash.add(UInt64(phase.rawValue))
        if plan != nil { layoutRNG.feed(&hash) }
        return hash.value
    }

    public func recording(contentVersion: String) -> RunRecording {
        var recording = sim.recording(contentVersion: contentVersion)
        recording.endHash = stateHash()
        recording.endTick = sim.tick
        recording.riftMode = setup.rift?.mode.rawValue
        recording.riftDepth = setup.depth
        recording.riftFloors = setup.rift?.floors
        recording.guardianID = setup.rift?.guardian?.id
        return recording
    }

    mutating func absorb(_ credits: [KillCredit]) {
        guard result == nil else { return }
        for credit in credits {
            if phase == .floors {
                meterPoints = min(RiftMeter.full, meterPoints + RiftMeter.gain(kind: credit.kind, elite: credit.elite, rare: credit.rare))
            }
            if credit.kind == .guardian { continue }
            if credit.elite || credit.rare { eliteKills += 1 } else { normalKills += 1 }
        }
    }

    /// Crossing 100% is a phase change. With no guardian definition the room simply stops; it does not trap.
    mutating func presentGuardianIfReady() {
        guard result == nil, phase == .floors, meterPoints >= RiftMeter.full, sim.heroDown == false else { return }
        phase = .guardian
        sim.room.summonGuardian()
    }

    private func shouldOpenStairs() -> Bool {
        guard phase == .floors, meterPoints < RiftMeter.full, sim.heroDown == false, sim.room.stairs == nil,
              sim.room.livingHostiles() == 0 else { return false }
        guard let plan else { return floor < floors }
        if roomIndex == plan.exit { return floor < floors }
        return plan.nextHop(from: roomIndex) != nil
    }

    /// A door before the exit walks to the next room. The exit door starts the next floor.
    private mutating func takePassage() {
        if let plan, roomIndex != plan.exit, let next = plan.nextHop(from: roomIndex),
           let template = template(id: plan.rooms[next].templateID) {
            roomIndex = next
            sim.room.enter(room: template)
            return
        }
        guard floor < floors else {
            sim.room.tookStairs = false
            return
        }
        floor += 1
        if templates.isEmpty == false {
            let generated = FloorLayout.generate(rng: &layoutRNG, templates: templates, lastFloor: floor == floors)
            plan = generated
            roomIndex = generated.entry
            if let template = template(id: generated.rooms[generated.entry].templateID) {
                sim.room.enter(room: template)
                return
            }
        }
        sim.room.beginNextFloor()
    }

    private func template(id: String) -> RoomTemplate? {
        templates.first { $0.id == id }
    }

    private func guardianFell() -> Bool {
        guard phase == .guardian else { return false }
        guard let boss = sim.room.actors.first(where: { $0.kind == .guardian }) else { return false }
        return boss.living == false && boss.hp <= 0
    }

    private mutating func finish(died: Bool) {
        guard result == nil else { return }
        let remaining = mode == .deepRift ? LanternRules.remaining(ticks: lanternTicks) : 0
        var resolved = RiftOutcome.resolve(mode: mode, died: died, lanternRemaining: remaining, depth: depth)
        if let table = setup.rift?.loot {
            var rng = RNGStreams(seed: seed).loot
            let rolled = LootRoller.roll(
                depth: depth, normalKills: normalKills, eliteKills: eliteKills, guardian: died == false,
                table: table, rng: &rng, p0: setup.tuning.combat.p0, h0: setup.tuning.combat.h0
            )
            resolved.items = rolled.items
            resolved.loot = rolled.items.map(\.markedLine)
            resolved.pity = rolled.pity
        }
        result = resolved
        phase = died ? .failed : .cleared
    }

    private func decorate(_ snap: SimSnapshot) -> SimSnapshot {
        var snap = snap
        let lit = mode == .deepRift
        snap.lanternOn = lit
        snap.lantern = lit ? LanternRules.remaining(ticks: lanternTicks) : 0
        snap.meter = meter
        snap.depth = depth
        snap.floor = floor
        snap.floorCount = floors
        snap.riftResult = result
        snap.stateHash = stateHash()
        return snap
    }
}

public actor RiftActor {
    private var world: RiftWorld
    private var pending: [SimCommand] = []

    public init(seed: UInt64, setup: RoomSetup) {
        world = RiftWorld(seed: seed, setup: setup)
    }

    public func enqueue(_ command: SimCommand) {
        pending.append(command)
    }

    public func snapshot() -> SimSnapshot {
        world.snapshot()
    }

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
            if last.paused || last.riftResult != nil { break }
        }
        last.events = events
        last.accepted = accepted
        return last
    }

    public func recording(contentVersion: String) -> RunRecording {
        world.recording(contentVersion: contentVersion)
    }
}
