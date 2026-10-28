import Foundation

public struct RiftScope: Sendable, Equatable {
    public var riftID: String
    public var seed: UInt64
    public var depth: Int
    public var mode: String
    public var loadoutHash: String

    public init(riftID: String, seed: UInt64, depth: Int, mode: String, loadoutHash: String) {
        self.riftID = riftID
        self.seed = seed
        self.depth = depth
        self.mode = mode
        self.loadoutHash = loadoutHash
    }
}

public struct MappedEvent: Sendable, Equatable {
    public var name: String
    public var parameters: [String: String]
}

public enum GameEvent: Sendable, Equatable {
    case appOpen(launchMS: Int, isCold: Bool, offlineMinutes: Int)
    case appBackground(sessionSeconds: Int, scene: String)
    case saveWrite(bytes: Int, ms: Int, reason: String)
    case saveMigrate(from: Int, to: Int, ms: Int)
    case syncConflict(localDepth: Int, cloudDepth: Int, choice: String)
    case tutorialStep(step: String, seconds: Int)
    case riftStart(scope: RiftScope, predicted: String, modifier: String, biome: String, lanternStart: Double)
    case floorComplete(scope: RiftScope, floor: Int, seconds: Int, meterPercent: Double, kills: Int)
    case guardianSpawn(scope: RiftScope, secondsElapsed: Int, lanternPercent: Double, guardianID: String)
    case riftEnd(scope: RiftScope, result: String, seconds: Int, depthDelta: Int, kills: Int, elites: Int, lanternEnd: Double, potionsUsed: Int, dpsAverage: Double, damageTaken: Double)
    case heroDeath(scope: RiftScope, killerID: String, killerAffixes: String, hpMax: Double, lastRelic: String, tick: Int)
    case eventRoom(scope: RiftScope, eventType: String, outcome: String)
    case itemDrop(rarity: String, quality: String, slot: String, itemID: String, itemLevel: Int, source: String)
    case itemEquip(slot: String, rarity: String, scoreDeltaDamage: Double, scoreDeltaToughness: Double)
    case itemSalvage(count: Int, byRarity: String, auto: Bool)
    case craftAction(action: String, rarity: String, cost: String, attempt: Int)
    case loadoutChange(relics: String, charms: String, weapons: String, setID: String)
    case tacticsEdit(ruleCount: Int, conditionsUsed: String)
    case paragonSpend(board: String, points: Int)
    case buildingUpgrade(building: String, tier: Int, cost: String)
    case wandererRescue(wandererID: String, depth: Int)
    case expeditionStart(depth: Int, predictedRiftsPerHour: Double)
    case expeditionReturn(minutes: Int, capped: Bool, rifts: Int, uniques: Int, endedEarly: Bool)
    case depthRecord(depth: Int, hoursPlayed: Double)
    case levelUp(kind: String, level: Int)
    case achievementUnlock(achievementID: String)
    case unlockView(trigger: String)
    case unlockPurchase(result: String, priceTier: String)
    case perfRift(fpsP50: Double, fpsP5: Double, entitiesMax: Int, memoryMBPeak: Double)
    case cardDrop(cardID: String, foil: Bool, firstCopy: Bool, stars: Int, source: String)
    case settingsChange(setting: String, value: String)

    public var mapped: MappedEvent {
        switch self {
        case let .appOpen(launchMS, isCold, offlineMinutes):
            return MappedEvent(name: "app_open", parameters: [
                "launch_ms": String(launchMS), "is_cold": flag(isCold), "offline_minutes": String(offlineMinutes),
            ])
        case let .appBackground(sessionSeconds, scene):
            return MappedEvent(name: "app_background", parameters: [
                "session_seconds": String(sessionSeconds), "scene": scene,
            ])
        case let .saveWrite(bytes, ms, reason):
            return MappedEvent(name: "save_write", parameters: [
                "bytes": String(bytes), "ms": String(ms), "reason": reason,
            ])
        case let .saveMigrate(from, to, ms):
            return MappedEvent(name: "save_migrate", parameters: [
                "from_v": String(from), "to_v": String(to), "ms": String(ms),
            ])
        case let .syncConflict(localDepth, cloudDepth, choice):
            return MappedEvent(name: "sync_conflict", parameters: [
                "local_depth": String(localDepth), "cloud_depth": String(cloudDepth), "choice": choice,
            ])
        case let .tutorialStep(step, seconds):
            return MappedEvent(name: "tutorial_step", parameters: [
                "step": step, "seconds": String(seconds),
            ])
        case let .riftStart(scope, predicted, modifier, biome, lanternStart):
            return scoped("rift_start", scope, [
                "predicted": predicted, "modifier": modifier, "biome": biome, "lantern_start": String(lanternStart),
            ])
        case let .floorComplete(scope, floor, seconds, meterPercent, kills):
            return scoped("floor_complete", scope, [
                "floor": String(floor), "seconds": String(seconds), "meter_pct": String(meterPercent), "kills": String(kills),
            ])
        case let .guardianSpawn(scope, secondsElapsed, lanternPercent, guardianID):
            return scoped("guardian_spawn", scope, [
                "seconds_elapsed": String(secondsElapsed), "lantern_pct": String(lanternPercent), "guardian_id": guardianID,
            ])
        case let .riftEnd(scope, result, seconds, depthDelta, kills, elites, lanternEnd, potionsUsed, dpsAverage, damageTaken):
            return scoped("rift_end", scope, [
                "result": result,
                "seconds": String(seconds),
                "depth_delta": String(depthDelta),
                "kills": String(kills),
                "elites": String(elites),
                "lantern_end": String(lanternEnd),
                "potions_used": String(potionsUsed),
                "dps_avg": String(dpsAverage),
                "damage_taken": String(damageTaken),
            ])
        case let .heroDeath(scope, killerID, killerAffixes, hpMax, lastRelic, tick):
            return scoped("hero_death", scope, [
                "killer_id": killerID, "killer_affixes": killerAffixes, "hp_max": String(hpMax), "last_relic": lastRelic, "tick": String(tick),
            ])
        case let .eventRoom(scope, eventType, outcome):
            return scoped("event_room", scope, ["event_type": eventType, "outcome": outcome])
        case let .itemDrop(rarity, quality, slot, itemID, itemLevel, source):
            return MappedEvent(name: "item_drop", parameters: [
                "rarity": rarity, "quality": quality, "slot": slot, "item_id": itemID, "ilvl": String(itemLevel), "source": source,
            ])
        case let .itemEquip(slot, rarity, scoreDeltaDamage, scoreDeltaToughness):
            return MappedEvent(name: "item_equip", parameters: [
                "slot": slot, "rarity": rarity, "score_delta_dmg": String(scoreDeltaDamage), "score_delta_tough": String(scoreDeltaToughness),
            ])
        case let .itemSalvage(count, byRarity, auto):
            return MappedEvent(name: "item_salvage", parameters: [
                "count": String(count), "by_rarity": byRarity, "auto": flag(auto),
            ])
        case let .craftAction(action, rarity, cost, attempt):
            return MappedEvent(name: "craft_action", parameters: [
                "action": action, "rarity": rarity, "cost": cost, "attempt": String(attempt),
            ])
        case let .loadoutChange(relics, charms, weapons, setID):
            return MappedEvent(name: "loadout_change", parameters: [
                "relics": relics, "charms": charms, "weapons": weapons, "set_id": setID,
            ])
        case let .tacticsEdit(ruleCount, conditionsUsed):
            return MappedEvent(name: "tactics_edit", parameters: [
                "rule_count": String(ruleCount), "conditions_used": conditionsUsed,
            ])
        case let .paragonSpend(board, points):
            return MappedEvent(name: "paragon_spend", parameters: ["board": board, "points": String(points)])
        case let .buildingUpgrade(building, tier, cost):
            return MappedEvent(name: "building_upgrade", parameters: [
                "building": building, "tier": String(tier), "cost": cost,
            ])
        case let .wandererRescue(wandererID, depth):
            return MappedEvent(name: "wanderer_rescue", parameters: ["wanderer_id": wandererID, "depth": String(depth)])
        case let .expeditionStart(depth, predictedRiftsPerHour):
            return MappedEvent(name: "expedition_start", parameters: [
                "depth": String(depth), "predicted_rifts_per_hour": String(predictedRiftsPerHour),
            ])
        case let .expeditionReturn(minutes, capped, rifts, uniques, endedEarly):
            return MappedEvent(name: "expedition_return", parameters: [
                "minutes": String(minutes), "capped": flag(capped), "rifts": String(rifts), "uniques": String(uniques), "ended_early": flag(endedEarly),
            ])
        case let .depthRecord(depth, hoursPlayed):
            return MappedEvent(name: "depth_record", parameters: ["depth": String(depth), "hours_played": String(hoursPlayed)])
        case let .levelUp(kind, level):
            return MappedEvent(name: "level_up", parameters: ["kind": kind, "level": String(level)])
        case let .achievementUnlock(achievementID):
            return MappedEvent(name: "achievement_unlock", parameters: ["achievement_id": achievementID])
        case let .unlockView(trigger):
            return MappedEvent(name: "unlock_view", parameters: ["trigger": trigger])
        case let .unlockPurchase(result, priceTier):
            return MappedEvent(name: "unlock_purchase", parameters: ["result": result, "price_tier": priceTier])
        case let .perfRift(fpsP50, fpsP5, entitiesMax, memoryMBPeak):
            return MappedEvent(name: "perf_rift", parameters: [
                "fps_p50": String(fpsP50), "fps_p5": String(fpsP5), "entities_max": String(entitiesMax), "mem_mb_peak": String(memoryMBPeak),
            ])
        case let .cardDrop(cardID, foil, firstCopy, stars, source):
            return MappedEvent(name: "card_drop", parameters: [
                "card_id": cardID, "foil": flag(foil), "first_copy": flag(firstCopy), "stars": String(stars), "source": source,
            ])
        case let .settingsChange(setting, value):
            return MappedEvent(name: "settings_change", parameters: ["setting": setting, "value": value])
        }
    }

    public static let fixtures: [GameEvent] = {
        let scope = RiftScope(riftID: "r", seed: 1, depth: 1, mode: "delve", loadoutHash: "h")
        return [
            .appOpen(launchMS: 1, isCold: true, offlineMinutes: 0),
            .appBackground(sessionSeconds: 1, scene: "hearth"),
            .saveWrite(bytes: 1, ms: 1, reason: "rift_end"),
            .saveMigrate(from: 1, to: 1, ms: 1),
            .syncConflict(localDepth: 1, cloudDepth: 2, choice: "local"),
            .tutorialStep(step: "sword", seconds: 1),
            .riftStart(scope: scope, predicted: "fair", modifier: "none", biome: "mossy_cellars", lanternStart: 1),
            .floorComplete(scope: scope, floor: 1, seconds: 1, meterPercent: 10, kills: 1),
            .guardianSpawn(scope: scope, secondsElapsed: 1, lanternPercent: 0.5, guardianID: "g"),
            .riftEnd(scope: scope, result: "clear", seconds: 1, depthDelta: 1, kills: 1, elites: 0, lanternEnd: 0.5, potionsUsed: 0, dpsAverage: 1, damageTaken: 1),
            .heroDeath(scope: scope, killerID: "slime", killerAffixes: "", hpMax: 1, lastRelic: "", tick: 1),
            .eventRoom(scope: scope, eventType: "shrine", outcome: "taken"),
            .itemDrop(rarity: "rare", quality: "standard", slot: "melee", itemID: "", itemLevel: 11, source: "fodder"),
            .itemEquip(slot: "melee", rarity: "rare", scoreDeltaDamage: 1, scoreDeltaToughness: 0),
            .itemSalvage(count: 1, byRarity: "common:1", auto: false),
            .craftAction(action: "reroll", rarity: "rare", cost: "shards:1", attempt: 1),
            .loadoutChange(relics: "ember_flask", charms: "", weapons: "sword", setID: ""),
            .tacticsEdit(ruleCount: 3, conditionsUsed: "hp"),
            .paragonSpend(board: "core", points: 1),
            .buildingUpgrade(building: "blacksmith", tier: 1, cost: "gold:1"),
            .wandererRescue(wandererID: "smith", depth: 1),
            .expeditionStart(depth: 10, predictedRiftsPerHour: 8),
            .expeditionReturn(minutes: 60, capped: false, rifts: 4, uniques: 0, endedEarly: false),
            .depthRecord(depth: 2, hoursPlayed: 0.1),
            .levelUp(kind: "hero", level: 2),
            .achievementUnlock(achievementID: "hd.depth.100"),
            .unlockView(trigger: "depth_25"),
            .unlockPurchase(result: "success", priceTier: "7.99"),
            .perfRift(fpsP50: 60, fpsP5: 60, entitiesMax: 10, memoryMBPeak: 100),
            .cardDrop(cardID: "cellar_slime", foil: false, firstCopy: true, stars: 1, source: "kill"),
            .settingsChange(setting: "music", value: "off"),
        ]
    }()
}

private func flag(_ value: Bool) -> String {
    value ? "true" : "false"
}

private func scoped(_ name: String, _ scope: RiftScope, _ extra: [String: String]) -> MappedEvent {
    var parameters = extra
    parameters["rift_id"] = scope.riftID
    parameters["rift_seed"] = String(scope.seed)
    parameters["depth"] = String(scope.depth)
    parameters["mode"] = scope.mode
    parameters["loadout_hash"] = scope.loadoutHash
    return MappedEvent(name: name, parameters: parameters)
}

public protocol TelemetrySink: Sendable {
    func record(name: String, parameters: [String: String])
}

public enum TelemetryError: Error, Equatable {
    case invalidEvent(String)
}

public struct TelemetryRouter: Sendable {
    public var sessionID: String
    private let sinks: [any TelemetrySink]

    public init(sessionID: String, sinks: [any TelemetrySink]) {
        self.sessionID = sessionID
        self.sinks = sinks
    }

    public func payload(for event: GameEvent) -> [String: String] {
        var parameters = event.mapped.parameters
        parameters["session_id"] = sessionID
        return parameters
    }

    public func emit(_ event: GameEvent) throws {
        let name = event.mapped.name
        let parameters = payload(for: event)
        if name.count > 40 || name.isEmpty || parameters.count > 15
            || name.hasPrefix("firebase_") || name.hasPrefix("google_") || name.hasPrefix("ga_") {
            throw TelemetryError.invalidEvent(name)
        }
        for sink in sinks {
            sink.record(name: name, parameters: parameters)
        }
    }
}

public final class RecordingSink: TelemetrySink, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [(name: String, parameters: [String: String])] = []

    public init() {}

    public func record(name: String, parameters: [String: String]) {
        lock.lock()
        stored.append((name, parameters))
        lock.unlock()
    }

    public func events() -> [(name: String, parameters: [String: String])] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}
