# Continue from M0

The M1 session loop (well, gate, Depth that sticks, return home) is underway in `ongoing/m1-session.md`. The fun-gate checklist below is still a phone call; the room was already good enough to build the session on top of it.

This is the working plan from the current tree. It does not replace `hearthdelve-full-build.plan.md` or `Hearthdelve — Game Design Spec.md`. Those still win: the spec on rules and numbers, the full-build plan on order, architecture, and gates. This file is the next sequence, the playtest method, and what a simulator pass on 2026-10-28 actually showed.

Do not start M1 until the fun gate in `ongoing/m0-fun-gate.md` is signed on a physical iPhone. Simulator playtests below are how an agent iterates. They are not the gate.

## Where the tree is

Playable: one 16×16 cellar, sword and bow, Ember Flask and Lantern Ward, three Tactics, fodder / brute / ranged, champion waves, 20 Hz snapshots, 1×/2×/4×, pause, death card, seed recordings.

Authored and validated, unused by the running app: the launch catalogs (9 weapons, 30 Relics, 24 Charms, 60 Uniques, 6 sets, 60 mobs, 15 Guardians, 2 Wardens, 12 Wanderers, 12 buildings, 12 affixes, 7 events, 8 modifiers, biome table, 77 generated cards), the damage formulas, the save schema, and the telemetry event names.

Not built: generation, Lantern, loot, Hearth, idle, Paragon, settings, audio playback, StoreKit, Game Center, iCloud.

## Baseline playtest, 2026-10-28

Device: iPhone 16e simulator, iOS 18.6, UDID `4FAEAB2B-3822-45DC-A65D-B48D68AF2F31`, 390×844 points. Scheme `Hearthdelve`, bundle `com.jacobrozell.hearthdelve`. Launch args `-seed 1`. Build and run took 73 seconds. Debug overlay reported 59–60 fps and about 27–37 nodes the whole time. Content hash prefix `e91519`.

What the screen showed, from screenshots plus a 64-second recording at `/tmp/hearthdelve-m0-seed1.mp4`:

- The room reads. Brick walls, dirt floor, hero paper-doll, green slimes, grey cyclops, and blue bats are distinct at this size. Fodder sit on the hero and die down. A white hit flash showed on a slime.
- Buttons sit in the bottom thumb zone. Accessibility frames: Ember Flask `{{14,736},{64,64}}`, Lantern Ward `{{88,736},{64,64}}`, Potion `{{212,740},{56,56}}`, Speed `{{278,746},{44,44}}`, Pause `{{332,746},{44,44}}`. Labels are `Ember Flask`, `Lantern Ward`, `Potion, N left`, `Speed N times`, `Pause`. Speed and Pause are exactly 44 points.
- Tactics fire on their own. Mid-run the potion went from `3 left / Ready` to `2 left / Not ready`, and Lantern Ward went `Not ready`, with no successful tap. At seed 2, tick 775, wave 3, the caption read `Tactic 1: HP below 35% → Potion`. Souls had fallen to 51, so a Relic had also spent. Both Relic buttons showed cooldown arcs.
- A thin red ring appeared around the hero during a melee clump (seed 2, tick 454, wave 2, 10 kills, HP 112). A large faint orange ring was on screen at the same moment as the potion caption. Neither sampled frame showed the filled orange slam disc the fun gate asks for. Treat telegraph readability as still open.
- Seed 2 died at tick 1108 (about 55 seconds). The card used the spec line, auto-saved `run-2-1108.json`, and offered `New run` and `Save this run`. Five seconds later seed 3 started at wave 1 with a full potion. The app was still on seed 3, tick ~98, wave 1, 2 kills, HP 147, Souls 100 when the session stopped.
- Nothing on screen is a Rift. No Lantern, meter, Depth, floor, loot, or Hearth. The top line is the debug seed/tick overlay, which a Release build hides.

What this pass could not do: tap. Two MCP paths failed.

1. `project-0-personal-ios-simulator` `ui_tap` at the Flask center `(46, 768)` failed. `idb` wants `SimulatorKit.framework` at `/Applications/Xcode.app/Contents/Developer/Library/PrivateFrameworks/SimulatorKit.framework`, and that file is not there.
2. `project-0-personal-XcodeBuildMCP` `snapshot_ui` returned tap targets (`Ember Flask` ref `e43` on the first snapshot, later `e54`) and told the caller to use `tap`, `batch`, and `wait_for_ui`. Those three tools are not registered in this session. Screenshot, `snapshot_ui`, `record_sim_video`, `build_run_sim`, and `ui_describe_all` do work.

`ui_tap` failed on 2026-10-28 because idb 1.1.8 looks for SimulatorKit inside `Xcode.app`, and that bundle is not writable. The fix is `Hearthdelve/agent/bin/idb_companion`, which is first on the ios-simulator MCP `PATH`. It points only the companion at a lookalike Xcode bundle under `~/Library/Application Support/hearthdelve-xcode`, where SimulatorKit is linked from `Contents/SharedFrameworks`. A direct `idb ui tap` through that wrapper loaded SimulatorKit and completed touch down and touch up. Reload the ios-simulator MCP so its `PATH` picks up the wrapper. Until that reload, this chat's `ui_tap` tool is still the old server.

XcodeBuildMCP taps are a separate set (`tap`, `swipe`, `type_text`, `button`, `key_press`, `wait_for_ui`, `batch`). They ship in the `ui-automation` workflow, which was off. `personal/.xcodebuildmcp/config.yaml` enables `simulator` and `ui-automation`. Reload XcodeBuildMCP to register them. `snapshot_ui` was already on. Those taps take an `elementRef` from the latest snapshot, not a raw coordinate.

The fun-gate checklist stays unchecked. Jacob still has to watch five minutes on a real phone.

## Standing playtest method

Use this on every slice that changes what the player sees. Headless `hearthsim` checks run in the same slice. They do not replace the simulator pass.

Session defaults were empty at the start of this run. Set them once per session, then build. Do not call `discover_projs` if the path below is right. Do not call `boot_sim` before `build_run_sim`.

1. `session_show_defaults` on `project-0-personal-XcodeBuildMCP`.
2. If the project, scheme, or simulator is missing, `session_set_defaults` with:
   - `projectPath`: `/Users/jrozell/Desktop/personal/Hearthdelve/Hearthdelve.xcodeproj`
   - `scheme`: `Hearthdelve`
   - `simulatorName`: `iPhone 16e`
   - `simulatorId`: `4FAEAB2B-3822-45DC-A65D-B48D68AF2F31`
   - `simulatorPlatform`: `iOS Simulator`
   - `bundleId`: `com.jacobrozell.hearthdelve`
   Keep iPhone 16e. It is the smallest phone on iOS 18, which is the oldest OS the golden seeds must hold on. Do not persist these defaults into the repo.
3. `build_run_sim`. For the cellar, `launchArgs`: `["-seed", "1"]`. For a later Gate screen, pass the seed the same way.
4. `get_booted_sim_id` on `project-0-personal-ios-simulator` and confirm it is the 16e.
5. `screenshot` with `returnFormat: "path"`, then read the image. One still frame is not the test. Also `ui_describe_all` and `snapshot_ui`.
6. Assert the accessibility tree before believing a pixel. Current cellar labels that must survive HUD edits: `HP`, `Souls`, `Ember Flask`, `Lantern Ward`, `Potion`, `Speed`, `Pause`, and, on death, the hearth sentence, `New run`, `Save this run`.
7. Tap from the latest `snapshot_ui` ref, not from stale coordinates: `tap` with `simulatorId` and `elementRef`. Refresh the snapshot after any overlay (pause, death, a new screen). If `tap` is still unregistered, try `ui_tap` at the frames above, and if that still throws SimulatorKit, stop and say so. Do not invent a passing tap.
8. For a fight, `record_sim_video` at 12 fps for 30–60 seconds, then sample frames. Look for the slam fill, a Relic burst, the tactic caption, and the death card. Stop the recording. Stop the app with `stop_app_sim` when the slice is done so the death loop does not keep the simulator busy.

Pair every simulator pass with the CLI, from `Hearthdelve/`:

```bash
swift run --package-path Packages/HearthSimCLI HearthSimCLI room --seed 1 --ticks 2000
swift run --package-path Packages/HearthSimCLI HearthSimCLI room --seed 1 --taps 40:flask,200:ward
swift test --package-path Packages/HearthCore
swift test --package-path Packages/HearthContent
```

`room` prints time-to-kill and whether Tactics fired. `replay --recording <file>` must print `match` for a recording pulled out of the simulator app container. The app writes those to Files → Hearthdelve → `recordings/` and the death card names the file.

Unblock taps before M1 UI work, or every new screen will be judged blind:

- Prefer enabling the XcodeBuildMCP UI automation workflow so `tap`, `batch`, and `wait_for_ui` register. `snapshot_ui` already speaks that API. Do not flip that config unless Jacob wants the MCP install changed.
- Otherwise point `idb` at the SimulatorKit that ships with the installed Xcode, then `ui_tap` / `ui_find_element` on the ios-simulator server work.

## Order of work

One slice at a time. Each slice ends with the simulator script for that slice and the CLI check named under it. Do not pull M2 systems forward to make M1 feel finished. Catalog JSON already exists. Wiring a row into the sim is the work. Adding more rows is not.

### 0. Close the fun gate

No new systems.

- Unblock taps, then on seed 1: tap Ember Flask while three enemies are in the clump, tap Lantern Ward as a champion wave starts, tap Speed through 1× → 2× → 4× → 1×, tap Pause and confirm `Resume`, `New run`, and `Save this run`, resume, and confirm the tick in the debug line froze while paused and moved again after.
- Hunt a cyclops windup in the recording. The fun gate wants a filled ground shape with a bright edge, held long enough to see whether the hero stepped out. If the ring stays a thin line, retune telegraph drawing in `RiftScene` before any generator work. Coefficients stay in `Content/tuning.json` → `room`.
- Run `room --seed 1` and confirm fodder are one or two hits. The earlier headless note said seed 1 lasts about 93 seconds, 0 of 10 slams landed, and all three Tactics fired. Re-run it. Do not treat the seed-2 death at tick 1108 as that number. Different seed.
- Jacob watches five minutes on a physical phone and checks `ongoing/m0-fun-gate.md`. If it fails, retune only. If it passes, record that and start M1.

### 1. M1, one Mossy Rift

Goal from the full-build plan: Gate to result, one biome, loot that sticks, death keeps the drop, same seed replays. Session gate is a coffee-break Rift, not the village.

Build in this order. The room sim stays the only combat. New code calls it. It does not grow a second combat engine.

1. **Rift shell around the room.** A run is 1–3 floors. Each floor is still one room at first, using `m0_cellar`, so combat does not wait on the generator. Kills fill the meter (fodder 1%, elites 4–6%, rare packs 8–10%). At 100% spawn the Guardian in the same room. Stairs are a door the hero walks through when the floor is roughly clear and the meter is not full. Deep Rift Lantern is a 6-minute burn on the snapshot field that is currently hardcoded to 1. Jumps are +3 / +2 / +1 / +0 from the fraction left at the Guardian kill. Delve leaves the Lantern off and does not advance Depth. Death and an empty Lantern both keep loot and grant +0. The result line stays the hearth sentence.
2. **One Guardian.** Pick the Mossy Guardian whose opcodes already validate. HP starts at 120× fodder HP. Two telegraphed mechanics, enrage at 30% HP. Time-to-kill target 30–60 seconds at the edge of Fair. Do not build the Warden.
3. **Layout pass, Mossy only.** About 8 templates, not 20. Tree of 4–8 rooms, 0–2 loops, entry, stairs, one Guardian arena on the last floor, at most one side room. Threat budget can spawn the three roles the room already simulates. Caster and swarmer rows exist in JSON. Do not invent their AI in this slice. Leave them out of packs until a later slice gives them a behavior and a telegraph of at least 0.6 seconds.
4. **Loot that persists.** Item level = Depth + 10. Common / Rare / Unique with the spec shares, the 40-Rare pity counter in the roller even if it rarely fires, a short affix pool, and three Uniques that already have opcodes, including Cinderfang. Upgrade score is two arrows against the equipped piece. Bag of 40. Slots that work at level 1: melee, ranged, four armor, first Relic. Weapon auto-switch stays the 3-tile rule already in the room. No Charms, no Glyphs, no Blacksmith.
5. **Local save.** `SaveStore` already writes three copies. Call it on Rift end and on background. Schema version stays 1. Do not add iCloud. Uniques are not auto-salvaged.
6. **Gate screen.** Depth, Delve versus Deep Rift, biome from the versioned table, predicted difficulty from `DifficultyBand`. The Hearth behind it can be one SwiftUI room with a well. The pan-able village is M2. Free play stops when a Deep Rift would pass Depth 25. Do not build the paywall yet. Just refuse the Depth.

CLI for the session gate, after the Rift runner exists:

- Three reference loadouts at a comfortable Mossy Depth clear a Delve in 3–5 minutes.
- A Deep Rift at the edge of Fair lands in 6–8 minutes, Guardian 30–60 seconds.
- First Unique inside half an hour of the early-game loadout.
- A saved recording replays to the same hash.

Simulator script for M1, iPhone 16e, after each of the six steps, not only at the end:

- After the shell: start a Delve at Depth 1. Confirm the debug line is joined by meter, Depth, and floor at the top, and that those labels are not buttons. Confirm the Lantern is absent in a Delve and present as a moth arc in a Deep Rift. Let a run hit 100% and confirm a Guardian appears on the hero. Die on purpose once the tap path works (or wait for a death) and confirm loot is listed and Depth did not move.
- After the Guardian: record 60 seconds of the boss. Both mechanics must show a filled telegraph. Enrage must be visible.
- After layout: run two seeds. Room count must fall in 4–8. Walk to the stairs in the recording. The hero takes them only when the meter is not full.
- After loot: the result lists items with two arrows. Equip one. Relaunch the app and confirm the bag is still there (`Save this run` is not the save under test; background the app and come back).
- After the Gate: open the app on the well, not in a fight. Switch Delve and Deep Rift. Change Depth. The predicted band changes when the loadout is too weak. Start, finish, return to the well.

### 2. M2, the three session shapes

Only after the session gate. Content stays Mossy plus Fungal. The work is the loop.

Buildings that must function, tier 1: Blacksmith (salvage, re-roll, raise item level, craft a Rare, transmute), Library (Tactics editor, slots still start at 3), Map Room (Expeditions, 8-hour cap), Apothecary (one potion), Inn (Wanderers walk and speak the first friendship line only), Stash (100), Reliquary (one signature slot), Chandlery (one Lantern-efficiency upgrade). Garden, Trophy Hall, Lighthouse, and Glyphwright are inert tier-0 shells so the village layout is final. Glyphs stay unwired. Hero levels bank a Glyph Point with no UI.

Idle rule, implemented exactly: when the Expedition Depth or the loadout changes, run 3 headless Rifts and store the mean. Background writes a timestamp only. On return, `floor(min(away, cap) / mean) * 0.6` Rifts of batched loot. Backwards clock jumps add 0. Auto-salvage before the bag is shown. Auto-Delve repeats a Delve at up to 4× with Lantern Mode. Deep Rifts never automate.

Meta that lands here: levels 1–100, Relic slots at 1 / 5 / 10, Charm slots at 3 / 15 / 30, Charm XP with Expedition time at 50%, Paragon after 100 with a free respec, four loadouts, loot rules. Onboarding is one Delve, then the first Relic, then three readable Tactics. Settings that the full-build plan assigns to M2, stored as specified: device prefs in `UserDefaults`, gameplay prefs in the save.

Simulator script:

- Cold launch lands on the village, about two screens wide. Pan with `ui_swipe`. Tap the well, the smith, the library. Each opens one screen and returns.
- Check-in, timed: collect, equip the arrow-up item, send an Expedition. Target under two minutes. Background with the home gesture is not available through `ui_tap`. Use the CLI clock test for the away math, and a real background on device before calling the loop gate done.
- Coffee break: one Delve and one Deep Rift from the well, then the bag.
- Evening: re-roll one affix, edit a Tactic, push a Depth. The Tactic caption in the Rift must match the edited rule.
- Lantern Mode: start Auto-Delve, wait the inactivity delay, confirm the scene stops rendering and the sim tick still advances (debug tick, or a log). Tap to wake.

CLI: first Unique inside 30 minutes, an upgrade at least every two Rifts through Depth 50, Depth 25 around two hours for the reference build, offline calc under 0.5 seconds, 1,000 headless Rifts under 10 seconds.

### 3. M3, launch

The spec’s launch set. No M4 item.

Content already in JSON gets wired: five biomes, affix schedule 1 / 2 / 3 / 4, the ban list already enforced by `affixSetIsLegal`, Heirlooms at 50, modifiers at 75, Starforged at 150, Warden every 50th Depth, all 12 affix behaviors, all 7 events, all 8 modifiers, Charm stats in the damage formula, set bonuses, Codex bonus every 10 entries, buildings to tier 5. Room templates grow from 8 to about 20 per biome. Echoes are a palette swap plus one new attack, not new silhouettes.

Bestiary cards: the generator exists. Add the drop roll, pity at 300, foil on Echo, stars, the Codex tab, and a quiet flip. Cards never add stats.

Platform, in the app target only: CloudKit conflict UI, Game Center best Deep Rift Depth plus the 39 launch achievements, StoreKit one non-consumable at $7.99 that gates Depth past 25, telemetry actually emitted through `HearthTelemetry` (the cases already match the catalog), `HearthAudio` buses fed by `GameEvent` with `.ambient` and the cue list. Ask Jacob before any App Store Connect, Firebase, or CloudKit id. Those are inputs the full-build plan says not to invent.

Simulator script:

- Depth 1, 25, 50, and 75 change biome or modifier in the Gate text, and the tree matches `BiomeTable`.
- An elite shows icon, shape, and color, not color alone. Frozen+Jailer never appears (`ui_describe_all` on the elite, or the combat log).
- A card flip is quieter than a Unique drop. Confirm by watching both in one recording.
- Settings: toggle music, left-handed layout (the bar mirrors), damage numbers, and Reset (it must demand the word RESET). Relaunch and confirm device settings stuck and a second install did not.
- The purchase screen appears when a Deep Rift would pass 25, and a Delve at 25 still starts. Do not complete a sandbox purchase from the agent. Stop on the sheet and let Jacob buy.
- VoiceOver labels from `ui_describe_all` cover every new control. Anything without a label fails the slice.

Ship checks stay the full-build plan’s: balance table, 60 fps on an iPhone 13-class device, memory under 400 MB, install under 300 MB, then the personal review lanes. Simulator fps is a smoke test only.

### 4. M4, after the launch gate

Do not open these while a launch slice is unfinished. Each one already has a save field or a JSON row.

- Glyphs, then show the banked points all at once. Sockets 1 / 2 / 2. Ranks cost 1 / 2 / 3 and refund. Kindle, Ricochet, Thrift, Bulwark, Harvest first. Ship `hd.chase.glyph_master` only when every launch Glyph can reach Rank III.
- Tactics AND/OR and hold-until, sold by Library tiers.
- Up to three companion Expeditions, 1–4 hours, no gear.
- Friendship steps two and three. No romance.
- Inn card game in `HearthCore`, deterministic, so `hearthsim` can play a match. Rewards are decor, card backs, titles, friendship. Never Power.
- Echo Seasons, opt-in, cosmetics only. The main hero is not reset.
- Supporter pack, cosmetics only.
- First expansion as a new biome-table version from a stated Depth upward.
- iPad landscape as a second layout. Portrait stays the phone default. Playtest that pass on an iPad simulator after the phone script is green, not instead of it.

## What not to do while following this

- Do not add a class, a virtual stick, ads, energy, or a second rarity.
- Do not put Firebase, CloudKit, Game Center, or StoreKit imports in a package. The app target owns them.
- Do not let the renderer write sim state.
- Do not special-case one Unique in Swift. New behavior is an opcode plus a test.
- Do not tune numbers that the spec already fixed. Numbers the spec left open stay in `Content/tuning.json`.
- Do not call the fun gate passed from a simulator recording.
