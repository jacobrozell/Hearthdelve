import CoreGraphics
import Foundation

/// One cottage or the well on the hand-built hamlet. `row` is the top row. Row 0 is the north edge.
public struct VillageBuilding: Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var column: Int
    public var row: Int
    public var width: Int
    public var height: Int
    /// Nil when the building can be opened. Otherwise the Depth that opens its system.
    public var unlockDepth: Int?
    public var accessibilityLabel: String
}

/// A snapshot the village scene draws. The renderer does not decide what a tap means.
public struct VillageSnapshot: Sendable, Equatable {
    public var columns: Int
    public var rows: Int
    public var tileset: String
    /// Tiled gids, row 0 at the top. Tile index + 1, never 0.
    public var ground: [Int]
    /// Tiled gids for props. 0 is empty.
    public var props: [Int]
    public var buildings: [VillageBuilding]
}

/// Screen placement for a building button. The camera sits on a scene point. Y grows up in the scene and down on the phone.
public enum VillageFrame {
    public static func sceneCenter(building: VillageBuilding, rows: Int, tile: CGFloat) -> CGPoint {
        let x = (CGFloat(building.column) + CGFloat(building.width) / 2) * tile
        let y = (CGFloat(rows) - CGFloat(building.row) - CGFloat(building.height) / 2) * tile
        return CGPoint(x: x, y: y)
    }

    public static func viewRect(building: VillageBuilding, rows: Int, camera: CGPoint, viewSize: CGSize, tile: CGFloat) -> CGRect {
        let center = sceneCenter(building: building, rows: rows, tile: tile)
        let viewX = viewSize.width / 2 + (center.x - camera.x)
        let viewY = viewSize.height / 2 - (center.y - camera.y)
        let width = max(tile * 2, CGFloat(building.width) * tile)
        let height = max(tile * 2, CGFloat(building.height) * tile)
        return CGRect(x: viewX - width / 2, y: viewY - height / 2, width: width, height: height)
    }
}

/// One hamlet, about two phone screens wide. Kenney Tiny Town indices. Gids are index + 1.
public enum VillageHamlet {
    public static let columns = 26
    public static let rows = 36

    public static func depthUnlocks(_ buildings: [BuildingDefinition]) -> [String: Int] {
        var unlocks: [String: Int] = [:]
        for building in buildings {
            if case .depth(let depth) = building.unlock {
                unlocks[building.id] = depth
            }
        }
        return unlocks
    }

    public static func make(names: [String: String] = [:], unlocks: [String: Int] = [:]) -> VillageSnapshot {
        let depths = unlocks.isEmpty ? ["apothecary": 2, "library": 3, "map_room": 5] : unlocks
        var ground = [Int](repeating: 1, count: columns * rows)
        for row in 0..<rows {
            for column in 0..<columns {
                ground[row * columns + column] = (column + row * 2) % 3 + 1
            }
        }
        var props = [Int](repeating: 0, count: columns * rows)
        func paint(_ column: Int, _ row: Int, _ tile: Int, into layer: inout [Int]) {
            guard column >= 0, row >= 0, column < columns, row < rows else { return }
            layer[row * columns + column] = tile + 1
        }
        for column in 0..<columns {
            let west = column == 0
            let east = column == columns - 1
            paint(column, 16, west ? 12 : east ? 14 : 13, into: &ground)
            paint(column, 17, west ? 24 : east ? 26 : 25, into: &ground)
            paint(column, 18, west ? 36 : east ? 38 : 37, into: &ground)
        }
        stamp(column: 1, row: 12, roof: .tile, wall: .wood, into: &ground)
        stamp(column: 7, row: 12, roof: .slate, wall: .stone, into: &ground)
        stamp(column: 16, row: 12, roof: .slate, wall: .wood, into: &ground)
        stamp(column: 21, row: 12, roof: .tile, wall: .stone, into: &ground)
        paint(3, 16, 107, into: &props)
        paint(9, 16, 115, into: &props)
        paint(23, 16, 83, into: &props)
        paint(13, 17, 104, into: &props)

        func title(_ id: String, _ fallback: String) -> String { names[id] ?? fallback }
        let buildings = [
            cottage("apothecary", title("apothecary", "Apothecary"), column: 1, depth: depths["apothecary"] ?? 2),
            cottage("blacksmith", title("blacksmith", "Blacksmith"), column: 7, depth: depths["blacksmith"]),
            VillageBuilding(
                id: "well", name: "The well", column: 13, row: 17, width: 1, height: 1,
                unlockDepth: nil, accessibilityLabel: "The well"
            ),
            cottage("library", title("library", "Library"), column: 16, depth: depths["library"] ?? 3),
            cottage("map_room", title("map_room", "Map Room"), column: 21, depth: depths["map_room"] ?? 5),
        ]
        return VillageSnapshot(columns: columns, rows: rows, tileset: "tiny-town", ground: ground, props: props, buildings: buildings)
    }

    private static func cottage(_ id: String, _ name: String, column: Int, depth: Int?) -> VillageBuilding {
        VillageBuilding(
            id: id, name: name, column: column, row: 12, width: 4, height: 4,
            unlockDepth: depth, accessibilityLabel: name
        )
    }

    private enum Roof { case slate, tile }
    private enum Wall { case wood, stone }

    private static func stamp(column: Int, row: Int, roof: Roof, wall: Wall, into ground: inout [Int]) {
        let roofTop = roof == .slate ? [48, 49, 50, 51] : [52, 53, 54, 55]
        let roofEave = roof == .slate ? [60, 61, 62, 63] : [64, 65, 66, 67]
        let walls = wall == .wood ? [72, 73, 74, 75] : [76, 77, 78, 79]
        let base = wall == .wood ? [84, 85, 86, 87] : [88, 89, 90, 91]
        let bands = [roofTop, roofEave, walls, base]
        for (offset, tiles) in bands.enumerated() {
            for (shift, tile) in tiles.enumerated() {
                let x = column + shift
                let y = row + offset
                guard x >= 0, y >= 0, x < columns, y < Self.rows else { continue }
                ground[y * columns + x] = tile + 1
            }
        }
    }
}
