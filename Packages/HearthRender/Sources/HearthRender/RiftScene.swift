import CoreGraphics
import SpriteKit
import HearthCore

/// Draws sim snapshots. Never decides anything: positions are interpolated between the last two ticks,
/// and every tween (bob, lean, lunge, flash, squash) is computed from the pose the sim reports.
public final class RiftScene: SKScene {
    /// Points per art pixel. Kenney tiles are 16 px, so a tile is 32 pt and a phone shows about 12 across.
    public static let pixel: CGFloat = 2
    public static let tile: CGFloat = 16 * pixel

    private let world = SKNode()
    private let floor = SKNode()
    private let marks = SKNode()
    private let bodies = SKNode()
    private let effects = SKNode()
    private let cameraNode = SKCameraNode()
    private let vignette = SKSpriteNode()
    private let art = ArtLibrary()

    private var actors: [UInt32: ActorNode] = [:]
    private var telegraphs: [UInt32: MarkNode] = [:]
    private var grounds: [UInt32: MarkNode] = [:]
    private var numbers: [SKLabelNode] = []
    private var bursts: [SKSpriteNode] = []
    private var shieldRing = SKSpriteNode()
    private var heroLight = SKSpriteNode()

    private var previous: SimSnapshot?
    private var current: SimSnapshot?
    private var stamp: TimeInterval = 0
    private var tickSeconds: TimeInterval = 0.05
    private var roomSize = CGSize.zero
    private var clock: TimeInterval = 0

    public override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 24 / 255, green: 20 / 255, blue: 37 / 255, alpha: 1)
        addChild(world)
        for (layer, z) in [(floor, 0.0), (marks, 10.0), (bodies, 20.0), (effects, 30.0)] {
            layer.zPosition = z
            world.addChild(layer)
        }
        camera = cameraNode
        addChild(cameraNode)
        vignette.texture = art.vignette
        vignette.zPosition = 100
        vignette.alpha = 0.85
        cameraNode.addChild(vignette)
        heroLight = SKSpriteNode(texture: art.glow)
        heroLight.color = SKColor(red: 1, green: 0.78, blue: 0.45, alpha: 1)
        heroLight.colorBlendFactor = 1
        heroLight.alpha = 0.22
        heroLight.blendMode = .add
        heroLight.size = CGSize(width: Self.tile * 7, height: Self.tile * 7)
        heroLight.zPosition = 5
        marks.addChild(heroLight)
        shieldRing = SKSpriteNode(texture: art.ring)
        shieldRing.color = SKColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
        shieldRing.colorBlendFactor = 1
        shieldRing.size = CGSize(width: Self.tile * 1.2, height: Self.tile * 1.2)
        shieldRing.zPosition = 25
        shieldRing.isHidden = true
        bodies.addChild(shieldRing)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        nil
    }

    public override func didMove(to view: SKView) {
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        layoutCamera()
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        layoutCamera()
    }

    /// Builds the floor once per room: a tile map for floor and walls, a second one for props.
    public func load(room: RoomTemplate) {
        floor.removeAllChildren()
        for node in actors.values { node.removeFromParent() }
        actors.removeAll()
        for node in Array(telegraphs.values) + Array(grounds.values) { node.removeFromParent() }
        telegraphs.removeAll()
        grounds.removeAll()
        previous = nil
        current = nil
        roomSize = CGSize(width: CGFloat(room.width) * Self.tile, height: CGFloat(room.height) * Self.tile)
        for layer in [room.tiles, room.objects] {
            let map = art.tileMap(layer, width: room.width, height: room.height, tileset: room.tileset)
            floor.addChild(map)
        }
        layoutCamera()
    }

    /// Hands the scene a new tick. `tickSeconds` is wall time per sim tick at the current speed.
    public func push(_ snapshot: SimSnapshot, tickSeconds: TimeInterval) {
        previous = current ?? snapshot
        current = snapshot
        stamp = clock
        self.tickSeconds = max(0.005, tickSeconds)
        for event in snapshot.events {
            play(event)
        }
    }

    public override func update(_ currentTime: TimeInterval) {
        clock = currentTime
        guard let current else { return }
        let paused = current.paused
        let blend = paused ? 1 : CGFloat(min(1, max(0, (currentTime - stamp) / tickSeconds)))
        let before = Dictionary(uniqueKeysWithValues: (previous?.entities ?? []).map { ($0.id, $0) })
        var seen = Set<UInt32>()
        var heroPoint = CGPoint.zero
        let hostiles = current.entities.filter { $0.hostile && $0.hp > 0 && $0.kind != .projectile && $0.kind != .zone }

        for pose in current.entities {
            seen.insert(pose.id)
            let old = before[pose.id] ?? pose
            let point = CGPoint(
                x: CGFloat(old.x + (pose.x - old.x) * Double(blend)) * Self.tile,
                y: CGFloat(old.y + (pose.y - old.y) * Double(blend)) * Self.tile
            )
            let node = actors[pose.id] ?? spawn(pose)
            node.position = point
            node.zPosition = 1000 - point.y / Self.tile
            if pose.kind == .hero {
                heroPoint = point
                let nearest = hostiles.map { (other: EntityPose) -> Double in
                    let dx = other.x - pose.x
                    let dy = other.y - pose.y
                    return dx * dx + dy * dy
                }.min() ?? 0
                node.body.texture = art.texture(nearest > 9 ? "hero.bow" : "hero.sword")
            }
            node.apply(pose, time: currentTime, paused: paused)
        }
        for (id, node) in actors where seen.contains(id) == false {
            node.removeFromParent()
            actors[id] = nil
        }

        sync(current.telegraphs.map { ($0.id, $0.x, $0.y, $0.radius, $0.progress, $0.slam ? "slam" : "bolt") }, into: &telegraphs, telegraph: true)
        sync(current.grounds.map { ($0.id, $0.x, $0.y, $0.radius, $0.life, $0.element) }, into: &grounds, telegraph: false)

        heroLight.position = heroPoint
        heroLight.alpha = 0.18 + 0.04 * CGFloat(sin(currentTime * 3))
        shieldRing.isHidden = current.shield <= 0
        shieldRing.position = CGPoint(x: heroPoint.x, y: heroPoint.y + Self.tile * 0.35)
        shieldRing.alpha = 0.55 + 0.25 * CGFloat(sin(currentTime * 8))
        follow(heroPoint)
        fadeEffects(currentTime)
    }

    // MARK: Nodes

    private func spawn(_ pose: EntityPose) -> ActorNode {
        let node = ActorNode(pose: pose, art: art)
        bodies.addChild(node)
        actors[pose.id] = node
        return node
    }

    private func sync(_ items: [(UInt32, Double, Double, Double, Double, String)], into store: inout [UInt32: MarkNode], telegraph: Bool) {
        var seen = Set<UInt32>()
        for (id, x, y, radius, amount, kind) in items {
            seen.insert(id)
            let node = store[id] ?? {
                let made = MarkNode(art: art, color: telegraph ? Palette.telegraph(kind) : Palette.element(kind), telegraph: telegraph)
                marks.addChild(made)
                store[id] = made
                return made
            }()
            node.position = CGPoint(x: CGFloat(x) * Self.tile, y: CGFloat(y) * Self.tile)
            node.set(radius: CGFloat(radius) * Self.tile, amount: CGFloat(amount))
        }
        for (id, node) in store where seen.contains(id) == false {
            node.removeFromParent()
            store[id] = nil
        }
    }

    // MARK: Events

    private func play(_ event: SimEvent) {
        switch event {
        case .hit(_, let x, let y, let amount, let crit, let onHero):
            let color = onHero ? Palette.hurt : crit ? Palette.crit : Palette.damage
            float(NumberFormat.short(amount.rounded()), x: x, y: y, color: color, big: crit)
        case .death(_, let x, let y, let elite):
            burst(x: x, y: y, radius: elite ? 1.2 : 0.7, color: Palette.dust, ring: false)
        case .burst(let x, let y, let radius, let element):
            burst(x: x, y: y, radius: radius, color: Palette.element(element), ring: true)
        case .cleave(let x, let y, let radius):
            burst(x: x, y: y, radius: radius, color: Palette.cleave, ring: true)
        case .heal(let amount):
            if let hero = current?.entities.first(where: { $0.kind == .hero }) {
                float("+\(NumberFormat.short(amount.rounded()))", x: hero.x, y: hero.y, color: Palette.heal, big: false)
            }
        case .shield, .relic, .potion, .wave, .heroDown, .invariant:
            break
        }
    }

    private func float(_ text: String, x: Double, y: Double, color: SKColor, big: Bool) {
        let label = numbers.first { $0.parent == nil } ?? {
            let made = SKLabelNode(fontNamed: "Kenney-Pixel")
            made.verticalAlignmentMode = .center
            numbers.append(made)
            return made
        }()
        guard label.parent == nil, effects.children.count < 120 else { return }
        label.text = text
        label.fontSize = big ? 20 : 14
        label.fontColor = color
        label.alpha = 1
        label.setScale(1)
        label.position = CGPoint(x: CGFloat(x) * Self.tile, y: CGFloat(y) * Self.tile + Self.tile * 0.9)
        label.userData = ["born": clock, "life": 0.7, "rise": Self.tile * 0.8]
        effects.addChild(label)
    }

    private func burst(x: Double, y: Double, radius: Double, color: SKColor, ring: Bool) {
        let sprite = bursts.first { $0.parent == nil } ?? {
            let made = SKSpriteNode()
            made.colorBlendFactor = 1
            bursts.append(made)
            return made
        }()
        guard sprite.parent == nil, effects.children.count < 120 else { return }
        sprite.texture = ring ? art.ring : art.glow
        sprite.blendMode = ring ? .alpha : .add
        sprite.color = color
        sprite.alpha = 0.9
        let size = CGFloat(radius) * 2 * Self.tile
        sprite.size = CGSize(width: size, height: size)
        sprite.setScale(0.4)
        sprite.position = CGPoint(x: CGFloat(x) * Self.tile, y: CGFloat(y) * Self.tile + (ring ? 0 : Self.tile * 0.3))
        sprite.userData = ["born": clock, "life": ring ? 0.35 : 0.45, "grow": 1.0]
        effects.addChild(sprite)
    }

    private func fadeEffects(_ now: TimeInterval) {
        for node in effects.children {
            guard let born = node.userData?["born"] as? TimeInterval, let life = node.userData?["life"] as? Double else { continue }
            let t = CGFloat((now - born) / life)
            if t >= 1 {
                node.removeFromParent()
                continue
            }
            node.alpha = 1 - t * t
            if let rise = node.userData?["rise"] as? CGFloat {
                node.position.y += rise * CGFloat(1 / 60.0 / life)
            }
            if node.userData?["grow"] != nil {
                node.setScale(0.4 + 0.6 * sqrt(t))
            }
        }
    }

    // MARK: Camera

    private func layoutCamera() {
        vignette.size = CGSize(width: size.width * 1.6, height: size.height * 1.3)
    }

    private func follow(_ hero: CGPoint) {
        // The HUD covers the bottom of the screen, so the room is framed in the space above it.
        let hud = size.height * 0.24
        let x = roomSize.width <= size.width
            ? roomSize.width / 2
            : min(max(hero.x, size.width / 2), roomSize.width - size.width / 2)
        let low = size.height / 2 - hud
        let high = roomSize.height - size.height / 2
        let y = low > high ? roomSize.height / 2 - hud / 2 : min(max(hero.y - hud / 2, low), high)
        let target = CGPoint(x: x, y: y)
        let position = cameraNode.position
        cameraNode.position = CGPoint(x: position.x + (target.x - position.x) * 0.15, y: position.y + (target.y - position.y) * 0.15)
    }
}

// MARK: - Actor node

/// One creature, projectile, or summon. The sim only reports pose; this turns it into motion.
final class ActorNode: SKNode {
    let body: SKSpriteNode
    private let shadow: SKSpriteNode
    private let outline: SKSpriteNode?
    private let bar: SKSpriteNode?
    private let barFill: SKSpriteNode?
    private let seed: Double
    private let kind: ActorKind

    init(pose: EntityPose, art: ArtLibrary) {
        kind = pose.kind
        seed = Double(pose.id % 17) * 0.37
        body = SKSpriteNode(texture: art.texture(pose.sprite))
        let tile = RiftScene.tile
        body.size = CGSize(width: tile, height: tile)
        body.anchorPoint = CGPoint(x: 0.5, y: 0.12)
        body.shader = art.flash
        shadow = SKSpriteNode(texture: art.shadow)
        shadow.size = CGSize(width: tile * 0.7, height: tile * 0.25)
        shadow.alpha = 0.45
        shadow.zPosition = -2
        if pose.elite {
            let ring = SKSpriteNode(texture: art.texture(pose.sprite))
            ring.size = CGSize(width: tile * 1.18, height: tile * 1.18)
            ring.anchorPoint = CGPoint(x: 0.5, y: 0.14)
            ring.shader = art.silhouette
            ring.zPosition = -1
            outline = ring
        } else {
            outline = nil
        }
        if pose.hostile, pose.kind != .projectile, pose.kind != .zone {
            let back = SKSpriteNode(color: SKColor(white: 0, alpha: 0.6), size: CGSize(width: tile * 0.7, height: 3))
            back.anchorPoint = CGPoint(x: 0, y: 0.5)
            back.position = CGPoint(x: -tile * 0.35, y: tile * 1.05)
            let fill = SKSpriteNode(color: pose.elite ? Palette.elite : Palette.hurt, size: CGSize(width: tile * 0.7, height: 3))
            fill.anchorPoint = CGPoint(x: 0, y: 0.5)
            back.addChild(fill)
            back.isHidden = true
            bar = back
            barFill = fill
        } else {
            bar = nil
            barFill = nil
        }
        super.init()
        if pose.kind == .projectile {
            body.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            body.size = CGSize(width: tile * 0.75, height: tile * 0.75)
            if pose.sprite.hasPrefix("fx.") {
                body.shader = nil
                body.texture = art.glow
                body.color = pose.hostile ? Palette.enemyBolt : Palette.heroBolt
                body.colorBlendFactor = 1
                body.blendMode = .add
                body.size = CGSize(width: tile * 0.6, height: tile * 0.6)
            }
        } else {
            addChild(shadow)
        }
        if body.shader != nil {
            body.setValue(SKAttributeValue(float: 0), forAttribute: "a_flash")
            body.setValue(SKAttributeValue(vectorFloat4: .zero), forAttribute: "a_tint")
        }
        if let outline { addChild(outline) }
        addChild(body)
        if let bar { addChild(bar) }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func apply(_ pose: EntityPose, time: TimeInterval, paused: Bool) {
        let t = paused ? 0 : time
        if kind == .projectile {
            body.zRotation = CGFloat(atan2(pose.dy, pose.dx)) - (body.blendMode == .add ? 0 : .pi / 4)
            return
        }
        let tile = RiftScene.tile
        let phase = CGFloat(pose.phase)
        var offset = CGPoint.zero
        var lean: CGFloat = 0
        var squash: CGFloat = 1
        var alpha: CGFloat = 1
        var flash: CGFloat = 0
        switch pose.anim {
        case .idle:
            offset.y = CGFloat(sin(t * 3.2 + seed)) * RiftScene.pixel * 0.6
        case .walk:
            offset.y = abs(CGFloat(sin(t * 11 + seed))) * RiftScene.pixel * 1.5
        case .windup:
            lean = -CGFloat(pose.facing) * 0.22 * phase
            squash = 1 - 0.12 * phase
            flash = 0.25 * phase
        case .attack:
            offset.x = CGFloat(pose.facing) * tile * 0.18 * (1 - phase)
            lean = CGFloat(pose.facing) * 0.12 * (1 - phase)
        case .hit:
            flash = 1 - phase
            offset.x = -CGFloat(pose.facing) * RiftScene.pixel * 2 * (1 - phase)
        case .death:
            squash = max(0.1, 1 - 0.85 * phase)
            alpha = 1 - phase
        }
        body.position = offset
        body.zRotation = lean
        body.xScale = CGFloat(pose.facing < 0 ? -1 : 1)
        body.yScale = squash
        body.alpha = alpha
        if body.shader != nil {
            let tint: SIMD4<Float> = pose.rooted ? SIMD4(0.45, 0.85, 0.4, 0.45) : pose.stunned ? SIMD4(1, 0.9, 0.4, 0.45) : .zero
            body.setValue(SKAttributeValue(float: Float(flash)), forAttribute: "a_flash")
            body.setValue(SKAttributeValue(vectorFloat4: tint), forAttribute: "a_tint")
        }
        outline?.position = offset
        outline?.zRotation = lean
        outline?.xScale = body.xScale * 1
        outline?.yScale = squash
        outline?.alpha = alpha * (0.75 + 0.25 * CGFloat(sin(t * 6)))
        shadow.alpha = 0.45 * alpha
        if let bar, let barFill {
            let fraction = pose.maxHP > 0 ? CGFloat(max(0, pose.hp) / pose.maxHP) : 0
            bar.isHidden = fraction >= 1 || fraction <= 0
            barFill.xScale = fraction
        }
        _ = tile
    }
}

// MARK: - Ground marks

/// A telegraph or a lingering zone: a filled shape with a bright edge, drawn above the floor and below bodies.
final class MarkNode: SKNode {
    private let fill: SKSpriteNode
    private let edge: SKSpriteNode
    private let glow: SKSpriteNode?
    private let telegraph: Bool

    init(art: ArtLibrary, color: SKColor, telegraph: Bool) {
        self.telegraph = telegraph
        fill = SKSpriteNode(texture: art.disc)
        fill.color = color
        fill.colorBlendFactor = 1
        fill.alpha = telegraph ? 0.45 : 0.28
        edge = SKSpriteNode(texture: art.ring)
        edge.color = color
        edge.colorBlendFactor = 1
        edge.alpha = 0.95
        if telegraph {
            glow = nil
        } else {
            let light = SKSpriteNode(texture: art.glow)
            light.color = color
            light.colorBlendFactor = 1
            light.blendMode = .add
            light.alpha = 0.35
            glow = light
        }
        super.init()
        if let glow { addChild(glow) }
        addChild(fill)
        addChild(edge)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func set(radius: CGFloat, amount: CGFloat) {
        let size = CGSize(width: radius * 2, height: radius * 2)
        edge.size = size
        if telegraph {
            fill.size = CGSize(width: size.width * max(0.05, amount), height: size.height * max(0.05, amount))
            edge.alpha = 0.6 + 0.4 * amount
        } else {
            fill.size = size
            glow?.size = CGSize(width: size.width * 1.4, height: size.height * 1.4)
            alpha = min(1, 0.3 + amount * 2)
        }
    }
}
