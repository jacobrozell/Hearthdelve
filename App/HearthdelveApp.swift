import SpriteKit
import SwiftUI
import HearthContent
import HearthCore
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

/// Owns the sim and feeds the scene at 20 Hz. At 2× and 4× each wall tick runs 2 or 4 sim ticks.
@MainActor
@Observable
final class RiftDriver {
    let scene: RiftScene
    var hud = RoomHUDState()
    var note: String?

    private let setup: RoomSetup
    private let contentVersion: String
    private var seed: UInt64
    private var sim: SimActor
    private var speed = SimSpeed.x1
    private var paused = false
    private var loop: Task<Void, Never>?
    private var fellAt: UInt64?
    private var savedThisRun = false
    private var tacticUntil: UInt64 = 0

    init() {
        let content = Bundle.main.url(forResource: "Content", withExtension: nil)
        var loaded: (RoomSetup, String)?
        var problem: String?
        if let content {
            do {
                let catalog = try ContentCatalog.load(from: content)
                #if DEBUG
                try catalog.validate()
                #endif
                loaded = (try catalog.m0Setup(), catalog.version)
            } catch {
                problem = "Content failed to load; using the built-in cellar. \(error)"
            }
        }
        self.setup = loaded?.0 ?? CellarFight.setup()
        contentVersion = loaded?.1 ?? "fixture"
        note = problem
        let launchSeed = UserDefaults.standard.integer(forKey: "seed")
        let first: UInt64 = launchSeed > 0 ? UInt64(launchSeed) : 1
        let setup = self.setup
        seed = first
        sim = SimActor(seed: first, setup: setup)
        scene = RiftScene(size: CGSize(width: 390, height: 844))
        scene.load(room: setup.room)
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
        #if DEBUG
        hud.debug = "seed \(snapshot.seed) · tick \(snapshot.tick) · \(snapshot.entities.count) ents · content \(contentVersion.prefix(6))"
        #endif
        if snapshot.heroDown {
            let fell = fellAt ?? snapshot.tick
            fellAt = fell
            if savedThisRun == false {
                savedThisRun = true
                Task { await saveRecording() }
            }
            // Keep the watch going: a new run starts on its own a few seconds after the fall.
            if snapshot.paused == false, snapshot.tick >= fell + UInt64(5 * 20 * speed.rawValue) {
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

    func newRun() {
        seed &+= 1
        sim = SimActor(seed: seed, setup: setup)
        paused = false
        fellAt = nil
        savedThisRun = false
        tacticUntil = 0
        hud.tactic = nil
        scene.load(room: setup.room)
        let next = speed
        Task { await sim.enqueue(.setSpeed(next)) }
    }

    /// Writes the run to Documents/recordings so `hearthsim replay --recording` can reproduce it on a Mac.
    func saveRecording() async {
        let recording = await sim.recording(contentVersion: contentVersion)
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
}

struct RiftHost: View {
    @State private var driver = RiftDriver()

    var body: some View {
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
                    newRun: driver.newRun,
                    saveRecording: { Task { await driver.saveRecording() } }
                ),
                note: driver.note
            )
        }
        .background(HearthPalette.ink)
        .onAppear { driver.start() }
    }

    private var debugOptions: SpriteView.DebugOptions {
        #if DEBUG
        [.showsFPS, .showsNodeCount]
        #else
        []
        #endif
    }
}
