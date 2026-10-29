# Hearthdelve as Avasia Game 3

Complete 2026-10-28. Every call in this doc is made. It is saga canon via the 2026-10-28 line in Avasia-iOS [`docs/SAGA.md`](../../Avasia-iOS/docs/SAGA.md) §7.

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
| Social commentary from playable tradeoffs, not narrator sermons (§0) | Every Anula is a choice: raise the sword, or build the Apothecary |
| Survivor's legend: the Messenger is myth, never a villain (§0) | The Messenger shows up only on broadsheets and cards. Never a boss |
| Horror comes from the system (§8.8) | Endless extraction under a sealed prison. The player is part of the system |

Hearthdelve also answers several open questions in SAGA §8.9:

- **Wallet and spell fuel: one meter or two?** One. Anula pays for gear, buildings, and ward-fuel.
- **Mining geography.** The NW mountain, north of Splitpath Station on the mine road (III-M01, III-M04).
- **The commodity primer.** The first Delve *is* the primer. You come home with crystal, then decide what to spend it on.

## Where and when

**When.** The Commodity Era, after Blade of Courage. Kaefden IV's face is on the stamped shard (III-M08). Whether he is still alive stays open, as SAGA leaves it.

**Where.** The NW mountain, west of KoN's Splitpath. That's the same mountain as KoN's pink cave (LORE_ARCHIVE §1.4), the Jal chain-mine (W-07), and the Kaefden penitentiary that became the Ash Vault (AV-01). Splitpath Station is the nearest town: a rail-head where Ring Road freight meets the crystal line (GAME3_OPENING). The mine road leaves it heading north. The Hearth sits at the end of that road.

## Decisions

Settled 2026-10-28. Jacob handed these calls over, so they follow the canon read above, not a preference.

**1. The Sinter stays nameless until Depth 150, then gets named but never killed.**

- Depth 1–50: the echo is only a sound. A chant through the well on the first walk home, nothing in combat. The mountain's history arrives through biome flavor and Codex pages.
- Depth 51–149: the echo has no name. Echo variants, Red Litany events, and Codex fragments (Malvek's sermons, Pell's ancestor's ledger, Bera's COPY) let a reader piece it together early.
- Depth 150: a milestone Warden named for what Delver Seven didn't finish. The game says "the Sinter" once, there. The spec already makes 150 the last Depth that gates new mechanics, so the name lands where the content stops being new.
- After 150 the echo is still there. Depth has no ceiling, so nothing below can be a final boss you finish.

Why: AV-01 has the Sinter "heard, not named." AshVault won't ship, so Hearthdelve is the only game where players meet the Sinter, and naming it late makes it worth finding. SAGA's rule that deep vessels are not redeemed fits a thing that is only appetite.

**2. The charter company is the first expansion, not launch.**

Sketch for later:

- An assayer comes up the mine road after the Relay Tower puts the Hearth's best Depth on the crystal line. The tower brings them; the player never caused it on purpose.
- A charter offer: sell crystal to the company for more Anula and faster Hearth projects, and a company office goes up in the village.
- Turning it down keeps the commons slower. Neither path locks content, and neither runs on a timer.
- The Wanderers disagree, per SAGA's "no faction is a clean mouthpiece." Old Hob wants the money, Fern refuses, and Pell counts both ledgers.

That makes the economy blade a choice the player makes, not scenery. The launch Hearth stays an honest commons.

**3. The Messenger never appears in person.**

Broadsheets, songs, and cards only. The survivor's legend pillar is about the myth, and III-M05 already tells the "living person refuses to be a saint" story in prose. A cameo risks contradicting whatever the SoC ending finally says. Revisit only if an expansion needs it, and even then never as a fight.

**4. Hale is a thirteenth Wanderer.**

Hale lives at the Inn with no building of their own, and is rescued at Depth 51. None of the twelve is replaced, because each one already runs a building. The entry has no building, so `Content/wanderers.json` needs `building` to be optional.

**5. The store name is Hearthdelve. The saga title is *Avasia: Hearthdelve*.**

- **App Store name:** Hearthdelve. Nobody searches for "Avasia" yet, and the unique word is the hook.
- **App Store subtitle:** sells the genre, not the saga. For example, "Endless loot. A village to come home to."
- **Title screen, saga docs, and Avasia-iOS cross-promo:** *Avasia: Hearthdelve*, matching *Avasia: King of Nacastrum* and *Avasia: Blade of Courage*.

If Avasia ever builds a store audience, the name can move to "Avasia: Hearthdelve" in an update without changing anything else.

## Next steps

**Saga.** Landed 2026-10-28 in Avasia-iOS `docs/SAGA.md` §7:

> **Game 3 = *Avasia: Hearthdelve*.** First 2D game; Commodity Era; NW mountain above the sealed Ash Vault. Anula is one meter (currency + fuel). The Rift is an uncharted vein; Depth is grade.

**Hearthdelve** (after the demo-on-device gate, not before)

- Add a Setting section to the design spec pointing here. Landed 2026-10-28.
- Display strings landed 2026-10-28: gold → Anula, Shards → Facets, Embers → Echoes, Souls → Charge, Lighthouse → Relay Tower. The craft button shows its Facet price. Save keys are still the old names.
- Rewrite the Codex and Wanderer flavor lines to match the Biomes and Wanderers tables.
- Add anchor tags to Relics in `Content/`.
- Add Hale to `Content/wanderers.json`. The entry has no building, so the schema needs `building` to be optional.
- Add the Depth 150+ Wardens to `Content/wardens.json` when M3 content work reaches them.

## Not in this handoff

Do not invent these. The flavor rewrite, Hale's lines, and the late Wardens wait on them.

- Biomes table
- Wanderers table, including Hale's lines
- Depth 150+ Warden list
