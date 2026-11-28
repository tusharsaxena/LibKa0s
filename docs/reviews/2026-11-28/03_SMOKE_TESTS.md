# In-client smoke tests — LibKa0s v1.119.0 review (2026-11-28)

LibKa0s has no TOC and no in-game surface of its own. Every step below runs through a consumer that
vendors this payload: **Ka0s Drop Watcher** (Retail) and **Ka0s Item Search** (WoW Forever), both on
`feat/2026-11-27-itemsearch-split`.

## Pre-flight

1. Headless gate, after the changes land, from the LibKa0s root:
   `lua tests/run.lua`, then `KA0S_KIT_CLIENT=forever lua tests/run.lua`, then
   `~/.claude/dev-copilot/bin/ka0s-bounded luacheck .`, then `python3 -m pytest -q tools/seeds`. All
   must report 0 failed and 0/0.
2. Re-vendor the payload whole into both consumers (`LibKa0s/` to `libs/LibKa0s/`, and `testkit/`
   to `tests/_kit/` if F-011 landed).
3. In the client: `/console scriptErrors 1`, and enable BugSack if you have it.
4. Retail: a Retail character with gear in its bags, Pawn installed and enabled. WoW Forever: a
   character with talent points spent.

## Per-change checks

### C-01 Shared tables refilled in place

- **Setup:** Drop Watcher and Item Search enabled together on WoW Forever.
- **Steps:**
  1. `/reload`.
  2. `/run local V=LibStub("LibKa0s-Verdict-1.0"); print(V.C == V.C, V.MODULES.VerdictConstants)`.
  3. Hover the same piece of gear in Item Search's window and in Drop Watcher's feed.
- **Expected:** no Lua error. Both addons show the same verdict word and the same item-level delta.
- **Pass if:** the verdicts are identical in both surfaces.

### C-02 `v:Events()` and the isolated stand-up

- **Setup:** both consumers re-wired to `Events()`.
- **Steps:**
  1. `/dw diagnostics`: the Verdict line is listed.
  2. Equip a different helm.
  3. Learn a mount or a toy, or use a vendor test item.
- **Expected:** the gear verdicts repaint within about 0.5 s of the equip, and a collectible's
  verdict turns to `collected` within about 0.5 s of learning it.
- **Pass if:** both refreshes happen, and the debug console shows no "has no NS.FEATURE_EVENTS row"
  line.

### C-03 The defaults when there is no config

- **Setup:** a Retail character wearing an heirloom in any slot. Drop Watcher with a fresh profile.
- **Steps:**
  1. `/reload`.
  2. Immediately link a higher-ilvl drop for that slot in chat and hover it (before the loot feed
     settles).
- **Expected:** the verdict reads `sidegrade`, with the heirloom reason.
- **Pass if:** the verdict is never `upgrade` while the heirloom is worn.

### C-04 Stood down is inert

- **Steps:**
  1. `/dw disable`.
  2. Hover several uncached items (fresh links from chat).
  3. `/dw enable`.
- **Expected:** no Lua error. While disabled, the debug console shows no `item facts` load lines.
  After `/dw enable`, hovered items judge normally.
- **Pass if:** both hold.

### C-05 Documentation, UX and tooling

- F-009: in Item Search, open Settings, then Comparison, then Weights. Paste
  `( Pawn: v1: "x": Strength=1 )` and press Enter. The chat line carries `[Ka0s Item Search]`.
- F-010: import `( Pawn: v1: "x": Strength=7.5 )`. The import line says the weight was clamped, or
  the slider reaches 7.5. Either is a pass; which one depends on the owner's choice.
- F-008 and F-011 have no in-client step.

## Regression

1. `/reload` on both clients: no Lua error. The ADDON_LOADED, PLAYER_LOGIN and PLAYER_ENTERING_WORLD
   sequence is clean.
2. Enter and leave combat with Drop Watcher's feed visible. Loot a bag item in combat: the gear
   verdict updates after combat (the `deferWhile` hold).
3. Retail: switch specialization. Gear verdicts update, and an off-spec line shows on an item your
   spec cannot use.
4. Forever: spend a talent point. Verdicts follow the top tree.
5. Open each consumer's Comparison page. Every row toggles. The spec strip switches between specs.
6. **Cross-addon (in-client half):** with every roster addon loaded, type each addon's slash root
   and confirm it reaches its own addon. Open Settings, then AddOns: each addon appears exactly once,
   and each multi-page addon's pages appear once each.

## Performance check (F-012, measure before acting)

With Drop Watcher's perf harness, run its own two-arm `/dw perf` protocol: clean arm first, suspend
second, no `/reload` between arms. Scroll Item Search's result list while the capture runs. Read the
`evaluate` and `gear.rebuild` **bucket figures**, never the frame-time delta. Record the capture as a
`docs/perf-analysis/<stamp>/` bundle in the consumer.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-01 | | | |
| C-02 | | | |
| C-03 | | | |
| C-04 | | | |
| C-05 | | | |
| Regression 1-6 | | | |
| Perf (F-012) | | | |
