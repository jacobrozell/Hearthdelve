import SwiftUI

/// The first home screen, before the village. The app no longer presents it.
public struct HearthWellView: View {
    public var bestDepth: Int
    public var bag: [LootLine]
    public var capacity: Int
    public var note: String?
    public var descend: () -> Void
    public var equip: (String) -> Void

    public init(bestDepth: Int, bag: [LootLine], capacity: Int = 40, note: String? = nil, descend: @escaping () -> Void, equip: @escaping (String) -> Void) {
        self.bestDepth = bestDepth
        self.bag = bag
        self.capacity = capacity
        self.note = note
        self.descend = descend
        self.equip = equip
    }

    public var body: some View {
        VStack(spacing: 18) {
            Text("Hearthdelve")
                .font(HearthFont.pixel(32))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 28)
            Text("Best Depth \(bestDepth)")
                .font(HearthFont.pixel(18))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Best Depth")
                .accessibilityValue("\(bestDepth)")
            Button(action: descend) {
                VStack(spacing: 4) {
                    Text("The well")
                        .font(HearthFont.pixel(28))
                    Text("Descend")
                        .font(HearthFont.pixel(16))
                        .opacity(0.8)
                }
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 88)
                .background(RoundedRectangle(cornerRadius: 4).fill(HearthPalette.amber))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("The well")
            .padding(.horizontal, 28)
            bagList
            if let note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(HearthPalette.parchment.opacity(0.7))
                    .padding(.horizontal, 24)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HearthPalette.ink)
    }

    private var bagList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bag \(bag.count)/\(capacity)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment.opacity(0.8))
                .accessibilityLabel("Bag")
                .accessibilityValue("\(bag.count) of \(capacity)")
            if bag.isEmpty {
                Text("Nothing in the bag yet.")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(bag) { line in
                            HStack(spacing: 8) {
                                Text(line.text)
                                    .font(HearthFont.pixel(16))
                                    .foregroundStyle(HearthPalette.parchment)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(line.equipped ? "Equipped" : "Equip") { equip(line.id) }
                                    .font(HearthFont.pixel(16))
                                    .foregroundStyle(HearthPalette.ink)
                                    .frame(minWidth: 72, minHeight: 44)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(line.equipped ? HearthPalette.parchment.opacity(0.4) : HearthPalette.amber))
                                    .buttonStyle(.plain)
                                    .disabled(line.equipped)
                                    .accessibilityLabel(line.equipped ? "Equipped" : "Equip \(line.text)")
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: 360, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 4).fill(HearthPalette.ink.opacity(0.001)))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.parchment.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

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
                Text(deepRift ? "Lantern on. A clear at your best Depth can advance it." : "No lantern. Depth stays.")
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

public struct SmithLine: Equatable, Sendable, Identifiable {
    public var id: String
    public var text: String
    public var damageArrow: Int
    public var toughnessArrow: Int
    public var equipped: Bool
    public var canSalvage: Bool
    public var canRaise: Bool
    public var raiseCaption: String

    public init(id: String, text: String, damageArrow: Int, toughnessArrow: Int, equipped: Bool, canSalvage: Bool, canRaise: Bool, raiseCaption: String) {
        self.id = id
        self.text = text
        self.damageArrow = damageArrow
        self.toughnessArrow = toughnessArrow
        self.equipped = equipped
        self.canSalvage = canSalvage
        self.canRaise = canRaise
        self.raiseCaption = raiseCaption
    }
}

/// Level, gold, and materials over the meadow. The Bag button is the only control in this bar.
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
                Text("Gold \(gold)")
                    .accessibilityLabel("Gold")
                    .accessibilityValue("\(gold)")
                Text("Dust \(dust)  Shards \(shards)  Embers \(embers)")
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Materials")
                    .accessibilityValue("Dust \(dust), Shards \(shards), Embers \(embers)")
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

public struct BagView: View {
    public var lines: [LootLine]
    public var count: Int
    public var capacity: Int
    public var close: () -> Void
    public var equip: (String) -> Void

    public init(lines: [LootLine], count: Int, capacity: Int, close: @escaping () -> Void, equip: @escaping (String) -> Void) {
        self.lines = lines
        self.count = count
        self.capacity = capacity
        self.close = close
        self.equip = equip
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("Bag \(count)/\(capacity)")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 24)
                .accessibilityLabel("Bag")
                .accessibilityValue("\(count) of \(capacity)")
            itemList
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

    private var itemList: some View {
        Group {
            if lines.isEmpty {
                Text("Nothing in the bag yet.")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(lines) { line in
                            HStack(spacing: 8) {
                                Text(line.text)
                                    .font(HearthFont.pixel(16))
                                    .foregroundStyle(HearthPalette.parchment)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ScoreMark(arrow: line.damageArrow, name: "damage")
                                ScoreMark(arrow: line.toughnessArrow, name: "toughness")
                                equipButton(line)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
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
}

public struct SmithView: View {
    public var gold: Int
    public var dust: Int
    public var shards: Int
    public var embers: Int
    public var lines: [SmithLine]
    public var confirming: Bool
    public var close: () -> Void
    public var salvage: (String) -> Void
    public var confirmSalvage: () -> Void
    public var cancelSalvage: () -> Void
    public var raise: (String) -> Void
    public var equip: (String) -> Void

    public init(
        gold: Int, dust: Int, shards: Int, embers: Int, lines: [SmithLine], confirming: Bool,
        close: @escaping () -> Void, salvage: @escaping (String) -> Void, confirmSalvage: @escaping () -> Void,
        cancelSalvage: @escaping () -> Void, raise: @escaping (String) -> Void, equip: @escaping (String) -> Void
    ) {
        self.gold = gold
        self.dust = dust
        self.shards = shards
        self.embers = embers
        self.lines = lines
        self.confirming = confirming
        self.close = close
        self.salvage = salvage
        self.confirmSalvage = confirmSalvage
        self.cancelSalvage = cancelSalvage
        self.raise = raise
        self.equip = equip
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text("Blacksmith")
                .font(HearthFont.pixel(28))
                .foregroundStyle(HearthPalette.amber)
                .padding(.top, 20)
                .accessibilityLabel("Blacksmith")
            Text("Gold \(gold)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Gold")
                .accessibilityValue("\(gold)")
            Text("Dust \(dust)   Shards \(shards)   Embers \(embers)")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment)
                .accessibilityLabel("Materials")
                .accessibilityValue("Dust \(dust), Shards \(shards), Embers \(embers)")
            ScrollView {
                VStack(spacing: 8) {
                    if lines.isEmpty {
                        Text("Nothing in the bag yet.")
                            .font(HearthFont.pixel(16))
                            .foregroundStyle(HearthPalette.parchment)
                    }
                    ForEach(lines) { line in
                        smithRow(line)
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
        .overlay {
            if confirming {
                ZStack {
                    Color.black.opacity(0.62).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("Salvage this Unique?")
                            .font(HearthFont.pixel(22))
                            .foregroundStyle(HearthPalette.amber)
                            .multilineTextAlignment(.center)
                        Text("It becomes Embers, and its signature is written in the Codex.")
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

    private func smithRow(_ line: SmithLine) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(line.text)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScoreMark(arrow: line.damageArrow, name: "damage")
                ScoreMark(arrow: line.toughnessArrow, name: "toughness")
                if line.equipped {
                    Text("Equipped")
                        .font(HearthFont.pixel(16))
                        .foregroundStyle(HearthPalette.amber)
                        .accessibilityLabel("Equipped")
                }
            }
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
