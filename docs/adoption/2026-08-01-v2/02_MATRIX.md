# Matrix — 2026-08-01 (run v2)

Second run of the day, taken after the v1.2.0 minor bumps to DebugLog, Slash, Options and
OptionsWidgets and after BankLedger's adoption landed as the fourth consumer. The earlier run is
`docs/adoption/2026-08-01/`; every figure below was re-established from evidence rather than
inherited from it. Section references are to `05_EVIDENCE.md` in this bundle.

## Scope — who has adopted, by three different accounts

| Account | Names | Agrees with the filesystem? |
|---|---|---|
| Filesystem (`ls -d ../*/libs/LibKa0s`) | AbsorbTracker, BankLedger, ConsumableMaster, KickCD | — it is the authority |
| `docs/releasing.md` Consumers table | AbsorbTracker, BankLedger, ConsumableMaster, KickCD | yes, at the repo level |
| `docs/adoption-prompt.md` "Adopted" (line 6) | AbsorbTracker, ConsumableMaster, KickCD | **no — BankLedger missing** |
| `docs/adoption-prompt.md` "Remaining targets" (line 8) | BankLedger, LootHistory, PanelMaster, prettychat, WhatGroup | **no — BankLedger is adopted** |
| `docs/releasing.md` "Remaining" (line 177) | LootHistory, PanelMaster, prettychat, WhatGroup | yes |

Four repos hold a `libs/LibKa0s/`, and those four are exactly the four `docs/releasing.md` names —
there is no unrecorded adoption and no recorded-but-absent one (§1). LootHistory, PanelMaster,
prettychat and WhatGroup have no `libs/LibKa0s` at all. The disagreement is entirely
`docs/adoption-prompt.md`, which was not moved when BankLedger landed although `docs/releasing.md`
was, in three separate commits: it still lists BankLedger as a remaining target (line 8), still
carries a live un-struck module-order row for it ending in "→ Perf" against a recorded Perf decline
(line 303), and still quotes only three suite totals as its additive-change proof (line 538). That
is a high-severity documentation finding, not an adoption one — the code is right and the map is
wrong (§1, §10). One further file-level omission, which is a `docs/releasing.md` fault rather than a
prompt one: its `LibKa0s-Slash-1.0` row names only `settings/Slash.lua` for AbsorbTracker, and there
is a second wiring at `settings/Schema.lua:182` (§4).

## Version fidelity — eight files, ship against four consumers

| File | Constant | Ship | AbsorbTracker | BankLedger | ConsumableMaster | KickCD |
|---|---|---|---|---|---|---|
| `Core.lua` | `MINOR` | 2 | 2 | 2 | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 4 | 4 | 4 | 4 | 4 |
| `Slash.lua` | `MINOR` | 5 | 5 | 5 | 5 | 5 |
| `Options.lua` | `MINOR` | 5 | 5 | 5 | 5 | 5 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 5 | 5 | 5 | 5 | 5 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 2 | 2 | 2 | 2 | 2 |
| `Perf.lua` | `MINOR` | 5 | 5 | 5 | 5 | 5 |
| `PerfPanel.lua` | `PANEL_MINOR` | 3 | 3 | 3 | 3 | 3 |

Thirty-two of thirty-two cells are at ship. There is **no cross-major skew anywhere**, which is the
central question this run was convened to answer, and it answers clean (§2). Every consumer took the
v1.2.0 bumps as separate, individually titled re-vendor commits with a clean working tree afterwards
— AbsorbTracker ebaad1e/87eda52/6d32bd4/39620b4, ConsumableMaster 9754b9e/e592a04/9d340f5/1a40448,
KickCD 1ae16b6/d24ebe1/040cddb/435ec6d — so the bytes on disk are the committed bytes in all four.
`NEEDS_CORE` is still 1 and Core is at 2 everywhere, so no major is silently absent in any host.

The one thing this table cannot show is that the release it describes does not exist as a ref:
`git tag` in this repo lists v1.0.0, v1.1.0 and v1.1.1 only, and `git describe --tags` reads
`v1.1.1-7-g8d1d879`. All four consumers' READMEs name "LibKa0s v1.2.0" and all four genuinely carry
that payload byte-for-byte, so four shipped addons name a version nobody can check out. That is the
run's highest-severity finding and it sits on the ship side, not on any consumer (§1).

## Byte fidelity — the four diffs, per consumer

| Consumer | `libs/` byte | `libs/` content | kit byte | kit content |
|---|---|---|---|---|
| AbsorbTracker | empty | empty | empty | empty |
| BankLedger | empty | empty | empty | empty |
| ConsumableMaster | empty | empty | empty | empty |
| KickCD | empty | empty | empty | empty |

Sixteen empty diffs. The pattern means both readings agree and neither branch of the method's
adjudication fires: there is no content fork in any `libs/` tree, and no line-ending divergence to
mistake for one (§3). Both halves were characterised positively rather than inferred from silence —
`file -b` reports CRLF working trees on the ship side and on all four consumer sides, and
`git cat-file -p HEAD:<path> | file -b -` reports LF blobs on all five, which is exactly the
round-trip `* text=auto eol=crlf` over LF blobs should produce.

This is the clean close of the earlier run's first finding. On 2026-08-01 v1, sixteen of the
library's forty-nine tracked files sat LF in the working tree, four of them ship files, and the byte
diff consequently cried wolf on ConsumableMaster — the one consumer that was correct. Today all
sixty tracked ship files are CRLF, `testkit/` and `tests/_kit/` agree on CRLF rather than agreeing
by accident at LF, and BankLedger has acquired its own `.gitattributes` pinning the same rule
(commit 9325663), which is why its clean diff is clean by construction rather than by luck. How the
ship-side condition was fixed could not be established: no commit in the last twenty-five is named
as a renormalisation, so this is a statement about current state and not about cause (§3).

## Module coverage — which majors each consumer wires, and where the seam is

| Major | AbsorbTracker | BankLedger | ConsumableMaster | KickCD |
|---|---|---|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua:25` | `core/CoreSetup.lua:34` | `core/CoreSetup.lua:33` | `core/CoreSetup.lua:64` |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua:14` | `core/DebugLogSetup.lua:20` | `modules/DebugLog.lua:55` | `core/DebugLogSetup.lua:45` |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua:24`, `settings/Schema.lua:182` | `settings/Slash.lua:99` | `core/SlashCommands.lua:1301` | `settings/Slash.lua:55` |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua:36` | `settings/OptionsSetup.lua:26` | `settings/Panel.lua:184` | `settings/OptionsSetup.lua:35` |
| `LibKa0s-Perf-1.0` | `core/PerfSetup.lua:14` | — declined | `modules/PerfSetup.lua:29` | `core/PerfSetup.lua:33` |

Nineteen of twenty possible wirings, and the twentieth is a decline with a structural argument
rather than a gap: BankLedger's capture engine runs out of combat while the probe's windows are
combat-gated, so every Perf bucket would read 0.000 by construction. It is recorded at its
`docs/pending/LEDGER.md` LIBKA0S-17 and `docs/releasing.md` correctly omits BankLedger from the Perf
row and states the decline in prose at line 177 (§4).

Every cell above matches `docs/releasing.md`'s per-module Consumers column, including
ConsumableMaster's three non-standard locations, with the single exception noted under Scope —
`settings/Schema.lua:182` is a second AbsorbTracker Slash lookup the table does not name, and it
reaches `lib.FormatValue`, which is precisely the function Slash minor 5 extended with the `format`
hook. A change to that function points a reviewer at one file when it should point at two. The call
is guarded (`if SlashLib then`), so the bounded damage is a silently wrong rendered value rather
than a Lua error. Separately, `docs/releasing.md` attributes decoration of the library instance
itself to AbsorbTracker alone and says no other module can collide with a host member; KickCD has
the same shape at `settings/OptionsSetup.lua:224`, decorated in place by three further files, so the
claim is stale and the collision surface is doubled (§4).

## Adoption depth — library surface against four consumers

Presence of a call in host code, `libs/` and `tests/` excluded. ✓ is a live call site; ✓* is reached
only transitively, through the library calling it on the host's behalf; — is absent; **dec.** is a
decline the host has written down.

| Surface | AbsorbTracker | BankLedger | ConsumableMaster | KickCD |
|---|---|---|---|---|
| Options `RenderRows` | ✓ | ✓* via `RenderSchema` | **dec.** | ✓ |
| Options `RenderGrid` | ✓ | — (stub only) | ✓ | **dec.** |
| Options the four makers (via `RenderField`) | ✓ | ✓ | ✓ | ✓ |
| Options `LSMValues` | ✓ | **dec.** | ✓ | ✓ |
| Options `SetRenderer` | **dec.** | ✓ | ✓ | ✓* |
| Options `RefreshAllPanels` | ✓ | ✓ | ✓ | ✓ |
| Options `RefreshScalars` | **dec.** | ✓ | ✓ | ✓* |
| Options the page registry | ✓ | ✓ | **dec.** | ✓ |
| Options `CreatePanel` canvas contract (minor 5) | ✓ unasserted | ✓ asserted | ✓ unasserted | ✓ unasserted |
| Options numeric-enum dropdown (minor 5) | — | ✓ | — | — |
| Options `InlineButtonPair` | ✓ | **dec.** | — | ✓ |
| Options `RestoreAllDefaults` | ✓ | **dec.** | — | ✓ |
| Options `PatchAlwaysShowScrollbar` | — (stub) | — | — (rebound, never called) | ✓ |
| Slash the dispatcher | ✓ | ✓ | ✓ | ✓ |
| Slash `HelpRows` | ✓* | ✓* | ✓* | ✓* |
| Slash `LandingRows` | ✓ | ✓ | **declined, unrecorded** | ✓ |
| Slash `CliList` | ✓ | ✓ | ✓ | ✓ |
| Slash `CliGet` | ✓ | ✓ | ✓ | ✓ |
| Slash `CliSet` | ✓ | ✓ | ✓ | ✓ |
| Slash `CliReset` | ✓ | ✓ | ✓ | ✓ |
| Slash `CliResetAll` | — (own body) | ✓ | **dec.** | — (own body) |
| Slash `lib.FormatRow` called directly | ✓ | — | — | — |
| Slash `FormatValue` / `ParseValue` direct | ✓ | ✓ | — | ✓ |
| Slash `SetRowAnnotator` | ✓ | — | — | — (stub only) |
| Slash `BuildListLines` | — | ✓ | — | — |
| Slash `CliVersion` | — | ✓ | — | — (stub only) |
| Slash `format` descriptor field (minor 5) | — | ✓ | — | — |
| Core the printer | ✓ | ✓ | ✓ | ✓ |
| Core `SafeToString` | ✓ | ✓ | ✓ | ✓ |
| Core `SKIN` / `ApplySkin` | **dec.** | **dec.** | **dec.** | **dec.** |
| Core `MakeCloseButton` | ✓* via DebugLog | **dec.** | ✓* via DebugLog | ✓* via DebugLog |
| DebugLog `applySkin` (minor 4) | — | ✓ | — | — |
| DebugLog `makeCloseButton` (minor 4) | — | ✓ | — | — |
| OptionsWidgets `sliderCommit` | — | — | ✓ | — |
| Host DebugLog file | deleted | deleted (357 lines) | survives as a 208-line seam | deleted (518 lines) |
| Host Perf file | deleted; 130-line seam | n/a — never had one, declined | 103-line descriptor | never had one; 218-line seam |

Depth is high and the declines are the interesting part. Every host takes all four schema-CLI verbs,
so the "hosts routinely take three of the four" pattern the method warns about does not appear once
in this collection. Core's window chrome is declined by all four in writing, which per the method
scores as faithful adoption rather than shortfall — but the net effect is that four of Core's public
members are dead in the field at the same moment DebugLog minor 4 grew an escape hatch from them
(§5, §10). The Options page registry and the two-tier refresh split the collection: no single
consumer's suite covers both halves, and the two hosts differ per surface.

The `CreatePanel` row deserves reading twice. Options minor 5 stamps `OnCommit`/`OnRefresh`/
`OnDefault` on every panel unconditionally, so all four consumers silently gained a working Blizzard
footer Defaults control they never asked for and three of them have no assertion on it anywhere,
tests included. One guard covers a surface with four beneficiaries (§5, §10).

**Single-consumer surfaces.** BankLedger only: `applySkin`, `makeCloseButton`, the `format` hook,
the numeric-enum dropdown, `BuildListLines`, `CliResetAll`, `CliVersion`, `O.__panels`. AbsorbTracker
only: direct `lib.FormatRow`, `SetRowAnnotator`. ConsumableMaster only: `sliderCommit`. KickCD only:
`PatchAlwaysShowScrollbar` — the sole public function of an entire vendored file, `OptionsScroll.lua`.
That all four v1.2.0 additions have the same single consumer, and that it is the host they were made
for, is the run's second high-severity finding: the library grew four contracts in one release
against one host's shape, and three of them cannot interact in any shipping combination (§10).

**Zero-consumer surfaces.** `lib.FormatKV`, `lib.MAX_BUFFER`, `lib.SECRET` read directly,
`Sl:HelpHeader`, `Sl:HelpRows` called by name, `D:LastLine`, `O.__pages`, the `skin` descriptor
field, the `ring` descriptor field, and Core's `SKIN` / `ApplySkin` / `MakeCloseButton` as direct
host calls. `HelpRows` is the notable one: every host reaches it through `PrintHelp`, so the
indented half of the row-formatter pair has no caller anywhere outside the library (§10).

## Convergence state

| Convergence | AbsorbTracker | BankLedger | ConsumableMaster | KickCD |
|---|---|---|---|---|
| #1 `reset` takes a path, not a page | adopted — `settings/Slash.lua:159` | adopted — `settings/Slash.lua:221`, LEDGER LIBKA0S-10 | adopted — `core/SlashCommands.lua:1360`, LEDGER LIBKA0S-12 + CHANGELOG | adopted — `settings/Slash.lua:189` |
| #2 landing rows through the one formatter | adopted — `settings/About.lua:93` | adopted — `settings/Panel.lua:356`, LEDGER LIBKA0S-11 | **declined, unrecorded** | adopted — `settings/Panel.lua:531` |

Convergence #1 is four for four, and the one decline the earlier run found — ConsumableMaster's
`/cm reset` as a confirm-gated global wipe, with the word "reset" appearing nowhere in its ledger —
is now converged and recorded twice over, with the destructive path re-homed to `/cm resetall`
carrying the same dialog and the same body, and `USAGE_RESET` overridden so a bare `/cm reset`
answers loudly rather than silently doing something else (§6).

Convergence #2 is where this run disagrees with both the earlier bundle and the prompt.
`docs/adoption/2026-08-01/03_DEVIATIONS.md` §4 recorded ConsumableMaster as **not applicable**,
reasoning from a grep of `settings/` for `COMMANDS` that returns nothing, and
`docs/adoption-prompt.md:438-446` has since been amended to use that as its worked example of "not
applicable is not declined". Both statements are individually true and the conclusion is false: the
landing page reaches its command rows through `KCM.SlashCommands.GetCommandSummary()`, a name that
grep never sees. `settings/Panel.lua:770` installs `Helpers.BuildAboutContent` as the renderer for
the panel `/cm config` opens, and `:718-729` formats each row itself —
`|cffffff00/cm %s|r␠␠|cffffffff—|r␠␠%s`, confirmed against the library's `Slash.lua:69` with `od -c`:
two spaces either side of the em dash against one, the dash white-wrapped against bare, the
description bare against wrapped. The chat half is already `lib.FormatRow`, pinned byte-for-byte at
`tests/test_slashsetup.lua:57`. That is the two-divergent-formatters state the convergence exists to
collapse, and `git log -L 718,729:settings/Panel.lua` shows the formatter arriving in f844f78, before
the adoption, so it was never revisited rather than weighed and kept. Nothing in the ledger, the
CHANGELOG or the README records a decision (§6). The correction cuts both ways: the consumer has an
undocumented decline, and the library's own artefacts now assert it has nothing to document.

## The green gate

| Repo | `lua tests/run.lua` | `luacheck .` | Files linted | Cross-checks |
|---|---|---|---|---|
| LibKa0s (ship) | 407 passed, 0 failed | 0 warnings / 0 errors | 11 | `docs/test-cases.md` Totals = 407; no README badge to drift |
| AbsorbTracker | 462 passed, 0 failed | 0 warnings / 0 errors | 28 | test-cases 462, README badge 462/462, prompt quotes 462 |
| BankLedger | 684 passed, 0 failed | 0 warnings / 0 errors | 24 | test-cases 684, README badge 684/684; **absent from the prompt** |
| ConsumableMaster | 554 passed, 0 failed | 0 warnings / 0 errors | 50 | test-cases 554, README badge 554/554, prompt quotes 554 |
| KickCD | 643 passed, 0 failed | 0 warnings / 0 errors | 32 | test-cases 643, README badge 643/643, prompt quotes 643 |

Green everywhere, with nothing to attribute: there are no warnings in any repo, so none inside the
five seam files (which would be an adoption defect) and none outside them (which would be
pre-existing host hygiene). KickCD's seven warnings from the earlier run are gone (§8).

The additive-change proof holds and was checked rather than asserted. AbsorbTracker is at 462, the
figure `docs/adoption-prompt.md:538` quotes; its total moved from the earlier run's 449 entirely on
its own new cases, committed before the four re-vendor commits, and stayed at 462 across them.
KickCD and ConsumableMaster are unmoved at 643 and 554. What the proof no longer covers is
BankLedger: its 684 cases are the only ones anywhere that exercise the four surfaces v1.2.0 added,
and step 8 does not tell a future library author to run them (§8, §10).

Every luacheck figure is scoped by an `exclude_files` rule and should be read that way. The ship
repo's 11 files are the eight ship files plus three under `testkit/`; the twenty-one files under
`tests/` — the whole suite, the fixtures, `wow_mock.lua` and the vendored `tests/_kit/` copies — are
never linted. Consumers exclude `libs/` and, variously, `tests/`. Excluding vendored code is correct
practice, since it is not the host's code to lint, but "0 warnings / 0 errors" as quoted in
`docs/releasing.md:17` and `docs/adoption-prompt.md:564` reads as repo-wide and is not (§8).

## What these tables do not cover

Nothing here observes a running WoW client. The footer Defaults control that all four consumers
gained this release, DebugLog's derived title-bar offsets, BankLedger's console wearing its own
chrome, the two numeric rows drawing as dropdowns, the converged landing-row spacing, colour
rendering and the on-screen half of the `L` trap are all invisible to a headless suite. No
consumer's `docs/smoke-tests.md` was executed. No assertion anywhere was mutation-verified, because
that would require editing a repo and this audit is read-only; where a ledger claims mutation
verification, the claim was read and not reproduced. The degraded-install path was exercised only
where a host's own suite does it. And no consumer failed to run — all four suites and all four lint
passes completed, so nothing in the green-gate table is a gap dressed as a pass.
