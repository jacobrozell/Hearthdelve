enum RoomPath {
    static func index(_ x: Int, _ y: Int, width: Int) -> Int {
        y * width + x
    }

    static func flow(width: Int, height: Int, blocked: [Bool], originX: Int, originY: Int) -> (sx: [Int8], sy: [Int8]) {
        let count = width * height
        var distance = Array(repeating: Int.max, count: count)
        var stepX = Array(repeating: Int8(0), count: count)
        var stepY = Array(repeating: Int8(0), count: count)
        guard originX >= 0, originY >= 0, originX < width, originY < height else {
            return (stepX, stepY)
        }
        let origin = index(originX, originY, width: width)
        distance[origin] = 0
        var queue = [origin]
        var head = 0
        let directions = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        while head < queue.count {
            let current = queue[head]
            head += 1
            let x = current % width
            let y = current / width
            for (dx, dy) in directions {
                let nx = x + dx
                let ny = y + dy
                guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                if dx != 0, dy != 0 {
                    if blocked[index(nx, y, width: width)] || blocked[index(x, ny, width: width)] { continue }
                }
                let next = index(nx, ny, width: width)
                if blocked[next] || distance[next] != Int.max { continue }
                distance[next] = distance[current] + 1
                stepX[next] = Int8(-dx)
                stepY[next] = Int8(-dy)
                queue.append(next)
            }
        }
        return (stepX, stepY)
    }

    static func astar(
        width: Int,
        height: Int,
        blocked: [Bool],
        from start: (Int, Int),
        to goal: (Int, Int)
    ) -> [(Int, Int)] {
        guard start != goal else { return [] }
        let count = width * height
        var gScore = Array(repeating: Int.max, count: count)
        var parent = Array(repeating: -1, count: count)
        var closed = Array(repeating: false, count: count)
        let startIndex = index(start.0, start.1, width: width)
        gScore[startIndex] = 0
        var open = [startIndex]
        let directions = [(1, 0, 10), (-1, 0, 10), (0, 1, 10), (0, -1, 10), (1, 1, 14), (1, -1, 14), (-1, 1, 14), (-1, -1, 14)]

        while open.isEmpty == false {
            var best = 0
            var bestF = Int.max
            for (offset, cell) in open.enumerated() {
                let x = cell % width
                let y = cell / width
                let score = gScore[cell] + heuristic(x, y, goal.0, goal.1)
                if score < bestF {
                    bestF = score
                    best = offset
                }
            }
            let current = open.remove(at: best)
            if current == index(goal.0, goal.1, width: width) {
                return rebuild(parent, current: current, width: width, start: startIndex)
            }
            closed[current] = true
            let x = current % width
            let y = current / width
            for (dx, dy, cost) in directions {
                let nx = x + dx
                let ny = y + dy
                guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                if dx != 0, dy != 0 {
                    if blocked[index(nx, y, width: width)] || blocked[index(x, ny, width: width)] { continue }
                }
                let next = index(nx, ny, width: width)
                if blocked[next] || closed[next] { continue }
                let tentative = gScore[current] + cost
                if tentative >= gScore[next] { continue }
                gScore[next] = tentative
                parent[next] = current
                if open.contains(next) == false {
                    open.append(next)
                }
            }
        }
        return []
    }

    /// True when the segment stays in open cells. A coarse sample can jump a corner the shot will hit; this walks every cell the segment enters.
    static func clearLine(blocked: [Bool], width: Int, height: Int, from ax: Double, _ ay: Double, to bx: Double, _ by: Double) -> Bool {
        func blockedCell(_ x: Int, _ y: Int) -> Bool {
            if x < 0 || y < 0 || x >= width || y >= height { return true }
            return blocked[y * width + x]
        }
        let dx = bx - ax
        let dy = by - ay
        var cx = Int(ax)
        var cy = Int(ay)
        let ex = Int(bx)
        let ey = Int(by)
        if cx == ex, cy == ey { return blockedCell(cx, cy) == false }
        let stepX = dx > 0 ? 1 : (dx < 0 ? -1 : 0)
        let stepY = dy > 0 ? 1 : (dy < 0 ? -1 : 0)
        let tDeltaX = stepX == 0 ? Double.infinity : abs(1 / dx)
        let tDeltaY = stepY == 0 ? Double.infinity : abs(1 / dy)
        let nextX = stepX > 0 ? Double(cx + 1) : Double(cx)
        let nextY = stepY > 0 ? Double(cy + 1) : Double(cy)
        var tMaxX = stepX == 0 ? Double.infinity : (nextX - ax) / dx
        var tMaxY = stepY == 0 ? Double.infinity : (nextY - ay) / dy
        var steps = 0
        while steps < width + height + 4 {
            steps += 1
            if tMaxX < tMaxY {
                if tMaxX > 1 { return true }
                cx += stepX
                tMaxX += tDeltaX
            } else if tMaxY < tMaxX {
                if tMaxY > 1 { return true }
                cy += stepY
                tMaxY += tDeltaY
            } else {
                if tMaxX > 1 { return true }
                if blockedCell(cx + stepX, cy) || blockedCell(cx, cy + stepY) { return false }
                cx += stepX
                cy += stepY
                tMaxX += tDeltaX
                tMaxY += tDeltaY
            }
            if blockedCell(cx, cy) { return false }
            if cx == ex, cy == ey { return true }
        }
        return false
    }

    private static func heuristic(_ x: Int, _ y: Int, _ gx: Int, _ gy: Int) -> Int {
        let dx = abs(x - gx)
        let dy = abs(y - gy)
        return max(dx, dy) * 10 + min(dx, dy) * 4
    }

    private static func rebuild(_ parent: [Int], current: Int, width: Int, start: Int) -> [(Int, Int)] {
        var path: [(Int, Int)] = []
        var cursor = current
        while cursor != start && cursor >= 0 {
            path.append((cursor % width, cursor / width))
            cursor = parent[cursor]
        }
        path.reverse()
        return path
    }
}
