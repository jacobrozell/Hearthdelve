import Darwin
import Foundation
import HearthCore

/// One cellar fight on stdin. Each line is a JSON op; each reply is one JSON line.
struct PlaySession {
    private var world: SimWorld

    init(seed: UInt64) {
        world = SimWorld(seed: seed, setup: CellarFight.setup())
    }

    func run() -> Int32 {
        setvbuf(stdout, nil, _IONBF, 0)
        var session = self
        while let line = readLine(strippingNewline: true) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            guard let data = trimmed.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                emit(["ok": false, "error": "bad json"])
                continue
            }
            emit(session.handle(object))
        }
        return 0
    }

    private mutating func handle(_ object: [String: Any]) -> [String: Any] {
        let op = object["op"] as? String ?? "look"
        switch op {
        case "look":
            return ok(render(events: []))
        case "step":
            return ok(step(ticks: number(object, "ticks", 20), commands: []))
        case "play":
            let seconds = min(30, max(1, number(object, "seconds", 5)))
            return ok(step(ticks: seconds * 20, commands: []))
        case "act":
            let button = (object["button"] as? String ?? "").lowercased()
            guard let command = command(button) else {
                return ["ok": false, "error": "button is flask, ward, potion, pause, resume, x1, x2, or x4"]
            }
            return ok(step(ticks: 1, commands: [command]))
        case "restart":
            let seed = u64(object, "seed") ?? (world.seed &+ 1)
            world = SimWorld(seed: seed, setup: CellarFight.setup())
            return ok(render(events: []))
        default:
            return ["ok": false, "error": "unknown op \(op)"]
        }
    }

    private mutating func step(ticks: Int, commands: [SimCommand]) -> String {
        var events: [SimEvent] = []
        var pending = commands
        let cap = min(600, max(1, ticks))
        for _ in 0..<cap {
            let snapshot = world.step(commands: pending)
            pending = []
            events.append(contentsOf: snapshot.events)
            if snapshot.heroDown { break }
        }
        return render(events: events)
    }

    private func render(events: [SimEvent]) -> String {
        let snapshot = world.snapshot()
        let hero = snapshot.entities.first { $0.kind == .hero }
        var lines: [String] = []
        let seconds = Double(snapshot.tick) / 20
        lines.append("tick \(snapshot.tick) · \(fmt(seconds))s · wave \(snapshot.wave) · kills \(snapshot.kills) · seed \(snapshot.seed)\(snapshot.heroDown ? " · DOWN" : "")")
        if let hero {
            lines.append("You \(fmt(hero.x)), \(fmt(hero.y)) · \(Int(snapshot.heroHP.rounded()))/\(Int(snapshot.heroMaxHP.rounded())) · shield \(Int(snapshot.shield.rounded())) · souls \(Int(snapshot.souls.rounded()))")
        }
        let relics = snapshot.relics.enumerated().map { slot, relic in
            let name = slot == 0 ? "Flask" : slot == 1 ? "Ward" : relic.name
            if relic.ready { return "\(name) ready (\(Int(relic.souls)) souls)" }
            return "\(name) \(fmt(relic.cooldown * relicCooldown(slot, snapshot)))s"
        }
        lines.append((relics + ["potion \(snapshot.potionCharges)/\(snapshot.potionMax)"]).joined(separator: " · "))
        let foes = snapshot.entities
            .filter { $0.hostile && $0.hp > 0 && $0.kind != .projectile && $0.kind != .zone }
            .sorted { dist($0, hero) < dist($1, hero) }
            .prefix(8)
        if foes.isEmpty {
            lines.append("No foes.")
        } else if let hero {
            lines.append(foes.map { foe in
                var bit = "\(kindName(foe.kind)) \(fmt(dist(foe, hero))) \(Int(foe.hp.rounded()))/\(Int(foe.maxHP.rounded()))"
                if foe.elite { bit += " elite" }
                if foe.anim == .windup { bit += " windup" }
                return bit
            }.joined(separator: " · "))
        }
        if snapshot.telegraphs.isEmpty == false {
            lines.append(snapshot.telegraphs.prefix(4).map { mark in
                "\(mark.slam ? "slam" : "shot") \(fmt(mark.progress)) at \(fmt(mark.x)), \(fmt(mark.y))"
            }.joined(separator: " · "))
        }
        let notes = events.suffix(8).map(note)
        if notes.isEmpty == false {
            lines.append(notes.joined(separator: " · "))
        }
        return lines.joined(separator: "\n")
    }

    private func relicCooldown(_ slot: Int, _ snapshot: SimSnapshot) -> Double {
        guard slot < snapshot.relics.count else { return 0 }
        let relic = snapshot.relics[slot]
        return relic.id == "lantern_ward" ? 18 : relic.id == "ember_flask" ? 6 : 6
    }

    private func command(_ button: String) -> SimCommand? {
        switch button {
        case "flask": .fireRelic(slot: 0)
        case "ward": .fireRelic(slot: 1)
        case "potion": .drinkPotion
        case "pause": .pause
        case "resume": .resume
        case "x1": .setSpeed(.x1)
        case "x2": .setSpeed(.x2)
        case "x4": .setSpeed(.x4)
        default: nil
        }
    }

    private func note(_ event: SimEvent) -> String {
        switch event {
        case .hit(_, _, _, let amount, let crit, let onHero):
            "hit \(Int(amount.rounded()))\(crit ? " crit" : "")\(onHero ? " on you" : "")"
        case .death(_, _, _, let elite):
            "death\(elite ? " elite" : "")"
        case .burst(_, _, _, let element):
            "\(element) burst"
        case .cleave:
            "cleave"
        case .shield(let amount):
            "shield \(Int(amount.rounded()))"
        case .heal(let amount):
            "heal \(Int(amount.rounded()))"
        case .relic(let slot, _):
            slot == 0 ? "cast Flask" : slot == 1 ? "cast Ward" : "cast relic \(slot)"
        case .potion:
            "drank"
        case .wave(let number, let champions):
            "wave \(number)\(champions ? " champions" : "")"
        case .heroDown:
            "you fell"
        case .invariant(let code):
            code
        }
    }

    private func kindName(_ kind: ActorKind) -> String {
        switch kind {
        case .hero: "hero"
        case .ally: "ally"
        case .fodder: "fodder"
        case .brute: "brute"
        case .shooter: "shooter"
        case .projectile: "shot"
        case .zone: "zone"
        }
    }

    private func dist(_ foe: EntityPose, _ hero: EntityPose?) -> Double {
        guard let hero else { return 0 }
        let dx = foe.x - hero.x
        let dy = foe.y - hero.y
        return (dx * dx + dy * dy).squareRoot()
    }

    private func ok(_ text: String) -> [String: Any] {
        ["ok": true, "text": text]
    }

    private func emit(_ object: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let line = String(data: data, encoding: .utf8) else { return }
        print(line)
    }

    private func number(_ object: [String: Any], _ key: String, _ fallback: Int) -> Int {
        (object[key] as? NSNumber)?.intValue ?? fallback
    }

    private func u64(_ object: [String: Any], _ key: String) -> UInt64? {
        guard let number = object[key] as? NSNumber else { return nil }
        return number.uint64Value
    }

    private func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
