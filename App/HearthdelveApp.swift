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
    case library
    case stash
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
    var smithNote: String?
    var stashNote: String?
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
        if fillEmptySlots() {
            let worn = prepared(base, seed: seed)
            setup = worn
            sim = RiftActor(seed: seed, setup: worn)
            scene.load(room: worn.room)
            shownRoom = worn.room.id
        }
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
                if let rule, setup.tactics.indices.contains(rule) {
                    flash(TacticLibrary.line(index: rule, rule: setup.tactics[rule], relicName: relicDisplay), at: snapshot.tick)
                } else {
                    flash("You: \(name)", at: snapshot.tick)
                }
            case .potion(let rule):
                if let rule, setup.tactics.indices.contains(rule) {
                    flash(TacticLibrary.line(index: rule, rule: setup.tactics[rule], relicName: relicDisplay), at: snapshot.tick)
                } else {
                    flash("You: Potion", at: snapshot.tick)
                }
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
        hud.floorCount = snapshot.floorCount
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
        hud.lootEmpty = "None"
        hud.lootNote = nil
        hud.depthDelta = nil
        hud.resultMessage = nil
        hud.reward = nil
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
            smithNote = nil
            place = .smith
        case "library":
            openOrLocked(id, unlocked: .library)
        case "stash_house":
            stashNote = nil
            openOrLocked(id, unlocked: .stash)
        default:
            openOrLocked(id, unlocked: nil)
        }
    }

    private func openOrLocked(_ id: String, unlocked: HearthPlace?) {
        guard let building = hamlet.buildings.first(where: { $0.id == id }) else { return }
        if let depth = building.unlockDepth, frontier < depth {
            cottageName = building.name
            cottageDepth = depth
            place = .cottage
            return
        }
        if let unlocked {
            place = unlocked
            return
        }
        cottageName = building.name
        cottageDepth = building.unlockDepth ?? 2
        place = .cottage
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
            let caption = SmithRules.raiseCaption(itemLevel: item.itemLevel, bestDepth: best, tuning: tuning)
            let afford = save.inventory.dust + 0.000_001 >= cost.dust && save.inventory.gold + 0.000_001 >= cost.gold
            let rerollCost = SmithRules.rerollCost(rarity: item.rarity, times: item.rerolls, tuning: tuning)
            let canReroll = rerollCost.map { save.inventory.shards + 0.000_001 >= $0.shards && save.inventory.embers + 0.000_001 >= $0.embers } ?? false
            let canTransmute = item.rarity == "unique" && save.inventory.embers + 0.000_001 >= tuning.transmuteEmbers
            let affixes = piece.affixes.enumerated().map { index, roll in
                let name = catalog?.itemAffixes.first { $0.id == roll.id }?.name ?? roll.stat
                return SmithAffix(index: index, name: name, detail: AffixFormat.line(name: name, value: roll.value))
            }
            return SmithLine(
                id: item.id, text: "\(piece.rarityName) \(piece.name) \(piece.itemLevel)",
                slot: piece.slot, slotName: GearSlots.name(piece.slot),
                damageArrow: marks.0, toughnessArrow: marks.1, equipped: equipped,
                canSalvage: equipped == false,
                canRaise: item.itemLevel < SmithRules.cap(bestDepth: best) && afford,
                raiseCaption: caption,
                affixes: affixes,
                canReroll: canReroll && affixes.isEmpty == false,
                rerollCaption: SmithRules.rerollCaption(rarity: item.rarity, times: item.rerolls, tuning: tuning) ?? "",
                canTransmute: canTransmute,
                transmuteCaption: item.rarity == "unique" ? SmithRules.transmuteCaption(tuning: tuning) : "",
                signature: signatureSentence(item)
            )
        }
    }

    func craftCaption() -> String {
        SmithRules.craftCaption(tuning: smithTuning)
    }

    func craftChoices() -> [CraftChoice] {
        guard let catalog else { return [] }
        return catalog.lootTable(pity: 0, equipped: [], idPrefix: "craft").bases.map {
            CraftChoice(id: $0.id, name: $0.name, slot: $0.slot, slotName: GearSlots.name($0.slot))
        }
    }

    func reroll(_ id: String, index: Int) {
        guard let catalog, let slot = save.inventory.bag.firstIndex(where: { $0.id == id }) else { return }
        let item = save.inventory.bag[slot]
        let piece = asLoot(item)
        var rng = smithRNG(extra: UInt64(item.rerolls))
        switch SmithRules.reroll(
            rarity: item.rarity, slot: piece.slot, affixes: piece.affixes, index: index, times: item.rerolls,
            shards: save.inventory.shards, embers: save.inventory.embers, pool: catalog.itemAffixes,
            tuning: smithTuning, rng: &rng
        ) {
        case .rerolled(let affixes, let shards, let embers):
            save.inventory.bag[slot].affixes = affixes.map(\.saved)
            save.inventory.bag[slot].rerolls += 1
            save.inventory.shards -= shards
            save.inventory.embers -= embers
            smithNote = nil
            saveGame()
        case .refused:
            break
        }
    }

    func craft(slot: String, typeID: String) {
        guard let catalog else { return }
        if save.inventory.bag.count >= InventorySave.bagCapacity {
            smithNote = StashRules.bagFull
            return
        }
        var rng = smithRNG(extra: UInt64(save.inventory.bag.count))
        let id = "craft-\(save.runSeed)-\(save.inventory.bag.count)"
        switch SmithRules.craft(
            slot: slot, typeID: typeID, bases: catalog.lootTable(pity: 0, equipped: [], idPrefix: "craft").bases,
            affixes: catalog.itemAffixes, shards: save.inventory.shards, bagCount: save.inventory.bag.count,
            bagCapacity: InventorySave.bagCapacity, itemLevel: SmithRules.cap(bestDepth: max(1, save.bestDepth)),
            tuning: smithTuning, rng: &rng, id: id
        ) {
        case .crafted(let item, let shards):
            guard save.inventory.store(stored(item)) else {
                smithNote = StashRules.bagFull
                return
            }
            save.inventory.shards -= shards
            smithNote = nil
            saveGame()
        case .refused("bag"):
            smithNote = StashRules.bagFull
        case .refused:
            break
        }
    }

    func transmute(_ id: String) {
        guard let catalog, let index = save.inventory.bag.firstIndex(where: { $0.id == id }) else { return }
        let item = save.inventory.bag[index]
        let uniques = catalog.uniques.map { LootUnique(id: $0.id, name: $0.name, slot: $0.slot) }
        var rng = smithRNG(extra: stableMix(item.definition))
        switch SmithRules.transmute(
            rarity: item.rarity, slot: slot(of: item), currentID: item.definition, uniques: uniques,
            embers: save.inventory.embers, tuning: smithTuning, rng: &rng
        ) {
        case .transmuted(let unique, let embers):
            save.inventory.bag[index].definition = unique.id
            save.inventory.bag[index].signature = unique.id
            save.inventory.bag[index].rerolls = 0
            save.inventory.embers -= embers
            smithNote = nil
            saveGame()
        case .refused:
            break
        }
    }

    func moveToStash(_ id: String) {
        let reason = save.inventory.moveToStash(id: id, equipped: wearing(id, save.loadouts.first))
        if let reason {
            stashNote = StashRules.note(for: reason)
            return
        }
        stashNote = nil
        saveGame()
    }

    func moveToBag(_ id: String) {
        let reason = save.inventory.moveToBag(id: id)
        if let reason {
            stashNote = StashRules.note(for: reason)
            return
        }
        stashNote = nil
        saveGame()
    }

    func stashLines() -> [LootLine] {
        save.inventory.stash.map { item in
            let piece = asLoot(item)
            return LootLine(
                id: item.id, text: "\(piece.rarityName) \(piece.name) \(piece.itemLevel)",
                slot: piece.slot, slotName: GearSlots.name(piece.slot),
                damageArrow: 0, toughnessArrow: 0, equipped: false, details: itemDetails(item)
            )
        }
    }

    func tacticLines() -> [TacticEditLine] {
        currentTactics().enumerated().map { index, rule in
            TacticEditLine(
                id: index,
                caption: TacticLibrary.line(index: index, rule: rule, relicName: relicDisplay),
                kind: rule.condition.kind,
                adjusts: TacticLibrary.adjusts(rule.condition.kind)
            )
        }
    }

    func tacticKinds() -> [TacticKindChoice] {
        TacticLibrary.kinds.map { TacticKindChoice(id: $0, name: TacticLibrary.kindLabel($0)) }
    }

    func chooseTacticKind(_ index: Int, _ kind: String) {
        guard let condition = TacticLibrary.preset(kind) else { return }
        let rules = currentTactics()
        if rules.indices.contains(index), rules[index].condition.kind == kind { return }
        guard let next = TacticLibrary.replace(rules, index: index, condition: condition, fallback: base.tactics) else { return }
        storeTactics(next)
    }

    func nudgeTactic(_ index: Int, _ delta: Int) {
        guard let next = TacticLibrary.nudge(currentTactics(), index: index, delta: delta, fallback: base.tactics) else { return }
        storeTactics(next)
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
        hud.lootEmpty = "None"
        hud.lootNote = nil
        hud.depthDelta = nil
        hud.resultMessage = nil
        hud.reward = nil
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

    func wornSlots() -> [GearSlotLine] {
        let loadout = save.loadouts.first
        return GearSlots.order.map { slot in
            let wearing: String
            if let id = loadout.flatMap({ equippedID(slot, $0) }),
               let item = save.inventory.bag.first(where: { $0.id == id }) {
                let piece = asLoot(item)
                wearing = "\(piece.rarityName) \(piece.name) \(piece.itemLevel)"
            } else {
                wearing = "Empty"
            }
            return GearSlotLine(id: slot, name: GearSlots.name(slot), wearing: wearing)
        }
    }

    func bagLines() -> [LootLine] {
        let loadout = save.loadouts.first
        return save.inventory.bag.map { item in
            let piece = asLoot(item)
            let marks = arrows(for: piece, against: loadout)
            return LootLine(
                id: item.id, text: "\(piece.rarityName) \(piece.name) \(piece.itemLevel)",
                slot: piece.slot, slotName: GearSlots.name(piece.slot),
                damageArrow: marks.0, toughnessArrow: marks.1, equipped: wearing(item.id, loadout),
                details: itemDetails(item)
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
        hud.lootEmpty = "None"
        hud.lootNote = nil
        hud.depthDelta = nil
        hud.resultMessage = nil
        hud.reward = nil
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
        refreshLootLines(loadout)
    }

    func saveGame() {
        try? store.write(save)
    }

    /// Puts the strongest bag piece into each slot that is still empty.
    @discardableResult
    private func fillEmptySlots() -> Bool {
        guard save.loadouts.isEmpty == false else { return false }
        var loadout = save.loadouts[0]
        let choices = save.inventory.bag.map { asLoot($0) }
        let p0 = catalog?.tuning.combat.p0 ?? 10
        let h0 = catalog?.tuning.combat.h0 ?? 100
        var changed = false
        for slot in GearSlots.order {
            guard let id = GearEquip.fill(slot: slot, wornID: equippedID(slot, loadout), choices: choices, p0: p0, h0: h0) else { continue }
            switch slot {
            case "melee": loadout.melee = id
            case "ranged": loadout.ranged = id
            case "relic": loadout.relics = [id]
            default: loadout.armor[slot] = id
            }
            changed = true
        }
        guard changed else { return false }
        save.loadouts[0] = loadout
        return true
    }

    var salvageCommons: Bool { save.gameplay.lootRules.contains(SmithRules.salvageCommon) }
    var salvageRares: Bool { save.gameplay.lootRules.contains(SmithRules.salvageRare) }

    func toggleSalvageCommons() { toggleSalvage(SmithRules.salvageCommon) }
    func toggleSalvageRares() { toggleSalvage(SmithRules.salvageRare) }

    private func toggleSalvage(_ token: String) {
        if let index = save.gameplay.lootRules.firstIndex(of: token) {
            save.gameplay.lootRules.remove(at: index)
        } else {
            save.gameplay.lootRules.append(token)
            _ = runAutoSalvage()
        }
        saveGame()
    }

    @discardableResult
    private func runAutoSalvage() -> (commons: Int, rares: Int) {
        let loadout = save.loadouts.first
        let candidates = save.inventory.bag.map { item in
            SmithRules.SalvageCandidate(
                id: item.id, rarity: item.rarity, signature: item.signature,
                equipped: wearing(item.id, loadout), locked: item.locked, favorite: item.favorite
            )
        }
        let picks = SmithRules.autoSalvage(items: candidates, rules: save.gameplay.lootRules, tuning: smithTuning)
        var commons = 0
        var rares = 0
        for pick in picks {
            guard let item = save.inventory.bag.first(where: { $0.id == pick.id }) else { continue }
            if item.rarity == "rare" { rares += 1 } else { commons += 1 }
            save.inventory.bag.removeAll { $0.id == pick.id }
            save.inventory.dust += pick.yield.dust
            save.inventory.shards += pick.yield.shards
            save.inventory.embers += pick.yield.embers
            SmithRules.record(signature: pick.yield.codexSignature, codex: &save.codex.signatures)
        }
        return (commons, rares)
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
            rift.loot = catalog.lootTable(pity: save.inventory.lootPity, equipped: equipped(loadout, catalog: catalog), idPrefix: "\(seed)-\(save.inventory.bag.count)")
        }
        next.rift = rift
        next.tactics = TacticLibrary.resolved(save.loadouts.first?.tactics.map(\.rule) ?? [], fallback: next.tactics)
        if let catalog, let loadout = save.loadouts.first {
            apply(loadout, catalog: catalog, to: &next)
        }
        let perLevel = catalog?.tuning.heroHPPerLevel ?? CellarFight.tuning.heroHPPerLevel
        next.bonusHP += HeroProgress.bonusHP(level: save.hero.level, perLevel: perLevel)
        return next
    }

    private func accept(_ result: RiftResult) {
        save.bestDepth = DepthRules.nextBest(best: save.bestDepth, foughtAt: result.depth, delta: result.depthDelta, died: result.died)
        hud.reward = grantProgress()
        guard setup.rift?.loot != nil else {
            saveGame()
            return
        }
        let startingPity = save.inventory.lootPity
        let room = InventorySave.bagCapacity - save.inventory.bag.count
        let kept = LootRoller.admit(result.items, room: room)
        for item in kept {
            _ = save.inventory.store(stored(item))
        }
        save.inventory.lootPity = LootRoller.pity(starting: startingPity, kept: kept)
        fillEmptySlots()
        let broken = runAutoSalvage()
        saveGame()
        let loadout = save.loadouts.first
        let still = kept.filter { item in save.inventory.bag.contains { $0.id == item.id } }
        hud.lootNote = SmithRules.salvageNote(commons: broken.commons, rares: broken.rares)
        hud.lootEmpty = result.items.isEmpty || still.isEmpty == false ? "None" : "The bag is full."
        hud.lootLines = still.map { item in
            let marks = arrows(for: item, against: loadout)
            return LootLine(
                id: item.id, text: "\(item.rarityName) \(item.name) \(item.itemLevel)",
                slot: item.slot, slotName: GearSlots.name(item.slot),
                damageArrow: marks.0, toughnessArrow: marks.1, equipped: wearing(item.id, loadout),
                details: signatureLine(item.signature) + item.affixes.map { roll in
                    let name = catalog?.itemAffixes.first { $0.id == roll.id }?.name ?? roll.stat
                    return AffixFormat.line(name: name, value: roll.value)
                }
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

    private func equipped(_ loadout: LoadoutSave?, catalog: ContentCatalog) -> [LootItem] {
        var gear: [LootItem] = []
        func add(_ id: String?, slot: String) {
            guard let id, let item = save.inventory.bag.first(where: { $0.id == id }) else { return }
            gear.append(LootItem(
                id: item.id, definition: item.definition, name: itemName(item, catalog: catalog), slot: slot,
                itemLevel: item.itemLevel, rarity: item.rarity,
                affixes: LootAffixRoll.parse(item.affixes, definitions: catalog.itemAffixes),
                signature: item.signature, damageArrow: 0, toughnessArrow: 0
            ))
        }
        add(loadout?.melee, slot: "melee")
        add(loadout?.ranged, slot: "ranged")
        add(loadout?.relics.first, slot: "relic")
        for slot in ["helm", "chest", "legs", "boots"] {
            add(loadout?.armor[slot], slot: slot)
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
            let rolls = LootAffixRoll.parse(worn.affixes, definitions: catalog.itemAffixes)
            setup.relics[0] = relic.tuned(by: rolls)
        }
        var signatures: [SignatureSpec] = []
        for id in [loadout.melee, loadout.ranged, loadout.relics.first].compactMap({ $0 }) + Array(loadout.armor.values) {
            guard let worn = bagItem(id), let unique = catalog.uniques.first(where: { $0.id == worn.definition }) else { continue }
            signatures.append(catalog.resolved(unique.effect))
        }
        setup.signatures = signatures
        let pieces: [(itemLevel: Int, affixes: [LootAffixRoll])] = ["helm", "chest", "legs", "boots"].compactMap { slot in
            guard let worn = bagItem(loadout.armor[slot]) else { return nil }
            return (worn.itemLevel, LootAffixRoll.parse(worn.affixes, definitions: catalog.itemAffixes))
        }
        let wornArmor = WornArmor.contribution(pieces: pieces, h0: catalog.tuning.combat.h0)
        setup.bonusHP = wornArmor.bonusHP
        setup.armor = wornArmor.armor
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

    func heroStats() -> [StatLine] {
        guard let catalog else { return [] }
        let loadout = save.loadouts.first
        func worn(_ id: String?) -> ItemSave? {
            guard let id else { return nil }
            return save.inventory.bag.first { $0.id == id }
        }
        let meleeItem = worn(loadout?.melee)
        let rangedItem = worn(loadout?.ranged)
        let relicItem = worn(loadout?.relics.first)
        let armor = ["helm", "chest", "legs", "boots"].compactMap { slot -> (itemLevel: Int, affixes: [LootAffixRoll])? in
            guard let item = worn(loadout?.armor[slot]) else { return nil }
            return (item.itemLevel, LootAffixRoll.parse(item.affixes, definitions: catalog.itemAffixes))
        }
        let meleeWeapon = meleeItem.flatMap { weapon($0, kind: .melee, catalog: catalog) } ?? base.melee
        let rangedWeapon = rangedItem.flatMap { weapon($0, kind: .ranged, catalog: catalog) } ?? base.ranged
        let innate = meleeWeapon.innate.kind == "critChance" ? meleeWeapon.innate.chance ?? 0 : 0
        return HeroSheet.lines(
            melee: meleeItem.map(asLoot),
            ranged: rangedItem.map(asLoot),
            relicAffixes: relicItem.map { LootAffixRoll.parse($0.affixes, definitions: catalog.itemAffixes) } ?? [],
            armor: armor,
            level: save.hero.level,
            perLevelHP: catalog.tuning.heroHPPerLevel,
            p0: catalog.tuning.combat.p0,
            h0: catalog.tuning.combat.h0,
            baseCrit: catalog.tuning.combat.critChance,
            innateCrit: innate,
            meleeRate: meleeWeapon.attacksPerSecond,
            rangedRate: rangedWeapon.attacksPerSecond
        ).map { StatLine(id: $0.id, name: $0.name, value: $0.value) }
    }

    private func itemDetails(_ item: ItemSave) -> [String] {
        var lines: [String] = []
        let sentence = signatureSentence(item)
        if sentence.isEmpty == false { lines.append(sentence) }
        for roll in asLoot(item).affixes {
            let name = catalog?.itemAffixes.first { $0.id == roll.id }?.name ?? roll.stat
            lines.append(AffixFormat.line(name: name, value: roll.value))
        }
        return lines
    }

    private func signatureSentence(_ item: ItemSave) -> String {
        guard item.rarity == "unique", let catalog else { return "" }
        return catalog.uniques.first { $0.id == item.definition }?.signature ?? ""
    }

    private func signatureLine(_ id: String?) -> [String] {
        guard let id, let sentence = catalog?.uniques.first(where: { $0.id == id })?.signature, sentence.isEmpty == false else { return [] }
        return [sentence]
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
        let worn: LootItem? = {
            guard let loadout, let wornID = equippedID(item.slot, loadout), wornID != item.id,
                  let piece = save.inventory.bag.first(where: { $0.id == wornID }) else { return nil }
            return asLoot(piece)
        }()
        let p0 = catalog?.tuning.combat.p0 ?? 10
        let h0 = catalog?.tuning.combat.h0 ?? 100
        return LootScore.marks(for: item, worn: worn, p0: p0, h0: h0)
    }

    private func refreshLootLines(_ loadout: LoadoutSave) {
        hud.lootLines = hud.lootLines.map { line in
            var line = line
            line.equipped = wearing(line.id, loadout)
            if let item = save.inventory.bag.first(where: { $0.id == line.id }) {
                let marks = arrows(for: asLoot(item), against: loadout)
                line.damageArrow = marks.0
                line.toughnessArrow = marks.1
            }
            return line
        }
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
        let words = name.split(separator: " ")
        return String(words.last ?? Substring(name))
    }

    private func relicDisplay(_ id: String) -> String {
        if let relic = setup.relics.first(where: { $0.id == id }) { return relic.name }
        if let relic = catalog?.relics.first(where: { $0.id == id }) { return relic.name }
        return id
    }

    private func currentTactics() -> [TacticRule] {
        TacticLibrary.resolved(save.loadouts.first?.tactics.map(\.rule) ?? [], fallback: base.tactics)
    }

    private func storeTactics(_ rules: [TacticRule]) {
        guard save.loadouts.isEmpty == false else { return }
        save.loadouts[0].tactics = rules.map(TacticSave.init(rule:))
        saveGame()
    }

    private func smithRNG(extra: UInt64) -> Xoshiro256StarStar {
        var seed = UInt64(max(1, save.runSeed))
        seed &+= extra &* 0x9E3779B97F4A7C15
        return RNGStreams(seed: seed).loot
    }

    private func stableMix(_ text: String) -> UInt64 {
        var hash = FNV64()
        for byte in text.utf8 { hash.add(byte) }
        return hash.value
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

    private func grantProgress() -> String {
        let curve = catalog?.tuning.heroXP ?? CellarFight.tuning.heroXP
        let grant = HeroProgress.apply(
            xp: HeroProgress.riftXP(level: save.hero.level, curve: curve),
            level: save.hero.level, xp: save.hero.xp, glyphPoints: save.hero.bankedGlyphPoints, curve: curve
        )
        save.hero.level = grant.level
        save.hero.xp = grant.xp
        save.hero.bankedGlyphPoints = grant.glyphPoints
        save.syncGlyphBank()
        let gold = catalog?.tuning.riftGold ?? CellarFight.tuning.riftGold
        save.inventory.gold += gold
        let paid = "\(Int(gold.rounded())) Anula"
        if grant.levelsGained > 0 { return "Level \(grant.level) · \(paid)" }
        return paid
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
                        slots: driver.wornSlots(), stats: driver.heroStats(), lines: driver.bagLines(), count: driver.bagLines().count, capacity: InventorySave.bagCapacity,
                        salvageCommons: driver.salvageCommons, salvageRares: driver.salvageRares,
                        close: driver.closeOverlay, equip: driver.equip,
                        toggleCommons: driver.toggleSalvageCommons, toggleRares: driver.toggleSalvageRares
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
                        slots: driver.wornSlots(), stats: driver.heroStats(), salvageCommons: driver.salvageCommons, salvageRares: driver.salvageRares,
                        gold: driver.goldAmount, dust: driver.dustAmount, shards: driver.shardAmount, embers: driver.emberAmount,
                        lines: driver.smithLines(), confirming: driver.pendingSalvage != nil,
                        craftChoices: driver.craftChoices(), craftCaption: driver.craftCaption(), bagFull: driver.bagLines().count >= InventorySave.bagCapacity,
                        note: driver.smithNote,
                        close: driver.closeOverlay, salvage: driver.salvage, confirmSalvage: driver.confirmSalvage,
                        cancelSalvage: driver.cancelSalvage, raise: driver.raiseItem, equip: driver.equip,
                        toggleCommons: driver.toggleSalvageCommons, toggleRares: driver.toggleSalvageRares,
                        reroll: driver.reroll, transmute: driver.transmute, craft: driver.craft
                    )
                }
                if driver.place == .library {
                    LibraryView(
                        lines: driver.tacticLines(), kinds: driver.tacticKinds(), close: driver.closeOverlay,
                        chooseKind: driver.chooseTacticKind, nudge: driver.nudgeTactic
                    )
                }
                if driver.place == .stash {
                    StashView(
                        bag: driver.bagLines(), stash: driver.stashLines(),
                        bagCount: driver.bagLines().count, bagCapacity: InventorySave.bagCapacity,
                        stashCount: driver.stashLines().count, stashCapacity: InventorySave.stashCapacity,
                        note: driver.stashNote, close: driver.closeOverlay,
                        toStash: driver.moveToStash, toBag: driver.moveToBag
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
