# Hearthdelve — Game Design Spec

Oct 27, 2026 · @Jacob

## Vision

Hearthdelve (working title) is a premium, portrait-mode iOS game where one hero auto-fights down an endless, depth-scaled Rift beneath a lantern-lit village, and the player wins by building smarter rather than tapping faster. Every Rift lasts 3–8 minutes, every depth number means harder enemies and better loot, and there is no ceiling.

**Elevator pitch:** Diablo 3's Greater Rifts, played like an idle game, with a cozy village to come home to.

### Design pillars

1. **Infinite, honest scaling.** Depth never caps. Each step up is a measurable jump in threat and reward, and new mechanics (elite affixes, biome variants) arrive on a schedule so depth 300 plays differently from depth 30.
2. **Build expression over reflexes.** The hero fights automatically. The player's decisions are gear, Relics, Charms, Glyphs, and tactics rules. Fully playable one-handed.
3. **Cozy between the danger.** Death costs nothing but the push. Loot is always kept. The hub is warm, slow, and safe.
4. **Respect the player's time.** No energy, no gacha, no guilt timers. Offline progress is fair and capped, never a chore.
5. **Short sessions, long arcs.** A Rift fits in a coffee break; Paragon and the Hearth take months.

### Reference points

| Game | What we take | What we leave |
| --- | --- | --- |
| Diablo 3 | Greater Rift structure, progress meter, Guardian boss, Paragon | 15-minute hard timer, multiplayer, seasons treadmill |
| Good Knight / idle RPGs | Auto-combat, offline gains | Gacha, energy, ad walls |
| Stardew Valley mines | Floor-by-floor descent, cozy town above | Manual combat |
| Final Fantasy XII | Gambit-style tactics rules | Party of six |
| Minecraft Dungeons II | Classless loadout: melee + ranged always, skills from gear, leveling passives, refundable enchant points | Open world, co-op, manual dodging |

### The gap on iOS

The target is a player who wants a real loot game with uncapped depth, on a phone, without free-to-play pressure. Most idle RPGs on the App Store monetize progression; Hearthdelve sells the whole game and lets the numbers go up forever.

## Setting

The store name is Hearthdelve. The saga title is *Avasia: Hearthdelve*. Place, era, and the ledger rules are in [`docs/avasia-game3.md`](docs/avasia-game3.md). This spec still wins on combat and loot numbers.

On screen the currency is Anula, rare salvage is Facets, unique salvage is Echoes, the relic meter is Charge, and the Depth 40 building is the Relay Tower. Save fields stay `gold`, `shards`, `embers`, and `souls` until a migration. Graphics stay on the Kenney hamlet until a later pass.

## Market comparison

No single iOS game combines classless gear builds, auto-battle, uncapped scaling depth, and fair pricing; each piece exists separately. Soda Dungeon 2 owns idle depth plus a town, Nonstop Knight 2 owns auto-battle ARPG, Eternium owns endless generated Trials, and Melvor Idle and Vampire Survivors prove fair monetization sells. Hearthdelve's bet is the combination.

| Game | Model on iOS | Overlap with Hearthdelve | What works | What hurts |
| --- | --- | --- | --- | --- |
| [Minecraft Dungeons II](https://metabot.gg/en/minecraft-dungeons-2/guides/beginners-guide) (Sep 2026) | Not on iOS (PC, consoles, Switch) | Classless loadout: melee + ranged, 3 artifacts, 3 talismans that level while equipped | Every drop can change the build; enchant points refund on removal | Echo Shards cap at 100, so payouts above the cap are wasted |
| [Soda Dungeon 2](https://mobilesyrup.com/2020/07/05/soda-dunegon-2-review/) | Free, ads + IAP | Deep dungeon, town to upgrade, configurable auto-fight | No timers, lives, or paywall; players set how heroes fight | Called grindy; players tire of seeing the same early monsters |
| [Nonstop Knight 2](https://www.pocketgamer.com/articles/080496/nonstop-knight-2-review/) | Free, IAP | Auto-run ARPG; player only fires skills; item sets; endless progress | Proves one-thumb auto-ARPG is fun | Keys gate chest rewards; reviewers cite IAP pressure |
| [Eternium](https://toucharcade.com/games/eternium) | Free, IAP | Endless generated Trials with leaderboards | No energy system, offline play, "never pay to win" stance | Manual combat; some reviews still call monetization aggressive |
| [Diablo Immortal](https://www.engadget.com/diablo-immortal-review-120001807.html) | Free, heavy IAP | 3–4 minute Elder Rifts, Diablo loot | Rift length is right for phones | Endgame power sold through crests; lasting backlash |
| [Melvor Idle](https://apps.apple.com/app/id1518963622) | Free trial, $9.99 premium unlock | Premium idle RPG, offline progress (24-hour cap) | Proves a premium idle RPG sells on iOS; even playing field | Menu-heavy; no real-time combat to watch |
| [Vampire Survivors](https://www.pocketgamer.biz/news/80396/vampire-survivors-surprise-launches-to-mobile/) | Free, optional ads only; also on Apple Arcade | Short runs, permanent unlocks, portrait support | Monetization never interrupts play | Fixed run length; shallow loot |
| [Archero](https://www.deconstructoroffun.com/blog/2019/8/9/why-archero-banked-25m-but-leaves-25m-hanging-hlx9n) | Free, IAP | Lone hero, auto-fire, gear between runs | One-touch control, short feedback loops, readable enemies | Free-to-play meta pressure |
| [IdleOn](https://www.gsmgotech.com/2025/12/the-idle-mmo-phenomenon-how-legends-of.html?m=1) | Free, IAP | Deep idle RPG, automation, offline progress | Long retention from interlocking systems | Steep learning curve; cluttered UI once systems pile up |

### Copy

- **Let players program the autopilot** (Soda Dungeon 2). Our Tactics list does this; make it the star of onboarding.
- **Short runs** (Diablo Immortal's Rifts). Keep the 3–8 minute target.
- **Endless generated mode + leaderboard** (Eternium Trials). Deep Rifts + Game Center cover it.
- **Fair, upfront pricing** (Melvor Idle, Vampire Survivors). Apple Arcade is a second route worth pitching, as Vampire Survivors did.
- **Readable combat** (Archero). Chunky silhouettes, effects that never hide enemies or telegraphs.
- **Gear is the build** (Minecraft Dungeons II). Already adopted.

### Prevent

| Pitfall seen in | What goes wrong | Hearthdelve rule |
| --- | --- | --- |
| Soda Dungeon 2 | Same monsters for the first 100 floors | 5 biomes × Echo variants, affix milestones every 25 Depths, a new biome in each content update |
| Nonstop Knight (original) | Progression slows to a crawl and stops feeling meaningful | Always a reachable goal per session: Charm ranks, Glyph Points, Paragon, Hearth projects |
| Nonstop Knight 2 | Keys ration rewards ("Diablo with forced breaks") | No keys, energy, or chest timers |
| Diablo Immortal | Power for sale | Never sell power; cosmetics or expansions only |
| Minecraft Dungeons II | Currency cap wastes rewards | No carry caps; any overflow auto-converts to a useful material |
| Mobile idle RPGs generally | Offline yields only gold, so players leave the app running | Offline Expeditions return real loot, Charm XP, and materials |
| IdleOn | Too many systems, cluttered UI | Unlock one system at a time; each screen owns one job |

## Core loops

Two loops share one hub: an active Rift loop when the player is watching and an Expedition loop when the app is closed, and both feed loot into the Hearth, where it becomes a stronger build for the next run.

&#91;embedded content: core loops · active, Hearth, away\]

### Session shapes

| Session | Length | Typical actions |
| --- | --- | --- |
| Check-in | Under 2 min | Open, collect Expedition loot, equip an upgrade, send a new Expedition |
| Coffee break | 5–10 min | One or two Delves or a Deep Rift push, then sort loot |
| Evening | 30–60 min | Several pushes, Tactics tuning, Blacksmith re-rolls, Hearth projects |

The long arc runs underneath every session: best Depth, Paragon level, Codex completion, and the Hearth's growth.

## Hero and loadout

There are no classes: the gear is the build. Every hero always carries a melee and a ranged weapon, gets active skills from three Relics and passives from three Charms, and swaps any of it for free outside a Rift. One lucky drop can turn a tank into a glass-cannon archer in a tap, which is what makes loot the heartbeat of an idle game. The model follows Minecraft Dungeons II, trimmed for auto-battle.

### Loadout slots (12)

| Slot | Count | Gives | Unlocks at hero level |
| --- | --- | --- | --- |
| Melee weapon | 1 | Melee attack pattern + weapon-type perk | 1 |
| Ranged weapon | 1 | Ranged attack; ammo regenerates, never collected | 1 |
| Armor: helm, chest, legs, boots | 4 | Max HP, armor, affixes; set bonuses at 2 and 4 pieces | 1 |
| Relics | 3 | Active skills that cost Souls and have cooldowns | 1, 5, 10 |
| Charms | 3 | Passives that rank up (I → III) while equipped | 3, 15, 30 |

### Weapon types

The weapon type sets the auto-attack; affixes and Uniques change the numbers and add effects. The hero switches weapons automatically: ranged while the target is beyond 3 tiles, melee once it closes (Tactics can override).

| Kind | Type | Range | Attacks/s | Innate perk |
| --- | --- | --- | --- | --- |
| Melee | Sword | 1 tile | 1.0 | Every 3rd hit cleaves |
| Melee | Hammer | 1 tile | 0.7 | Every 4th hit stuns for 1 s |
| Melee | Daggers | 1 tile | 1.8 | +15% crit chance |
| Melee | Spear | 2 tiles | 1.1 | Pierces one enemy |
| Melee | Scythe | 1.5-tile arc | 0.9 | 3% of damage healed |
| Ranged | Bow | 8 tiles | 0.9 | Every 3rd shot is charged (+100%) |
| Ranged | Crossbow | 7 tiles | 1.5 | Bolts pierce |
| Ranged | Wand | 6 tiles | 1.2 | Homing bolts; element set by affix |
| Ranged | Sling | 6 tiles | 1.3 | Shots ricochet to 1 extra target |

### Relics (skills)

Relics are the hero's active skills. Each costs **Souls** (1 per kill, +5 per elite, cap 100, slow regen) and has a cooldown. Tactics rules fire them automatically; the player can also tap one to fire it early. Every Relic is tagged so affixes, Charms, and Uniques can target tags.

| Relic | Souls | Cooldown | Effect | Tags |
| --- | --- | --- | --- | --- |
| Ember Flask | 30 | 6 s | Firebomb: 380% Power as Fire in a 3-tile radius; burning ground 3 s | Fire, AoE |
| Lantern Ward | 40 | 18 s | Shield absorbing 20% max HP for 6 s | Defense, Radiant |
| Briar Hound | 60 | 30 s | Hound for 20 s: taunts, bites for 90% Power | Summon, Nature |
| Root Snare | 25 | 10 s | Roots enemies within 2 tiles for 2.5 s | Control, Nature |
| Blink Feather | 15 | 5 s | Dash 4 tiles away from the nearest enemy; next attack crits | Mobility |
| Hearthbread Totem | 50 | 25 s | Totem heals 4% max HP/s within 3 tiles for 8 s | Sustain, Summon |

Launch target: 30 Relics across Fire, Frost, Nature, Radiant, Shadow, and untyped.

### Charms (passives)

Charms are passive trinkets that rank up from I to III by earning Charm XP while equipped. Expedition time counts at 50%, so idle play levels them too. Target pace: Rank II after about 3 hours of active play, Rank III after about 15.

| Charm | Rank I → III |
| --- | --- |
| Ember Heart | Burn damage +20% → +50% |
| Lucky Acorn | Magic find +10% → +30% |
| Mossback Shell | Damage taken −8% → −20% while standing still |
| Moth Lantern | Lantern burns 10% → 25% slower |
| Hound's Collar | Summons gain +25% → +75% HP and damage |
| Soul Jar | Max Souls +20 → +60; +1 → +3 Souls per kill |

Launch target: 24 Charms.

### Rarity

Every weapon, armor piece, and Relic rolls one of three rarities. Charms have no rarity; they are found whole and ranked up.

| Rarity | Random affixes | Fixed effect | Base drop share |
| --- | --- | --- | --- |
| Common | 1 | None | 60% |
| Rare | 2 | None | 32% |
| Unique | 2 | 1 signature effect, always the same for that named item | 8% |

Unique signature effects are the build-makers (example: *Cinderfang*, a Unique Hammer: "Stuns from this weapon trigger a free Ember Flask"). Some Unique armor also belongs to a named set with 2- and 4-piece bonuses. Item level, affix ranges, and Depth-gated quality tiers are in Loot and items.

### Glyphs (enchantments)

Glyphs add a second, slower layer of tuning. A Glyph is learned once (dropped by Guardians and events) and kept forever in the Codex. The hero earns 1 **Glyph Point** per level; applying a Glyph to an item spends points, and removing it refunds them, so experimenting is free.

- Sockets: Common 1, Rare 2, Unique 2.
- Each Glyph has Ranks I–III costing 1 / 2 / 3 points.
- Examples: *Kindle* (melee hits ignite), *Ricochet* (ranged shots bounce), *Thrift* (Relics cost 15% fewer Souls), *Bulwark* (+armor), *Harvest* (+Souls per kill).

### Hero level and stats

- Hero level 1–100 grants base HP and 1 Glyph Point per level (points accrue unseen until Glyphs unlock, then appear all at once). After 100, XP flows into Paragon (see Meta progression).
- There are no primary stats. Damage scales from **Power**, set by the item level of the weapon or Relic being used. Defense comes from armor pieces.
- Derived stats rolled as affixes: crit chance (base 5%), crit damage (base +50%), attack speed, cooldown reduction, area damage, elemental bonus, damage to elites, max HP, armor, all-resist, dodge, life per hit, move speed, Soul gain, magic find, lantern efficiency.

### Example builds

| Build | Melee | Ranged | Relics | Charms | Plays like |
| --- | --- | --- | --- | --- | --- |
| Ember Bruiser | Hammer (Cinderfang) | Wand | Ember Flask, Lantern Ward, Root Snare | Ember Heart, Mossback Shell, Soul Jar | Stands in the middle and burns everything |
| Hound Warden | Spear | Bow | Briar Hound, Hearthbread Totem, Root Snare | Hound's Collar, Mossback Shell, Lucky Acorn | Lets the pet tank while poking from range |
| Glass Archer | Daggers | Crossbow | Blink Feather, Ember Flask, Lantern Ward | Ember Heart, Moth Lantern, Soul Jar | Kites constantly; fast pushes, fragile |

## The Descent (Rift system)

The dungeon is one infinite stack of numbered **Depths**. A single Rift run takes the hero through 1–3 generated floors at a chosen Depth, fills a progress meter by killing enemies, then summons a Guardian. Beat the Guardian and the next Depth unlocks.

### Two ways to enter

| Mode | Depth chosen | Lantern (soft timer) | Rewards | Purpose |
| --- | --- | --- | --- | --- |
| Delve | Any Depth up to your best | Off | Loot, gold, XP, crafting materials | Farming, testing builds, relaxing |
| Deep Rift | Your best Depth, or lower | On | Everything above + Depth advancement, Heirloom chances, Paragon bonus XP | Pushing the number |

### Run structure

1. **Gate.** Pick Depth and mode. The gate shows the biome, the active Rift modifier, and a predicted difficulty (Easy / Fair / Hard / Deadly) from the loadout's effective build multiplier vs. the B(d) that Depth requires (Easy at 1.5× or more, Fair 1.0–1.5×, Hard 0.7–1.0×, Deadly below 0.7×; see Balance math).
2. **Floors.** Each floor is a generated layout of 4–8 rooms. Kills fill the **Rift meter**: fodder 1%, elites 4–6%, rare packs 8–10%. Stairs to the next floor appear once a floor is roughly cleared; the hero takes them automatically if the meter isn't full.
3. **Guardian.** At 100% the Guardian spawns near the hero. No more meter, just the boss.
4. **Result.** Loot from the Guardian, gold and crafting materials, and (in Deep Rifts) a Depth jump.

### The Lantern (cozy soft timer)

Diablo 3's hard 15-minute fail state is replaced by the **Lantern**, which burns down over a 6-minute baseline. Running out never fails the run; it only shrinks the Depth jump.

| Lantern left at Guardian kill | Depth advance |
| --- | --- |
| More than 50% | +3 |
| 25–50% | +2 |
| Under 25% | +1 |
| Empty | +0 (loot still kept) |

Lantern Shrines refill 20%. Lantern-efficiency gear and the Hearth's Chandlery slow the burn.

### Death

The hero wakes at the Hearth with everything already picked up. A death in a Deep Rift ends that push attempt and gives +0 Depth. No gear loss, no durability, no corpse runs.

### Depth structure

- **Biome bands:** every 10 Depths the biome changes, cycling Mossy Cellars → Fungal Hollows → Drowned Library → Ember Forges → Starless Vault. After Depth 50 the cycle repeats as **Echo** variants (darker palette, +1 elite affix, new mob variants). Depth-to-biome is a versioned table, not a formula, so an expansion's new rotation takes effect only from a stated Depth band upward (for example, from Depth 201) and no Depth below it ever changes biome. Saves and leaderboard snapshots record the table version.
- **Mechanic milestones:** Depth 25 adds 2-affix elites; 50 adds 3-affix elites and Heirloom drops; 75 adds Rift modifiers; 100 adds 4-affix elites; 150 adds Starforged drops. After 150, nothing new is gated; numbers alone climb.
- **Warden fights:** every 50 Depths the Guardian is a scripted milestone boss with an extra phase and a guaranteed legendary.
- **Rift modifiers (Depth 75+):** one per run, shown at the Gate. Examples: *Brittle* (enemies take +25% crit damage, you take +15%), *Swarm* (2× fodder, half HP), *Fog* (vision radius 60%), *Bounty* (elites drop 2× materials).

### Leaderboards

Best Deep Rift Depth goes to Game Center, saved with a snapshot of the loadout that set it. A local ghost of your best run's timeline (meter vs. lantern) shows on the Gate so pushes feel like racing yourself.

## Combat model

Combat is real-time auto-battle on a top-down tile grid, driven by a fixed-tick simulation (20 ticks/s). The hero moves, targets, and casts on their own using a player-authored **Tactics** list; the player's only live inputs are tapping a Relic to fire it early, a potion button, a speed toggle (1×/2×/4× in Delves), and pause.

### Hero AI

1. **Target selection** each tick from a priority rule (default: nearest; options: elites first, lowest HP, highest threat, Guardian only).
2. **Positioning** by weapon: ranged while the target is beyond 3 tiles, melee once it closes. A Kite stance always prefers range; a Guard stance holds behind summons. Pathing uses A\* on the room grid, recomputed at most every 0.5 s.
3. **Action** = the first Tactics rule whose condition is true and whose skill is ready; otherwise the generator skill.

### Tactics (gambits)

Tactics are an ordered list of IF → THEN rules, evaluated top to bottom every decision tick. Players start with 3 slots and unlock up to 10 through the Hearth's Library. This is where most build skill lives.

| # | IF (condition) | THEN (action) |
| --- | --- | --- |
| 1 | Self HP below 35% | Drink potion |
| 2 | Lantern Ward ready AND elite within 4 tiles | Use Lantern Ward |
| 3 | 3+ enemies within 3 tiles AND Souls ≥ 30 | Throw Ember Flask |
| 4 | Target is Guardian | Summon Briar Hound |
| 5 | Target beyond 3 tiles | Ranged attack |
| 6 | Always | Melee attack |

Condition library (unlocked progressively): HP thresholds (self, target), enemy count in radius, target type (fodder/elite/rare/Guardian), target affix present, Soul thresholds, buff/debuff present, cooldown ready, Lantern below X%, Rift meter above X%. Advanced unlocks add AND/OR and a "hold until" modifier for timing big cooldowns.

### Damage formula

Outgoing hit:

```latex
D = P \cdot S \cdot \left(1 + \sum A_i\right) \cdot \prod_j X_j \cdot C
```

- P = Power of the weapon or Relic used, set by its item level (which comes from the Depth it dropped at).
- S = attack or Relic coefficient (a Sword hit is 1.0; Ember Flask is 3.8).
- A = additive bonuses sharing one bucket: affixes, Glyphs, Charms, Paragon.
- X = independent multipliers: Unique signature effects, set bonuses, Rift modifiers. Keep these rare and visible; they are the long-term power engine.
- C = 1 + crit damage on a crit, else 1.

Incoming damage after mitigation:

```latex
D_{taken} = D_{enemy} \cdot \left(1 - \frac{Armor}{Armor + 50L}\right) \cdot \left(1 - \frac{Res}{Res + 5L}\right) \cdot \prod_k (1 - R_k)
```

L = enemy level (Depth + 60). R = multiplicative damage-reduction sources. Dodge is rolled before mitigation.

### Enemy behavior

Each mob has a role template: **Fodder** (walk in, melee), **Brute** (slow, telegraphed slam), **Ranged** (keeps distance), **Caster** (area denial), **Swarmer** (fast, fragile, packs of 6–10). Every dangerous attack has a visible telegraph of at least 0.6 s, so a well-tuned Tactics list (dodge-roll on telegraph, for heroes with a movement Relic like Blink Feather) can play around it.

## Procedural generation

Every Rift is generated from one 64-bit seed, so a run can be replayed, shared, or simulated headlessly for balance. Generation runs in four passes: layout, population, events, Guardian.

### 1. Layout

- Grid of 16×16-tile rooms joined by short corridors, built with a seeded room-graph: pick 4–8 rooms, connect them as a tree, add 0–2 loops so the hero isn't always backtracking.
- Each biome supplies room templates (hand-made 16×16 chunks with open spawn zones) plus a tileset. Templates are rotated and mirrored for variety; target 20+ templates per biome at launch.
- One room is tagged Entry, one Stairs (or Guardian Arena on the last floor), and up to two Side rooms for events.

### 2. Population (threat budget)

Each room gets a **threat budget** from Depth and room size; packs are bought from the biome's mob table until the budget is spent.

| Pack | Threat cost | Meter value | Notes |
| --- | --- | --- | --- |
| Fodder group (4–8) | 1 each | 1% each | Always the bulk |
| Brute / Caster / Ranged | 3 each | 2% each | Mixed into fodder packs |
| Swarm (6–10) | 0.5 each | 0.5% each | Fast, fragile |
| Champion pack (3 blue elites) | 15 | 5% each | Share the same affixes |
| Rare + minions (1 yellow + 4) | 18 | 10% + 1% each | Rare has one more affix than champions |

Each biome has 3 mob families (example, Fungal Hollows: sporelings, mycelium brutes, cap-shamans), each covering several roles. Echo variants swap in recolored, re-skilled versions with one new attack each.

### 3. Elite affixes

Affix count by Depth: 1 (Depth 1–24), 2 (25–49), 3 (50–99), 4 (100+). Pairs that combine unfairly (for example Frozen + Jailer) are blocked in a compatibility table. Every affix has a distinct icon and color so it reads at phone size.

| Affix | Effect | Unlocks at Depth |
| --- | --- | --- |
| Molten | Leaves fire trails; explodes on death | 1 |
| Frozen | Spawns frost orbs that burst after 1.5 s | 1 |
| Shielding | Periodically immune to damage for 3 s | 1 |
| Vampiric | Heals 30% of damage dealt | 1 |
| Thornback | Reflects 15% of melee damage | 10 |
| Waller | Raises walls that split the room | 10 |
| Splitter | Splits into two smaller copies at 50% HP | 20 |
| Mortar | Lobs telegraphed shells at range | 20 |
| Haunted | Releases a ghost on death that chases the hero | 30 |
| Vortex | Pulls the hero toward it | 40 |
| Lanternbane | Each hit drains 1% Lantern | 60 |
| Jailer | Roots the hero for 1.5 s | 75 |

### 4. Events

Side rooms roll one event from a weighted table. At most one event per floor, two per Rift.

| Event | Effect | Weight | From Depth |
| --- | --- | --- | --- |
| Shrine | One of: +25% damage 30 s, 2× move speed 30 s, +50% loot quality this floor | 30 | 1 |
| Lantern Shrine | Refills 20% Lantern | 20 | 1 |
| Cursed Chest | Survive 3 waves in 30 s for a chest with 1 guaranteed Unique roll | 15 | 5 |
| Glimmerkin | Treasure creature that flees; drops gold and materials if caught | 10 | 5 |
| Lost Wanderer | Meet a Wanderer for a small gift; each Wanderer's first rescue is a scripted event at their building's unlock Depth | 10 | 3 |
| Campfire | Full heal; Charms gain 2 minutes of XP | 10 | 1 |
| Glyph Lectern | Learn a random unowned Glyph | 5 | 15 |

### 5. Guardians

- Each biome has 3 Guardians, each with 2–3 telegraphed mechanics and an enrage at 30% HP.
- Every 50 Depths a milestone Warden appears: a scripted fight with an extra phase and a guaranteed Unique.
- Guardian HP is a fixed multiple of fodder HP at that Depth (start at 120×), so time-to-kill tracks the same scaling curve as everything else.

## Loot and items

Loot is the progression engine: item level follows Depth with no ceiling, so going deeper is the only way to grow Power, and Uniques plus sets are where builds come from. Every item is scored for the current loadout at pickup, so the player never does stat math on a phone.

### Item level and Power

- **Item level = Depth it dropped at + 10** (Delve drops use the Delve's Depth). Expeditions drop at their Depth.
- Power on weapons and Relics, and HP/armor on armor, scale with item level on the curve in Balance math.
- The Blacksmith can raise an old favorite's item level to your best Depth for materials, so a perfect Unique found at Depth 40 can come with you to Depth 400.

### Rarity odds

Rarity uses the three tiers from Hero and loadout. Odds shift toward Unique as Depth rises, capped so Uniques stay special.

| Source | Common | Rare | Unique |
| --- | --- | --- | --- |
| Normal mob, Depth 1 | 60% | 32% | 8% |
| Normal mob, Depth 100+ | 45% | 40% | 15% |
| Elite pack | 0% | 75% | 25% |
| Guardian | 0% | 50% (×2 items) | 1 guaranteed |

Pity rule: if 40 Rares drop in a row with no Unique, the next Rare is upgraded to a Unique.

### Quality tiers (Depth-gated)

Quality is a second roll layered on rarity, the long-tail chase for infinite play.

| Tier | Drops from | Chance on Rare/Unique | Effect |
| --- | --- | --- | --- |
| Standard | Any Depth | Base | Normal affix ranges |
| Heirloom | Depth 50+ | 10% | Affix ranges +25%, gold name border |
| Starforged | Depth 150+ | 1% of Heirlooms | Every affix at max roll, signature effect +20% |

### Affixes

Affixes are tagged by slot so weapons roll offense, armor rolls defense, and Relics roll Relic modifiers. Each affix has a range (example: crit chance 3–6%), and Heirloom/Starforged push that range.

| Slot | Affix pool (examples) |
| --- | --- |
| Melee weapon | +% melee damage, attack speed, crit chance, crit damage, area damage, life per hit, chance to ignite/chill/bleed |
| Ranged weapon | +% ranged damage, attack speed, pierce +1, crit chance, ammo regen, chance to ignite/chill/bleed |
| Armor | Max HP, armor, all-resist, dodge, life regen, move speed, damage to elites, lantern efficiency, magic find |
| Relic | +% Relic damage, cooldown reduction, Soul cost reduction, duration, radius, +1 charge |

### Uniques and sets

- Launch target: 60 Uniques (20 weapons, 25 armor, 15 Relics), each with a signature effect that changes how something plays, not just a bigger number.
- 6 armor sets of 4 pieces, each with 2-piece (stat) and 4-piece (build-defining) bonuses.
- Example 4-piece, *Lamplighter's Vigil*: "Your Lantern no longer burns while a Relic is on cooldown longer than 10 s; Relic damage +150%."

### Codex and the Reliquary

Inspired by Diablo 3's Kanai's Cube: salvaging a Unique records its signature effect in the Codex. The Hearth's **Reliquary** lets the hero equip up to 3 recorded signature effects (one weapon, one armor, one Relic) on top of gear, unlocked one slot at a time. This turns duplicate Uniques into progress and lets late-game builds stack signatures.

### Crafting (Blacksmith)

| Action | Cost | Notes |
| --- | --- | --- |
| Salvage | Gives materials | Common → Dust, Rare → Shards, Unique → Embers + Codex entry |
| Re-roll one affix | Shards (Rare) or Embers (Unique) | Other affixes locked; cost doubles per re-roll on the same item |
| Raise item level | Dust + gold | Up to your best Depth |
| Craft a Rare | Shards | Pick slot and type; random affixes |
| Transmute a Unique | Embers (high) | Turn a Unique into another random Unique of the same slot |

### Inventory

- Bag: 40 slots; Stash: 100 slots, expandable at the Hearth.
- **Loot rules** (cozy QoL): auto-salvage by rarity, score threshold, or "not an upgrade for any saved loadout". Uniques are never auto-salvaged until recorded in the Codex.
- Up to 4 saved loadouts for one-tap swaps between farming and pushing.

### Bestiary cards

Every creature has a card, dropped by chance when the hero kills it, so every kill in an auto-battler carries a little hope. Cards are a collection, not Power: they unlock lore, decor, and card backs, feed the Trophy Hall, and later become the decks for the Inn card game (see Cozy layer).

- **Launch set:** one card per mob role in each of the 15 families, plus 15 Guardians and 2 Wardens (about 77 cards). Each Echo variant has a **foil** version of its base card.
- **Drop odds:** 1% per kill until you own that card, then 0.1%. Elites roll 5×, rare packs 10×. A Guardian's card is guaranteed on its first kill, then 5%. Pity: the card is guaranteed after 300 kills of that creature without it. Expeditions roll cards at the same rates inside their batched loot.
- **Duplicates** raise a card's stars (1 ★ at 1 copy, 2 ★ at 3, 3 ★ at 10); a 3 ★ card unlocks its lore entry. Copies past that become gifts to Wanderers.
- **Rewards:** every 10 cards owned grants decor or a card back. The Trophy Hall's small family bonus requires owning that family's Guardian card. Cards never add stats directly.
- **Card values for the later card game** are generated from data: four edge numbers from the creature's role and Depth band (Brutes heavy on one side, Swarmers low but even, Guardians high), so no card needs hand balancing.
- **UI:** a Bestiary tab inside the Codex, not a new screen. A drop gets a short flip reveal, quieter than a Unique's beam.
- Cards are never sold, in packs or otherwise.

## Idle systems

The hero keeps working while the player is away, and the payout is real: gear, materials, XP, and Charm XP, not just gold. Idle play is about 60% as efficient as active play, so playing is always better but never required.

### Three modes of play

| Mode | Player is | What happens | Efficiency vs. active |
| --- | --- | --- | --- |
| Active | Watching | Hero runs Delves or Deep Rifts on screen; player taps Relics and potions | 100% |
| Auto-Delve | App open, not watching | Delves repeat at a chosen Depth at up to 4× speed. **Lantern Mode** dims the screen and stops rendering to save battery; the sim keeps running | 100% (Delve only, no Depth advance) |
| Expedition | App closed | Progress computed on return from the hero's stats; no frame-by-frame sim | 60% |

Deep Rifts are never automated: pushing Depth is the one thing that always needs the player.

### Expeditions

- Before closing the app, the player picks an Expedition Depth from any Depth rated Easy or Fair for the current loadout. Default: best Depth minus 10%.
- Expedition length cap: **8 hours** base, raised to 12 / 16 / 24 by the Hearth's Map Room.
- Return screen, "While you were away": Rifts cleared, XP, materials, a short list of the best items found, and Charm rank-ups. Items below the loot-rule threshold are auto-salvaged first so the bag never overflows.
- If the loadout changed or a Depth turns out harder than predicted, the Expedition ends early and returns everything earned so far. It never fails to zero.

### How offline gains are computed

The simulation core estimates a clear time for the loadout at that Depth by running 3 headless Rifts (well under a second on device) when the player sets the Expedition or changes the loadout, and saves the result. Leaving the app only records a timestamp, so force-quits and short background windows never matter. Offline gains then scale from that sample:

```latex
Rifts = \left\lfloor \frac{\min(t_{away},\ t_{cap})}{\bar{t}_{clear}} \right\rfloor \cdot 0.6
```

Loot is rolled per Rift with the normal tables (batched, not item-by-item), so offline drops can still include Uniques and Heirlooms.

### Companions (Wanderers)

Wanderers rescued in Rifts move into the Hearth. Up to 3 can be sent on short side Expeditions (1–4 hours) that return crafting materials, Glyphs, or decor, never gear. They are the reason to check in a few times a day without being punished for not doing so.

### Notifications

Opt-in only: Expedition cap reached, Companion back. No "come back" nag notifications.

### Clock handling

Use wall-clock time, clamp to the cap, and ignore backwards jumps (count them as 0 elapsed). It is a single-player game, so clock changes only cheat the player out of their own fun; no server check needed.

## Meta progression

Five layers stack so that a session always moves at least one bar: hero level early, Paragon and Hearth forever, Codex for collectors, and Depth milestones for pushers. There is no forced prestige reset; uncapped Depth already provides the infinite climb.

| Layer | Range | Earned by | Gives |
| --- | --- | --- | --- |
| Hero level | 1–100 | XP | Base HP, Glyph Points, Relic/Charm slot unlocks |
| Paragon | 1–∞ | XP after level 100 | Points in four boards |
| Hearth | 12 buildings, 5 tiers each | Gold + materials | Systems, slots, quality-of-life |
| Codex | 60+ entries at launch | Salvaging Uniques, learning Glyphs, collecting Bestiary cards | Reliquary options + small collection bonuses |
| Depth milestones | Every 10 Depths | Deep Rift pushes | One-time rewards, titles, decor |

### Paragon

- One point per Paragon level, spent on four boards. XP per level grows slowly (+2% per level) so levels keep coming at high Depth, where XP per Rift is also higher.
- **Core** (uncapped): +0.5% Power per point. This is the slow, never-ending lever that helps close the scaling gap.
- **Offense / Defense / Utility** (each node capped at 50 points): crit, attack speed, Relic damage; max HP, armor, resist; move speed, magic find, lantern efficiency, Soul gain.
- Points are respec-able for free, so experimenting costs nothing.

### Hearth buildings

| Building | Opens on first clear of | Wanderer | Unlocks | Upgrades raise |
| --- | --- | --- | --- | --- |
| Blacksmith | Onboarding Delve | Smith | Crafting, re-rolls, raising item level | Re-roll discounts, craftable rarity |
| Apothecary | Depth 2 | Herbalist | Potions | Potion strength, charges, cooldown |
| Library | Depth 3 | Archivist | Tactics editing; slots 3 → 10; Codex | AND/OR rules, "hold until" (post-launch) |
| Map Room | Depth 5 | Cartographer | Expeditions | Cap 8 → 24 hours |
| Stash House | Depth 8 | Quartermaster | Storage | Stash 100 → 400 slots |
| Inn | Depth 10 | Bard | Rescued Wanderers live here | Companion Expedition slots 1 → 3 (post-launch) |
| Chandlery | Depth 12 | Chandler | Lantern upgrades | Burn time, Lantern Shrine strength |
| Reliquary | Depth 15 | Relic keeper | Codex signature slots | 1 → 3 slots |
| Garden | Depth 20 | Gardener | Cozy resource loop | Herbs for potions, decor flowers |
| Trophy Hall | Depth 25 | Trophy keeper | Guardian trophies, Training Yard | Displays kills; small bonus vs. that Guardian family |
| Lighthouse | Depth 40 | Lighthouse keeper | Depth milestones | Shows best Depth on the Hearth skyline |
| Glyphwright | Depth 50 | Glyphwright | Glyph ranks (post-launch; the building waits, inert, until then) | Max Glyph rank, socket unlock on Commons |

Opening Depths are starting values to tune in playtests; each Wanderer's first rescue is a scripted event on that Depth's first clear.

### Codex collection bonuses

Every 10 Codex entries grants a small permanent bonus (+1% magic find, +1% Relic damage, and so on). It rewards breadth without forcing anyone to collect everything.

### Seasons (optional, post-launch)

**Echo Seasons** would be an opt-in fresh start: a new hero with a seasonal rule (example: "every Relic is Fire"), its own leaderboard, and rewards limited to cosmetics, Hearth decor, and one new Codex entry carried back. The main hero is never reset or weakened.

### Achievements (Game Center)

Launch with 39 achievements worth 900 points, including 7 long-haul Chase achievements; Glyph Master (20 points) follows when Glyphs ship, keeping 80 of Game Center's [1,000-point cap](https://developer.apple.com/help/app-store-connect/reference/achievements) (100 maximum per achievement) for expansions and Seasons. Achievements mark milestones across every layer, so a pusher, a collector, and a decorator all have a trail to follow.

| Group | Achievement | Condition | Points | Hidden |
| --- | --- | --- | --- | --- |
| Depth | First Light | Clear your first Rift | 5 | No |
| Depth | Into the Hollows | Reach Depth 10 | 10 | No |
| Depth | Lantern-Bearer | Reach Depth 25 | 15 | No |
| Depth | Halfway Down | Reach Depth 50 | 25 | No |
| Depth | Centurion | Reach Depth 100 | 35 | No |
| Depth | Starless | Reach Depth 150 | 40 | No |
| Depth | Bottomless | Reach Depth 200 | 50 | No |
| Depth | Light to Spare | Advance +3 Depth in one Deep Rift | 15 | No |
| Depth | Warden's End | Defeat the Depth 50 Warden | 25 | No |
| Loot | Something Shiny | Find your first Unique | 10 | No |
| Loot | Matched Set | Equip a full 4-piece set | 25 | No |
| Loot | Heirloom | Find an Heirloom item | 20 | No |
| Loot | Starforged | Find a Starforged item | 35 | No |
| Loot | Archivist | Record 25 Codex entries | 25 | No |
| Loot | Complete Codex | Record every launch Unique | 50 | No |
| Build | Well Rehearsed | Fill 10 Tactics slots | 20 | No |
| Build | Kindling | Clear Depth 25 with three Fire-tagged Relics | 25 | No |
| Build | Full Reliquary | Fill all 3 Reliquary slots | 25 | No |
| Build | Paragon of the Deep | Reach Paragon 100 | 40 | No |
| Hearth | A New Neighbor | Rescue your first Wanderer | 10 | No |
| Hearth | Full House | Rescue all 12 Wanderers | 30 | No |
| Hearth | Master Builder | Raise any building to tier 5 | 20 | No |
| Hearth | Lantern-Lit Hamlet | Raise every building to tier 5 | 40 | No |
| Hearth | Home Sweet Home | Fill 20 decor spots | 20 | No |
| Hearth | Moth Friend | Tap the lantern moth 10 times at the Hearth | 5 | Yes |
| Idle | Welcome Back | Return from your first Expedition | 5 | No |
| Idle | Night Shift | Finish a full 24-hour Expedition | 20 | No |
| Idle | Sleep Loot | Get a Unique from an Expedition | 15 | No |
| Idle | Glimmer Catcher | Catch a Glimmerkin | 10 | No |
| Mastery | Teetotaler | Clear a Depth 50+ Deep Rift without a potion | 25 | Yes |
| Mastery | Better Late | Finish a Deep Rift with the Lantern empty | 5 | Yes |
| Mastery | Swift Descent | Clear a Deep Rift at your best Depth in under 3 minutes | 20 | Yes |

**Chase achievements** are the long tail: each should take a dedicated player months, and most players never finish them all. Target times are tuning goals for HearthSimCLI, not promises.

| Achievement | Condition | Points | Target time |
| --- | --- | --- | --- |
| Abyssal | Reach Depth 300 | 40 | Top builds only; 300+ hours |
| Starforged Kit | Equip Starforged items in all 9 weapon, armor, and Relic slots at once | 30 | About 300 hours |
| Paragon Eternal | Reach Paragon 500 | 30 | About 400 hours |
| Ten Thousand Rifts | Clear 10,000 Rifts (Expeditions count) | 20 | About a year of daily play |
| Charmed Life | Raise all 24 launch Charms to Rank III | 20 | About 120 hours of rotating Charms |
| Unbroken | Clear 50 Deep Rifts in a row without dying | 20 | Skill and patience, any Depth over 50 |
| Glyph Master | Raise every launch Glyph to Rank III | 20 | Ships with Glyphs (post-MVP) |
| Bestiary | Own every launch Bestiary card (foils not required) | 20 | About 200 hours |

Chase achievements show their progress in the Codex (for example "Ten Thousand Rifts: 3,412 / 10,000") so the long climb stays visible.

**Implementation notes**

- Counter achievements (Archivist, Full House, Paragon) report percent complete as they progress.
- Achievements are tracked in the save file first and reported to Game Center when online, then re-reported on a new device after an iCloud restore, so nothing is lost offline.
- The Game Center access point shows on the Hearth only, never during a Rift.
- Achievement IDs are permanent in App Store Connect; use a stable scheme such as `hd.depth.100`.

## Cozy layer

The Hearth is a small village in a forest clearing built over the Rift, and it is the game's emotional counterweight: slow, warm, safe, and visibly shaped by everything the player does below. Coziness comes from consequence-free failure, a living home base, and gentle pacing, not from removing challenge.

### The Hearth as a place

- A single hand-built scene the player can pan around (about 2 phone screens wide), not a menu. Buildings are tapped to open their screens.
- Every Hearth building upgrade changes its sprite. The village grows from a campfire and two tents to a lantern-lit hamlet.
- **Day/night follows the device clock**, with lanterns lighting at dusk. Weather (rain, snow, fireflies) rotates for mood only.

### Wanderers (NPCs)

- 12 Wanderers at launch, one per Hearth building (smith, herbalist, cartographer, a bard for the Inn, and so on). Each one's first rescue is a guaranteed Rift event at the Depth that unlocks their building, so they are home in time to introduce it; the random Lost Wanderer event covers later visits and gifts.
- Each has a short three-step friendship thread unlocked by Depth milestones: a few lines of dialogue and a small gift (decor, a Charm, a Glyph). No romance, no gifting minigame.
- Wanderers wander the Hearth, sit by the fire, and comment on your latest Unique or Depth record.

### Decor

- A grid of decor spots around the village. Decor comes from Depth milestones, Wanderer gifts, the Garden, Guardian trophies, and Seasons.
- Purely cosmetic. No stat bonuses on decor, so decorating is never a min-max chore.

### Companion pet

A lantern moth (later: other pets) follows the hero into Rifts. It picks up loot (larger pickup radius) and glows brighter as the Lantern runs low, giving the soft timer a gentle visual instead of a ticking clock.

### Inn card game (post-launch)

A small, quiet card game played at the Inn against Wanderers, using the Bestiary cards the player has collected. It is a second way to enjoy the collection, kept deliberately tiny so it never competes with the Rift for development time.

- **Rules:** a 3×3 board, 5-card hands from your Bestiary. Each card has four edge values; placing a card captures adjacent enemy cards whose touching edge is lower. Most cards owned when the board fills wins.
- **Hearthdelve twist:** each match is played on a biome board, and cards from that biome get +1 on every edge, so collecting widely matters.
- **Opponents:** each Wanderer has a themed deck and three difficulty tiers; the AI is deterministic and lives in HearthCore, so HearthSimCLI can test it.
- **Length:** about 3 minutes a match, portrait, one-handed.
- **Rewards:** decor, card backs, titles, and Wanderer friendship progress. Never Power, never gear.
- **Not at first:** player-versus-player, deck-building beyond picking 5 cards, or extra rule variants.

### Tone rules

- Death text is soft: "You wake by the hearth. Everything you found came home with you."
- No red "FAILED" screens, no countdown timers on screen, no limited-time shop pressure.
- Enemies are creepy-cute (mushrooms, moths, clockwork, drowned books), not gory.
- Music shifts from acoustic Hearth themes to darker biome ambience, and always resolves back to the Hearth theme on return.

## Balance math

Enemies get 12% tougher per Depth while gear Power grows 10% per Depth, so drops alone always fall behind; the difference is what Uniques, sets, Charms, Glyphs, and Paragon must supply. Where a player's build can no longer cover that gap is their personal push ceiling, and it moves up forever as Paragon climbs.

### Core curves

Enemy HP and damage at Depth d:

```latex
HP_{enemy}(d) = HP_0 \cdot 1.12^{d} \qquad Dmg_{enemy}(d) = Dmg_0 \cdot 1.08^{d}
```

Gear Power and armor-based hero HP at item level i (i = Depth + 10):

```latex
Power(i) = P_0 \cdot 1.10^{\,i-10} \qquad HP_{hero}(i) = H_0 \cdot 1.08^{\,i-10}
```

Hero HP tracks enemy damage at the same rate, so survival stays roughly flat with Depth and the push is decided by kill speed. The build multiplier the player must bring:

```latex
B(d) = \left(\frac{1.12}{1.10}\right)^{d} \approx 1.018^{d}
```

&#91;embedded content: computed from the curves above · Depth 0–300\]

The requirement stays small through the early game (under 2.5× by Depth 50) and climbs steeply after Depth 150, which is where pushing becomes theorycrafting.

### Where the multiplier comes from

Planned budget at roughly 100 hours of play; every source is multiplicative with the others.

| Source | Target contribution |
| --- | --- |
| Paragon Core (+0.5% Power per point) | ×2–3 |
| Unique signature effects + Reliquary | ×2–4 |
| 4-piece set bonus | ×2–3 |
| Charms at Rank III + Glyphs | ×1.5–2 |
| Heirloom / Starforged affix ranges | ×1.2–1.5 |

The product of the low ends is about 14×, so an average 100-hour build reaches around Depth 150; strong builds push past 200.

### Tuning targets

| Target | Value |
| --- | --- |
| Delve length at a comfortable Depth | 3–5 min |
| Deep Rift at personal best | 6–8 min |
| Fodder time-to-kill at par | 1–2 hits |
| Elite pack time-to-kill | 8–15 s |
| Guardian time-to-kill | 30–60 s |
| First Unique | Within the first 30 minutes |
| Equipped upgrade frequency (to Depth 50) | At least one every 2 Rifts |
| Depth 25 / 50 / 100 / 150 reached | About 2 / 10 / 40 / 120 hours of play |

All values get verified in HearthSimCLI against reference loadouts before each content update. Numbers this spec does not fix (the hero XP curve, Paragon XP base, gold and material costs, building upgrade costs, re-roll base costs) live in one \`Content/tuning.json\` and are tuned against these targets, never hard-coded.

## Technical architecture

The core decision: the whole game runs in a pure-Swift, deterministic simulation that knows nothing about SpriteKit. SpriteKit only draws snapshots of it. That one split gives offline Expeditions, 4× speed, battery-saving Lantern Mode, headless balance testing, and a way out if SpriteKit ever stalls.

### Platform

- Swift 6 with strict concurrency, iOS 18 and later, iPhone first; iPad and Mac (Designed for iPad) come free with the layout rules below.
- SpriteKit for the Rift and Hearth scenes, SwiftUI for every menu, overlaid with `SpriteView`.
- SpriteKit risk: Apple deprecated SceneKit at WWDC 2025, but an Apple engineer stated in 2026 that [SpriteKit is not deprecated](https://developer.apple.com/forums/thread/830810). The sim/render split keeps a renderer swap (Metal or another engine) to a contained rewrite.

### Modules (Swift packages)

| Package | Depends on | Owns |
| --- | --- | --- |
| HearthCore | Nothing (Foundation only) | RNG, Rift generation, combat sim, Tactics evaluator, loot rolls, balance formulas |
| HearthContent | HearthCore | Data definitions: weapons, Relics, Charms, affixes, mobs, biomes, Uniques (JSON + Codable) |
| HearthRender | HearthCore, SpriteKit | Scenes, node pools, animation, effects; reads sim snapshots, never writes game state |
| HearthUI | HearthCore, SwiftUI | All screens: loadout, Tactics editor, Hearth buildings, Codex, Gate |
| HearthPersistence | HearthCore | Save files, schema migrations, iCloud sync |
| HearthSimCLI | HearthCore, HearthContent | macOS command-line tool that runs thousands of Rifts per loadout for balance |
| HearthAudio | HearthCore, AVFoundation | Mixer buses, cue playback from GameEvents, music crossfades, voice limits, haptics |

### Simulation loop

- Fixed tick at **20 Hz**. The renderer interpolates between the last two snapshots at 60/120 fps.
- Speed 2×/4× = more ticks per frame. Lantern Mode = ticks with no rendering.
- Determinism: a custom 64-bit PRNG (xoshiro256\*\* seeded via SplitMix64) rather than GameplayKit, so results never change with OS updates. Separate RNG streams for layout, population, combat, and loot, so tweaking one system never reshuffles the others. The per-tick sim uses no transcendental math (pow, exp, log): scaling curves are precomputed tables indexed by integer Depth and item level, because those functions can return slightly different results across OS versions and would quietly break seed replay. Golden-seed tests also run on the oldest supported iOS.
- Entities: a light data-oriented model (arrays of structs per component), capped at about 150 active entities. Targeting uses a spatial hash grid.
- Pathing: the hero uses A\* on the room grid (re-planned at most every 0.5 s); mobs follow one shared flow field toward the hero, recomputed once per tick.

### Rendering

- `SKTileMapNode` for floors and walls, texture atlases per biome, node pooling for mobs, projectiles, and damage numbers.
- Lighting faked with additive glow sprites rather than `SKLightNode`, which is costly with many lights.
- Particle budget: at most 8 live emitters, each capped in birth rate.

### Numbers

All stats are `Double` (safe to about 1e308, which is Depth 6,000+ on the planned curve). Display uses short suffixes (K, M, B, T, then aa, ab, ac…). Balance comparisons (Power vs. Threat) are done in log space to avoid precision loss.

### Saves and sync

- One Codable JSON save with a schema version and a migration chain. Autosave at every Rift end, Hearth change, and app backgrounding; keep the last 3 saves locally.
- iCloud sync via a CloudKit private-database record holding the save blob. On conflict, show both (best Depth, Paragon level, last played) and let the player choose.
- Game Center: best Deep Rift Depth leaderboard (with loadout snapshot), plus achievements (see Meta progression).

### Performance targets

| Metric | Target |
| --- | --- |
| Frame rate in Rifts | 60 fps on iPhone 13-class hardware; 120 fps on ProMotion where it holds |
| Memory | Under 400 MB |
| Sim cost | 1,000 headless Rifts in under 10 s on an M-series Mac |
| Offline calculation on launch | Under 0.5 s |
| Install size | Under 300 MB |

### Testing

- Unit tests for HearthCore (formulas, Tactics evaluation, loot tables).
- Golden-seed tests: fixed seeds must generate identical Rifts across builds.
- Balance runs in HearthSimCLI on every content change: clear-time and death-rate tables per Depth for a set of reference loadouts.
- No ad SDKs; the only third-party SDKs are Firebase Analytics and Crashlytics (see Analytics and diagnostics).

## Analytics and diagnostics

Every meaningful game event is logged once, through one typed pipeline, to three places: Firebase Analytics for trends, Crashlytics for crashes and errors with a breadcrumb trail, and an on-device log for bug reports. Every Rift event also carries its seed, so any reported problem can be replayed exactly in HearthSimCLI.

### Stack

| Tool | Used for |
| --- | --- |
| Firebase Analytics | Product events, funnels, retention, balance telemetry |
| Firebase Crashlytics | Crashes, non-fatal errors, custom logs (breadcrumbs), custom keys (state at crash time) |
| MetricKit | Apple's own hang, CPU, disk-write, and launch diagnostics, forwarded as Crashlytics non-fatals |
| On-device breadcrumb file | Last 500 events, attached to in-app bug reports |
| HearthSimCLI | Replays any reported Rift from its seed, loadout, and versions |

### Architecture rule

HearthCore stays free of Firebase. The sim emits typed `GameEvent` values on an event bus; a separate **HearthTelemetry** package subscribes and routes each event to the right sinks. Swapping or adding a backend touches one package, and headless sim runs simply have no telemetry subscriber.

&#91;embedded content: telemetry pipeline · 1 router, 3 sinks\]

### Event conventions

- Names are `snake_case` `domain_action` (`rift_start`, `item_equip`), at most 40 characters, never starting with `firebase_`, `google_`, or `ga_`.
- Firebase allows about 500 distinct event names and 25 parameters per event; parameter values are capped at 100 characters (approximate limits; confirm against the Firebase docs). Design target: under 60 event names, at most 15 parameters each, enforced by a CI test.
- Events carry only `session_id` as a shared parameter. Slower-changing context is set as Firebase **user properties** and updated when it changes: `schema_v`, `content_v`, `sim_v`, `best_depth`, `paragon`, `hero_level`. Firebase records the app version on its own.
- Rift-scoped events add `rift_id`, `rift_seed`, `depth`, `mode`, `loadout_hash`, which keeps the largest event (`rift_end`) at 15 parameters.
- Per-tick and per-hit data never goes to Analytics. It is summarized per Rift, and the raw stream only reaches the local breadcrumb file (sampled to 1 entry per second in combat).

### Event catalog

| Domain | Event | When | Key parameters |
| --- | --- | --- | --- |
| App | `app_open` | Cold or warm launch | `launch_ms`, `is_cold`, `offline_minutes` |
| App | `app_background` | App leaves foreground | `session_seconds`, `scene` |
| App | `save_write` | Each autosave | `bytes`, `ms`, `reason` |
| App | `save_migrate` | Save schema upgraded | `from_v`, `to_v`, `ms` |
| App | `sync_conflict` | iCloud conflict shown | `local_depth`, `cloud_depth`, `choice` |
| Onboarding | `tutorial_step` | Each onboarding step completes | `step`, `seconds` |
| Rift | `rift_start` | Gate confirms | `predicted`, `modifier`, `biome`, `lantern_start` |
| Rift | `floor_complete` | Stairs taken | `floor`, `seconds`, `meter_pct`, `kills` |
| Rift | `guardian_spawn` | Meter hits 100% | `seconds_elapsed`, `lantern_pct`, `guardian_id` |
| Rift | `rift_end` | Rift ends any way | `result` (clear, death, quit, lantern\_out), `seconds`, `depth_delta`, `kills`, `elites`, `lantern_end`, `potions_used`, `dps_avg`, `damage_taken` |
| Rift | `hero_death` | Hero dies | `killer_id`, `killer_affixes`, `hp_max`, `last_relic`, `tick` |
| Rift | `event_room` | Side event resolved | `event_type`, `outcome` |
| Loot | `item_drop` | Rare or better drops | `rarity`, `quality`, `slot`, `item_id` (Uniques), `ilvl`, `source` |
| Loot | `item_equip` | Item equipped | `slot`, `rarity`, `score_delta_dmg`, `score_delta_tough` |
| Loot | `item_salvage` | Salvage (batched per action) | `count`, `by_rarity`, `auto` |
| Loot | `craft_action` | Blacksmith action | `action`, `rarity`, `cost`, `attempt` |
| Build | `loadout_change` | Leaving the loadout screen with changes | `relics`, `charms`, `weapons`, `set_id` |
| Build | `tactics_edit` | Leaving Tactics with changes | `rule_count`, `conditions_used` |
| Build | `paragon_spend` | Points spent | `board`, `points` |
| Hearth | `building_upgrade` | Building tier raised | `building`, `tier`, `cost` |
| Hearth | `wanderer_rescue` | Wanderer joins | `wanderer_id`, `depth` |
| Idle | `expedition_start` | App closes with Expedition set | `depth`, `predicted_rifts_per_hour` |
| Idle | `expedition_return` | Return screen shown | `minutes`, `capped`, `rifts`, `uniques`, `ended_early` |
| Progress | `depth_record` | New best Depth | `depth`, `hours_played` |
| Progress | `level_up` | Hero or Paragon level | `kind`, `level` |
| Progress | `achievement_unlock` | Achievement earned | `achievement_id` |
| Store | `unlock_view` | Unlock screen shown | `trigger` |
| Store | `unlock_purchase` | StoreKit result | `result`, `price_tier` |
| Perf | `perf_rift` | Rift ends (sampled 10%) | `fps_p50`, `fps_p5`, `entities_max`, `mem_mb_peak` |
| Loot | `card_drop` | Bestiary card drops | `card_id, foil, first_copy, stars, source` |
| App | `settings_change` | Any setting changed | `setting, value` |

### Breadcrumbs

- Every `GameEvent` (and every screen change) is also written as one compact line to the Crashlytics custom log and to the on-device breadcrumb file. Crashlytics keeps 64 kB per session and drops the oldest lines first, so lines stay short: `t=1532 rift_end r=clear d=47 s=312`.
- In combat, a 1-per-second state line is added locally only: tick, hero HP, Souls, Lantern, target, active Relic, entity count.
- The local file is a ring buffer of the last 500 lines, kept across launches, so a crash's trail survives the restart.

### Crash context (Crashlytics custom keys)

Crashlytics allows up to 64 custom keys; we keep about 15, updated on change: `scene`, `rift_seed`, `depth`, `tick`, `mode`, `loadout_hash`, `save_v`, `content_v`, `sim_v`, `entity_count`, `offline_calc` (true while computing offline gains), `last_event`, `best_depth`, `paragon`, `low_power_mode`.

### Errors (non-fatals)

Errors are recorded with stable domains and codes so they group cleanly; variable data (IDs, values) goes in `userInfo`, never in the domain or code. Crashlytics keeps the 8 most recent non-fatals per session, so each one should matter.

| Domain | Example codes | Recorded when |
| --- | --- | --- |
| `hd.save` | load\_failed, migrate\_failed, write\_failed, corrupt\_restored | Save problems; a backup save was used |
| `hd.sync` | cloudkit\_error, conflict\_unresolved | iCloud failures |
| `hd.sim` | invariant\_nan, invariant\_negative\_hp, desync, tick\_overrun | A soft assert in the sim fails (logged with seed and tick, then the sim self-corrects) |
| `hd.content` | missing\_definition, bad\_reference | Data files reference something that doesn't exist |
| `hd.offline` | calc\_timeout, calc\_mismatch | Offline gains took too long or disagreed with a re-check |
| `hd.store` | purchase\_failed, restore\_failed | StoreKit errors |
| `hd.gc` | auth\_failed, report\_failed | Game Center errors |
| `hd.metrickit` | hang, cpu\_exception, disk\_write | Forwarded MetricKit diagnostics |

### Reproducing a bug

1. A crash or non-fatal arrives in Crashlytics with its breadcrumb log and keys (seed, Depth, tick, loadout hash, versions).
2. If the player used **Settings → Send a bug report**, the share sheet bundle also includes the breadcrumb file and a copy of the save.
3. Load the save into HearthSimCLI with the same `sim_v` and `content_v`, replay `rift_seed` to `tick`, and the run reproduces exactly, because the sim is deterministic.

### Privacy

- No personal data, no ad identifier, no ATT prompt: the AdSupport framework is not linked, and ad-personalization signals are disabled in Info.plist.
- Crashlytics user ID is a random install UUID, never a Game Center or Apple ID.
- Settings has an **Analytics** toggle (Crashlytics opt-out included); turning it off stops collection immediately.
- App Store privacy label: Diagnostics and Usage Data, not linked to identity, not used for tracking.

### Dashboards and alerts

- **Funnel:** install → first Rift → first Unique → Depth 10 → Depth 25 (unlock wall) → `unlock_purchase`.
- **Retention:** D1, D7, D30, split by whether the player ever set an Expedition.
- **Balance:** median Rift time and death rate by Depth band vs. Balance math targets; drop-rate observed vs. table (catches RNG or table bugs); Uniques per hour.
- **Health:** crash-free sessions (alert below 99.5%), top non-fatal domains, `perf_rift` p5 fps by device model.
- Optional BigQuery export for custom queries once the event volume justifies it.

### Debug tooling

- Debug and TestFlight builds include a hidden overlay that streams events live and shows the current seed and tick.
- Firebase DebugView via the `-FIRDebugEnabled` launch argument when validating new events.
- A unit test checks every `GameEvent` case has a mapping, name length, and parameter count within limits, so a bad event fails CI instead of silently dropping in production.

## UI and UX

Portrait, one-handed, thumb-zone first: everything tapped often lives in the bottom third of the screen, and no screen needs a second hand. Each screen owns one job, and systems unlock one at a time so the UI never piles up.

### Screens

| Screen | Reached from | Job |
| --- | --- | --- |
| Hearth | App launch | Home scene; tap buildings, see Wanderers, start a Rift |
| Rift Gate | Hearth (the well) | Pick Depth and mode; shows biome, modifier, predicted difficulty, ghost of best run |
| Rift (combat) | Gate | Watch the run; Relic buttons, potion, speed, pause |
| Loadout | Bottom bar, everywhere | 12 slots, saved loadouts, compare on tap |
| Tactics | Loadout, Library | Ordered IF → THEN rules with drag to reorder |
| Bag and Stash | Bottom bar | Items sorted by upgrade score; loot rules |
| Blacksmith, Reliquary, other buildings | Hearth | One building, one job |
| Paragon | Loadout | Four boards, free respec |
| Codex | Library | Uniques, Glyphs, mobs, Wanderer stories |
| While you were away | App return | Expedition summary, best finds first |
| Settings | Hearth gear; Rift pause menu (Audio and Display only) | Audio, gameplay, display, battery, notifications, data (see Settings and quality of life) |

### Rift HUD (bottom to top)

1. Bottom bar: 3 Relic buttons (cooldown rings, Soul cost), potion, speed toggle, pause.
2. Above it: hero HP bar, Soul bar, Lantern (the moth's glow plus a thin arc).
3. Top: Rift meter, Depth, floor number. Nothing interactive at the top.

### Item comparison

- Every item shows one **upgrade score**: estimated change in damage and toughness for the current loadout, as two arrows (green up / red down) with percentages.
- Long-press opens the full affix list and a side-by-side with the equipped item.
- New Uniques get a short reveal moment (beam of light on drop, a sting in the music), the one place the game is loud.

### Onboarding

- First 10 minutes: one Delve with a starter Sword and Bow, then the first Relic, then Tactics with 3 prefilled rules the player can read and tweak.
- Each new system is introduced by the Wanderer who runs it, in two or three lines, at the moment it unlocks.

### Accessibility

- Dynamic Type in all SwiftUI screens; VoiceOver labels on every control and item.
- Elite affixes and elements use icon + shape + color, never color alone; colorblind palettes for telegraphs.
- Toggles: reduce flashing, screen shake off, damage numbers off/compact, larger telegraphs, haptics level.
- Left-handed layout mirrors the bottom bar.

### UI skin

The UI has two layers. **In-world UI** (Rift HUD, Hearth building screens, item cards, tooltips, the Bestiary) wears a Kenney pixel skin so it belongs to the game. **System UI** (Settings, purchase, bug report, Game Center, iCloud) stays native SwiftUI with SF Symbols and the system font, framed in the same pixel panels, because those screens must be fully accessible and look trustworthy.

| Use | Kenney pack (All-in-1) | Notes |
| --- | --- | --- |
| Panels, buttons, bars, sliders | UI Pack - Pixel Adventure, if it is the pixel fantasy set; otherwise UI Pixel Pack | 9-slice panels drawn at the same 2 points per art pixel as the world |
| Wanderer speech bubbles, Hearth reactions | Emote Pack (16 pixel-style sheets) | A Wanderer reacts with an emote to a new Unique or Depth record |
| Titles, HUD numbers, item names | A pixel font from the Kenney Fonts pack | Only at whole-number scales; never for body text |
| Body text, tooltips, Settings | System font (SF Pro Rounded) | Scales with Dynamic Type |
| Pointer on iPad and Mac | Cursor Pixel Pack | Post-launch nicety |
| Controller prompts | Input Prompts Pixel | Only if controller support is added later |
| Not used in the game | UI Adventure Pack, UI Pack - Adventure, UI Pack, Game Icons | Smooth vector styles that clash with 16×16 art |

SwiftUI draws Kenney panels as resizable images with cap insets and nearest-neighbor interpolation (`.interpolation(.none)`), so borders stay crisp. The local agent opens the UI Pack - Pixel Adventure and Fonts folders first; the bundle index lists their names but not their files.

## Settings and quality of life

Every common toggle a player expects is here, and defaults favor calm play: sound on but polite, motion and flashing reduced only when the system asks for it. Device preferences (audio, display, haptics, notifications) are stored per device; gameplay preferences (loot rules, auto-equip, Tactics) live in the save and sync with iCloud.

### Settings

Reached from the gear on the Hearth and from the Rift pause menu (the pause menu shows only Audio and Display).

| Group | Setting | Default | Notes |
| --- | --- | --- | --- |
| Audio | Master volume | 80% |  |
| Audio | Music on/off + volume | On, 70% |  |
| Audio | Ambience on/off + volume | On, 70% |  |
| Audio | Sound effects on/off + volume | On, 80% |  |
| Audio | UI sounds on/off | On |  |
| Audio | Play music over my audio | Off | When off, game music stays silent while the player's own music or podcast plays; SFX still play |
| Audio | Haptics | Light | Off / Light / Full |
| Gameplay | Default Rift speed | 1× | Last choice is remembered |
| Gameplay | Auto-equip clear upgrades | Off | Equips only when both damage and toughness improve; never touches locked items or saved loadouts |
| Gameplay | Confirm before salvaging Uniques and Heirlooms | On |  |
| Gameplay | Pause on Guardian spawn | Off | For players who like to tap Relics in boss fights |
| Gameplay | Damage numbers | Auto | Auto (off above Depth 50) / On / Compact / Off |
| Gameplay | Show Lantern as a percentage | Off | The moth's glow stays either way |
| Display | Reduce flashing | Follows system |  |
| Display | Screen shake | Off |  |
| Display | Larger telegraphs | Off |  |
| Display | Colorblind palette | Off | Protanopia, deuteranopia, tritanopia |
| Display | Left-handed layout | Off | Mirrors the bottom bar |
| Display | Text size | Follows system | Dynamic Type for body text; pixel font steps 1× / 2× |
| Battery | Frame rate | Auto | Auto (30 fps in Low Power Mode) / 30 / 60 / 120 |
| Battery | Lantern Mode after inactivity | 2 min | Dims the screen during Auto-Delve after no touches |
| Battery | Keep screen awake during Auto-Delve | Only while charging |  |
| Notifications | Expedition cap reached | Off (asked once, after the first Expedition) | All opt-in, all respect Focus |
| Notifications | Companion back (post-launch) | Off |  |
| Data | iCloud sync | On |  |
| Data | Export / import save |  | Share sheet with a JSON file |
| Data | Restore purchase |  |  |
| Data | Analytics and crash reports | On | Off stops collection immediately |
| Data | Send a bug report |  | Attaches breadcrumbs and the save |
| Data | Reset progress |  | Two confirmations, then type RESET |
| About | Credits and licenses, privacy policy, version |  | Kenney, music and ambience packs, Sonniss |

Every change logs a `settings_change` event (setting, new value) so defaults can be tuned from real use.

### Quality of life

- **Loot:** lock or favorite an item so it can never be salvaged; "New" badges; sort and filter in the bag, search in the stash; a salvage preview before bulk salvage; undo the last salvage until leaving the screen; an Equip Best button per saved loadout that shows the change before applying.
- **Rift flow:** result screen buttons for Retry this Depth and Push next Depth; Repeat last Delve from the Hearth; Auto-Delve stop conditions (after N runs, when the bag is full, after a Unique drops); skip the result animation by tapping.
- **Build testing:** a Training Yard at the Trophy Hall with a target dummy that reports damage per second over 30 seconds, so a loadout or Tactics change can be checked without a Rift.
- **Tactics:** starter templates, copy rules between saved loadouts, and a line under each rule showing how often it fired in the last Rift.
- **Information:** long-press any stat, affix, or keyword for a plain explanation; Codex search; damage and toughness change shown after every equip.
- **Hearth:** badges on buildings when something is ready (an affordable upgrade, a Wanderer gift, a finished Expedition) and a Collect All button on return.
- **Interruptions:** auto-pause on a phone call or app switch, resume exactly where the player left off, and pick up the same session on another device through iCloud.
- **Onboarding:** tutorials can be replayed from the Codex and are skipped automatically when restoring an iCloud save.
- **Touch:** every control at least 44 points, all primary actions in the bottom third of the screen, nothing that needs a second hand.

## Art and audio direction

Warm pixel art in a top-down three-quarter view, readable at phone size first and pretty second. Every enemy, telegraph, and drop must be identifiable in under half a second on an iPhone mini-sized screen.

### Visual style

- **16×16 pixel tiles and characters**, drawn at 2 points per art pixel (6 device pixels on 3× iPhones, 4 on 2× iPads) with nearest-neighbor filtering. A phone shows about 12 tiles across in portrait. Guardians and Wardens can be 32×32 (2×2 tiles).
- **Base art is Kenney's CC0 packs** (see Art sources below); commissioned art fills only the gaps and matches Kenney's style.
- Palette: a master palette built from the Kenney packs' own colors plus warm ambers and greens for the Hearth. Each biome gets a 12-color sub-palette applied by offline recolor; Echo variants shift darker and cooler with a palette-swap shader.
- **Animation is procedural by default**, because Kenney sprites are single frames: idle bob, walk bounce and flip, wind-up lean, attack lunge with a weapon arc, white hit flash with knockback, death squash and fade. Hand-drawn frames are optional per creature and reserved for Guardians.
- Light is the motif: lanterns, glowing fungi, forge fire, starlight. Darkness at the screen edges shrinks as the Lantern burns down.
- Enemies are creepy-cute with strong silhouettes; elites get an affix-colored outline plus floating affix icons.
- Hero appearance comes from equipped armor and weapons (modular paper-doll layers from Kenney's Roguelike Characters), so a new drop is visible on the character.

### Readability rules

- Telegraphs are filled ground shapes with a bright edge, drawn above floor decals and below characters.
- Hero projectiles are lighter and more saturated than enemy ones.
- Damage numbers are small and off by default above Depth 50, where they turn into noise.

### Art sources (Kenney CC0)

Kenney's packs are public domain (CC0): free for commercial use, no credit required (credit in About anyway). Together they cover the world, the hero, the Hearth, items, and UI; the real gaps are creatures, Guardians, Relic and Charm icons, and the moth.

| Asset | Launch need | Kenney source (All-in-1 pack name) | Commission (gaps) |
| --- | --- | --- | --- |
| Dungeon tilesets | 5 biomes | [Tiny Dungeon](https://opengameart.org/content/tiny-dungeon) (dirt and sand floors, brick walls, doors, stairway arch, pit, fountains, chests) and Roguelike Dungeon Pack (rock walls, ores, skulls), recolored per biome | Biome props (fungi, drowned books, forges, starfields) and water tiles |
| Room templates | 20 per biome | Assembled in Tiled from the tilesets above | None |
| Hero paper-doll | Body, 4 armor layers, weapon layer | [Roguelike Characters Pack](https://opengameart.org/node/44629): bases, clothing, armor, headgear, hair, weapons, shields | Crossbow, Sling, Scythe (Bow is in Tiny Town) |
| Mob families | 15 families, about 60 creatures | Tiny Dungeon: 8 creatures (slime, cyclops, horned crab-demon, bat, ghost, spider, two rats) plus a mimic chest for the Glimmerkin | About 50 creatures |
| Guardians + Wardens | 15 + 2 | None | All, at 32×32 |
| Hearth buildings | 12 buildings × 5 tiers | [Tiny Town](https://opengameart.org/content/tiny-town) (roofs, wood and stone walls, doors, windows, fences, trees, castle pieces, the well that becomes the Rift entrance, beehive, archery target, cauldron) and Roguelike Base Pack / Roguelike Interior Pack (furniture, banners) | Lighthouse if castle pieces can't compose it |
| Wanderers | 12 | Tiny Dungeon's 12 human characters, one per Wanderer | None |
| Light and the Lantern | Hero light radius, lit props, dusk | Light Masks (152 masks: circles, streaks, noise) for light radii and darkness | Lantern, campfire, and candle sprites (not in Tiny Dungeon or Tiny Town; check Tiny Farm and the 1-Bit Pack first) |
| Items and loot icons | Weapons, armor, potions, chests | Tiny Dungeon weapons, shields, potions, vials; Tiny Town bow, tools, coin, key | 30 Relic, 24 Charm, armor-slot, and material icons |
| UI | Panels, buttons, bars, cursors | UI Pack - Pixel Adventure or UI Pixel Pack (see UI skin), Emote Pack, a Kenney pixel font | None |
| Bestiary cards | Frame, foil, 5 backgrounds, 3 backs | UI Pixel Pack panels as the frame; creature sprite on top | Foil overlay, card backs |
| Telegraphs and VFX | Shared kit | Tiny Dungeon hazard stripes and dashed marker as optional overlays | Drawn in code from the palette: filled shapes, 1-pixel particles |

- **Two Kenney styles.** The Tiny series (Dungeon, Town, Farm, Battle) is chunkier; the Roguelike series (Characters, Base, Dungeon, Interior, UI Pixel) is finer. Put both side by side on a phone in M0. If they clash, the Roguelike series becomes the base and Tiny Dungeon only supplies recolored creatures.
- **Exact sprite indices** are recorded per contract id in `docs/art/kenney-map.json` by the local agent against the All-in-1 bundle; gameplay code never references a pack file name. The build plan carries the first-pass index notes for Tiny Dungeon and Tiny Town.
- **Commission brief:** 16×16, the master palette, Kenney's outline and shading rules, single-frame sprites that animate procedurally. Roughly 50 creatures, 17 bosses, about 70 icons, 3 weapon types, the lantern and campfire set, biome props, water tiles, and the moth.

### Audio

The sound should feel like a warm room with a dungeon underneath: acoustic and soft at the Hearth, quiet and atmospheric below, with loot as the one loud moment. Kenney's packs (already owned in the All-in-1 bundle) cover UI, hits, and foley; two inexpensive music and ambience packs plus a free sound-effects library fill the rest.

#### Direction

- Hearth: acoustic guitar, fiddle, soft woodwinds; a fire-crackle bed that changes with time of day; rain as an optional weather layer.
- Biomes: ambient, low-melody tracks, one per biome, plus a Guardian track.
- Loot sounds rise in pitch with rarity; a Unique gets a short sting, the loudest sound in the game.
- Lantern low: a gentle fading hum instead of a ticking clock.
- Haptics: light tap on pickups, medium on Unique drops, none on regular hits.

#### Sources

| Need | Source | License | Use for |
| --- | --- | --- | --- |
| UI | Kenney Interface Sounds (100: click, select, confirmation, open, close, toggle, scroll, error) | CC0 | Every menu and button; skip Kenney UI Audio to keep one UI voice |
| Combat hits and footsteps | Kenney Impact Sounds (130: metal, wood, punch, soft, plate, glass, mining, footsteps on five surfaces) | CC0 | Weapon hits by type, mob hits, Guardian slams, footsteps per biome |
| Foley | Kenney RPG Audio (51: book flips, cloth, creaks, doors, knife draw and slice, coins, leather, latches, metal pots) | CC0 | Codex and Library pages, gold, equipping, chests, doors, Blacksmith and Apothecary |
| Jingles | Kenney Music Jingles (85 in five styles); use the Pizzicato set | CC0 | Rift clear, level up, Depth record, achievement, card drop |
| Music, Hearth | [Cozy Casual Bundle Vol. 1](https://iamlufus.itch.io/cozy-casual-bundle-vol-1-game-music-pack-relaxing-jazz-acoustic-social) (23 loopable tracks, $29.97) | Royalty-free | Hearth day and night themes, menus |
| Music, biomes | [RPG Music Pack: Dungeon Themes](https://owl-theory-music.itch.io/rpg-music-pack-dungeon-themes) (10 looping tracks with variations, $12.99) | Royalty-free | One track per biome, Guardian and Warden tracks, spares for Echoes |
| Ambience | [Fantasy Ambiences](https://cyberleaf.itch.io/fantasy-ambiences) (17 loops, about 53 min, $9) | Royalty-free (license in package) | Cave, Dungeon, Mines, Temple, Astral Plane, Forest, Village, plus Campfire and Rain layers |
| Spells and Relics | Sonniss GDC game-audio bundles (free; the 2026 bundle is 7.47 GB) | Royalty-free, no attribution; can't redistribute standalone | Fire, frost, nature, radiant, and shadow casts; shields; summons |
| Backups | Kenney Music Loops (29; mostly comedic, audition "Infinite Descent", "Sad Town", "Retro Mystic"); Freesound filtered to CC0 | CC0 | Placeholders and one-off gaps |

License rules: CC0 or royalty-free only, never CC-BY-NC; each pack's license file is kept in `Audio/licenses/`; read each paid pack's license text before shipping, since the store pages are not the license. Kenney's Retro Sounds stay out by default: chiptune bleeps fight the acoustic score.

#### Biome sound map

| Place | Music | Ambience bed | Footsteps |
| --- | --- | --- | --- |
| Hearth | Cozy pack, day and night themes | Village + Campfire (+ Rain) | Grass, wood |
| Mossy Cellars | Dungeon Themes track 1 | Cave | Concrete |
| Fungal Hollows | Dungeon Themes track 2 | Forest (creepy) | Grass |
| Drowned Library | Dungeon Themes track 3 | Temple (quiet) | Wood |
| Ember Forges | Dungeon Themes track 4 | Mines + Hellish Dungeon | Concrete |
| Starless Vault | Dungeon Themes track 5 | Astral Plane | Concrete |
| Echo variants | Same track, an alternate variation from the pack | Same bed, pitched down a semitone | Same |

Track numbers are slots to fill after auditioning, not the pack's order.

#### Cue list

| Group | Cues |
| --- | --- |
| UI | Tap, open, close, confirm, error, tab switch, slider tick |
| Combat | Hit per weapon type (9), ranged release, hero hurt, mob death, elite death, telegraph wind-up, Guardian slam, Guardian death |
| Relics | Cast per element (Fire, Frost, Nature, Radiant, Shadow, untyped), shield up, summon, heal |
| Loot | Pickup (pitched Common / Rare / Unique), Unique sting, Heirloom shimmer, card flip, gold |
| Progress | Level up, Depth record, Rift clear, achievement, Charm rank-up |
| Lantern | Low hum (fades in under 25%), Lantern out, Lantern Shrine refill |
| Hearth | Building upgrade, Wanderer arrives, Blacksmith anvil, re-roll, salvage, Expedition sent, Expedition return |

#### Audio tech

- **Audio session:** `.ambient` by default, so Hearthdelve mixes with the player's own music or podcasts and respects the silent switch, which suits an idle game. When other audio is already playing, the game's music stays silent while SFX play.
- **Engine:** `AVAudioEngine` with four mixer buses (music, ambience, SFX, UI), each with a Settings slider. A new **HearthAudio** package subscribes to the same `GameEvent` stream as telemetry, so the sim never calls audio.
- **Voice limits:** at most 12 simultaneous SFX with priority (UI > loot > Relics > hits); an identical cue plays at most once per 50 ms. At 2×/4× speed, hit sounds thin out; in Lantern Mode only loot stings play.
- **Music:** 2-second crossfades between Hearth and biome tracks, a cut to the Guardian track at spawn, and always back to the Hearth theme on return.
- **Files:** short SFX as CAF, music and ambience as AAC (.m4a, about 160 kbps), all converted at build time from the source OGG and WAV; loudness normalized (music around −16 LUFS). Audio budget: about 40 MB of the 300 MB install.
- **Haptics:** Core Haptics patterns for pickups and Uniques, following the system haptics setting and the in-game haptics level.

## Monetization

Recommendation: **free to download, one-time unlock** for the full game, the model [Melvor Idle](https://apps.apple.com/app/id1518963622) uses with its $9.99 Premium Edition. A free start beats a paywall for discovery on the App Store, and a single unlock keeps the promise that nothing is ever for sale except the game itself.

### Options considered

| Model | Price | For | Against |
| --- | --- | --- | --- |
| Free + one-time unlock (recommended) | Free through Depth 25 (the first two biomes and the start of the third); $7.99 unlock | Discoverable; players try before buying; clean promise | Needs a strong first hour to convert |
| Premium upfront | $5.99–$7.99 | Simplest; clear fairness signal | Fewer downloads; no trial |
| Apple Arcade | Paid by Apple | Funding plus featuring; no monetization design at all | Must be pitched and accepted; exclusivity terms |

### After launch

- **Expansions** ($2.99–$4.99): a new biome pair, mob families, Guardians, Uniques, and a Wanderer. Depth stays one ladder; expansion biomes join the rotation only from a stated Depth band upward, so no Depth below it changes biome.
- **Supporter pack** (optional): Hearth decor and hero cosmetics only.

### Never

Ads, energy or keys, loot boxes, premium currencies, timers you can pay to skip, or anything that adds Power.

## Roadmap

Build in four milestones, each closed by a gate that must pass before the next starts. The first gate is the riskiest question in the whole design: is auto-combat fun to watch? Everything else is content.

&#91;embedded content: roadmap · 4 milestones, 4 gates\]

No dates are set yet; each milestone gets a time box once M0 shows how fast content can be made.

Text version, for exports that drop the diagram:

1. **M0, One room:** hand-built room, Sword + Bow, 2 Relics, 3 Tactics, 3 mob types, telegraphs, seed replay. Gate: auto-combat is fun to watch for 5 minutes on a real iPhone.
2. **M1, One Rift:** Mossy Cellars generation, Lantern, Guardian, loot, loadout, local save, Gate screen, soft death. Gate: a coffee-break Rift plays end to end and replays from its seed.
3. **M2, Hearth and idle:** Hearth scene and core buildings, Expeditions, Paragon, Tactics editor, onboarding, Mossy + Fungal content. Gate: check-in, coffee-break, and evening sessions all work.
4. **M3, Launch content:** all 5 biomes and the full loot catalog, Bestiary cards, iCloud, Game Center, telemetry, StoreKit unlock, audio, accessibility. Gate: balance, performance, and crash-free targets met.
5. **M4, after launch:** the list below.

### After launch (M4)

- Glyphs (the build stays complete without them)
- Echo Seasons
- Companion side Expeditions
- Wanderer friendship threads beyond the first step
- Advanced Tactics conditions (AND/OR, hold-until)
- Expansions and supporter pack
- Inn card game (Bestiary cards themselves ship at launch)

## Decisions

All ten open questions were settled on Oct 27, 2026: the spec's defaults stand, with Seasons and iPad landscape scheduled for after launch.

| Question | Decision |
| --- | --- |
| Title | Keep Hearthdelve as the working title |
| Origins (starting class pick) | None: fully classless |
| Fourth rarity | No: three tiers (Common, Rare, Unique) |
| Lantern soft timer | Keep it in Deep Rifts |
| Glyphs | Post-MVP |
| Manual control | Pure auto + Tactics; no virtual stick |
| Business model | Free + one-time unlock |
| Art source | 16×16 Kenney CC0 packs as the base art from M0; commission only the gaps (creatures, bosses, icons, moth) in Kenney's style |
| Seasons | Build Echo Seasons after launch |
| iPad landscape | Portrait at launch; landscape layout in a later version |
| Localization | English at launch; every string in a String Catalog so more languages can follow |

## Sources

- [Minecraft Dungeons II beginner's guide (MetaBot)](https://metabot.gg/en/minecraft-dungeons-2/guides/beginners-guide)
- [Soda Dungeon 2 review (MobileSyrup)](https://mobilesyrup.com/2020/07/05/soda-dunegon-2-review/)
- [Nonstop Knight 2 review (Pocket Gamer)](https://www.pocketgamer.com/articles/080496/nonstop-knight-2-review/)
- [Eternium (TouchArcade)](https://toucharcade.com/games/eternium)
- [Diablo Immortal review (Engadget)](https://www.engadget.com/diablo-immortal-review-120001807.html)
- [Melvor Idle (App Store)](https://apps.apple.com/app/id1518963622)
- [Vampire Survivors mobile launch (PocketGamer.biz)](https://www.pocketgamer.biz/news/80396/vampire-survivors-surprise-launches-to-mobile/)
- [Archero deconstruction (Deconstructor of Fun)](https://www.deconstructoroffun.com/blog/2019/8/9/why-archero-banked-25m-but-leaves-25m-hanging-hlx9n)
- [IdleOn overview (GSMGoTech)](https://www.gsmgotech.com/2025/12/the-idle-mmo-phenomenon-how-legends-of.html?m=1)
- [SpriteKit continued support thread (Apple Developer Forums)](https://developer.apple.com/forums/thread/830810)
- [Customize Crashlytics crash reports for Apple platforms (Firebase)](https://firebase.google.com/docs/crashlytics/ios/customize-crash-reports)
- [Game Center achievements reference (App Store Connect Help)](https://developer.apple.com/help/app-store-connect/reference/achievements)
- [Free sound effects and music for games (Cinevva guide, 2026)](https://app.cinevva.com/guides/free-sound-effects-music)
- [Sonniss GDC 2026 game audio bundle (rekkerd.org)](https://rekkerd.org/sonniss-releases-gdc-2026-game-audio-bundle/)
- [Cozy Casual Bundle Vol. 1 (itch.io)](https://iamlufus.itch.io/cozy-casual-bundle-vol-1-game-music-pack-relaxing-jazz-acoustic-social)
- [RPG Music Pack: Dungeon Themes (itch.io)](https://owl-theory-music.itch.io/rpg-music-pack-dungeon-themes)
- [Fantasy Ambiences (itch.io)](https://cyberleaf.itch.io/fantasy-ambiences)
- [Kenney Interface Sounds (OpenGameArt)](https://opengameart.org/content/interface-sounds)
- [Kenney RPG sound effects (OpenGameArt)](https://opengameart.org/content/50-rpg-sound-effects)
