# Hearthdelve

Portrait iPhone game. The fight is Swift. The village is SpriteKit plus SwiftUI. Team `7JT2JB89AV`. Version **0.1.0 (1)**. Not submitted.

A cold launch opens on a hamlet about two phone screens wide. Pan it, tap the well, run a Delve, and come home with loot. Equip from the bag. Salvage at the smith. Level, gold, and Dust move. The Apothecary, Library, and Map Room name the Depth that opens them and do not open a system yet.

## Run

```bash
xcodegen generate
swift test --package-path Packages/HearthCore
swift test --package-path Packages/HearthContent
```

Open `Hearthdelve.xcodeproj` and run the `Hearthdelve` scheme (iOS 18+). `-seed` jumps into a fight. A normal launch opens on the village.

## Docs

- Demo checklist: [`ongoing/demo-mvp.md`](ongoing/demo-mvp.md)
- Design: [`Hearthdelve — Game Design Spec.md`](Hearthdelve%20—%20Game%20Design%20Spec.md)
- Build order: [`hearthdelve-full-build.plan.md`](hearthdelve-full-build.plan.md)
