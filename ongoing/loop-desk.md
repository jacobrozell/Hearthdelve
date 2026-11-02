# Desk loop

Drafted 2026-11-01. Spec wins on rules. This pass changes how the screens share one decision. It does not add buildings, tactics, prices, or save fields. The three slices and the app wiring are in the tree and uncommitted.

## Order

1. Pure rules and the two UI files, in parallel. New parameters have defaults so `App/HearthdelveApp.swift` still compiles.
2. Wire the app: well, result desk, bag opens the smith on one piece, locked doors, potion long-press, expedition return.
3. Player guide, then a simulator pass. Do not commit unless asked.

## Contracts

### HearthCore `DeskRules`

One id per slot.

- **Upgrade.** Not worn. Weapons and relics: damage arrow up, toughness not down. Armor: toughness arrow up, damage not down. Keep the best item level, then id.
- **Salvage.** Not worn, locked, favorited, or unique. At least one arrow down, and none up. A mixed piece stays for the player.

`HeroSheet` labels: `Base crit`, `Melee swing`, `Ranged swing`. The numbers do not change. Crit Chance and Attack Speed rolls still raise weapon power only.

### RoomHUD

- Drop the wave and kills row. The tactic line stays a short flash.
- The top meter draws only when its value is above 0. Depth, floor, and the Lantern stay.
- `equipUpgradesTitle` and `salvageDownsTitle` on the result state. Buttons appear only when the title is set.
- New `RoomActions` closures default to no-ops so the current call site compiles.
- Long-press on the potion shows `potionNote` when that string is set.

### HearthUI screens

- `HamletBar`: Farm, Push, and Change. The host supplies the titles.
- `SmithView` gains `focusID` (nil shows today's list) and `showsBag` (true shows today's list).
- `BagView` gains an optional per-row Smith action. Nil draws no button.
- `LockedDoorNote` is a card, not a full screen. `LockedCottageView` stays until the host switches.
- `PotionFacts.sentence` is the long-press copy.

## App wiring, after the three land

- The well opens the gate. Farm on the bar repeats the last Delve or Deep Rift. Push is a Deep Rift at best Depth. Change opens the same gate.
- Result: Equip upgrades calls `DeskRules` then the existing `equip`. Salvage the rest salvages those ids through the existing salvage path, skips uniques, and can undo.
- Bag row Smith opens `SmithView` focused on that piece. The hamlet smith lists the bag so salvage is there (`showsBag` is true when nothing is focused).
- Apothecary does not open a page. The potion note is `PotionFacts`.
- A locked cottage sets a note over the hamlet. It does not replace the hamlet.
- Expedition return fills the same result desk as a rift. `AwayView` stops being the payout screen.

## Leave alone

Delve versus Deep Rift, one Expedition, eight hours, 60%, Easy or Fair, three tactics, Kenney, schema 1, Old Lintel, and the buildings that are still shells.
