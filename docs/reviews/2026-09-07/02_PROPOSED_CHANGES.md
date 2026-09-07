# 02 — Proposed changes (HLD + LLD)

**Standard resolved:** Ka0s WoW Addon Standard **v2.38.0 (2026-09-02)**, index plus all 26 section
files fetched verbatim. The conformance check below was performed, not skipped.

**Scope reminder:** LibKa0s is a library repo. Nothing here targets a path under `libs/` or
`tests/_kit/` in a consumer, and nothing here proposes editing this repo's `tests/_kit/` copy — the
kit's master is `testkit/` and the two are held byte-identical by `tests/test_kitsync.lua`.

---

## HLD — themes

### Theme A — Stop constructing frames the client can never reclaim (F-001, F-005)

**Rationale.** `OptionsWidgets.lua`'s tab strip is the newest surface in the library and the only one
that rebuilds frames on a user gesture. WoW frames are permanent; the correct answer is a pool, and
this repo ships one (`LibKa0s-Pool-1.0`). The sibling `Widgets.lua` already reached the right
conclusion independently and wrote a third implementation of it. Consolidating both onto `Pool` fixes
the leak and deletes a duplicate.

**Alternatives considered.**
- *Leave the leak; a settings panel is not a hot path.* Rejected — `options-ui-§13` makes the strip
  mandatory on every page of every consumer, and a 13-tab page leaks 14 frames per click for the
  session. It is a hot path by frequency of gesture, not by frame budget.
- *Cache the buttons on `ctx` without a pool (a plain free list local to `OptionsWidgets`).*
  Rejected — that is a fourth pool in a repo that extracted one, which `library-stack-§7`'s promotion
  bars are written against and which is the exact drift this library exists to end.
- *Fix only `OptionsWidgets` and leave `Widgets.lua`'s attic pool alone.* Tempting (it works, and it
  is well-commented), but it leaves two release semantics in one library and the next author picks by
  coin toss. Migrating it is small and is sequenced second so the leak fix can land alone.

**Trade-off.** `Pool.ReleaseAll`'s `before` hook must carry `Widgets.lua`'s attic reparent, which is
slightly less legible than the current inline `reclaim`. Accepted: the contract gains a single owner.

### Theme B — Make the standing evidence say what was measured (F-002, F-003, F-012, F-013)

**Rationale.** `RESULTS.md` is banner-labelled "generated, never hand-edited" and is half
hand-written. That is why its prose is a month stale while its table is current, and why it now
asserts a cap compliance its own manifest contradicts. The fix is structural, not editorial: move the
narrative to where the repo already keeps frozen, dated analysis, and let the generated file be
generated.

**Alternatives considered.**
- *Just update the prose.* Rejected as the only change — it repairs today's numbers and reproduces
  the same rot at the next release. It is included as a stopgap inside the structural change.
- *Delete the prose sections.* Rejected — the reading discipline they carry (lint scope, the
  permanent perf skip and why, the `and`/`or` caveat on Lua CCN) is genuinely valuable and is cited by
  this review.
- *Regenerate `RESULTS.md` now, as part of this review.* **Forbidden.** Regeneration in place belongs
  to the release checkpoint (`automated-tests`; `/wow-addon:bump-version`). This review measured to a
  scratch path and touched nothing.

### Theme C — One diagnostic policy across the Options major (F-006, F-008)

**Rationale.** The major already has a policy — *report the authoring defect, render anyway* — stated
at `Options.lua:283-288` and executed by `EMPTY_DROPDOWN`, `NO_GROUPS`, `ROW_FAILED`. Two seams do not
follow it: `OptionsWidgets`' printer swallows when the host omits one, and a composed reset with no
handler is silent. Both are one-line-shaped fixes that make the policy uniform.

### Theme D — Widen the two gates that are narrower than their names (F-004, F-009)

**Rationale.** `test_eol.lua` and `.luacheckrc` both produce a green number over a subset that the
number's reader will take for the whole. Widening both is cheap; widening `test_eol` will go red on
seven real files, which is the gate working.

### Theme E — Documentation currency (F-010, F-011)

Small, no design content.

---

## Upstream change-set (does **not** land in this repo)

| # | Finding | Owning repo | File | Change | Version bump | Consumer action |
|---|---|---|---|---|---|---|
| U-1 | F-014 | `tusharsaxena/WowAddonStandards` | `standards/standards/library-stack.md` (§7 module table + `:70`), `standards/STANDARDS.md:57`, `standards/standards/open-evolutions.md:13` | Add the `OptionsScroll.lua` row; correct "thirteen files" → "fourteen files" in all three places | Standard minor bump + dated changelog entry | Every repo bumps its standards pointer (this repo's is F-010) |
| U-2 | F-015 | `tusharsaxena/WowAddonStandards` | `standards/standards/library-stack.md:175-226` | Make the applicability classification exhaustive — a default clause plus explicit exclusions — and state whether `layout`'s 1500-LOC MUST binds a library's ship folder | Standard minor bump | This repo then either peels `LibKa0s/OptionsWidgets.lua` (1838 LOC) or ratifies a `CLAUDE.md` register row; other library repos re-check the same way |

Neither is a code change anywhere. Both must land upstream before **C-8** below can be decided.

---

## LLD — change set

### C-1 — Pool the tab strip's buttons and the content panel `[F-001]`

**Files:** `LibKa0s/OptionsWidgets.lua` (bump `WIDGETS_MINOR` 13 → 14; update
`CHANGELOG.md` version block and add `docs/api/Options/version-14.14.2.3-docs.md`).

**Before** (`:1052-1070`, abridged):

```lua
releaseLedger(ctx, "__tabKids")
for i, tab in ipairs(spec.tabs) do
  local b, w = makeTab(ctx.chrome, tab, tab.key == spec.value, spec.onSelect)
  ctx.__tabKids[#ctx.__tabKids + 1] = b
end
drawContentPanel(ctx)
```

**After** (shape):

```lua
-- One pool per ctx, so one page's released buttons never surface on another's chrome.
ctx.__tabPool = ctx.__tabPool or Pool.New()
Pool.ReleaseAll(ctx.__tabPool, function(f)
  f:Hide(); f:ClearAllPoints(); f:SetParent(atticFrame())
end)
for i, tab in ipairs(spec.tabs) do
  local b = Pool.Acquire(ctx.__tabPool, function() return newTabButton(ctx.chrome) end)
  dressTab(b, ctx.chrome, tab, tab.key == spec.value, spec.onSelect)
  ...
end
```

**Decomposition required.** `makeTab` currently *creates and dresses* in one body. Split into
`newTabButton(parent)` (the `CreateFrame`, the frame-level lift, the FontString) and
`dressTab(b, parent, tab, active, onSelect)` (label, measure, state, art, `SetScript`). The
`OnClick` closure must be **re-set on every dress**, not cached, since a reused button's old closure
points at the previous render's `onSelect`.

`drawContentPanel` gets the same treatment: one panel per `ctx`, created once and re-anchored
(`ClearAllPoints` then the four `SetPoint`s) rather than re-created. Its two textures are children of
that panel and survive with it.

**Risk.** A reused `Button` carries stale scripts and stale textures. Mitigate with `dressTab`
unconditionally setting every property `makeTab` sets today — no `if not already set` shortcuts.
The atlas swap between selected and unselected states is the property most likely to be missed.

**Tests to add** (`tests/test_options_widgets.lua`):
- *"tabstrip: a second render reuses the first render's buttons"* — count `CreateFrame` calls via the
  mock across two `TabStrip` calls; assert the second adds none. **Red under:** reverting `C-1`.
- *"tabstrip: a reused tab fires the CURRENT onSelect, not the one it was built with"* — render with
  `onSelect = A`, re-render with `onSelect = B`, click, assert `B` ran. **Red under:** caching the
  `OnClick` closure.
- *"tabstrip: a tab reused from active to inactive loses the selected atlas"*.
- *"tabstrip: two ctxs never share a pooled button"*.

**Expected movement:** pass count **764 → ~768**; `docs/test-cases.md` and this repo's inventory move
in the same change (`testing-§5`). Complexity: `drawContentPanel` should *fall* below CCN 14 once the
creation half moves out — to be confirmed by the next release's regeneration, **not** run now.

### C-2 — Migrate `Widgets.lua`'s handle/box pools onto `LibKa0s-Pool-1.0` `[F-005]`

**Files:** `LibKa0s/Widgets.lua` (bump `MINOR` 9 → 10).

Replace `handlePool`, `boxPool` and `reclaim` (`:799`, `:815-827`) with two `Pool.New()` instances and
`Pool.ReleaseAll(pool, before)`, carrying the existing three-step contract (hide, `ClearAllPoints`,
reparent to `atticFrame()`) in the `before` hook. `atticFrame()` stays — it is the library's own
concept and `Pool` has no opinion about parents.

**Risk.** `reclaim` also clears `f.__row`; that must move into the `before` hook or the reused frame
carries a dead row reference. Existing cases in `tests/test_widgets.lua` over Cancel/reclaim should
stay green unchanged — if any of them go red, the `before` hook is missing a step, which is the
migration's own gate.

**Sequencing:** after C-1, and as its own commit. Both touch pooling but different files.

### C-3 — Move `RESULTS.md`'s narrative into per-run `ANALYSIS.md`, and refresh what remains `[F-002, F-003]`

**Files:** `docs/automated-tests/RESULTS.md`, `testkit/run-automated-tests.sh` (+ the byte-identical
`tests/_kit/` copy, re-vendored by copying `testkit/` — never edited in place), `docs/automated-tests/README.md`.

Three parts:

1. **Reduce `RESULTS.md` to what the runner writes** — the header, the reading rules, and the table.
   The banner's claim "generated, never hand-edited" then becomes true.
2. **Move the four narrative sections** (`## Test suite`, `## Lint`, `## Perf`, `## Complexity watch
   list`) into the newest bundle's `ANALYSIS.md`, where they are frozen and dated and cannot rot —
   which is what this repo already does for every bundle that has one. Correct the numbers in the
   move: 764 cases, 18 linted files, 14 shipped library files, and a band table stating that **two**
   files are over 1500 (`LibKa0s/OptionsWidgets.lua` 1838, `tests/test_options_widgets.lua` 2287),
   matching `manifest.json`'s `overCapFiles: 2`.
3. **Refresh the watch list** in that moved copy against today's `lizard`: ceiling is
   `drawContentPanel@LibKa0s/OptionsWidgets.lua:643-677` at CCN 14, not `Kit.run`.

**Explicitly not done here.** This review does not write any of it — the checkpoint is **release**
(`/wow-addon:bump-version`). C-3 is the specification for that release's regeneration, and the numbers
above are today's measurements, to be re-measured then.

**Risk.** Two bundles lack `ANALYSIS.md` (`20260903-161751` among them, including the newest). The
narrative needs a home that exists; creating that file is part of the change.

### C-4 — Widen `test_eol.lua` to the whole tracked tree, and repair the seven stragglers `[F-004]`

**Files:** `tests/test_eol.lua`, plus a byte-level repair of the seven files.

**Before:** `tests/test_eol.lua:29` — `local BUNDLES = "docs/automated-tests"`, used only at `:38`.

**After:** drop the path filter — `git ls-files` with no pathspec — and rename the case to
*"eol: every tracked file carries the terminator .gitattributes declares for it"*. The body needs no
other change: `declaredEol` already returns `unspecified` where nothing is pinned and the binary skip
(`data:find("\000")`) already covers the 123 `-text` assets.

**Then repair,** in the same change, per the message the test already prints:

```sh
for p in LibKa0s/DebugLog.lua LibKa0s/Pool.lua tests/test_debuglog.lua tests/test_pool.lua \
         docs/api/Options/version-8.7.3-docs.md docs/api/Options/version-9.7.3-docs.md \
         docs/api/testkit/version-12-docs.md; do rm "$p" && git checkout -- "$p"; done
```

**Risk.** The widened gate now shells out `git check-attr` once per tracked file (~475). Measure the
run's wall time; if it is material, batch via `git check-attr --stdin`. Do **not** add a wall-clock
assertion to compensate — `performance` forbids it and it is a flake generator.

**Regression pressure:** the case is renamed, so `docs/test-cases.md` moves in the same change even
though the count does not.

### C-5 — Lint the test tree `[F-009]`

**Files:** `.luacheckrc`.

Narrow `exclude_files` from `{ "tests/", "docs/" }` to `{ "tests/_kit/", "docs/" }` (the kit is linted
at its master path `testkit/`, and `test_kitsync.lua` holds the copies identical, so linting it twice
buys nothing). Add a `files["tests/"]` stanza declaring `LK_TEST` and whatever `_G` reads the suites
make, rather than adding them to the top-level `read_globals` — a global silenced repo-wide to quiet
test code is the config-hides-a-real-problem shape this review is told to flag.

**Risk.** Expect warnings on first run. Fix them in the suites; do **not** grow `read_globals` to
silence them, and do not weaken a test to clear one.

### C-6 — One printer per Options instance `[F-006]`

**Files:** `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua` (bump both minors).

**Before:** `Options.lua:289` builds a type-checked, chat-frame-backed sink; `OptionsWidgets.lua:696`
independently builds `d.print or function() end`.

**After:** `lib:New` stores its sink on the instance (`O.__print`) and `lib.__AttachWidgets(O, d)`
reads `local print = O.__print`. One construction, one policy, one fallback. `__AttachCompose` needs
nothing — the composers print nothing.

**Risk.** `__AttachWidgets` is called at the end of `lib:New`, so `O.__print` is already set; verify
the ordering rather than assuming it. Add a case asserting a widget-layer diagnostic reaches
`DEFAULT_CHAT_FRAME` when the descriptor omits `print`. **Red under:** restoring the no-op fallback.

### C-7 — Report a composed button with no handler `[F-008]`

**Files:** `LibKa0s/Options.lua` (a new `lib.STRINGS.DEAD_BUTTON`), `LibKa0s/OptionsWidgets.lua`
(`makeBtn`).

At `OptionsWidgets.lua:1313-1319`, `makeBtn` reports once at build time when `spec` is present and
`spec.onClick` is not, instead of only returning early on click:

```lua
local function makeBtn(spec)
  if not spec then return end
  if not spec.onClick then print(lib.STRINGS.DEAD_BUTTON:format(tostring(spec.text or "?"))) end
  ...
```

Report-and-render, not raise: `options-ui`'s reset controls are acts, and this major's stated policy
everywhere else (`NO_GROUPS`, `EMPTY_DROPDOWN`) is to report and keep drawing. Raising would take a
page down over a missing callback, which is a worse failure.

Depends on **C-6** — without it the line is swallowed for a host that omits `print`, which would make
this change do nothing in exactly the sloppily-wired host it is written for.

**Test:** compose `MasterControls{ onResetAll = nil }`, run the returned `afterGroup`, assert the
line was printed. **Red under:** removing the report.

### C-8 — `LibKa0s/OptionsWidgets.lua` at 1838 LOC `[F-015, blocked]`

**Blocked on U-2.** Until the standard says whether `layout`'s 1500-LOC MUST binds a library's ship
folder, the compliant act is to *record*, not to peel. Two outcomes:

- **It binds** → peel at the seam the file's own comments already draw: the chrome block —
  `setTabLabel`/`setTabFont`/`drawTabArt`/`drawContentPanel`/`drawChromeDivider`/`makeTab`/`placeTabs`/
  `TabStrip`/`PageBanner`/`SubTabStrip`, roughly `:560-1250` — into a fifth Options file
  (`OptionsChrome.lua`), with its own `__chromeMinor`/`__chromeShellMinor` pair following the
  established idiom, a new row in `tests/run.lua`'s `MAJORS` table, and a new `<Script>` line in
  `LibKa0s.xml` after `OptionsWidgets.lua`. **This also changes the standard's file count again** (U-1
  would land at fifteen), which is an argument for doing U-1 and U-2 in one upstream pass.
- **It does not bind** → a ratified row in `CLAUDE.md`'s `## Documented deviations`, or nothing at all
  if the section is declared inapplicable.

Do **not** peel by moving a body into a helper named for its position (`part2`, `chromeRest`) —
anti-patterns' complexity-refactor rule. The seam above is a real cohesion boundary, not a line count.

### C-9 — Documentation currency `[F-010, F-011, F-013]`

- `CLAUDE.md:3` and `README.md:3`: v2.28.0 → the version resolved when U-1/U-2 land.
- `tests/run.lua:112`: one comment naming `Kit.assertSuiteInventory` as what holds the hand-typed
  suite list honest.
- `testkit/run-automated-tests.sh`: render the Version cell as `<addonVersion> → <release>` when
  `manifest.release` is set. Re-vendor `testkit/` → `tests/_kit/` as a whole folder in the same
  commit; bump `Kit.VERSION` 14 → 15 and add `docs/api/testkit/version-15-docs.md`.

### C-10 — Document `P.Open`'s active-arm allocation `[F-007]`

**Files:** `LibKa0s/Perf.lua` (bump `MINOR` 7 → 8 if the code changes; docstring-only is still a minor
bump, since the file ships), `docs/record-schema.md`.

Preferred: replace the per-`Open` table with a high-water free list on `openStack` — slots are reused
rather than allocated, `P.Reset`'s in-place emptying (`:502-504`) stays valid, and the docstring's
existing honesty about Shape B's cost gains a matching sentence about the capture arm.

Minimum: state it. A docstring that says the pair allocates nothing while the probe is on would be the
same defect this file's own author already corrected once for the off path.

**Evidence for the claim:** extend `tests/test_perf_isolation.lua`'s dormant case with an **active**
sibling — 10,000 `Open`/`Close` pairs with the gate **on**, asserting heap growth falls below a
stated bound after the change. That is the scenario that would show the fix; it belongs in the green
gate beside its dormant twin, not in a `tests/perf.lua` this repo deliberately does not carry
(`performance-§9` keeps scenarios per-addon, and `docs/automated-tests/README.md` records that
disposition).

---

## Standards conformance (per change)

| Change | Conformance |
|---|---|
| C-1 | `library-stack-§7` — adopts the shared `Pool` module rather than a fourth local pool. `testing-§5` — inventory and count move in the same change. `options-ui-§13`'s wrap-stability invariant is preserved: the measure-before-state ordering in `makeTab` must survive the split into `newTabButton`/`dressTab`, and the new cases assert the invariant, not the mechanism. No new deviation. |
| C-2 | `library-stack-§7`, same rule, applied to the earlier module. Removes an existing duplication rather than adding one. |
| C-3 | `automated-tests` — regeneration at **release**, never here; the frozen bundle store is append-only and no committed bundle is edited or deleted. Rejected alternative: hand-editing the numbers into `RESULTS.md` now, which `automated-tests` forbids ("a hand-edited report is worse than an absent one"). |
| C-4 | `line-endings-§2` (the CRLF pin) and `line-endings-§5`. `testing-§12` — the widened gate still fails rather than passes when it cannot look, which the existing body already guarantees. Rejected alternative: adding the seven files to an exception list in `.gitattributes`, which would make the pin decorative. |
| C-5 | `lint` — 0 warnings / 0 errors over a scope that means something. Rejected alternative: adding `LK_TEST` to top-level `read_globals`, which is the config-hides-the-problem shape. |
| C-6, C-7 | `options-ui`'s report-and-render policy for authoring defects; `anti-patterns` on a control that looks live and is not. Rejected alternative for C-7: `error()` on a missing handler, which takes a page down over a nil callback. |
| C-8 | `layout-§1` if it binds; otherwise `CLAUDE.md`'s deviation register per `library-stack-§7`'s substitute obligation. Deliberately **blocked** rather than guessed, because guessing is how a review manufactures a finding the standard never meant. |
| C-9 | `documentation-§6` (the standards pointer), `library-stack-§7`'s substitute list. The kit re-vendor is a whole-folder copy plus a `Kit.VERSION` bump plus an API document — never a partial edit. |
| C-10 | `performance-§2` (the zero-overhead claim is measured, and the claim's *scope* is stated), `performance-§9` (no `tests/perf.lua` is added — the evidence goes in the gated suite where its dormant twin already lives). No wall-clock assertion anywhere. |

No proposed change targets a path under `libs/` or `tests/_kit/`. The two `tests/_kit/` files that
move (C-3, C-9) move as a **whole-folder re-vendor from `testkit/`**, which is the sanctioned path and
is gated by `tests/test_kitsync.lua`.
