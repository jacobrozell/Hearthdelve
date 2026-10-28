# Art contract

16×16 tiles and characters, nearest-neighbor, drawn at 2 points per art pixel. A portrait phone shows about 12 tiles across. Guardians and Wardens may be 32×32. Gameplay code uses the contract ids in `kenney-map.json`, never a pack file name.

Draw order: shadow, telegraph, floor decal, body, legs, chest, boots, helm, weapon, moth, affix icons. Sprites face right. Left is a mirror. Animation ids are `idle`, `walk`, `windup`, `attack`, `hit`, `death`. Each id is a procedural tween unless a sprite supplies frames. Hand-drawn frames are reserved for Guardians.

Hero paper-doll layers come from Roguelike Characters. Generic armor is a recolor. The six sets are distinct combinations plus a tint. An elite is a tint plus a floating icon. Echo biomes are a darker, cooler palette swap plus one new attack.

`tilemap_packed.png` is a tight 12×11 grid of 16×16 (192×176). `tilemap.png` is the same grid with a 1px gutter (203×186). Indices match `Tiles/tile_NNNN.png`.

In-world UI uses UI Pack - Pixel Adventure: panels, buttons, and bars as resizable images with cap insets and `.interpolation(.none)`. UI Pixel Pack stays vendored as the fallback. System screens stay native SwiftUI inside those frames. Kenney Pixel is the title, HUD, and item-name font, only at whole-number scales. Body text is SF Pro Rounded.

The master palette is `palette.gpl`, sampled from Tiny Dungeon and Tiny Town. Hearth amber `#fdbe53` and grass `#84c669` are Tiny Town colors. Biome lists in `biome-palettes.json` pick 12 of those colors. Echoes are a palette-swap shader, not new paints.

Room chunks are 16×16, authored in Tiled, and exported as JSON (`Content/schema/room.schema.json`) with tile ids, collision, spawn rects, and a tag: `entry`, `stairs`, `arena`, or `side`.

## Pipeline

`swift scripts/build-atlas.swift` reads `kenney-map.json` and writes `App/Assets.xcassets`: `Hearth.spriteatlas` (contract sprites, composed from layers when an entry has `layers`) and `Tiles.spriteatlas` (every Tiny Dungeon tile, named `tiny-dungeon_NNNN`). Asset names are the contract id with `.` replaced by `_`. Gaps render as a magenta-outlined placeholder, so missing art never crashes. Re-run the script after editing the map. The commission brief is `style-key.md`.

The hero is Roguelike Characters layers `0` (body), `3, 4, 6, 19` (outfit and hair), plus `368` (sword) or `52` (bow). The render shows the sword when a target is within 3 tiles and the bow otherwise.

Rendering: nearest filtering everywhere. Feedback is procedural: hit flash and elite outline are `SKShader`s, and telegraphs are a filled disc that fills toward the strike plus a bright edge ring. There is also additive ember glow, a hero light, and a vignette. The HUD sits in the bottom 24% of the screen, and the camera keeps the room above it.

Vendored packs are unmodified Kenney CC0, licenses kept beside the files. Credit Kenney on the About screen. Ids marked `gap:` wait for the commission that starts when the fun gate passes.
