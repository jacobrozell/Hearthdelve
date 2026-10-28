import CoreText
import SwiftUI

public enum HearthFont {
    /// Registers the bundled Kenney Pixel font once. Used for titles and HUD numbers at whole-number sizes.
    public static func register(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "KenneyPixel", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    public static func pixel(_ size: CGFloat) -> Font {
        .custom("Kenney-Pixel", fixedSize: size)
    }
}

public struct RelicButtonState: Equatable, Sendable {
    public var name: String
    public var short: String
    public var souls: Int
    public var cooldown: Double
    public var ready: Bool

    public init(name: String, short: String, souls: Int, cooldown: Double, ready: Bool) {
        self.name = name
        self.short = short
        self.souls = souls
        self.cooldown = cooldown
        self.ready = ready
    }
}

public struct RoomHUDState: Equatable, Sendable {
    public var hp: Double = 0
    public var maxHP: Double = 1
    public var shield: Double = 0
    public var souls: Double = 0
    public var soulCap: Double = 100
    public var relics: [RelicButtonState] = []
    public var potionCharges = 0
    public var potionMax = 0
    public var potionCooldown: Double = 0
    public var speed = 1
    public var paused = false
    public var wave = 0
    public var kills = 0
    public var tactic: String?
    public var debug: String?
    public var down = false
    public var meter: Double = 0
    public var depth = 1
    public var floor = 1
    public var lanternOn = false
    public var lantern: Double = 0
    public var enraged = false
    public var lootLines: [LootLine] = []
    public var depthDelta: Int?
    public var settled = false
    public var resultMessage: String?
    public var homeTitle = "New run"
    public var leaveTitle = "New run"

    public init() {}
}

public struct RoomActions {
    public var relic: (Int) -> Void
    public var potion: () -> Void
    public var speed: () -> Void
    public var pause: () -> Void
    public var newRun: () -> Void
    public var saveRecording: () -> Void
    public var equip: (String) -> Void

    public init(
        relic: @escaping (Int) -> Void, potion: @escaping () -> Void, speed: @escaping () -> Void, pause: @escaping () -> Void,
        newRun: @escaping () -> Void, saveRecording: @escaping () -> Void, equip: @escaping (String) -> Void
    ) {
        self.relic = relic
        self.potion = potion
        self.speed = speed
        self.pause = pause
        self.newRun = newRun
        self.saveRecording = saveRecording
        self.equip = equip
    }
}

public struct LootLine: Equatable, Sendable, Identifiable {
    public var id: String
    public var text: String
    public var damageArrow: Int
    public var toughnessArrow: Int
    public var equipped: Bool

    public init(id: String, text: String, damageArrow: Int, toughnessArrow: Int, equipped: Bool) {
        self.id = id
        self.text = text
        self.damageArrow = damageArrow
        self.toughnessArrow = toughnessArrow
        self.equipped = equipped
    }
}

/// The Rift HUD, bottom to top: thumb buttons, then HP and Souls. Nothing tappable sits at the top of the screen.
public struct RoomHUD: View {
    public var state: RoomHUDState
    public var actions: RoomActions
    public var note: String?

    public init(state: RoomHUDState, actions: RoomActions, note: String? = nil) {
        self.state = state
        self.actions = actions
        self.note = note
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                top
                Spacer()
                if state.down == false, state.settled == false {
                    bottom
                }
            }
            if state.down {
                DownOverlay(
                    newRun: actions.newRun, save: actions.saveRecording, equip: actions.equip, note: note,
                    message: state.resultMessage ?? "You wake by the hearth. Everything you found came home with you.",
                    loot: state.lootLines, depthDelta: state.depthDelta, homeTitle: state.homeTitle
                )
            } else if state.settled {
                ClearOverlay(
                    newRun: actions.newRun, save: actions.saveRecording, equip: actions.equip, note: note,
                    message: state.resultMessage ?? "The Guardian falls.",
                    loot: state.lootLines, depthDelta: state.depthDelta, homeTitle: state.homeTitle
                )
            } else if state.paused {
                PauseOverlay(resume: actions.pause, newRun: actions.newRun, save: actions.saveRecording, note: note, leaveTitle: state.leaveTitle)
            }
        }
    }

    /// Meter, Depth, and floor sit at the top and do not take taps. The Lantern arc is only there in a Deep Rift.
    private var top: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let debug = state.debug {
                Text(debug)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 10) {
                Text("Depth \(state.depth)")
                    .accessibilityLabel("Depth")
                    .accessibilityValue("\(state.depth)")
                Text("Floor \(state.floor)")
                    .accessibilityLabel("Floor")
                    .accessibilityValue("\(state.floor)")
                Spacer(minLength: 0)
                if state.lanternOn {
                    LanternArc(fraction: state.lantern)
                }
            }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.parchment)
            RiftMeterBar(value: state.meter)
            if state.enraged {
                Text("Enraged")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(Color(red: 0.93, green: 0.33, blue: 0.36))
                    .accessibilityLabel("Enraged")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .allowsHitTesting(false)
    }

    private var bottom: some View {
        VStack(spacing: 8) {
            if let tactic = state.tactic {
                Text(tactic)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(HearthPalette.ink.opacity(0.7)))
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
            HStack(alignment: .lastTextBaseline) {
                Text("Wave \(state.wave)")
                Spacer()
                Text("\(state.kills) kills")
            }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.parchment.opacity(0.8))
            .allowsHitTesting(false)
            HStack(spacing: 8) {
                Meter(title: "HP", value: fraction(state.hp, state.maxHP), text: "\(Int(state.hp.rounded()))", tint: HearthPalette.grass, shield: fraction(state.shield, state.maxHP))
                Meter(title: "Souls", value: fraction(state.souls, state.soulCap), text: "\(Int(state.souls.rounded()))", tint: HearthPalette.amber, shield: 0)
            }
            .allowsHitTesting(false)
            HStack(spacing: 10) {
                ForEach(Array(state.relics.enumerated()), id: \.offset) { slot, relic in
                    ThumbButton(
                        title: relic.short, subtitle: "\(relic.souls)", cooldown: relic.cooldown, ready: relic.ready, size: 64,
                        tint: HearthPalette.amber, label: relic.name, action: { actions.relic(slot) }
                    )
                }
                Spacer(minLength: 4)
                ThumbButton(
                    title: "Pot", subtitle: "\(state.potionCharges)/\(state.potionMax)", cooldown: state.potionCooldown,
                    ready: state.potionCharges > 0 && state.potionCooldown == 0, size: 56, tint: HearthPalette.grass,
                    label: "Potion, \(state.potionCharges) left", action: actions.potion
                )
                ThumbButton(title: "\(state.speed)×", subtitle: nil, cooldown: 0, ready: true, size: 44, tint: HearthPalette.parchment,
                            label: "Speed \(state.speed) times", action: actions.speed)
                ThumbButton(title: state.paused ? "▶" : "II", subtitle: nil, cooldown: 0, ready: true, size: 44, tint: HearthPalette.parchment,
                            label: state.paused ? "Resume" : "Pause", action: actions.pause)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .animation(.easeOut(duration: 0.2), value: state.tactic)
    }

    private func fraction(_ value: Double, _ cap: Double) -> Double {
        guard cap > 0 else { return 0 }
        return min(1, max(0, value / cap))
    }
}

private struct Meter: View {
    var title: String
    var value: Double
    var text: String
    var tint: Color
    var shield: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text(text)
            }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.parchment)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(HearthPalette.ink.opacity(0.8))
                    Rectangle().fill(tint).frame(width: proxy.size.width * value)
                    if shield > 0 {
                        Rectangle().fill(HearthPalette.amber.opacity(0.85)).frame(width: proxy.size.width * min(1, shield), height: 3)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                    Rectangle().stroke(HearthPalette.parchment.opacity(0.5), lineWidth: 1)
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(text)")
    }
}

private struct ThumbButton: View {
    var title: String
    var subtitle: String?
    var cooldown: Double
    var ready: Bool
    var size: CGFloat
    var tint: Color
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(HearthPalette.ink.opacity(0.75))
                Circle().stroke(tint.opacity(ready ? 1 : 0.35), lineWidth: 2)
                if cooldown > 0 {
                    Circle()
                        .trim(from: 0, to: cooldown)
                        .stroke(HearthPalette.parchment.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(x: -1)
                }
                VStack(spacing: -2) {
                    Text(title).font(HearthFont.pixel(size > 50 ? 20 : 16))
                    if let subtitle {
                        Text(subtitle).font(HearthFont.pixel(12)).opacity(0.75)
                    }
                }
                .foregroundStyle(tint.opacity(ready ? 1 : 0.5))
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(ready ? "Ready" : "Not ready")
    }
}

private struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 14) { content }
            .padding(22)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: 4).fill(HearthPalette.ink.opacity(0.94)))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(HearthPalette.amber.opacity(0.6), lineWidth: 2))
            .padding(24)
    }
}

private struct PanelButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HearthFont.pixel(20))
                .foregroundStyle(HearthPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 3).fill(HearthPalette.amber))
        }
        .buttonStyle(.plain)
    }
}

private struct LanternArc: View {
    var fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(HearthPalette.ink.opacity(0.85), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(1, max(0, fraction)))
                .stroke(HearthPalette.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 28, height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lantern")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}

private struct RiftMeterBar: View {
    var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Meter")
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
            }
            .font(HearthFont.pixel(16))
            .foregroundStyle(HearthPalette.parchment)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(HearthPalette.ink.opacity(0.8))
                    Rectangle().fill(HearthPalette.amber).frame(width: proxy.size.width * min(1, max(0, value)))
                    Rectangle().stroke(HearthPalette.parchment.opacity(0.5), lineWidth: 1)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rift meter")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
    }
}

private struct LootList: View {
    var lines: [LootLine]
    var depthDelta: Int?
    var equip: (String) -> Void

    var body: some View {
        VStack(spacing: 4) {
            if let depthDelta {
                Text("Depth +\(depthDelta)")
                    .font(HearthFont.pixel(18))
                    .foregroundStyle(HearthPalette.amber)
                    .accessibilityLabel("Depth")
                    .accessibilityValue("plus \(depthDelta)")
            }
            Text("Loot")
                .font(HearthFont.pixel(16))
                .foregroundStyle(HearthPalette.parchment.opacity(0.8))
                .accessibilityLabel("Loot")
            if lines.isEmpty {
                Text("None")
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.parchment)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(lines) { line in
                            HStack(spacing: 8) {
                                Text(line.text)
                                    .font(HearthFont.pixel(16))
                                    .foregroundStyle(HearthPalette.parchment)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ScoreMark(arrow: line.damageArrow, name: "damage")
                                ScoreMark(arrow: line.toughnessArrow, name: "toughness")
                                Button(line.equipped ? "Equipped" : "Equip") { equip(line.id) }
                                    .font(HearthFont.pixel(16))
                                    .foregroundStyle(HearthPalette.ink)
                                    .frame(minWidth: 72, minHeight: 44)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(line.equipped ? HearthPalette.parchment.opacity(0.4) : HearthPalette.amber))
                                    .buttonStyle(.plain)
                                    .disabled(line.equipped)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
    }
}

struct ScoreMark: View {
    var arrow: Int
    var name: String

    var body: some View {
        Group {
            if arrow > 0 {
                MarkTriangle().fill(HearthPalette.amber)
            } else if arrow < 0 {
                MarkTriangle().fill(HearthPalette.parchment.opacity(0.7)).rotationEffect(.degrees(180))
            } else {
                Rectangle().fill(HearthPalette.parchment.opacity(0.7)).frame(width: 8, height: 2)
            }
        }
        .frame(width: 12, height: 12)
        .accessibilityLabel("\(name) \(arrow > 0 ? "up" : arrow < 0 ? "down" : "same")")
    }
}

private struct MarkTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct DownOverlay: View {
    var newRun: () -> Void
    var save: () -> Void
    var equip: (String) -> Void
    var note: String?
    var message: String
    var loot: [LootLine]
    var depthDelta: Int?
    var homeTitle: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            Panel {
                Text(message)
                    .font(HearthFont.pixel(20))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(HearthPalette.parchment)
                LootList(lines: loot, depthDelta: depthDelta, equip: equip)
                PanelButton(title: homeTitle, action: newRun)
                Button("Save this run", action: save)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                if let note {
                    Text(note).font(.caption2).foregroundStyle(HearthPalette.parchment.opacity(0.7))
                }
            }
        }
    }
}

private struct ClearOverlay: View {
    var newRun: () -> Void
    var save: () -> Void
    var equip: (String) -> Void
    var note: String?
    var message: String
    var loot: [LootLine]
    var depthDelta: Int?
    var homeTitle: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            Panel {
                Text(message)
                    .font(HearthFont.pixel(22))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(HearthPalette.amber)
                LootList(lines: loot, depthDelta: depthDelta, equip: equip)
                PanelButton(title: homeTitle, action: newRun)
                Button("Save this run", action: save)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                if let note {
                    Text(note).font(.caption2).foregroundStyle(HearthPalette.parchment.opacity(0.7))
                }
            }
        }
    }
}

private struct PauseOverlay: View {
    var resume: () -> Void
    var newRun: () -> Void
    var save: () -> Void
    var note: String?
    var leaveTitle: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture(perform: resume)
            Panel {
                Text("Paused").font(HearthFont.pixel(28)).foregroundStyle(HearthPalette.amber)
                PanelButton(title: "Resume", action: resume)
                PanelButton(title: leaveTitle, action: newRun)
                Button("Save this run", action: save)
                    .font(HearthFont.pixel(16))
                    .foregroundStyle(HearthPalette.amber)
                if let note {
                    Text(note).font(.caption2).foregroundStyle(HearthPalette.parchment.opacity(0.7))
                }
            }
        }
    }
}
