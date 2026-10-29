# Next steps

Drafted 2026-10-28, after the commodity ledger playtest. Spec wins on rules. [`hearthdelve-full-build.plan.md`](../hearthdelve-full-build.plan.md) wins on build order. [`docs/avasia-game3.md`](../docs/avasia-game3.md) wins on saga names.

Do not start the rest of M2. That means Expeditions, Auto-Delve, Lantern Mode, Paragon, Charms, extra loadouts, day and night, weather, the moth, audio, StoreKit, Game Center, iCloud, Glyphs, Wanderer friendship, rooms past Mossy, a fourth tactic slot, and the buildings that are still shells. Do not retune Old Lintel. Do not invent the Biomes table, the Wanderers table, Hale's lines, or the Depth 150+ Warden list.

## Already in

- Saga line in Avasia-iOS `docs/SAGA.md` §7. Store name Hearthdelve. Saga title *Avasia: Hearthdelve*.
- Setting section in the design spec, pointing at `docs/avasia-game3.md`.
- On-screen words: Anula, Facets, Echoes, Charge, Relay Tower. Craft button shows `Craft · 8 Facets`. Save keys are still `gold`, `shards`, `embers`, `souls`.
- Simulator pass in [`playtest-commodity.md`](playtest-commodity.md). iPhone 16, iOS 18.6. Words held. Equip was not reached because that death's loot did not beat the worn sword.

## 1. Jacob, on a phone

Cold launch the current build. Background it. Come back and find the same save. That is still the demo done-when. The fun gate and the session gate stay unsigned until Jacob says so.

While that save is in hand, the ten-minute script in [`demo-mvp.md`](demo-mvp.md) is the check: pan, Delve, equip an up arrow, salvage, and see Anula move. One Deep Rift if there is time. Depth only moves on a clear at best Depth.

## 2. Close the two simulator gaps

Still this slice. No new systems.

- Run Delve until a drop scores above the worn piece. Equip it. The next fight should show the higher piece. The last run had only down and same marks, so this path is unwatched.
- Salvage a Rare so Facets leave 0. Re-roll one affix. The button should say Facets, then double on that same piece. The last run never spent Facets.
- Leave the Library and the Stash House locked unless best Depth actually reaches 3 and 8. `Charge ≥ 30` and the Relay Tower name are already unit-tested. Do not force the doors.

## 3. Story work that can start without the missing tables

In this order. Stop at the first one that needs a line Jacob has not written.

1. **Anchor tags on Relics.** `Content/relics.json` already has element tags (`fire`, `frost`, `nature`, `radiant`, `shadow`, `untyped`). Saga anchors are sky, earth, flesh, and civic. No map between them was in the handoff. Do not stamp tags. The step is one sentence from Jacob, then a content pass and a validator check.
2. **Hale's schema, not Hale's row.** A Wanderer must name a building, and the validator rejects a building id that is not in `buildings.json`. It also requires exactly three intro lines. Make `building` optional in the decoder and the validator, with a test that an omitted building is legal and a present building must still match. Do not add Hale until those three lines exist. Hale lives at the Inn, has no building, and is rescued at Depth 51. None of the twelve is replaced.
3. **Codex and Wanderer flavor.** Blocked. Rewrite them only from the Biomes and Wanderers tables. Bea’s role is already `relay keeper`. Her three intro lines stay until that table arrives.
4. **Save-key migration.** After the phone gate, and only when a second save shape is worth the risk. Display strings do not depend on it.

## 4. Later, still not this phase

- Depth 150+ Wardens, when M3 content work starts, and only from the list Jacob writes. The Sinter is named once, at Depth 150, and is not killed.
- Charter company, first expansion, not launch.
- A title screen, when one exists, reads *Avasia: Hearthdelve*. There is no title screen in this build. Do not add one to satisfy the name.
- Graphics stay Kenney until the fun gate is signed.

## Done when

Jacob has signed or refused the phone pass. The equip path and one Facet re-roll have been seen on the simulator. Hale is either still absent, or present with Jacob's three lines and no building. No anchor tag has been invented.
