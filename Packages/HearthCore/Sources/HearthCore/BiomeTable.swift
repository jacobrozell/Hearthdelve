public struct BiomeSegment: Codable, Sendable, Equatable {
    public var id: String
    public var fromDepth: Int
    public var bandWidth: Int
    public var echoFromDepth: Int?
    public var order: [String]
}

public struct BiomePlacement: Sendable, Equatable {
    public var biomeID: String
    public var echo: Bool
    public var tableVersion: Int
}

public struct BiomeTable: Codable, Sendable, Equatable {
    public var version: Int
    public var segments: [BiomeSegment]

    public func placement(at depth: Int) -> BiomePlacement? {
        guard let segment = segments.filter({ depth >= $0.fromDepth }).max(by: { $0.fromDepth < $1.fromDepth }) else {
            return nil
        }
        guard segment.bandWidth > 0, segment.order.isEmpty == false else { return nil }
        let echo = segment.echoFromDepth.map { depth >= $0 } ?? false
        let origin = echo ? segment.echoFromDepth ?? segment.fromDepth : segment.fromDepth
        guard depth >= origin else { return nil }
        let index = (depth - origin) / segment.bandWidth
        let biomeID = segment.order[index % segment.order.count]
        return BiomePlacement(biomeID: biomeID, echo: echo, tableVersion: version)
    }
}

public enum BiomeName {
    public static func display(id: String, echo: Bool) -> String {
        let base: String
        switch id {
        case "mossy_cellars": base = "Mossy Cellars"
        case "fungal_hollows": base = "Fungal Hollows"
        case "drowned_library": base = "Drowned Library"
        case "ember_forges": base = "Ember Forges"
        case "starless_vault": base = "Starless Vault"
        default: base = id
        }
        return echo ? "Echo \(base)" : base
    }
}
