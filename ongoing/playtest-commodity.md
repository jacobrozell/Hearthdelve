# Commodity ledger playtest

Drafted 2026-10-28. Next phase after the ten-minute Mossy demo. The physical iPhone cold launch is still Jacob's gate. This pass checks that the evening slice still plays and that the ledger uses the saga words.

Graphics stay Kenney. Save keys stay `gold`, `shards`, `embers`, and `souls`. Hale, Codex flavor, and the Biomes and Wanderers tables are not in this pass.

## What the screen should say

| Was | Now | Where |
| --- | --- | --- |
| Gold | Anula | Village corner, smith, result card, raise price |
| Shards | Facets | Village, smith, rare re-roll, craft button |
| Embers | Echoes | Village, smith, unique re-roll, transmute, unique salvage ask |
| Souls | Charge | Fight meter, Library condition |
| Lighthouse | Relay Tower | Building name in `Content/buildings.json`. Not placed on the hamlet yet. |

The craft button reads `Craft · 8 Facets`. A full bag still says `The bag is full.` Ember Flask stays the relic's name.

## Script

Fresh save, iPhone simulator, normal launch (no `-seed`). About fifteen minutes.

1. Cold launch. The corner reads Level, Anula, Dust, Facets, Echoes, and Best Depth. Pan the hamlet. A locked cottage names itself and a Depth.
2. Open the Blacksmith. The same four words are on the smith. The craft control says `Craft · 8 Facets`. Close it.
3. Tap the well. Start a Delve at Depth 1. The Lantern stays unlit. The meter under the hero says Charge, not Souls. Nothing at the top of the fight is a button.
4. Clear or die. The result names Anula, not Gold. Home puts the camera on the well. Level moved, or the result explains why it did not.
5. Equip a piece with an up arrow. Salvage something that is not worn. Dust, Facets, or Echoes move. A Unique asks before it becomes Echoes.
6. If the bag has a Rare with an affix and at least 4 Facets, re-roll one line. The price says Facets and doubles on that piece only. If it does not, write that down and move on. Do not grind for it.
7. Library and Stash House stay locked on a fresh Depth 1 save. Do not force them. The unit tests cover `Charge ≥ 30` and the Relay Tower name.

## Out of scope

Phone backgrounding, rooms past Mossy, Hale, charter company, Sinter lines, new art, save migration.

## Done when

The six steps above pass on the simulator, and `swift test` for HearthCore and HearthContent is green. Failures get a one-line note under Results. The phone pass stays unsigned.

## Results

Simulator: iPhone 16, iOS 18.6. Not a physical iPhone. No code changes. HearthCore and HearthContent tests were not re-run (already green this session).

1. pass — Corner read "Level 1", "Anula 0", "Dust 0 Facets 0 Echoes 0", "Best Depth 1", and Bag. Panned to the Apothecary. Locked cottage read "Apothecary" and "Opens at Depth 2".
2. pass — Blacksmith read "Anula 0" and "Dust 0 Facets 0 Echoes 0". The craft control read "Craft · 8 Facets". Its accessibility label was "Craft a Rare for 8 Facets".
3. pass — Depth 1 Delve, Floor 1 of 2. Gate said "A Delve leaves the Lantern unlit, so Depth stays." No Lantern meter on the fight. The meter under the hero read "Charge" (value 100), not Souls. Top of the fight was Depth, Floor, and Guardian text, not buttons.
4. pass — Died. Result read "You wake by the hearth. Everything you found came home with you." and "Level 2 · 25 Anula". No Gold. Village put the well at screen center. Corner then read Level 2, Anula 25, Best Depth 1.
5. partial — Salvage and the Unique ask passed. An unworn Common Sword moved Materials from "Dust 0, Facets 0, Echoes 0" to "Dust 5, Facets 0, Echoes 0". The Unique ask read "Salvage this Unique?" and "It becomes Echoes, and its signature is written in the Codex." Kept it. Nothing on the result card or the smith scored above the worn sword (marks were down or same), so equip was not reached. That is this death's loot, not a broken arrow.
6. pass — Not run. Facets stayed 0, so the line was not re-rolled and nothing was ground. Rare re-roll values already read "4 Facets". Unique re-roll values read "2 Echoes".
7. pass — Library read "Opens at Depth" 3. Stash House read "Opens at Depth" 8. Neither was forced open.
