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

    public init() {}
}

public struct RoomActions {
    public var relic: (Int) -> Void
    public var potion: () -> Void
    public var speed: () -> Void
    public var pause: () -> Void
    public var newRun: () -> Void
    public var saveRecording: () -> Void

    public init(
        relic: @escaping (Int) -> Void, potion: @escaping () -> Void, speed: @escaping () -> Void, pause: @escaping () -> Void,
        newRun: @escaping () -> Void, saveRecording: @escaping () -> Void
    ) {
        self.relic = relic
        self.potion = potion
        self.speed = speed
        self.pause = pause
        self.newRun = newRun
        self.saveRecording = saveRecording
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
                if let debug = state.debug {
                    Text(debug)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                        .allowsHitTesting(false)
                }
                Spacer()
                bottom
            }
            if state.down {
                DownOverlay(newRun: actions.newRun, save: actions.saveRecording, note: note)
            } else if state.paused {
                PauseOverlay(resume: actions.pause, newRun: actions.newRun, save: actions.saveRecording, note: note)
            }
        }
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

private struct DownOverlay: View {
    var newRun: () -> Void
    var save: () -> Void
    var note: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            Panel {
                Text("You wake by the hearth. Everything you found came home with you.")
                    .font(HearthFont.pixel(20))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(HearthPalette.parchment)
                PanelButton(title: "New run", action: newRun)
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

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture(perform: resume)
            Panel {
                Text("Paused").font(HearthFont.pixel(28)).foregroundStyle(HearthPalette.amber)
                PanelButton(title: "Resume", action: resume)
                PanelButton(title: "New run", action: newRun)
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
