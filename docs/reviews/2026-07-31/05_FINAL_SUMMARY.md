# 05 — Final Summary

> **Status: forward-looking.** This document is written on the assumption that every change in
> `02_PROPOSED_CHANGES.md` has been implemented per `04_EXECUTION_PLAN.md` and every test in
> `03_SMOKE_TESTS.md` has passed. Fill in the measured numbers and the commit range as the work
> lands; the narrative is the PR description and the changelog source.

---

## Headline

The five-major extraction is architecturally sound — this pass did not change its shape. What it
changed is the evenness of the discipline across the five. Four of the majors already validated their
descriptors, defaulted their output to the chat frame, and declared a dependency floor so a
half-vendored copy goes **absent** rather than half-wired; `LibKa0s-Options-1.0`, the youngest, did
none of the three, and each omission had a real failure attached — a nil-call crash mid-panel-build
on a partial vendor, a combat refusal that could vanish without a trace, and a `/framestack` frame
name that could silently become nothing. Alongside that, two staleness gaps the paired-minor guards
do not reach were closed (a cross-major function snapshotted at file load; a secondary attaching over
a shell with no declared minimum), the secret-safe seam was made total instead of near-total at its
last two public entry points, two contract bugs in the Options flow engine were fixed, and the one
remaining coupling still enforced by a line in a release doc — the `testkit/` ↔ `tests/_kit/` sync —
became a red suite.

---

## Counts

**Critical fixed: 0 · High fixed: 4 · Medium fixed: 7 · Low fixed: 4 (of 5)**

No Critical findings were raised. The taint model, the secret-safe seam's detector, the per-instance
frame ownership and the `NEEDS_CORE` floors were all already correct before this pass.

| Finding | Severity | Change | Status |
|---|---|---|---|
| F-001 | High | C-1 | Fixed |
| F-002 | High | C-8 | Fixed |
| F-003 | High | C-5 | Fixed |
| F-004 | High | C-3 | Fixed |
| F-005 | Medium | C-2 | Fixed |
| F-006 | Medium | C-6 | Fixed |
| F-007 | Medium | C-8 | Fixed |
| F-008 | Medium | C-7 | Fixed |
| F-009 | Medium | C-7 | Fixed |
| F-010 | Medium | C-4 | Fixed |
| F-011 | Medium | C-10 | Fixed |
| F-012 | Low | C-9 | Fixed |
| F-013 | Low | C-9 | Fixed |
| F-014 | Low | C-9 (M4-T2) | **Deferred if cut** — see Known follow-ups |
| F-015 | Low | C-8 | Fixed |
| F-016 | Low | C-1 | Fixed |

---

## Changes by theme

### Theme A — Options brought up to the discipline the other four majors keep

**What changed.** `LibKa0s-Options-1.0` now validates its descriptor and errors by field name at
`:New` (matching `Perf`'s `required()` helper and `Core`/`DebugLog`/`Slash`'s `error(MAJOR .. ":New
requires …")` form); refuses at `:New` when `OptionsWidgets.lua` did not arrive, naming the missing
file, instead of nil-calling `O.AttachTooltip` on the first panel `OnShow`; defaults its output sink
to the chat frame rather than to a no-op; and treats a second `CreateOptionsPanel()` as a no-op.

**Why it mattered.** Every one of these was a silent failure that surfaced a login later, in the
library's own code, with a stack that pointed at the library rather than at the mis-vendored host.
The `mainPanelName` case is the sharpest: the field exists so `/framestack` can attribute the canvas
to its host and two addons cannot collide, and a nil silently produced an anonymous frame — the
property lost with nothing to say so. `options-ui-§2` also requires the in-combat refusal to print
and forbids a silent no-op, which the discarding default sink could produce.

**Findings covered:** F-001, F-004, F-005, F-010, F-016 · **Changes:** C-1, C-2, C-3, C-4

**Files touched**
- `LibKa0s/Options.lua`
- `LibKa0s/OptionsWidgets.lua` (comment only)
- `tests/test_options.lua`
- `README.md`, `CHANGELOG.md`

### Theme B — The two cross-boundary staleness gaps

**What changed.** `DebugLog` re-exports `MakeCloseButton` as a forwarder that resolves through the
`core` **table** at call time, rather than snapshotting the function value at file load. Every paired
secondary file (`OptionsWidgets.lua`, `OptionsScroll.lua`, `PerfPanel.lua`) now declares a
`NEEDS_SHELL` floor and stays absent below it, mirroring the `NEEDS_CORE` floors on the cross-major
axis.

**Why it mattered.** LibStub upgrades a major **in place**, so a newer `Core.lua` replaces the
function on the shared table — but a `DebugLog.lua` whose own minor did not move returns early and
never re-snapshots. The console then wore the older Core's close button while `lib.MODULES.Core`
reported the newer minor: the exact "which half came from where?" question `library-stack-§7`
requires be answerable at runtime, answered wrongly, silently, and surviving a `/reload`.

**Findings covered:** F-003, F-006 · **Changes:** C-5, C-6

**Files touched**
- `LibKa0s/DebugLog.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/OptionsScroll.lua`, `LibKa0s/PerfPanel.lua`
- `tests/test_debuglog.lua`, `tests/test_versioning.lua`
- `docs/releasing.md`, `CHANGELOG.md`

### Theme C — The secret-safe seam made total

**What changed.** `Slash.FormatValue` routes all five type branches through the concat probe, not
just the fallthrough. `DebugLog:Add` — public, documented as ungated, and the path a host's perf
output takes — now stringifies its message through the same seam the gated `D.Debug` sink already
used.

**Why it mattered.** `events-frames-taint-§8` requires the seam be single and total precisely so no
call site has to reason about where its input came from, and names `string.format` alongside
`table.concat` as a raiser. Both entry points were safe only on an unwritten invariant about their
inputs. The console case is the one with teeth: a raise inside a repeating logger stops the callback
rescheduling and freezes the display until `/reload`.

**Findings covered:** F-008, F-009 · **Changes:** C-7

**Files touched**
- `LibKa0s/Slash.lua`, `LibKa0s/DebugLog.lua`
- `tests/test_slash.lua`, `tests/test_debuglog.lua`, `tests/_kit/mock_base.lua` (secret-value mock)
- `CHANGELOG.md`

### Theme D — The two contract bugs the tests could not see

**What changed.** `O.RestoreDefaults` passes `ctx.unit` to `d.rowsForPage`, the same filter
`O.RenderSchema` renders with. `O.RenderRows` shallow-copies its `afterGroup` / `pairWith` arguments
instead of consuming the caller's tables. A `solo` row is no longer given a `pairWith` partner. The
test fixture's `rowsForPage` widened to `(pageKey, filter)` so the argument is observable at all.

**Why it mattered.** The Defaults button on a per-unit page reset **every** unit's rows while showing
one unit's — the user watched one page revert and silently lost settings on pages they never opened.
And a second render of the same page (a unit switch, or any `ClearScroll` + re-render) silently
dropped every inline action button and paired widget, if the host had hoisted its table to a
file-level constant, which is the natural way to write it.

**Findings covered:** F-002, F-007, F-015 · **Changes:** C-8

**Files touched**
- `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua`
- `tests/fixture_options.lua`, `tests/test_options.lua`, `tests/test_options_widgets.lua`
- `CHANGELOG.md`

### Theme E — The last remembered coupling, mechanized

**What changed.** The suite now fails when `testkit/` and `tests/_kit/` differ, in file set or in
bytes. `docs/releasing.md`'s manual `diff -r` step remains, now backed rather than relied on.

**Why it mattered.** This is the drift `anti-patterns` #45 calls uniquely silent: both copies work,
the suite stays green, and the divergence ships. The repo already made the file-minor ↔ changelog
coupling mechanical; this was the one left over.

**Findings covered:** F-011 · **Changes:** C-10

**Files touched**
- `tests/test_kit_sync.lua` (new), `tests/run.lua`, `docs/releasing.md`, `CHANGELOG.md`

### Theme F — Correctness and cost cleanups

**What changed.** `printer.Format` applies `string.format` on every path, so the zero-argument and
many-argument forms agree on what a `%%` means. The concat probe reuses one file-level scratch slot
instead of allocating a table per stringified value, clearing the slot after the probe so no secret
is retained by the library.

**Why it mattered.** The `Format` split changed the *meaning* of a format string based on argument
count — a ten-minute debug for whoever hit it. The probe sits on the per-argument path of every chat
line, every console line and every Perf render; the `pcall` there is mandatory and untouched, the
allocation around it was not.

**Findings covered:** F-012, F-013 · **Changes:** C-9

**Files touched**
- `LibKa0s/Core.lua`, `tests/test_core.lua`, `CHANGELOG.md`

---

## API / behavior changes

Every change is either additive or an enforcement of an already-documented contract. No descriptor
field is added, removed or repurposed, so `library-stack-§7`'s additive-only rule within `-1.0` holds.

| Change | Externally observable |
|---|---|
| C-1 | `LibKa0s-Options-1.0:New` now **raises** when `OptionsWidgets.lua` is absent, with a message naming the file. Previously it returned an instance that crashed at first panel `OnShow`. |
| C-2 | `LibKa0s-Options-1.0:New` now **raises** when any of `parentTitle`, `mainPanelName`, `get`, `set`, `applyDefault`, `rowsForPage`, `allRows` is missing or the wrong type. All seven were already documented as required. **This is the one change that can break a host that was working by accident.** |
| C-3 | With no descriptor `print`, Options' user-facing lines now go to `DEFAULT_CHAT_FRAME` instead of being discarded. No prefix tag is synthesized — the cyan tag is the host's (`slash-commands-§4`). |
| C-4 | A second `CreateOptionsPanel()` is a no-op instead of registering a duplicate Blizzard category. |
| C-5 | `LibKa0s-DebugLog-1.0.MakeCloseButton` is now a function that forwards, not a copied reference. Same signature, same return. |
| C-6 | A secondary file over a shell below its floor is now **absent** rather than attached. All floors ship at 1, so no shipped configuration changes. |
| C-7 | A combat-protected value reaching `Slash.FormatValue` or `DebugLog:Add` now renders `<secret>` instead of raising. A bare table passed to `D:Add` also renders `<secret>` — the documented `Core.SafeToString` behavior, now reaching one more call site. |
| C-8 | `O.RestoreDefaults(pageKey, ctx)` calls `d.rowsForPage(pageKey, ctx.unit)`. A host whose `rowsForPage` ignores its second argument is unaffected. `RenderRows` no longer writes to the caller's tables. A `solo` row no longer receives a `pairWith` partner. |
| C-9 | `Format(fmt)` with no varargs now applies `string.format`, so `%%` collapses to `%` as it already did with arguments. |
| C-10 | Test-only. |

**No slash subcommands added, renamed or removed.** No locale keys added or renamed. No new
user-facing English string beyond the existing frozen `lib.STRINGS` tables.

---

## Saved-variable / migration notes

**None.** No change in this set touches a persisted schema. LibKa0s owns no saved variables of its
own except `Perf`'s `_G[d.sv]` ring (`LibKa0s/Perf.lua:443-453`, `lib.SCHEMA = 2`), which is
untouched by this pass — `lib.SCHEMA` does not move and no existing `<Addon>PerfDB` needs migrating.
Host settings databases are reached only through the descriptor's `get`/`set`/`applyDefault`, which
keep their signatures. **No user needs to run a reset.**

---

## Deprecated-API migrations

**None.** No deprecated or removed Blizzard API is called anywhere in `LibKa0s/`, before or after
this pass. The two private-API reaches are already correctly handled and were not changed:

| Reach | Handling | File |
|---|---|---|
| `SettingsPanel:GetCategoryList()` / `entry:SetExpanded()` | Wrapped in `pcall`, presence-guarded at every hop | `LibKa0s/Options.lua:411-423` |
| `ScrollingMessageFrameMixin` scroll API (`GetMaxScrollRange` / `GetScrollOffset` / `SetScrollOffset`) | The modern mixin form, method-presence-guarded, with the initial sync run **last** in the window build | `LibKa0s/DebugLog.lua:454-465` |

Both are exactly what `anti-patterns` #41 asks for. Worth recording so a future sweep does not
"modernize" them into a regression.

---

## Performance impact

Fill from `03_SMOKE_TESTS.md`'s spot-checks.

| Metric | Before | After | Notes |
|---|---|---|---|
| `collectgarbage("count")` delta over 1000 debug lines | | | C-9 / F-013: one table allocation removed per stringified value |
| `GetAddOnCPUUsage(<Host>)` over the same burst | | | Expected flat-to-slightly-better; the `pcall` is unchanged and dominates |
| Console buffer trim at the 500-line cap | O(n) shift per line | O(n) shift per line, **unless M4-T2 landed** | See Known follow-ups |

No hot-path or per-frame code was added. The one `pcall` added per rendered settings value (C-7) is
on a user-initiated path, not a repaint path.

---

## Known follow-ups

- **F-014 — the console buffer's O(n) trim** (`LibKa0s/DebugLog.lua:412`). Deferred if M4-T2 was cut.
  Rewriting `D.buffer` as a ring moves four public readers (`CopyText`, `BufferSize`, `LastLine`,
  `FindLine`) with it, for a bounded 500-element shift nobody has measured. Real, small, and not
  worth coupling to a release that is otherwise about correctness.
- **No shell-floor negotiation across majors.** C-6 closes the within-major direction; the cross-major
  direction stays one-way by design — a dependent names a `NEEDS_CORE` floor, and nothing negotiates
  back. `docs/releasing.md` names whole-folder copying as the mitigation. Revisit only if a real skew
  incident occurs; a negotiation protocol nobody needs is worse than the documented rule.
- **`tests/fixture_options.lua` still models a simpler host than the descriptor promises.** C-8 widened
  `rowsForPage`; `skipRestoreAll`, `afterRestoreAll`, `colorDecode`/`colorEncode` and `scheduleTimer`
  remain thinly exercised. The class of bug F-002 belongs to — the library passing an argument the
  fixture cannot see — is not fully swept.
- **`README.md` is 53 KB.** Not a defect and not in scope, but it is now the single largest artifact
  in the repo and is where a descriptor contract goes stale first. Consider splitting per-major
  reference pages under `docs/` at the next documentation pass.

---

## Verification evidence

- Completed checklist with sign-off table: `docs/reviews/2026-07-31/03_SMOKE_TESTS.md`
- Headless gate: `lua tests/run.lua` — `___ passed, 0 failed` · `luacheck .` — `0 warnings / 0 errors`
- Kit sync: `diff -r testkit tests/_kit` empty (now suite-enforced, C-10)
- Vendor sync, per consumer: `diff -r LibKa0s <Consumer>/libs/LibKa0s` empty
- Commit range: `<first>..<last>` on `feature/libka0s-five-module-extraction`
- Re-vendor commits: one per consumer, listed in `docs/releasing.md`'s consumer table

---

## Suggested commit message / PR description

```
fix(libka0s): even out the five majors — Options hardening, version-skew and secret-safety gaps

Follows docs/reviews/2026-07-31. Four High, seven Medium, four Low findings closed.
No Critical findings; the taint model, per-instance frame ownership and the
secret-safe detector were already correct.

Options (F-001, F-004, F-005, F-010, F-016)
- Refuse at :New when OptionsWidgets.lua did not arrive, naming the file, instead
  of nil-calling O.AttachTooltip on the first panel OnShow. The shell's own
  comment claimed call-time reach made this safe; it did not, and
  docs/releasing.md already said so.
- Validate the descriptor and error by field name, matching Perf's required()
  helper and the error() form Core/DebugLog/Slash use. mainPanelName is the
  sharpest case: a nil silently produced an anonymous canvas frame, losing the
  /framestack attribution the field exists for.
- Default the printer to DEFAULT_CHAT_FRAME rather than a no-op, so an in-combat
  refusal is never silent (options-ui-§2). No tag is synthesized; the cyan
  prefix stays the host's (slash-commands-§4).
- CreateOptionsPanel is idempotent.

Version skew (F-003, F-006)
- DebugLog forwards MakeCloseButton through the live Core table instead of
  snapshotting the function at file load. LibStub upgrades a major in place, so
  a newer Core over an unchanged DebugLog left the console wearing the old
  button while lib.MODULES reported the new minor.
- Every paired secondary declares a NEEDS_SHELL floor, mirroring NEEDS_CORE on
  the within-major axis (library-stack-§7).

Secret safety (F-008, F-009)
- Slash.FormatValue routes every type branch through the concat probe, not just
  the fallthrough; DebugLog:Add — public and ungated — guards its message. Both
  were safe only on an unwritten invariant, which is exactly the per-call-site
  reasoning events-frames-taint-§8 exists to remove.

Options flow engine (F-002, F-007, F-015)
- RestoreDefaults passes the ctx.unit filter RenderSchema renders with; a
  per-unit page's Defaults button was resetting every unit's rows.
- RenderRows copies afterGroup/pairWith instead of consuming the caller's
  tables, so a second render of the same page keeps its inline buttons.
- A solo row no longer receives a pairWith partner.

Also: the testkit/ <-> tests/_kit/ sync is now a red suite rather than a line in
a release doc (anti-patterns #45); Core's concat probe reuses one scratch slot;
printer.Format's zero-arg and many-arg paths agree.

Standards: checked against Ka0s WoW Addon Standard v2.14.0 (2026-07-30). No
change introduces a new deviation.

Tests: ___ passed, 0 failed. luacheck: 0 warnings / 0 errors.
```
