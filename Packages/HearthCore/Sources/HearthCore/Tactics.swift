public struct TacticCondition: Codable, Sendable, Equatable {
    public var kind: String
    public var value: Double?
    public var count: Int?
    public var tiles: Double?

    public init(kind: String, value: Double? = nil, count: Int? = nil, tiles: Double? = nil) {
        self.kind = kind
        self.value = value
        self.count = count
        self.tiles = tiles
    }
}

public struct TacticAction: Codable, Sendable, Equatable {
    public var kind: String
    public var relic: String?

    public init(kind: String, relic: String? = nil) {
        self.kind = kind
        self.relic = relic
    }
}

public struct TacticRule: Codable, Sendable, Equatable {
    public var condition: TacticCondition
    public var action: TacticAction

    enum CodingKeys: String, CodingKey {
        case condition = "if"
        case action = "then"
    }

    public init(_ condition: TacticCondition, _ action: TacticAction) {
        self.condition = condition
        self.action = action
    }
}

public struct TacticPreset: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var rules: [TacticRule]
}

/// What the evaluator can see. Distances are squared tiles so the tick never takes a square root here.
public struct TacticContext: Sendable, Equatable {
    public var hpFraction: Double
    public var souls: Double
    public var shield: Double
    public var enemyDistances: [Double]
    public var eliteDistances: [Double]
    public var targetDistance: Double?
    public var targetElite: Bool

    public init(hpFraction: Double, souls: Double, shield: Double, enemyDistances: [Double], eliteDistances: [Double], targetDistance: Double?, targetElite: Bool) {
        self.hpFraction = hpFraction
        self.souls = souls
        self.shield = shield
        self.enemyDistances = enemyDistances
        self.eliteDistances = eliteDistances
        self.targetDistance = targetDistance
        self.targetElite = targetElite
    }
}

public enum Tactics {
    public static func holds(_ condition: TacticCondition, _ context: TacticContext) -> Bool {
        switch condition.kind {
        case "always":
            return true
        case "selfHPBelow":
            return context.hpFraction < (condition.value ?? 0)
        case "eliteWithin":
            let reach = square(condition.tiles ?? 0)
            return context.eliteDistances.contains { $0 <= reach }
        case "enemiesWithin":
            let reach = square(condition.tiles ?? 0)
            return context.enemyDistances.filter { $0 <= reach }.count >= (condition.count ?? 1)
        case "soulsAtLeast":
            return context.souls >= (condition.value ?? 0)
        case "targetBeyond":
            guard let distance = context.targetDistance else { return false }
            return distance > square(condition.tiles ?? 0)
        case "targetIsElite":
            return context.targetElite
        case "shieldDown":
            return context.shield <= 0
        default:
            return false
        }
    }

    /// Index of the first rule whose condition holds and whose action is ready. Nil means use the generator attack.
    public static func firstMatch(_ rules: [TacticRule], _ context: TacticContext, ready: (TacticAction) -> Bool) -> Int? {
        for (index, rule) in rules.enumerated() where holds(rule.condition, context) && ready(rule.action) {
            return index
        }
        return nil
    }

    private static func square(_ value: Double) -> Double { value * value }
}

/// The three rules the fight already runs. No fourth slot, no AND/OR, no hold-until.
public enum TacticLibrary {
    public static let slotCount = 3
    public static let kinds = [
        "always", "selfHPBelow", "eliteWithin", "enemiesWithin",
        "soulsAtLeast", "targetBeyond", "targetIsElite", "shieldDown",
    ]

    public static func kindLabel(_ kind: String) -> String {
        switch kind {
        case "always": "Always"
        case "selfHPBelow": "HP"
        case "eliteWithin": "Elite"
        case "enemiesWithin": "Count"
        case "soulsAtLeast": "Charge"
        case "targetBeyond": "Beyond"
        case "targetIsElite": "Target"
        case "shieldDown": "Shield"
        default: kind
        }
    }

    public static func adjusts(_ kind: String) -> Bool {
        switch kind {
        case "selfHPBelow", "eliteWithin", "enemiesWithin", "soulsAtLeast", "targetBeyond": true
        default: false
        }
    }

    /// A condition of a kind the fight already evaluates. Unknown kinds are nil.
    public static func preset(_ kind: String) -> TacticCondition? {
        switch kind {
        case "always": TacticCondition(kind: "always")
        case "selfHPBelow": TacticCondition(kind: "selfHPBelow", value: 0.35)
        case "eliteWithin": TacticCondition(kind: "eliteWithin", tiles: 4)
        case "enemiesWithin": TacticCondition(kind: "enemiesWithin", count: 5, tiles: 2)
        case "soulsAtLeast": TacticCondition(kind: "soulsAtLeast", value: 30)
        case "targetBeyond": TacticCondition(kind: "targetBeyond", tiles: 3)
        case "targetIsElite": TacticCondition(kind: "targetIsElite")
        case "shieldDown": TacticCondition(kind: "shieldDown")
        default: nil
        }
    }

    /// Saved rules when there are three known kinds. Otherwise the fight's prefilled three.
    public static func resolved(_ rules: [TacticRule], fallback: [TacticRule]) -> [TacticRule] {
        if rules.count >= slotCount {
            let head = Array(rules.prefix(slotCount))
            if head.allSatisfy({ kinds.contains($0.condition.kind) }) { return head }
        }
        return Array(fallback.prefix(slotCount))
    }

    /// Replaces one condition and leaves that rule's action alone. A fourth slot is refused.
    public static func replace(_ rules: [TacticRule], index: Int, condition: TacticCondition, fallback: [TacticRule]) -> [TacticRule]? {
        guard kinds.contains(condition.kind) else { return nil }
        var next = resolved(rules, fallback: fallback)
        guard next.indices.contains(index) else { return nil }
        next[index] = TacticRule(condition, next[index].action)
        return next
    }

    /// Steps the number on one condition. Kinds with no number stay as they are.
    public static func nudge(_ rules: [TacticRule], index: Int, delta: Int, fallback: [TacticRule]) -> [TacticRule]? {
        var next = resolved(rules, fallback: fallback)
        guard next.indices.contains(index) else { return nil }
        var condition = next[index].condition
        switch condition.kind {
        case "selfHPBelow":
            let stepped = ((condition.value ?? 0.35) + Double(delta) * 0.05) * 100
            condition.value = min(0.95, max(0.05, stepped.rounded() / 100))
        case "eliteWithin", "targetBeyond":
            condition.tiles = min(12, max(1, (condition.tiles ?? 4) + Double(delta)))
        case "enemiesWithin":
            condition.count = min(9, max(1, (condition.count ?? 1) + delta))
        case "soulsAtLeast":
            condition.value = min(100, max(0, (condition.value ?? 0) + Double(delta) * 10))
        default:
            break
        }
        next[index] = TacticRule(condition, next[index].action)
        return next
    }

    /// The same words the rift prints for a condition.
    public static func caption(_ condition: TacticCondition) -> String {
        let tiles = condition.tiles.map { $0.formatted() } ?? "0"
        switch condition.kind {
        case "always": return "always"
        case "selfHPBelow": return "HP below \(Int(((condition.value ?? 0) * 100).rounded()))%"
        case "eliteWithin": return "elite within \(tiles)"
        case "enemiesWithin": return "\(condition.count ?? 1)+ within \(tiles)"
        case "soulsAtLeast": return "Charge ≥ \(Int((condition.value ?? 0).rounded()))"
        case "targetBeyond": return "target beyond \(tiles)"
        case "targetIsElite": return "target is elite"
        case "shieldDown": return "no shield"
        default: return condition.kind
        }
    }

    public static func actionName(_ action: TacticAction, relicName: (String) -> String) -> String {
        switch action.kind {
        case "potion": return "Potion"
        case "relic":
            if let relic = action.relic { return relicName(relic) }
            return "Relic"
        default: return action.kind
        }
    }

    public static func line(index: Int, rule: TacticRule, relicName: (String) -> String) -> String {
        "Tactic \(index + 1): \(caption(rule.condition)) → \(actionName(rule.action, relicName: relicName))"
    }
}
