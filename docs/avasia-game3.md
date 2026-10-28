# Hearthdelve as Avasia Game 3

Drafted 2026-10-28. A proposal, not canon. Nothing here is canon until it lands in the decision log in Avasia-iOS `docs/SAGA.md` §7.

Canon sources read for this draft, all in Avasia-iOS: `docs/SAGA.md` (§0 pillars, §3, §8), `docs/sequel/GAME3_OPENING.md`, `docs/LORE_ARCHIVE.md` §1.4, `docs/fiction/commodity/` (III-M01 to III-M09), and `docs/fiction/ASH_VAULT/` (AV-01 to AV-03). The AshVault repo's `ios/docs/avasia-integration-spec.md` covers the prison history.

## The pitch

**Avasia: Hearthdelve** is the first 2D Avasia game and opens the Commodity Era. Anula is money and magic, and the deepest uncharted vein on the continent runs under a mountain the crown sealed seventy years before King of Nacastrum. A handful of people who walked out of Splitpath Station's company house light a campfire above it. One of them goes down.

Each Rift brings back crystal. You spend it on two things: arming the hero or building the village. Depth never caps, because the vein never ends and the echo at the bottom keeps getting louder.

The saga asks Era 3 one question: *Who can afford to spend it?* Hearthdelve doesn't answer it with a sermon. It answers it with the player's ledger.

## Why it fits

| SAGA requirement | Hearthdelve today |
| --- | --- |
| First 2D game (§1, §3) | SpriteKit, Kenney 16×16 tiles, a village you can pan, rendered fights |
| Post-Age era, new generation (§3, §5) | New hero, no Age-era cast on screen |
| Fiction explains the format leap: the continent is "charted, priced, networked" (§8.6) | Map Room, Expeditions to named places, a relay tower on the skyline (see Wanderers) |
| Primary spine is the Anula economy (§8.6) | The loot economy *is* the game. Swap gold for Anula and the spine is in place |
| Social commentary from playable tradeoffs, not narrator sermons (§0) | Every Anula is a choice: Raise the sword, or build the Apothecary |
| Survivor's legend: the Messenger is myth, never a villain (§0) | The Messenger shows up only on broadsheets and cards. Never a boss |
| Horror comes from the system (§8.8) | Endless extraction under a sealed prison. The player is part of the system |

Hearthdelve also answers several open questions in SAGA §8.9:

- **Wallet and spell fuel: one meter or two?** One. Anula pays for gear, buildings, and ward-fuel.
- **Mining geography.** The NW mountain, north of Splitpath Station on the mine road (III-M01, III-M04).
- **The commodity primer.** The first Delve *is* the primer. You come home with shards, then decide what to spend them on.

## Where and when

**When.** The Commodity Era, after Blade of Courage. Kaefden IV's face is on the stamped shard (III-M08). Whether he is still alive stays open, as SAGA leaves it.

**Where.** The NW mountain, west of KoN's Splitpath. That's the same mountain as KoN's pink cave (LORE_ARCHIVE §1.4), the Jal chain-mine (W-07), and the Kaefden penitentiary that became the Ash Vault (AV-01). Splitpath Station is the nearest town: a rail-head where Ring Road freight meets the crystal line (GAME3_OPENING). The mine road leaves it heading north. The Hearth sits at the end of that road.

**The Hearth.** The spec already says the village grows "from a campfire and two tents." In Avasia terms, those tents belong to people who refused company scrip. Diaspora from Cataracta, a Warden off rotation, a clerk who kept the wrong ledger. They aren't saints. Like everyone else on the mountain, they live off what comes out of the ground (see the Writing rules section).

**The Rift.** An uncharted Anula vein under the old penitentiary. Anula forms slowly in living stone (SAGA §8.10), so the deeper you go, the older and purer the crystal. That's the in-world reason for no ceiling: **Depth is grade.** Item level follows Depth, so better crystal makes better gear.

**The Sinter.** AV-01 ends with Delver Seven cutting the Heart: "sudden, guilty, incomplete." *Incomplete* is the hook. What was left of the Sinter's binding has seeped into the vein for generations. That's why the deep stone echoes, and why Echo variants start at Depth 51. Nobody in the Hearth knows the name. The Codex finds it.

## Anchor law in the systems

SAGA §0 says every game is a new container for the same law. The game shouldn't explain anchor law in a tutorial. Give each progression layer one anchor, and the player learns all four just by playing.

| Anchor | Hearthdelve layer | Why |
| --- | --- | --- |
| **Earth** | Anula: the currency, Relic fuel, the Lantern | Anula is the earth-anchor commodity. Relics run on its stored charge. The Lantern is a ward that burns it |
| **Sky** | Glyphs and the Glyphwright | Learned marks, kept forever, refundable. Tower knowledge from returning mages, no longer floating |
| **Flesh** | The Reliquary and the deep echo | Recording a Unique's signature binds its echo to the hero. The deep stone is full of the Sinter's echo |
| **Civic** | Hearth buildings, Wanderer threads, Trophy Hall | Oaths, memorials, a shared village. The commons the Hearth chooses to be |

Changes this implies:

- **Souls → Charge.** Relics spend Charge gathered from crystal-laced enemies. "Souls" means something else in Avasia, and it would read as flesh magic in every fight.
- **Reliquary slots carry an echo.** The spec's three slots are the licensed amount. A post-launch Red Litany choice (a fourth slot, with a real cost) is the cult's offer made playable. See The three blades section.
- **Damage elements stay as they are.** Fire, Frost, Nature, Radiant and Shadow describe what a hit does. Anchors describe what binds the power. Don't merge the two systems; just tag Relics with their anchor.

## Currency and the dual spend

| Today | Proposed | Notes |
| --- | --- | --- |
| Gold | **Anula**, counted in graded shards | Kaefden IV on the face. The UI may say "shards" |
| Dust (Common salvage) | **Dust** | Ungraded Anula dust, the same stuff Tavi sells (III-M02). The name already fits |
| Shards (Rare salvage) | **Facets** (working) | Renamed so "shards" can mean money |
| Embers (Unique salvage) | **Echoes** (working) | Comes with the Codex signature. The echo is what the Reliquary binds |

The dual spend (SAGA §8.10: "you are not choosing spells; you are choosing what not to buy") plays out as **Raise the gear or build the Hearth**. Both cost Anula. The Chandlery's ward-fuel upgrades are a third sink, and they really are magic paid for with money.

**One hard rule.** The dual spend applies to *choices*, never to *entry*. A Rift never costs Anula to start, and no timer charges rent. GAME3_OPENING's "rent due in three days" stays backstory (see Tensions below). Hearthdelve's pillar "no energy, no guilt timers" wins this one.

## Biomes as history

The launch biomes already line up with the mountain's past. Keep the names. Change the Codex and the flavor.

| Depth band | Biome | What it was |
| --- | --- | --- |
| 1–10 | Mossy Cellars | The upper mine. Jal-era chain-mine galleries (W-07). Rubble Folk are old cave-ins with opinions |
| 11–20 | Fungal Hollows | Living stone where the vein starts to glow. Sylvian elders called this kind of ground sacred |
| 21–30 | Drowned Library | The penitentiary archive, flooded after the seal. Bera's COPY (AV-02) came out of here. Page Ghosts are redacted maps |
| 31–40 | Ember Forges | Malvek's forge rings. His sermons are carved into the slag (MALVEK_SERMONS) |
| 41–50 | Starless Vault | Below the old Vault Heart. No surveyor charted it. Clockwork Watch are penal turnkey mechanisms still running |
| 51+ | Echo variants | The same stone, now loud. Darker palette, one extra affix, the Sinter's leftover binding |

A content update that adds a biome adds a new stretch of vein (the spec's versioned biome table already supports this). Western pits under treaty labor and the Sylvian border are the obvious next two.

## The three blades

SAGA §0 lists three horrors for Game 3. Each needs a place to live where it doesn't fight Hearthdelve's tone.

| Blade | Where it shows up | How loud |
| --- | --- | --- |
| **Anula economy**: "You can't afford to be safe." | The village ledger, the market board news on the relay tower, Wanderer lines about Splitpath | Ambient, every session |
| **Flesh garrisons**: "We keep you safe but never say what it costs us." | A licensed Warden living in the Hearth (see Wanderers), the Reliquary | One friendship thread, one system |
| **Red Litany**: "Safety is a lie. Bleed and be free." | Deep Rift events and elite affixes past Depth 50; a Pit Chapel event; the optional fourth Reliquary slot | Rare, late, psychological first |

SAGA's writing rules apply directly:

- Licensed Wardens are not cultists.
- Cult horror is psychological first.
- Deep vessels are not redeemed.

On a 16×16 Kenney sprite, "psychological first" is the only option anyway. Chanting in the audio, echolalia in Codex text, and a moth that won't fly toward a certain door.

## Wanderers

There are twelve Wanderers, one per building. Most already fit Avasia. Each mapping below is a suggestion, and their existing intro lines stay.

| Wanderer | Building | Avasia identity |
| --- | --- | --- |
| Old Hob | Blacksmith | Ex-company smith who quit grading shards for the assayer |
| Tansy | Apothecary | Cataracta diaspora druid. Heals cost crystal, and she hates that they do |
| Quill | Library | An archivist from Thekia's search archive (III-M09). Tactics are "rules written down so heroes don't forget mid-swing" |
| Mara | Map Room | A crystal-line surveyor. The Map Room is where the continent becomes legible (SAGA §8.6). Expeditions go to named places on the Ring Roads |
| Pell | Stash House | **Make the name collision intentional.** A descendant of Commander Pell, who wrote "Delver 7, ring ten breached" in the ledger (AV-01). The family still counts twice |
| Lark | Inn | Sings broadsheet ballads about the Messenger, mostly wrong (III-M05). The Inn card game decks include broadsheet cards |
| Wick | Chandlery | Sells ward-fuel. Says out loud that light costs money |
| Ossa | Reliquary | Used to sell Messenger "relics" at Splitpath. Now keeps real echoes and is frightened of them |
| Fern | Garden | Sylvian. Gives things away on purpose. The gift economy, kept alive in one garden bed |
| Gorran | Trophy Hall | Agromanian veteran from the western pits (III-M08's veteran voice). Remembers when Many Hands meant something |
| Bea | Lighthouse → **Relay Tower** | Runs a pirate crystal-line relay. Her tower shows your best Depth on the skyline and brings in the broadsheets |
| Ivo | Glyphwright | A mage back from Nacastrum. "The marks on the walls aren't decoration" is about sky-anchor runes |

**Add Hale.** Warden Hale from III-M03 ends a rotation and can't stop hearing the chant. Hale comes to the Hearth for quiet. Hale could be a thirteenth Wanderer, or take over a role that fits (Trophy Hall works). Hale's three-step thread is the flesh-garrison blade, told kindly.

## Milestone wardens: a naming collision

Hearthdelve calls its every-50-Depth bosses **Wardens** (Keeper of the Well at 50, The Lampless One at 100). In the Commodity Era, "Warden" means a licensed Flesh-Warden, and canon says those are sympathetic.

Recommendation: keep the word and pin its meaning to **the old penitentiary's wardens**. AshVault's roster already did this: Turnkey Hess, Pink Bloom, the Echo Sergeant, Malvek's Shade, the Sinter. They're dead men bound into the stone. They aren't Commodity Era Wardens, and the Codex says so in one line. The Keeper of the Well and the Lampless One already fit, as a turnkey and as a ward-lighter. Past Depth 100, the AshVault roster supplies the next milestones, and the Sinter's residue is the long tail.

If that's still confusing in playtests, rename the tier **Vessels**, after SAGA's "deep vessels."

## Survivor's legend and the crown

- **The Messenger** (the SoC protagonist) appears on broadsheets at the Relay Tower, in Lark's songs, and on Bestiary-style cards. Never as a fight. A late, optional cameo as a tired person passing through, who won't be a saint, matches III-M05. Decide this later.
- **Kaefden IV** is on the shard. That's all.
- **Vashirr** isn't in the game. The Red Litany quotes him wrongly, and Gorran says so.

## The first ten minutes

GAME3_OPENING wants three facts taught through play. Hearthdelve's existing demo loop teaches all three without a rent timer:

1. **Anula is money.** The first Delve comes home with shards. Old Hob raises your sword with them.
2. **Anula is magic.** The Lantern burns as you descend, and its fuel is crystal charge. The first Relic spends Charge. A single line from Wick: "Light costs money."
3. **Flesh echoes exist.** On the walk home, a chant comes up through the well. Later, the Library's first Codex entry is a page from Pell's ancestor's ledger.

The opening card replaces III-M01's rent scene with its aftermath: *You walked out of Splitpath Station with what you carried. The mine road ends at a cold fire. Something under it is worth more than rent.*

## Where Hearthdelve and the bible disagree

| Tension | Bible says | Hearthdelve says | Proposed call |
| --- | --- | --- | --- |
| Tone | Body horror, bitter realism | Creepy-cute, no gore | Cozy above, wrong below, unjust offscreen. Horror stays in text and sound. Deep bands get darker, not bloodier |
| Pressure | Rent due in three days | No guilt timers | Rent is backstory. The pressure is the dual spend, never a clock |
| Format | "Exploration, movement, and combat on a visual plane" (§3) | Auto-battle, one-handed | Amend §3 to "rendered towns and fights; the continent charted as nodes." The Map Room carries the "legible" promise |
| Protagonist | Dock clerk or mine courier | A delver | The hero *was* a Splitpath courier. III-M01 becomes the hero's last day there |
| "Warden" | Licensed, sympathetic | Boss tier | Old penitentiary wardens (see above) |
| Story density | Nine Commodity stories, a mother-search thread | Three-step Wanderer threads, a Codex | The prose stays in the anthology. The Library unlocks III-M story entries as Codex pages. The game stays light on text |

Hearthdelve's monetization (premium, power never for sale) is one place where Hearthdelve and the bible fully agree. A game about who can afford magic that refuses to sell power is a store-page line, not a contradiction.

## Links to the other apps

Keep them light and one way. Never "play X to progress in Y."

- A small shared `AvasiaLedger` (App Group on team `7JT2JB89AV`, or iCloud key-value) stores cross-game flags.
- Finishing KoN or SoC in Avasia-iOS gives one Wanderer an extra line and unlocks one decor piece in Hearthdelve.
- Reaching certain Depths in Hearthdelve unlocks the matching AV and III-M stories in the Avasia-iOS anthology.
- Echo Seasons (post-launch) can bring back EchoShafts' Flesh-Warden as a seasonal hero with a flesh-anchor rule.

## If this is a yes

**Avasia-iOS**

- Add a decision-log entry to SAGA §7 (draft below).
- Update §3 and §5: Game 3 is *Avasia: Hearthdelve*, and the format line becomes the amended one from the Tensions table.
- Add a note at the top of GAME3_OPENING.md: Splitpath Station is the hero's backstory and the nearest town; the playable opening is the Hearth.
- Mark the §8.9 questions this doc answers.

Draft §7 line:

> | 2026-10-xx | **Game 3 = *Avasia: Hearthdelve*.** First 2D game; Commodity Era; NW mountain above the sealed Ash Vault. Anula is one meter (currency + fuel). The Rift is an uncharted vein; Depth is grade. See Hearthdelve `docs/avasia-game3.md` |

**Hearthdelve** (after the demo-on-device gate, not before)

- Add a Setting section to the design spec pointing here.
- Content renames: gold → Anula, Shards → Facets, Embers → Echoes, Souls → Charge, Lighthouse → Relay Tower. Most of the work is display strings. Save keys can wait for a migration.
- Rewrite the Codex and Wanderer flavor lines to match the Biomes and Wanderers tables.
- Add anchor tags to Relics in `Content/`.

## Open questions

1. Is the Sinter's leftover binding the long-tail villain, or should the deep echo stay nameless?
2. Should the Hearth stay an honest commons, or should a charter company eventually notice its output and send an assayer up the mine road? That would be a natural first expansion.
3. Hale: a thirteenth Wanderer, or a replacement for an existing one?
4. Should the Messenger cameo happen at all?
5. Is "Avasia: Hearthdelve" the store name, or does Avasia stay in the subtitle?
