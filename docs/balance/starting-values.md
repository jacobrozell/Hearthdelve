# Starting values

These live in `Content/tuning.json` because the spec does not fix them. `proposal` is true until HearthSimCLI tunes them against the targets.

Paragon growth `1.02` is the spec (+2% per Paragon level). The base is not. Hero XP base `100` and growth `1.08` are a starting curve. Soul regen `1` per second is a stand-in for the spec's "slow regen".

Combat seeds, chosen so a Fair build at item level `depth + 10` kills fodder in two hits before armor: `P0 = 10`, `HP0 = 15`, so hit points over power is 1.5. Enemy damage `Dmg0 = 8` and hero HP `H0 = 160` keep survival flat with depth, about twenty unmitigated fodder hits. A potion restores 55% of max HP.

Ember Flask's hit is 380% Power. Burning ground ticks 40% Power per second for 3 seconds. The tick is not in the spec.

The one-room speeds, brute and ranged multipliers, potion, and starting Souls are in `tuning.room`. They are proposals so the first pack can be watched: fodder still die in two sword hits, the brute is the elite the Lantern Ward tactic is waiting for, and Souls start full so a Relic tap does something before the first kill.

The M0 numbers came from `HearthSimCLI sweep` and `room` runs, and from watching the app. The hero reacts after 0.25 s. Fodder swing every 2 s. The ranged bat fires every 1.8 s, and its bolt travels 6 tiles per second. Elites have 3× HP. The Cyclops slam has a 1.0 s telegraph and a 1.2-tile radius, so a hero who walks away when the telegraph appears gets clear. Every third wave is a champion pack. With no taps, seed 1 holds out about 90 seconds across five waves: fodder die in about one sword hit, slams land 0 of 10, and all three Tactics fire. Tapping Relics is what keeps the run alive past that.

Gold per Rift is `riftGold` 25. Each hero level after 1 adds `heroHPPerLevel` 8 hit points on the next fight. Salvage pays `smith.commonDust` 5, `rareShards` 2, and `uniqueEmbers` 1. Raising an item one level starts at 8 Dust and 10 gold, then multiplies by `raiseGrowth` 1.12 for each level above 11, and stops at best Depth + 10.
