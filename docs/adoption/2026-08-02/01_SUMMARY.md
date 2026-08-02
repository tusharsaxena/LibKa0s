# Adoption report — 2026-08-02

Run against LibKa0s at **v1.5.0** — Core 3, DebugLog 7, Slash 5, Options 5, OptionsWidgets 5,
OptionsScroll 2, Perf 5, PerfPanel 3, each read out of the ship folder rather than out of the
changelog. Method: `docs/adoption-report.md`.

This is the first run since **2026-08-01 (run v2)**, and the first with the consumer set complete:
`WhatGroup` landed on 2026-08-02 as the eighth adopter, and `docs/adoption-prompt.md` now records
no remaining targets. Four consumers have been added since the last run (LootHistory, PanelMaster,
prettychat, WhatGroup), the library has moved v1.2.0 → v1.5.0, and Core and DebugLog have both
taken minor bumps. Nothing below is inherited from the previous bundle; every figure was
re-established from evidence, including the ones that have not moved.

## Verdict

**The mechanical half is clean in every dimension this report can measure, across twice the
consumers of the last run.** Sixty-four of sixty-four file-minor cells — eight files across eight
consumers — sit at the current ship minors. There is no cross-major skew anywhere, which is the
single most serious thing this report can find and the failure mode whole-folder vendoring exists to
prevent. That figure is worth stating plainly because DebugLog minor 7 was cut *during* the WhatGroup
adoption and had to reach seven already-adopted hosts to be correct; it reached all seven.

All thirty-two vendor diffs are empty on both readings, byte and content, for both the library and
the test kit. Nothing has forked, and — unlike the 2026-08-01 v1 run — there is no line-ending
divergence anywhere to adjudicate. Every consumer's gate actually runs green: 469, 687, 561, 648,
534, 609, 255 and 415 cases, zero failures, and 0 warnings / 0 errors from `luacheck` in all eight
repos plus this one. All 4,197 cases were run for this report, not quoted.

**The previous run's headline finding is fully closed.** It found four published addons naming a
release that did not resolve to a git ref. Today `git describe --tags` reads `v1.5.0` exactly, the
tag points at HEAD, `git diff v1.5.0 -- LibKa0s testkit` is empty, and all eight consumers carry a
README provenance line naming v1.5.0 — so every one of those lines is not merely present but
*true*, and checkable by a stranger with one command. Every consumer also carries `LICENSE` inside
`libs/LibKa0s/`, proving a whole-folder copy in all eight.

**`L`-trap guard coverage is 35 / 35 module-adoptions — the first complete sweep in the series.**
Every adopted major in every consumer carries either a rendered assertion or, for Core and Options
which cannot express the trap, the library tripwire that stands in for one. The v2 run found this
paragraph in the prompt claiming three consumers carried an Options substitute when none did; four
consumers have been added since and all four arrived carrying both tripwires. Both user-visible
convergences are **adopted** by all eight consumers, and every one is recorded in the host's own
`docs/pending/LEDGER.md`.

**What this run found instead is that the library's map of its own provisional surfaces is now wrong
in three places, and wrong in both directions.** `docs/adoption-prompt.md`'s "Provisional surfaces"
section is the document a new adopter reads to learn which contracts are unsettled, and it is stale:

- **`makeCloseButton` (DebugLog minor 4) now has *zero* consumers.** It was added for BankLedger;
  BankLedger and LootHistory have each since dropped it deliberately, with a rationale written into
  both seam files, once Core minor 3 made the Ka0s edge the library's own default. A surface with
  one consumer is a finding because its contract has been tested against exactly one shape. A
  surface with **none** is a different and quieter thing: live code on the `-1.0` contract, frozen
  against removal, whose override path no shipped addon exercises. It is well covered by the
  library's own suite (six cases), so this is a question about whether it should still be in the
  contract, not a correctness defect.
- **`applySkin` and the numeric-enum dropdown are no longer single-consumer** — two each — so the
  section overstates the risk on both, and understates how much was learned. The prompt still reads
  "One implementation behind them."
- **The `format` × `colorDecode` precedence is still unexercised**, and this run can now say *why*
  it is likely to stay that way: the three hosts passing `format` (BankLedger, LootHistory,
  prettychat) and the three passing colour codecs (AbsorbTracker, ConsumableMaster, KickCD) are
  **disjoint sets**, with no overlap and no host near the boundary. Documented-but-unexecuted
  ordering inside a frozen major does not improve by waiting.

The remaining findings are bookkeeping in documents that are otherwise current: four suite totals
quoted in the prompt as the proof that a library change was additive have each drifted by +2 and now
understate every one, and the prompt's consumer-suite list names four hosts where there are eight.
That list is read by a library author deciding which suites to re-run, so its being half the true
length is the one stale figure here with a mechanism behind it.

## Confidence

| Consumer | Grade | Why |
|---|---|---|
| AbsorbTracker | **High** | All 8 minors current; both diffs empty; 469 green, luacheck 0/0; all five majors wired with guards on every one (`tests/test_ltrap.lua` is the reference implementation); both convergences adopted and recorded; provenance true. |
| BankLedger | **High** | 8/8 current; diffs empty; 687 green, 0/0; four majors, Perf declined at `LIBKA0S-17` with reasons; deepest schema-CLI adoption in the set; both convergences adopted and recorded. |
| ConsumableMaster | **High** | 8/8 current; diffs empty; 561 green, 0/0; five majors; the v1-run finding (an unrecorded `reset` convergence) is closed at `LIBKA0S-12`/`-13`; descriptor `L` is a plain table with a comment explaining each override's arity. |
| KickCD | **High** | 8/8 current; diffs empty; 648 green, 0/0; five majors; carries the only `L = NS.L and { … } or nil` in the set — the legitimate form, and it has its own guard case driving all three spellings. |
| LootHistory | **High** | 8/8 current; diffs empty; 534 green, 0/0; four majors, Perf declined twice over at `LIBKA0S-17`; second host on `applySkin` and on the `format` hook; both tripwires present. |
| PanelMaster | **High** | 8/8 current; diffs empty; 609 green, 0/0; four majors, Perf declined at `LIBKA0S-31`; 34 ledger rows; first host to pass a descriptor `L` and to wrap instance members. |
| prettychat | **High** | 8/8 current; diffs empty; 255 green, 0/0; four majors, Perf declined at `LIBKA0S-12`; only host passing `sep = ""` and `pairWith`; both tripwires present. |
| WhatGroup | **High** | 8/8 current; diffs empty; 415 green, 0/0; four majors, Perf declined at `LIBKA0S-15`; drove DebugLog minor 7; both tripwires present, and its descriptor `L` is a one-key plain table with a case proving the override took *and* that nothing else was overridden. |

No consumer grades below High. Under this report's own rule — *if this consumer had silently
diverged, would anything in its own repo have caught it?* — every one of the eight would now be
caught by its own `test_vendor_sync.lua`, which asserts the vendored folder against the release the
README claims. That test exists in all eight and is the reason this run found no drift to report.

## Findings, ranked

| # | Severity | Finding |
|---|---|---|
| 1 | Medium | `makeCloseButton` (DebugLog minor 4) has **zero** shipped consumers — both hosts that once passed it have deliberately dropped it. `03_DEVIATIONS.md` §1. |
| 2 | Medium | `docs/adoption-prompt.md` §"Provisional surfaces" is stale in three entries, in both directions; it is the document a new adopter reads to learn what is unsettled. §2. |
| 3 | Medium | The prompt's additive-change proof names **four** consumer suites where there are eight, and all four totals are stale by +2. A library author following it re-runs half the fleet. §3. |
| 4 | Low | No shipped addon executes the `format` × `colorDecode` precedence — the two host sets are disjoint, so it will not resolve on its own. (This finding originally added "and no test pins it", which was false; see the correction in §4.) |
| 5 | Low | `sliderCommit`, `pairWith` and `sep` each have exactly one consumer; `skin` joins `makeCloseButton` at zero. §5. |
| 6 | Low | Two provenance lines (LootHistory, WhatGroup) are phrased mid-sentence rather than as the templated standalone sentence. Both are true and both are found by the `[Bb]undles` gate; noted so the next sweep does not read it as drift. §6. |

## What this report did not check

- **Anything in-game.** Every claim here is headless. Colour codecs, widget dispatch, `hasAlpha`,
  panel layout, the suspended arm and the `L` trap's on-screen half are all invisible to this run.
  Each consumer's `docs/smoke-tests.md` is the instrument for those; this report did not execute one.
- **Whether each consumer's `docs/test-cases.md` and `[tests]` badge agree with its suite.** The
  suites were run and their totals recorded; badge parity is a per-repo gate, not this report's.
- **The two `-1.0` majors' behaviour under a host that vendors an older `Core.lua`.** No consumer is
  in that state today, so the degradation path was not exercised by any repo in this sweep beyond
  each host's own library-absent cases.
- **`WhoGotLoots` and `BuffTextNotifications`**, which are out of scope until they are on the
  standard at all, and which correctly hold no `libs/LibKa0s/`.
