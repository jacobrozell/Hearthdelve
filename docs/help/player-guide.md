# Player guide source

Source for a later help screen, a long-press on a stat, and the two or three lines a Wanderer says when a system unlocks. It describes what a new player can touch in this build. The spec still wins on rules. If this file and the spec disagree, stop and ask. Do not teach a **Later** note as if it were already in the game.

When a system ships, add an entry here before writing its screen. Prices that can change live in `Content/tuning.json` and are listed in [`docs/balance/starting-values.md`](../balance/starting-values.md).

Each entry has:

- **Meets** — the moment the player first needs the words.
- **Say** — the short lines. A tutorial or a Wanderer can speak these as they are.
- **Page** — the help page.
- **Later** — only when the spec goes further than this build.

## First trip

### The hamlet

- **Meets** — cold launch, before the first Delve.
- **Say** — "This is home. Pan it with a finger. The well starts a Delve. The Blacksmith takes the gear you do not want."
- **Page** — The hamlet is the village. The well opens the gate. The Blacksmith is open from the start. Other cottages stay shut until best Depth reaches the number on the door, and the door says so. Coming home from a rift puts the camera back on the well. Level, Anula, Dust, Facets, and Echoes sit in the corner. The Bag button is there too.
- **Later** — Wanderers, day and night, weather, and the moth are not in this build. Locked cottages name a Depth and do not open a system: Apothecary 2, Map Room 5, Inn 10, Chandlery 12, Reliquary 15, Garden 20, Trophy Hall 25, Relay Tower 40, Glyphwright 50. The Library (3) and the Stash House (8) do open once that Depth is reached.

### The well

- **Meets** — the first tap on the well.
- **Say** — "A Delve farms the Depth you pick and does not move your best. A Deep Rift is the push. Only a clear at your best Depth advances it."
- **Page** — The gate shows the Depth, the biome, and a difficulty word (Easy, Fair, Hard, or Deadly) from the worn weapons against that Depth. Depth can be any number up to best Depth. A Delve leaves the Lantern unlit. A Deep Rift burns a six-minute Lantern. Time left when the Guardian falls is a Depth jump of +3, +2, +1, or +0. Death still brings the loot home and does not move Depth. The Mossy Cellars are the rooms this build runs. The gate says so when the chosen Depth would be somewhere else.
- **Later** — Lantern Mode, Auto-Delve, and rooms past Mossy are not in this build. Free Deep Rifts stop past Depth 25 in the rules already shipped.

### The fight

- **Meets** — the rift, under the hero.
- **Say** — "You do not swing. The hero does. Tap a Relic to fire it early. The three rules at the Library fire them for you. Drink happens on its own when you are hurt."
- **Page** — The hero shoots while the target is farther than 3 tiles and in sight, and swings once it is in melee reach. Speed is 1×, then 2× and 4×. The potion has 3 drinks and each one heals 55% of max HP. It will not fire while already full. The buttons are the worn Relic and the Ward. The line under a tactic is the same sentence the Library edits. The top of the screen shows the floor and, on a Guardian, the meter. Nothing up there is a button. The meter under the hero reads Charge. A clear or a death both pay Anula and experience and send the found gear home.
- **Later** — Three Relic buttons, Charms, and the Lantern arc on a Delve are spec, not this screen. This fight has the Relics the loadout equipped, starting from Ember Flask and Lantern Ward.

## Gear

### A drop

- **Meets** — the result card, and again in the Bag.
- **Say** — "The name is the rarity, the piece, and its item level. The lines under it are the rolls. An up arrow is better than what you are wearing in that slot. A down arrow is worse."
- **Page** — Common has one roll. Rare and Unique have two. A Unique also has a signature sentence that always does the same thing for that named piece. The two arrows are damage and toughness against the piece in that slot. They are level when the new piece matches, and they stay off the piece you already have equipped. An empty slot fills itself with the strongest piece that fits. The bag holds 40. When it is full, the game says "The bag is full." and new drops wait.
- **Later** — The spec's long-press compare, lock, favorite, and a single upgrade percent are not on the card yet. Locked and favorite already exist on the save and are skipped by auto-salvage.

### You

- **Meets** — the Bag and the Blacksmith, above the pile of gear. This is the block labeled You.
- **Say** — "There is no Strength or Dexterity. Melee and Ranged are how hard those weapons hit. The other lines are what the armor, the relic, and the weapon type add. A weapon's rolls raise that weapon's power."
- **Page** — The sheet is the worn loadout, not the whole bag.

  | Line | What it is |
  | --- | --- |
  | Melee | That weapon's power: its item level, plus its own rolls. |
  | Ranged | The same, for the ranged weapon. |
  | Bonus HP | Max HP rolls on the four armor pieces, plus 8 for each level after 1. |
  | Armor | The armor rating from those same pieces. Incoming hits use it. |
  | Crit | 5%. A crit deals half again as much. That bonus is not its own line. |
  | Melee crit | Only while the melee weapon is Daggers. Those add 15%, so this reads 20%. Ranged shots stay at 5%. |
  | Melee speed, Ranged speed | How often that weapon type swings. A roll named Attack Speed does not change this. |
  | Relic damage | The worn relic's Relic Damage roll. It raises that relic's damage. |
  | Cooldown | The worn relic's Cooldown Reduction roll. It shortens that relic's cooldown. |

  In the rift, a hit still scales with the Depth. Melee and Ranged say how far those weapons sit above a normal weapon. Bonus HP and Armor are added on top of the Depth's own hit points. A higher number on You is a stronger next fight. It is not the damage printed on a slime.

  A Crit Chance roll and an Attack Speed roll raise that weapon's Melee or Ranged number. They do not change Crit, Melee crit, or the speed lines. That is why a re-roll can move power without moving Crit.

- **Later** — The spec also names crit damage as its own stat, area damage, elemental bonus, damage to elites, all-resist, dodge, life per hit, move speed, Soul gain, magic find, and lantern efficiency. None of those are rolled or shown yet. Crit damage is a flat half-again in the fight, from `tuning.json`, with no gear roll. Glyphs, Charms, and Paragon are not on this sheet.

### Rolls

- **Meets** — under a piece's name, before Salvage or Re-roll.
- **Say** — "Each line is one roll and the number it rolled. Re-roll replaces that one line. The other line stays."
- **Page** — The eight rolls, and where they can land:

  | Roll | Slots | What it changes |
  | --- | --- | --- |
  | Melee Damage | Melee | That weapon's Melee power. |
  | Ranged Damage | Ranged | That weapon's Ranged power. |
  | Crit Chance | Melee, Ranged | That weapon's power. Not the Crit line. |
  | Attack Speed | Melee, Ranged | That weapon's power. Not how often it swings. |
  | Max HP | Helm, Chest, Legs, Boots | Bonus HP. |
  | Armor | Helm, Chest, Legs, Boots | Armor. |
  | Relic Damage | Relic | Relic damage, and that relic's hits. |
  | Cooldown Reduction | Relic | Cooldown, and that relic's wait. |

  A roll reads as a percent, such as Ranged Damage +6.8%. Ranges are about 4–8% for damage, hit points, armor, and relic damage, and about 3–6% for crit, attack speed, and cooldown.

- **Later** — Heirloom and Starforged ranges, Glyph sockets, and a re-roll of the whole item are not in this build.

### Weapon types

- **Meets** — the first time two weapons of the same slot feel different at the same item level.
- **Say** — "The type is the attack. The rolls are the numbers. A hammer is slow and stuns. Daggers are fast and crit more often. The sling bounces a shot."
- **Page** — The hero always has a melee and a ranged weapon. The type sets the reach, the speed on You, and one built-in trick. Rolls and a Unique signature sit on top.

  | Type | Speed | Reach | Built-in |
  | --- | --- | --- | --- |
  | Sword | 1/s | 1 tile | Every 3rd hit cleaves. |
  | Hammer | 0.7/s | 1 tile | Every 4th hit stuns for 1 second. |
  | Daggers | 1.8/s | 1 tile | +15% crit on melee swings. |
  | Spear | 1.1/s | 2 tiles | The thrust hits one enemy behind the first. |
  | Scythe | 0.9/s | a short arc | 3% of damage healed. |
  | Bow | 0.9/s | 8 tiles | Every 3rd shot hits twice as hard. |
  | Crossbow | 1.5/s | 7 tiles | Bolts pierce. |
  | Wand | 1.2/s | 6 tiles | Bolts turn toward the target. |
  | Sling | 1.3/s | 6 tiles | A shot bounces to one extra target. |

## The Blacksmith

### Salvage and raise

- **Meets** — the first full bag, or the first piece that is worse than what is worn.
- **Say** — "Salvage turns a piece into materials. What you are wearing cannot be salvaged. Raise spends Dust and Anula to push the item level up, and it stops at your best Depth plus 10."
- **Page** — Common pays 5 Dust. Rare pays 2 Facets. Unique pays 1 Echo, asks first, and writes that signature into the Codex. Raising one level starts at 8 Dust and 10 Anula, then grows for each level above 11. The button says what it costs, or "Needs Depth N" when the piece is already at the cap. Auto-salvage is off until toggled. It can take commons, then rares. It never takes a Unique, a worn piece, a locked piece, or a favorite.
- **Later** — Undo, a salvage preview, and Equip Best are spec quality-of-life, not this screen.

### Re-roll, craft, transmute

- **Meets** — a Rare or Unique whose rolls are on screen and not the ones the player wants.
- **Say** — "Re-roll replaces one line and leaves the other. The price doubles each time you do it to that same piece. Craft spends Facets for a new Rare of a slot and a type you pick. Transmute spends Echoes and turns a Unique into another Unique of the same slot."
- **Page** — Re-roll is Facets on a Rare and Echoes on a Unique. The first prices are 4 Facets and 2 Echoes, then 8, 16, and so on for that item only. Commons have a roll and no re-roll. Craft costs 8 Facets and the button says so. It makes a Rare at the same item-level cap as Raise, with random rolls for the chosen slot. The type has to match the slot. Transmute costs 12 Echoes, keeps the item if it was equipped, and resets that piece's re-roll count. A full bag refuses the craft before the Facets are spent, and it says "The bag is full."
- **Later** — Re-rolling every line at once, craftable rarity above Rare, and a re-roll discount from the smith's building tier are not in this build.

## Stash House

- **Meets** — best Depth 8, the cottage south of the path. Before that, the door says it opens at Depth 8.
- **Say** — "The bag holds 40. The stash holds 100. Move a piece either way. What you are wearing stays worn."
- **Page** — Both piles show the same rolls the Bag shows. Equipped pieces have no move button. A full stash says "The stash is full." A full bag says "The bag is full." when something tries to come back.
- **Later** — The spec grows the stash with the building's tier, up to 400. This cottage is the 100-cap room only.

## Library

- **Meets** — best Depth 3. Before that, the door says it opens at Depth 3.
- **Say** — "These three rules are already running the fight. Change a rule and the next rift says the new line."
- **Page** — There are three rules and no fourth. A rule is one condition, then an action: the potion, or a relic. The conditions are Always, HP below a percent, an elite within some tiles, a count of enemies within some tiles, Charge at least a number, the target beyond some tiles, the target is an elite, and the shield is down. The + and − buttons nudge the number on the rules that have one. The rift prints the same sentence, such as "Tactic 2: always → Lantern Ward". The starter three are: drink below 35% HP, Ward when an elite is within 4 tiles, and Ember Flask when 5 or more enemies are within 2 tiles. A potion rule set to Always still waits until the hero is hurt.
- **Later** — Slots toward 10, AND/OR, and hold-until are spec unlocks. They are not in this Library.

## What a tutorial should not say yet

Expeditions, Auto-Delve, Lantern Mode, Paragon, Charms, extra loadouts, Glyphs, the Reliquary's extra signatures, Wanderer friendship, and the buildings listed under The hamlet. The first ten minutes the spec describes — one Delve, then a Relic, then reading the three rules — can be written from The well, The fight, A drop, You, and Library. The smith's re-roll is the evening lesson, after the player has a Rare they want to keep.
