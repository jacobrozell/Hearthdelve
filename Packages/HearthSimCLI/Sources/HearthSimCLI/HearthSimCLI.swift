import Foundation
import HearthContent
import HearthCore

@main
enum HearthSimCLI {
    static func main() {
        do {
            exit(try run(Array(CommandLine.arguments.dropFirst())))
        } catch let validation as ContentValidation {
            for issue in validation.issues {
                fputs("\(issue.domain) \(issue.code): \(issue.message)\n", stderr)
            }
            exit(1)
        } catch {
            fputs("\(error)\n", stderr)
            exit(1)
        }
    }

    static func run(_ args: [String]) throws -> Int32 {
        let command = args.first ?? "help"
        switch command {
        case "tick":
            let seed = UInt64(flag(args, "seed") ?? "") ?? 1
            let ticks = Int(flag(args, "ticks") ?? "") ?? 100
            print(RoomRun.run(seed: seed, setup: CellarFight.setup(), ticks: ticks).hash)
        case "curves":
            var curves = BalanceCurves()
            for depth in 0...300 {
                print("\(depth)\t\(curves.requiredBuild.value(at: depth))")
            }
        case "loadouts":
            let catalog = try loadCatalog(args)
            var curves = BalanceCurves()
            for loadout in catalog.loadouts {
                print(loadout.name)
                for depth in loadout.depths {
                    let power = curves.weaponPower(p0: catalog.tuning.combat.p0, itemLevel: depth + 10)
                    let required = curves.requiredBuild.value(at: depth)
                    print("  depth \(depth) ilvl \(depth + 10) parPower \(power) B \(required)")
                }
            }
        case "validate":
            let catalog = try loadCatalog(args)
            print("ok \(catalog.relics.count) relics, \(catalog.uniques.count) uniques, \(catalog.mobs.count) mobs, \(catalog.bestiary().count) cards, content \(catalog.version)")
        case "room":
            return try room(args)
        case "replay":
            return try replay(args)
        case "smoke":
            return try smoke(args)
        case "sweep":
            return try sweep(args)
        case "play":
            return PlaySession(seed: UInt64(flag(args, "seed") ?? "") ?? 1).run()
        default:
            print("""
            hearthsim room --seed 1 --ticks 1200 [--taps 40:flask,300:ward,500:potion] [--record run.json] [--fixture]
            hearthsim replay --recording run.json
            hearthsim smoke [--depths 1,25,50]
            hearthsim sweep --p0 8,10,12 --hp0 12,15,18
            hearthsim play
            hearthsim validate | loadouts | curves | tick --seed 1 --ticks 100
            Content defaults to ./Content; pass --content <dir> to change it.
            """)
            return command == "help" ? 0 : 1
        }
        return 0
    }

    // MARK: Commands

    /// Runs the M0 room headlessly and prints the numbers the fun gate is judged on.
    private static func room(_ args: [String]) throws -> Int32 {
        let seed = UInt64(flag(args, "seed") ?? "") ?? 1
        let ticks = Int(flag(args, "ticks") ?? "") ?? 1200
        let catalog = args.contains("--fixture") ? nil : try loadCatalog(args)
        let setup = try catalog?.m0Setup() ?? CellarFight.setup()
        let taps = try parseTaps(flag(args, "taps"))
        var world = SimWorld(seed: seed, setup: setup)
        let start = world.snapshot()
        while Int(world.tick) < ticks {
            let next = world.tick + 1
            _ = world.step(commands: taps.filter { $0.tick == next }.map(\.command))
        }
        let end = world.snapshot()
        let stats = world.stats
        let fodderHP = start.entities.first { $0.kind == .fodder && $0.elite == false }?.maxHP ?? 0
        print("hash \(end.stateHash)")
        print("seed \(seed) ticks \(end.tick) content \(catalog?.version ?? "fixture")")
        print("formula depth \(setup.depth) heroHP \(fmt(start.heroMaxHP)) fodderHP \(fmt(fodderHP)) p0 \(setup.tuning.combat.p0) hp0 \(setup.tuning.combat.hp0)")
        print("waves \(stats.waves) kills \(end.kills) first_wave_seconds \(stats.firstWaveTick.map { fmt(Double($0) / 20) } ?? "none")")
        for (name, role) in [("fodder", stats.fodder), ("brute", stats.brute), ("shooter", stats.shooter)] {
            print("\(name) kills \(role.kills) mean_hits \(fmt(role.meanHits)) ttk_seconds \(fmt(role.kills == 0 ? 0 : Double(role.lifeTicks) / Double(role.kills) / 20))")
        }
        print("slams landed \(stats.slamsLanded) dodged \(stats.slamsDodged)")
        print("relic_casts \(stats.relicCasts) potions \(stats.potions) tactic_fires \(stats.tacticFires)")
        print("damage dealt \(fmt(stats.damageDealt)) taken \(fmt(stats.damageTaken))")
        print("hero_down \(stats.heroDownTick.map { fmt(Double($0) / 20) + "s" } ?? "no") invariants \(stats.invariants)")
        if let path = flag(args, "record") {
            let recording = world.recording(contentVersion: catalog?.version ?? "fixture")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(recording).write(to: URL(fileURLWithPath: path))
            print("recorded \(path)")
        }
        return stats.invariants == 0 ? 0 : 1
    }

    /// Replays a recording exported from the app (or `room --record`) and checks the end-state hash.
    private static func replay(_ args: [String]) throws -> Int32 {
        guard let path = flag(args, "recording") else {
            fputs("replay needs --recording <file>\n", stderr)
            return 1
        }
        let recording = try JSONDecoder().decode(RunRecording.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        guard recording.simVersion == SimVersion.current else {
            fputs("recording is sim v\(recording.simVersion); this build is v\(SimVersion.current)\n", stderr)
            return 1
        }
        let setup: RoomSetup
        if recording.contentVersion == "fixture" {
            setup = CellarFight.setup()
        } else {
            let catalog = try loadCatalog(args)
            if catalog.version != recording.contentVersion {
                fputs("warning: content \(catalog.version) differs from recorded \(recording.contentVersion)\n", stderr)
            }
            setup = try catalog.m0Setup()
        }
        let hash = recording.replay(setup: setup)
        let match = hash == recording.endHash
        print("replay seed \(recording.seed) ticks \(recording.endTick) inputs \(recording.inputs.count)")
        print("expected \(recording.endHash)")
        print("actual   \(hash)")
        print(match ? "match" : "MISMATCH")
        return match ? 0 : 2
    }

    /// Every Relic and reference loadout in the M0 room at each Depth. Fails on invariants or a Relic that never fires.
    private static func smoke(_ args: [String]) throws -> Int32 {
        let catalog = try loadCatalog(args)
        let depths = (flag(args, "depths") ?? "1,25,50").split(separator: ",").compactMap { Int($0) }
        let ticks = Int(flag(args, "ticks") ?? "") ?? 1200
        var failures = 0
        print("relic\tdepth\tcasts\tkills\tdown\tinvariants")
        for relic in catalog.relics {
            for depth in depths {
                let result = RoomRun.run(seed: 1, setup: try catalog.setup(relic: relic.id, depth: depth), ticks: ticks)
                let bad = result.stats.invariants > 0 || result.stats.relicCasts == 0
                if bad { failures += 1 }
                print("\(relic.id)\t\(depth)\t\(result.stats.relicCasts)\t\(result.kills)\t\(result.stats.heroDownTick.map { "\($0 / 20)s" } ?? "-")\t\(result.stats.invariants)\(bad ? "\tFAIL" : "")")
            }
        }
        print("loadout\tdepth\tcasts\tkills\tdown\tinvariants")
        for loadout in catalog.loadouts {
            for depth in depths {
                let result = RoomRun.run(seed: 1, setup: try catalog.setup(loadout: loadout.id, depth: depth), ticks: ticks)
                let bad = result.stats.invariants > 0
                if bad { failures += 1 }
                print("\(loadout.id)\t\(depth)\t\(result.stats.relicCasts)\t\(result.kills)\t\(result.stats.heroDownTick.map { "\($0 / 20)s" } ?? "-")\t\(result.stats.invariants)\(bad ? "\tFAIL" : "")")
            }
        }
        print(failures == 0 ? "smoke ok" : "smoke failed: \(failures)")
        return failures == 0 ? 0 : 1
    }

    /// Re-runs the M0 room across P0 and HP0 so the fodder-in-two-hits target can be tuned from numbers.
    private static func sweep(_ args: [String]) throws -> Int32 {
        let catalog = try loadCatalog(args)
        let p0s = (flag(args, "p0") ?? "\(catalog.tuning.combat.p0)").split(separator: ",").compactMap { Double($0) }
        let hp0s = (flag(args, "hp0") ?? "\(catalog.tuning.combat.hp0)").split(separator: ",").compactMap { Double($0) }
        let ticks = Int(flag(args, "ticks") ?? "") ?? 2400
        print("p0\thp0\tfodder_hits\tfodder_ttk\tbrute_ttk\twaves\tdown")
        for p0 in p0s {
            for hp0 in hp0s {
                var setup = try catalog.m0Setup()
                setup.tuning.combat.p0 = p0
                setup.tuning.combat.hp0 = hp0
                var hits = 0.0
                var fodder = 0.0
                var brute = 0.0
                var waves = 0
                var downs = 0
                let seeds: [UInt64] = [1, 2, 3]
                for seed in seeds {
                    let stats = RoomRun.run(seed: seed, setup: setup, ticks: ticks).stats
                    hits += stats.fodder.meanHits
                    fodder += stats.fodder.kills == 0 ? 0 : Double(stats.fodder.lifeTicks) / Double(stats.fodder.kills) / 20
                    brute += stats.brute.kills == 0 ? 0 : Double(stats.brute.lifeTicks) / Double(stats.brute.kills) / 20
                    waves += stats.waves
                    if stats.heroDownTick != nil { downs += 1 }
                }
                let n = Double(seeds.count)
                print("\(p0)\t\(hp0)\t\(fmt(hits / n))\t\(fmt(fodder / n))\t\(fmt(brute / n))\t\(fmt(Double(waves) / n))\t\(downs)/\(seeds.count)")
            }
        }
        return 0
    }

    // MARK: Helpers

    private static func loadCatalog(_ args: [String]) throws -> ContentCatalog {
        let directory = contentDirectory(args)
        let catalog = try ContentCatalog.load(from: directory)
        let map = directory.deletingLastPathComponent().appendingPathComponent("docs/art/kenney-map.json")
        var entries: Set<String>?
        if let data = try? Data(contentsOf: map),
           let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let mapped = object["entries"] as? [String: Any] {
            entries = Set(mapped.keys)
        }
        try catalog.validate(artEntries: entries)
        return catalog
    }

    /// `40:flask,300:ward,500:potion` or `40:0` (Relic slot). Ticks are the tick the tap applies on.
    private static func parseTaps(_ text: String?) throws -> [RecordedInput] {
        guard let text, text.isEmpty == false else { return [] }
        return try text.split(separator: ",").map { item in
            let parts = item.split(separator: ":")
            guard parts.count == 2, let tick = UInt64(parts[0]) else { throw ContentError.badReference("bad tap \(item)") }
            switch parts[1] {
            case "flask": return RecordedInput(tick: tick, command: .fireRelic(slot: 0))
            case "ward": return RecordedInput(tick: tick, command: .fireRelic(slot: 1))
            case "potion": return RecordedInput(tick: tick, command: .drinkPotion)
            default:
                guard let slot = Int(parts[1]) else { throw ContentError.badReference("bad tap \(item)") }
                return RecordedInput(tick: tick, command: .fireRelic(slot: slot))
            }
        }
    }

    private static func flag(_ args: [String], _ name: String) -> String? {
        guard let index = args.firstIndex(of: "--\(name)"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    private static func contentDirectory(_ args: [String]) -> URL {
        if let path = flag(args, "content") {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Content")
    }

    private static func fmt(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
