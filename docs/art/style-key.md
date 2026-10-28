# Style key

The brief for commissioned gap art. Kenney's Tiny Dungeon is the reference: match it so a commissioned slime and a Kenney slime can stand in the same room. The M0 build is the live reference. It puts a Tiny Dungeon room and a Roguelike Characters hero on one phone screen.

## Rules

- 16×16 canvas, transparent background, one frame. Guardians and Wardens are 32×32. The game animates every sprite in code (bob, lean, lunge, flash, squash), so no frames are needed.
- Colors only from `palette.gpl`. Each biome uses its 12 colors in `biome-palettes.json`. Echo variants are a shader swap; do not paint them.
- Outline: 1 px, closed, in `ink` (#262b44) or `shadow` (#3f2631). No anti-aliasing and no partial alpha.
- Shading: two or three tones per material. Light comes from the top left. No dithering and no gradients.
- Silhouette first. A creature must read in under half a second at iPhone mini size, against both sand and brick. Fill most of the canvas and keep the feet on the bottom 2 rows.
- Face right. The game mirrors for left.
- Reserved colors. Telegraph orange (#f26b40) and enemy-bolt purple (#bf4dd9) are reserved for warnings. Keep them off creature bodies at large sizes.
- Tone: creepy-cute (mushrooms, moths, clockwork, drowned books). No gore, and nothing that copies a real-world IP.

## Gaps (143)

`docs/art/kenney-map.json` marks each one as `{"gap": "<id>"}`. The game shows a placeholder until the PNG lands, so art can arrive in any order.

| Group | Count | Ids |
| --- | --- | --- |
| Creatures | 52 | `creature.*` rows in `Content/mobs.json` without a Kenney sprite |
| Guardians, Wardens | 17 | `guardian.*`, `warden.*` (32×32) |
| Relic icons | 30 | `icon.relic.<relic id>` |
| Charm icons | 24 | `icon.charm.<charm id>` |
| Summons | 4 | `summon.hound`, `summon.wisp`, `summon.moth_decoy`, `summon.soldier` |
| Weapons | 3 | `weapon.crossbow`, `weapon.sling`, `weapon.scythe`, as Roguelike Characters paper-doll weapon layers |
| Light set, pet | 4 | `prop.lantern`, `prop.campfire`, `prop.candle`, `pet.moth` |
| Other | 9 | `tile.water`, `prop.lighthouse`, armor-slot icons, material icons |

Families anchored on a Kenney creature (rats, slimes, rubble folk, spiders, page ghosts, inkcrabs) should borrow that creature's proportions and outline weight.

## Delivery and acceptance

- Drop one PNG per id in `Art/commission/<id>.png`. A map entry then becomes `{"commission": "Art/commission/<id>.png"}`, and `swift scripts/build-atlas.swift` packs it.
- Accepted when the sprite holds up on a physical iPhone in the M0 room at 1×: it reads in under half a second, its outline matches the Kenney neighbors, and it uses no off-palette colors.
