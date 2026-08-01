# Matrix — 2026-08-01

## Scope

`docs/releasing.md`'s Consumers table names AbsorbTracker, KickCD and ConsumableMaster. The
filesystem agrees exactly — `libs/LibKa0s/` exists in those three and in no other repo under
`../`. No unrecorded adoption, no recorded-but-absent one.

Not adopted, per `docs/adoption-prompt.md`: BankLedger, LootHistory, PanelMaster, prettychat,
WhatGroup. Out of scope until they are on the standard: WhoGotLoots, BuffTextNotifications (neither
has a `libs/` tree at all).

## Version fidelity

Every consumer, every file, at the shipped minor. No skew.

| File | Constant | Ship | AbsorbTracker | KickCD | ConsumableMaster |
|---|---|---|---|---|---|
| `Core.lua` | `MINOR` | 2 | 2 | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 3 | 3 | 3 | 3 |
| `Slash.lua` | `MINOR` | 4 | 4 | 4 | 4 |
| `Options.lua` | `MINOR` | 4 | 4 | 4 | 4 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 4 | 4 | 4 | 4 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 2 | 2 | 2 | 2 |
| `Perf.lua` | `MINOR` | 5 | 5 | 5 | 5 |
| `PerfPanel.lua` | `PANEL_MINOR` | 3 | 3 | 3 | 3 |

All three were re-vendored through the v1.1.0 release. `NEEDS_CORE = 1` is satisfied everywhere
(Core is at 2), so no major is silently absent in any host.

## Byte fidelity

| Consumer | `diff -r` (byte) | `diff -r --strip-trailing-cr` (content) | Kit byte | Kit content |
|---|---|---|---|---|
| AbsorbTracker | empty | empty | empty | empty |
| KickCD | empty | empty | empty | empty |
| ConsumableMaster | **4 files differ** | empty | **1 file differs** | empty |

The four: `Options.lua`, `OptionsWidgets.lua`, `Perf.lua`, `Slash.lua`. The one: `mock_base.lua`.
All line-ending only. See `03_DEVIATIONS.md` §1 for which side is the anomaly — it is not
ConsumableMaster.

### Working-tree line endings

| File | Ship | AbsorbTracker | KickCD | ConsumableMaster | Git blob |
|---|---|---|---|---|---|
| `Core.lua` | CRLF | CRLF | CRLF | CRLF | LF |
| `DebugLog.lua` | CRLF | CRLF | CRLF | CRLF | LF |
| `LibKa0s.xml` | CRLF | CRLF | CRLF | CRLF | LF |
| `Options.lua` | **LF** | **LF** | **LF** | CRLF | LF |
| `OptionsScroll.lua` | CRLF | CRLF | CRLF | CRLF | LF |
| `OptionsWidgets.lua` | **LF** | **LF** | **LF** | CRLF | LF |
| `Perf.lua` | **LF** | **LF** | **LF** | CRLF | LF |
| `PerfPanel.lua` | CRLF | CRLF | CRLF | CRLF | LF |
| `Slash.lua` | **LF** | **LF** | **LF** | CRLF | LF |

Every repo is `git status` clean. Blobs are normalised LF, `.gitattributes` says `eol=crlf`, and
under that combination a working tree holding either ending is clean — which is why nothing has
ever reported this.

## Majors wired, and where the seam lives

All five in all three. Fifteen of fifteen.

| Major | AbsorbTracker | KickCD | ConsumableMaster |
|---|---|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua` | `core/CoreSetup.lua` | `core/CoreSetup.lua` |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua` | `core/DebugLogSetup.lua` | `modules/DebugLog.lua` |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua`, `settings/Schema.lua` | `settings/Slash.lua` | `core/SlashCommands.lua` |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua` | `settings/OptionsSetup.lua` | `settings/Panel.lua` |
| `LibKa0s-Perf-1.0` | `core/PerfSetup.lua` | `core/PerfSetup.lua` | `modules/PerfSetup.lua` |

`docs/releasing.md`'s per-module Consumers column matches this exactly, including
ConsumableMaster's three non-standard locations. The table is accurate and needs no correction.

One addition it does not record: AbsorbTracker resolves `LibKa0s-Slash-1.0` in **two** files —
`settings/Slash.lua` and `settings/Schema.lua` — where the table names only the first.

## TOC wiring

| Consumer | Version | `LibKa0s.xml` line | PerfDB SavedVariable |
|---|---|---|---|
| AbsorbTracker | 1.9.0 | 27 | `AbsorbTrackerPerfDB` ✓ |
| KickCD | 1.2.1 | 26 | `KickCDPerfDB` ✓ |
| ConsumableMaster | 1.5.0 | 36 | `ConsumableMasterPerfDB` ✓ |

All three load `libs\LibKa0s\LibKa0s.xml` from the `# Libraries` block after LibStub and Ace3, and
all three declare the second Perf global. ConsumableMaster's TOC is the only one that documents
*why* each seam file sits where it does, inline (lines 31-36, 44-55, 97-101, 111).

## Adoption depth, by surface

Presence of a call in host code, excluding `libs/` and `tests/`.

| Surface | AbsorbTracker | KickCD | ConsumableMaster |
|---|---|---|---|
| Options `RenderRows` | ✓ (4 files) | ✓ (3 files) | ✓ (1 file) |
| Options `RenderGrid` | — | — | ✓ |
| Options `LSMValues` | ✓ (4 files) | ✓ (5 files) | ✓ (2 files) |
| Slash `CliList` / `CliGet` / `CliSet` | ✓ | ✓ | ✓ |
| Slash `CliReset` | ✓ | ✓ | **declined** |
| Slash `HelpRows` | ✓ | ✓ | ✓ |
| Slash `LandingRows` | ✓ | ✓ | n/a — no landing page |
| Host console file survives | deleted | deleted | `modules/DebugLog.lua`, 208 lines (seam) |
| `NS.LIBKA0S_MISSING` clause | ✓ 6 sites | **0 sites** (own idiom) | ✓ 5 sites |

Seam file sizes, as a proxy for how much adapter each host needed:

| Seam | AbsorbTracker | KickCD | ConsumableMaster |
|---|---|---|---|
| Core | 78 | 102 | 99 |
| DebugLog | 110 | 169 | 208 |
| Perf | 130 | 215 | 103 |
| Options | 199 | 232 | 920 |
| Slash | 471 | 343 | 1350 |

ConsumableMaster's Options and Slash figures are whole host files that also carry the addon's own
page builders and command tree, not adapter alone — they are not comparable to the other two
columns. KickCD's uniformly larger seams are the adapters the prompt predicted (colour codec,
`groupKey`, `panelKey`→`pageKey`, the 3-arg write seam).

## Convergences

| Convergence | AbsorbTracker | KickCD | ConsumableMaster |
|---|---|---|---|
| #1 `reset` takes a path | adopted — `/at reset <path>` + `/at resetall` | adopted — `/kcd reset <path>` + `/kcd resetall`, spell rebuild re-homed under a subcommand group | **declined, unrecorded** — `/cm reset` is the confirm-gated global wipe |
| #2 landing rows through one formatter | adopted | adopted | **not applicable** — no landing page carries command rows |

## Green gate

| Repo | `lua tests/run.lua` | `luacheck .` |
|---|---|---|
| LibKa0s | 382 passed, 0 failed | 0 warnings / 0 errors, 11 files |
| AbsorbTracker | 449 passed, 0 failed | 0 warnings / 0 errors, 28 files |
| KickCD | 629 passed, 0 failed | **7 warnings** / 0 errors, 32 files |
| ConsumableMaster | 544 passed, 0 failed | 0 warnings / 0 errors, 50 files |

AbsorbTracker at 449 is unchanged from the figure `docs/adoption-prompt.md` quotes as its
additive-change proof. That proof still holds.

KickCD's seven warnings are all outside the five seam files — `core/Database.lua`,
`core/KickCD.lua`, `core/LSMPatch.lua`, `modules/Cooldowns.lua`, `modules/IconGrid.lua`,
`settings/Profiles.lua`, `settings/Spells.lua`. `CoreSetup`, `DebugLogSetup`, `PerfSetup`,
`OptionsSetup` and `Slash.lua` all report OK. Nothing is attributable to the adoption.

## `L` trap

| Consumer | Descriptor `L` overrides | Shape | Regression guard |
|---|---|---|---|
| AbsorbTracker | none — omits `L` everywhere | n/a (correct: translates nothing) | none |
| KickCD | 1 — `settings/Slash.lua:331` | plain table, one key, gated on `NS.L` ✓ | ✓ `tests/test_perfsetup.lua:375`, `:450` |
| ConsumableMaster | 1 — `core/SlashCommands.lua:1289` → `SLASH_STRINGS` (`:1257`) | plain table of 7 literals ✓ | none |

No addon passes its locale table. Guard coverage: **1 of 15** module-adoptions.

## Provenance

| Consumer | README names LibKa0s | CHANGELOG.md | `LICENSE` in `libs/LibKa0s/` |
|---|---|---|---|
| AbsorbTracker | no | absent | no |
| KickCD | no | absent | no |
| ConsumableMaster | no | absent | no |

Ship files carry no copyright header either: `grep -c -i copyright LibKa0s/*.lua` returns 0 for all
nine files, and `\bMIT\b` matches nothing.

## Adoption record quality

| Consumer | Record | Assessment |
|---|---|---|
| AbsorbTracker | `docs/pending/LEDGER.md` ISS-19, PLAN-04 | Adequate — records the perf extraction and the shared degradation clause. |
| KickCD | `docs/pending/LEDGER.md` PLAN-01 | Thin — one entry, and about pruning AceTimer rather than about adoption. The colour-shape and flow-engine findings live in this repo's `docs/releasing.md`, not in KickCD's. |
| ConsumableMaster | `docs/pending/LEDGER.md` LIBKA0S-01 … -07 | **The best in the collection.** Seven tracked items with superseded entries preserved, each naming the upstream minor that unblocked it. This is the record the other two should copy. Its one hole is the `reset` decision. |
