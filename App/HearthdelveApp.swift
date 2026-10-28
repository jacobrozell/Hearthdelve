import SpriteKit
import SwiftUI
import UIKit
import HearthContent
import HearthCore
import HearthPersistence
import HearthRender
import HearthUI

@main
struct HearthdelveApp: App {
    init() {
        HearthFont.register()
    }

    var body: some Scene {
        WindowGroup {
            RiftHost()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

enum HearthPlace {
    case village
    case bag
    case gate
    case smith
    case cottage
    case rift
}

struct GateForm: Equatable {
    var depth: Int
    var bestDepth: Int
    var deepRift: Bool
    var biome: String
    var band: String
    var blocked: Bool
    var mossyNote: Bool
}

/// Owns the sim and feeds the scene at 20 Hz. At 2× and 4× each wall tick runs 2 or 4 sim ticks.
@MainActor
@Observable
final class RiftDriver {
    let scene: RiftScene
    var hud = RoomHUDState()
    var note: String?

    private var setup: RoomSetup
    private let contentVersion: String
    private var seed: UInt64
    private var sim: RiftActor
    private var speed = SimSpeed.x1
    private var paused = false
    private var loop: Task<Void, Never>?
    private var fellWall: ContinuousClock.Instant?
    private var savedThisRun = false
    private var tacticUntil: UInt64 = 0
    private var mode: RiftMode
    private var jumpIn = false
    private var useSavedDepth = false
    var place: HearthPlace = .village
    var frontier: Int { max(1, save.bestDepth) }
    private var chosenDepth = 1
    private var deepRift = false
    private let guardian: GuardianDefinition
    private var roomsByID: [String: RoomTemplate] = [:]
    private var shownRoom = ""
    private var catalog: ContentCatalog?
    private var base: RoomSetup
    private var save: SaveGame
    private let store: SaveStore
    private var acceptedLoot = false
    let village = VillageScene(size: CGSize(width: 390, height: 844))
    var hamlet = VillageHamlet.make()
    var glance = CGPoint.zero
    var panCursor = CGSize.zero
    var pendingSalvage: String?
    var cottageName = ""
    var cottageDepth = 0

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        store = SaveStore(directory: documents.appendingPathComponent("save", isDirectory: true))
        save = (try? store.load()) ?? SaveGame.newGame()
        let content = Bundle.main.url(forResource: "Content", withExtension: nil)
        var loaded: (RoomSetup, String, GuardianDefinition, [RoomTemplate])?
        var problem: String?
        if let content {
            do {
                let catalog = try ContentCatalog.load(from: content)
                #if DEBUG
                try catalog.validate()
                #endif
                self.catalog = catalog
                let boss = catalog.guardians.first { $0.id == "old_lintel" } ?? GuardianCatalog.oldLintel()
                loaded = (try catalog.m0Setup(), catalog.version, boss, catalog.mossyRooms())
            } catch {
                problem = "Content failed to load; using the built-in cellar. \(error)"
            }
        }
        let launchSeed = UserDefaults.standard.integer(forKey: "seed")
        let jumping = launchSeed > 0
        let first: UInt64 = jumping ? UInt64(launchSeed) : 1
        let depthArg = UserDefaults.standard.integer(forKey: "depth")
        let startingMode: RiftMode = UserDefaults.standard.string(forKey: "mode") == "deep" ? .deepRift : .delve
        guardian = loaded?.2 ?? GuardianCatalog.oldLintel()
        var bare = loaded?.0 ?? CellarFight.setup()
        if depthArg > 0 { bare.depth = depthArg }
        let mossy = loaded?.3 ?? []
        var rooms = Dictionary(uniqueKeysWithValues: mossy.map { ($0.id, $0) })
        rooms[bare.room.id] = bare.room
        bare.rift = RiftConfig(mode: startingMode, floors: RiftFloors.count(for: first), guardian: guardian, templates: mossy)
        base = bare
        contentVersion = loaded?.1 ?? "fixture"
        note = problem
        seed = first
        setup = bare
        sim = RiftActor(seed: first, setup: bare)
        scene = RiftScene(size: CGSize(width: 390, height: 844))
        roomsByID = rooms
        mode = startingMode
        jumpIn = jumping
        let run = prepared(bare, seed: first)
        setup = run
        sim = RiftActor(seed: first, setup: run)
        scene.load(room: run.room)
        shownRoom = run.room.id
        place = jumping ? .rift : .village
        chosenDepth = max(1, depthArg > 0 ? depthArg : save.bestDepth)
        hud.homeTitle = jumping ? "New run" : "Village"
        hud.leaveTitle = jumping ? "New run" : "Leave"
        hamlet = builtHamlet()
        village.show(hamlet)
        glance = village.cameraPoint
    }

    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            await self?.run()
        }
    }

    private func run() async {
        let clock = ContinuousClock()
        var deadline = clock.now
        while Task.isCancelled == false {
            deadline += .milliseconds(50)
            let snapshot = await sim.advance(ticks: paused ? 1 : speed.rawValue)
            show(snapshot)
            if clock.now > deadline + .milliseconds(250) {
                deadline = clock.now
            }
            try? await clock.sleep(until: deadline)
        }
    }

    private func show(_ snapshot: SimSnapshot) {
        guard place == .rift else { return }
        if snapshot.roomID.isEmpty == false, snapshot.roomID != shownRoom, let room = roomsByID[snapshot.roomID] {
            scene.load(room: room)
            shownRoom = snapshot.roomID
        }
        scene.push(snapshot, tickSeconds: 0.05)
        for event in snapshot.events {
            switch event {
            case .relic(let slot, let rule):
                let name = setup.relics.indices.contains(slot) ? setup.relics[slot].name : "Relic"
                flash(rule.map { "Tactic \($0 + 1): \(describe(setup.tactics[$0].condition)) → \(name)" } ?? "You: \(name)", at: snapshot.tick)
            case .potion(let rule):
                flash(rule.map { "Tactic \($0 + 1): \(describe(setup.tactics[$0].condition)) → Potion" } ?? "You: Potion", at: snapshot.tick)
            default:
                break
            }
        }
        if snapshot.tick >= tacticUntil { hud.tactic = nil }
        hud.hp = snapshot.heroHP
        hud.maxHP = snapshot.heroMaxHP
        hud.shield = snapshot.shield
        hud.souls = snapshot.souls
        hud.soulCap = snapshot.soulCap
        hud.relics = snapshot.relics.map { relic in
            RelicButtonState(name: relic.name, short: short(relic.name), souls: Int(relic.souls), cooldown: relic.cooldown, ready: relic.ready)
        }
        hud.potionCharges = snapshot.potionCharges
        hud.potionMax = snapshot.potionMax
        hud.potionCooldown = snapshot.potionCooldown
        hud.speed = snapshot.speed.rawValue
        hud.paused = snapshot.paused
        hud.wave = snapshot.wave
        hud.kills = snapshot.kills
        hud.down = snapshot.heroDown
        hud.meter = snapshot.meter
        hud.depth = snapshot.depth
        hud.floor = snapshot.floor
        hud.lanternOn = snapshot.lanternOn
        hud.lantern = snapshot.lantern
        hud.enraged = snapshot.entities.contains { $0.enraged }
        if let result = snapshot.riftResult {
            if acceptedLoot == false {
                acceptedLoot = true
                accept(result)
            }
            hud.depthDelta = result.depthDelta
            hud.resultMessage = result.message
            hud.settled = result.died == false
        }
        #if DEBUG
        hud.debug = "seed \(snapshot.seed) · tick \(snapshot.tick) · \(snapshot.entities.count) ents · content \(contentVersion.prefix(6))"
        #endif
        if snapshot.heroDown {
            if fellWall == nil {
                fellWall = ContinuousClock.now
                // Freeze the tick the hero falls so the card holds that moment. The watch still moves on.
                let actor = sim
                Task { await actor.enqueue(.pause) }
            }
            if savedThisRun == false {
                savedThisRun = true
                let actor = sim
                Task { await saveRecording(from: actor) }
            }
            if jumpIn, let fellWall, ContinuousClock.now - fellWall >= .seconds(5) {
                newRun()
            }
        } else if snapshot.riftResult != nil {
            if fellWall == nil {
                fellWall = ContinuousClock.now
                let actor = sim
                Task { await actor.enqueue(.pause) }
            }
            if savedThisRun == false {
                savedThisRun = true
                let actor = sim
                Task { await saveRecording(from: actor) }
            }
            if jumpIn, let fellWall, ContinuousClock.now - fellWall >= .seconds(5) {
                newRun()
            }
        }
    }

    // MARK: Inputs

    func fireRelic(_ slot: Int) {
        Task { await sim.enqueue(.fireRelic(slot: slot)) }
    }

    func drinkPotion() {
        Task { await sim.enqueue(.drinkPotion) }
    }

    func cycleSpeed() {
        speed = switch speed {
        case .x1: .x2
        case .x2: .x4
        case .x4: .x1
        }
        let next = speed
        Task { await sim.enqueue(.setSpeed(next)) }
    }

    func togglePause() {
        paused.toggle()
        let command: SimCommand = paused ? .pause : .resume
        Task { await sim.enqueue(command) }
    }

    func returnHome() {
        if jumpIn {
            newRun()
            return
        }
        village.isPaused = false
        village.centerOnWell()
        glance = village.cameraPoint
        place = .village
        loop?.cancel()
        loop = nil
        paused = false
        fellWall = nil
        savedThisRun = false
        acceptedLoot = false
        tacticUntil = 0
        hud.tactic = nil
        hud.settled = false
        hud.down = false
        hud.lootLines = []
        hud.depthDelta = nil
        hud.resultMessage = nil
        hud.enraged = false
        hud.paused = false
    }

    func openGate() {
        chosenDepth = frontier
        place = .gate
    }

    func closeGate() {
        place = .village
    }

    func openBag() { place = .bag }

    func closeOverlay() {
        pendingSalvage = nil
        place = .village
    }

    func syncVillage(viewSize: CGSize) {
        guard viewSize.width > 1, viewSize.height > 1 else { return }
        if village.size != viewSize { village.size = viewSize }
        village.clampCamera()
        glance = village.cameraPoint
    }

    func panVillage(finger: CGSize) {
        let dx = finger.width - panCursor.width
        let dy = finger.height - panCursor.height
        panCursor = finger
        village.pan(fingerX: dx, fingerY: dy)
        glance = village.cameraPoint
    }

    func endVillagePan() {
        panCursor = .zero
    }

    func tapBuilding(_ id: String) {
        switch id {
        case "well":
            openGate()
        case "blacksmith":
            pendingSalvage = nil
            place = .smith
        default:
            guard let building = hamlet.buildings.first(where: { $0.id == id }) else { return }
            cottageName = building.name
            cottageDepth = building.unlockDepth ?? 2
            place = .cottage
        }
    }

    func salvage(_ id: String) {
        guard let item = save.inventory.bag.first(where: { $0.id == id }) else { return }
        switch SmithRules.salvage(rarity: item.rarity, signature: item.signature, equipped: wearing(item.id, save.loadouts.first), confirmed: false, tuning: smithTuning) {
        case .needsConfirmation:
            pendingSalvage = id
        case .granted(let yield):
            applySalvage(yield, id: id)
        case .refused:
            break
        }
    }

    func confirmSalvage() {
        guard let id = pendingSalvage, let item = save.inventory.bag.first(where: { $0.id == id }) else {
            pendingSalvage = nil
            return
        }
        pendingSalvage = nil
        if case .granted(let yield) = SmithRules.salvage(rarity: item.rarity, signature: item.signature, equipped: wearing(id, save.loadouts.first), confirmed: true, tuning: smithTuning) {
            applySalvage(yield, id: id)
        }
    }

    func cancelSalvage() {
        pendingSalvage = nil
    }

    func raiseItem(_ id: String) {
        guard let index = save.inventory.bag.firstIndex(where: { $0.id == id }) else { return }
        let item = save.inventory.bag[index]
        switch SmithRules.raise(itemLevel: item.itemLevel, bestDepth: max(1, save.bestDepth), dust: save.inventory.dust, gold: save.inventory.gold, tuning: smithTuning) {
        case .raised(let level, let dust, let gold):
            save.inventory.bag[index].itemLevel = level
            save.inventory.dust -= dust
            save.inventory.gold -= gold
            saveGame()
        case .refused:
            break
        }
    }

    func smithLines() -> [SmithLine] {
        let tuning = smithTuning
        let best = max(1, save.bestDepth)
        let loadout = save.loadouts.first
        return save.inventory.bag.map { item in
            let piece = asLoot(item)
            let marks = arrows(for: piece, against: loadout)
            let equipped = wearing(item.id, loadout)
            let cost = SmithRules.raiseCost(itemLevel: item.itemLevel, tuning: tuning)
            let atCap = item.itemLevel >= SmithRules.cap(bestDepth: best)
            let caption = atCap ? "At the cap" : "\(whole(cost.dust)) Dust, \(whole(cost.gold)) Gold"
            let afford = save.inventory.dust + 0.000_001 >= cost.dust && save.inventory.gold + 0.000_001 >= cost.gold
            return SmithLine(
                id: item.id, text: "\(piece.rarityName) \(piece.name) \(piece.itemLevel)",
                damageArrow: marks.0, toughnessArrow: marks.1, equipped: equipped,
                canSalvage: equipped == false, canRaise: atCap == false && afford, raiseCaption: caption
            )
        }
    }

    var heroLevel: Int { save.hero.level }
    var goldAmount: Int { whole(save.inventory.gold) }
    var dustAmount: Int { whole(save.inventory.dust) }
    var shardAmount: Int { whole(save.inventory.shards) }
    var emberAmount: Int { whole(save.inventory.embers) }

    func stepDepth(_ delta: Int) {
        let best = max(1, save.bestDepth)
        chosenDepth = min(best, max(1, chosenDepth + delta))
    }

    func chooseDelve() { deepRift = false }
    func chooseDeepRift() { deepRift = true }

    func beginRift() {
        let form = gateForm()
        guard form.blocked == false else { return }
        mode = form.deepRift ? .deepRift : .delve
        chosenDepth = form.depth
        useSavedDepth = true
        let nextSeed = UInt64(max(1, save.runSeed))
        save.runSeed = Int(nextSeed) + 1
        saveGame()
        seed = nextSeed
        let nextSetup = prepared(base, seed: nextSeed)
        setup = nextSetup
        sim = RiftActor(seed: nextSeed, setup: nextSetup)
        paused = false
        speed = .x1
        fellWall = nil
        savedThisRun = false
        acceptedLoot = false
        tacticUntil = 0
        hud.tactic = nil
        hud.settled = false
        hud.down = false
        hud.lootLines = []
        hud.depthDelta = nil
        hud.resultMessage = nil
        hud.enraged = false
        hud.paused = false
        shownRoom = ""
        scene.load(room: nextSetup.room)
        village.isPaused = true
        place = .rift
        start()
    }

    func gateForm() -> GateForm {
        let best = max(1, save.bestDepth)
        let depth = min(best, max(1, chosenDepth))
        let placement = catalog?.biomes.placement(at: depth)
        let biomeID = placement?.biomeID ?? "mossy_cellars"
        let echo = placement?.echo ?? false
        let p0 = catalog?.tuning.combat.p0 ?? 10
        let band = BuildForecast.band(depth: depth, weapons: forecastWeapons(), p0: p0)
        let blocked = deepRift && DepthRules.deepRiftAllowed(depth: depth, best: best) == false
        return GateForm(
            depth: depth, bestDepth: best, deepRift: deepRift, biome: BiomeName.display(id: biomeID, echo: echo),
            band: band.label, blocked: blocked, mossyNote: biomeID != "mossy_cellars" || echo
        )
    }

    func bagLines() -> [LootLine] {
        let loadout = save.loadouts.first
        return save.inventory.bag.map { item in
            let piece = asLoot(item)
            let marks = arrows(for: piece, against: loadout)
            return LootLine(
                id: item.id, text: "\(piece.rarityName) \(piece.name) \(piece.itemLevel)",
                damageArrow: marks.0, toughnessArrow: marks.1, equipped: wearing(item.id, loadout)
            )
        }
    }

    func newRun() {
        seed &+= 1
        let nextSetup = prepared(base, seed: seed)
        setup = nextSetup
        sim = RiftActor(seed: seed, setup: nextSetup)
        paused = false
        fellWall = nil
        savedThisRun = false
        acceptedLoot = false
        tacticUntil = 0
        hud.tactic = nil
        hud.settled = false
        hud.lootLines = []
        hud.depthDelta = nil
        hud.resultMessage = nil
        hud.enraged = false
        shownRoom = ""
        scene.load(room: nextSetup.room)
        let next = speed
        Task { await sim.enqueue(.setSpeed(next)) }
    }

    func equip(_ id: String) {
        guard save.loadouts.isEmpty == false, let item = save.inventory.bag.first(where: { $0.id == id }) else { return }
        var loadout = save.loadouts[0]
        let piece = slot(of: item)
        switch piece {
        case "melee": loadout.melee = id
        case "ranged": loadout.ranged = id
        case "relic": loadout.relics = [id]
        case "helm", "chest", "legs", "boots": loadout.armor[piece] = id
        default: return
        }
        save.loadouts[0] = loadout
        saveGame()
        hud.lootLines = hud.lootLines.map { line in
            var line = line
            line.equipped = wearing(line.id, loadout)
            return line
        }
    }

    func saveGame() {
        try? store.write(save)
    }

    private func prepared(_ bare: RoomSetup, seed: UInt64) -> RoomSetup {
        var next = bare
        if useSavedDepth {
            next.depth = min(max(1, chosenDepth), max(1, save.bestDepth))
        }
        guard var rift = next.rift else { return next }
        rift.floors = RiftFloors.count(for: seed)
        rift.mode = mode
        rift.guardian = guardian
        if let catalog {
            let loadout = save.loadouts.first
            rift.loot = catalog.lootTable(pity: save.inventory.lootPity, equipped: equipped(loadout, depth: next.depth, catalog: catalog), idPrefix: "\(seed)-\(save.inventory.bag.count)")
        }
        next.rift = rift
        if let catalog, let loadout = save.loadouts.first {
            apply(loadout, catalog: catalog, to: &next)
        }
        let perLevel = catalog?.tuning.heroHPPerLevel ?? CellarFight.tuning.heroHPPerLevel
        next.bonusHP += HeroProgress.bonusHP(level: save.hero.level, perLevel: perLevel)
        return next
    }

    private func accept(_ result: RiftResult) {
        save.bestDepth = DepthRules.nextBest(best: save.bestDepth, foughtAt: result.depth, delta: result.depthDelta, died: result.died)
        grantProgress()
        guard setup.rift?.loot != nil else {
            saveGame()
            return
        }
        let room = InventorySave.bagCapacity - save.inventory.bag.count
        let kept = LootRoller.admit(result.items, room: room)
        for item in kept {
            _ = save.inventory.store(stored(item))
        }
        save.inventory.lootPity = result.pity
        saveGame()
        let loadout = save.loadouts.first
        hud.lootLines = kept.map { item in
            LootLine(
                id: item.id, text: "\(item.rarityName) \(item.name) \(item.itemLevel)",
                damageArrow: item.damageArrow, toughnessArrow: item.toughnessArrow, equipped: wearing(item.id, loadout)
            )
        }
    }

    private func stored(_ item: LootItem) -> ItemSave {
        ItemSave(
            id: item.id, definition: item.definition, itemLevel: item.itemLevel, rarity: item.rarity, quality: "standard",
            affixes: item.affixes.map(\.saved), signature: item.signature, locked: false, favorite: false, glyphSockets: []
        )
    }

    private func wearing(_ id: String, _ loadout: LoadoutSave?) -> Bool {
        guard let loadout else { return false }
        return loadout.melee == id || loadout.ranged == id || loadout.relics.contains(id) || loadout.armor.values.contains(id)
    }

    private func slot(of item: ItemSave) -> String {
        guard let catalog else { return item.definition }
        if let unique = catalog.uniques.first(where: { $0.id == item.definition }) { return unique.slot }
        if let weapon = catalog.weapons.first(where: { $0.id == item.definition }) { return weapon.kind.rawValue }
        if catalog.relics.contains(where: { $0.id == item.definition }) { return "relic" }
        return item.definition
    }

    private func equipped(_ loadout: LoadoutSave?, depth: Int, catalog: ContentCatalog) -> [LootItem] {
        var gear: [LootItem] = []
        func add(_ id: String?, slot: String, fallback: String, name: String, fallbackWhenEmpty: Bool) {
            if let id, let item = save.inventory.bag.first(where: { $0.id == id }) {
                gear.append(LootItem(
                    id: item.id, definition: item.definition, name: itemName(item, catalog: catalog), slot: slot,
                    itemLevel: item.itemLevel, rarity: item.rarity,
                    affixes: LootAffixRoll.parse(item.affixes, definitions: catalog.itemAffixes),
                    signature: item.signature, damageArrow: 0, toughnessArrow: 0
                ))
            } else if fallbackWhenEmpty {
                gear.append(.plain(id: "worn-\(slot)", name: name, slot: slot, itemLevel: depth + 10, definition: fallback))
            }
        }
        add(loadout?.melee, slot: "melee", fallback: "sword", name: "Sword", fallbackWhenEmpty: true)
        add(loadout?.ranged, slot: "ranged", fallback: "bow", name: "Bow", fallbackWhenEmpty: true)
        add(loadout?.relics.first, slot: "relic", fallback: "ember_flask", name: "Ember Flask", fallbackWhenEmpty: true)
        for slot in ["helm", "chest", "legs", "boots"] {
            add(loadout?.armor[slot], slot: slot, fallback: slot, name: slot, fallbackWhenEmpty: false)
        }
        return gear
    }

    private func apply(_ loadout: LoadoutSave, catalog: ContentCatalog, to setup: inout RoomSetup) {
        func bagItem(_ id: String?) -> ItemSave? {
            guard let id else { return nil }
            return save.inventory.bag.first { $0.id == id }
        }
        if let worn = bagItem(loadout.melee), let weapon = weapon(worn, kind: .melee, catalog: catalog) { setup.melee = weapon }
        if let worn = bagItem(loadout.ranged), let weapon = weapon(worn, kind: .ranged, catalog: catalog) { setup.ranged = weapon }
        if let worn = bagItem(loadout.relics.first), let relic = relic(worn, catalog: catalog), setup.relics.isEmpty == false {
            setup.relics[0] = relic
        }
        var signatures: [SignatureSpec] = []
        for id in [loadout.melee, loadout.ranged, loadout.relics.first].compactMap({ $0 }) + Array(loadout.armor.values) {
            guard let worn = bagItem(id), let unique = catalog.uniques.first(where: { $0.id == worn.definition }) else { continue }
            signatures.append(catalog.resolved(unique.effect))
        }
        setup.signatures = signatures
        var bonus = 0.0
        var rating = 0.0
        var curves = BalanceCurves()
        for slot in ["helm", "chest", "legs", "boots"] {
            guard let worn = bagItem(loadout.armor[slot]) else { continue }
            let rolls = LootAffixRoll.parse(worn.affixes, definitions: catalog.itemAffixes)
            let hp = curves.heroHitPoints(h0: catalog.tuning.combat.h0, itemLevel: worn.itemLevel)
            bonus += hp * rolls.filter { $0.stat == "maxHP" }.reduce(0) { $0 + $1.value }
            rating += hp * rolls.filter { $0.stat == "armor" }.reduce(0) { $0 + $1.value }
        }
        setup.bonusHP = bonus
        setup.armor = rating
        let worn = [loadout.melee, loadout.ranged].compactMap { id -> LootItem? in
            guard let item = bagItem(id) else { return nil }
            return asLoot(item)
        }
        setup.powerScale = BuildForecast.multiplier(depth: setup.depth, weapons: worn, p0: catalog.tuning.combat.p0)
    }

    private func forecastWeapons() -> [LootItem] {
        guard let loadout = save.loadouts.first else { return [] }
        return [loadout.melee, loadout.ranged].compactMap { id in
            guard let id, let item = save.inventory.bag.first(where: { $0.id == id }) else { return nil }
            return asLoot(item)
        }
    }

    private func asLoot(_ item: ItemSave) -> LootItem {
        let definitions = catalog?.itemAffixes ?? []
        return LootItem(
            id: item.id, definition: item.definition, name: catalog.map { itemName(item, catalog: $0) } ?? item.definition,
            slot: slot(of: item), itemLevel: item.itemLevel, rarity: item.rarity,
            affixes: LootAffixRoll.parse(item.affixes, definitions: definitions),
            signature: item.signature, damageArrow: 0, toughnessArrow: 0
        )
    }

    private func arrows(for item: LootItem, against loadout: LoadoutSave?) -> (Int, Int) {
        guard let loadout, let wornID = equippedID(item.slot, loadout), wornID != item.id,
              let worn = save.inventory.bag.first(where: { $0.id == wornID }) else { return (0, 0) }
        let old = asLoot(worn)
        let p0 = catalog?.tuning.combat.p0 ?? 10
        let h0 = catalog?.tuning.combat.h0 ?? 100
        return (
            LootScore.arrow(new: LootScore.damage(itemLevel: item.itemLevel, affixes: item.affixes, p0: p0), old: LootScore.damage(itemLevel: old.itemLevel, affixes: old.affixes, p0: p0)),
            LootScore.arrow(new: LootScore.toughness(itemLevel: item.itemLevel, affixes: item.affixes, h0: h0), old: LootScore.toughness(itemLevel: old.itemLevel, affixes: old.affixes, h0: h0))
        )
    }

    private func equippedID(_ slot: String, _ loadout: LoadoutSave) -> String? {
        switch slot {
        case "melee": loadout.melee
        case "ranged": loadout.ranged
        case "relic": loadout.relics.first
        default: loadout.armor[slot]
        }
    }

    private func weapon(_ item: ItemSave, kind: WeaponKind, catalog: ContentCatalog) -> WeaponDefinition? {
        let id = catalog.uniques.first { $0.id == item.definition }?.weaponType ?? item.definition
        return catalog.weapons.first { $0.id == id && $0.kind == kind }
    }

    private func relic(_ item: ItemSave, catalog: ContentCatalog) -> RelicDefinition? {
        let id = catalog.uniques.first { $0.id == item.definition }?.baseRelic ?? item.definition
        return catalog.relics.first { $0.id == id }
    }

    private func itemName(_ item: ItemSave, catalog: ContentCatalog) -> String {
        if let unique = catalog.uniques.first(where: { $0.id == item.definition }) { return unique.name }
        if let weapon = catalog.weapons.first(where: { $0.id == item.definition }) { return weapon.name }
        if let relic = catalog.relics.first(where: { $0.id == item.definition }) { return relic.name }
        return item.definition.prefix(1).uppercased() + item.definition.dropFirst()
    }

    /// Writes the run to Documents/recordings so `hearthsim replay --recording` can reproduce it on a Mac.
    func saveRecording() async {
        await saveRecording(from: sim)
    }

    func saveRecording(from actor: RiftActor) async {
        let recording = await actor.recording(contentVersion: contentVersion)
        do {
            let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("recordings", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("run-\(recording.seed)-\(recording.endTick).json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(recording).write(to: file)
            note = "Saved \(file.lastPathComponent) in Files › Hearthdelve › recordings"
        } catch {
            note = "Could not save the run: \(error.localizedDescription)"
        }
    }

    // MARK: Text

    private func flash(_ text: String, at tick: UInt64) {
        hud.tactic = text
        tacticUntil = tick + 40
    }

    private func short(_ name: String) -> String {
        String(name.split(separator: " ").first ?? Substring(name))
    }

    private func describe(_ condition: TacticCondition) -> String {
        let tiles = condition.tiles.map { $0.formatted() } ?? "0"
        return switch condition.kind {
        case "always": "always"
        case "selfHPBelow": "HP below \(Int((condition.value ?? 0) * 100))%"
        case "eliteWithin": "elite within \(tiles)"
        case "enemiesWithin": "\(condition.count ?? 1)+ within \(tiles)"
        case "soulsAtLeast": "Souls ≥ \(Int(condition.value ?? 0))"
        case "targetBeyond": "target beyond \(tiles)"
        case "targetIsElite": "target is elite"
        case "shieldDown": "no shield"
        default: condition.kind
        }
    }

    private func builtHamlet() -> VillageSnapshot {
        let buildings = catalog?.buildings ?? []
        return VillageHamlet.make(
            names: Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0.name) }),
            unlocks: VillageHamlet.depthUnlocks(buildings)
        )
    }

    private var smithTuning: SmithTuning {
        catalog?.tuning.smith ?? CellarFight.tuning.smith
    }

    private func grantProgress() {
        let curve = catalog?.tuning.heroXP ?? CellarFight.tuning.heroXP
        let grant = HeroProgress.apply(
            xp: HeroProgress.riftXP(level: save.hero.level, curve: curve),
            level: save.hero.level, xp: save.hero.xp, glyphPoints: save.hero.bankedGlyphPoints, curve: curve
        )
        save.hero.level = grant.level
        save.hero.xp = grant.xp
        save.hero.bankedGlyphPoints = grant.glyphPoints
        save.inventory.gold += catalog?.tuning.riftGold ?? CellarFight.tuning.riftGold
    }

    private func applySalvage(_ yield: SalvageYield, id: String) {
        save.inventory.bag.removeAll { $0.id == id }
        save.inventory.dust += yield.dust
        save.inventory.shards += yield.shards
        save.inventory.embers += yield.embers
        SmithRules.record(signature: yield.codexSignature, codex: &save.codex.signatures)
        saveGame()
    }

    private func whole(_ value: Double) -> Int {
        Int(value.rounded())
    }
}

struct RiftHost: View {
    @State private var driver = RiftDriver()

    var body: some View {
        ZStack {
            villageStack
                .allowsHitTesting(driver.place != .rift)
                .accessibilityHidden(driver.place == .rift)
            if driver.place == .rift {
                ZStack {
                    SpriteView(scene: driver.scene, debugOptions: debugOptions)
                        .ignoresSafeArea()
                    RoomHUD(
                        state: driver.hud,
                        actions: RoomActions(
                            relic: driver.fireRelic,
                            potion: driver.drinkPotion,
                            speed: driver.cycleSpeed,
                            pause: driver.togglePause,
                            newRun: driver.returnHome,
                            saveRecording: { Task { await driver.saveRecording() } },
                            equip: driver.equip
                        ),
                        note: driver.note
                    )
                }
                .background(HearthPalette.ink)
            }
        }
        .background(HearthPalette.ink)
        .onAppear {
            if driver.place == .rift { driver.start() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { driver.saveGame() }
        }
    }

    private var villageStack: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(scene: driver.village)
                    .ignoresSafeArea()
                if driver.place == .village {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 12)
                                .onChanged { driver.panVillage(finger: $0.translation) }
                                .onEnded { _ in driver.endVillagePan() }
                        )
                    ForEach(driver.hamlet.buildings) { building in
                        let rect = VillageFrame.viewRect(
                            building: building, rows: driver.hamlet.rows, camera: driver.glance,
                            viewSize: geo.size, tile: VillageScene.tile
                        )
                        Button { driver.tapBuilding(building.id) } label: {
                            Color.clear
                                .frame(width: rect.width, height: rect.height)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .position(x: rect.midX, y: rect.midY)
                        .accessibilityLabel(building.accessibilityLabel)
                    }
                    VStack {
                        VillageChrome(
                            level: driver.heroLevel,
                            gold: driver.goldAmount,
                            dust: driver.dustAmount,
                            shards: driver.shardAmount,
                            embers: driver.emberAmount,
                            bestDepth: driver.frontier,
                            openBag: driver.openBag
                        )
                        .padding(.top, topSafeInset)
                        Spacer(minLength: 0).allowsHitTesting(false)
                    }
                }
                if driver.place == .bag {
                    BagView(
                        lines: driver.bagLines(), count: driver.bagLines().count, capacity: InventorySave.bagCapacity,
                        close: driver.closeOverlay, equip: driver.equip
                    )
                }
                if driver.place == .gate {
                    let form = driver.gateForm()
                    RiftGateView(
                        depth: form.depth,
                        bestDepth: form.bestDepth,
                        deepRift: form.deepRift,
                        biome: form.biome,
                        band: form.band,
                        blocked: form.blocked,
                        mossyNote: form.mossyNote,
                        lower: { driver.stepDepth(-1) },
                        raise: { driver.stepDepth(1) },
                        chooseDelve: { driver.chooseDelve() },
                        chooseDeepRift: { driver.chooseDeepRift() },
                        start: { driver.beginRift() },
                        back: { driver.closeGate() }
                    )
                }
                if driver.place == .smith {
                    SmithView(
                        gold: driver.goldAmount, dust: driver.dustAmount, shards: driver.shardAmount, embers: driver.emberAmount,
                        lines: driver.smithLines(), confirming: driver.pendingSalvage != nil,
                        close: driver.closeOverlay, salvage: driver.salvage, confirmSalvage: driver.confirmSalvage,
                        cancelSalvage: driver.cancelSalvage, raise: driver.raiseItem, equip: driver.equip
                    )
                }
                if driver.place == .cottage {
                    LockedCottageView(name: driver.cottageName, depth: driver.cottageDepth, close: driver.closeOverlay)
                }
            }
            .onAppear { driver.syncVillage(viewSize: geo.size) }
            .onChange(of: geo.size) { _, size in driver.syncVillage(viewSize: size) }
        }
        .ignoresSafeArea()
    }

    @Environment(\.scenePhase) private var scenePhase

    /// The village map is full-bleed, so the status bar does not inset this view. Read the window inset directly.
    private var topSafeInset: CGFloat {
        let inset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
        return inset > 0 ? inset : 59
    }

    private var debugOptions: SpriteView.DebugOptions {
        #if DEBUG
        [.showsFPS, .showsNodeCount]
        #else
        []
        #endif
    }
}
