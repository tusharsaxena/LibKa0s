# 02 — Proposed Changes (HLD + LLD)

**Standard resolved:** Ka0s WoW Addon Standard **v2.14.0 (2026-07-30)**, fetched from
`https://github.com/tusharsaxena/WowAddonStandards` — `standards/STANDARDS.md` plus all 23 section
files discovered from its Sections list. The standards cross-check below is a **guardrail on this
remediation**, confirming no proposed change introduces a new deviation. It is not a compliance
audit; pre-existing deviations unrelated to these changes are out of scope
(`wow-addon:standards-audit` owns those).

---

## HLD — themes

### Theme A — Bring `LibKa0s-Options-1.0` up to the discipline the other four majors already keep

**Rationale.** Four of the five majors converge on one shape: validate the descriptor and `error`
with a message naming the major; default the output sink to the chat frame; declare a dependency
floor and go *absent* rather than half-wired. Options is the youngest and keeps none of the three.
That is not a style difference — each omission has a concrete failure attached (F-001, F-004, F-005),
and each failure is invisible until a panel build a login later.

**Covers:** F-001, F-004, F-005, F-010, F-016.

**Alternatives considered.**
- *Fold `OptionsWidgets.lua` into `Options.lua` so the attach seam disappears.* Rejected. The
  combined file lands near 1000 LOC and rising, and `anti-patterns` #16 peels at 1500; more
  importantly it would destroy the per-file minor, which `library-stack-§7` requires ("Files MUST NOT
  be bumped in lockstep") and which the whole three-file layout exists to preserve.
- *Guard the single `O.AttachTooltip` call site and stop there.* Rejected as the whole fix: it
  converts a crash into a silently tooltip-less Defaults button and leaves the next cross-file reach
  to rediscover the problem. Kept as the belt half of a belt-and-braces pair.
- *Make Options refuse at `:New` when an attach file is missing (mirroring `NEEDS_CORE`).* Adopted —
  this is the shape the other four majors use and the one `docs/releasing.md` already argues for
  ("the module is **absent** rather than half-wired… That is the honest failure").

**Trade-off.** Refusing at `:New` turns a partial vendor from a late crash into an early one. That is
strictly better for diagnosis and strictly worse for a host that vendored `Options.lua` +
`OptionsScroll.lua` deliberately without the widget makers — a configuration nobody ships and which
`docs/releasing.md:87` already declares unsupported ("Copy the WHOLE folder, always").

### Theme B — Close the two cross-boundary staleness gaps the paired guards do not reach

**Rationale.** The paired-secondary guards are correct and are the thing `library-stack-§7` asks for,
but they are scoped to files *within* a major. Two values cross a boundary they do not cover: a
function snapshotted across majors at file load (F-003), and a secondary attaching over a shell with
no declared minimum (F-006). Both are silent, both survive `/reload`, and both make `lib.MODULES`
report a truth that does not match what is executing — which defeats the runtime-answerability the
`MODULES` registry exists for.

**Covers:** F-003, F-006.

**Alternatives considered.**
- *Bump `DebugLog`'s minor whenever `Core`'s moves.* Rejected outright: lockstep bumping is
  explicitly forbidden (`library-stack-§7`) and discards the narrow-skew property that justified
  per-module majors.
- *Have `DebugLog` re-read `LibStub("LibKa0s-Core-1.0")` at each call.* Rejected: `library-stack-§4`
  says resolve once and stash, not per-call. The forwarder-over-the-stashed-**table** form gets the
  liveness without the repeated lookup, because `NewLibrary` mutates the table in place.

### Theme C — Make the secret-safe seam total instead of near-total

**Rationale.** Core's stringifier is exactly the mandated implementation and is the reason this
library is worth adopting. But two public rendering entry points — `Slash.FormatValue` and
`DebugLog:Add` — reach past it, on an unwritten invariant about where their inputs come from.
`events-frames-taint-§8` requires the seam be single and total precisely so no call site has to
reason about that, and `anti-patterns` #35 names `string.format` alongside `table.concat`.

**Covers:** F-008, F-009.

**Trade-off.** One extra `pcall` per rendered settings value and per console line. Bought back, and
then some, by C-9 (F-013), which removes an allocation from the same path.

### Theme D — Fix the two contract bugs the tests cannot currently see

**Rationale.** F-002 (dropped page filter) and F-007 (mutating the caller's tables) are ordinary
bugs, but they share a cause: the fixture models a simpler host than the API promises.
`tests/fixture_options.lua` declares `rowsForPage = function(pageKey)`, so the second argument is
structurally unobservable, and no test renders the same page twice. `testing` requires a covering
test per logic change; here the *fixture* is what has to move first.

**Covers:** F-002, F-007, F-015.

### Theme E — Mechanize the remaining remembered coupling

**Rationale.** The repo already makes the file-minor ↔ changelog coupling mechanical, which is why
`test_versioning.lua` is the best file in the suite. The kit sync is the one remaining coupling still
enforced by a line in a release doc. `library-stack-§7` asks for mechanical over remembered, and
`anti-patterns` #45 explains why this particular drift is the one that will not announce itself.

**Covers:** F-011.

### Theme F — Small correctness and cost cleanups

**Covers:** F-012, F-013, F-014.

---

## LLD — change-set

Change IDs are `C-n`. Each names the findings it closes.

---

### C-1 — Options: attach-completeness check + guarded reach `[F-001, F-016]`

**Files:** `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua`, `LibKa0s/OptionsScroll.lua`
(comment/minor only), `CHANGELOG.md`, `README.md`.

Both halves. The braces half — refuse early, with a message that names the missing file:

```lua
-- at the end of lib:New, replacing the bare `if lib.__AttachWidgets then ... end` pair
if not lib.__AttachWidgets then
  error(MAJOR .. ":New — OptionsWidgets.lua did not load; this major is three files and must be "
    .. "vendored whole (see docs/releasing.md)", 2)
end
lib.__AttachWidgets(O, d)
if lib.__AttachScroll then lib.__AttachScroll(O, d) end   -- scroll patch stays optional-degradable
```

The belt half — the shell stops assuming a maker exists:

```lua
-- EnsureDefaultsButton, Options.lua:234
if O.AttachTooltip then O.AttachTooltip(btn, lib.STRINGS.DEFAULTS_LABEL, panel.defaultsTooltip) end
```

And the comment at `Options.lua:462-465` is rewritten to say what is now true: the widget makers are
**required** and refused-on-absence; the scroll patch is **optional** and degrades (a hidden-on-short-pages
scrollbar is an `options-ui-§10` deviation for the host, but a survivable one, and it is the honest
description of the current guard).

**Asymmetry is deliberate and worth stating in the comment:** `OptionsWidgets.lua` supplies the
public surface (`RenderField`, `Section`, `AttachTooltip`, …) — without it the instance cannot do its
job. `OptionsScroll.lua` supplies one cosmetic override. Refusing on the first and degrading on the
second is the difference between a broken instance and an ugly one.

**Risk:** a host with a stale partial vendor moves from "panel crashes on open" to "`:New` raises at
enable". Louder, earlier, and named — which is the intent. Both `MINOR` in `Options.lua` and the
changelog block must move together.

**Standards conformance:** shaped by `library-stack-§7` (multi-file major must pair by version, not
merely presence — this extends pairing to *presence* too) and `docs/releasing.md`'s own stated
principle. Rejected alternative — collapsing the three files into one — would breach
`library-stack-§7`'s no-lockstep rule and approach `anti-patterns` #16. No new deviation.

---

### C-2 — Options: descriptor validation, matching the other four majors `[F-005]`

**Files:** `LibKa0s/Options.lua`, `README.md`, `tests/test_options.lua`.

Adopt Perf's helper shape verbatim so the five majors read identically:

```lua
local function required(d, key, wanted)
  if type(d[key]) ~= wanted then
    error(MAJOR .. ":New requires descriptor." .. key .. " (a " .. wanted .. ")", 2)
  end
end

function lib:New(d)
  d = type(d) == "table" and d or {}
  required(d, "parentTitle",   "string")
  required(d, "mainPanelName", "string")
  required(d, "get",           "function")
  required(d, "set",           "function")
  required(d, "applyDefault",  "function")
  required(d, "rowsForPage",   "function")
  required(d, "allRows",       "function")
  ...
```

`README.md:353-356` — the paragraph explaining that this module validates nothing — is replaced by
the same descriptor table the other majors get.

**Risk:** this is a **behavior change for a non-conforming host**. A host that today omits, say,
`allRows` and never calls `RestoreAllDefaults` gets a working panel; after this it gets an error at
`:New`. That is the correct trade (the README already marks all seven as required), but it means C-2
is the one change in this set with a real blast radius, and it must land with the consumer
re-vendoring, not before it. This is **not** a contract change under `library-stack-§7`'s
additive-only rule — no field is added, removed or repurposed; the documented contract is merely
enforced.

---

### C-3 — Options: default the printer to the chat frame `[F-004]`

**Files:** `LibKa0s/Options.lua`.

```lua
-- was: local print = d.print or function() end
local print = type(d.print) == "function" and d.print or function(line)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(line) end
end
```

Byte-for-byte the fallback `Slash.lua:201-203` and `DebugLog.lua:164-166` already use.

**Standards conformance:** required by `options-ui-§2` (the lockdown refusal MUST print and MUST NOT
silently no-op). Deliberately does **not** synthesize a chat tag: `slash-commands-§4`'s cyan
`NS.PREFIX` belongs to the host, and Core's own header (`Core.lua:122-124`) records why a library
must never invent one from an abbreviation. The descriptor's `print` stays the intended path; this is
the visible-rather-than-silent floor beneath it.

---

### C-4 — Options: make `CreateOptionsPanel` idempotent `[F-010]`

**Files:** `LibKa0s/Options.lua`, `tests/test_options.lua`.

Guard on `mainCategory`, and drain `pendingPages` as it is consumed so a builder cannot run twice:

```lua
function O.CreateOptionsPanel()
  if mainCategory then return end          -- already built; a second call is a no-op
  ...
  for _, page in ipairs(pendingPages) do page.builder(mainCategory) end
  pendingPages = {}                        -- reassigned, not wiped: nothing else holds it
end
```

**Risk:** a host that (wrongly) relies on a second call to rebuild loses that. None does; the
registry is private and `README.md` describes the call as the one-time build.

**Standards conformance:** keeps the eager-category / lazy-body split intact (`options-ui-§1`,
`options-ui-§9`, `anti-patterns` #22) — the guard is on *re-registration*, never on first
registration, and the body deferral at `Options.lua:374-378` is untouched.

---

### C-5 — DebugLog: forward `MakeCloseButton` instead of snapshotting it `[F-003]`

**Files:** `LibKa0s/DebugLog.lua`, `CHANGELOG.md`.

```lua
-- was: lib.MakeCloseButton = core.MakeCloseButton
-- Forwarder, not a snapshot: LibStub upgrades a major IN PLACE, so `core` (the table) is stable
-- across a Core minor bump while `core.MakeCloseButton` (the value) is not. A DebugLog whose own
-- minor did not move must still draw the newer Core's button.
function lib.MakeCloseButton(parent, onClick)
  return core.MakeCloseButton(parent, onClick)
end
```

`D.MakeCloseButton = lib.MakeCloseButton` (line 175) is resolved at `:New` time — after every file
has loaded — so it picks up the forwarder with no further change.

**Risk:** one extra call frame per console build (once per session per host). Nil.

**Standards conformance:** directly serves `library-stack-§7`'s requirement that the live minor of
every file be *answerable at runtime* — today `lib.MODULES.Core` can report a minor whose code is not
the code running. No new deviation; `library-stack-§4`'s resolve-once rule is honored, since the
`LibStub` lookup itself is still once at load.

---

### C-6 — Declare a shell floor on the secondary files `[F-006]`

**Files:** `LibKa0s/OptionsWidgets.lua`, `LibKa0s/OptionsScroll.lua`, `LibKa0s/PerfPanel.lua`,
`docs/releasing.md`, `tests/test_versioning.lua`.

Mirror `NEEDS_CORE` on the within-major axis, so a secondary states the minimum primary it was built
against and goes absent below it:

```lua
local NEEDS_SHELL = 1
if (lib.MINOR or 0) < NEEDS_SHELL then return end   -- older shell won the race; stay absent
```

Placed **before** the existing paired-minor guard, which is unchanged. `test_versioning.lua` gains a
row asserting every secondary declares a floor, alongside the existing paired-guard row.

**Risk:** none today (all floors are 1). The value is that raising one later is a single edit at the
top of the file rather than a discovery at panel-build time, and `docs/releasing.md:87-90` already
documents the vendoring consequence of raising a floor — that paragraph gains the within-major case.

**Standards conformance:** `library-stack-§7` ("pair its files by version, not merely by presence")
is satisfied today by the re-attach guard; this adds the refusal direction the cross-major floors
already have. Additive, no contract change.

---

### C-7 — Route the last two rendering entry points through the secret-safe seam `[F-008, F-009]`

**Files:** `LibKa0s/Slash.lua`, `LibKa0s/DebugLog.lua`, `tests/test_slash.lua`,
`tests/test_debuglog.lua`.

`Slash.FormatValue` — guard each branch's input rather than only the fallthrough:

```lua
if row.type == "number" then
  if not core.IsConcatSafe(v) then return core.SECRET end
  if row.fmt then return row.fmt:format(v) end
  return tostring(v)
end
```

…and the same shape for the `color` and `string` branches. `bool` needs no guard (a boolean is never
secret, and both arms return a literal).

`DebugLog:Add` — one line:

```lua
function D:Add(tag, msg)
  msg = safeToString(msg)   -- Add is public and ungated; the gated sink already guards, this did not
  ...
```

`D.Debug` (line 431) then hands an already-safe string in, so the double pass costs one extra `pcall`
on a string that is trivially concat-safe.

**Risk:** a host that deliberately passes a table to `D:Add` now sees `<secret>` instead of a table
address. Core's own header (`Core.lua:64-66`) already documents that a bare table renders as the
sentinel, so this is the documented behavior arriving at one more call site.

**Standards conformance:** required by `events-frames-taint-§8` and `anti-patterns` #35 — the seam
must be single and total, and detection must probe `table.concat` (it does; `core.IsConcatSafe` is
reused unchanged rather than reimplemented). Rejected alternative: documenting the "settings values
are never secret" invariant in a comment and leaving the code alone — that is precisely the per-call-site
reasoning §8 forbids.

---

### C-8 — Thread the page filter through `RestoreDefaults`, and stop mutating caller tables `[F-002, F-007, F-015]`

**Files:** `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua`, `tests/fixture_options.lua`,
`tests/test_options.lua`, `tests/test_options_widgets.lua`.

**F-002:**

```lua
function O.RestoreDefaults(pageKey, ctx)
  -- Same filter RenderSchema renders with, so the Defaults button resets exactly the rows the user
  -- is looking at — on a per-unit page the two disagreed, and the button reset every unit's rows.
  for _, row in ipairs(d.rowsForPage(pageKey, ctx and ctx.unit) or {}) do
```

**F-007 — copy on entry, never write to the caller's tables:**

```lua
function O.RenderRows(ctx, rows, afterGroup, pairWith)
  -- Shallow copies: the one-shot bookkeeping below consumes entries, and consuming the CALLER's
  -- table would make a second render of the same page (a unit switch, a ClearScroll + re-render)
  -- silently drop every inline button and paired widget.
  local pendingAfter, pendingPair = {}, {}
  if afterGroup then for k, v in pairs(afterGroup) do pendingAfter[k] = v end end
  if pairWith   then for k, v in pairs(pairWith)   do pendingPair[k]  = v end end
```

…and the two `= nil` writes retarget to the local copies.

**F-015 — resolve the `solo` / `pairWith` contradiction** by making `solo` win, matching its
documented meaning ("render this row alone in the left half of its own line"):

```lua
if not row.solo and pendingPair[row.path] and pendingCount == 1 then
```

**Risk:** F-015's resolution is a behavior choice. If any host relies on the current
solo-plus-partner behavior it would change; the block comment at `OptionsWidgets.lua:419` is the
contract and says otherwise, so the code is what is wrong.

**Fixture change is the prerequisite:** `tests/fixture_options.lua:111` must become
`rowsForPage = function(pageKey, filter)` and record the filter, or F-002 cannot be asserted at all.

---

### C-9 — Small cleanups `[F-012, F-013, F-014]`

**Files:** `LibKa0s/Core.lua`, `LibKa0s/DebugLog.lua`.

- **F-012:** `printer.Format` runs `:format()` on every path. Guard the no-arg case against a
  malformed format string rather than skipping the call:
  `local ok, s = pcall(string.format, safeFmt); emit(ok and s or safeFmt)`.
- **F-013:** hoist the probe's scratch table to a file-level upvalue. The `pcall` stays — it is the
  mandated detector (`events-frames-taint-§8`) — only the allocation goes:

  ```lua
  -- One scratch slot, reused. Non-reentrant by construction: table.concat cannot yield or call back
  -- into Lua, so no second probe can be in flight while this one holds the slot.
  local probeSlot = {}
  local function probeConcat(v) probeSlot[1] = v; return table.concat(probeSlot) end
  ```

  The slot must be cleared after the probe (`probeSlot[1] = nil`) so a secret is not retained by the
  library — do it in `IsConcatSafe` around the `pcall`, not inside the probe, which may not return.
- **F-014:** replace the `table.remove(D.buffer, 1)` trim with a head index (`D.first`), or a
  ring, so the steady state is O(1). `D:CopyText`, `D:BufferSize`, `D:LastLine` and `D:FindLine`
  move with it — this is the largest of the three and is optional; defer it if the milestone runs
  long.

**Standards conformance:** F-013 is bounded by `events-frames-taint-§8` — the `table.concat` probe
and the `pcall` are mandatory and are untouched; only the allocation around them changes. Rejected
alternative: a `type(v)`-based fast path — that is exactly the private stringifier `Perf minor 2`
deleted this release, because a secret **is** a string or a number.

---

### C-10 — Gate the kit sync in the suite `[F-011]`

**Files:** `tests/test_versioning.lua` (or a new `tests/test_kit_sync.lua`), `docs/releasing.md`.

A test that walks `testkit/` and `tests/_kit/`, asserts the same file set, and asserts byte-identical
contents. Pure Lua 5.1 + `io.open`, no shell-out, so it runs wherever the suite runs.

**Risk:** none. It fails exactly when `docs/releasing.md:61`'s manual `diff -r` would have.

**Standards conformance:** `library-stack-§7` ("SHOULD make the coupling mechanical rather than
remembered") and `anti-patterns` #45. Same rationale as the existing changelog-vs-minor test.

---

## Conformance summary

| Change | Standard rules that shaped it | Introduces a new deviation? |
|---|---|---|
| C-1 | `library-stack-§7`, `anti-patterns` #16 (rejected: file merge) | No |
| C-2 | `library-stack-§7` (additive-only — unaffected, no field moves) | No |
| C-3 | `options-ui-§2`, `slash-commands-§4` (why no tag is synthesized) | No |
| C-4 | `options-ui-§1`, `options-ui-§9`, `anti-patterns` #22 | No |
| C-5 | `library-stack-§4`, `library-stack-§7` | No |
| C-6 | `library-stack-§7` | No |
| C-7 | `events-frames-taint-§8`, `anti-patterns` #35 | No |
| C-8 | `options-ui-§6`, `options-ui-§11` (refresh model untouched) | No |
| C-9 | `events-frames-taint-§8` (probe form is mandatory and preserved) | No |
| C-10 | `library-stack-§7`, `anti-patterns` #45 | No |

Untouched on purpose, and worth recording so a later pass does not "fix" them:

- `O.RefreshAllPanels` running every panel's scalar refreshers is the **reference** pattern in
  `options-ui-§11`, not `anti-patterns` #39 — #39 forbids re-running *renderers*, which this does not.
- `O.OpenOptionsPanel`'s refuse-and-do-not-replay is exactly `options-ui-§2`; do not add a
  `PLAYER_REGEN_ENABLED` replay.
- `BUTTON_PAIR_REL = 0.492` and the `HALF = 0.5` split for schema widgets are the two distinct values
  `options-ui-§6`/`§8` require; they are not a copy-paste inconsistency.
- The always-shown scrollbar patch is mandated by `options-ui-§10` / `anti-patterns` #30.
- The lazy Defaults button is mandated by `options-ui-§5` / `anti-patterns` #42; C-1 touches only the
  tooltip reach inside it, never the deferral.
