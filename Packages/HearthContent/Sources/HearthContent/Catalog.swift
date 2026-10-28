import Foundation
import HearthCore

public struct ContentError: Error, Equatable, Sendable {
    public var domain: String
    public var code: String
    public var message: String

    public static func missing(_ message: String) -> ContentError {
        ContentError(domain: "hd.content", code: "missing_definition", message: message)
    }

    public static func badReference(_ message: String) -> ContentError {
        ContentError(domain: "hd.content", code: "bad_reference", message: message)
    }
}

public struct ContentValidation: Error, Equatable, Sendable {
    public var issues: [ContentError]
}

public struct AffixFile: Codable, Sendable, Equatable {
    public var affixes: [EliteAffixDefinition]
    public var bans: [[String]]
}

public struct ContentCatalog: Sendable {
    public var tuning: Tuning
    public var weapons: [WeaponDefinition]
    public var relics: [RelicDefinition]
    public var charms: [CharmDefinition]
    public var uniques: [UniqueDefinition]
    public var sets: [SetDefinition]
    public var families: [FamilyDefinition]
    public var mobs: [MobDefinition]
    public var guardians: [GuardianDefinition]
    public var wardens: [WardenDefinition]
    public var wanderers: [WandererDefinition]
    public var modifiers: [RiftModifierDefinition]
    public var biomes: BiomeTable
    public var buildings: [BuildingDefinition]
    public var affixes: [EliteAffixDefinition]
    public var affixBans: [[String]]
    public var events: [RiftEventDefinition]
    public var loadouts: [LoadoutFixture]
    public var tactics: [TacticPreset]
    public var rooms: [RoomTemplate]
    public var slice: SliceDefinition
    /// FNV-64 of every content file, in name order. Recordings carry it so a replay can tell content drifted.
    public var version: String

    public static func load(from directory: URL) throws -> ContentCatalog {
        let decoder = JSONDecoder()
        var hash = FNV64()
        func data(_ name: String) throws -> Data {
            let url = directory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ContentValidation(issues: [.missing("Missing \(name)")])
            }
            return try Data(contentsOf: url)
        }
        func decode<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
            let bytes = try data(name)
            for byte in name.utf8 { hash.add(byte) }
            for byte in bytes { hash.add(byte) }
            do {
                return try decoder.decode(type, from: bytes)
            } catch {
                throw ContentValidation(issues: [.badReference("\(name) does not decode: \(error)")])
            }
        }
        let roomNames = try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("rooms").path)
            .filter { $0.hasSuffix(".json") }
            .sorted()
        let affixFile = try decode(AffixFile.self, "affixes.json")
        var catalog = ContentCatalog(
            tuning: try decode(Tuning.self, "tuning.json"),
            weapons: try decode([WeaponDefinition].self, "weapons.json"),
            relics: try decode([RelicDefinition].self, "relics.json"),
            charms: try decode([CharmDefinition].self, "charms.json"),
            uniques: try decode([UniqueDefinition].self, "uniques.json"),
            sets: try decode([SetDefinition].self, "sets.json"),
            families: try decode([FamilyDefinition].self, "families.json"),
            mobs: try decode([MobDefinition].self, "mobs.json"),
            guardians: try decode([GuardianDefinition].self, "guardians.json"),
            wardens: try decode([WardenDefinition].self, "wardens.json"),
            wanderers: try decode([WandererDefinition].self, "wanderers.json"),
            modifiers: try decode([RiftModifierDefinition].self, "modifiers.json"),
            biomes: try decode(BiomeTable.self, "biomes.json"),
            buildings: try decode([BuildingDefinition].self, "buildings.json"),
            affixes: affixFile.affixes,
            affixBans: affixFile.bans,
            events: try decode([RiftEventDefinition].self, "events.json"),
            loadouts: try decode([LoadoutFixture].self, "loadouts.json"),
            tactics: try decode([TacticPreset].self, "tactics.json"),
            rooms: try roomNames.map { try decode(RoomTemplate.self, "rooms/\($0)") },
            slice: try decode(SliceDefinition.self, "m0.json"),
            version: ""
        )
        catalog.version = String(hash.value, radix: 16)
        return catalog
    }

    // MARK: Room setups

    /// The one-room M0 fight, resolved from `m0.json`.
    public func m0Setup() throws -> RoomSetup {
        try setup(
            room: slice.room, depth: slice.depth, melee: slice.melee, ranged: slice.ranged, relics: slice.relics,
            tactics: slice.tactics, unique: nil, fodder: slice.fodder, brute: slice.brute, shooter: slice.shooter
        )
    }

    /// A reference loadout dropped into the M0 room at any Depth, for the CLI balance smoke.
    public func setup(loadout id: String, depth: Int) throws -> RoomSetup {
        guard let loadout = loadouts.first(where: { $0.id == id }) else { throw ContentError.missing("loadout \(id)") }
        return try setup(
            room: slice.room, depth: depth, melee: loadout.melee, ranged: loadout.ranged, relics: loadout.relics,
            tactics: loadout.tactics, unique: loadout.uniqueWeapon, fodder: slice.fodder, brute: slice.brute, shooter: slice.shooter
        )
    }

    /// The M0 room with one Relic swapped in and a single "fire when ready" rule, for the per-Relic smoke.
    public func setup(relic id: String, depth: Int) throws -> RoomSetup {
        guard let relic = relics.first(where: { $0.id == id }) else { throw ContentError.missing("relic \(id)") }
        var base = try m0Setup()
        base.depth = depth
        base.relics = [relic]
        base.tactics = [TacticRule(TacticCondition(kind: "enemiesWithin", count: 1, tiles: 4), TacticAction(kind: "relic", relic: id))]
        return base
    }

    public func setup(
        room roomID: String, depth: Int, melee: String, ranged: String, relics relicIDs: [String], tactics tacticsID: String,
        unique: String?, fodder: String, brute: String, shooter: String
    ) throws -> RoomSetup {
        guard let room = rooms.first(where: { $0.id == roomID }) else { throw ContentError.missing("room \(roomID)") }
        guard let melee = weapons.first(where: { $0.id == melee }) else { throw ContentError.missing("weapon \(melee)") }
        guard let ranged = weapons.first(where: { $0.id == ranged }) else { throw ContentError.missing("weapon \(ranged)") }
        guard let preset = tactics.first(where: { $0.id == tacticsID }) else { throw ContentError.missing("tactics \(tacticsID)") }
        let chosen = try relicIDs.map { id in
            guard let relic = relics.first(where: { $0.id == id }) else { throw ContentError.missing("relic \(id)") }
            return relic
        }
        func mob(_ id: String) throws -> MobDefinition {
            guard let mob = mobs.first(where: { $0.id == id }) else { throw ContentError.missing("mob \(id)") }
            return mob
        }
        var signatures: [SignatureSpec] = []
        if let unique {
            guard let item = uniques.first(where: { $0.id == unique }) else { throw ContentError.missing("unique \(unique)") }
            signatures.append(resolved(item.effect))
        }
        return RoomSetup(
            room: room, tuning: tuning, depth: depth, melee: melee, ranged: ranged, relics: chosen, tactics: preset.rules,
            signatures: signatures, fodder: try mob(fodder), brute: try mob(brute), shooter: try mob(shooter)
        )
    }

    /// A signature with `enqueues` turned into that Relic's opcodes, so the sim only ever runs opcodes.
    public func resolved(_ effect: SignatureSpec) -> SignatureSpec {
        var effect = effect
        if let id = effect.enqueues, let relic = relics.first(where: { $0.id == id }) {
            effect.opcodes = (effect.opcodes ?? []) + relic.opcodes
        }
        return effect
    }

    // MARK: Bestiary

    /// One card per mob, Guardian, and Warden. Generated, never hand-written, so cards cannot drift from creatures.
    public func bestiary() -> [BestiaryCard] {
        let band = Dictionary(uniqueKeysWithValues: (biomes.segments.first?.order ?? []).enumerated().map { ($1, $0) })
        var cards: [BestiaryCard] = []
        for mob in mobs {
            let tier = band[mob.biome] ?? 0
            cards.append(BestiaryCard(id: "card.\(mob.id)", creature: mob.id, name: mob.name, kind: .mob, family: mob.family,
                                      role: mob.role, biome: mob.biome, depthBand: tier + 1, edges: BestiaryCard.edges(role: mob.role, tier: tier)))
        }
        for guardian in guardians {
            let tier = band[guardian.biome] ?? 0
            cards.append(BestiaryCard(id: "card.\(guardian.id)", creature: guardian.id, name: guardian.name, kind: .guardian,
                                      family: guardian.family, role: "guardian", biome: guardian.biome, depthBand: tier + 1,
                                      edges: BestiaryCard.edges(role: "guardian", tier: tier)))
        }
        for warden in wardens {
            cards.append(BestiaryCard(id: "card.\(warden.id)", creature: warden.id, name: warden.name, kind: .warden, family: nil,
                                      role: "warden", biome: nil, depthBand: warden.depth / 10,
                                      edges: BestiaryCard.edges(role: "warden", tier: warden.depth / 50)))
        }
        return cards
    }

    // MARK: Validation

    /// Every sprite contract id the catalog references. The CLI checks these against `docs/art/kenney-map.json`.
    public func spriteIDs() -> [String] {
        var ids = weapons.compactMap(\.sprite) + weapons.compactMap(\.projectile) + mobs.map(\.sprite) + guardians.map(\.sprite)
        ids += wardens.map(\.sprite) + wanderers.map(\.sprite) + buildings.map(\.sprite)
        ids += relics.map { "icon.relic.\($0.id)" } + charms.map { "icon.charm.\($0.id)" }
        for kind in summonKinds() where mobs.contains(where: { $0.id == kind }) == false {
            ids.append("summon.\(kind)")
        }
        return Array(Set(ids).subtracting(["fx.bolt.hero"])).sorted()
    }

    public func validate(artEntries: Set<String>? = nil) throws {
        var issues: [ContentError] = []
        let weaponIDs = collect(weapons.map(\.id), "weapon", &issues)
        let relicIDs = collect(relics.map(\.id), "relic", &issues)
        let charmIDs = collect(charms.map(\.id), "charm", &issues)
        let uniqueIDs = collect(uniques.map(\.id), "unique", &issues)
        _ = collect(sets.map(\.id), "set", &issues)
        _ = collect(sets.flatMap(\.pieces).map(\.id) + uniques.map(\.id), "item", &issues)
        let familyIDs = collect(families.map(\.id), "family", &issues)
        let mobIDs = collect(mobs.map(\.id), "mob", &issues)
        _ = collect(guardians.map(\.id) + wardens.map(\.id) + mobs.map(\.id), "creature", &issues)
        let wandererIDs = collect(wanderers.map(\.id), "wanderer", &issues)
        _ = collect(modifiers.map(\.id), "modifier", &issues)
        let affixIDs = collect(affixes.map(\.id), "affix", &issues)
        let buildingIDs = collect(buildings.map(\.id), "building", &issues)
        _ = collect(events.map(\.id), "event", &issues)
        _ = collect(loadouts.map(\.id), "loadout", &issues)
        let tacticIDs = collect(tactics.map(\.id), "tactics", &issues)
        let roomIDs = collect(rooms.map(\.id), "room", &issues)

        let biomeIDs = Set(biomes.segments.flatMap(\.order))
        if biomes.segments.isEmpty {
            issues.append(.badReference("Biome table has no segments"))
        }
        for segment in biomes.segments where segment.bandWidth <= 0 || segment.order.isEmpty {
            issues.append(.badReference("Biome segment \(segment.id) is empty"))
        }

        for weapon in weapons where EffectCatalog.innate.contains(weapon.innate.kind) == false {
            issues.append(.badReference("Weapon \(weapon.id) has unknown innate \(weapon.innate.kind)"))
        }

        for relic in relics {
            let elements = relic.tags.filter { EffectCatalog.relicElements.contains($0) }
            if elements.count != 1 {
                issues.append(.badReference("Relic \(relic.id) needs exactly one element tag"))
            }
            if relic.souls < 0 || relic.cooldown <= 0 {
                issues.append(.badReference("Relic \(relic.id) needs a cooldown and a Soul cost"))
            }
            if relic.opcodes.isEmpty {
                issues.append(.missing("Relic \(relic.id) has no opcodes"))
            }
            check(relic.opcodes, "Relic \(relic.id)", &issues)
        }
        for element in EffectCatalog.relicElements.sorted() {
            let tagged = relics.filter { $0.tags.contains(element) }
            let roles = Set(tagged.flatMap { Self.roles(of: $0.opcodes) })
            for role in ["damage", "control", "defense"] where roles.contains(role) == false {
                issues.append(.missing("No \(element) Relic offers \(role)"))
            }
        }

        for charm in charms {
            if charm.stats.isEmpty {
                issues.append(.missing("Charm \(charm.id) has no stats"))
            }
            for stat in charm.stats {
                checkStat(stat.stat, "Charm \(charm.id)", &issues)
                if stat.ranks?.count != 3 {
                    issues.append(.badReference("Charm \(charm.id) needs three ranks for \(stat.stat)"))
                }
            }
        }

        for item in uniques {
            let label = "Unique \(item.id)"
            if EffectCatalog.slots.contains(item.slot) == false {
                issues.append(.badReference("\(label) has unknown slot \(item.slot)"))
            }
            if let weaponType = item.weaponType {
                if let weapon = weapons.first(where: { $0.id == weaponType }) {
                    if weapon.kind.rawValue != item.slot {
                        issues.append(.badReference("\(label) is a \(item.slot) Unique on a \(weapon.kind.rawValue) weapon"))
                    }
                } else {
                    issues.append(.missing("\(label) references missing weapon \(weaponType)"))
                }
            } else if item.slot == "melee" || item.slot == "ranged" {
                issues.append(.missing("\(label) needs a weapon type"))
            }
            if item.slot == "relic" {
                if let base = item.baseRelic {
                    if relicIDs.contains(base) == false { issues.append(.missing("\(label) references missing relic \(base)")) }
                } else {
                    issues.append(.missing("\(label) needs a base Relic"))
                }
            }
            check(item.effect, label, relicIDs, &issues)
        }

        for set in sets {
            let slots = set.pieces.map(\.slot).sorted()
            if slots != ["boots", "chest", "helm", "legs"] {
                issues.append(.badReference("Set \(set.id) needs one helm, chest, legs, and boots"))
            }
            for stat in set.bonus2Stats { checkStat(stat.stat, "Set \(set.id)", &issues) }
            check(set.bonus4Effect, "Set \(set.id)", relicIDs, &issues)
        }

        for family in families {
            if biomeIDs.contains(family.biome) == false {
                issues.append(.missing("Family \(family.id) references missing biome \(family.biome)"))
            }
            let roles = Set(mobs.filter { $0.family == family.id }.map(\.role))
            if roles.count < 4 {
                issues.append(.badReference("Family \(family.id) covers \(roles.count) roles; it needs 4"))
            }
        }
        for mob in mobs {
            if EffectCatalog.roles.contains(mob.role) == false {
                issues.append(.badReference("Mob \(mob.id) has unknown role \(mob.role)"))
            }
            if biomeIDs.contains(mob.biome) == false {
                issues.append(.missing("Mob \(mob.id) references missing biome \(mob.biome)"))
            }
            if familyIDs.contains(mob.family) == false {
                issues.append(.missing("Mob \(mob.id) references missing family \(mob.family)"))
            } else if let family = families.first(where: { $0.id == mob.family }), family.biome != mob.biome {
                issues.append(.badReference("Mob \(mob.id) lives in \(mob.biome) but its family is in \(family.biome)"))
            }
            if mob.sprite.isEmpty {
                issues.append(.missing("Mob \(mob.id) has no sprite"))
            }
            if mob.sprite.hasPrefix("wanderer.") {
                issues.append(.badReference("Mob \(mob.id) uses a Wanderer sprite"))
            }
            if mob.role == "brute" || mob.role == "caster", (mob.telegraphSeconds ?? 0) < 0.6 {
                issues.append(.badReference("\(mob.role.capitalized) \(mob.id) needs a telegraph of at least 0.6s"))
            }
        }

        for guardian in guardians {
            let label = "Guardian \(guardian.id)"
            if biomeIDs.contains(guardian.biome) == false {
                issues.append(.missing("\(label) references missing biome \(guardian.biome)"))
            }
            if let family = families.first(where: { $0.id == guardian.family }) {
                if family.biome != guardian.biome { issues.append(.badReference("\(label) is not in its family's biome")) }
            } else {
                issues.append(.missing("\(label) references missing family \(guardian.family)"))
            }
            if (2...3).contains(guardian.mechanics.count) == false {
                issues.append(.badReference("\(label) needs 2–3 mechanics"))
            }
            checkBoss(guardian.hpMultiplier, guardian.enrageAt, guardian.mechanics, label, mobIDs, &issues)
        }
        for warden in wardens {
            let label = "Warden \(warden.id)"
            if warden.depth <= 0 || warden.depth % 50 != 0 {
                issues.append(.badReference("\(label) must sit on a multiple of 50"))
            }
            if warden.phases.count < 2 {
                issues.append(.badReference("\(label) needs an extra phase"))
            }
            checkBoss(warden.hpMultiplier, warden.enrageAt, warden.phases.flatMap { $0 }, label, mobIDs, &issues)
        }

        for wanderer in wanderers {
            if buildingIDs.contains(wanderer.building) == false {
                issues.append(.missing("Wanderer \(wanderer.id) references missing building \(wanderer.building)"))
            }
            if wanderer.intro.count != 3 {
                issues.append(.badReference("Wanderer \(wanderer.id) needs a three-step friendship thread"))
            }
        }
        for building in buildings {
            if wandererIDs.contains(building.wanderer) == false {
                issues.append(.missing("Building \(building.id) references missing wanderer \(building.wanderer)"))
            } else if let wanderer = wanderers.first(where: { $0.id == building.wanderer }), wanderer.building != building.id {
                issues.append(.badReference("Building \(building.id) and Wanderer \(wanderer.id) disagree"))
            }
        }

        for modifier in modifiers {
            for stat in modifier.stats { checkStat(stat.stat, "Modifier \(modifier.id)", &issues) }
        }

        for affix in affixes {
            if EffectCatalog.shapes.contains(affix.shape) == false {
                issues.append(.badReference("Affix \(affix.id) has unknown shape \(affix.shape)"))
            }
            if affix.color.count != 7 || affix.color.hasPrefix("#") == false {
                issues.append(.badReference("Affix \(affix.id) color must be #rrggbb"))
            }
        }
        let looks = affixes.map { "\($0.color)/\($0.shape)" }
        if Set(looks).count != looks.count {
            issues.append(.badReference("Two affixes share a color and shape"))
        }
        for ban in affixBans {
            if ban.count != 2 {
                issues.append(.badReference("Affix ban \(ban) must name two affixes"))
                continue
            }
            for id in ban where affixIDs.contains(id) == false {
                issues.append(.missing("Affix ban references missing affix \(id)"))
            }
        }
        for event in events where event.weight <= 0 {
            issues.append(.badReference("Event \(event.id) has no weight"))
        }

        for preset in tactics {
            for rule in preset.rules {
                if EffectCatalog.conditions.contains(rule.condition.kind) == false {
                    issues.append(.badReference("Tactics \(preset.id) has unknown condition \(rule.condition.kind)"))
                }
                if EffectCatalog.actions.contains(rule.action.kind) == false {
                    issues.append(.badReference("Tactics \(preset.id) has unknown action \(rule.action.kind)"))
                }
                if rule.action.kind == "relic", relicIDs.contains(rule.action.relic ?? "") == false {
                    issues.append(.missing("Tactics \(preset.id) fires missing relic \(rule.action.relic ?? "nil")"))
                }
            }
        }

        for loadout in loadouts {
            for weapon in [loadout.melee, loadout.ranged] where weaponIDs.contains(weapon) == false {
                issues.append(.missing("Loadout \(loadout.id) references missing weapon \(weapon)"))
            }
            for relic in loadout.relics where relicIDs.contains(relic) == false {
                issues.append(.missing("Loadout \(loadout.id) references missing relic \(relic)"))
            }
            for charm in loadout.charms where charmIDs.contains(charm) == false {
                issues.append(.missing("Loadout \(loadout.id) references missing charm \(charm)"))
            }
            if let unique = loadout.uniqueWeapon, uniqueIDs.contains(unique) == false {
                issues.append(.missing("Loadout \(loadout.id) references missing unique \(unique)"))
            }
            if tacticIDs.contains(loadout.tactics) == false {
                issues.append(.missing("Loadout \(loadout.id) references missing tactics \(loadout.tactics)"))
            } else if let preset = tactics.first(where: { $0.id == loadout.tactics }) {
                for rule in preset.rules where rule.action.kind == "relic" && loadout.relics.contains(rule.action.relic ?? "") == false {
                    issues.append(.badReference("Loadout \(loadout.id) Tactics fire \(rule.action.relic ?? "") it does not carry"))
                }
            }
        }

        for room in rooms {
            let cells = room.width * room.height
            if room.tiles.count != cells || room.objects.count != cells || room.collision.count != cells {
                issues.append(.badReference("Room \(room.id) layers do not match \(room.width)×\(room.height)"))
                continue
            }
            if room.collision[room.hero.y * room.width + room.hero.x] != 0 {
                issues.append(.badReference("Room \(room.id) puts the hero in a wall"))
            }
            if room.spawns.isEmpty {
                issues.append(.missing("Room \(room.id) has no spawn zones"))
            }
            for rect in room.spawns where rect.x < 0 || rect.y < 0 || rect.x + rect.w > room.width || rect.y + rect.h > room.height {
                issues.append(.badReference("Room \(room.id) has a spawn zone outside the room"))
            }
        }

        if roomIDs.contains(slice.room) == false { issues.append(.missing("M0 slice references missing room \(slice.room)")) }
        if tacticIDs.contains(slice.tactics) == false { issues.append(.missing("M0 slice references missing tactics \(slice.tactics)")) }
        for weapon in [slice.melee, slice.ranged] where weaponIDs.contains(weapon) == false {
            issues.append(.missing("M0 slice references missing weapon \(weapon)"))
        }
        for relic in slice.relics where relicIDs.contains(relic) == false {
            issues.append(.missing("M0 slice references missing relic \(relic)"))
        }
        for mob in [slice.fodder, slice.brute, slice.shooter] where mobIDs.contains(mob) == false {
            issues.append(.missing("M0 slice references missing mob \(mob)"))
        }

        if let artEntries {
            for id in spriteIDs() where artEntries.contains(id) == false {
                issues.append(.missing("Sprite \(id) is not in docs/art/kenney-map.json"))
            }
        }

        if issues.isEmpty == false {
            throw ContentValidation(issues: issues)
        }
    }

    public func affixSetIsLegal(_ ids: [String]) -> Bool {
        let present = Set(ids)
        for ban in affixBans where Set(ban).isSubset(of: present) {
            return false
        }
        return true
    }

    /// What a Relic offers, from its opcodes: damage, control, or defense.
    public static func roles(of opcodes: [OpcodeSpec]) -> Set<String> {
        var roles = Set<String>()
        for opcode in opcodes {
            switch opcode.op {
            case "damage", "zone":
                roles.insert("damage")
            case "root", "stun", "taunt":
                roles.insert("control")
            case "shield", "heal", "dash":
                roles.insert("defense")
            case "summon":
                roles.insert((opcode.coefficient ?? 0) > 0 ? "damage" : "defense")
                if opcode.taunts == true { roles.insert("control") }
            default:
                break
            }
        }
        return roles
    }

    static let requiredFields: [String: [String]] = [
        "damage": ["coefficient", "radius"], "zone": ["coefficient", "radius", "duration"], "shield": ["fraction", "duration"],
        "heal": ["fraction", "duration"], "root": ["radius", "duration"], "dash": ["tiles"],
        "summon": ["kind", "duration", "coefficient"], "taunt": ["radius", "duration"], "stun": ["radius", "duration"],
    ]

    private func summonKinds() -> [String] {
        var opcodes: [OpcodeSpec] = relics.flatMap(\.opcodes)
        opcodes += uniques.flatMap { $0.effect.opcodes ?? [] }
        opcodes += sets.flatMap { $0.bonus4Effect.opcodes ?? [] }
        let mechanics: [MechanicSpec] = guardians.flatMap(\.mechanics) + wardens.flatMap { $0.phases.flatMap { $0 } }
        opcodes += mechanics.flatMap(\.opcodes)
        return opcodes.filter { $0.op == "summon" }.compactMap { $0.kind }
    }

    private func check(_ opcodes: [OpcodeSpec], _ label: String, _ issues: inout [ContentError]) {
        for opcode in opcodes {
            if EffectCatalog.opcodes.contains(opcode.op) == false {
                issues.append(.badReference("\(label) has unknown opcode \(opcode.op)"))
                continue
            }
            if let element = opcode.element, EffectCatalog.elements.contains(element) == false {
                issues.append(.badReference("\(label) has unknown element \(element)"))
            }
            let fields: [String: Bool] = [
                "coefficient": opcode.coefficient != nil, "radius": opcode.radius != nil, "duration": opcode.duration != nil,
                "fraction": opcode.fraction != nil, "tiles": opcode.tiles != nil, "kind": opcode.kind != nil,
            ]
            for field in Self.requiredFields[opcode.op, default: []] where fields[field] != true {
                issues.append(.badReference("\(label) \(opcode.op) is missing \(field)"))
            }
        }
    }

    private func check(_ effect: SignatureSpec, _ label: String, _ relicIDs: Set<String>, _ issues: inout [ContentError]) {
        if EffectCatalog.hooks.contains(effect.hook) == false {
            issues.append(.badReference("\(label) has unknown hook \(effect.hook)"))
        }
        if let enqueues = effect.enqueues, relicIDs.contains(enqueues) == false {
            issues.append(.missing("\(label) enqueues missing relic \(enqueues)"))
        }
        if effect.enqueues == nil, (effect.opcodes ?? []).isEmpty, (effect.stats ?? []).isEmpty {
            issues.append(.missing("\(label) signature does nothing"))
        }
        if let chance = effect.chance, chance <= 0 || chance > 1 {
            issues.append(.badReference("\(label) chance must be in (0, 1]"))
        }
        check(effect.opcodes ?? [], label, &issues)
        for stat in effect.stats ?? [] { checkStat(stat.stat, label, &issues) }
    }

    private func checkBoss(_ hp: Double, _ enrage: Double, _ mechanics: [MechanicSpec], _ label: String, _ mobIDs: Set<String>, _ issues: inout [ContentError]) {
        if hp <= 0 || enrage <= 0 || enrage >= 1 {
            issues.append(.badReference("\(label) needs an HP multiple and an enrage threshold"))
        }
        for mechanic in mechanics {
            if mechanic.telegraphSeconds < 0.6 {
                issues.append(.badReference("\(label) \(mechanic.id) telegraph is under 0.6s"))
            }
            if EffectCatalog.shapes.contains(mechanic.shape) == false {
                issues.append(.badReference("\(label) \(mechanic.id) has unknown shape \(mechanic.shape)"))
            }
            check(mechanic.opcodes, "\(label) \(mechanic.id)", &issues)
            for opcode in mechanic.opcodes where opcode.op == "summon" && mobIDs.contains(opcode.kind ?? "") == false {
                issues.append(.missing("\(label) \(mechanic.id) summons missing mob \(opcode.kind ?? "nil")"))
            }
        }
    }

    private func checkStat(_ stat: String, _ label: String, _ issues: inout [ContentError]) {
        if EffectCatalog.stats.contains(stat) == false {
            issues.append(.badReference("\(label) has unknown stat \(stat)"))
        }
    }

    private func collect(_ ids: [String], _ label: String, _ issues: inout [ContentError]) -> Set<String> {
        var seen = Set<String>()
        for id in ids {
            if seen.insert(id).inserted == false {
                issues.append(.badReference("Duplicate \(label) id \(id)"))
            }
        }
        return seen
    }
}

public struct BestiaryCard: Sendable, Equatable, Codable {
    public enum Kind: String, Sendable, Codable {
        case mob
        case guardian
        case warden
    }

    public var id: String
    public var creature: String
    public var name: String
    public var kind: Kind
    public var family: String?
    public var role: String
    public var biome: String?
    public var depthBand: Int
    /// Top, right, bottom, left, for the Inn card game.
    public var edges: [Int]

    static func edges(role: String, tier: Int) -> [Int] {
        let base: [Int] = switch role {
        case "fodder": [3, 2, 3, 2]
        case "swarmer": [2, 2, 2, 2]
        case "brute": [6, 2, 4, 2]
        case "ranged": [2, 5, 2, 3]
        case "caster": [4, 3, 1, 4]
        case "guardian": [6, 5, 6, 5]
        default: [7, 7, 7, 7]
        }
        return base.map { min(9, $0 + tier / 2) }
    }
}
