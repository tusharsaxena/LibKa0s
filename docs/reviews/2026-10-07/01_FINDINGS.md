# 01 — Findings (LibKa0s, 2026-10-07)

**Verdict: minor issues.** No Critical or High findings. Two Medium findings are latent hazards in the two widgets added in v1.69.0 and v1.70.0. Nine Low findings cover hardening, comments and test hygiene.

**Resolved scope:** `all`, so the whole repository at `353f286` (branch `feat/2026-10-07-review-audit-remediation`, clean tree, library v1.70.0). The review read the payload in depth where it is new since the 2026-09-23 review: `LibKa0s/WidgetsLineChart.lua` (v1.69.0, minor 2 in v1.70.0) and `LibKa0s/WidgetsAutocomplete.lua` (v1.70.0), plus their three suites. It spot-checked the trust boundary (`SlashParse.lua` and `Schema.lua`'s write seam), `Bus.lua` and the raw-`print` and `_G`-write sites. It also re-checked the status of the 2026-09-23 review's findings. All older modules were not re-read line by line, because four earlier reviews and audits already cover them.

**Repo kind:** `library` (from `dev-copilot-profile`: `profile=wow kind=library`). Suites whose subject this repo lacks are marked **not applicable**.

## Measurement run (Step 0b, re-run 2026-10-07 at `353f286`; output in session scratch, nothing written into the repo)

| Suite | Result | Command (from the repo root unless noted) |
|---|---|---|
| luacheck | **pass**: `0 warnings / 0 errors in 153 files` | `ka0s-bounded luacheck .` |
| Headless suite | **pass**: `2087 passed, 0 failed, 2 skipped, 2089 total` (exit 0). Both skips are declared: the kit's `test_prose.lua`, declined by the `localization-§5` register row, and the diagnostics-contract opt-out case, which does not apply to this repo's default | `ka0s-bounded lua5.1 tests/run.lua` |
| Fresh `--list` inventory | **pass**: 2089 total. **Byte-identical** to the committed `docs/test-cases.md` after CR-strip (`diff` empty) | `ka0s-bounded lua5.1 tests/run.lua --list` |
| Offline perf runner | **not applicable**: no `tests/perf.lua`. The library *is* the Perf harness, and `tests/test_perf_*.lua` pin it inside the gate | none |
| Complexity (sighted, kit rev 37) | **pass**: `0 warnings (fun rate 0.00), 42163 NLOC / 6382 funcs, avg CCN 2.0 (max 15)`. No blind-file note was printed, so 0 blind files | `ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` |
| `make test` | **not applicable**: no root `Makefile` | none |
| Kit sync (source to own copy) | **pass**: `diff -r testkit tests/_kit` is empty, and `Kit.VERSION = 37` in both | `diff -r testkit tests/_kit` |
| Vendor sync (source to consumers) | **pass**: `diff -rq LibKa0s/LibKa0s AbsorbTracker/libs/LibKa0s` is empty, and every one of the 11 consumers' `tests/_kit` matches `LibKa0s/testkit` | from `GIT/`, as shown |
| Cross-addon, class 1 (slash tokens) | **clean**: 22 roots across 11 addons, `uniq -d` empty, 0 raw `SLASH_*` in TOC-loaded source | the overlay's two loops, TOC-derived load-list scope |
| Cross-addon, class 2 (vendored minors) | **clean**: one line, `Bus:2 Compat:1 Core:10 DebugLog:19 Env:1 Item:2 Launcher:5 Lifecycle:3 Media:4 Options:28 Perf:14 Pool:3 Schema:2 Slash:19 Widgets:12` | the overlay's loop |
| Cross-addon, class 3 (payload bytes) | **clean**: 0 `diff -rq` lines against AbsorbTracker's copy (the reference) | the overlay's loop |
| Cross-addon, class 4 (`## Interface:`) | **clean**: one value, `120100` | the overlay's loop |

**Baseline comparison.** Measured at tag `v1.70.0` (from `git -C LibKa0s describe --tags --abbrev=0`). The overlay's recorded baseline is v1.56.0, so the library-derived rows differ because the brief is stale, not because anything drifted. All four collision classes are clean, which matches the recorded 2026-09-23 outcome. The roster is still 11 (`WowAddonStandards/standards/ADDONS.md`).

**Committed artifacts compared with the fresh run**
- `docs/test-cases.md` matches the fresh `--list` (2089).
- `docs/automated-tests/` newest bundle `20261007-102304` was measured at `6b401e1`, 6 commits behind HEAD. `git diff --stat 6b401e1 HEAD -- LibKa0s testkit tests tools` is **empty**: the intervening commits are documentation and release records only, so its figures still describe the code. Its `complexity.txt` totals (`42163 / 6.7 / 2.0 / 54.3 / 6382 / 0`) equal today's run.
- `docs/performance.md` does not exist (not applicable to a library, per `CLAUDE.md`).

**Standards cross-check.** Ran against Ka0s WoW Addon Standard **v2.76.1** (2026-10-07). The index and all 27 section files listed under its Sections heading were fetched with `curl` from `raw.githubusercontent.com/.../master` into scratch. The fetched `testing.md` is byte-identical, after CR-strip, to the local `../WowAddonStandards` copy. The README names v2.76.0; v2.76.1 is a patch, and this review raises nothing against that pointer.

**Status of the 2026-09-23 review.** Its only deferred finding, F-014 (Schema `instanceId` pass-through), now reads as fixed in the source: `LibKa0s/Schema.lua:380` is `if type(get) == "function" then return get(instanceId) end`. Nothing is carried over.

---

## Medium

### F-001 — `LineChart` draws unclipped, and `ChartMath.Dashes` has no bound, so one far off-plot point in a dashed range creates an unbounded number of permanent Line regions `[correctness]` `[perf]`

- **Where:** `LibKa0s/WidgetsLineChart.lua:212`, `while s < len do` (the dash loop, with no cap on iterations). `:362`, `if inDash(sr, a.x, b.x) then dashed(c, x1, y1, x2, y2, color, th) else seg(...) end` (no clip to the plot rectangle). `:369`, `if lo == nil or hi == nil then lo, hi = dataRange(d.series) end` (a host-supplied `yMin`/`yMax` is trusted even when the data lies outside it). `:236`, `l = c:CreateLine(nil, "ARTWORK")` (every dash is a pooled region that is never destroyed).
- **Problem:** A segment's pixel length is used as-is. A point whose y is far outside a host-given `[yMin, yMax]`, or whose x is far outside `[xMin, xMax]`, produces a segment millions of pixels long. When that segment's midpoint falls in the series' dashed range, `Dashes` returns `len / 7` four-number tables, and `dashed()` turns each one into a `CreateLine` region.
- **Impact:** Measured headless today (scratch script loading the payload file under a stub LibStub, through `ka0s-bounded`): `Dashes(0,0,0,1e5)` returns **14 286** dashes, and `Dashes(0,0,0,1e6)` returns **142 858** dashes using **22 MB**. In the client, each dash also becomes a Line region that lives for the session (the file's own header, `:224`: "Regions are never destroyed in the client"). The result is a hitch or freeze on that render and a permanent pool of that size. Non-finite input does not hang: `NiceTicks(0, 1/0)` returns 0 ticks.
- **Reachability:** No shipping host reaches this today. LootHistory, the only consumer (`modules/TimelineModel.lua:475`, `local yMin, yMax = TM.YRange(series)`), derives the y range from the same series, and its points lie inside its own x window. It is reached by a second consumer that passes a fixed y range, such as a 0–100 % axis with an outlier, or that leaves points outside `[xMin, xMax]`. The `library-stack-§7` deviation row expects exactly that kind of second consumer.
- **Coverage:** No case draws a point outside the domain. `tests/test_widgets_linechart.lua` covers markers outside the domain (`:111`) but not series points.

### F-002 — `Autocomplete`'s hooks are installed once per box and die silently if anything later calls `SetScript` on a hooked script, and a fresh `lib.Autocomplete` call cannot reinstall them `[design]` `[api]`

- **Where:** `LibKa0s/WidgetsAutocomplete.lua:345-349`:
  ```lua
  local function hookBox(box)
    if hooked[box] then return end
    hooked[box] = true
    for _, script in ipairs(HOOK_ORDER) do box:HookScript(script, dispatch(HOOKS[script])) end
  end
  ```
- **Problem:** In the client, `SetScript` replaces a script together with every `HookScript` wrapper on it. After a host, a skinning addon or a later rebuild calls `box:SetScript("OnTextChanged", …)`, the dispatcher for that script is gone. Because `hooked[box]` is still `true`, the documented recovery (call `lib.Autocomplete(box, opts)` again, `:370-373`) never re-hooks. The API document (`docs/api/Widgets/version-12.1.4.2.1-docs.md:1216-1219`, "hooked once per box, so the host's own handler runs first") does not say that the host's scripts must be set **before** the call.
- **Impact:** With `OnTextChanged` replaced, the list never opens. With `OnEditFocusLost` or `OnHide` replaced, a list stays up over the UI after the box is left. No error is raised in either case.
- **Reachability:** No player reaches this today. Both adopters set their scripts first. LootHistory's `modules/BrowserFilterBar.lua:426` says so explicitly ("AFTER the scripts above, because the library HOOKS them"), and BankLedger's `modules/Browser.lua:1093-1100` sets its scripts before `:1105`. It is reached by any future host that re-sets a script after attaching. The precondition is known only to one consumer's comment, not to the contract.
- **Coverage:** The suite builds boxes whose scripts are all set before attachment (`tests/test_widgets_autocomplete.lua:46-63`, `newBox`), so no case exercises a later `SetScript`. The mock may not model `SetScript` clearing hooks. That is unverified, because the kit was not read for it.

---

## Low

### F-003 — The chart's hover does not resync on `SetData` or `Render`, so every host must remember `ClearHover` before repainting `[design]`

- **Where:** `LibKa0s/WidgetsLineChart.lua:409`, `function c:SetData(data) self.__data = data end`. `:430`, `if i ~= self.__hoverIndex then` (the crosshair moves and `onHover` fires only when the index changes).
- **Problem:** The behavior is documented (`version-12.1.4.2.1-docs.md:1125-1129`), but the documented remedy is host code. The one consumer had to write it: LootHistory `modules/Timeline.lua:308`, `self.chart:ClearHover()`, with a three-line comment explaining why. A resize under a resting cursor (`:463`, `OnSizeChanged` → `Render`) also leaves the crosshair at the old pixel until the index changes.
- **Impact:** A second host that skips the call shows the previous data's tooltip values and crosshair after a live repaint.
- **Reachability:** No player reaches this today, because LootHistory compensates. A future chart host whose data refreshes while the cursor rests on the chart would hit it.

### F-004 — The chart owns `OnSizeChanged` → `Render`, so a host that also renders from its own layout pass may draw twice `[perf]` *(unverified)*

- **Where:** `LibKa0s/WidgetsLineChart.lua:463`, `c:SetScript("OnSizeChanged", function(self, w, h) self:Render(w, h) end)`. In the consumer, LootHistory `modules/Timeline.lua` `TL:Layout` calls `anchorBody(...)` and then `self.chart:Render(self.chartW, …)`.
- **Problem:** When the host's re-anchor changes the chart's size, the chart renders once from its own script and once from the host's explicit call, which may use a different height.
- **Impact:** Double LTTB thinning, label work and pooled-region repainting per layout pass. The cost is unmeasured: there is no perf scenario for the chart, and the Perf harness has no chart bucket.
- **Reachability:** Any LootHistory player who resizes the browser while on the Timeline tab. It is a cost, not a visible defect.

### F-005 — `Autocomplete` calls host `provider` and `onPick` unprotected, unlike the library's other host callbacks `[error-handling]`

- **Where:** `LibKa0s/WidgetsAutocomplete.lua:239`, `local items = self.__provider(text)` (from a `C_Timer.After` callback, `:289-291`). `:264`, `if onPick then onPick(item) end`.
- **Problem:** Other host callbacks in the same major run under `pcall` with a reported fallback, for example `tooltipPlace` (`version-12.1.4.2.1-docs.md:750`, "calls it under `pcall`"). A provider that raises does so on every debounce. That is one error per typing burst, and the list never shows.
- **Impact:** A host bug surfaces as an error loop while typing, with no line naming the widget.
- **Reachability:** Only a host whose provider raises. Neither adopter is known to.

### F-006 — `ParseValue` accepts non-finite numbers, and the write seam stores them on a number row with no `min`/`max`/`validate` `[correctness]` *(in-client `tonumber` unverified)*

- **Where:** `LibKa0s/SlashParse.lua:128`, `local n = tonumber(args[1])`. `:140-141`, `if row.min then n = math.max(row.min, n) end` / `if row.max then n = math.min(row.max, n) end`. `LibKa0s/Schema.lua:519`, `storeWrite(set, value, parts, root, first)` (no type or finiteness check of its own).
- **Problem:** Under Lua 5.1 here, `tonumber("nan")`, `tonumber("inf")` and `tonumber("1e400")` answer `nan`, `inf` and `inf`. Clamping happens to absorb NaN, because `math.max(min, nan)` answers `min` (verified: `math.max(-100, 0/0)` → `-100`, while `math.max(0/0, -100)` → `-nan`), so the argument order is load-bearing and nothing records that. A row with no bounds stores the non-finite value.
- **Impact:** A NaN or inf setting reaches layout math, and how it serializes into SavedVariables is unverified.
- **Reachability:** Only a player typing `/<slash> set <path> nan` on an unbounded number row. The sampled consumer rows all carry `min`/`max`, and no unbounded row was confirmed. Whether WoW's `tonumber` accepts `"nan"` is **unverified**.

### F-007 — The `owners`/`hooked` comment claims entries are collected, which Lua 5.1 weak keys cannot do here `[naming]`

- **Where:** `LibKa0s/WidgetsAutocomplete.lua:67-70`, "Weak-keyed: a box the host drops takes its entries with it."
- **Problem:** Lua 5.1 has no ephemerons. The value (`h.__box`, `:363`) strongly references its key, so an `owners` entry is never collected.
- **Impact:** None at runtime, because client frames are never collected anyway. The comment misstates the invariant.
- **Reachability:** A comment, with no runtime effect.

### F-008 — `opts.maxRows` accepts a non-integer, which desynchronizes the row count from the list height `[correctness]`

- **Where:** `LibKa0s/WidgetsAutocomplete.lua:194`, `local n = min(#items, h.__maxRows)`. `:209`, `list:SetHeight(n * h.__rowH + 2 * AC.PAD)`. `:351-353`, `positive()` checks only `> 0`.
- **Problem:** `maxRows = 2.5` with 8 items draws 2 rows (`for i = 1, 2.5`) in a 2.5-row-tall list.
- **Impact:** A visible empty half-row.
- **Reachability:** Only a host passing a fractional `maxRows`. LootHistory passes `SUGGEST_MAX`, which was not read and is presumed an integer.

### F-009 — `skin()` rebuilds the backdrop on every render `[perf]` *(unverified)*

- **Where:** `LibKa0s/WidgetsAutocomplete.lua:166`, `list:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })`, reached from `render` (`:193`) on every debounce tick that shows rows.
- **Problem:** `SetBackdrop` re-lays the backdrop's pieces and allocates a table on each call. Only the colors need to follow the box.
- **Impact:** Small garbage and region work per typing pause. Not measured.
- **Reachability:** Every player typing in a LootHistory or BankLedger search box.

### F-010 — The chart's default x labels use the C runtime's English month abbreviation `[locale]` *(in-client unverified)*

- **Where:** `LibKa0s/WidgetsLineChart.lua:304`, `return date("%d %b", x)`.
- **Problem:** `%b` comes from the C locale, not the client locale. The widget offers `opts.formatX`, but LootHistory passes only `formatY` (`modules/Timeline.lua:249-253`; `grep -c formatX` = 0).
- **Impact:** A deDE or frFR player sees "07 Oct" style labels on the Timeline axis for spans of a day or more.
- **Reachability:** Any non-English LootHistory player viewing a Timeline span of one day or more, if the client's `date` is C-locale. That condition is unverified.

### F-011 — The three v1.69.0 and v1.70.0 suites carry no `-- red under:` notes on their negative assertions `[tests]`

- **Where:** `tests/test_widgets_autocomplete.lua`, `tests/test_widgets_linechart.lua` and `tests/test_widgets_linechart_math.lua` have **0** `red under` comments (`git grep -c 'red under' -- <those three>` prints nothing). The convention is established elsewhere: `tests/test_launcher.lua` has 46, `tests/test_options_tabs.lua` 41 and `tests/test_options_ids.lua` 41. Example negative cases: `test_widgets_linechart.lua:148-154` ("Clear hides every line", `assertEqual(shownLines(c), 0)` with no positive precondition in the case) and `test_widgets_autocomplete.lua:369-375` ("a debounce still waiting when focus goes shows nothing", `assertEqual(#calls, 0)`).
- **Problem:** `testing-§12` SHOULD-level: the mutation that reddens each negative case is not recorded. On reading, both examples look falsifiable. The first relies on another case to prove that `Render` draws; the second relies on `box:type` arming a timer. The mutation was **not run**, because this agent does not modify the repo.
- **Impact:** The next author must work out the falsification again.
- **Reachability:** The test inventory only. The shipped code is not affected.

---

*No `[upstream]` findings. This repo is the upstream, it vendors nothing beyond its own `tests/_kit/` copy of `testkit/`, and that copy is byte-identical to the source. No `[cross-addon]` findings: all four classes are clean.*
