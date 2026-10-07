# 02 — Proposed changes (LibKa0s, 2026-10-07)

**Standard resolved:** Ka0s WoW Addon Standard **v2.76.1** (2026-10-07). See `01_FINDINGS.md` for how it was fetched. The rules that shaped these changes are `library-stack-§7` (a Ka0s-owned lib, per-file minors, additive surface), `testing-§5` (the inventory moves with the count), `testing-§12` (falsifiable negatives), `testing-§13` (characterization before a behavior-preserving refactor), `localization-§5` (US English in authored text) and the repo's own `docs/releasing.md` order of operations.

## HLD

### Theme A — The line chart bounds its own work (F-001, F-003)

**What.** Clip every series segment, and every marker rule, to the plot rectangle before drawing it, so the region count is bounded by plot geometry instead of by input values. Then make a data change re-arm the hover.

**Why.** The widget accepts host numbers verbatim, and each dash is a permanent region (F-001). The hover contract today puts a correctness duty on every host (F-003).

**Alternatives rejected.**
- *Clamp the input y values.* This changes the plotted shape of an outlier and breaks the "the widget plots the numbers it is handed" contract in the header (`LibKa0s/WidgetsLineChart.lua:21-23`).
- *Cap `Dashes` alone.* This still draws one huge off-plot solid segment, and the cap value would be arbitrary.
- *Document F-001 as a host duty.* That repeats F-003's pattern of moving library invariants into consumers.

**Trade-off.** One extra clip computation per segment. It is cheap, at O(points after LTTB), which is already ≤ plot width / `pxPerPoint`.

### Theme B — The autocomplete survives its host (F-002, F-005, F-007, F-008, F-009)

**What.**
- Re-install the hooks on every `lib.Autocomplete` call, behind a per-box generation, so stale hooks go inert and a replaced script can be recovered.
- State the "set your scripts first" precondition in the API document.
- Run `provider` and `onPick` under `pcall`, routing a raise to `geterrorhandler()` once and closing the list.
- Floor `maxRows`.
- Set the backdrop once and recolor per show.
- Correct the weak-table comment.

**Why.** A hook lost to a later `SetScript` cannot be recovered today, and nothing says so (F-002). The remaining items are cheap hardening in the same file at the same minor bump.

**Alternatives rejected.**
- *Replace hooks with `SetScript` wrappers that chain the host's handler.* That overwrites host scripts, which the file's own header rules out (`:18-24`), and it breaks hosts that set scripts afterwards in a different way.
- *Detect lost hooks through `GetScript`.* What `GetScript` answers on a hooked script is not documented reliably. This is unverified, so the design does not depend on it.

### Theme C — The CLI refuses non-finite numbers (F-006)

**What.** `parseNumber` rejects `nan` and `±inf` with the existing `ERR_NUMBER` string, before any enum or clamp logic, and a comment records why `math.max(row.min, n)` has its argument order.

**Why.** A stored NaN or inf is never a value a player meant, and today it is absorbed only by argument-order luck.

**Alternative rejected.** Rejecting in `Schema.Set`. The write seam is type-agnostic by design (`row.validate` is the host's hook), and the slash parser is where text becomes a number.

### Theme D — Records and locale (F-010, F-011)

**What.**
- Record each negative case's mutation as a `-- red under:` note, after actually running the mutation on a `cp` backup per `testing-§12`.
- For F-010, the library's default label stays as it is, and its API document states that the default is the C locale's English abbreviation and that a localized host passes `formatX`. The fix belongs to LootHistory, the consumer that shows the label. That is a consumer task, not an upstream one. It is listed under follow-ups and not executed here, because this bundle may not touch another repo.

**Deferred: F-004** (double render). The cost is unmeasured. Adding an opt-out such as `opts.manualRender` would be a new API surface justified by a guess. The compliant path is to measure first, with a headless count of `Render` calls per `TL:Layout` in LootHistory's own suite or an in-client capture, and to change the seam only if the number justifies it.

## Upstream change-set

**None.** This repo is the upstream. Every change below lands in `LibKa0s/`, `tests/` or `docs/` here, ships as release **v1.71.0**, and then reaches the 11 consumers through the whole-folder re-vendor that is step 8 of `docs/releasing.md`. That step is part of the release, not a follow-up. No change targets any consumer's `libs/` or `tests/_kit/`.

## LLD

### C-01 — Clip segments and markers to the plot (F-001)

- **File:** `LibKa0s/WidgetsLineChart.lua`. `CHART_MINOR` 2 → **3**, so the Widgets key becomes 12.1.4.3.1 (WidgetsAutocomplete moves too, in C-03).
- **Change:** add a private `clip(s, x1, y1, x2, y2)` (Liang–Barsky against `[s.left, s.left+s.w] × [s.bottom, s.bottom+s.h]`) that returns the clipped endpoints, or nil when the segment is fully outside. `drawSeries` (`:358-363`) calls it before `seg` or `dashed`. `inDash` keeps using the **data-space** midpoint, so a segment's dash state does not change when it is clipped. Publish the clip as `ChartMath.Clip` alongside the other pure functions so the suite pins it without geometry (the header's stated reason for `ChartMath`, `:12-17`).
  ```lua
  -- before
  if inDash(sr, a.x, b.x) then dashed(c, x1, y1, x2, y2, color, th) else seg(c, x1, y1, x2, y2, color, th) end
  -- after
  local cx1, cy1, cx2, cy2 = Math.Clip(s, x1, y1, x2, y2)
  if cx1 then
    if inDash(sr, a.x, b.x) then dashed(c, cx1, cy1, cx2, cy2, color, th) else seg(c, cx1, cy1, cx2, cy2, color, th) end
  end
  ```
- **Risk:** a single-point series (`:353-356`) keeps its 2 px tick but is skipped when the point lies outside the plot. Markers already filter by domain (`:331`). A point exactly on the edge must survive, so use inclusive comparisons.
- **Tests:** new cases in `tests/test_widgets_linechart_math.lua` (Clip: inside, crossing, fully outside, vertical, degenerate) and in `tests/test_widgets_linechart.lua`. In the latter, a dashed series with explicit `yMax = 1` and one point at `y = 1e6` draws **no more lines than the plot height allows**, with a `-- red under: drop the Clip call in drawSeries` note. This moves the case count.

### C-02 — Hover re-arms on new data and re-anchors on render (F-003)

- **File:** `LibKa0s/WidgetsLineChart.lua`, at the same minor 3 as C-01.
- **Change:** `SetData` sets `self.__hoverIndex = nil` and hides `__cross` **without** calling `onHover(nil)`, so no tooltip flicker occurs. The armed `OnUpdate` then hovers again against the new data on the next frame and fires `onHover` with the new index. `render` re-positions the crosshair (`moveCross`) when `__hoverIndex` is set and still valid for the current `hoverXs`.
- **API document:** the new `version-12.1.4.3.1-docs.md` rewrites the `onHover` bullet (the current one is `version-12.1.4.2.1-docs.md:1125-1129`) and drops "a host … calls `ClearHover` before `SetData`". LootHistory's existing call (`modules/Timeline.lua:308`) stays valid and becomes redundant. Removing it is the consumer's choice, not part of this change.
- **Tests:** "SetData under a resting hover re-fires onHover on the next hover tick with the new data". Pin it by calling `HoverAtPixel` at the same pixel after `SetData` and asserting the call count rises.

### C-03 — Autocomplete hardening (F-002, F-005, F-007, F-008, F-009)

- **File:** `LibKa0s/WidgetsAutocomplete.lua`. `AUTOCOMPLETE_MINOR` 1 → **2**, so the Widgets key becomes 12.1.4.3.2.
- **F-002:** replace `hooked[box] = true` with a generation counter. Each `lib.Autocomplete` call increments `gen[box]` and installs a fresh hook set whose `dispatch` closure captures that generation and runs only while `gen[box] == myGen`. Stale hooks still installed become no-ops, so nothing is dispatched twice. A host that replaced a script calls `lib.Autocomplete` again to recover. The API document gains a precondition bullet: "Set the box's own scripts before calling; a later `SetScript` on a hooked script removes the hook, and calling `Autocomplete` again restores it."
  - **Risk:** the number of hooks on a box grows by 8 per call. That is acceptable, because hosts call once per build (the two adopters call it once, at `BrowserFilterBar.lua:429` and `Browser.lua:1105`). Record the growth in the API document.
- **F-005:** `local ok, items = pcall(self.__provider, text)`. On `not ok`, `self:Close()`, then `geterrorhandler()(items)` when it is present, so the error still surfaces through the client's handler once per refresh rather than escaping a timer. Wrap `onPick` the same way, after `Close()`.
- **F-007:** rewrite the comment at `:67-68`: "Weak-keyed for form; under Lua 5.1 an entry whose handle references its box is never collected, and client frames are never collected anyway."
- **F-008:** `__maxRows = floor(positive(opts.maxRows, AC.MAX_ROWS))`, with a floor of 1.
- **F-009:** move `SetBackdrop` into `ensureList` (once). `skin()` keeps only the two color calls.
- **Tests (`tests/test_widgets_autocomplete.lua`):**
  - a host `SetScript("OnTextChanged", …)` after attach, then `Autocomplete` again, and typing opens the list (this needs the kit's frame mock to drop hooks on `SetScript`; see the risk below);
  - a raising provider closes the list, calls the error handler once and does not raise out of the timer;
  - `maxRows = 2.5` draws 2 rows in a 2-row-tall list.
- **Risk:** if `testkit/mock_base.lua` does not model `SetScript` discarding hooks, the F-002 case cannot go red. Read the mock first. If it does not model this, the fidelity fix is a **kit revision** (37 → 38) under `testing-§1`, with its own `test_mock_*` case, and that ships in the same release.

### C-04 — Reject non-finite numbers in the CLI (F-006)

- **File:** `LibKa0s/SlashParse.lua`. `PARSE_MINOR` 1 → **2**, so the Slash key becomes 19.2.
  ```lua
  local n = tonumber(args[1])
  -- nan ~= nan; math.huge is inf. A setting is never meant to be either, and a bounded row only
  -- absorbs them by argument order: math.max(row.min, nan) is row.min, math.max(nan, row.min) is nan.
  if not n or n ~= n or n == math.huge or n == -math.huge then return nil, S("ERR_NUMBER") end
  ```
- **Tests (`tests/test_slash_parse.lua`):** `nan`, `inf`, `-inf` and `1e400` on a row with no bounds each answer `nil, ERR_NUMBER`.

### C-05 — Locale note for the chart's default x label (F-010)

- **File:** the new `docs/api/Widgets/version-12.1.4.3.2-docs.md` (written for C-01 to C-03 anyway). One bullet states that the default `formatX` uses `date("%d %b")`, which is the C runtime's English month abbreviation, and that a host showing other locales passes `formatX`. No code change in the library.
- **Consumer follow-up (not executed here):** LootHistory passes a `formatX` built from its locale table.

### C-06 — Record the mutations behind the new suites' negative cases (F-011)

- **Files:** `tests/test_widgets_autocomplete.lua`, `tests/test_widgets_linechart.lua`, `tests/test_widgets_linechart_math.lua`. Comments only, so no minor bump and no case-count change.
- **Procedure:** for each negative assertion, `cp` the implementation file aside, apply the mutation, watch the case go red, restore from the `cp` (never `git checkout`, per `testing-§12`), and write `-- red under: <mutation>` on the case. A case that stays green under every plausible mutation is a real `testing-§12` defect: rewrite it with a positive precondition, which moves no count.

### Release mechanics (all of C-01 to C-06, one release)

Follow `docs/releasing.md` steps 1–9:
- minors: WidgetsLineChart 3, WidgetsAutocomplete 2, SlashParse 2, plus the kit 38 only if C-03's mock fix is needed;
- a `CHANGELOG.md` v1.71.0 version block;
- new API documents for Widgets and Slash, and `lua tools/gen-api-members.lua` for their manifests (C-01 adds the member `ChartMath.Clip`);
- `docs/test-cases.md` regenerated **in the same change** that moves the count (`testing-§5`);
- the release record via `/dev-copilot:bump-version`;
- the re-vendor into all 11 consumers;
- the `CONSUMERS.md` sweep.

The complexity watch list should not move: every edited function stays well under CCN 15. The next release's regeneration confirms that.

## Standards conformance (per change)

| Change | Conformance |
|---|---|
| C-01, C-02 | Additive (one new `ChartMath` member). No existing member is removed, so the change stays inside `library-stack-§7`'s additive-release reading. The secondary file stays paired on the shell's minor. `layout-§1`: the file grows by about 40 lines from 465 and stays far from 1500. |
| C-03 | Keeps "hooks, never scripts" (the file header). Rejected the `SetScript`-chaining option, which would override host scripts. `geterrorhandler()` is the client's own reporting path, so no private printer is hand-rolled (the `extra` rule against re-hand-rolling a subsystem the library provides). A kit fix, if needed, goes through `testkit/` and the kit-sync gate (`testing-§11`), never into `tests/_kit/` directly. |
| C-04 | Reuses the existing `ERR_NUMBER` string, so no new prose and no `localization-§5` exposure. |
| C-05 | Documentation only, in a **new** per-version API document. The superseded document is not edited (the `CLAUDE.md` documentation map: "A superseded document is never edited"). |
| C-06 | Follows `testing-§12` exactly, including the `cp`-backup rule. No test is weakened or deleted. |
| F-004 deferral | Measure before changing the seam (`testing-§14`'s measure-first principle applied to a perf claim). |
