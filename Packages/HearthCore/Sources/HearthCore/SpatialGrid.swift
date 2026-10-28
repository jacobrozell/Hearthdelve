/// One bucket per tile holding actor indices. Rebuilt in index order, so queries come back in a fixed order.
struct SpatialGrid: Sendable {
    let width: Int
    let height: Int
    private var buckets: [[Int]]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        buckets = Array(repeating: [], count: width * height)
    }

    mutating func rebuild(_ actors: [Actor]) {
        for index in buckets.indices { buckets[index].removeAll(keepingCapacity: true) }
        for (index, actor) in actors.enumerated() where actor.living && actor.kind != .hero {
            let x = min(max(Int(actor.x), 0), width - 1)
            let y = min(max(Int(actor.y), 0), height - 1)
            buckets[y * width + x].append(index)
        }
    }

    func query(x: Double, y: Double, radius: Double) -> [Int] {
        let minX = max(Int(x - radius), 0)
        let maxX = min(Int(x + radius), width - 1)
        let minY = max(Int(y - radius), 0)
        let maxY = min(Int(y + radius), height - 1)
        guard minX <= maxX, minY <= maxY else { return [] }
        var found: [Int] = []
        for row in minY...maxY {
            for column in minX...maxX {
                found.append(contentsOf: buckets[row * width + column])
            }
        }
        return found
    }
}
