/// Everything the one-room fight needs. HearthContent builds it from the catalogs; tests build it by hand.
public struct RoomSetup: Sendable, Equatable {
    public var room: RoomTemplate
    public var tuning: Tuning
    public var depth: Int
    public var melee: WeaponDefinition
    public var ranged: WeaponDefinition
    public var relics: [RelicDefinition]
    public var tactics: [TacticRule]
    /// Hooks with `opcodes` already filled in (HearthContent resolves `enqueues`).
    public var signatures: [SignatureSpec]
    public var fodder: MobDefinition
    public var brute: MobDefinition
    public var shooter: MobDefinition

    public init(
        room: RoomTemplate, tuning: Tuning, depth: Int, melee: WeaponDefinition, ranged: WeaponDefinition,
        relics: [RelicDefinition], tactics: [TacticRule], signatures: [SignatureSpec] = [],
        fodder: MobDefinition, brute: MobDefinition, shooter: MobDefinition
    ) {
        self.room = room
        self.tuning = tuning
        self.depth = depth
        self.melee = melee
        self.ranged = ranged
        self.relics = relics
        self.tactics = tactics
        self.signatures = signatures
        self.fodder = fodder
        self.brute = brute
        self.shooter = shooter
    }
}

public enum ActorKind: UInt8, Sendable, Equatable {
    case hero
    case ally
    case fodder
    case brute
    case shooter
    case projectile
    case zone

    var creature: Bool { self != .projectile && self != .zone }
}

public struct RoleStats: Sendable, Equatable {
    public var kills = 0
    public var lifeTicks = 0
    public var hits = 0

    public var meanSeconds: Double { kills == 0 ? 0 : Double(lifeTicks) / Double(kills) / Double(RoomMath.ticksPerSecond) }
    public var meanHits: Double { kills == 0 ? 0 : Double(hits) / Double(kills) }
}

public struct RoomStats: Sendable, Equatable {
    public var fodder = RoleStats()
    public var brute = RoleStats()
    public var shooter = RoleStats()
    public var waves = 0
    public var firstWaveTick: Int?
    public var heroDownTick: Int?
    public var damageTaken = 0.0
    public var damageDealt = 0.0
    public var relicCasts = 0
    public var potions = 0
    public var dodges = 0
    public var slamsLanded = 0
    public var slamsDodged = 0
    public var tacticFires: [Int] = []
    public var invariants = 0
}

enum RoomMath {
    static let ticksPerSecond = 20
    static let dt = 1.0 / Double(ticksPerSecond)
    static let bodyRadius = 0.3
    static let deathTicks = 16
    static let heroDeathTicks = 40
    static let shooterWindupTicks = 12
    static let zonePulseTicks = 10
    static let allyBiteTicks = 20
    static let allyTauntRange = 3.0

    static func ticks(_ seconds: Double) -> Int {
        Int((seconds * Double(ticksPerSecond)).rounded())
    }
}

struct Actor: Sendable {
    var id: UInt32
    var kind: ActorKind
    var team: UInt8
    var x: Double
    var y: Double
    var facing: Int8 = 1
    var hp: Double
    var maxHP: Double
    var elite = false
    var sprite: String
    var wait = 0
    var windup = 0
    var windupTotal = 0
    var aimX = 0.0
    var aimY = 0.0
    var hurt = 0
    var death = 0
    var deathTotal = RoomMath.deathTicks
    var root = 0
    var stun = 0
    var taunt = 0
    var dx = 0.0
    var dy = 0.0
    var speed = 0.0
    var power = 0.0
    var life = 0
    var radius = 0.0
    var element = "physical"
    var crit = false
    var pierce = 0
    var bounce = 0
    var homing: UInt32 = 0
    var lastHit: UInt32 = 0
    var taunts = false
    var flash = 0
    var moved = false
    var born = 0
    var hits = 0
    var anim: AnimID = .idle
    var phase = 0.0

    var living: Bool { hp > 0 && death == 0 && kind.creature }
}

enum DamageSource {
    case weapon
    case relic
    case signature
    case zone
    case ally
}

struct RoomNumbers: Sendable {
    var power: Double
    var heroHP: Double
    var fodderHP: Double
    var enemyDamage: Double
    var meleePeriod: Int
    var rangedPeriod: Int
    var meleeReach: Double
    var rangedReach: Double
    var swap: Double
    var fodderPeriod: Int
    var bruteRecovery: Int
    var shooterPeriod: Int
    var slamTicks: Int
    var reaction: Int
    var potionPeriod: Int
    var waveDelay: Int
    var relicPeriods: [Int]

    init(setup: RoomSetup) {
        let tuning = setup.tuning
        var curves = BalanceCurves(through: max(setup.depth + 10, 1))
        power = curves.weaponPower(p0: tuning.combat.p0, itemLevel: setup.depth + 10)
        heroHP = curves.heroHitPoints(h0: tuning.combat.h0, itemLevel: setup.depth + 10)
        fodderHP = curves.enemyHitPoints(hp0: tuning.combat.hp0, depth: setup.depth)
        enemyDamage = curves.enemyDamageAmount(dmg0: tuning.combat.dmg0, depth: setup.depth)
        meleePeriod = max(1, RoomMath.ticks(1 / setup.melee.attacksPerSecond))
        rangedPeriod = max(1, RoomMath.ticks(1 / setup.ranged.attacksPerSecond))
        meleeReach = setup.melee.rangeTiles + 0.35
        rangedReach = setup.ranged.rangeTiles
        swap = tuning.room.swapTiles
        fodderPeriod = RoomMath.ticks(tuning.room.fodderAttackSeconds)
        bruteRecovery = RoomMath.ticks(tuning.room.bruteRecoverySeconds)
        shooterPeriod = RoomMath.ticks(tuning.room.rangedAttackSeconds)
        slamTicks = max(RoomMath.ticks(0.6), RoomMath.ticks(setup.brute.telegraphSeconds ?? 0.6))
        reaction = RoomMath.ticks(tuning.room.heroReactionSeconds)
        potionPeriod = RoomMath.ticks(tuning.room.potionCooldown)
        waveDelay = max(1, RoomMath.ticks(tuning.room.waveDelaySeconds))
        relicPeriods = setup.relics.map { max(1, RoomMath.ticks($0.cooldown)) }
    }
}

struct RoomState: Sendable {
    let setup: RoomSetup
    let numbers: RoomNumbers
    let width: Int
    let height: Int
    let blocked: [Bool]
    var streams: RNGStreams
    var tick = 0
    var actors: [Actor] = []
    var nextID: UInt32 = 1
    var souls: Double
    var shield = 0.0
    var shieldTicks = 0
    var relicWait: [Int]
    var potionCharges: Int
    var potionWait = 0
    var swings = 0
    var shots = 0
    var nextCrit = false
    var healTicks = 0
    var healPerTick = 0.0
    var path: [(Int, Int)] = []
    var pathAge = 0
    var pathTarget: UInt32 = 0
    var wave = 0
    var waveTimer = 0
    var waveCleared = false
    var kills = 0
    var killHash = FNV64()
    var heroDown = false
    var hookCounters: [Int]
    var hookDepth = 0
    var flow: (sx: [Int8], sy: [Int8]) = ([], [])
    var grid: SpatialGrid
    var stats = RoomStats()
    var events: [SimEvent] = []

    init(seed: UInt64, setup: RoomSetup) {
        self.setup = setup
        numbers = RoomNumbers(setup: setup)
        width = setup.room.width
        height = setup.room.height
        blocked = setup.room.blockedGrid()
        streams = RNGStreams(seed: seed)
        souls = setup.tuning.room.startingSouls
        relicWait = Array(repeating: 0, count: setup.relics.count)
        potionCharges = setup.tuning.room.potionCharges
        hookCounters = Array(repeating: 0, count: setup.signatures.count)
        grid = SpatialGrid(width: setup.room.width, height: setup.room.height)
        stats.tacticFires = Array(repeating: 0, count: setup.tactics.count)
        spawnHero()
        spawnWave()
        events.removeAll()
    }

    // MARK: Tick

    mutating func advance(_ commands: [SimCommand]) {
        tick += 1
        for index in actors.indices { actors[index].moved = false }
        if heroDown == false {
            apply(commands)
        }
        tickTimers()
        if heroDown == false {
            let hero = actors[0]
            flow = RoomPath.flow(width: width, height: height, blocked: blocked, originX: Int(hero.x), originY: Int(hero.y))
            heroThink()
            mobsThink()
            alliesThink()
        }
        reap()
        separate()
        checkInvariants()
        paint()
    }

    private mutating func apply(_ commands: [SimCommand]) {
        for command in commands {
            switch command {
            case .fireRelic(let slot):
                if relicReady(slot) { castRelic(slot, rule: nil) }
            case .drinkPotion:
                drink(rule: nil)
            case .setSpeed, .pause, .resume:
                break
            }
        }
    }

    private mutating func tickTimers() {
        for slot in relicWait.indices where relicWait[slot] > 0 { relicWait[slot] -= 1 }
        if potionWait > 0 { potionWait -= 1 }
        if shieldTicks > 0 {
            shieldTicks -= 1
            if shieldTicks == 0 { shield = 0 }
        }
        if healTicks > 0, actors[0].living {
            healTicks -= 1
            actors[0].hp = min(actors[0].maxHP, actors[0].hp + healPerTick)
        }
        if tick % RoomMath.ticksPerSecond == 0 {
            souls = min(SoulRules.cap, souls + setup.tuning.soulRegenPerSecond)
        }
        if waveTimer > 0, heroDown == false {
            waveTimer -= 1
            if waveTimer == 0 { spawnWave() }
        }
        for index in actors.indices {
            if actors[index].wait > 0 { actors[index].wait -= 1 }
            if actors[index].hurt > 0 { actors[index].hurt -= 1 }
            if actors[index].flash > 0 { actors[index].flash -= 1 }
            if actors[index].root > 0 { actors[index].root -= 1 }
            if actors[index].taunt > 0 { actors[index].taunt -= 1 }
            if actors[index].stun > 0 {
                actors[index].stun -= 1
                actors[index].windup = 0
            }
            if actors[index].death > 0 { actors[index].death -= 1 }
            switch actors[index].kind {
            case .projectile where actors[index].hp > 0:
                stepProjectile(index)
            case .zone where actors[index].hp > 0:
                stepZone(index)
            case .ally where actors[index].living:
                actors[index].life -= 1
                if actors[index].life <= 0 { kill(index) }
            default:
                break
            }
            if actors[index].windup > 0, actors[index].living, heroDown == false {
                actors[index].windup -= 1
                if actors[index].windup == 0 { resolveWindup(index) }
            }
        }
    }

    // MARK: Hero

    private mutating func heroThink() {
        let hero = actors[0]
        guard hero.living else { return }
        let target = nearestEnemy(x: hero.x, y: hero.y)
        let context = tacticContext(target: target)
        var acted = false
        if let rule = Tactics.firstMatch(setup.tactics, context, ready: { actionReady($0, target: target) }) {
            let action = setup.tactics[rule].action
            stats.tacticFires[rule] += 1
            switch action.kind {
            case "potion":
                drink(rule: rule)
                acted = true
            case "relic":
                if let slot = setup.relics.firstIndex(where: { $0.id == action.relic }) {
                    castRelic(slot, rule: rule)
                    acted = true
                }
            default:
                break
            }
        }

        if let threat = slamThreat() {
            stats.dodges += 1
            var dx = actors[0].x - threat.0
            var dy = actors[0].y - threat.1
            let length = (dx * dx + dy * dy).squareRoot()
            if length < 0.01 {
                dx = 0
                dy = -1
            } else {
                dx /= length
                dy /= length
            }
            move(0, dx, dy, speed: setup.tuning.room.heroTilesPerSecond)
            return
        }

        guard let target else { return }
        let enemy = actors[target]
        let distance = dist2(hero.x, hero.y, enemy.x, enemy.y)
        let melee = numbers.meleeReach * numbers.meleeReach
        let swap = numbers.swap * numbers.swap
        let reach = numbers.rangedReach * numbers.rangedReach
        let sight = distance > swap && distance <= reach && lineOfSight(hero.x, hero.y, enemy.x, enemy.y)
        face(0, toward: enemy.x)
        if distance > melee && sight == false {
            approach(target)
        }
        guard acted == false, actors[0].wait == 0 else { return }
        if distance <= melee {
            swing(at: target)
        } else if sight {
            shoot(at: target)
        }
    }

    private func tacticContext(target: Int?) -> TacticContext {
        let hero = actors[0]
        var enemies: [Double] = []
        var elites: [Double] = []
        for actor in actors where actor.living && actor.team == 1 {
            let distance = dist2(hero.x, hero.y, actor.x, actor.y)
            enemies.append(distance)
            if actor.elite { elites.append(distance) }
        }
        let targetDistance = target.map { dist2(hero.x, hero.y, actors[$0].x, actors[$0].y) }
        return TacticContext(
            hpFraction: hero.maxHP == 0 ? 1 : hero.hp / hero.maxHP,
            souls: souls,
            shield: shield,
            enemyDistances: enemies,
            eliteDistances: elites,
            targetDistance: targetDistance,
            targetElite: target.map { actors[$0].elite } ?? false
        )
    }

    private func actionReady(_ action: TacticAction, target: Int?) -> Bool {
        switch action.kind {
        case "potion":
            return potionCharges > 0 && potionWait == 0 && actors[0].hp < actors[0].maxHP
        case "relic":
            guard let slot = setup.relics.firstIndex(where: { $0.id == action.relic }) else { return false }
            return relicReady(slot)
        case "melee", "ranged":
            return target != nil
        default:
            return false
        }
    }

    func relicReady(_ slot: Int) -> Bool {
        guard setup.relics.indices.contains(slot) else { return false }
        return relicWait[slot] == 0 && souls >= setup.relics[slot].souls
    }

    /// The center of a brute slam the hero is standing in, once the hero has had time to react.
    private func slamThreat() -> (Double, Double)? {
        let hero = actors[0]
        let reach = setup.tuning.room.slamRadius + 0.35
        for actor in actors where actor.living && actor.kind == .brute && actor.windup > 0 {
            guard actor.windupTotal - actor.windup >= numbers.reaction else { continue }
            if dist2(hero.x, hero.y, actor.aimX, actor.aimY) <= reach * reach {
                return (actor.aimX, actor.aimY)
            }
        }
        return nil
    }

    private mutating func approach(_ target: Int) {
        let hero = actors[0]
        let goal = actors[target]
        if goal.id != pathTarget || pathAge >= 10 {
            pathTarget = goal.id
            pathAge = 0
            path = RoomPath.astar(width: width, height: height, blocked: blocked, from: (Int(hero.x), Int(hero.y)), to: (Int(goal.x), Int(goal.y)))
        } else {
            pathAge += 1
        }
        while let next = path.first, dist2(hero.x, hero.y, Double(next.0) + 0.5, Double(next.1) + 0.5) < 0.04 {
            path.removeFirst()
        }
        let aim: (Double, Double)
        if path.count <= 1 {
            aim = (goal.x, goal.y)
        } else {
            aim = (Double(path[0].0) + 0.5, Double(path[0].1) + 0.5)
        }
        steer(0, toward: aim.0, aim.1, speed: setup.tuning.room.heroTilesPerSecond)
    }

    private mutating func swing(at target: Int) {
        swings += 1
        actors[0].wait = numbers.meleePeriod
        actors[0].flash = 6
        let innate = setup.melee.innate
        let crit = rollCrit(extra: innate.kind == "critChance" ? innate.chance ?? 0 : 0)
        let amount = hitAmount(coefficient: 1, crit: crit)
        let tx = actors[target].x
        let ty = actors[target].y
        damageEnemy(target, amount, crit: crit, source: .weapon)
        let every = innate.hits ?? 0
        switch innate.kind {
        case "cleaveEvery" where every > 0 && swings % every == 0:
            events.append(.cleave(x: tx, y: ty, radius: 1.5))
            for index in enemies(near: tx, ty, radius: 1.5) where actors[index].id != actors[target].id {
                damageEnemy(index, amount, crit: crit, source: .weapon)
            }
        case "stunEvery" where every > 0 && swings % every == 0:
            if actors[target].living {
                actors[target].stun = RoomMath.ticks(innate.seconds ?? 1)
                fire("onStun", x: tx, y: ty, target: target)
            }
        case "arcHeal":
            heal(amount * (innate.fraction ?? 0))
        case "pierce":
            let extra = enemies(near: tx, ty, radius: 1.2).filter { actors[$0].id != actors[target].id }.prefix(innate.enemies ?? 1)
            for index in extra { damageEnemy(index, amount, crit: crit, source: .weapon) }
        default:
            break
        }
    }

    private mutating func shoot(at target: Int) {
        shots += 1
        actors[0].wait = numbers.rangedPeriod
        actors[0].flash = 6
        let innate = setup.ranged.innate
        let crit = rollCrit(extra: 0)
        var amount = hitAmount(coefficient: 1, crit: crit)
        if innate.kind == "chargedEvery", let every = innate.shots, every > 0, shots % every == 0 {
            amount *= 1 + (innate.bonus ?? 0)
        }
        let hero = actors[0]
        let goal = actors[target]
        var shot = make(.projectile, x: hero.x, y: hero.y, sprite: setup.ranged.projectile ?? "fx.bolt.hero", team: 0)
        aimActor(&shot, goal.x, goal.y)
        shot.speed = setup.tuning.room.projectileTilesPerSecond
        shot.life = RoomMath.ticks((numbers.rangedReach + 1.5) / shot.speed)
        shot.power = amount
        shot.crit = crit
        shot.hp = 1
        shot.maxHP = 1
        switch innate.kind {
        case "pierceBolts": shot.pierce = 2
        case "ricochet": shot.bounce = innate.targets ?? 1
        case "homing": shot.homing = goal.id
        default: break
        }
        actors.append(shot)
    }

    private mutating func rollCrit(extra: Double) -> Bool {
        if nextCrit {
            nextCrit = false
            return true
        }
        return CombatRoll.unitInterval(streams.combat.next()) < setup.tuning.combat.critChance + extra
    }

    private func hitAmount(coefficient: Double, crit: Bool) -> Double {
        CombatMath.outgoing(power: numbers.power, coefficient: coefficient, additive: [], multipliers: [], critDamage: setup.tuning.combat.critDamage, isCrit: crit)
    }

    // MARK: Relics, potions, opcodes

    private mutating func castRelic(_ slot: Int, rule: Int?) {
        let relic = setup.relics[slot]
        souls -= relic.souls
        relicWait[slot] = numbers.relicPeriods[slot]
        stats.relicCasts += 1
        events.append(.relic(slot: slot, rule: rule))
        let hero = actors[0]
        var center = (hero.x, hero.y)
        var target: Int?
        if let nearest = nearestEnemy(x: hero.x, y: hero.y), dist2(hero.x, hero.y, actors[nearest].x, actors[nearest].y) <= 36 {
            target = nearest
            if relic.opcodes.contains(where: { $0.op == "damage" || $0.op == "zone" || $0.op == "stun" }) {
                center = (actors[nearest].x, actors[nearest].y)
            }
        }
        run(relic.opcodes, x: center.0, y: center.1, target: target, source: .relic)
        fire("onCast", x: hero.x, y: hero.y, target: target)
    }

    private mutating func drink(rule: Int?) {
        guard potionCharges > 0, potionWait == 0, actors[0].living, actors[0].hp < actors[0].maxHP else { return }
        potionCharges -= 1
        potionWait = numbers.potionPeriod
        stats.potions += 1
        heal(actors[0].maxHP * setup.tuning.room.potionHeal)
        events.append(.potion(rule: rule))
        fire("onPotion", x: actors[0].x, y: actors[0].y, target: nil)
    }

    private mutating func heal(_ amount: Double) {
        guard amount > 0, actors[0].living else { return }
        let before = actors[0].hp
        actors[0].hp = min(actors[0].maxHP, actors[0].hp + amount)
        if actors[0].hp > before { events.append(.heal(amount: actors[0].hp - before)) }
    }

    private mutating func run(_ opcodes: [OpcodeSpec], x: Double, y: Double, target: Int?, source: DamageSource) {
        let maxHP = actors[0].maxHP
        for spec in opcodes {
            guard let effect = EffectRunner.resolve(spec, power: numbers.power, maxHP: maxHP) else { continue }
            switch effect {
            case .damage(_, let element, let radius):
                let coefficient = spec.coefficient ?? 0
                if radius > 0 {
                    events.append(.burst(x: x, y: y, radius: radius, element: element))
                    for index in enemies(near: x, y, radius: radius) {
                        let crit = rollCrit(extra: 0)
                        damageEnemy(index, hitAmount(coefficient: coefficient, crit: crit), crit: crit, source: source)
                    }
                } else if let target, actors[target].living {
                    let crit = rollCrit(extra: 0)
                    damageEnemy(target, hitAmount(coefficient: coefficient, crit: crit), crit: crit, source: source)
                }
            case .zone(let element, let radius, let duration, let coefficient):
                var zone = make(.zone, x: x, y: y, sprite: "fx.zone.\(element)", team: 0)
                zone.radius = radius
                zone.life = RoomMath.ticks(duration)
                zone.power = numbers.power * coefficient
                zone.element = element
                zone.hp = 1
                zone.maxHP = Double(zone.life)
                actors.append(zone)
            case .shield(let amount, let duration):
                shield = max(shield, amount)
                shieldTicks = max(shieldTicks, RoomMath.ticks(duration))
                events.append(.shield(amount: amount))
            case .heal(let fraction, _, let duration):
                if duration > 0 {
                    healTicks = RoomMath.ticks(duration)
                    healPerTick = maxHP * fraction / Double(RoomMath.ticksPerSecond)
                    events.append(.heal(amount: maxHP * fraction * duration))
                } else {
                    heal(maxHP * fraction)
                }
            case .root(let radius, let duration):
                events.append(.burst(x: x, y: y, radius: radius, element: "nature"))
                for index in enemies(near: actors[0].x, actors[0].y, radius: radius) {
                    actors[index].root = max(actors[index].root, RoomMath.ticks(duration))
                }
            case .stun(let radius, let duration):
                let hit = radius > 0 ? enemies(near: x, y, radius: radius) : (target.map { [$0] } ?? [])
                for index in hit where actors[index].living {
                    actors[index].stun = max(actors[index].stun, RoomMath.ticks(duration))
                }
                if hit.isEmpty == false { fire("onStun", x: x, y: y, target: hit.first) }
            case .dash(let tiles, let crits):
                dash(tiles: tiles)
                if crits { nextCrit = true }
                fire("onDash", x: actors[0].x, y: actors[0].y, target: nil)
            case .summon(let kind, let duration, let bite, let taunts):
                var ally = make(.ally, x: actors[0].x + 0.6, y: actors[0].y, sprite: "summon.\(kind)", team: 0)
                if blockedBox(ally.x, ally.y) { ally.x = actors[0].x }
                ally.hp = maxHP * 0.5
                ally.maxHP = ally.hp
                ally.power = numbers.power * bite
                ally.life = RoomMath.ticks(duration)
                ally.taunts = taunts
                ally.speed = setup.tuning.room.heroTilesPerSecond
                actors.append(ally)
            case .taunt(let radius, let duration):
                for index in enemies(near: actors[0].x, actors[0].y, radius: max(radius, 4)) {
                    actors[index].taunt = RoomMath.ticks(duration)
                }
            }
        }
    }

    private mutating func dash(tiles: Double) {
        var dx = 0.0
        var dy = -1.0
        if let nearest = nearestEnemy(x: actors[0].x, y: actors[0].y) {
            dx = actors[0].x - actors[nearest].x
            dy = actors[0].y - actors[nearest].y
            let length = (dx * dx + dy * dy).squareRoot()
            if length > 0.01 {
                dx /= length
                dy /= length
            }
        }
        var travelled = 0.0
        while travelled < tiles {
            let nx = actors[0].x + dx * 0.25
            let ny = actors[0].y + dy * 0.25
            if blockedBox(nx, ny) { break }
            actors[0].x = nx
            actors[0].y = ny
            travelled += 0.25
        }
        actors[0].moved = true
        path.removeAll()
    }

    /// Runs every signature listening for `hook`. Effects started by a signature never trigger another.
    private mutating func fire(_ hook: String, x: Double, y: Double, target: Int?) {
        guard hookDepth == 0 else { return }
        hookDepth += 1
        defer { hookDepth -= 1 }
        for (index, signature) in setup.signatures.enumerated() where signature.hook == hook {
            if let every = signature.every, every > 1 {
                hookCounters[index] += 1
                if hookCounters[index] % every != 0 { continue }
            }
            if let chance = signature.chance, chance < 1 {
                if CombatRoll.unitInterval(streams.combat.next()) >= chance { continue }
            }
            run(signature.opcodes ?? [], x: x, y: y, target: target, source: .signature)
        }
    }

    // MARK: Damage

    private mutating func damageEnemy(_ index: Int, _ amount: Double, crit: Bool, source: DamageSource) {
        guard actors[index].living, amount > 0 else { return }
        actors[index].hp -= amount
        actors[index].hurt = 4
        if source == .weapon { actors[index].hits += 1 }
        stats.damageDealt += amount
        events.append(.hit(id: actors[index].id, x: actors[index].x, y: actors[index].y, amount: amount, crit: crit, onHero: false))
        let x = actors[index].x
        let y = actors[index].y
        if source == .weapon {
            fire("onHit", x: x, y: y, target: index)
            if crit { fire("onCrit", x: x, y: y, target: index) }
        }
        if actors[index].hp <= 0, actors[index].death == 0 {
            kill(index)
            souls = min(SoulRules.cap, souls + SoulRules.perKill + (actors[index].elite ? SoulRules.perElite : 0))
            kills += 1
            killHash.add(UInt64(actors[index].id))
            record(actors[index])
            if source != .signature { fire("onKill", x: x, y: y, target: nil) }
        }
    }

    private mutating func record(_ actor: Actor) {
        let life = tick - actor.born
        guard actor.elite == false else { return }
        switch actor.kind {
        case .fodder:
            stats.fodder.kills += 1
            stats.fodder.lifeTicks += life
            stats.fodder.hits += actor.hits
        case .brute:
            stats.brute.kills += 1
            stats.brute.lifeTicks += life
            stats.brute.hits += actor.hits
        case .shooter:
            stats.shooter.kills += 1
            stats.shooter.lifeTicks += life
            stats.shooter.hits += actor.hits
        default:
            break
        }
    }

    private mutating func kill(_ index: Int) {
        actors[index].hp = 0
        actors[index].windup = 0
        actors[index].death = actors[index].kind == .hero ? RoomMath.heroDeathTicks : RoomMath.deathTicks
        actors[index].deathTotal = actors[index].death
        events.append(.death(id: actors[index].id, x: actors[index].x, y: actors[index].y, elite: actors[index].elite))
    }

    private mutating func hurtHero(_ raw: Double) {
        guard actors[0].living else { return }
        let taken = CombatMath.incoming(raw: raw, armor: 0, resist: 0, level: CombatMath.level(depth: setup.depth), reductions: [])
        var remaining = taken
        if shield > 0 {
            let absorbed = min(shield, remaining)
            shield -= absorbed
            remaining -= absorbed
            if shield <= 0 {
                shieldTicks = 0
                fire("onShieldBreak", x: actors[0].x, y: actors[0].y, target: nil)
            }
        }
        actors[0].hp -= remaining
        actors[0].hurt = 4
        stats.damageTaken += remaining
        events.append(.hit(id: actors[0].id, x: actors[0].x, y: actors[0].y, amount: taken, crit: false, onHero: true))
        fire("onHurt", x: actors[0].x, y: actors[0].y, target: nil)
        if actors[0].hp <= 0 {
            kill(0)
            heroDown = true
            stats.heroDownTick = tick
            events.append(.heroDown)
        }
    }

    private mutating func hurtAlly(_ index: Int, _ amount: Double) {
        guard actors[index].living else { return }
        actors[index].hp -= amount
        actors[index].hurt = 4
        if actors[index].hp <= 0 { kill(index) }
    }

    // MARK: Mobs

    private mutating func mobsThink() {
        for index in actors.indices where actors[index].living && actors[index].team == 1 {
            guard actors[index].stun == 0, actors[index].windup == 0 else { continue }
            let goal = mobGoal(index)
            let actor = actors[index]
            let goalActor = actors[goal]
            let distance = dist2(actor.x, actor.y, goalActor.x, goalActor.y)
            face(index, toward: goalActor.x)
            let kind = actor.taunt > 0 && actor.kind == .shooter ? ActorKind.fodder : actor.kind
            switch kind {
            case .brute:
                if distance <= 1.6 * 1.6, actor.wait == 0 {
                    actors[index].windup = numbers.slamTicks
                    actors[index].windupTotal = numbers.slamTicks
                    actors[index].aimX = goalActor.x
                    actors[index].aimY = goalActor.y
                } else if distance > 0.9 * 0.9 {
                    chase(index, goal: goal, speed: setup.tuning.room.bruteTilesPerSecond)
                }
            case .shooter:
                let sight = lineOfSight(actor.x, actor.y, goalActor.x, goalActor.y)
                if distance < 3.5 * 3.5 {
                    var dx = actor.x - goalActor.x
                    var dy = actor.y - goalActor.y
                    let length = (dx * dx + dy * dy).squareRoot()
                    if length > 0.01 {
                        dx /= length
                        dy /= length
                    }
                    move(index, dx, dy, speed: setup.tuning.room.rangedTilesPerSecond)
                } else if distance > 6.5 * 6.5 || sight == false {
                    chase(index, goal: goal, speed: setup.tuning.room.rangedTilesPerSecond)
                } else if actor.wait == 0 {
                    actors[index].windup = RoomMath.shooterWindupTicks
                    actors[index].windupTotal = RoomMath.shooterWindupTicks
                    actors[index].aimX = goalActor.x
                    actors[index].aimY = goalActor.y
                }
            default:
                if distance <= 0.9 * 0.9 {
                    if actor.wait == 0 {
                        actors[index].wait = numbers.fodderPeriod
                        actors[index].flash = 6
                        let amount = numbers.enemyDamage * (actor.elite ? 1.5 : 1)
                        if goal == 0 { hurtHero(amount) } else { hurtAlly(goal, amount) }
                    }
                } else {
                    chase(index, goal: goal, speed: setup.tuning.room.fodderTilesPerSecond)
                }
            }
        }
    }

    /// The hero, unless a taunting summon is close enough to pull this mob.
    private func mobGoal(_ index: Int) -> Int {
        let actor = actors[index]
        var best = 0
        var bestDistance = RoomMath.allyTauntRange * RoomMath.allyTauntRange
        for (other, ally) in actors.enumerated() where ally.kind == .ally && ally.living && ally.taunts {
            let distance = dist2(actor.x, actor.y, ally.x, ally.y)
            if distance <= bestDistance {
                bestDistance = distance
                best = other
            }
        }
        return best
    }

    private mutating func chase(_ index: Int, goal: Int, speed: Double) {
        guard actors[index].root == 0 else { return }
        let actor = actors[index]
        let target = actors[goal]
        if goal != 0 || dist2(actor.x, actor.y, target.x, target.y) <= 2.25 {
            steer(index, toward: target.x, target.y, speed: speed)
            return
        }
        let cell = Int(actor.y) * width + Int(actor.x)
        guard cell >= 0, cell < flow.sx.count else { return }
        let sx = Int(flow.sx[cell])
        let sy = Int(flow.sy[cell])
        if sx == 0, sy == 0 {
            steer(index, toward: target.x, target.y, speed: speed)
            return
        }
        steer(index, toward: Double(Int(actor.x) + sx) + 0.5, Double(Int(actor.y) + sy) + 0.5, speed: speed)
    }

    private mutating func resolveWindup(_ index: Int) {
        let actor = actors[index]
        if actor.kind == .brute {
            let radius = setup.tuning.room.slamRadius
            events.append(.burst(x: actor.aimX, y: actor.aimY, radius: radius, element: "physical"))
            let amount = numbers.enemyDamage * setup.tuning.room.bruteDamage * (actor.elite ? 1.5 : 1)
            if actors[0].living, dist2(actors[0].x, actors[0].y, actor.aimX, actor.aimY) <= radius * radius {
                stats.slamsLanded += 1
                hurtHero(amount)
            } else {
                stats.slamsDodged += 1
            }
            for other in actors.indices where actors[other].kind == .ally && actors[other].living {
                if dist2(actors[other].x, actors[other].y, actor.aimX, actor.aimY) <= radius * radius {
                    hurtAlly(other, amount)
                }
            }
            actors[index].wait = numbers.bruteRecovery
            actors[index].flash = 6
        } else if actor.kind == .shooter {
            var bolt = make(.projectile, x: actor.x, y: actor.y, sprite: "fx.bolt.enemy", team: 1)
            aimActor(&bolt, actor.aimX, actor.aimY)
            bolt.speed = setup.tuning.room.boltTilesPerSecond
            bolt.life = RoomMath.ticks(9 / bolt.speed)
            bolt.power = numbers.enemyDamage * (actor.elite ? 1.5 : 1)
            bolt.hp = 1
            bolt.maxHP = 1
            actors.append(bolt)
            actors[index].wait = numbers.shooterPeriod
            actors[index].flash = 6
        }
    }

    // MARK: Allies, projectiles, zones

    private mutating func alliesThink() {
        for index in actors.indices where actors[index].kind == .ally && actors[index].living {
            guard let target = nearestEnemy(x: actors[index].x, y: actors[index].y) else {
                if dist2(actors[index].x, actors[index].y, actors[0].x, actors[0].y) > 2.25 {
                    steer(index, toward: actors[0].x, actors[0].y, speed: actors[index].speed)
                }
                continue
            }
            let distance = dist2(actors[index].x, actors[index].y, actors[target].x, actors[target].y)
            face(index, toward: actors[target].x)
            if distance > 0.9 * 0.9 {
                steer(index, toward: actors[target].x, actors[target].y, speed: actors[index].speed)
            } else if actors[index].wait == 0 {
                actors[index].wait = RoomMath.allyBiteTicks
                actors[index].flash = 6
                damageEnemy(target, actors[index].power, crit: false, source: .ally)
            }
        }
    }

    private mutating func stepProjectile(_ index: Int) {
        if actors[index].homing != 0, let goal = actors.firstIndex(where: { $0.id == actors[index].homing && $0.living }) {
            let tx = actors[goal].x
            let ty = actors[goal].y
            aimActor(&actors[index], tx, ty)
        }
        let step = actors[index].speed * RoomMath.dt
        actors[index].x += actors[index].dx * step
        actors[index].y += actors[index].dy * step
        actors[index].life -= 1
        if actors[index].life <= 0 || blockedPoint(actors[index].x, actors[index].y) {
            actors[index].hp = 0
            return
        }
        let shot = actors[index]
        for other in actors.indices where actors[other].living && actors[other].team != shot.team && actors[other].id != shot.lastHit {
            guard dist2(shot.x, shot.y, actors[other].x, actors[other].y) <= 0.45 * 0.45 else { continue }
            if shot.team == 1 {
                if other == 0 { hurtHero(shot.power) } else { hurtAlly(other, shot.power) }
                actors[index].hp = 0
                return
            }
            damageEnemy(other, shot.power, crit: shot.crit, source: .weapon)
            actors[index].lastHit = actors[other].id
            if actors[index].pierce > 0 {
                actors[index].pierce -= 1
                return
            }
            if actors[index].bounce > 0 {
                actors[index].bounce -= 1
                let hitX = actors[other].x
                let hitY = actors[other].y
                let next = enemies(near: hitX, hitY, radius: 4).first { actors[$0].id != actors[index].lastHit }
                if let next {
                    let nx = actors[next].x
                    let ny = actors[next].y
                    aimActor(&actors[index], nx, ny)
                    actors[index].life = RoomMath.ticks(5 / actors[index].speed)
                    return
                }
            }
            actors[index].hp = 0
            return
        }
    }

    private mutating func stepZone(_ index: Int) {
        actors[index].life -= 1
        if actors[index].life <= 0 {
            actors[index].hp = 0
            return
        }
        guard actors[index].power > 0, actors[index].life % RoomMath.zonePulseTicks == 0 else { return }
        let amount = actors[index].power * Double(RoomMath.zonePulseTicks) / Double(RoomMath.ticksPerSecond)
        for other in enemies(near: actors[index].x, actors[index].y, radius: actors[index].radius) {
            damageEnemy(other, amount, crit: false, source: .zone)
        }
    }

    // MARK: Waves

    private mutating func spawnHero() {
        let point = setup.room.hero
        var hero = make(.hero, x: Double(point.x) + 0.5, y: Double(height - 1 - point.y) + 0.5, sprite: "hero", team: 0)
        hero.hp = numbers.heroHP
        hero.maxHP = numbers.heroHP
        actors.append(hero)
    }

    private mutating func spawnWave() {
        wave += 1
        waveCleared = false
        stats.waves = wave
        let room = setup.tuning.room
        let champions = room.championEvery > 0 && wave % room.championEvery == 0
        var fodder = min(8, 3 + wave / 2) + Int(streams.population.next() % 2)
        let brutes = wave >= 2 ? (wave >= 7 ? 2 : 1) : 0
        let shooters = wave >= 4 ? 2 : 1
        if champions {
            fodder /= 2
            for _ in 0..<3 { spawnMob(.fodder, elite: true) }
        }
        for _ in 0..<fodder { spawnMob(.fodder, elite: false) }
        for _ in 0..<brutes { spawnMob(.brute, elite: false) }
        for _ in 0..<shooters { spawnMob(.shooter, elite: false) }
        events.append(.wave(number: wave, champions: champions))
    }

    private mutating func spawnMob(_ kind: ActorKind, elite: Bool) {
        let rects = setup.room.spawns
        guard rects.isEmpty == false else { return }
        var x = 0.0
        var y = 0.0
        for _ in 0..<8 {
            let rect = rects[Int(streams.population.next() % UInt64(rects.count))]
            let column = rect.x + Int(streams.population.next() % UInt64(max(1, rect.w)))
            let row = rect.y + Int(streams.population.next() % UInt64(max(1, rect.h)))
            let jitter = Double(Int(streams.population.next() % 5) - 2) * 0.08
            x = Double(column) + 0.5 + jitter
            y = Double(height - 1 - row) + 0.5
            if blockedBox(x, y) == false { break }
        }
        let definition: MobDefinition
        let scale: Double
        switch kind {
        case .brute:
            definition = setup.brute
            scale = setup.tuning.room.bruteHitPoints
        case .shooter:
            definition = setup.shooter
            scale = setup.tuning.room.rangedHitPoints
        default:
            definition = setup.fodder
            scale = 1
        }
        var mob = make(kind, x: x, y: y, sprite: definition.sprite, team: 1)
        mob.elite = elite
        mob.hp = numbers.fodderHP * scale * (elite ? setup.tuning.room.eliteHitPoints : 1)
        mob.maxHP = mob.hp
        mob.facing = -1
        mob.wait = RoomMath.ticks(0.5)
        actors.append(mob)
    }

    private mutating func reap() {
        actors.removeAll { actor in
            if actor.kind == .hero { return false }
            return actor.hp <= 0 && actor.death == 0
        }
        let living = actors.contains { $0.living && $0.team == 1 }
        if waveCleared == false, living == false, heroDown == false {
            waveCleared = true
            if stats.firstWaveTick == nil { stats.firstWaveTick = tick }
            potionCharges = min(setup.tuning.room.potionCharges, potionCharges + setup.tuning.room.potionRefillPerWave)
            waveTimer = numbers.waveDelay
        }
    }

    private mutating func separate() {
        grid.rebuild(actors)
        let indexes = actors.indices.filter { actors[$0].living && actors[$0].kind != .hero }
        for left in indexes {
            for right in grid.query(x: actors[left].x, y: actors[left].y, radius: 0.6) where right > left && actors[right].living && actors[right].kind != .hero {
                push(left, right, spacing: 0.55)
            }
            push(0, left, spacing: 0.6, moveFirst: false)
        }
    }

    private mutating func push(_ left: Int, _ right: Int, spacing: Double, moveFirst: Bool = true) {
        guard actors[left].living, actors[right].living else { return }
        var dx = actors[right].x - actors[left].x
        var dy = actors[right].y - actors[left].y
        let squared = dx * dx + dy * dy
        guard squared < spacing * spacing else { return }
        var length = squared.squareRoot()
        if length < 0.001 {
            dx = actors[right].id % 2 == 0 ? 1 : -1
            dy = 0
            length = 1
        }
        let overlap = (spacing - min(length, spacing)) / 2
        let ux = dx / length * overlap
        let uy = dy / length * overlap
        nudge(right, ux * (moveFirst ? 1 : 2), uy * (moveFirst ? 1 : 2))
        if moveFirst { nudge(left, -ux, -uy) }
    }

    private mutating func nudge(_ index: Int, _ dx: Double, _ dy: Double) {
        if blockedBox(actors[index].x + dx, actors[index].y) == false { actors[index].x += dx }
        if blockedBox(actors[index].x, actors[index].y + dy) == false { actors[index].y += dy }
    }

    private mutating func checkInvariants() {
        for index in actors.indices {
            if actors[index].hp.isFinite == false || actors[index].x.isFinite == false || actors[index].y.isFinite == false {
                actors[index].hp = 0
                actors[index].x = actors[0].x
                actors[index].y = actors[0].y
                stats.invariants += 1
                events.append(.invariant(code: "invariant_nan"))
            } else if actors[index].hp < 0 {
                actors[index].hp = 0
            }
        }
        if souls.isFinite == false || souls < 0 {
            souls = 0
            stats.invariants += 1
            events.append(.invariant(code: "invariant_negative_souls"))
        }
    }

    private mutating func paint() {
        for index in actors.indices {
            let actor = actors[index]
            if actor.death > 0 || (actor.hp <= 0 && actor.kind.creature) {
                actors[index].anim = .death
                actors[index].phase = actor.death == 0 ? 1 : 1 - Double(actor.death) / Double(max(1, actor.deathTotal))
            } else if actor.hurt > 0 {
                actors[index].anim = .hit
                actors[index].phase = Double(actor.hurt) / 4
            } else if actor.windup > 0 {
                actors[index].anim = .windup
                actors[index].phase = 1 - Double(actor.windup) / Double(max(1, actor.windupTotal))
            } else if actor.flash > 0 {
                actors[index].anim = .attack
                actors[index].phase = 1 - Double(actor.flash) / 6
            } else if actor.moved || actor.kind == .projectile {
                actors[index].anim = .walk
                actors[index].phase = 0
            } else {
                actors[index].anim = .idle
                actors[index].phase = 0
            }
        }
    }

    // MARK: Geometry

    private mutating func make(_ kind: ActorKind, x: Double, y: Double, sprite: String, team: UInt8) -> Actor {
        let id = nextID
        nextID += 1
        return Actor(id: id, kind: kind, team: team, x: x, y: y, hp: 1, maxHP: 1, sprite: sprite, born: tick)
    }

    private mutating func steer(_ index: Int, toward x: Double, _ y: Double, speed: Double) {
        var dx = x - actors[index].x
        var dy = y - actors[index].y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0.001 else { return }
        dx /= length
        dy /= length
        move(index, dx, dy, speed: min(speed, length * Double(RoomMath.ticksPerSecond)))
    }

    private mutating func move(_ index: Int, _ dx: Double, _ dy: Double, speed: Double) {
        guard actors[index].root == 0 || actors[index].kind == .hero else { return }
        let step = speed * RoomMath.dt
        let nx = actors[index].x + dx * step
        let ny = actors[index].y + dy * step
        if blockedBox(nx, actors[index].y) == false { actors[index].x = nx }
        if blockedBox(actors[index].x, ny) == false { actors[index].y = ny }
        if dx > 0.05 { actors[index].facing = 1 }
        if dx < -0.05 { actors[index].facing = -1 }
        actors[index].moved = true
    }

    private mutating func face(_ index: Int, toward x: Double) {
        if x > actors[index].x + 0.05 { actors[index].facing = 1 }
        if x < actors[index].x - 0.05 { actors[index].facing = -1 }
    }

    func nearestEnemy(x: Double, y: Double) -> Int? {
        var best: Int?
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, actor) in actors.enumerated() where actor.living && actor.team == 1 {
            let distance = dist2(x, y, actor.x, actor.y)
            if distance < bestDistance {
                bestDistance = distance
                best = index
            }
        }
        return best
    }

    private func enemies(near x: Double, _ y: Double, radius: Double) -> [Int] {
        let reach = (radius + RoomMath.bodyRadius) * (radius + RoomMath.bodyRadius)
        return actors.indices.filter { actors[$0].living && actors[$0].team == 1 && dist2(x, y, actors[$0].x, actors[$0].y) <= reach }
    }

    func lineOfSight(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Bool {
        let dx = bx - ax
        let dy = by - ay
        let steps = Int((dx * dx + dy * dy).squareRoot() / 0.25) + 1
        for step in 1..<steps {
            let t = Double(step) / Double(steps)
            if blockedPoint(ax + dx * t, ay + dy * t) { return false }
        }
        return true
    }

    func blockedPoint(_ x: Double, _ y: Double) -> Bool {
        if x < 0 || y < 0 { return true }
        let tx = Int(x)
        let ty = Int(y)
        if tx >= width || ty >= height { return true }
        return blocked[ty * width + tx]
    }

    func blockedBox(_ x: Double, _ y: Double) -> Bool {
        let r = RoomMath.bodyRadius
        return blockedPoint(x - r, y - r) || blockedPoint(x + r, y - r) || blockedPoint(x - r, y + r) || blockedPoint(x + r, y + r)
    }

    // MARK: Output

    func feed(_ hash: inout FNV64) {
        hash.add(UInt64(tick))
        hash.add(souls.bitPattern)
        hash.add(shield.bitPattern)
        hash.add(UInt64(shieldTicks))
        for wait in relicWait { hash.add(UInt64(wait)) }
        hash.add(UInt64(potionCharges))
        hash.add(UInt64(potionWait))
        hash.add(UInt64(swings))
        hash.add(UInt64(shots))
        hash.add(UInt64(wave))
        hash.add(UInt64(waveTimer))
        hash.add(UInt64(kills))
        hash.add(killHash.value)
        streams.layout.feed(&hash)
        streams.population.feed(&hash)
        streams.combat.feed(&hash)
        streams.loot.feed(&hash)
        for actor in actors {
            hash.add(UInt64(actor.id))
            hash.add(UInt64(actor.kind.rawValue))
            hash.add(actor.x.bitPattern)
            hash.add(actor.y.bitPattern)
            hash.add(actor.hp.bitPattern)
            hash.add(UInt64(actor.wait))
            hash.add(UInt64(actor.windup))
            hash.add(UInt64(actor.stun))
            hash.add(UInt64(actor.root))
            hash.add(UInt64(bitPattern: Int64(actor.life)))
        }
    }

    func entities() -> [EntityPose] {
        actors.filter { $0.kind != .zone }.map { actor in
            EntityPose(
                id: actor.id, kind: actor.kind, x: actor.x, y: actor.y, facing: actor.facing, anim: actor.anim, phase: actor.phase,
                hp: actor.hp, maxHP: actor.maxHP, sprite: actor.sprite, elite: actor.elite,
                rooted: actor.root > 0, stunned: actor.stun > 0, hostile: actor.team == 1, dx: actor.dx, dy: actor.dy
            )
        }
    }

    func telegraphs() -> [TelegraphSnapshot] {
        actors.compactMap { actor in
            guard actor.living, actor.windup > 0 else { return nil }
            let progress = 1 - Double(actor.windup) / Double(max(1, actor.windupTotal))
            let radius = actor.kind == .brute ? setup.tuning.room.slamRadius : 0.45
            return TelegraphSnapshot(id: actor.id, x: actor.aimX, y: actor.aimY, radius: radius, progress: progress, slam: actor.kind == .brute)
        }
    }

    func grounds() -> [GroundSnapshot] {
        actors.compactMap { actor in
            guard actor.kind == .zone, actor.hp > 0 else { return nil }
            return GroundSnapshot(id: actor.id, x: actor.x, y: actor.y, radius: actor.radius, element: actor.element, life: Double(actor.life) / max(1, actor.maxHP))
        }
    }
}

func aimActor(_ actor: inout Actor, _ x: Double, _ y: Double) {
    var dx = x - actor.x
    var dy = y - actor.y
    let length = (dx * dx + dy * dy).squareRoot()
    if length < 0.001 {
        dx = Double(actor.facing)
        dy = 0
    } else {
        dx /= length
        dy /= length
    }
    actor.dx = dx
    actor.dy = dy
    actor.facing = dx < 0 ? -1 : 1
}

func dist2(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Double {
    let dx = ax - bx
    let dy = ay - by
    return dx * dx + dy * dy
}
