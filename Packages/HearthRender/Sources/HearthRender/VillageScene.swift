import SpriteKit
import HearthCore

/// Draws a village snapshot and slides the camera. Taps are buttons in SwiftUI, so this scene never changes the save.
public final class VillageScene: SKScene {
    public static let tile: CGFloat = RiftScene.tile

    private let world = SKNode()
    private let cameraNode = SKCameraNode()
    private let art = ArtLibrary()
    public private(set) var map = VillageHamlet.make()
    public private(set) var cameraPoint = CGPoint.zero

    public override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 132 / 255, green: 198 / 255, blue: 105 / 255, alpha: 1)
        isUserInteractionEnabled = false
        addChild(world)
        camera = cameraNode
        addChild(cameraNode)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        nil
    }

    public func show(_ snapshot: VillageSnapshot) {
        map = snapshot
        world.removeAllChildren()
        let ground = art.tileMap(snapshot.ground, width: snapshot.columns, height: snapshot.rows, tileset: snapshot.tileset)
        let props = art.tileMap(snapshot.props, width: snapshot.columns, height: snapshot.rows, tileset: snapshot.tileset)
        props.zPosition = 1
        world.addChild(ground)
        world.addChild(props)
        for building in snapshot.buildings {
            let label = SKLabelNode(fontNamed: "Kenney-Pixel")
            label.text = building.name
            label.fontSize = 16
            label.fontColor = SKColor(red: 38 / 255, green: 43 / 255, blue: 68 / 255, alpha: 1)
            label.verticalAlignmentMode = .bottom
            label.horizontalAlignmentMode = .center
            label.zPosition = 2
            label.isAccessibilityElement = false
            let center = VillageFrame.sceneCenter(building: building, rows: snapshot.rows, tile: Self.tile)
            label.position = CGPoint(x: center.x, y: center.y + CGFloat(building.height) * Self.tile / 2 + 4)
            world.addChild(label)
        }
        centerOnWell()
    }

    public func centerOnWell() {
        guard let well = map.buildings.first(where: { $0.id == "well" }) else { return }
        cameraPoint = VillageFrame.sceneCenter(building: well, rows: map.rows, tile: Self.tile)
        clampCamera()
    }

    /// Finger deltas in view points. Positive x is right. Positive y is down.
    public func pan(fingerX: CGFloat, fingerY: CGFloat) {
        cameraPoint.x -= fingerX
        cameraPoint.y += fingerY
        clampCamera()
    }

    public func clampCamera() {
        let mapWidth = CGFloat(map.columns) * Self.tile
        let mapHeight = CGFloat(map.rows) * Self.tile
        let halfWidth = max(1, size.width / 2)
        let halfHeight = max(1, size.height / 2)
        cameraPoint.x = clamp(cameraPoint.x, low: min(halfWidth, mapWidth - halfWidth), high: max(halfWidth, mapWidth - halfWidth))
        cameraPoint.y = clamp(cameraPoint.y, low: min(halfHeight, mapHeight - halfHeight), high: max(halfHeight, mapHeight - halfHeight))
        cameraNode.position = cameraPoint
    }

    public override func didMove(to view: SKView) {
        isPaused = false
        if world.children.isEmpty {
            show(map)
        } else {
            clampCamera()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        clampCamera()
    }

    private func clamp(_ value: CGFloat, low: CGFloat, high: CGFloat) -> CGFloat {
        min(high, max(low, value))
    }
}
