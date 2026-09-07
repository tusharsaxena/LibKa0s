# 05 — Final summary

> **Status: forward-looking.** This document is written under the assumption that every change in
> `02_PROPOSED_CHANGES.md` was implemented per `04_EXECUTION_PLAN.md` and every check in
> `03_SMOKE_TESTS.md` passed. As of the review date (2026-09-07) **nothing has been implemented** —
> the review pass was observe-and-record only. Fill in the bracketed figures at implementation time;
> do not carry a bracket into a PR description.

---

## Headline

LibKa0s' settings-panel tab strip — the surface `options-ui-§13` made mandatory across the whole
collection three weeks ago — was rebuilding every tab button and its content panel from scratch on
every click and throwing the old ones away. WoW cannot reclaim a frame, so each click leaked one
frame per tab, permanently, in nine addons. This cycle pools them, and while it was in there it
consolidated the library's **three** competing widget-release implementations onto the one
`LibKa0s-Pool-1.0` module that exists for exactly that purpose. Alongside it, two gates that had been
reporting green over a narrower slice than their names implied were widened — the line-ending gate
now covers the whole repository instead of one directory, and immediately found seven files that had
been violating the CRLF pin, two of them shipped library source vendored into every consumer — and
the standing automated-test record, whose hand-written half had drifted a month out of date while
claiming to be generated, was restructured so it can no longer say the suite has 499 cases when it has
768.

---

## Counts

```
Critical fixed: 0   (none raised)
High     fixed: 1   F-001
Medium   fixed: 7   F-002 F-003 F-004 F-005 F-006 F-007 F-008 F-009   [8 raised, see deferrals]
Low      fixed: 4   F-010 F-011 F-012 F-013
Upstream filed: 2   F-014 F-015  (WowAddonStandards — not this repo)
```

**Deferred, with reason:**

- **F-015 / C-8** — `LibKa0s/OptionsWidgets.lua` at 1838 LOC. Deferred pending the upstream ruling
  (F-015/U-2) on whether `layout-§1`'s 1500-LOC cap binds a library's ship folder. Peeling a 690-line
  block on a guess is how a review manufactures work the standard never asked for. Resolution is a
  `CLAUDE.md` deviation row or a fifth Options file, and it is decided upstream first.
- **F-009 / C-5** — if the newly-linted test tree produced a large warning backlog, only the
  `.luacheckrc` scope change shipped and the backlog was split into its own follow-up. Record which
  happened.

---

## Changes by theme

### Theme A — Stop constructing frames the client can never reclaim

**What changed.** The tab strip and the page's content panel now acquire their frames from a
per-page pool and give them back on re-render, instead of calling `CreateFrame` on every click.
`makeTab` split into a construction half and a dressing half so a reused button is fully re-stated —
label, measured width, selection atlas, and a fresh `OnClick` closure pointing at the *current*
`onSelect`. Separately, `Widgets.lua`'s reorder-list handle and box pools, which had been a third
hand-rolled implementation of the same idea, moved onto `LibKa0s-Pool-1.0`.

**Why it mattered.** WoW frames are permanent — an unparented frame stays in the client's frame list
for the session, still holding its handler closure and everything that closure captured. A
thirteen-tab page leaked fourteen frames per click. The strip is mandatory on every page of every
consumer, so this was collection-wide and grew with ordinary use.

**Findings covered:** F-001, F-005. **Changes:** C-1, C-2.

**Files touched**
- `LibKa0s/OptionsWidgets.lua`
- `LibKa0s/Widgets.lua`
- `tests/test_options_widgets.lua`
- `docs/api/Options/version-14.14.2.3-docs.md` *(new)*
- `docs/api/Widgets/version-10-docs.md` *(new)*

### Theme B — Make the standing evidence say what was measured

**What changed.** `docs/automated-tests/RESULTS.md` was reduced to the parts the runner actually
writes — the header, the reading rules, the trend table. Its four narrative sections moved into the
newest bundle's frozen, dated `ANALYSIS.md`, corrected against fresh numbers, with a complexity watch
list that names the real ceiling. `docs/releasing.md` now requires a clean tree for the release
battery, and the runner renders the Version cell as `<version> → <release>` on a release run.

**Why it mattered.** The file carried a banner reading "generated, never hand-edited" over a body
that was half hand-written, so it rotted invisibly: it claimed 499 cases against 764, twelve linted
files against eighteen, eight shipped library files against fourteen, and — flatly — "Nothing is over
the 1500 cap" while its own manifest recorded `overCapFiles: 2`. This is the artefact reviews and
audits are instructed to cite.

**Findings covered:** F-002, F-003, F-012, F-013. **Changes:** C-3, C-9 (partial).

**Files touched**
- `docs/automated-tests/RESULTS.md`
- `docs/automated-tests/<new-stamp>/ANALYSIS.md` *(new)*
- `docs/releasing.md`
- `testkit/run-automated-tests.sh`, `testkit/framework.lua`
- `tests/_kit/` *(whole-folder re-vendor, own commit)*
- `docs/api/testkit/version-15-docs.md` *(new)*

### Theme C — One diagnostic policy across the Options major

**What changed.** The Options shell's chat sink is now built once per instance and handed to the
widget layer, instead of the widget layer deriving a second, silently-discarding one from the same
descriptor field. And a composed reset button whose handler the host forgot now says so at build time
rather than looking live and doing nothing.

**Why it mattered.** The major's stated policy is *report the authoring defect, render anyway*. Two
seams did not follow it, and they were the two that mattered most: an ungrouped page under a mandatory
strip, and a `string` row that draws as an empty dropdown, were exactly the diagnostics being thrown
away.

**Findings covered:** F-006, F-008. **Changes:** C-6, C-7.

**Files touched**
- `LibKa0s/Options.lua`
- `LibKa0s/OptionsWidgets.lua`
- `tests/test_options_widgets.lua`, `tests/test_options_compose.lua`

### Theme D — Widen the two gates that were narrower than their names

**What changed.** `tests/test_eol.lua` dropped its `docs/automated-tests/` path filter and now asks
git about every tracked file. It went red on seven, which were repaired in the same change.
`.luacheckrc`'s exclusion narrowed from all of `tests/` to just the vendored `tests/_kit/` copy, so
the larger half of the tree is linted for the first time.

**Why it mattered.** Both produced a green number over a subset the number's reader would take for
the whole. Two shipped library files — `DebugLog.lua` and `Pool.lua` — had been vendoring into every
consumer's client-bound `libs/` with the wrong line terminator, and nothing in the collection could
see it, because the index blob is correct either way and `git status` stays silent.

**Findings covered:** F-004, F-009. **Changes:** C-4, C-5.

**Files touched**
- `tests/test_eol.lua`, `.luacheckrc`
- `LibKa0s/DebugLog.lua`, `LibKa0s/Pool.lua` *(bytes only — see the migration note below)*
- `tests/test_debuglog.lua`, `tests/test_pool.lua`
- `docs/api/Options/version-8.7.3-docs.md`, `docs/api/Options/version-9.7.3-docs.md`, `docs/api/testkit/version-12-docs.md`
- `tests/*.lua` *(lint fixes)*

### Theme E — Perf bracket honesty

**What changed.** `P.Open` reuses its slot from a high-water free list instead of allocating a table
per bracket, and the docstring — which was already scrupulously honest about Shape B's cost when the
probe is off — now states the capture-arm cost too. A headless case pins it, beside the dormant one
that has been green since the same defect was found on the other path.

**Why it mattered.** The chosen shape's stated justification for rejecting a closure-returning
`Bracket(key)` was that a closure would allocate; the shape that replaced it then allocated a table.
Only the `active` arm of a two-arm capture pays it, so it biases the frame-time delta in a known
direction — a delta the standard already says is unresolved below the harness's own spread.

**Findings covered:** F-007. **Changes:** C-10.

**Files touched**
- `LibKa0s/Perf.lua`, `docs/record-schema.md`, `tests/test_perf_isolation.lua`

### Theme F — Documentation currency

**What changed.** The standards pointer in `CLAUDE.md` and `README.md` moved off v2.28.0 onto the
version published by the upstream pass. `tests/run.lua` gained one comment naming
`Kit.assertSuiteInventory` as what keeps its hand-typed suite list honest beside its correctly-derived
load list.

**Why it mattered.** The pointer named a standard predating `options-ui-§13`, `§15`, `§16`, `§17` and
`§18` — the five rules the entire settings-revamp-v2 branch was written to implement and which
`OptionsCompose.lua` cites by number throughout.

**Findings covered:** F-010, F-011. **Changes:** C-9.

**Files touched:** `CLAUDE.md`, `README.md`, `tests/run.lua`.

---

## API / behaviour changes

**No public contract was removed or renamed.** Every change is behavioural-internal or additive.

| Surface | Change | Consumer action |
|---|---|---|
| `O.TabStrip` | Returns the same button array; the buttons are now pooled and reused across renders | **None**, unless a host cached a button table across renders — that was never supported and is now visibly wrong |
| `O.InlineButtonPair` | A spec with no `onClick` is now reported once at build time | Fix the missing handler; the button still draws |
| `O.MasterControls` | Unchanged signature. A host omitting `onResetAll`/`onResetPosition` now sees a chat line | As above |
| `lib.STRINGS.DEAD_BUTTON` | **New** string | None — library-owned, deliberately untranslated |
| `P.Open` / `P.Close` | Unchanged signature and semantics; the slot is pooled | None |
| `descriptor.print` | Now type-checked at the widget layer as it always was at the shell, and its absence falls back to `DEFAULT_CHAT_FRAME` in **both** | None; a host passing a non-function `print` now gets it ignored rather than a raise |

**LibStub minors moved** (the load-bearing number — a released change that forgets its bump silently
does not reach a host holding the old copy):

| File | Before | After |
|---|---|---|
| `LibKa0s/OptionsWidgets.lua` | 14 (13 at review) | 15 |
| `LibKa0s/Options.lua` | 14 | 15 |
| `LibKa0s/Widgets.lua` | 9 | 10 |
| `LibKa0s/Perf.lua` | 7 | 8 |
| kit revision | 14 | 15 |

**Deliberately NOT bumped:** `LibKa0s/DebugLog.lua` (12) and `LibKa0s/Pool.lua` (3). Their bytes
changed — LF to CRLF — and their content did not. A line terminator is not a released change, and a
spurious bump would make LibStub prefer a copy differing from its predecessor in nothing.

**No slash commands** exist here to add or rename; **no locale keys** — a library ships no `locales/`.

---

## Saved-variable / migration notes

**None.** LibKa0s persists nothing of its own. `LibKa0s-Perf-1.0` writes through a global whose name
the host's descriptor supplies (`sv`), and neither its record shape (`docs/record-schema.md`) nor its
key set changed. No `schemaVersion` moved anywhere; no user profile needs migrating; no consumer needs
a `/<host> reset`.

Consumers do need a **re-vendor**: copy the whole `LibKa0s/` folder into `libs/LibKa0s/`, copy
`testkit/` into `tests/_kit/`, and move the provenance line in the host's root `CLAUDE.md` to the new
tag in the same commit — each consumer's `tests/test_vendor_sync.lua` resolves that tag and diffs both
payloads against it.

---

## Deprecated-API migrations

**None.** The review swept the shipped library for the current deprecation set and found no live use:
`GetSpellInfo`, `GetItemInfo`, `IsAddOnLoaded`/`LoadAddOn`/`GetAddOnInfo`, `UnitAura`/`UnitBuff`/
`UnitDebuff`, `C_Container`'s predecessors, and `InterfaceOptions_AddCategory` are all absent.

Two things were checked and are already correct, and are recorded here so the next reviewer does not
re-derive them:

| Old API | Current usage | Where |
|---|---|---|
| `GetAddOnMetadata` | `C_AddOns.GetAddOnMetadata` **first**, with the bare global only as a fallback | `LibKa0s/Env.lua:60-66` |
| `SetBackdrop` without `BackdropTemplate` | Every backdropped frame is created with the `"BackdropTemplate"` inherit, and `ApplySkin` no-ops on a frame lacking `SetBackdrop` | `LibKa0s/Core.lua:120-191`, `LibKa0s/DebugLog.lua:409`, `LibKa0s/PerfPanel.lua:156`, `LibKa0s/Widgets.lua:180/295/489` |

Settings registration is via `Settings.RegisterCanvasLayoutCategory` + `Settings.OpenToCategory` with
a `mainCategoryID`, not a frame handle — the 10.0 return-value trap is already avoided
(`LibKa0s/Options.lua:895-907`).

---

## Performance impact

**Measured numbers only. Fill from the records named; do not estimate.**

| Metric | Record | Before | After |
|---|---|---|---|
| Frames created per full tab sweep (8-tab page, 10 sweeps) | `03_SMOKE_TESTS.md` C-1, in-client frame count | *[N1−N0]* | *[N1−N0]* |
| Heap growth, 10k dormant `Open`/`Close` | `tests/test_perf_isolation.lua:66`, green today | < 1 KB | < 1 KB *(unchanged — this path was already free)* |
| Heap growth, 10k **active** `Open`/`Close` | new case, `tests/test_perf_isolation.lua` | *[KB]* | *[KB]* |
| Per-bucket `calls` / `totalMs` / `maxMs` | consumer's `docs/perf-analysis/<stamp>/dump.json` | *[stamp]* | *[stamp]* |

Read the bucket figures, **not** `fps.deltaMsPerFrame` — the standard states that delta is unresolved
below the harness's measured run-to-run spread, and F-007 is a small bias in exactly that number. Both
captures must come from the same client, the same host version and the same addon set, or they are not
comparable.

No offline scenario numbers appear here: this repo ships no `tests/perf.lua`, by a dated decision
recorded in `docs/automated-tests/README.md`, and the zero-overhead evidence lives in the gated suite
instead.

---

## Test and complexity movement

| | Before (measured 2026-09-07) | After |
|---|---|---|
| Passing / total | **764 / 764** | *[~772 / ~772]* |
| Suites | 22 | 22 |
| Lint | 0 warnings / 0 errors over **18** files | 0 / 0 over *[~40]* files |
| `lizard` warnings | **0** | 0 *(release gate: zero functions above CCN 15)* |
| Max CCN | **14** — `drawContentPanel@LibKa0s/OptionsWidgets.lua:643-677` | *[expected to fall]* |
| Files over `layout-§1`'s 1500 cap | **2** — `LibKa0s/OptionsWidgets.lua` 1838, `tests/test_options_widgets.lua` 2287 | *[unchanged unless C-8 ran]* |

`docs/test-cases.md` moved in the **same change** as every count movement and every case rename
(`testing-§5`). This repo carries no README `[tests]` badge — `documentation-§1`'s badge row does not
bind a library repo (`library-stack-§7`).

**Watch-list entries these changes are expected to move**, to be confirmed by the next release's
regeneration and **not** regenerated here:

- `drawContentPanel` should fall well below CCN 14 once the frame-construction half moves into
  `newTabButton` — a genuine removal of decisions, not a relocation.
- `tests/test_options_widgets.lua` grows by ~6 cases and moves further past 1500. If C-8 ran, the
  suite splits with the source it covers.
- `Kit.run`'s old watch-list entry (`testkit/framework.lua:394-433`, CCN 14) is retired — it is now
  `:668-695` at CCN 10, and the refreshed list should say so rather than carrying the stale row.

---

## Known follow-ups

| Item | Why deferred |
|---|---|
| **F-015 / C-8** — `OptionsWidgets.lua` at 1838 LOC | Blocked on the upstream ruling (U-2) on whether `layout-§1`'s cap binds a library ship folder. Peeling 690 lines on a guess is worse than waiting. |
| **`tests/test_options_widgets.lua` at 2287 LOC** | Same ruling. Its peel seam is obvious (split by widget family) and its length is case count rather than tangle, so it is a deliberate hold, not an oversight. |
| **A `Kit.VERSION`-aware consumer sweep** | Nine consumers now hold kit revision 14 or older. Which one is on what is answerable (`Kit.VERSION` exists for exactly this) but the sweep is its own pass, not this one's. |
| **Lint backlog in `tests/`** | If the widened `.luacheckrc` surfaced more than a handful of warnings, they ship as their own commit — mixing them into the pooling work would bury a real change in noise. |
| **`docs/adoption-report.md` currency** | Not touched or verified by this review. It claims which consumer has adopted which major; nothing here checks it and it is the kind of table that rots. |
| **No `ANALYSIS.md` on several bundles** | `20260903-161751` among them, including the newest before this cycle. Backfilling frozen analysis for past runs is not sanctioned — a bundle is frozen — so the gap stands as history. |

---

## Verification evidence

- **Smoke tests:** `docs/reviews/2026-09-07/03_SMOKE_TESTS.md`, sign-off table completed, run in a
  consumer with the re-vendored payload (LibKa0s has no install of its own).
- **In-game perf capture:** frozen as `docs/perf-analysis/<stamp>/` **in the consumer addon** that
  produced it — `report.md`, verbatim `dump.json`, and that capture's `ANALYSIS.md`.
- **Out-of-game battery:** `docs/automated-tests/<new-stamp>/` in this repo, with `RESULTS.md`'s
  newest row and `manifest.json`'s clean-tree SHA.
- **Commit range / PR:** *[fill in]*
- **Findings this work answers:** `docs/reviews/2026-09-07/01_FINDINGS.md`.

---

## Suggested commit message / PR description

```
LibKa0s v1.26.0: pool the tab strip, widen two gates, unrot the record

The settings-panel tab strip rebuilt every button and its content panel with
CreateFrame on each click and dropped the old ones. WoW cannot reclaim a frame,
so a thirteen-tab page leaked fourteen frames per click, in nine addons, for the
whole session. Both are now pooled through LibKa0s-Pool-1.0 — the module this
repo extracted for exactly this and had not adopted itself. Widgets.lua's
reorder-list pools, a third implementation of the same idea, move onto it too.

Two gates were narrower than their names. test_eol.lua asked git about one
directory; widened to the tracked tree it went red on seven files that had been
violating the CRLF pin, two of them shipped library source vendored into every
consumer. .luacheckrc excluded all of tests/, so the larger half of the repo had
never been linted; it now excludes only the byte-identical tests/_kit/ copy.

RESULTS.md carried a "generated, never hand-edited" banner over a body that was
half hand-written, and had drifted a month: 499 cases against 764, twelve linted
files against eighteen, and "Nothing is over the 1500 cap" while its own manifest
recorded overCapFiles: 2. The narrative moves to a frozen, dated ANALYSIS.md; the
generated file is now only what the runner writes.

Also: the Options major's chat sink is built once per instance instead of twice
with two different fallbacks, one of which discarded every line; a composed reset
button with no handler reports instead of looking live and doing nothing; and
P.Open reuses its bracket slot rather than allocating a table per open in the
capture arm.

Findings: F-001 (High) · F-002 F-003 F-004 F-005 F-006 F-007 F-008 F-009 (Medium)
          F-010 F-011 F-012 F-013 (Low)
Deferred: F-015 (OptionsWidgets.lua 1838 LOC) — blocked on a standards ruling.
Upstream: F-014, F-015 filed against tusharsaxena/WowAddonStandards.

Minors: Options 15, OptionsWidgets 15, Widgets 10, Perf 8, kit revision 15.
DebugLog and Pool change bytes only (LF→CRLF) and deliberately do NOT bump.

Tests 764 → [N]. Lint 0/0 over [N] files. lizard 0 warnings.
Consumers: re-vendor LibKa0s/ and testkit/ whole, and move the provenance line
to v1.26.0 in the same commit.

Review: docs/reviews/2026-09-07/
```
