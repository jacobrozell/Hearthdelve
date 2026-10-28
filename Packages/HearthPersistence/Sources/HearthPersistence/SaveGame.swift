import Foundation
import HearthCore

public struct ItemSave: Codable, Sendable, Equatable {
    public var id: String
    public var definition: String
    public var itemLevel: Int
    public var rarity: String
    public var quality: String
    public var affixes: [String]
    public var signature: String?
    public var locked: Bool
    public var favorite: Bool
    public var glyphSockets: [String]

    public init(id: String, definition: String, itemLevel: Int, rarity: String, quality: String, affixes: [String], signature: String?, locked: Bool, favorite: Bool, glyphSockets: [String]) {
        self.id = id
        self.definition = definition
        self.itemLevel = itemLevel
        self.rarity = rarity
        self.quality = quality
        self.affixes = affixes
        self.signature = signature
        self.locked = locked
        self.favorite = favorite
        self.glyphSockets = glyphSockets
    }
}

public struct TacticSave: Codable, Sendable, Equatable {
    public var condition: String
    public var action: String
}

public struct HeroSave: Codable, Sendable, Equatable {
    public var level: Int
    public var xp: Double
    public var paragon: Int
    public var paragonXP: Double
    public var bankedGlyphPoints: Int
    public var soulCapBonus: Double
}

public struct GlyphSave: Codable, Sendable, Equatable {
    public var bankedPoints: Int
    public var learned: [String]
    public var wired: Bool
}

public struct ReliquarySave: Codable, Sendable, Equatable {
    public var weaponSignature: String?
    public var armorSignature: String?
    public var relicSignature: String?
}

public struct InventorySave: Codable, Sendable, Equatable {
    public static let bagCapacity = 40

    public var bag: [ItemSave]
    public var stash: [ItemSave]
    public var gold: Double
    public var dust: Double
    public var shards: Double
    public var embers: Double
    /// Rares since the last Unique. Missing on older schema-1 files, which start the streak over.
    public var lootPity: Int

    public init(bag: [ItemSave], stash: [ItemSave], gold: Double, dust: Double, shards: Double, embers: Double, lootPity: Int = 0) {
        self.bag = bag
        self.stash = stash
        self.gold = gold
        self.dust = dust
        self.shards = shards
        self.embers = embers
        self.lootPity = lootPity
    }

    private enum CodingKeys: String, CodingKey {
        case bag, stash, gold, dust, shards, embers, lootPity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bag = try container.decode([ItemSave].self, forKey: .bag)
        stash = try container.decode([ItemSave].self, forKey: .stash)
        gold = try container.decode(Double.self, forKey: .gold)
        dust = try container.decode(Double.self, forKey: .dust)
        shards = try container.decode(Double.self, forKey: .shards)
        embers = try container.decode(Double.self, forKey: .embers)
        lootPity = try container.decodeIfPresent(Int.self, forKey: .lootPity) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bag, forKey: .bag)
        try container.encode(stash, forKey: .stash)
        try container.encode(gold, forKey: .gold)
        try container.encode(dust, forKey: .dust)
        try container.encode(shards, forKey: .shards)
        try container.encode(embers, forKey: .embers)
        try container.encode(lootPity, forKey: .lootPity)
    }

    /// Keeps the item when the bag has room. Uniques are admitted ahead of other rarities by the caller.
    public mutating func store(_ item: ItemSave) -> Bool {
        guard bag.count < Self.bagCapacity else { return false }
        bag.append(item)
        return true
    }
}

public struct LoadoutSave: Codable, Sendable, Equatable {
    public var id: String
    public var name: String
    public var melee: String?
    public var ranged: String?
    public var armor: [String: String]
    public var relics: [String]
    public var charms: [String]
    public var tactics: [TacticSave]
}

public struct CodexSave: Codable, Sendable, Equatable {
    public var signatures: [String]
    public var glyphs: [String]
}

public struct BestiaryCardSave: Codable, Sendable, Equatable {
    public var copies: Int
    public var foil: Bool
    public var pity: Int
}

public struct HearthSave: Codable, Sendable, Equatable {
    public var tiers: [String: Int]
    public var rescued: [String]
}

public struct ExpeditionSave: Codable, Sendable, Equatable {
    public var depth: Int?
    public var startedAt: Double?
    public var meanClearSeconds: Double?
}

public struct CompanionExpeditionSave: Codable, Sendable, Equatable {
    public var wanderer: String
    public var startedAt: Double
    public var hours: Int
}

public struct InnSave: Codable, Sendable, Equatable {
    public var records: [String: Int]
    public var friendships: [String: Int]
}

public struct GameplayPrefs: Codable, Sendable, Equatable {
    public var lootRules: [String]
    public var autoEquip: Bool
}

public struct SaveGame: Codable, Sendable, Equatable {
    public static let schemaVersion = 1

    public var schemaVersion: Int
    public var biomeTableVersion: Int
    public var seasonID: String?
    public var hero: HeroSave
    public var glyphs: GlyphSave
    public var reliquary: ReliquarySave
    public var inventory: InventorySave
    public var loadouts: [LoadoutSave]
    public var codex: CodexSave
    public var bestiary: [String: BestiaryCardSave]
    public var hearth: HearthSave
    public var expeditions: ExpeditionSave
    public var companions: [CompanionExpeditionSave]
    public var inn: InnSave
    public var gameplay: GameplayPrefs
    /// Highest Depth a Delve may enter. Deep Rift clears at this Depth raise it.
    public var bestDepth: Int = 1
    /// Next seed the gate will use. Launch arguments bypass it.
    public var runSeed: Int = 1

    public static func newGame(biomeTableVersion: Int = 1) -> SaveGame {
        SaveGame(
            schemaVersion: schemaVersion,
            biomeTableVersion: biomeTableVersion,
            seasonID: nil,
            hero: HeroSave(level: 1, xp: 0, paragon: 0, paragonXP: 0, bankedGlyphPoints: 0, soulCapBonus: 0),
            glyphs: GlyphSave(bankedPoints: 0, learned: [], wired: false),
            reliquary: ReliquarySave(weaponSignature: nil, armorSignature: nil, relicSignature: nil),
            inventory: InventorySave(bag: [], stash: [], gold: 0, dust: 0, shards: 0, embers: 0),
            loadouts: [
                LoadoutSave(id: "loadout-1", name: "Loadout 1", melee: nil, ranged: nil, armor: [:], relics: [], charms: [], tactics: []),
            ],
            codex: CodexSave(signatures: [], glyphs: []),
            bestiary: [:],
            hearth: HearthSave(tiers: [:], rescued: []),
            expeditions: ExpeditionSave(depth: nil, startedAt: nil, meanClearSeconds: nil),
            companions: [],
            inn: InnSave(records: [:], friendships: [:]),
            gameplay: GameplayPrefs(lootRules: [], autoEquip: false)
        )
    }

    public func soulCap() -> Double {
        SoulRules.cap + hero.soulCapBonus
    }
}

public enum SaveError: Error, Equatable {
    case unsupportedSchema(Int)
}

public enum SaveMigrator {
    public static func load(_ data: Data) throws -> SaveGame {
        let save = try JSONDecoder().decode(SaveGame.self, from: fillingDefaults(data))
        guard save.schemaVersion == SaveGame.schemaVersion else {
            throw SaveError.unsupportedSchema(save.schemaVersion)
        }
        return save
    }

    /// Schema 1 grew bestDepth, runSeed, and hero.bankedGlyphPoints. Older files omit them.
    static func fillingDefaults(_ data: Data) -> Data {
        guard var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return data }
        if object["bestDepth"] == nil { object["bestDepth"] = 1 }
        if object["runSeed"] == nil { object["runSeed"] = 1 }
        if var hero = object["hero"] as? [String: Any] {
            if hero["bankedGlyphPoints"] == nil { hero["bankedGlyphPoints"] = 0 }
            object["hero"] = hero
        }
        return (try? JSONSerialization.data(withJSONObject: object)) ?? data
    }
}

public struct SaveStore {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func write(_ save: SaveGame) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(save)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let current = directory.appendingPathComponent("save.json")
        let first = directory.appendingPathComponent("save.1.json")
        let second = directory.appendingPathComponent("save.2.json")
        if fileManager.fileExists(atPath: first.path) {
            if fileManager.fileExists(atPath: second.path) {
                try fileManager.removeItem(at: second)
            }
            try fileManager.moveItem(at: first, to: second)
        }
        if fileManager.fileExists(atPath: current.path) {
            try fileManager.moveItem(at: current, to: first)
        }
        try data.write(to: current, options: .atomic)
    }

    public func load() throws -> SaveGame {
        let data = try Data(contentsOf: directory.appendingPathComponent("save.json"))
        return try SaveMigrator.load(data)
    }
}
