// Packs contract ids from docs/art/kenney-map.json into App/Assets.xcassets.
// Hearth.spriteatlas holds one image per contract id ("creature.slime" -> "creature_slime"), with `layers` composited.
// Tiles.spriteatlas holds every Tiny Dungeon tile as "tiny-dungeon_0048", for room tile maps.
// Usage:
//   swift scripts/build-atlas.swift                      build the asset catalog and copy the Kenney Pixel font
//   swift scripts/build-atlas.swift contact <pack> <out> [firstColumn lastColumn]  labeled contact sheet of a pack sheet
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let vendor = root.appendingPathComponent("Art/vendor/kenney")

struct Sheet: Decodable {
    var pack: String
    var packed: String?
    var spaced: String?
    var tile: Int
    var columns: Int
    var rows: Int
    var packedSpacing: Int?
    var spacedGutter: Int?
}

struct Layer: Decodable {
    var pack: String
    var index: Int
}

struct Entry: Decodable {
    var pack: String?
    var index: Int?
    var gap: String?
    var commission: String?
    var layers: [Layer]?
}

struct ArtMap: Decodable {
    var sheets: [String: Sheet]
    var entries: [String: Entry]
}

func loadImage(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("Cannot read \(url.path)")
    }
    return image
}

func context(width: Int, height: Int) -> CGContext {
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.interpolationQuality = .none
    return context
}

func write(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

func sheetImage(_ sheet: Sheet) -> (CGImage, Int) {
    if let packed = sheet.packed {
        return (loadImage(vendor.appendingPathComponent(sheet.pack).appendingPathComponent(packed)), sheet.packedSpacing ?? 0)
    }
    return (loadImage(vendor.appendingPathComponent(sheet.pack).appendingPathComponent(sheet.spaced!)), sheet.spacedGutter ?? 1)
}

func crop(_ sheet: Sheet, _ image: CGImage, _ gutter: Int, _ index: Int) -> CGImage {
    let column = index % sheet.columns
    let row = index / sheet.columns
    let rect = CGRect(x: column * (sheet.tile + gutter), y: row * (sheet.tile + gutter), width: sheet.tile, height: sheet.tile)
    return image.cropping(to: rect)!
}

let map = try JSONDecoder().decode(ArtMap.self, from: Data(contentsOf: root.appendingPathComponent("docs/art/kenney-map.json")))
var cache: [String: (CGImage, Int)] = [:]
func tile(_ pack: String, _ index: Int) -> CGImage {
    guard let sheet = map.sheets[pack] else { fatalError("No sheet \(pack)") }
    if cache[pack] == nil { cache[pack] = sheetImage(sheet) }
    let (image, gutter) = cache[pack]!
    return crop(sheet, image, gutter, index)
}

let args = Array(CommandLine.arguments.dropFirst())
if args.first == "contact", args.count >= 3 {
    guard let sheet = map.sheets[args[1]] else { fatalError("No sheet \(args[1])") }
    let first = args.count > 3 ? Int(args[3])! : 0
    let last = args.count > 4 ? Int(args[4])! : sheet.columns - 1
    let scale = 6
    let cell = sheet.tile * scale + 14
    let canvas = context(width: (last - first + 1) * cell, height: sheet.rows * cell)
    canvas.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1))
    canvas.fill(CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height))
    let graphics = NSGraphicsContext(cgContext: canvas, flipped: false)
    NSGraphicsContext.current = graphics
    for index in 0..<(sheet.columns * sheet.rows) {
        let column = index % sheet.columns
        let row = index / sheet.columns
        guard column >= first, column <= last else { continue }
        let x = (column - first) * cell
        let y = canvas.height - (row + 1) * cell
        canvas.draw(tile(args[1], index), in: CGRect(x: x + 7, y: y + 12, width: sheet.tile * scale, height: sheet.tile * scale))
        NSString(string: "\(index)").draw(at: NSPoint(x: x + 2, y: y), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 10), .foregroundColor: NSColor.yellow])
    }
    write(canvas.makeImage()!, to: URL(fileURLWithPath: args[2]))
    exit(0)
}

let catalog = root.appendingPathComponent("App/Assets.xcassets")
let fileManager = FileManager.default
let info = Data(#"{"info":{"author":"xcode","version":1}}"#.utf8)

func folder(_ url: URL) {
    try? fileManager.removeItem(at: url)
    try! fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    try! info.write(to: url.appendingPathComponent("Contents.json"))
}

func imageset(_ image: CGImage, named name: String, in atlas: URL) {
    let set = atlas.appendingPathComponent("\(name).imageset")
    try! fileManager.createDirectory(at: set, withIntermediateDirectories: true)
    write(image, to: set.appendingPathComponent("\(name).png"))
    let contents = #"{"images":[{"filename":"\#(name).png","idiom":"universal"}],"info":{"author":"xcode","version":1}}"#
    try! Data(contents.utf8).write(to: set.appendingPathComponent("Contents.json"))
}

folder(catalog)
let hearth = catalog.appendingPathComponent("Hearth.spriteatlas")
folder(hearth)
var written = 0
var gaps: [String] = []
for (id, entry) in map.entries.sorted(by: { $0.key < $1.key }) {
    let name = id.replacingOccurrences(of: ".", with: "_")
    if let commission = entry.commission {
        imageset(loadImage(root.appendingPathComponent(commission)), named: name, in: hearth)
        written += 1
        continue
    }
    var parts: [Layer] = entry.layers ?? []
    if let pack = entry.pack, let index = entry.index { parts.insert(Layer(pack: pack, index: index), at: 0) }
    if parts.isEmpty {
        gaps.append(id)
        continue
    }
    let size = map.sheets[parts[0].pack]!.tile
    let canvas = context(width: size, height: size)
    for part in parts {
        canvas.draw(tile(part.pack, part.index), in: CGRect(x: 0, y: 0, width: size, height: size))
    }
    imageset(canvas.makeImage()!, named: name, in: hearth)
    written += 1
}

let tiles = catalog.appendingPathComponent("Tiles.spriteatlas")
folder(tiles)
let dungeon = map.sheets["tiny-dungeon"]!
for index in 0..<(dungeon.columns * dungeon.rows) {
    imageset(tile("tiny-dungeon", index), named: String(format: "tiny-dungeon_%04d", index), in: tiles)
}

let fonts = root.appendingPathComponent("App/Fonts")
try? fileManager.createDirectory(at: fonts, withIntermediateDirectories: true)
let font = fonts.appendingPathComponent("KenneyPixel.ttf")
try? fileManager.removeItem(at: font)
try fileManager.copyItem(at: vendor.appendingPathComponent("fonts/Kenney Pixel.ttf"), to: font)

print("assets: \(written) sprites, \(dungeon.columns * dungeon.rows) tiles, \(gaps.count) gaps -> \(catalog.path)")
