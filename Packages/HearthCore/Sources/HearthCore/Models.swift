public enum WeaponKind: String, Codable, Sendable, Equatable {
    case melee
    case ranged
}

public struct InnateSpec: Codable, Sendable, Equatable {
    public var kind: String
    public var hits: Int?
    public var seconds: Double?
    public var chance: Double?
    public var enemies: Int?
    public var fraction: Double?
    public var shots: Int?
    public var bonus: Double?
    public var targets: Int?
}

public struct WeaponDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var kind: WeaponKind
    public var rangeTiles: Double
    public var attacksPerSecond: Double
    public var innate: InnateSpec
    public var sprite: String?
    public var projectile: String?
}

public struct RelicDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var souls: Double
    public var cooldown: Double
    public var tags: [String]
    public var opcodes: [OpcodeSpec]
}

/// A stat bonus. Charms carry `ranks` (I, II, III); everything else carries `value`.
public struct StatEffect: Codable, Sendable, Equatable {
    public var stat: String
    public var value: Double?
    public var ranks: [Double]?
}

public struct CharmDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var effect: String
    public var stats: [StatEffect]
}

/// A hook that runs opcodes, or enqueues a Relic for free, when its event fires.
public struct SignatureSpec: Codable, Sendable, Equatable {
    public var hook: String
    public var chance: Double?
    public var every: Int?
    public var enqueues: String?
    public var opcodes: [OpcodeSpec]?
    public var stats: [StatEffect]?

    public init(hook: String, chance: Double? = nil, every: Int? = nil, enqueues: String? = nil, opcodes: [OpcodeSpec]? = nil, stats: [StatEffect]? = nil) {
        self.hook = hook
        self.chance = chance
        self.every = every
        self.enqueues = enqueues
        self.opcodes = opcodes
        self.stats = stats
    }
}

public struct UniqueDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var slot: String
    public var weaponType: String?
    public var baseRelic: String?
    public var signature: String
    public var effect: SignatureSpec
}

public struct SetPiece: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var slot: String
}

public struct SetDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var pieces: [SetPiece]
    public var bonus2: String
    public var bonus2Stats: [StatEffect]
    public var bonus4: String
    public var bonus4Effect: SignatureSpec
}

public struct FamilyDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var biome: String
}

public struct MobDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var family: String
    public var role: String
    public var biome: String
    public var sprite: String
    public var telegraphSeconds: Double?
}

public struct MechanicSpec: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var telegraphSeconds: Double
    public var shape: String
    public var opcodes: [OpcodeSpec]
}

public struct GuardianDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var biome: String
    public var family: String
    public var sprite: String
    public var hpMultiplier: Double
    public var enrageAt: Double
    public var mechanics: [MechanicSpec]
}

public struct WardenDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var depth: Int
    public var sprite: String
    public var hpMultiplier: Double
    public var enrageAt: Double
    public var phases: [[MechanicSpec]]
}

public struct WandererDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var role: String
    public var building: String
    public var sprite: String
    public var intro: [String]
}

public struct RiftModifierDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var effect: String
    public var fromDepth: Int
    public var stats: [StatEffect]
}

public enum BuildingUnlock: Codable, Sendable, Equatable {
    case onboarding
    case depth(Int)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let depth = try? container.decode(Int.self) {
            self = .depth(depth)
            return
        }
        let label = try container.decode(String.self)
        guard label == "onboarding" else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown building unlock \(label)")
        }
        self = .onboarding
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .onboarding:
            try container.encode("onboarding")
        case .depth(let depth):
            try container.encode(depth)
        }
    }
}

public struct BuildingDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var wanderer: String
    public var unlock: BuildingUnlock
    public var sprite: String
}

public struct EliteAffixDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var effect: String
    public var unlockDepth: Int
    public var color: String
    public var shape: String
}

public struct RiftEventDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var effect: String
    public var weight: Int
    public var fromDepth: Int
}

public struct LoadoutFixture: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var melee: String
    public var ranged: String
    public var relics: [String]
    public var charms: [String]
    public var uniqueWeapon: String?
    public var tactics: String
    public var depths: [Int]
}

public struct CombatTuning: Codable, Sendable, Equatable {
    public var p0: Double
    public var hp0: Double
    public var dmg0: Double
    public var h0: Double
    public var critChance: Double
    public var critDamage: Double
}

public struct XPCurveTuning: Codable, Sendable, Equatable {
    public var base: Double
    public var growth: Double
}

/// Salvage yields and the smith prices the spec leaves open. Growth and re-roll doubling use repeated multiplication.
public struct SmithTuning: Codable, Sendable, Equatable {
    public var commonDust: Double
    public var rareShards: Double
    public var uniqueEmbers: Double
    public var raiseDust: Double
    public var raiseGold: Double
    public var raiseGrowth: Double
    /// Shards for the first re-roll of one affix on a Rare. Each later re-roll on that item doubles it.
    public var rerollRareShards: Double
    /// Embers for the first re-roll of one affix on a Unique.
    public var rerollUniqueEmbers: Double
    /// Shards to craft one Rare of a chosen slot and type.
    public var craftRareShards: Double
    /// Embers to turn a Unique into another Unique of the same slot.
    public var transmuteEmbers: Double

    private enum CodingKeys: String, CodingKey {
        case commonDust, rareShards, uniqueEmbers, raiseDust, raiseGold, raiseGrowth
        case rerollRareShards, rerollUniqueEmbers, craftRareShards, transmuteEmbers
    }

    public init(
        commonDust: Double, rareShards: Double, uniqueEmbers: Double,
        raiseDust: Double, raiseGold: Double, raiseGrowth: Double,
        rerollRareShards: Double = 4, rerollUniqueEmbers: Double = 2,
        craftRareShards: Double = 8, transmuteEmbers: Double = 12
    ) {
        self.commonDust = commonDust
        self.rareShards = rareShards
        self.uniqueEmbers = uniqueEmbers
        self.raiseDust = raiseDust
        self.raiseGold = raiseGold
        self.raiseGrowth = raiseGrowth
        self.rerollRareShards = rerollRareShards
        self.rerollUniqueEmbers = rerollUniqueEmbers
        self.craftRareShards = craftRareShards
        self.transmuteEmbers = transmuteEmbers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commonDust = try container.decode(Double.self, forKey: .commonDust)
        rareShards = try container.decode(Double.self, forKey: .rareShards)
        uniqueEmbers = try container.decode(Double.self, forKey: .uniqueEmbers)
        raiseDust = try container.decode(Double.self, forKey: .raiseDust)
        raiseGold = try container.decode(Double.self, forKey: .raiseGold)
        raiseGrowth = try container.decode(Double.self, forKey: .raiseGrowth)
        rerollRareShards = try container.decodeIfPresent(Double.self, forKey: .rerollRareShards) ?? 4
        rerollUniqueEmbers = try container.decodeIfPresent(Double.self, forKey: .rerollUniqueEmbers) ?? 2
        craftRareShards = try container.decodeIfPresent(Double.self, forKey: .craftRareShards) ?? 8
        transmuteEmbers = try container.decodeIfPresent(Double.self, forKey: .transmuteEmbers) ?? 12
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commonDust, forKey: .commonDust)
        try container.encode(rareShards, forKey: .rareShards)
        try container.encode(uniqueEmbers, forKey: .uniqueEmbers)
        try container.encode(raiseDust, forKey: .raiseDust)
        try container.encode(raiseGold, forKey: .raiseGold)
        try container.encode(raiseGrowth, forKey: .raiseGrowth)
        try container.encode(rerollRareShards, forKey: .rerollRareShards)
        try container.encode(rerollUniqueEmbers, forKey: .rerollUniqueEmbers)
        try container.encode(craftRareShards, forKey: .craftRareShards)
        try container.encode(transmuteEmbers, forKey: .transmuteEmbers)
    }
}

public struct RoomTuning: Codable, Sendable, Equatable {
    public var heroTilesPerSecond: Double
    public var heroReactionSeconds: Double
    public var swapTiles: Double
    public var fodderTilesPerSecond: Double
    public var bruteTilesPerSecond: Double
    public var rangedTilesPerSecond: Double
    public var projectileTilesPerSecond: Double
    public var boltTilesPerSecond: Double
    public var fodderAttackSeconds: Double
    public var bruteRecoverySeconds: Double
    public var rangedAttackSeconds: Double
    public var bruteHitPoints: Double
    public var rangedHitPoints: Double
    public var eliteHitPoints: Double
    public var bruteDamage: Double
    public var slamRadius: Double
    public var potionHeal: Double
    public var potionCooldown: Double
    public var potionCharges: Int
    public var potionRefillPerWave: Int
    public var startingSouls: Double
    public var waveDelaySeconds: Double
    public var championEvery: Int
}

public struct Tuning: Codable, Sendable, Equatable {
    public var proposal: Bool
    public var combat: CombatTuning
    public var heroXP: XPCurveTuning
    public var paragonXP: XPCurveTuning
    /// Flat gold added when a Rift ends. The spec leaves this number in tuning.
    public var riftGold: Double
    /// Max HP added on the next fight for each hero level after 1. Applied through `RoomSetup.bonusHP`.
    public var heroHPPerLevel: Double
    public var smith: SmithTuning
    public var soulRegenPerSecond: Double
    public var room: RoomTuning
}

/// The M0 slice: which room, loadout, Tactics preset, and mobs the one-room fight uses.
public struct SliceDefinition: Codable, Sendable, Equatable {
    public var room: String
    public var depth: Int
    public var melee: String
    public var ranged: String
    public var relics: [String]
    public var tactics: String
    public var fodder: String
    public var brute: String
    public var shooter: String
}
