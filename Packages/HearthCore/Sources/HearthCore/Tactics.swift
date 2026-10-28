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
