/// The hand-built cellar the app boots into. Tests use the same room so a golden seed matches the phone.
public enum CellarFight {
    public static let tuning = Tuning(
        proposal: true,
        combat: CombatTuning(p0: 10, hp0: 15, dmg0: 8, h0: 160, critChance: 0.05, critDamage: 0.5),
        heroXP: XPCurveTuning(base: 100, growth: 1.08),
        paragonXP: XPCurveTuning(base: 1000, growth: 1.02),
        riftGold: 25,
        heroHPPerLevel: 8,
        smith: SmithTuning(
            commonDust: 5, rareShards: 2, uniqueEmbers: 1, raiseDust: 8, raiseGold: 10, raiseGrowth: 1.12,
            rerollRareShards: 4, rerollUniqueEmbers: 2, craftRareShards: 8, transmuteEmbers: 12
        ),
        soulRegenPerSecond: 1,
        room: RoomTuning(
            heroTilesPerSecond: 3.2, heroReactionSeconds: 0.25, swapTiles: 3,
            fodderTilesPerSecond: 2, bruteTilesPerSecond: 1.2, rangedTilesPerSecond: 1.6,
            projectileTilesPerSecond: 10, boltTilesPerSecond: 6,
            fodderAttackSeconds: 2, bruteRecoverySeconds: 1.5, rangedAttackSeconds: 1.8,
            bruteHitPoints: 4, rangedHitPoints: 2, eliteHitPoints: 3, bruteDamage: 2.2, slamRadius: 1.2,
            potionHeal: 0.55, potionCooldown: 8, potionCharges: 3, potionRefillPerWave: 1,
            startingSouls: 100, waveDelaySeconds: 2, championEvery: 3
        )
    )

    public static let room = RoomTemplate.ascii([
        "################",
        "#..S....S....S.#",
        "#..............#",
        "#S............S#",
        "#....#....#....#",
        "#....#....#....#",
        "#..............#",
        "#..............#",
        "#..............#",
        "#..............#",
        "#....#....#....#",
        "#....#....#....#",
        "#..............#",
        "#..............#",
        "#......H.......#",
        "################",
    ])

    public static let sword = WeaponDefinition(id: "sword", name: "Sword", kind: .melee, rangeTiles: 1, attacksPerSecond: 1, innate: InnateSpec(kind: "cleaveEvery", hits: 3))
    public static let bow = WeaponDefinition(id: "bow", name: "Bow", kind: .ranged, rangeTiles: 8, attacksPerSecond: 0.9, innate: InnateSpec(kind: "chargedEvery", shots: 3, bonus: 1))
    public static let flask = RelicDefinition(id: "ember_flask", name: "Ember Flask", souls: 30, cooldown: 6, tags: ["fire"], opcodes: [
        OpcodeSpec(op: "damage", coefficient: 3.8, element: "fire", radius: 3),
        OpcodeSpec(op: "zone", coefficient: 0.4, element: "fire", radius: 3, duration: 3),
    ])
    public static let ward = RelicDefinition(id: "lantern_ward", name: "Lantern Ward", souls: 40, cooldown: 18, tags: ["radiant"], opcodes: [
        OpcodeSpec(op: "shield", duration: 6, fraction: 0.2),
    ])
    public static let tactics = [
        TacticRule(TacticCondition(kind: "selfHPBelow", value: 0.35), TacticAction(kind: "potion")),
        TacticRule(TacticCondition(kind: "eliteWithin", tiles: 4), TacticAction(kind: "relic", relic: "lantern_ward")),
        TacticRule(TacticCondition(kind: "enemiesWithin", count: 5, tiles: 2), TacticAction(kind: "relic", relic: "ember_flask")),
    ]

    public static func mob(_ id: String, _ role: String, telegraph: Double? = nil) -> MobDefinition {
        MobDefinition(id: id, name: id, family: "test", role: role, biome: "mossy_cellars", sprite: "creature.\(id)", telegraphSeconds: telegraph)
    }

    public static func setup(relics: [RelicDefinition] = [flask, ward], tactics: [TacticRule] = tactics, signatures: [SignatureSpec] = [], melee: WeaponDefinition = sword) -> RoomSetup {
        RoomSetup(
            room: room, tuning: tuning, depth: 1, melee: melee, ranged: bow, relics: relics, tactics: tactics,
            signatures: signatures, fodder: mob("slime", "fodder"), brute: mob("cyclops", "brute", telegraph: 1), shooter: mob("bat", "ranged")
        )
    }
}
