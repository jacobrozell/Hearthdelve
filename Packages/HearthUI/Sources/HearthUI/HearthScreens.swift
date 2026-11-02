import SwiftUI

/// Depth, mode, biome, and the predicted band. Start is refused when a Deep Rift would pass the free limit.
public struct RiftGateView: View {
    public var depth: Int
    public var bestDepth: Int
    public var deepRift: Bool
    public var biome: String
    public var band: String
    public var blocked: Bool
    public var mossyNote: Bool
    public var lower: () -> Void
    public var raise: () -> Void
    public var chooseDelve: () -> Void
    public var chooseDeepRift: () -> Void
    public var start: () -> Void
    public var back: () -> Void

    public init(
        depth: Int, bestDepth: Int, deepRift: Bool, biome: String, band: String, blocked: Bool, mossyNote: Bool,
        lower: @escaping () -> Void, raise: @escaping () -> Void, chooseDelve: @escaping () -> Void,
        chooseDeepRift: @escaping () -> Void, start: @escaping () -> Void, back: @escaping () -> Void
    ) {
        self.depth = depth
        self.bestDepth = bestDepth
        self.deepRift = deepRift
        self.biome = biome
        self.band = band
        self.blocked = blocked
        self.mossyNote = mossyNote
        self.lower = lower
        self.raise = raise
        self.chooseDelve = chooseDelve
        self.chooseDeepRift = chooseDeepRift
        self.start = start
        self.back = back
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("The well")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 24)
            HStack(spacing: 12) {
                step("−", label: "Lower depth", enabled: depth > 1, action: lower)
                VStack(spacing: 0) {
                    Text("Depth")
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.parchment.opacity(0.8))
                    Text("\(depth)")
                        .font(HearthFont.pixel(36))
                        .foregroundStyle(HearthPalette.parchment)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Depth")
                .accessibilityValue("\(depth) of \(bestDepth)")
                step("+", label: "Raise depth", enabled: depth < bestDepth, action: raise)
            }
            HStack(spacing: 10) {
                modeButton("Delve", on: deepRift == false, action: chooseDelve)
                modeButton("Deep Rift", on: deepRift, action: chooseDeepRift)
            }
            .padding(.horizontal, 24)
            VStack(spacing: 6) {
                labeled("Biome", biome)
                labeled("Difficulty", band)
                Text(deepRift ? "The Lantern is burning. A clear at your best Depth can advance it." : "A Delve leaves the Lantern unlit, so Depth stays.")
                    .font(HearthFont.pixel(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(HearthPalette.parchment.opacity(0.85))
                if mossyNote {
                    Text("These floors are still the Mossy Cellars.")
                        .font(HearthFont.pixel(16))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(HearthPalette.parchment.opacity(0.7))
                }
                if blocked {
                    Text("The way deeper is closed.")
                        .font(HearthFont.pixel(18))
                        .foregroundStyle(HearthPalette.amber)
                        .accessibilityLabel("The way deeper is closed.")
                }
            }
            .padding(.horizontal, 24)
            Button(action: start) {
                Text("Start")
                    .font(HearthFont.pixel(24))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: 4).fill(blocked ? HearthPalette.parchment.opacity(0.35) : HearthPalette.amber))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(blocked)
            .accessibilityLabel("Start")
            .padding(.horizontal, 28)
            Button("Back", action: back)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }

    private func labeled(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(value)
        }
        .font(HearthFont.pixel(20))
        .foregroundStyle(HearthPalette.parchment)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue(value)
    }

    private func step(_ title: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.ink)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 4).fill(enabled ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
        .accessibilityLabel(label)
    }

    private func modeButton(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(18))
                .foregroundStyle(on ? HearthPalette.ink : HearthPalette.parchment)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(on ? HearthPalette.amber : HearthPalette.ink))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(HearthPalette.amber.opacity(0.7), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

public struct SmithAffix: Equatable, Sendable, Identifiable {
    public var index: Int
    public var name: String
    public var detail: String
    public var id: Int { index }

    public init(index: Int, name: String, detail: String) {
        self.index = index
        self.name = name
        self.detail = detail
    }
}

public struct StatLine: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var value: String

    public init(id: String, name: String, value: String) {
        self.id = id
        self.name = name
        self.value = value
    }
}

public struct CraftChoice: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var slot: String
    public var slotName: String

    public init(id: String, name: String, slot: String, slotName: String) {
        self.id = id
        self.name = name
        self.slot = slot
        self.slotName = slotName
    }
}

public struct SmithLine: Equatable, Sendable, Identifiable {
    public var id: String
    public var text: String
    public var slot: String
    public var slotName: String
    public var damageArrow: Int
    public var toughnessArrow: Int
    public var equipped: Bool
    public var canSalvage: Bool
    public var canRaise: Bool
    public var raiseCaption: String
    public var affixes: [SmithAffix]
    public var canReroll: Bool
    public var rerollCaption: String
    public var canTransmute: Bool
    public var transmuteCaption: String
    public var signature: String
    public var isNew: Bool
    public var locked: Bool
    public var favorite: Bool

    public init(
        id: String, text: String, slot: String, slotName: String, damageArrow: Int, toughnessArrow: Int,
        equipped: Bool, canSalvage: Bool, canRaise: Bool, raiseCaption: String,
        affixes: [SmithAffix], canReroll: Bool, rerollCaption: String, canTransmute: Bool, transmuteCaption: String,
        signature: String, isNew: Bool = false, locked: Bool = false, favorite: Bool = false
    ) {
        self.id = id
        self.text = text
        self.slot = slot
        self.slotName = slotName
        self.damageArrow = damageArrow
        self.toughnessArrow = toughnessArrow
        self.equipped = equipped
        self.canSalvage = canSalvage
        self.canRaise = canRaise
        self.raiseCaption = raiseCaption
        self.affixes = affixes
        self.canReroll = canReroll
        self.rerollCaption = rerollCaption
        self.canTransmute = canTransmute
        self.transmuteCaption = transmuteCaption
        self.signature = signature
        self.isNew = isNew
        self.locked = locked
        self.favorite = favorite
    }
}

enum SlotGroups {
    static func loot(_ lines: [LootLine]) -> [(name: String, lines: [LootLine])] {
        grouped(lines, slot: \.slot, name: \.slotName)
    }

    static func smith(_ lines: [SmithLine]) -> [(name: String, lines: [SmithLine])] {
        grouped(lines, slot: \.slot, name: \.slotName)
    }

    private static func grouped<T>(_ lines: [T], slot: (T) -> String, name: (T) -> String) -> [(name: String, lines: [T])] {
        let order = ["melee", "ranged", "relic", "helm", "chest", "legs", "boots"]
        var seen: [String] = []
        for line in lines {
            let id = slot(line)
            if seen.contains(id) == false { seen.append(id) }
        }
        seen.sort { left, right in
            (order.firstIndex(of: left) ?? order.count) < (order.firstIndex(of: right) ?? order.count)
        }
        return seen.map { id in
            let rows = lines.filter { slot($0) == id }
            return (rows.first.map(name) ?? id, rows)
        }
    }
}

struct SalvageRules: View {
    var commons: Bool
    var rares: Bool
    var caption: String?
    var undoTitle: String?
    var note: String? = nil
    var toggleCommons: () -> Void
    var toggleRares: () -> Void
    var undo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Auto-salvage")
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                rule("Commons", on: commons, action: toggleCommons)
                rule("Rares", on: rares, action: toggleRares)
            }
            if let caption {
                Text(caption)
                    .font(HearthFont.pixel(14))
                    .foregroundStyle(HearthPalette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(caption)
            }
            if let undoTitle {
                Button(undoTitle, action: undo)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.parchment))
                    .buttonStyle(.plain)
                    .accessibilityLabel(undoTitle)
            }
            if let note {
                Text(note)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(note)
            }
        }
    }

    private func rule(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(on ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Auto-salvage \(title)")
        .accessibilityValue(on ? "On" : "Off")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

struct ItemFacts: View {
    var title: String
    var details: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                Text(detail)
                    .font(HearthFont.pixel(14))
                    .foregroundStyle(HearthPalette.parchment.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(detail)
            }
        }
    }
}

struct StatBlock: View {
    var lines: [StatLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("You")
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .accessibilityAddTraits(.isHeader)
            Text("A weapon affix raises that weapon's power.")
                .font(HearthFont.pixel(14))
                .foregroundStyle(HearthPalette.parchment.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            ForEach(lines) { line in
                HStack(spacing: 8) {
                    Text(line.name)
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.amber)
                        .frame(width: 128, alignment: .leading)
                    Text(line.value)
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.parchment)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(line.name)
                .accessibilityValue(line.value)
            }
        }
    }
}

struct WornSlots: View {
    var slots: [GearSlotLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Worn")
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .accessibilityAddTraits(.isHeader)
            ForEach(slots) { slot in
                HStack(spacing: 8) {
                    Text(slot.name)
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.amber)
                        .frame(width: 72, alignment: .leading)
                    Text(slot.wearing)
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.parchment)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(slot.name)
                .accessibilityValue(slot.wearing)
            }
        }
    }
}

/// Level, Anula, and materials over the meadow. The Bag button is the only control in this bar.
public struct VillageChrome: View {
    public var level: Int
    public var gold: Int
    public var dust: Int
    public var shards: Int
    public var embers: Int
    public var bestDepth: Int
    public var openBag: () -> Void

    public init(level: Int, gold: Int, dust: Int, shards: Int, embers: Int, bestDepth: Int, openBag: @escaping () -> Void) {
        self.level = level
        self.gold = gold
        self.dust = dust
        self.shards = shards
        self.embers = embers
        self.bestDepth = bestDepth
        self.openBag = openBag
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(level)")
                    .accessibilityLabel("Level")
                    .accessibilityValue("\(level)")
                Text("Anula \(gold)")
                    .accessibilityLabel("Anula")
                    .accessibilityValue("\(gold)")
                Text("Dust \(dust)  Facets \(shards)  Echoes \(embers)")
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Materials")
                    .accessibilityValue("Dust \(dust), Facets \(shards), Echoes \(embers)")
                Text("Best Depth \(bestDepth)")
                    .accessibilityLabel("Best Depth")
                    .accessibilityValue("\(bestDepth)")
            }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.ink)
            .allowsHitTesting(false)
            Spacer(minLength: 0)
            Button(action: openBag) {
                Text("Bag")
                    .font(HearthFont.pixel(18))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(minWidth: 64, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bag")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HearthPalette.parchment.opacity(0.92))
    }
}

/// Farm, Push, and Change. The host places this on the hamlet. Farm and Push appear only when a title is set.
public struct HamletBar: View {
    public var farmTitle: String?
    public var pushTitle: String?
    public var farm: () -> Void
    public var push: () -> Void
    public var change: () -> Void

    public init(
        farmTitle: String?, pushTitle: String?,
        farm: @escaping () -> Void, push: @escaping () -> Void, change: @escaping () -> Void
    ) {
        self.farmTitle = farmTitle
        self.pushTitle = pushTitle
        self.farm = farm
        self.push = push
        self.change = change
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let farmTitle {
                filled(farmTitle, action: farm)
            }
            if let pushTitle {
                filled(pushTitle, action: push)
            }
            Button("Change", action: change)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.ink)
                .frame(minWidth: 96, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.parchment))
                .accessibilityLabel("Change")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HearthPalette.parchment.opacity(0.92))
    }

    private func filled(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct BagFilters: View {
    var filter: String
    var choose: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            chip("all", "All")
            chip("upgrades", "Upgrades")
            chip("rest", "Rest")
        }
    }

    private func chip(_ id: String, _ title: String) -> some View {
        let on = filter == id
        return Button { choose(id) } label: {
            Text(title)
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(on ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(on ? "On" : "Off")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

struct KeepMarks: View {
    var locked: Bool
    var favorite: Bool
    var lock: () -> Void
    var favor: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            mark(locked ? "Locked" : "Lock", on: locked, action: lock, label: locked ? "Locked" : "Lock")
            mark(favorite ? "Favorited" : "Favorite", on: favorite, action: favor, label: favorite ? "Favorited" : "Favorite")
        }
    }

    private func mark(_ title: String, on: Bool, action: @escaping () -> Void, label: String) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(on ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

public struct BulkSalvageAsk: View {
    public var sentence: String
    public var confirm: () -> Void
    public var cancel: () -> Void

    public init(sentence: String, confirm: @escaping () -> Void, cancel: @escaping () -> Void) {
        self.sentence = sentence
        self.confirm = confirm
        self.cancel = cancel
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Break these down?")
                    .font(HearthFont.pixel(22))
                    .foregroundStyle(HearthPalette.amber)
                    .multilineTextAlignment(.center)
                Text(sentence)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Salvage", action: confirm)
                    .font(HearthFont.pixel(18))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
                    .buttonStyle(.plain)
                    .accessibilityLabel("Salvage")
                Button("Not now", action: cancel)
                    .font(HearthFont.pixel(18))
                    .foregroundStyle(HearthPalette.amber)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Not now")
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 4).fill(HearthPalette.ink))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.amber.opacity(0.6), lineWidth: 2))
            .padding(24)
        }
    }
}

public struct BagView: View {
    public var slots: [GearSlotLine]
    public var stats: [StatLine]
    public var lines: [LootLine]
    public var count: Int
    public var capacity: Int
    public var bagEmpty: Bool
    public var filter: String
    public var salvageCommons: Bool
    public var salvageRares: Bool
    public var salvagePreview: String?
    public var undoTitle: String?
    public var close: () -> Void
    public var equip: (String) -> Void
    public var chooseFilter: (String) -> Void
    public var toggleLock: (String) -> Void
    public var toggleFavorite: (String) -> Void
    public var toggleCommons: () -> Void
    public var toggleRares: () -> Void
    public var undo: () -> Void
    public var work: ((String) -> Void)?
    public var note: String?

    public init(
        slots: [GearSlotLine], stats: [StatLine], lines: [LootLine], count: Int, capacity: Int, bagEmpty: Bool, filter: String,
        salvageCommons: Bool, salvageRares: Bool, salvagePreview: String?, undoTitle: String?,
        close: @escaping () -> Void, equip: @escaping (String) -> Void, chooseFilter: @escaping (String) -> Void,
        toggleLock: @escaping (String) -> Void, toggleFavorite: @escaping (String) -> Void,
        toggleCommons: @escaping () -> Void, toggleRares: @escaping () -> Void, undo: @escaping () -> Void,
        work: ((String) -> Void)? = nil, note: String? = nil
    ) {
        self.slots = slots
        self.stats = stats
        self.lines = lines
        self.count = count
        self.capacity = capacity
        self.bagEmpty = bagEmpty
        self.filter = filter
        self.salvageCommons = salvageCommons
        self.salvageRares = salvageRares
        self.salvagePreview = salvagePreview
        self.undoTitle = undoTitle
        self.close = close
        self.equip = equip
        self.chooseFilter = chooseFilter
        self.toggleLock = toggleLock
        self.toggleFavorite = toggleFavorite
        self.toggleCommons = toggleCommons
        self.toggleRares = toggleRares
        self.undo = undo
        self.work = work
        self.note = note
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("Bag \(count)/\(capacity)")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 24)
                .accessibilityLabel("Bag")
                .accessibilityValue("\(count) of \(capacity)")
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    WornSlots(slots: slots)
                        .padding(.horizontal, 16)
                    if stats.isEmpty == false {
                        StatBlock(lines: stats)
                            .padding(.horizontal, 16)
                    }
                    BagFilters(filter: filter, choose: chooseFilter)
                        .padding(.horizontal, 16)
                    SalvageRules(
                        commons: salvageCommons, rares: salvageRares, caption: salvagePreview, undoTitle: undoTitle,
                        note: note, toggleCommons: toggleCommons, toggleRares: toggleRares, undo: undo
                    )
                        .padding(.horizontal, 16)
                    if lines.isEmpty {
                        Text(bagEmpty ? "Nothing in the bag yet." : emptyFilter)
                            .font(HearthFont.pixel(16))
                            .foregroundStyle(HearthPalette.parchment)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(SlotGroups.loot(lines), id: \.name) { group in
                            Text(group.name)
                                .font(HearthFont.pixel(18))
                                .foregroundStyle(HearthPalette.amber)
                                .padding(.horizontal, 16)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(group.lines) { line in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top, spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            if line.isNew {
                                                Text("New")
                                                    .font(HearthFont.pixel(14))
                                                    .foregroundStyle(HearthPalette.amber)
                                                    .accessibilityLabel("New")
                                            }
                                            ItemFacts(title: line.text, details: line.details)
                                        }
                                        if line.equipped == false {
                                            ScoreMark(arrow: line.damageArrow, name: "damage")
                                            ScoreMark(arrow: line.toughnessArrow, name: "toughness")
                                        }
                                        if let work {
                                            smithButton(line, work: work)
                                        }
                                        equipButton(line)
                                    }
                                    KeepMarks(locked: line.locked, favorite: line.favorite, lock: { toggleLock(line.id) }, favor: { toggleFavorite(line.id) })
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .accessibilityLabel("Close")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }

    private func equipButton(_ line: LootLine) -> some View {
        Button(line.equipped ? "Equipped" : "Equip") { equip(line.id) }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.ink)
            .frame(minWidth: 88, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 3).fill(line.equipped ? HearthPalette.parchment.opacity(0.4) : HearthPalette.amber))
            .buttonStyle(.plain)
            .disabled(line.equipped)
            .accessibilityLabel(line.equipped ? "Equipped" : "Equip \(line.text)")
    }

    private func smithButton(_ line: LootLine, work: @escaping (String) -> Void) -> some View {
        Button("Smith") { work(line.id) }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.ink)
            .frame(minWidth: 88, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
            .buttonStyle(.plain)
            .accessibilityLabel("Smith \(line.text)")
    }

    private var emptyFilter: String {
        filter == "upgrades" ? "No upgrades in the bag." : "Nothing left to sort out."
    }
}

public struct SmithView: View {
    public var slots: [GearSlotLine]
    public var stats: [StatLine]
    public var salvageCommons: Bool
    public var salvageRares: Bool
    public var salvagePreview: String?
    public var undoTitle: String?
    public var toggleCommons: () -> Void
    public var toggleRares: () -> Void
    public var undo: () -> Void
    public var toggleLock: (String) -> Void
    public var toggleFavorite: (String) -> Void
    public var gold: Int
    public var dust: Int
    public var shards: Int
    public var embers: Int
    public var lines: [SmithLine]
    public var confirming: Bool
    public var craftChoices: [CraftChoice]
    public var craftCaption: String
    public var bagFull: Bool
    public var note: String?
    public var focusID: String?
    public var showsBag: Bool
    public var close: () -> Void
    public var salvage: (String) -> Void
    public var confirmSalvage: () -> Void
    public var cancelSalvage: () -> Void
    public var raise: (String) -> Void
    public var equip: (String) -> Void
    public var reroll: (String, Int) -> Void
    public var transmute: (String) -> Void
    public var craft: (String, String) -> Void

    public init(
        slots: [GearSlotLine], stats: [StatLine], salvageCommons: Bool, salvageRares: Bool, salvagePreview: String?, undoTitle: String?,
        gold: Int, dust: Int, shards: Int, embers: Int, lines: [SmithLine], confirming: Bool,
        craftChoices: [CraftChoice], craftCaption: String, bagFull: Bool, note: String?,
        close: @escaping () -> Void, salvage: @escaping (String) -> Void, confirmSalvage: @escaping () -> Void,
        cancelSalvage: @escaping () -> Void, raise: @escaping (String) -> Void, equip: @escaping (String) -> Void,
        toggleCommons: @escaping () -> Void, toggleRares: @escaping () -> Void, undo: @escaping () -> Void,
        toggleLock: @escaping (String) -> Void, toggleFavorite: @escaping (String) -> Void,
        reroll: @escaping (String, Int) -> Void, transmute: @escaping (String) -> Void, craft: @escaping (String, String) -> Void,
        focusID: String? = nil, showsBag: Bool = true
    ) {
        self.slots = slots
        self.stats = stats
        self.salvageCommons = salvageCommons
        self.salvageRares = salvageRares
        self.salvagePreview = salvagePreview
        self.undoTitle = undoTitle
        self.toggleCommons = toggleCommons
        self.toggleRares = toggleRares
        self.undo = undo
        self.toggleLock = toggleLock
        self.toggleFavorite = toggleFavorite
        self.gold = gold
        self.dust = dust
        self.shards = shards
        self.embers = embers
        self.lines = lines
        self.confirming = confirming
        self.craftChoices = craftChoices
        self.craftCaption = craftCaption
        self.bagFull = bagFull
        self.note = note
        self.focusID = focusID
        self.showsBag = showsBag
        self.close = close
        self.salvage = salvage
        self.confirmSalvage = confirmSalvage
        self.cancelSalvage = cancelSalvage
        self.raise = raise
        self.equip = equip
        self.reroll = reroll
        self.transmute = transmute
        self.craft = craft
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text("Blacksmith")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 20)
                .accessibilityLabel("Blacksmith")
            Text("Anula \(gold)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Anula")
                .accessibilityValue("\(gold)")
            Text("Dust \(dust)   Facets \(shards)   Echoes \(embers)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Materials")
                .accessibilityValue("Dust \(dust), Facets \(shards), Echoes \(embers)")
            if let note {
                Text(note)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(note)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    smithList
                    CraftBar(choices: craftChoices, caption: craftCaption, bagFull: bagFull, craft: craft)
                    WornSlots(slots: slots)
                    if stats.isEmpty == false {
                        StatBlock(lines: stats)
                    }
                    SalvageRules(
                        commons: salvageCommons, rares: salvageRares, caption: salvagePreview, undoTitle: undoTitle,
                        toggleCommons: toggleCommons, toggleRares: toggleRares, undo: undo
                    )
                }
                .padding(.horizontal, 16)
            }
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .padding(.bottom, 12)
                .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
        .overlay {
            if confirming {
                ZStack {
                    Color.black.opacity(0.62).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("Salvage this Unique?")
                            .font(HearthFont.pixel(22))
                            .foregroundStyle(HearthPalette.amber)
                            .multilineTextAlignment(.center)
                        Text("It becomes Echoes, and its signature is written in the Codex.")
                            .font(HearthFont.pixel(16))
                            .foregroundStyle(HearthPalette.parchment)
                            .multilineTextAlignment(.center)
                        Button("Salvage", action: confirmSalvage)
                            .font(HearthFont.pixel(18))
                            .foregroundStyle(HearthPalette.ink)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
                            .buttonStyle(.plain)
                            .accessibilityLabel("Salvage")
                        Button("Keep", action: cancelSalvage)
                            .font(HearthFont.pixel(18))
                            .foregroundStyle(HearthPalette.amber)
                            .frame(minHeight: 44)
                            .accessibilityLabel("Keep")
                    }
                    .padding(22)
                    .background(RoundedRectangle(cornerRadius: 4).fill(HearthPalette.ink))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.amber.opacity(0.6), lineWidth: 2))
                    .padding(24)
                }
            }
        }
    }

    @ViewBuilder
    private var smithList: some View {
        if let focusID {
            if let line = lines.first(where: { $0.id == focusID }) {
                smithRow(line)
            }
        } else if showsBag {
            if lines.isEmpty {
                Text("Nothing in the bag yet.")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
                    .frame(maxWidth: .infinity)
            }
            ForEach(SlotGroups.smith(lines), id: \.name) { group in
                Text(group.name)
                    .font(HearthFont.pixel(18))
                    .foregroundStyle(HearthPalette.amber)
                    .accessibilityAddTraits(.isHeader)
                ForEach(group.lines) { line in
                    smithRow(line)
                }
            }
        }
    }

    private func smithRow(_ line: SmithLine) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if line.isNew {
                        Text("New")
                            .font(HearthFont.pixel(14))
                            .foregroundStyle(HearthPalette.amber)
                            .accessibilityLabel("New")
                    }
                    Text(line.text)
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.parchment)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if line.signature.isEmpty == false {
                        Text(line.signature)
                            .font(HearthFont.pixel(14))
                            .foregroundStyle(HearthPalette.parchment.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(line.signature)
                    }
                }
                if line.equipped == false {
                    ScoreMark(arrow: line.damageArrow, name: "damage")
                    ScoreMark(arrow: line.toughnessArrow, name: "toughness")
                }
                if line.equipped {
                    Text("Equipped")
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.amber)
                        .accessibilityLabel("Equipped")
                }
            }
            ForEach(line.affixes) { affix in
                Text(affix.detail)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .accessibilityLabel(affix.detail)
            }
            KeepMarks(locked: line.locked, favorite: line.favorite, lock: { toggleLock(line.id) }, favor: { toggleFavorite(line.id) })
            HStack(spacing: 8) {
                if line.equipped == false {
                    Button("Equip") { equip(line.id) }
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.ink)
                        .frame(minWidth: 72, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
                        .buttonStyle(.plain)
                        .accessibilityLabel("Equip \(line.text)")
                }
                Button("Salvage") { salvage(line.id) }
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(minWidth: 88, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(line.canSalvage ? HearthPalette.parchment : HearthPalette.parchment.opacity(0.35)))
                    .buttonStyle(.plain)
                    .disabled(line.canSalvage == false)
                    .accessibilityLabel("Salvage \(line.text)")
                Button(action: { raise(line.id) }) {
                    VStack(spacing: 0) {
                        Text("Raise")
                        Text(line.raiseCaption)
                            .font(HearthFont.pixel(12))
                    }
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(line.canRaise ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .disabled(line.canRaise == false)
                .accessibilityLabel("Raise \(line.text)")
                .accessibilityValue(line.raiseCaption)
            }
            ForEach(line.affixes) { affix in
                if line.rerollCaption.isEmpty == false {
                    Button(action: { reroll(line.id, affix.index) }) {
                        VStack(spacing: 0) {
                            Text("Re-roll \(affix.name)")
                            Text(line.rerollCaption)
                                .font(HearthFont.pixel(12))
                        }
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 3).fill(line.canReroll ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
                    }
                    .buttonStyle(.plain)
                    .disabled(line.canReroll == false)
                    .accessibilityLabel("Re-roll \(affix.detail)")
                    .accessibilityValue(line.rerollCaption)
                }
            }
            if line.transmuteCaption.isEmpty == false {
                Button(action: { transmute(line.id) }) {
                    VStack(spacing: 0) {
                        Text("Transmute")
                        Text(line.transmuteCaption)
                            .font(HearthFont.pixel(12))
                    }
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(line.canTransmute ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .disabled(line.canTransmute == false)
                .accessibilityLabel("Transmute \(line.text)")
                .accessibilityValue(line.transmuteCaption)
            }
        }
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.parchment.opacity(0.25), lineWidth: 1))
    }
}

/// A cottage whose system is not in this demo. Names the building and the Depth that opens it.
public struct LockedCottageView: View {
    public var name: String
    public var depth: Int
    public var close: () -> Void

    public init(name: String, depth: Int, close: @escaping () -> Void) {
        self.name = name
        self.depth = depth
        self.close = close
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(name)
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 48)
                .accessibilityLabel(name)
            Text("Opens at Depth \(depth)")
                .font(HearthFont.pixel(20))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Opens at Depth")
                .accessibilityValue("\(depth)")
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .accessibilityLabel("Close")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }
}

/// A locked door the host overlays on the hamlet. A card, naming the building and the Depth that opens it.
public struct LockedDoorNote: View {
    public var name: String
    public var depth: Int
    public var detail: String?
    public var close: () -> Void

    public init(name: String, depth: Int, detail: String? = nil, close: @escaping () -> Void) {
        self.name = name
        self.depth = depth
        self.detail = detail
        self.close = close
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text(name)
                .font(HearthFont.pixel(22))
                .foregroundStyle(HearthPalette.amber)
                .multilineTextAlignment(.center)
                .accessibilityLabel(name)
            Text(detail ?? "Opens at Depth \(depth)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .multilineTextAlignment(.center)
                .accessibilityLabel(detail == nil ? "Opens at Depth" : (detail ?? name))
                .accessibilityValue(detail == nil ? "\(depth)" : "")
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .accessibilityLabel("Close")
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 4).fill(HearthPalette.ink))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.amber.opacity(0.6), lineWidth: 2))
    }
}

public struct ApothecaryView: View {
    public var healPercent: Int
    public var charges: Int
    public var cooldown: Int
    public var close: () -> Void

    public init(healPercent: Int, charges: Int, cooldown: Int, close: @escaping () -> Void) {
        self.healPercent = healPercent
        self.charges = charges
        self.cooldown = cooldown
        self.close = close
    }

    public var body: some View {
        VStack(spacing: 14) {
            Text("Apothecary")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 36)
                .accessibilityLabel("Apothecary")
            Text("One potion")
                .font(HearthFont.pixel(20))
                .foregroundStyle(HearthPalette.parchment)
            Text("Heals \(healPercent)% of max HP.")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Heal")
                .accessibilityValue("\(healPercent) percent")
            Text("\(charges) charges. \(cooldown)s between drinks.")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Charges")
                .accessibilityValue("\(charges) charges, \(cooldown) seconds")
            Text("It starts full each rift, and one charge comes back each wave. The fight drinks it below 35% HP. You can tap it too.")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .accessibilityLabel("Close")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }
}

/// One line the fight can show for the potion.
public enum PotionFacts {
    public static func sentence(healPercent: Int, charges: Int, cooldown: Int) -> String {
        "Heals \(healPercent)%. \(charges) charges. \(cooldown)s between drinks. Starts full. One charge back each wave."
    }
}

public struct MapRoomView: View {
    public var depth: Int
    public var best: Int
    public var band: String
    public var canSend: Bool
    public var status: String?
    public var note: String?
    public var timing: Bool
    public var stepsLocked: Bool
    public var lower: () -> Void
    public var raise: () -> Void
    public var send: () -> Void
    public var close: () -> Void

    public init(
        depth: Int, best: Int, band: String, canSend: Bool, status: String?, note: String?, timing: Bool, stepsLocked: Bool,
        lower: @escaping () -> Void, raise: @escaping () -> Void, send: @escaping () -> Void, close: @escaping () -> Void
    ) {
        self.depth = depth
        self.best = best
        self.band = band
        self.canSend = canSend
        self.status = status
        self.note = note
        self.timing = timing
        self.stepsLocked = stepsLocked
        self.lower = lower
        self.raise = raise
        self.send = send
        self.close = close
    }

    public var body: some View {
        VStack(spacing: 14) {
            Text("Map Room")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 28)
                .accessibilityLabel("Map Room")
            Text("Expeditions")
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.parchment)
            Text("Depth \(depth)")
                .font(HearthFont.pixel(22))
                .foregroundStyle(HearthPalette.amber)
                .accessibilityLabel("Depth")
                .accessibilityValue("\(depth)")
            Text(band)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Difficulty")
                .accessibilityValue(band)
            HStack(spacing: 12) {
                step("Lower Depth", "−", lower)
                step("Raise Depth", "+", raise)
            }
            .padding(.horizontal, 24)
            if let status {
                Text(status)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .accessibilityLabel(status)
            }
            if let note {
                Text(note)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .accessibilityLabel(note)
            }
            Button(action: send) {
                Text(timing ? "Timing…" : "Send")
                    .font(HearthFont.pixel(18))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(canSend && timing == false ? HearthPalette.amber : HearthPalette.parchment.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .disabled(canSend == false || timing)
            .padding(.horizontal, 24)
            .accessibilityLabel(timing ? "Timing" : "Send expedition")
            Text("Best Depth \(best). Easy or Fair only. Eight hours, then it comes home.")
                .font(HearthFont.pixel(14))
                .foregroundStyle(HearthPalette.parchment.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .accessibilityLabel("Close")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }

    private func step(_ label: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(22))
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(stepsLocked ? HearthPalette.parchment.opacity(0.35) : HearthPalette.amber))
        }
        .buttonStyle(.plain)
        .disabled(stepsLocked)
        .accessibilityLabel(label)
    }
}

public struct AwayView: View {
    public var title: String
    public var reward: String?
    public var note: String?
    public var lines: [LootLine]
    public var close: () -> Void

    public init(title: String, reward: String?, note: String?, lines: [LootLine], close: @escaping () -> Void) {
        self.title = title
        self.reward = reward
        self.note = note
        self.lines = lines
        self.close = close
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("While you were away")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 28)
                .multilineTextAlignment(.center)
                .accessibilityLabel("While you were away")
            Text(title)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.parchment)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .accessibilityLabel(title)
            if let reward {
                Text(reward)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .accessibilityLabel(reward)
            }
            if let note {
                Text(note)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .accessibilityLabel(note)
            }
            if lines.isEmpty == false {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(lines) { line in
                            ItemFacts(title: line.text, details: line.details)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .accessibilityLabel("Close")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }
}

private struct CraftBar: View {
    var choices: [CraftChoice]
    var caption: String
    var bagFull: Bool
    var craft: (String, String) -> Void
    @State private var slot = "melee"
    @State private var typeID = ""

    var body: some View {
        let types = choices.filter { $0.slot == slot }
        let chosen = types.first { $0.id == typeID }?.id ?? types.first?.id ?? ""
        VStack(alignment: .leading, spacing: 8) {
            Text("Craft a Rare")
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(slotRows, id: \.id) { entry in
                        chip(entry.name, on: entry.id == slot) {
                            slot = entry.id
                            typeID = ""
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(types) { entry in
                        chip(entry.name, on: entry.id == chosen) { typeID = entry.id }
                    }
                }
            }
            Button(action: { if chosen.isEmpty == false { craft(slot, chosen) } }) {
                Text(bagFull ? "The bag is full." : "Craft · \(caption)")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 3).fill(bagFull || chosen.isEmpty ? HearthPalette.parchment.opacity(0.35) : HearthPalette.amber))
            }
            .buttonStyle(.plain)
            .disabled(bagFull || chosen.isEmpty)
            .accessibilityLabel(bagFull ? "The bag is full." : "Craft a Rare for \(caption)")
        }
    }

    private var slotRows: [(id: String, name: String)] {
        var seen: [String] = []
        var rows: [(id: String, name: String)] = []
        for choice in choices where seen.contains(choice.slot) == false {
            seen.append(choice.slot)
            rows.append((choice.slot, choice.slotName))
        }
        return rows
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(16))
                .foregroundStyle(on ? HearthPalette.ink : HearthPalette.parchment)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(on ? HearthPalette.amber : HearthPalette.ink))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(HearthPalette.amber.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

public struct TacticKindChoice: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TacticEditLine: Equatable, Sendable, Identifiable {
    public var id: Int
    public var caption: String
    public var kind: String
    public var adjusts: Bool

    public init(id: Int, caption: String, kind: String, adjusts: Bool) {
        self.id = id
        self.caption = caption
        self.kind = kind
        self.adjusts = adjusts
    }
}

/// The three rules the fight already runs. The caption is the same line the rift shows.
public struct LibraryView: View {
    public var lines: [TacticEditLine]
    public var kinds: [TacticKindChoice]
    public var close: () -> Void
    public var chooseKind: (Int, String) -> Void
    public var nudge: (Int, Int) -> Void

    public init(
        lines: [TacticEditLine], kinds: [TacticKindChoice], close: @escaping () -> Void,
        chooseKind: @escaping (Int, String) -> Void, nudge: @escaping (Int, Int) -> Void
    ) {
        self.lines = lines
        self.kinds = kinds
        self.close = close
        self.chooseKind = chooseKind
        self.nudge = nudge
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text("Library")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 20)
                .accessibilityLabel("Library")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(lines) { line in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(line.caption)
                                .font(HearthFont.pixel(16))
                                .foregroundStyle(HearthPalette.parchment)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityLabel(line.caption)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(kinds) { kind in
                                        Button(kind.name) { chooseKind(line.id, kind.id) }
                                            .font(HearthFont.pixel(16))
                                            .foregroundStyle(line.kind == kind.id ? HearthPalette.ink : HearthPalette.parchment)
                                            .padding(.horizontal, 10)
                                            .frame(minHeight: 44)
                                            .background(RoundedRectangle(cornerRadius: 3).fill(line.kind == kind.id ? HearthPalette.amber : HearthPalette.ink))
                                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(HearthPalette.amber.opacity(0.7), lineWidth: 1))
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Tactic \(line.id + 1) \(kind.name)")
                                            .accessibilityAddTraits(line.kind == kind.id ? .isSelected : [])
                                    }
                                }
                            }
                            if line.adjusts {
                                HStack(spacing: 8) {
                                    step("−", label: "Lower tactic \(line.id + 1)") { nudge(line.id, -1) }
                                    step("+", label: "Raise tactic \(line.id + 1)") { nudge(line.id, 1) }
                                }
                            }
                        }
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.parchment.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
            }
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .padding(.bottom, 12)
                .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }

    private func step(_ title: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(22))
                .foregroundStyle(HearthPalette.ink)
                .frame(width: 52, height: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

public struct StashView: View {
    public var bag: [LootLine]
    public var stash: [LootLine]
    public var bagCount: Int
    public var bagCapacity: Int
    public var stashCount: Int
    public var stashCapacity: Int
    public var note: String?
    public var close: () -> Void
    public var toStash: (String) -> Void
    public var toBag: (String) -> Void

    public init(
        bag: [LootLine], stash: [LootLine], bagCount: Int, bagCapacity: Int, stashCount: Int, stashCapacity: Int, note: String?,
        close: @escaping () -> Void, toStash: @escaping (String) -> Void, toBag: @escaping (String) -> Void
    ) {
        self.bag = bag
        self.stash = stash
        self.bagCount = bagCount
        self.bagCapacity = bagCapacity
        self.stashCount = stashCount
        self.stashCapacity = stashCapacity
        self.note = note
        self.close = close
        self.toStash = toStash
        self.toBag = toBag
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text("Stash House")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 20)
                .accessibilityLabel("Stash House")
            Text("Bag \(bagCount)/\(bagCapacity)   Stash \(stashCount)/\(stashCapacity)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Bag \(bagCount) of \(bagCapacity), stash \(stashCount) of \(stashCapacity)")
            if let note {
                Text(note)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .accessibilityLabel(note)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    pile("Bag", lines: bag, actionTitle: "Stash", equippedStays: true, action: toStash)
                    pile("Stash", lines: stash, actionTitle: "Bag", equippedStays: false, action: toBag)
                }
                .padding(.horizontal, 16)
            }
            Button("Close", action: close)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .frame(minHeight: 44)
                .padding(.bottom, 12)
                .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }

    private func pile(_ title: String, lines: [LootLine], actionTitle: String, equippedStays: Bool, action: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.amber)
                .accessibilityAddTraits(.isHeader)
            if lines.isEmpty {
                Text("Empty")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
            }
            ForEach(lines) { line in
                HStack(alignment: .top, spacing: 8) {
                    ItemFacts(title: line.text, details: line.details)
                    if equippedStays && line.equipped {
                        Text("Equipped")
                            .font(HearthFont.pixel(16))
                            .foregroundStyle(HearthPalette.amber)
                            .accessibilityLabel("Equipped")
                    } else {
                        Button(actionTitle) { action(line.id) }
                            .font(HearthFont.pixel(16))
                            .foregroundStyle(HearthPalette.ink)
                            .frame(minWidth: 72, minHeight: 44)
                            .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(actionTitle) \(line.text)")
                    }
                }
            }
        }
    }
}
