/// One floor of the Mossy Cellars: a small graph of room templates.
/// A tree of 4–8 rooms, then 0–2 extra edges. The layout stream decides every choice.
public struct FloorPlan: Sendable, Equatable {
    public struct Room: Sendable, Equatable {
        public var templateID: String
        public var tag: String
        public var links: [Int]
    }

    public var rooms: [Room]
    public var entry: Int
    public var exit: Int
    /// Nil when this floor has no optional side room.
    public var side: Int?

    public var loops: Int {
        let edges = rooms.reduce(0) { $0 + $1.links.count } / 2
        return edges - (rooms.count - 1)
    }

    /// The next room on a shortest path from `index` to the exit. Nil at the exit.
    public func nextHop(from index: Int) -> Int? {
        guard rooms.indices.contains(index), index != exit else { return nil }
        var parent = Array(repeating: -1, count: rooms.count)
        var queue = [exit]
        parent[exit] = exit
        var head = 0
        while head < queue.count {
            let node = queue[head]
            head += 1
            for link in rooms[node].links where parent[link] < 0 {
                parent[link] = node
                queue.append(link)
            }
        }
        let next = parent[index]
        guard next >= 0, next != index else { return nil }
        return next
    }
}

public enum FloorLayout {
    /// `templates` are the Mossy starter kit. The exit is the arena on the last floor and the stairs room otherwise.
    public static func generate(rng: inout Xoshiro256StarStar, templates: [RoomTemplate], lastFloor: Bool) -> FloorPlan {
        precondition(templates.isEmpty == false, "A floor needs at least one room template")
        let count = 4 + Int(rng.next() % 5)
        var links = Array(repeating: [Int](), count: count)
        for index in 1..<count {
            let parent = Int(rng.next() % UInt64(index))
            links[index].append(parent)
            links[parent].append(index)
        }
        let extra = Int(rng.next() % 3)
        var added = 0
        var attempts = 0
        while added < extra, attempts < count * count {
            attempts += 1
            let left = Int(rng.next() % UInt64(count))
            let right = Int(rng.next() % UInt64(count))
            if left == right || links[left].contains(right) { continue }
            links[left].append(right)
            links[right].append(left)
            added += 1
        }

        let exit = farthest(from: 0, links: links)
        var tags = Array(repeating: "", count: count)
        var ids = Array(repeating: "", count: count)
        tags[0] = "entry"
        ids[0] = pick("entry", templates: templates, rng: &rng).id
        let exitTag = lastFloor ? "arena" : "stairs"
        tags[exit] = exitTag
        ids[exit] = pick(exitTag, templates: templates, rng: &rng).id

        var side: Int?
        let leaves = (0..<count).filter { links[$0].count == 1 && $0 != 0 && $0 != exit }
        if leaves.isEmpty == false, rng.next() % 2 == 0 {
            let choice = leaves[Int(rng.next() % UInt64(leaves.count))]
            side = choice
            tags[choice] = "side"
            ids[choice] = pick("side", templates: templates, rng: &rng).id
        }

        let combat = ["corridor", "small", "large", "alcove"]
        var cursor = 0
        for index in 0..<count where ids[index].isEmpty {
            let tag = combat[cursor % combat.count]
            cursor += 1
            tags[index] = tag
            ids[index] = pick(tag, templates: templates, rng: &rng).id
        }

        let rooms = (0..<count).map { index in
            FloorPlan.Room(templateID: ids[index], tag: tags[index], links: links[index])
        }
        return FloorPlan(rooms: rooms, entry: 0, exit: exit, side: side)
    }

    private static func pick(_ tag: String, templates: [RoomTemplate], rng: inout Xoshiro256StarStar) -> RoomTemplate {
        let pool = templates.filter { $0.tag == tag }
        let source = pool.isEmpty ? templates : pool
        return source[Int(rng.next() % UInt64(source.count))]
    }

    private static func farthest(from origin: Int, links: [[Int]]) -> Int {
        var distance = Array(repeating: -1, count: links.count)
        var queue = [origin]
        distance[origin] = 0
        var head = 0
        while head < queue.count {
            let node = queue[head]
            head += 1
            for next in links[node] where distance[next] < 0 {
                distance[next] = distance[node] + 1
                queue.append(next)
            }
        }
        var best = origin
        for index in links.indices where distance[index] > distance[best] {
            best = index
        }
        return best
    }
}
