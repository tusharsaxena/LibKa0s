# 04 — Execution plan (LibKa0s, 2026-09-23)

LibKa0s is the upstream, so milestones M1 to M5 land **here**. M6 is the cross-repo handoff: a whole-folder re-vendor into each of the eleven consumers as its own commit, plus the small host-side migrations the additive fields make possible.

- **Never** edit a consumer's `libs/LibKa0s/` or `tests/_kit/` in place.
- **Every** milestone's exit criterion includes: `lua5.1 tests/run.lua` shows 0 failed, `luacheck .` shows 0/0, `diff -rq testkit tests/_kit` is empty, and the versioning suite is green (that suite asserts each changed file's minor went up and `CHANGELOG.md` accounts for it).
- Work on the branch that's already checked out. Commit per task.

## M1: the High findings (F-001, F-002)

**Done when:** C-01 and C-02 are merged, `docs/test-cases.md` and the README badge have moved in the same commits, S-001 and S-002 pass on one consumer, and the API docs for `Item` and `Options` are updated with regenerated manifests.

| Task | Owner role | Findings / change | Files |
|---|---|---|---|
| M1-T1 | wow-api-migrator | F-001, F-013 / C-01 | `LibKa0s/Item.lua`, `tests/test_item.lua`, `docs/api/Item/version-2-docs.md` (new), `docs/api/Item/members-2.json` |
| M1-T2 | test-kit-author | F-002 / C-02 (kit half) | `testkit/mock_record.lua`, a 2-line hook in `testkit/mock_base.lua`, `tests/_kit/` (re-copied), `tests/test_mock_record.lua` |
| M1-T3 | lua-refactorer | F-002 / C-02 | `LibKa0s/OptionsTabs.lua`, `tests/test_options_tabs.lua`, `docs/api/Options/…` (new version key) |

**Concurrency:**
- M1-T1 doesn't overlap M1-T2 or M1-T3, so it's **parallelizable**.
- M1-T3 depends on M1-T2, because it uses the kit's Create/Release survey. **Serialize T2 → T3.**

**Checkpoint A:** a human runs S-001 and S-002 on LootHistory and MultiMeters before M2.

## M2: the library's seams agree (F-003, F-008, F-014)

**Done when:** C-03 and C-07 are merged with their cases. C-08 is either merged or recorded as deferred in `CHANGELOG.md` and the Schema API document.

| Task | Owner role | Findings / change | Files |
|---|---|---|---|
| M2-T1 | lua-refactorer | F-003 / C-03 | `LibKa0s/Slash.lua`, `tests/test_slash.lua`, `docs/api/Slash/…` |
| M2-T2 | lua-refactorer | F-008 / C-07 | `LibKa0s/Core.lua`, `tests/test_core.lua`, `docs/api/Core/…` |
| M2-T3 | lua-refactorer (optional) | F-014 / C-08 | `LibKa0s/Schema.lua`, `tests/test_schema.lua`, `docs/api/Schema/…` |

All three tasks touch disjoint files, so they're **parallelizable**. `tests/test_slash.lua` is at 1327 lines: add C-03's cases in a new `tests/test_slash_refusal.lua` if they would take it past 1500 (layout-§1).

## M3: survive the underlying libraries (F-004, F-005)

**Done when:** C-04 and C-05 are merged with their cases, and S-004 (ruRU) and S-005 pass.

| Task | Owner role | Findings / change | Files |
|---|---|---|---|
| M3-T1 | locale-fixer | F-004 / C-04 | `LibKa0s/Media.lua`, `tests/test_media.lua`, `docs/api/Media/…` |
| M3-T2 | lua-refactorer | F-005 / C-05 | `LibKa0s/Bus.lua`, `tests/test_bus.lua`, `docs/api/Bus/…` |

**Parallelizable.**

## M4: launcher refusal and notices (F-006, F-009)

**Done when:** C-06 is merged, and the Launcher docs describe the two new optional fields with a rung (a)/(b)/(c) table.

| Task | Owner role | Findings / change | Files |
|---|---|---|---|
| M4-T1 | ux-cleanup | F-006, F-009 / C-06 | `LibKa0s/Launcher.lua`, `tests/test_launcher.lua`, `docs/api/Launcher/…` |

**Serialize after M5-T1**, because both touch `tests/test_launcher.lua` (F-007's rewrite of lines 123-128).

## M5: tests and hygiene (F-007, F-010, F-011, F-012, F-015, F-016, F-017)

**Done when:** C-09 to C-13 are merged, C-14's watch-list notes are staged for the next release run, and the pass count and badge are current.

| Task | Owner role | Findings / change | Files |
|---|---|---|---|
| M5-T1 | test-kit-author | F-007 / C-09 | new `testkit/asserts.lua`, a load line in `testkit/framework.lua`, `tests/_kit/`, `tests/test_launcher.lua`, `tests/test_kit_inventory.lua`, `tests/test_mock_ace.lua`, `tests/test_loader.lua`, `tests/test_options_compose.lua`, `tests/test_schema.lua` |
| M5-T2 | lua-refactorer | F-012 / C-10 | `LibKa0s/Widgets.lua`, `tests/test_widgets.lua` (at 1493 lines, so add the cases to a **new** `tests/test_widgets_reorder.lua`) |
| M5-T3 | lua-refactorer | F-010 / C-11 | `LibKa0s/DebugLog.lua`, `tests/test_debuglog.lua` (characterization cases first, testing-§13) |
| M5-T4 | lua-refactorer | F-011, F-016 / C-12 | `LibKa0s/Perf.lua`, `tests/test_perf_core.lua` |
| M5-T5 | doc-writer | F-017 / C-13 | `LibKa0s/Lifecycle.lua` (docstring), `tests/test_lifecycle.lua` |
| M5-T6 | doc-writer | F-015 / C-14 | a note for the release run (no file edit now) |

**Concurrency:**
- **Parallelizable:** T2, T3, T4 and T5 (disjoint files).
- **Order for T1:** M5-T1 comes before M4-T1 (they share `tests/test_launcher.lua`), and M5-T1 comes before M1-T2 if both touch the kit in the same revision. **Recommended:** fold M1-T2 and M5-T1 into **one kit revision** and serialize them.

**Checkpoint B:** before release, the full battery runs, then the `docs/releasing.md` steps. That covers the repo semver bump, CHANGELOG, API docs, manifests, the `docs/automated-tests/` release run via `/wow-addon:bump-version`, and a tag.

## M6: cross-repo handoff (the re-vendor)

**Done when:** all eleven consumers each have one re-vendor commit, their own suites are green, their `diff -rq` against this repo is empty, and the cross-addon four-class pass is re-run clean.

| Task | Owner role | Repos | What |
|---|---|---|---|
| M6-T1..T11 | revendor-bot | AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | `rm -rf libs/LibKa0s tests/_kit && cp -r ../LibKa0s/LibKa0s libs/LibKa0s && cp -r ../LibKa0s/testkit tests/_kit`, then the host suite and a commit: "Re-vendor LibKa0s vX.Y.Z" |
| M6-T12 | per-host (after T1..T11) | the rung (a)/(b) hosts | Pass `isEnabled` and `disabledLine` to Launcher and delete the hand-written gate in `onClick` (F-006). One commit per host |
| M6-T13 | per-host | AuraMaster | Its Slash `set` wrapper should `return NS.SetByPath(path, v)` and drop its hand-printed refusal (F-003) |
| M6-T14 | per-host | LootHistory | Refresh `tests/test_itemsetup.lua`'s `EPIC_LINK` fixture to the `|cnIQ` shape (F-001) |

**Concurrency:**
- T1..T11 are **parallelizable** across repos, one repo per agent. They are **serialized after Checkpoint B**.
- T12, T13 and T14 each follow their own repo's T-n.

## Suggested commit messages

- `Item: read the 11.1.5+ |cnIQ quality escape before the hex rung (F-001, F-013)`
- `Kit: record AceGUI Create/Release so a leak is assertable (F-002)`
- `OptionsTabs: pool the header, the rule and the banner widget instead of unparenting them (F-002)`
- `Slash: honor the write seam's false, reason (F-003)`
- `Core: printer.Format falls back like DebugLog.Debug on a secret in a numeric slot (F-008)`
- `Media: register the mono face with a langmask and count what LSM actually holds (F-004)`
- `Bus: re-stamp tracking wrappers after an AceEvent re-embed (F-005)`
- `Launcher: own the rung (a)/(b) disabled refusal; print notices once, untagged (F-006, F-009)`
- `Tests: assert what raised, not only that it raised (F-007)`
- `Widgets/DebugLog/Perf/Lifecycle: hygiene (F-010, F-011, F-012, F-016, F-017)`
- per consumer: `Re-vendor LibKa0s vX.Y.Z (review 2026-09-23)`

Every commit ends with the session's attribution lines.
