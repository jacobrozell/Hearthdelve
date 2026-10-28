public struct GridRect: Codable, Sendable, Equatable {
    public var x: Int
    public var y: Int
    public var w: Int
    public var h: Int

    public init(x: Int, y: Int, w: Int, h: Int) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }
}

public struct GridPoint: Codable, Sendable, Equatable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// One 16×16 room chunk as exported from Tiled. Rows run top to bottom. Tile ids are Tiled gids:
/// 0 is empty, otherwise the tileset index plus one.
public struct RoomTemplate: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var biome: String
    public var tileset: String
    public var width: Int
    public var height: Int
    public var tag: String
    public var tiles: [Int]
    public var objects: [Int]
    public var collision: [Int]
    public var spawns: [GridRect]
    public var hero: GridPoint

    public init(id: String, biome: String, tileset: String, width: Int, height: Int, tag: String, tiles: [Int], objects: [Int], collision: [Int], spawns: [GridRect], hero: GridPoint) {
        self.id = id
        self.biome = biome
        self.tileset = tileset
        self.width = width
        self.height = height
        self.tag = tag
        self.tiles = tiles
        self.objects = objects
        self.collision = collision
        self.spawns = spawns
        self.hero = hero
    }

    /// Builds a collision-only room from text rows: `#` is a wall, `H` the hero, `S` a one-tile spawn.
    public static func ascii(_ rows: [String], id: String = "ascii") -> RoomTemplate {
        let height = rows.count
        let width = rows[0].count
        var collision: [Int] = []
        var spawns: [GridRect] = []
        var hero = GridPoint(x: width / 2, y: height - 2)
        for (row, line) in rows.enumerated() {
            for (column, character) in line.enumerated() {
                collision.append(character == "#" ? 1 : 0)
                if character == "H" { hero = GridPoint(x: column, y: row) }
                if character == "S" { spawns.append(GridRect(x: column, y: row, w: 1, h: 1)) }
            }
        }
        return RoomTemplate(
            id: id, biome: "mossy_cellars", tileset: "tiny-dungeon", width: width, height: height, tag: "arena",
            tiles: Array(repeating: 49, count: width * height), objects: Array(repeating: 0, count: width * height),
            collision: collision, spawns: spawns, hero: hero
        )
    }

    /// Collision in sim space: y grows upward, so file row 0 is the top row.
    public func blockedGrid() -> [Bool] {
        var blocked = Array(repeating: false, count: width * height)
        for row in 0..<height {
            for column in 0..<width where collision[row * width + column] != 0 {
                blocked[(height - 1 - row) * width + column] = true
            }
        }
        return blocked
    }
}
