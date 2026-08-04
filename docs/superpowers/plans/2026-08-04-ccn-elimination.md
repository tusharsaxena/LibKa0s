# CCN elimination — LibKa0s

Branch `feat/fix-ccn`. Design: `LibKa0s/docs/superpowers/specs/2026-08-04-ccn-elimination-design.md`.

**7 functions** with `lizard` CCN > 15. Target: every one at CCN <= 15, behavior unchanged.

## Exit criteria

1. `luacheck . --quiet` — 0 warnings, 0 errors.
2. `lua5.1 tests/run.lua` — all pass, count >= baseline.
3. `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` — no CCN > 15.
4. No behavior change. No version bump, no CHANGELOG, no merge, no tag.

## Rules

- Preferred shapes, in order: table-driven dispatch; a named file-local helper for a
  self-contained block; a data table + loop replacing repeated defaulting; splitting a
  builder into N small builders.
- No dumping a body into one helper to game the metric. Every resulting function must be a
  unit a reader can name.
- Dispatch/defaults tables are **module-level**, built once at file load — never per call.
- `lizard` counts `and`/`or` as decisions. Prefer `== nil` over `or` wherever a stored
  `false` or `0` must survive.
- Hot paths must not gain a per-call allocation.
- Sixteen functions across the collection have no coverage; where this file says
  `Coverage: NONE`, write a characterization test pinning current behavior **before**
  refactoring.

## Functions

### `P.Progress` — CCN 32 → target 13

`LibKa0s/Perf.lua:334-373` · pattern `ternary-state-chain` · risk **medium**

**What it does.** Returns the perf run's step-state map for the panel to render — start / measureA / measureB / finish / report / dump / cancel, each one of locked | ready | busy | done | used | cancel. Strictly linear: exactly one step is `ready` at a time.

**Where the branches come from.** The highest CCN in the repo, and it is entirely `and`/`or` ternary chains. Three 6-to-8-term `x and "busy" or (y and "done") or ((z and w) and "ready") or "locked"` expressions for a/b/fin (21), plus the aBusy/bBusy/finished derivations (4) and the start/cancel ternaries (6).

**Fix.** Replace the ternary chains with a table-free priority helper and split the arm derivation out.
1. File-local, next to Progress: `local function pick(busy, done, ready) if busy then return "busy" end; if done then return "done" end; if ready then return "ready" end; return "locked" end` (CCN 4). This encodes the SAME precedence the or-chains encode: busy > done > ready > locked.
2. `local function armStates()` computing and returning `a, b, fin, finished`:
   `local aBusy = (P.armed == "active") or (P.recording == "active")`
   `local bBusy = (P.armed == "suspended") or (P.recording == "suspended")`
   `local finished = (not P.run) and (completed.active or completed.suspended)`
   `local a   = pick(aBusy, completed.active, P.run and not bBusy)`
   `local b   = pick(bBusy, completed.suspended, P.run and completed.active and not aBusy)`
   `local fin = pick(nil, finished, P.run and completed.suspended and not bBusy)`  (CCN 13)
3. P.Progress keeps the `review(key)` closure verbatim and just assembles the return table: `start = P.run and "done" or "ready"`, the three arm fields, report/dump via review, `cancel = (P.run or P.armed or P.recording) and "cancel" or "locked"` (CCN 7).
No per-call allocation is added — Progress already builds its return table, and `pick` takes plain values. Note it is called from PerfPanel.lua:96 once per button per panel refresh, not per frame, so this is not a hot path.

**Must not change.** The truthiness semantics of the or-chains must be preserved exactly, and `pick` must return the STRING states, never the truthy values it was handed — the original chains return the literal "done"/"ready" so a truthy `completed.active` table can never leak into the result. `fin` genuinely has no busy state; pass nil rather than inventing one. `review()` is checked BEFORE `finished` in spirit — `used` is sticky and stays clickable, so a report/dump run via a typed command keeps its mark. `cancel` returns the literal "cancel", not "ready", because the panel colors it separately. The one-ready invariant is asserted directly at tests/test_perf_panel.lua:129.

**Coverage.** tests/test_perf_panel.lua:39-260 — extensive and direct: start done/ready, measureA busy for both armed and recording, B locked meanwhile, the exactly-one-ready invariant (:129), redo relocking B (:149-152), A offered again (:174), cancel locked-before/cancel-during (:253-255). Strongest coverage of any function in this list; safe to refactor against.

---

### `O.RenderRows` — CCN 25 → target 11

`LibKa0s/OptionsWidgets.lua:603-674` · pattern `table-render-loop` · risk **medium**

**What it does.** Schema-driven page renderer: walks declared rows, emits a Section heading when `group` changes, packs rows two-per-flow-row (respecting `solo` and `skipRender`), pcall-guards each row so one raising row cannot take the page down, fires one-shot `pairWith` hooks beside a row and one-shot `afterGroup` hooks at the end of a group, then runs a layout pass.

**Where the branches come from.** One loop body carrying five independent concerns. The two one-shot hook conditions dominate: the pairWith guard is a 5-term `and` chain and the afterGroup guard is a 6-term chain with an embedded `or` (11 of the 25). The rest is the group-change check (2), skipRender (1), solo/pending flush logic (4), the pcall ok/else (1) and the entry + DoLayout guards.

**Fix.** Hoist the duplicated row-plumbing and extract the two hook conditions, all as file-locals inside the same enclosing do-block (they need `L`, `HALF`, `O`, `lib`).
1. Hoist `startRow` to a single file-local `local function startRow() ... end` — it is byte-identical in RenderGrid (OptionsWidgets.lua:555-560) and RenderRows (620-625). Removes a duplicate, no CCN change.
2. `local function renderRowGuarded(ctx, row, parent)` — the pcall(O.RenderField, ...) plus the ROW_FAILED print, returns ok (CCN 3). RenderGrid's `renderInto` (571-583) becomes a two-line wrapper over it.
3. `local function shouldFirePair(pairWith, firedPair, row, pendingCount)` — returns the 5-term boolean (CCN 6).
4. `local function shouldFireAfter(afterGroup, firedAfter, row, nextRow)` — returns the 6-term boolean (CCN 7).
The loop body then reads as five short `if`s: group change (2), skipRender (1), solo pre-flush (2), pendingRow default (1), ok (1), shouldFirePair (1), solo-or-full flush (2), shouldFireAfter (1), plus the entry guard and DoLayout (2) → CCN 11.
All four helpers are file-level closures created once at load, not per call, so nothing new is allocated per render.

**Must not change.** The one-shot sets `firedAfter`/`firedPair` MUST stay call-local (created fresh in each RenderRows call) — consuming the caller's tables would make a re-render of the same page silently drop every inline button, which is exactly what the current comment warns about and what tests/test_options_widgets.lua:620 pins. Flush ordering is load-bearing: a group heading flushes the PREVIOUS group's tail row before the Section is emitted, an afterGroup hook flushes so its buttons start on a fresh line, and a pairWith hook only fires when pendingCount == 1 (i.e. it takes the second cell). Each row stays individually pcall-guarded — a page-level guard is not equivalent. In-game-only: two-column flow layout and the AceGUI layout pass at the end.

**Coverage.** tests/test_options_widgets.lua — :320 (rows render), :362 (RenderGrid guards each item the way RenderRows guards each row), :560 (one Heading per group in first-seen order), :620 (caller's afterGroup/pairWith tables left intact), :649 (layout pass at the end). No direct case for `solo`, for `skipRender`, or for the pairWith `pendingCount == 1` condition — add characterization cases for those three before refactoring.

---

### `lib.FormatValue` — CCN 25 → target 6

`LibKa0s/Slash.lua:87-118` · pattern `elseif-dispatch + field-defaulting` · risk **medium**

**What it does.** Renders a stored settings value for chat display according to the row's declared type — color (both named-key and positional table shapes), number (with optional row.fmt), bool, empty string as (none) — guarding every input through Core's concat-safety seam first so a combat-protected 'secret' value renders as the sentinel instead of raising inside string.format.

**Where the branches come from.** An if-chain over row.type plus a defaulting block. Eight of the 25 come from the four `local r = v.r or v[1] or 0` component-defaulting lines alone; another 4 from the single `if not (safe and safe and safe and safe)` guard; the remaining ~12 are the four type branches with their per-branch concat-safety guards and the bool ternary.

**Fix.** Table-driven dispatch on row.type, plus a data table for the color components. All module-level, allocated once at load.
1. `local COLOR_KEYS = { { "r", 1, 0 }, { "g", 2, 0 }, { "b", 3, 0 }, { "a", 4, 1 } }` — named key, positional index, default.
2. `local function colorComponents(v)` loops COLOR_KEYS with `local n = v[k[1]] or v[k[2]] or k[3]` (keep `or`, NOT a nil-check — the `or` semantics are what ships) and returns nil as soon as a component fails core.IsConcatSafe, else the four numbers (CCN 5).
3. `local FORMATTERS = {}` keyed by row.type, each `function(row, v)` returning a string or nil to fall through:
   `FORMATTERS.color` — `if type(v) ~= "table" then return nil end; local r,g,b,a = colorComponents(v); if not r then return core.SECRET end; return ("{%.2f, %.2f, %.2f, %.2f}"):format(r,g,b,a)` (CCN 3)
   `FORMATTERS.number` — the IsConcatSafe guard, row.fmt, tostring (CCN 3)
   `FORMATTERS.bool` — `return v and "true" or "false"` (CCN 3)
   `FORMATTERS.string` — `if v == "" then return lib.STRINGS.NONE end` (CCN 2)
4. `function lib.FormatValue(row, v) row = row or {}; if v == nil then return "nil" end; local f = FORMATTERS[row.type]; local s = f and f(row, v); if s ~= nil then return s end; return core.SafeToString(v) end` (CCN 6).
Fall-through is preserved exactly: a non-table `color`, a non-empty `string`, and an unknown row.type all reach core.SafeToString as they do today. No formatter can return false, so `f and f(row, v)` is safe.

**Must not change.** Concat-safety is the whole point: EVERY branch must guard its input through core.IsConcatSafe/SafeToString before a value reaches string.format, and a secret must render as core.SECRET on every branch (tests/test_slash.lua:145-155 checks all four). Both color storage shapes must keep working with NAMED KEYS WINNING over positional — and the `or` chain, not a nil-check, is the shipped semantic. A colour whose alpha is absent still renders 1.00, not 0.00. Non-table color and non-empty string must fall through to SafeToString, unchanged. `nil` renders as the literal "nil" before any type dispatch. Not a hot path (chat echo / settings list), but keep COLOR_KEYS and FORMATTERS at module scope so nothing is built per call.

**Coverage.** tests/test_slash.lua:113-220 — every schema type (:120), row.fmt applied, empty string as (none), nil, the secret sentinel on all four branches (:145), and positional colour reading incl. a secret component (:159-174), plus the FormatKV wrapper (:214). Also exercised via the host-hook cases at :595-712. Very strong; safe to refactor against.

---

### `lib.ApplySkin` — CCN 21 → target 6

`LibKa0s/Core.lua:119-171` · pattern `guard-stack` · risk **low**

**What it does.** Applies a Ka0s skin table to a frame: SetBackdrop, backdrop + border colors, lazily synthesizes a 1px inner-highlight child frame and tints it, then tints the frame's optional title FontString and divider texture. Every step is guarded on type() rather than truthiness so a mock frame whose metatable answers every key cannot make it raise.

**Where the branches come from.** Four independent guarded blocks in one body: the entry guard + skin defaulting (`not frame or not frame.SetBackdrop`, `type(skin)=="table" and skin or lib.SKIN` = 4), bg/border (2), the inner-border block which is a 6-deep nested guard stack including create-once and re-tint (10), and the title/divider accents which are two 3-condition `and` chains (6).

**Fix.** Split into three file-local helpers above lib.ApplySkin, all `local function`, no new globals.
1. `local function applyBackdrop(frame, skin)` — SetBackdrop + the bg and border color blocks verbatim (CCN 3).
2. `local function ensureInnerBorder(frame, skin)` — the `type(frame.innerBorder) ~= "table"` create-once block, returns `frame.innerBorder` (CCN 4: the not-a-table check, `type(inner)=="table"`, `inner.SetPoint`, `inner.SetBackdrop`).
3. `local function applyInnerBorder(frame, skin)` — the `type(skin.innerBorder)=="table" and type(CreateFrame)=="function"` gate, calls ensureInnerBorder, then the `type(inner)=="table" and type(inner.SetBackdropBorderColor)=="function"` re-tint (CCN 6).
4. Replace the title/divider pair with a module-level constant descriptor table + loop — allocation-free, defined once at file scope next to lib.SKIN:
   `local ACCENTS = { { skinKey="title", frameKey="title", method="SetTextColor", n=3 }, { skinKey="divider", frameKey="divider", method="SetColorTexture", n=4 } }`
   `local function applyAccents(frame, skin)` loops ACCENTS, keeps the identical `type(skin[k])=="table" and type(frame[k])=="table" and type(frame[k][method])=="function"` triple guard once, and calls `target[method](target, unpack(c, 1, a.n))` — note `unpack` must be `unpack(c, 1, a.n)` so the divider still gets its 4th alpha component and the title still gets exactly 3 args (CCN 5).
lib.ApplySkin then reduces to the entry guard, the skin default, and four calls (CCN 5).

**Must not change.** The type()-not-truthiness discipline is load-bearing and is the documented reason this function looks the way it does — a consumer mock whose metatable answers every key with a function must not make it raise. The inner highlight must be created EXACTLY ONCE across repeated ApplySkin calls on the same frame (test_core.lua:188 pins this) and must be re-tinted on every call. Title gets 3 args, divider gets 4 — do not collapse them to one arity. In-game-only: that the inner frame is inset 1px on both axes and sits inside the black edge.

**Coverage.** tests/test_core.lua:125-244 — 7 cases: no-op without SetBackdrop, backdrop + both colors, inner highlight synthesized exactly once, survives an answers-everything metatable, title + divider tinting, tolerates neither, honours an explicit skin table. Good coverage; no new characterization test needed.

---

### `setEnabled (inner closure of lib.PatchAlwaysShowScrollbar)` — CCN 18 → target 4

`LibKa0s/OptionsScroll.lua:68-85` · pattern `mirrored-branch-duplication` · risk **low**

**What it does.** Enables or disables the always-shown AceGUI scrollbar: on enable it calls scrollbar:Enable, tints the thumb white and enables the up/down step buttons; on disable it zeroes the scroll value, disables the bar, dims the thumb gray and disables the step buttons. Early-returns when the state has not changed.

**Where the branches come from.** Two near-mirror-image branches, each doing the same four optional-object/optional-method dances: `thumb and thumb.SetVertexColor`, `upBtn and upBtn.Enable`, `downBtn and downBtn.Enable` (2 each), duplicated across the if and the else. 14 of the 18 come from that duplication alone.

**Fix.** Collapse the two branches into one parameterized apply, keeping call ORDER byte-identical.
Add a file-local helper at module scope (next to THUMB_ON/THUMB_OFF), truthiness-guarded exactly as today — NOT `type(...)=="function"`, because the existing fixtures assign plain fields and the truthiness test is what ships:
  `local function callIf(obj, method, ...) if obj and obj[method] then obj[method](obj, ...) end end`  (CCN 3)
Inside PatchAlwaysShowScrollbar, one closure that preserves ordering:
  `local function applyState(action, tint) callIf(scrollbar, action); callIf(thumb, "SetVertexColor", unpack(tint)); callIf(upBtn, action); callIf(downBtn, action) end`  (CCN 1)
setEnabled becomes:
  `if currentEnabled == want then return end; currentEnabled = want; if not scrollbar then return end`
  `if want then applyState("Enable", THUMB_ON) else scrollbar:SetValue(0); applyState("Disable", THUMB_OFF) end`  (CCN 4)
THUMB_ON/THUMB_OFF stay module-level constants, so nothing is allocated per call.

**Must not change.** Order of calls within a state change: bar first, thumb tint second, up button, down button. On disable, `scrollbar:SetValue(0)` fires BEFORE Disable and is unconditional (not guarded like the rest) — keep it that way. The `currentEnabled == want` short-circuit must stay, because MoveScroll reads `currentEnabled == false` to swallow wheel input, and OnRelease resets it to nil. Guards must remain truthiness checks, not type checks, or mocks that assign non-function fields change behavior. In-game-only: the gray-vs-white thumb reading as 'shown but inert'.

**Coverage.** tests/test_options.lua:616-635 covers the enable/disable transition via scrollbar.Enable/Disable stubs only. The thumb tint and the up/down step buttons are NOT exercised (the fixture scrollbar has no GetThumbTexture and no GetName, so thumb/upBtn/downBtn are all nil). Add a characterization test with a named scrollbar + thumb stub and _G[name.."ScrollUpButton"/"ScrollDownButton"] before refactoring.

---

### `lib.PatchAlwaysShowScrollbar` — CCN 17 → target 8

`LibKa0s/OptionsScroll.lua:46-159` · pattern `options-builder` · risk **low**

**What it does.** Idempotently patches one AceGUI ScrollFrame so its scrollbar and 20px gutter are always shown: resolves the scrollbar/thumb/step-button handles, stashes the stock FixScroll, forces the gutter layout, then installs FixScroll, MoveScroll and OnRelease overrides that restore everything when AceGUI recycles the widget.

**Where the branches come from.** CCN is the OUTER body only (lizard scores the four nested closures separately). It comes almost entirely from handle resolution: four `a and a.b and a:b() or nil` defaulting chains for thumb, sbName, upBtn, downBtn (10 of the 17), plus the 2-condition entry guard and the three-block gutter forcing (4).

**Fix.** Extract the handle resolution and the gutter forcing into file-local helpers at module scope; both are stateless functions of the widget.
1. `local function stepButtons(scrollbar)` — returns `sbName, upBtn, downBtn` from the two `_G[sbName .. ...]` lookups plus the GetName chain (CCN 8).
2. `local function thumbOf(scrollbar)` — the `scrollbar and scrollbar.GetThumbTexture and scrollbar:GetThumbTexture() or nil` chain (CCN 4).
3. `local function forceGutter(scroll, scrollbar)` — sets scrollBarShown, Show, the BOTTOMRIGHT -GUTTER point and the content width inset (CCN 5; the same three blocks also appear inside the FixScroll override — do NOT try to share them with FixScroll, that override re-checks `self.scrollBarShown` first and its semantics differ).
The outer body then reads: entry guard, stash originals, `local scrollbar = scroll.scrollbar`, `local thumb = thumbOf(scrollbar)`, `local sbName, upBtn, downBtn = stepButtons(scrollbar)`, `forceGutter(scroll, scrollbar)`, then the four closure assignments (CCN 3).

**Must not change.** Idempotency via the shared `_ka0sAlwaysScrollbar` marker — the marker name must stay generic because AceGUI pools ScrollFrames across every addon in the session. `scroll.__stockFixScroll` must still be set for observability. Handle resolution must stay tolerant of a nil scrollbar and a nameless scrollbar (headless). OnRelease must continue to restore all three methods from the CLOSURE upvalues, so the extraction must not move the `origFixScroll`/`origMoveScroll`/`origOnRelease` capture out of the outer body. In-game-only: that the gutter persists so every settings page's content ends at the same x.

**Coverage.** tests/test_options.lua:595-648 — 4 cases: lazy/patched-once EnsureScroll incl. the gutter inset assertion, idempotency, FixScroll enable/disable, OnRelease restoring the stock FixScroll and clearing the marker. The handle-resolution paths (named scrollbar, step buttons) are NOT covered — see setEnabled above; one fixture upgrade covers both.

---

### `P.FormatReport` — CCN 16 → target 5

`LibKa0s/Perf.lua:492-555` · pattern `report-section-builder` · risk **low**

**What it does.** Renders a saved perf record as a list of plain strings (returned, not printed, so the headless suite can assert on exact lines): a capture header, the context lines, the two FPS arms plus their delta, the bucket table indented by nesting depth with a ms/s column derived from active seconds only, and a trailing 'buckets nest — do not sum' note.

**Where the branches come from.** Four unrelated report sections in one body. Each contributes 3-5: the header's label defaulting ternary (2), the two-arm loop with its sampled/not-sampled branch and the both-arms delta check (5), the bucket loop with its `if b` and the `secs > 0 and (...) or 0` ternary (5), and the nesting-pairs loop with its 2-term guard and the non-empty check (4).

**Fix.** Split into three section builders that each take the existing `add` closure, so line ORDER and every format string stay byte-identical. Declare them as file-locals just above P.FormatReport.
1. `local function addFpsLines(add, f)` — the two-arm `for _, name in ipairs({"active","suspended"})` loop and the delta branch. Hoist the `{"active","suspended"}` literal to a module-level `local FPS_ARMS = { "active", "suspended" }` while you are there (CCN 5).
2. `local function addBucketLines(add, record, secs)` — the `depthOf` local (keep it nested here, it is only used by this section), the two header `add` calls and the BUCKET_ORDER loop (CCN 5).
3. `local function addNestingNote(add, record)` — the pairsOut loop and the `#pairsOut > 0` check (CCN 5).
P.FormatReport keeps `lines`, `add`, the capture header with its label ternary, the ContextLines loop, then three calls and `return lines` (CCN 5).

**Must not change.** Every format string, every column width and the exact line ORDER are the contract — the headless suite asserts on concatenated output. `add`'s `select("#", ...) > 0` varargs trick must survive being passed as a value. ms/s divides by ACTIVE seconds only (tests/test_perf_core.lua:322 pins this) and must guard `secs > 0`. `depthOf` reads `record.buckets[key].within` first and falls back to P.BUCKET_WITHIN, with the 8-deep guard against a malformed descriptor. The unsampled-arm line is '(not sampled)', never zeros.

**Coverage.** tests/test_perf_core.lua:250-362 — 9 cases covering the header, unsampled arm, both arms + delta, ms/s from active seconds only, the nesting warning, omitted never-fired buckets and nested-bucket indentation. tests/test_perf_run.lua:274 covers the caller ordering it inside. Excellent coverage.

---
