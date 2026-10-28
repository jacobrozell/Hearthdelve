public enum EffectCatalog {
    public static let opcodes: Set<String> = [
        "damage", "zone", "shield", "heal", "root", "dash", "summon", "taunt", "stun",
    ]
    public static let hooks: Set<String> = [
        "onHit", "onCrit", "onKill", "onStun", "onCast", "onHurt", "onPotion", "onShieldBreak", "onDash", "passive",
    ]
    public static let innate: Set<String> = [
        "cleaveEvery", "stunEvery", "critChance", "pierce", "arcHeal",
        "chargedEvery", "pierceBolts", "homing", "ricochet",
    ]
    public static let elements: Set<String> = [
        "fire", "frost", "nature", "radiant", "shadow", "untyped", "physical",
    ]
    public static let relicElements: Set<String> = ["fire", "frost", "nature", "radiant", "shadow", "untyped"]
    public static let roles: Set<String> = ["fodder", "brute", "ranged", "caster", "swarmer"]
    public static let slots: Set<String> = ["melee", "ranged", "helm", "chest", "legs", "boots", "relic"]
    public static let shapes: Set<String> = ["circle", "ring", "line", "cone", "square", "triangle", "diamond", "star"]
    public static let stats: Set<String> = [
        "burnDamage", "magicFind", "damageTakenWhileStill", "lanternBurn", "summonPower", "maxSouls", "soulsPerKill",
        "critChance", "critDamage", "attackSpeed", "cooldownReduction", "areaDamage", "elementalDamage", "eliteDamage",
        "maxHP", "armor", "allResist", "dodge", "lifePerHit", "moveSpeed", "soulGain", "lanternEfficiency",
        "relicDamage", "soulCost", "relicDuration", "relicRadius", "potionHeal", "shieldStrength", "rootDuration",
        "stunDuration", "meleeDamage", "rangedDamage", "damageTaken", "healingReceived", "lanternPauseOnCooldownOver",
        "enemyHP", "enemyDamage", "enemySpeed", "fodderCount", "visionRadius", "materialFind", "goldFind", "xpGain",
        "lootQuality", "lanternBurnRate", "eliteAffixes", "packCount",
    ]
    public static let conditions: Set<String> = [
        "always", "selfHPBelow", "eliteWithin", "enemiesWithin", "soulsAtLeast", "targetBeyond", "targetIsElite", "shieldDown",
    ]
    public static let actions: Set<String> = ["potion", "relic", "melee", "ranged"]
}

public struct OpcodeSpec: Codable, Sendable, Equatable {
    public var op: String
    public var coefficient: Double?
    public var element: String?
    public var radius: Double?
    public var duration: Double?
    public var fraction: Double?
    public var tiles: Double?
    public var kind: String?
    public var taunts: Bool?
    public var nextCrit: Bool?

    public init(
        op: String, coefficient: Double? = nil, element: String? = nil, radius: Double? = nil, duration: Double? = nil,
        fraction: Double? = nil, tiles: Double? = nil, kind: String? = nil, taunts: Bool? = nil, nextCrit: Bool? = nil
    ) {
        self.op = op
        self.coefficient = coefficient
        self.element = element
        self.radius = radius
        self.duration = duration
        self.fraction = fraction
        self.tiles = tiles
        self.kind = kind
        self.taunts = taunts
        self.nextCrit = nextCrit
    }
}

public enum ResolvedEffect: Sendable, Equatable {
    case damage(amount: Double, element: String, radius: Double)
    case zone(element: String, radius: Double, duration: Double, coefficient: Double)
    case shield(amount: Double, duration: Double)
    case heal(fractionPerSecond: Double, radius: Double, duration: Double)
    case root(radius: Double, duration: Double)
    case dash(tiles: Double, nextAttackCrits: Bool)
    case summon(kind: String, duration: Double, biteCoefficient: Double, taunts: Bool)
    case taunt(radius: Double, duration: Double)
    case stun(radius: Double, duration: Double)
}

public enum EffectRunner {
    public static func resolve(
        _ spec: OpcodeSpec,
        power: Double,
        maxHP: Double,
        additive: [Double] = [],
        multipliers: [Double] = [],
        critDamage: Double = 0.5,
        isCrit: Bool = false
    ) -> ResolvedEffect? {
        switch spec.op {
        case "damage":
            let amount = CombatMath.outgoing(
                power: power,
                coefficient: spec.coefficient ?? 0,
                additive: additive,
                multipliers: multipliers,
                critDamage: critDamage,
                isCrit: isCrit
            )
            return .damage(amount: amount, element: spec.element ?? "physical", radius: spec.radius ?? 0)
        case "zone":
            return .zone(
                element: spec.element ?? "physical",
                radius: spec.radius ?? 0,
                duration: spec.duration ?? 0,
                coefficient: spec.coefficient ?? 0
            )
        case "shield":
            return .shield(amount: maxHP * (spec.fraction ?? 0), duration: spec.duration ?? 0)
        case "heal":
            return .heal(
                fractionPerSecond: spec.fraction ?? 0,
                radius: spec.radius ?? 0,
                duration: spec.duration ?? 0
            )
        case "root":
            return .root(radius: spec.radius ?? 0, duration: spec.duration ?? 0)
        case "dash":
            return .dash(tiles: spec.tiles ?? 0, nextAttackCrits: spec.nextCrit ?? false)
        case "summon":
            return .summon(
                kind: spec.kind ?? "",
                duration: spec.duration ?? 0,
                biteCoefficient: spec.coefficient ?? 0,
                taunts: spec.taunts ?? false
            )
        case "taunt":
            return .taunt(radius: spec.radius ?? 0, duration: spec.duration ?? 0)
        case "stun":
            return .stun(radius: spec.radius ?? 0, duration: spec.duration ?? 0)
        default:
            return nil
        }
    }
}
