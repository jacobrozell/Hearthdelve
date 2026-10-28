import CoreGraphics
import SpriteKit

/// Textures by contract id. Sprites come from the Hearth atlas, room tiles from the Tiles atlas,
/// and telegraph shapes and glows are drawn in code so they stay crisp at any radius.
@MainActor
final class ArtLibrary {
    let disc: SKTexture
    let ring: SKTexture
    /// A thick rim so a telegraph reads as an edge, not a hairline.
    let boldRing: SKTexture
    /// A wide annulus, for ring-shaped attacks that should still look filled.
    let band: SKTexture
    let glow: SKTexture
    let shadow: SKTexture
    let vignette: SKTexture
    /// Mixes a sprite toward white by `a_flash`, so hit flashes read as white rather than tinted.
    let flash: SKShader
    /// Draws only a sprite's silhouette in `u_color`, for the elite outline behind the body.
    let silhouette: SKShader

    private let hearth: SKTextureAtlas
    private let tiles: SKTextureAtlas
    private let hearthNames: Set<String>
    private let tileNames: Set<String>
    private var cache: [String: SKTexture] = [:]
    private var tileGroups: [Int: SKTileGroup] = [:]
    private lazy var missing: SKTexture = Self.draw(size: 16) { context, size in
        context.setFillColor(CGColor(red: 0.85, green: 0.35, blue: 0.75, alpha: 1))
        context.fill(CGRect(x: 3, y: 2, width: size - 6, height: size - 5))
        context.setFillColor(CGColor(red: 0.1, green: 0.05, blue: 0.15, alpha: 1))
        context.fill(CGRect(x: 5, y: 9, width: 2, height: 2))
        context.fill(CGRect(x: 9, y: 9, width: 2, height: 2))
    }

    init() {
        flash = SKShader(source: """
        void main() {
            vec4 c = texture2D(u_texture, v_tex_coord);
            vec3 tinted = mix(c.rgb, a_tint.rgb * c.a, a_tint.a);
            gl_FragColor = vec4(mix(tinted, vec3(c.a), a_flash), c.a) * v_color_mix.a;
        }
        """)
        flash.attributes = [SKAttribute(name: "a_flash", type: .float), SKAttribute(name: "a_tint", type: .vectorFloat4)]
        silhouette = SKShader(source: """
        void main() {
            float a = texture2D(u_texture, v_tex_coord).a;
            gl_FragColor = vec4(u_color.rgb * a, a) * v_color_mix.a;
        }
        """)
        silhouette.uniforms = [SKUniform(name: "u_color", vectorFloat4: SIMD4<Float>(0.35, 0.6, 1, 1))]
        hearth = SKTextureAtlas(named: "Hearth")
        tiles = SKTextureAtlas(named: "Tiles")
        hearthNames = Set(hearth.textureNames.map(Self.bare))
        tileNames = Set(tiles.textureNames.map(Self.bare))
        disc = Self.draw(size: 64, smooth: true) { context, size in
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fillEllipse(in: CGRect(x: 1, y: 1, width: size - 2, height: size - 2))
        }
        ring = Self.draw(size: 64, smooth: true) { context, size in
            context.setStrokeColor(CGColor(gray: 1, alpha: 1))
            context.setLineWidth(3)
            context.strokeEllipse(in: CGRect(x: 2.5, y: 2.5, width: size - 5, height: size - 5))
        }
        boldRing = Self.draw(size: 64, smooth: true) { context, size in
            context.setStrokeColor(CGColor(gray: 1, alpha: 1))
            context.setLineWidth(8)
            context.strokeEllipse(in: CGRect(x: 5, y: 5, width: size - 10, height: size - 10))
        }
        band = Self.draw(size: 64, smooth: true) { context, size in
            context.setStrokeColor(CGColor(gray: 1, alpha: 1))
            context.setLineWidth(22)
            context.strokeEllipse(in: CGRect(x: 12, y: 12, width: size - 24, height: size - 24))
        }
        glow = Self.gradient(size: 64, inner: 1, outer: 0)
        vignette = Self.gradient(size: 128, inner: 0, outer: 1, color: CGColor(red: 0.06, green: 0.04, blue: 0.1, alpha: 1), start: 0.55)
        shadow = Self.draw(size: 32, smooth: true) { context, size in
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    /// `creature.slime` lives in the atlas as `creature_slime`. Gaps fall back to a placeholder so missing art is obvious.
    func texture(_ id: String) -> SKTexture {
        if let texture = cache[id] { return texture }
        let name = id.replacingOccurrences(of: ".", with: "_")
        let texture: SKTexture
        if hearthNames.contains(name) {
            texture = hearth.textureNamed(name)
        } else {
            texture = missing
        }
        texture.filteringMode = .nearest
        cache[id] = texture
        return texture
    }

    /// A tile map for one room layer. Values are Tiled gids: tile index + 1, 0 for empty. Row 0 is the top row.
    func tileMap(_ gids: [Int], width: Int, height: Int, tileset: String) -> SKTileMapNode {
        var groups: [SKTileGroup] = []
        for gid in Set(gids).sorted() where gid > 0 {
            groups.append(group(gid - 1, tileset: tileset))
        }
        let size = CGSize(width: RiftScene.tile, height: RiftScene.tile)
        let map = SKTileMapNode(tileSet: SKTileSet(tileGroups: groups), columns: width, rows: height, tileSize: size)
        map.anchorPoint = .zero
        map.enableAutomapping = false
        for row in 0..<height {
            for column in 0..<width {
                let gid = gids[row * width + column]
                guard gid > 0 else { continue }
                map.setTileGroup(group(gid - 1, tileset: tileset), forColumn: column, row: height - 1 - row)
            }
        }
        return map
    }

    private func group(_ index: Int, tileset: String) -> SKTileGroup {
        if let group = tileGroups[index] { return group }
        let name = String(format: "%@_%04d", tileset, index)
        let texture = tileNames.contains(name) ? tiles.textureNamed(name) : missing
        texture.filteringMode = .nearest
        let definition = SKTileDefinition(texture: texture, size: CGSize(width: RiftScene.tile, height: RiftScene.tile))
        let group = SKTileGroup(tileDefinition: definition)
        tileGroups[index] = group
        return group
    }

    private static func bare(_ name: String) -> String {
        var name = name
        if name.hasSuffix(".png") { name.removeLast(4) }
        if name.hasSuffix("@2x") || name.hasSuffix("@3x") { name.removeLast(3) }
        return name
    }

    private static func draw(size: Int, smooth: Bool = false, _ body: (CGContext, CGFloat) -> Void) -> SKTexture {
        let context = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setShouldAntialias(smooth)
        body(context, CGFloat(size))
        let texture = SKTexture(cgImage: context.makeImage()!)
        texture.filteringMode = smooth ? .linear : .nearest
        return texture
    }

    private static func gradient(size: Int, inner: CGFloat, outer: CGFloat, color: CGColor = CGColor(gray: 1, alpha: 1), start: CGFloat = 0) -> SKTexture {
        draw(size: size, smooth: true) { context, side in
            let components = color.components ?? [1, 1, 1, 1]
            let r = components.count >= 3 ? components[0] : components[0]
            let g = components.count >= 3 ? components[1] : components[0]
            let b = components.count >= 3 ? components[2] : components[0]
            let colors = [CGColor(srgbRed: r, green: g, blue: b, alpha: inner), CGColor(srgbRed: r, green: g, blue: b, alpha: inner), CGColor(srgbRed: r, green: g, blue: b, alpha: outer)]
            let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: [0, start, 1])!
            let center = CGPoint(x: side / 2, y: side / 2)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: side / 2, options: [.drawsAfterEndLocation])
        }
    }
}

/// Render colors. Hero shots are lighter and more saturated than enemy ones; telegraphs are warm and loud.
enum Palette {
    static let telegraphSlam = SKColor(red: 0.95, green: 0.42, blue: 0.25, alpha: 1)
    static let telegraphBolt = SKColor(red: 0.8, green: 0.45, blue: 0.95, alpha: 1)
    static let heroBolt = SKColor(red: 1, green: 0.95, blue: 0.6, alpha: 1)
    static let enemyBolt = SKColor(red: 0.75, green: 0.3, blue: 0.85, alpha: 1)
    static let damage = SKColor(red: 1, green: 0.96, blue: 0.86, alpha: 1)
    static let crit = SKColor(red: 1, green: 0.8, blue: 0.25, alpha: 1)
    static let hurt = SKColor(red: 0.93, green: 0.33, blue: 0.36, alpha: 1)
    static let heal = SKColor(red: 0.5, green: 0.9, blue: 0.45, alpha: 1)
    static let elite = SKColor(red: 0.35, green: 0.6, blue: 1, alpha: 1)
    static let dust = SKColor(red: 0.85, green: 0.8, blue: 0.7, alpha: 1)
    static let cleave = SKColor(red: 1, green: 1, blue: 1, alpha: 1)

    static func telegraph(_ kind: String) -> SKColor {
        kind == "slam" ? telegraphSlam : telegraphBolt
    }

    static func element(_ element: String) -> SKColor {
        switch element {
        case "fire": SKColor(red: 1, green: 0.5, blue: 0.2, alpha: 1)
        case "frost": SKColor(red: 0.55, green: 0.85, blue: 1, alpha: 1)
        case "nature": SKColor(red: 0.45, green: 0.85, blue: 0.35, alpha: 1)
        case "radiant": SKColor(red: 1, green: 0.9, blue: 0.5, alpha: 1)
        case "shadow": SKColor(red: 0.55, green: 0.4, blue: 0.85, alpha: 1)
        default: SKColor(red: 0.9, green: 0.88, blue: 0.82, alpha: 1)
        }
    }
}
