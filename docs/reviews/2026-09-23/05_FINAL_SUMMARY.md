# 05 — Final summary (LibKa0s, 2026-09-23)

*Written as though every change in `02_PROPOSED_CHANGES.md` has landed and every test in `03_SMOKE_TESTS.md` has passed. The numbers marked "expected" are to be confirmed by the release run.*

## Headline

This pass fixed two defects that every consumer shipped.
- The item-quality fallback now reads the `|cnIQ` color escape the client has used in item links since 11.1.5. Before this, LootHistory recorded a blank quality for every item that wasn't cached yet.
- The settings page chrome now pools its banner, header and divider instead of leaking an AceGUI widget and a frame on every page re-render.

Beyond those two, the library's own seams now agree with each other:
- the slash CLI reports a value the write seam rejected;
- the chat printer survives a combat-protected value in a numeric slot, as the debug sink already did;
- the monospace face registers on ruRU/CJK clients;
- the Bus keeps tracking after an AceEvent upgrade;
- the launcher owns the disabled-state refusal every host had been writing by hand.

Test assertions that only checked "it raised" now check what was raised.

## Counts

Critical fixed: 0, High fixed: 2, Medium fixed: 6, Low fixed: 8 (F-009 to F-013, F-016, F-017, plus F-015 recorded as watch notes).

**Deferred:** F-014 (C-08, Schema's `instanceId` pass-through) until an instanced host adopts the Schema runtime. No consumer needs it today.

## Changes by theme

### T1. Item links (F-001, F-013 / C-01)
- **What changed:** `QualityFromLink` reads `|cnIQ<n>` first and falls back to the hex color. The quality map is only cached once it has entries.
- **Why it mattered:** the fallback exists for uncached items, and on the current client it answered nothing.
- **Files:** `LibKa0s/Item.lua`, `tests/test_item.lua`, `docs/api/Item/*`.

### T2. Chrome pooling (F-002 / C-02)
- **What changed:** PageHeader's frame and the divider come from per-page pools. The banner's dropdown is returned to AceGUI.
- **Why it mattered:** unbounded widget and frame growth on the most-used settings pages of eight consumers.
- **Files:** `LibKa0s/OptionsTabs.lua`, `tests/test_options_tabs.lua`, `testkit/mock_record.lua`, `testkit/mock_base.lua`, `tests/_kit/*`, `docs/api/Options/*`.

### T3. Seams agree (F-003, F-008 / C-03, C-07)
- **What changed:** `set` on the CLI prints the refusal and its reason. `printer.Format` never raises on a protected value.
- **Why it mattered:** a silent CLI no-op, and a latent in-combat raise.
- **Files:** `LibKa0s/Slash.lua`, `LibKa0s/Core.lua`, and their suites and docs.

### T4. Underlying libraries (F-004, F-005 / C-04, C-05)
- **What changed:** the font registers with a langmask and the count reflects LSM's actual state. The Bus re-stamps wrappers that AceEvent re-embedded.
- **Why it mattered:** a missing face on four locales, and a latent draw-gate regression.
- **Files:** `LibKa0s/Media.lua`, `LibKa0s/Bus.lua`, and their suites and docs.

### T5. Launcher (F-006, F-009 / C-06)
- **What changed:** the optional `isEnabled`/`disabledLine` fields let the one click implementation refuse rungs (a) and (b) while disabled. Notices print once, untagged.
- **Why it mattered:** three host spellings of a MUST, and duplicated, double-tagged notices.
- **Files:** `LibKa0s/Launcher.lua`, `tests/test_launcher.lua`, `docs/api/Launcher/*`.

### T6. Tests (F-007 / C-09)
- **What changed:** `Kit.assertErrorMatches` was added in the new `testkit/asserts.lua`, and 23 call sites now assert on what was raised.
- **Files:** `testkit/asserts.lua`, `testkit/framework.lua`, `tests/_kit/*`, and six suites.

### T7. Hygiene (F-010, F-011, F-012, F-016, F-017 / C-10 to C-13; F-015 / C-14)
- **What changed:** a ring buffer for the console, raw-initialized Perf fields, bracket depth reset per window, the drag poll moved onto a library-owned frame with a pooled drop line, and a Lifecycle re-entrancy rule documented and pinned.
- **Files:** `LibKa0s/DebugLog.lua`, `LibKa0s/Perf.lua`, `LibKa0s/Widgets.lua`, `LibKa0s/Lifecycle.lua`, and their suites.

## API and behavior changes

- **Minor bumps (expected):** Core 7→8, Item 1→2, Media 3→4, Widgets 9→10, DebugLog 12→13, Slash 14→15, Launcher 1→2, Perf 12→13, Bus 1→2, Lifecycle 1→2, OptionsTabs 3→4 (so a new Options version key), plus one kit revision. Schema is unchanged unless C-08 is taken.
- **No floor raised, no field removed or repurposed** (library-stack-§7).
- **New optional descriptor fields:** Launcher's `isEnabled` and `disabledLine`. Slash's `set` may answer `false, reason`.
- **New kit member:** `Kit.assertErrorMatches`. New mock survey: AceGUI create/release counts.
- **String changes:** the Launcher's `NO_*` values lose their `[LibKa0s] ` tag (the keys are unchanged). Slash gains `NO_DEFAULT`.
- **No SavedVariables, slash roots or reserved verbs change.**

## Saved-variable and migration notes

None. The library persists nothing. LootHistory's stored links keep working through the hex rung.

## Deprecated-API migrations

| Old | New | Files |
|---|---|---|
| Item-link color `\|cff<hex>` (retired from links in 11.1.5) | `\|cnIQ<n>` named quality color | `LibKa0s/Item.lua` |

## Performance impact

The perf-tagged changes are F-002, F-010 and F-011. There's no offline scenario runner here, so the evidence is:
- the kit's AceGUI create/release survey, where `created - released` stays constant across repeated renders (expected);
- `tests/test_perf_isolation.lua`'s 0.0 KB dormant and active pin, which stays green;
- a frozen in-client capture in one consumer's `docs/perf-analysis/` (S-008).

No before/after figures are claimed until those records exist.

## Test and complexity movement

- **Pass count:** 1484 → about 1498 to 1500 (expected). `docs/test-cases.md` and the README badge moved in each commit that moved the count.
- **Complexity:** no function crosses CCN 15. The four at exactly 15 (`lib.Catalog`, `lib.GetSpellCooldown`, `idHelpIcon`, `liveTimers`) get watch-list dispositions at the release run. The release run's `RESULTS.md` row confirms this; nothing was regenerated in this pass.

## Known follow-ups

- F-014 / C-08 is deferred until an instanced host adopts the Schema runtime.
- Open issues #32 and #33 (the `OptionsWidgets.lua` and `test_options_widgets.lua` peels) are unchanged by this pass, which deliberately adds nothing to either file.
- The ratified `testkit/framework.lua` row: C-09 put its helper in a new file for exactly that reason.
- Consumer-side cleanups after the re-vendor (M6-T12..T14): the launcher gates, AuraMaster's Slash wrapper, and LootHistory's link fixture.

## Verification evidence

- `03_SMOKE_TESTS.md` with its sign-off table filled in.
- The commit range on `feat/2026-09-23-review-audit-remediation` in this repo, plus one re-vendor commit per consumer.
- The release run's `docs/automated-tests/<stamp>/` bundle.

## Suggested PR description

```
LibKa0s review 2026-09-23 remediation

High:
- F-001 Item.QualityFromLink reads the 11.1.5+ |cnIQ escape (was nil on every live link)
- F-002 OptionsTabs pools PageHeader/divider and releases the PageBanner dropdown to AceGUI

Medium:
- F-003 Slash reports the write seam's refusal
- F-004 Media registers the mono face with a langmask; counts what LSM holds
- F-005 Bus re-stamps wrappers after an AceEvent re-embed
- F-006 Launcher owns the rung (a)/(b) disabled refusal (isEnabled/disabledLine, optional)
- F-007 Tests assert what raised (Kit.assertErrorMatches)
- F-008 Core printer.Format falls back on a secret in a numeric slot

Low: F-009..F-013, F-015..F-017 (notices once, ring buffer, Perf raw fields and depth reset,
drag poll on a library frame, quality map retry, CCN-15 watch notes, Lifecycle re-entrancy).
Deferred: F-014.

No floor raised; every contract change additive. Re-vendor into all eleven consumers follows,
one commit each.
```
