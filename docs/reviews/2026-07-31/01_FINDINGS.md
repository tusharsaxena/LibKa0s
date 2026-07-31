# 01 — Findings

**Scope:** `git diff master...HEAD` on `feature/libka0s-five-module-extraction` — the extraction of
`LibKa0s-Core-1.0`, `-DebugLog-1.0`, `-Slash-1.0`, `-Options-1.0` and the Core-ification of
`-Perf-1.0`, plus the shared `testkit/`.

**Verdict: minor issues — mergeable after the four High findings, none of which are architectural.**

The five-major split is sound and the hard parts are right: every frame is per-instance and named
from the descriptor, no module holds a lib-level singleton, the `NEEDS_CORE` floor makes a
half-vendored major *absent* rather than half-wired, the paired-secondary guards pair on the
primary's minor (not merely on presence), and the secret-safe seam probes `table.concat` rather than
`..`. 329/329 green, luacheck 0/0 in 11 files, and `docs/releasing.md` is unusually honest about its
own hazards. What follows is mostly the Options major, which is the youngest of the five and is the
one place where the discipline the other four keep has not been applied uniformly.

**Standards cross-check: performed.** Resolved the Ka0s WoW Addon Standard at **v2.14.0 (2026-07-30)**
from `https://github.com/tusharsaxena/WowAddonStandards` (index + all 23 section files). Every fix
direction below has been checked against it; where a rule shapes or forbids a direction it is cited
as `filename-§N`. This is a guardrail on remediation, **not** a compliance audit — pre-existing
deviations unrelated to these findings are out of scope and belong to `wow-addon:standards-audit`.

---

## High

### F-001 — `EnsureDefaultsButton` calls an attach-file function without the guard its own comment claims `[design]`
`LibKa0s/Options.lua:234` (comment at `LibKa0s/Options.lua:462-465`)

`O.EnsureDefaultsButton` calls `O.AttachTooltip(btn, ...)` unguarded, while the sibling reach in
`O.EnsureScroll` is guarded (`if O.PatchAlwaysShowScrollbar then`); the closing comment on `lib:New`
asserts that reaching for both "at CALL time and never at load time" is what makes a missing attach
file survivable, which is true of one of the two and false of the other.

**Impact:** on a vendored copy where `OptionsWidgets.lua` did not arrive, `lib:New` succeeds and the
host holds an instance that looks whole until the first panel `OnShow`, which raises *attempt to
call a nil value (field 'AttachTooltip')* mid-header-build — and the caller is the **library's own
shell**, not the host, which `docs/releasing.md:79-86` says is where the failure surfaces.

**Fix direction:** make the half-wired state detectable rather than latent — a post-attach
completeness check inside `lib:New` that refuses (or a published `O.MODULES`-style capability flag
the shell tests before reaching). Do **not** "fix" it by folding the widget makers into `Options.lua`:
that would push the file past the peel threshold and lose the per-file minor the multi-file pairing
rule requires (`anti-patterns` #16, `library-stack-§7`).

### F-002 — `RestoreDefaults` drops the page filter that `RenderSchema` passes `[logic]`
`LibKa0s/Options.lua:301` vs `LibKa0s/OptionsWidgets.lua:485`

`O.RenderSchema` renders a page with `d.rowsForPage(pageKey, ctx.unit)`; `O.RestoreDefaults(pageKey, ctx)`
resets it with `d.rowsForPage(pageKey)` — no filter — despite already holding the `ctx` that carries it.

**Impact:** on a per-unit (or otherwise filtered) page, the header **Defaults** button resets every
unit's rows while the panel in front of the user shows one unit's. The user sees one page revert and
silently loses settings on pages they never opened. Untested: `tests/fixture_options.lua:111` declares
`rowsForPage = function(pageKey)`, so the fixture cannot observe the second argument at all.

**Fix direction:** thread `ctx and ctx.unit` through, matching `RenderSchema`. Purely additive to the
descriptor contract (`library-stack-§7` additive-only), since `rowsForPage` already receives the
argument on the render path.

### F-003 — `DebugLog` snapshots a cross-major function at file-load time `[design]`
`LibKa0s/DebugLog.lua:46`

`lib.MakeCloseButton = core.MakeCloseButton` is evaluated when `DebugLog.lua` runs. `LibStub`
upgrades a major **in place**, so a later `Core.lua` at a higher minor replaces `core.MakeCloseButton`
on the shared table — but a `DebugLog.lua` whose own minor did not rise returns early and never
re-snapshots. The paired-secondary guards (`__widgetsShellMinor`, `__scrollShellMinor`,
`__panelProbeMinor`) protect files *within* a major; nothing protects this, and `docs/releasing.md:68-77`
says so explicitly ("Nothing negotiates the other direction").

**Impact:** a host carrying two vendored copies (new Core, unchanged DebugLog) draws its debug
console's close button from the older Core file while `lib.MODULES.Core` truthfully reports the newer
minor — the exact "which half came from where?" question `library-stack-§7` requires be answerable at
runtime, answered wrongly. Silent; survives a `/reload`.

**Fix direction:** re-export as a forwarder that resolves through the `core` **table** at call time
(the table identity is stable across a `NewLibrary` upgrade; the function value is not). Same shape
`PerfPanel.lua:186,195` already uses correctly.

### F-004 — Options' default printer is a silent no-op, so a combat refusal can vanish `[ux]`
`LibKa0s/Options.lua:117`

`local print = d.print or function() end`. `Core`, `DebugLog` and `Slash` all default their sink to
`DEFAULT_CHAT_FRAME:AddMessage`; only Options defaults to discarding.

**Impact:** a host that omits `print` gets a settings panel that refuses to open in combat **with no
output whatsoever** — the user presses the key, nothing happens, and there is nothing to grep for.
`options-ui-§2` is explicit that the lockdown refusal MUST print the gray notice and **MUST NOT
silently no-op**; the same silence also swallows `NO_ACEGUI`, the one line that explains an
options panel that never appears.

**Fix direction:** default to `DEFAULT_CHAT_FRAME:AddMessage`, matching the three sibling modules.
Note the library cannot supply the mandated cyan `NS.PREFIX` tag itself (`slash-commands-§4`) — the
tag is the host's, which is why the descriptor's `print` remains the intended path; the fallback
exists so the refusal is *visible*, not so it is *tagged*.

---

## Medium

### F-005 — Options performs no descriptor validation, alone among the five majors `[design]`
`LibKa0s/Options.lua:115`

`Core:New`, `DebugLog:New` and `Slash:New` all `error(MAJOR .. ":New requires descriptor.X", 2)`;
`Perf` carries a `required(d, key, wanted)` helper (`LibKa0s/Perf.lua:174,184-187`). Options indexes
`d` directly, so only a nil descriptor raises — and it raises as `attempt to index a nil value`, not
as a message naming the library. `README.md:353-356` documents the gap as intentional.

**Impact:** `mainPanelName` is the sharpest case — it is documented as *"Frame name for the main
canvas, so `/framestack` attributes it to the host and two addons cannot collide"*, and a nil silently
yields `CreateFrame("Frame", nil)`, an anonymous canvas. The property the field exists to guarantee is
lost with no error, no test, and nothing visible in-game except an unattributable frame. The remaining
required fields surface a page-build away, in a widget maker, with a stack that points at the library.

### F-006 — The paired-secondary guard records the shell minor but never declares a floor `[design]`
`LibKa0s/OptionsWidgets.lua:18-21`, `LibKa0s/OptionsScroll.lua:24-27`

The guard re-attaches whenever the shell underneath changed — correct, and what `library-stack-§7`
requires. But it is symmetric where the cross-major relationship is not: `DebugLog`/`Slash`/`Options`/`Perf`
each declare `NEEDS_CORE = 1` and refuse below it, while a secondary file declares no minimum shell
minor. A newer `OptionsWidgets.lua` attaches happily over an older `Options.lua` shell.

**Impact:** the header comment concedes the risk ("there is no version negotiation that would catch
it") but the mitigation is whole-folder copying only. A widget file that starts reading a `lib.LAYOUT`
key a later shell added would nil-index at panel build with nothing at load time to say why.

### F-007 — `RenderRows` mutates the caller's `afterGroup` / `pairWith` tables `[design]`
`LibKa0s/OptionsWidgets.lua:463,475`

Both one-shot mechanisms are implemented by writing `nil` into the table the **caller** owns.

**Impact:** rendering the same page twice — which the library explicitly supports via
`O.ClearScroll(ctx)` + re-render, and which a per-unit page does on every unit switch — silently
drops every inline action button and every paired widget on the second pass, if the host hoisted its
`afterGroup`/`pairWith` table to a file-level constant (the natural way to write it). No error, no
test, and it looks like a rendering bug rather than an ownership bug.

### F-008 — `Slash.FormatValue` bypasses the secret-safe stringifier on four of its five branches `[taint]`
`LibKa0s/Slash.lua:79-92`

`tostring(v)` (number branch), `row.fmt:format(v)`, the colour `%.2f` format and the raw `string`
return all skip `core.SafeToString`; only the fallthrough at line 91 uses it. Every one of those
results then reaches `lib.FormatKV`, which is a `string.format`.

**Impact:** `events-frames-taint-§8` is explicit that a secret raises in **`string.format` as well as**
`table.concat`, and `anti-patterns` #35 forbids feeding one into either. The invariant that makes the
current code safe — *a stored settings value is never a combat-protected value* — is real but is
nowhere written down and nowhere enforced; a host whose `d.get` returns a derived or live value
breaks it, and the module's own `HelpHeader`/`CliVersion` (lines 250, 355) demonstrate the careful
form two screens away.

### F-009 — `DebugLog:Add` does not route its message through the secret-safe stringifier `[taint]`
`LibKa0s/DebugLog.lua:407-415`

`D:Add` is public, documented ("UNGATED on purpose"), and is the path a host's perf output and the
enable-bracket lines take. It hands `msg` straight to `lib.FormatColored` / `lib.FormatPlain`, both of
which are `string.format`. The gated sink `D.Debug` (line 428) and the `initSummary` call (line 541)
*do* guard, so the module already knows the rule and applies it on two of three entry points.

**Impact:** same as F-008, but on the console — and `events-frames-taint-§8` names precisely this
failure mode: a raise inside a repeating logger kills the ticker and the display freezes until
`/reload`.

### F-010 — `CreateOptionsPanel` is not idempotent `[logic]`
`LibKa0s/Options.lua:387-407`

No re-entry guard, and `pendingPages` is never drained. A second call re-runs `registerMain()` — a
second `Settings.RegisterCanvasLayoutCategory` + `RegisterAddOnCategory` for the same addon — and
re-runs every page builder, appending a second `ctx` per page to `renderedPanels`.

**Impact:** a duplicate entry in the Blizzard options list and a permanently doubled refresher
fan-out (`RefreshAllPanels` then runs each widget's updater twice per write). Not currently reachable
through any shipped host, but the function is public, cheap to call twice across a login and a
profile change, and nothing about the API says it may not be.

### F-011 — The `testkit/` ↔ `tests/_kit/` sync is documented but not gated `[testability]`
`testkit/` vs `tests/_kit/` (identical today), `tests/run.lua:5-11`, `docs/releasing.md:54-61`

The repo deliberately consumes its own kit through `tests/_kit/` so that LibKa0s is a consumer on the
same terms as every addon — a good decision. But `diff -r testkit tests/_kit` is a **manual** step in
the release doc; nothing in `tests/run.lua` fails when the two diverge.

**Impact:** this is the drift `anti-patterns` #45 calls *uniquely silent* — both copies work, the
suite stays green, and the divergence ships. `library-stack-§7` asks the lib repo to "make the
coupling mechanical rather than remembered", which the changelog-vs-minor test already does for file
versions and which this one gap does not do for the kit.

---

## Low

### F-012 — `printer.Format` with zero varargs skips `string.format` `[logic]`
`LibKa0s/Core.lua:178-184`

`if n == 0 then emit(lib.SafeToString(fmt)) return end` — so `Format("100%% done")` emits the literal
`100%% done`, while `Format("100%% done", x)` emits `100% done`. The zero-argument shortcut changes
the meaning of the format string rather than just skipping work. Cosmetic, but it is the kind of
inconsistency a host debugs for ten minutes.

### F-013 — Every probed value allocates a table `[perf]`
`LibKa0s/Core.lua:54`

`probeConcat` builds a fresh one-element table per call, and `SafeToString` is on the per-argument
path of every chat line, every debug line and every Perf render. One allocation plus one `pcall` per
argument. The `pcall` is load-bearing and must stay (`events-frames-taint-§8` mandates the concat
probe); the allocation is not — a hoisted single-slot scratch table would do, and the probe cannot
re-enter.

### F-014 — The console buffer trims with an O(n) shift `[perf]`
`LibKa0s/DebugLog.lua:412`

`table.remove(D.buffer, 1)` on every line once the 500-line cap is reached. Bounded and small, but it
is a 500-element move per logged line at steady state, on a path that exists to be cheap.

### F-015 — `solo` and `pairWith` contradict each other `[logic]`
`LibKa0s/OptionsWidgets.lua:453-466`

A row marked `solo` ("render this row alone in the left half of its own line", per the block comment
at line 419) that is also named in `pairWith` receives a right-hand partner anyway: the `pendingCount == 1`
test at line 461 is satisfied on a freshly-flushed solo row. Whichever behavior is intended, the two
documented contracts cannot both hold.

### F-016 — A code comment contradicts `docs/releasing.md` `[naming]`
`LibKa0s/Options.lua:462-465` vs `docs/releasing.md:79-86`

The release doc correctly describes the partial-vendor failure ("the host holds an instance that
looks whole until something calls `O.AttachTooltip` or `O.PatchAlwaysShowScrollbar`"); the code
comment claims call-time reach is what makes that safe. The doc is right and the comment is wrong,
and it is the comment a maintainer reads while editing the function. Resolved together with F-001.
The doc also under-states it by one word: the first caller of `O.AttachTooltip` is the **shell
itself**, not a host.
