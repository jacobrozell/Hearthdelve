# Demo MVP — village, one loop, a little meta

Drafted 2026-10-28. Updated the same day after the three slices landed on the simulator.

## Landed

The home is a Kenney Tiny Town hamlet, about two phone screens wide. A finger pans it. The well opens the existing gate. Coming back from a rift centers the camera on the well. The Apothecary, Library, and Map Room name themselves and the Depth that opens them (2, 3, and 5) and do not open a system. The Blacksmith opens salvage and raise.

A finished rift, clear or death, grants XP from the `heroXP` curve and the flat `riftGold` in `tuning.json`. One clear is enough to leave level 1. The village shows level, Anula, Dust, Facets, and Echoes. Each level after 1 adds `heroHPPerLevel` hit points on the next fight through `RoomSetup.bonusHP`, and banks one Glyph Point with no UI. Levels stop at 100. Paragon is not built.

The smith salvages by hand: Common to Dust, Rare to Facets, Unique to Echoes plus one Codex signature. A Unique asks first. Equipped pieces are refused. Raising an item costs Dust and gold from `tuning.json`, starting at item level 11 and growing by repeated multiplication, and stops at best Depth + 10. The button says `Needs Depth N` while a drop is already at that cap. The bag and the smith group by slot, show what is worn, and update the two arrows after an equip. An empty slot auto-equips the strongest fitting piece. Auto-salvage by rarity (commons, then rares) is off until toggled. Uniques, equipped, locked, and favorite pieces are never auto-salvaged.

The result card shows the level and the Anula the rift paid. A full bag says the bag is full. The gate calls the Depth timer the Lantern and leaves it unlit on a Delve. The shield button reads Ward. The fight HUD shows `Floor n/n` and a Guardian meter.

`-seed` still jumps into a fight. A normal launch opens on the village.

Simulator, iPhone 16 (iOS 18.6): panned to the Apothecary and back, opened the gate, ran a Delve, returned to the village with level 2 and 25 gold, equipped a rare sword that showed an up arrow, salvaged one common for 5 Dust, and saw a Unique ask before it would salvage. The physical iPhone pass was not run.

## Still open

The done-when is still a cold launch on a physical iPhone, including backgrounding and finding the same save. Raise waits until a Deep Rift moves best Depth, because drops at the current best are already item level best + 10. Day and night, weather, the moth, and the Later list are untouched.

A person holding the phone should be able to do this in about ten minutes, with no Xcode on screen:

1. Pan a small village.
2. Tap the well, run a Delve, and come home with loot.
3. Equip something with an up arrow. The next fight is a bit stronger.
4. Salvage the rest at the smith so the bag has room. Dust, Facets, or Echoes go up. Hero level goes up.

That is the demo. Depth still only moves on a Deep Rift clear at your best.

## Already in the build

The Mossy fight, Old Lintel, the gate, loot, equip, the bag of 40, local save, and the Depth rules. One rift currently fills the bag, so a second rift cannot keep new drops until something spends items. The smith is that something.

Save fields already exist: hero level and XP, banked Glyph Points, gold, Dust, Shards, Embers, building tiers, rescued Wanderers. `Content/tuning.json` has the hero XP curve (`base` 100, `growth` 1.08), flat `riftGold`, `heroHPPerLevel`, and the smith yields and starting raise costs. Building rows and Kenney Tiny Town tiles (grass, path, well, houses) are mapped, and the Tiny Town sheet is in the tile atlas.

## What to build, in order

The three slices below are in the build. What is still open is at the top of this file. Do not start the Later list.

Each slice ends on a phone or the iPhone simulator, then the previous slice still works.

### 1. The village

Replace the SwiftUI well with one hand-built hamlet, about two phone screens wide. Pan with a finger. Kenney Tiny Town only: grass, a path, the well, the smith, and two or three other cottages.

The well opens the gate that already exists. Coming home from a rift lands here, camera on the well. The smith can be tapped and opens an empty screen that closes. The other cottages show a name and the Depth that opens them (Apothecary 2, Library 3, Map Room 5) and do not open a system.

Day and night, weather, the moth, and a second art pass wait.

### 2. Level and gold

On rift end, grant XP from `tuning.json` → `heroXP` and a flat gold amount, also stored in `tuning.json`. Show level and gold on the village. Each level adds a little max HP in the next fight. Glyph Points bank on the save with no UI.

One clear should be enough to see the level move. Do not build Paragon.

### 3. The smith

The one building that works.

- Salvage, by the spec: Common becomes Dust, Rare becomes Shards, Unique becomes Embers and a Codex signature entry. Uniques ask first. They are never salvaged by themselves.
- Raise item level with Dust and gold, up to best Depth + 10. Costs start in `tuning.json`.
- The bag shows what is equipped. After a raise or an equip, the arrows update.

Re-roll, craft, and transmute wait. The demo only needs room in the bag and one spend.

### 4. The ten-minute script, on a phone

Install with the `Hearthdelve` scheme. No TestFlight.

- Pan the village. Tap a locked cottage and come back.
- Delve at Depth 1. Come home. Equip an up arrow. Level and gold moved.
- Salvage until the bag is not full. Raise one weapon or armor piece by one item level.
- Run again and feel the stronger piece.
- One Deep Rift, so Depth can move if the clear is fast enough. If it is not, the demo still holds: the Delve loop is the show.

`-seed` still jumps into a fight for checks. A normal launch opens on the village.

## Done when

A cold launch on a physical iPhone shows the village, a full Delve, loot kept, an equip, a salvage, a level change, and a return to the same village after the app is backgrounded. The save is still there.

## Later

This demo does not build them. The full M2 plan still does, after the phone script above is actually fun to show.

- Working Apothecary, Library, Map Room, Stash, Inn, Chandlery, Reliquary.
- Expeditions, Auto-Delve, and Lantern Mode.
- Paragon, Charms, four loadouts, the tactics editor.
- Audio, StoreKit, Game Center, iCloud.
- Rooms for biomes past Mossy. The gate may still name them. The demo fight stays Mossy, and the village copy can keep saying so when Depth leaves the first band.
