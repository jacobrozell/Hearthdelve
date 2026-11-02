public struct DeskPiece: Equatable, Sendable {
    public var id: String
    public var slot: String
    public var itemLevel: Int
    public var damageArrow: Int
    public var toughnessArrow: Int
    public var equipped: Bool
    public var locked: Bool
    public var favorite: Bool
    public var rarity: String

    public init(
        id: String,
        slot: String,
        itemLevel: Int,
        damageArrow: Int,
        toughnessArrow: Int,
        equipped: Bool,
        locked: Bool,
        favorite: Bool,
        rarity: String
    ) {
        self.id = id
        self.slot = slot
        self.itemLevel = itemLevel
        self.damageArrow = damageArrow
        self.toughnessArrow = toughnessArrow
        self.equipped = equipped
        self.locked = locked
        self.favorite = favorite
        self.rarity = rarity
    }
}

public enum DeskRules {
    /// One id per slot. Not equipped.
    /// Weapons and relics (slot melee, ranged, relic): damageArrow > 0 and toughnessArrow >= 0.
    /// Armor (helm, chest, legs, boots): toughnessArrow > 0 and damageArrow >= 0.
    /// Among matches, highest itemLevel, then lowest id.
    public static func upgradeIDs(_ pieces: [DeskPiece]) -> [String] {
        var best: [String: DeskPiece] = [:]
        var order: [String] = []
        for piece in pieces where isUpgrade(piece) {
            if let current = best[piece.slot] {
                if preferred(piece, over: current) {
                    best[piece.slot] = piece
                }
            } else {
                order.append(piece.slot)
                best[piece.slot] = piece
            }
        }
        return order.compactMap { best[$0]?.id }
    }

    /// Not equipped, not locked, not favorite, rarity != unique.
    /// At least one arrow is negative and neither arrow is positive.
    /// Order is the input order.
    public static func salvageIDs(_ pieces: [DeskPiece]) -> [String] {
        pieces.filter(isSalvage).map(\.id)
    }

    private static func isUpgrade(_ piece: DeskPiece) -> Bool {
        guard !piece.equipped else { return false }
        if GearSlots.isArmor(piece.slot) {
            return piece.toughnessArrow > 0 && piece.damageArrow >= 0
        }
        guard piece.slot == "melee" || piece.slot == "ranged" || piece.slot == "relic" else { return false }
        return piece.damageArrow > 0 && piece.toughnessArrow >= 0
    }

    private static func preferred(_ piece: DeskPiece, over current: DeskPiece) -> Bool {
        if piece.itemLevel != current.itemLevel { return piece.itemLevel > current.itemLevel }
        return piece.id < current.id
    }

    private static func isSalvage(_ piece: DeskPiece) -> Bool {
        guard !piece.equipped, !piece.locked, !piece.favorite, piece.rarity != "unique" else { return false }
        let negative = piece.damageArrow < 0 || piece.toughnessArrow < 0
        let positive = piece.damageArrow > 0 || piece.toughnessArrow > 0
        return negative && !positive
    }
}
