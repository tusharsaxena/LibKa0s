# 01 — Findings (LibKa0s, 2026-09-07)

**Verdict: minor issues.** The library is healthy by every gate it runs — 0/0 lint, 764/764 tests,
0 `lizard` warnings — and the code reads as unusually well-reasoned. What this review found is
concentrated in two places: **one real frame leak on the newest surface** (the tab strip rebuilds
every button and its content panel with `CreateFrame` on every click and never pools them), and a
**standing evidence record that has gone a month stale in its hand-written half while its generated
half kept moving**, to the point where it asserts "Nothing is over the 1500 cap" against a shipped
file that is now 1838 LOC.

**Scope note.** LibKa0s is a **library repo**, not an addon. Reviewed against
`library-stack-§7`'s applicability list. Skipped as inapplicable, per that list: TOC/`toc-file`,
`options-ui` (as a consumer obligation), `slash-commands`, `preview-mode`, `savedvariables`,
`packaging`, `documentation-§1`'s README/badge row, `documentation-§3`'s `docs/` trio and tier
model. Also skipped for lack of subject: locale files and `L[...]` keys (a library ships no
`locales/`), AceConfig `AddToBlizOptions` return handling (no host registration happens here),
saved-variable schema/migration (nothing here persists except through a host-supplied `sv` name),
and event-registration review (the library registers no game events outside `Perf`'s sampler frame).
Taint was reviewed and is treated below where the library touches protected surfaces.

---

## Measurement run (Step 0 — all re-run today, 2026-09-07)

| Suite | Command (repo root) | Result |
|---|---|---|
| luacheck | `luacheck .` | **pass** — 0 warnings / 0 errors in **18 files**. Scope: `.luacheckrc:4` `exclude_files = { "tests/", "docs/" }`, so this covers the 14 files in `LibKa0s/` plus 4 in `testkit/` and **no test code** (~11,200 LOC under `tests/`). |
| Headless tests | `lua5.1 tests/run.lua` | **pass** — **764 passed, 0 failed, 0 skipped, 764 total**. |
| `--list` inventory | `lua5.1 tests/run.lua --list > <scratch>/list.md` | **pass** — 865 lines, total **764**. `diff` against committed `docs/test-cases.md`: **identical, no drift**. |
| Offline perf runner | — | **skipped (no `tests/perf.lua`)**. Documented as permanent in `docs/automated-tests/README.md` and `RESULTS.md`; the zero-overhead evidence `performance-§2` demands is instead held as a green test case (`tests/test_perf_isolation.lua:66`), which I read and confirm is falsifiable. |
| Complexity | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` → scratch | **pass** — 13678 NLOC, 1900 functions, avg CCN 1.9, **0 warnings**, max CCN **14**. |
| `make test` | — | **skipped (no `Makefile`)**. |
| Vendor sync | `diff -r testkit/ tests/_kit/` | **pass** — byte-identical (also gated by `tests/test_kitsync.lua`). No sibling consumer repo on disk, so no consumer-side sync was checkable. |

**Fresh run vs. committed artefacts**

- `docs/test-cases.md` — **agrees**. 764 total, no case drift.
- `docs/automated-tests/RESULTS.md` — **disagrees, badly, in its prose half.** Its table's newest
  row (`20260903-161751`, v1.24.0) says 764/764 over 18 files; its narrative sections still say
  "499 cases" (`RESULTS.md:49`), "Clean over 12 files" (`:79`) and *"the 8 shipped library files
  under `LibKa0s/`"* (`:81`). There are 14. See **F-002**.
- `docs/automated-tests/RESULTS.md` complexity watch list — **stale by 8 runs.** It is dated
  *"Current state as of `20260823-235820`"* (`:119`) and names `Kit.run@testkit/framework.lua:394-433`
  as the CCN-14 ceiling. Today `Kit.run` is at `testkit/framework.lua:668-695`, **CCN 10**, and the
  new ceiling is `drawContentPanel@LibKa0s/OptionsWidgets.lua:643-677`, **CCN 14** — in the
  *shipped* library, one arm below the CCN-15 release gate, unmentioned. See **F-003**.
- `docs/automated-tests/RESULTS.md` file-band table — **contradicted by its own manifest.**
  `:158` reads *"Nothing is over the 1500 cap."*; the newest bundle's
  `20260903-161751/manifest.json` records `"overCapFiles": 2`. See **F-002**.
- `docs/performance.md` — does not exist and is not owed (`documentation-§3` does not bind here).

**Not run here (in-client only):** taint under real combat, the `/<addon> perf` two-arm capture
protocol, frame/atlas rendering. Those are written up in `03_SMOKE_TESTS.md`.

**Standards cross-check: performed.** Resolved **Ka0s WoW Addon Standard v2.38.0 (2026-09-02)`,
index + all 26 section files fetched verbatim via `curl` from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`.

---

## High

### F-001 — The tab strip rebuilds every button and its content panel with `CreateFrame` on every click, and pools none of them `[perf]`

**Where:** `LibKa0s/OptionsWidgets.lua:943` (`makeTab` → `local b = CreateFrame("Button", nil, parent)`),
`:645` (`drawContentPanel` → `local panel = CreateFrame("Frame", nil, ctx.body)`),
`:873-879` (`releaseLedger` → `f:Hide(); f:SetParent(nil)`).

**Problem.** `O.RenderTabbedSchema`'s `onSelect` handler (`:1815-1826`) re-enters `RenderTabbedSchema`,
which calls `O.TabStrip`, which drains `__tabKids` via `releaseLedger` and then constructs a **brand-new
`Button` per tab** plus a **new content-panel `Frame` and two textures**. `releaseLedger` only hides and
unparents; nothing is retained for reuse. WoW frames cannot be destroyed or collected — an unparented
frame stays in the client's frame list for the session, still holding its `OnClick` closure and, through
it, `ctx` and the render's upvalues.

**Impact.** One `Button` per tab plus one `Frame` and two `Texture`s leak on **every tab click**, in
every consumer that adopts the mandatory strip. A 13-tab page — the one `options-ui-§13`'s wrap rule
was written from — leaks 14 frames per click. `LibKa0s-Pool-1.0` exists in this same repo for exactly
this, and this same library already pools in `LibKa0s/Widgets.lua:799` (`handlePool`, `boxPool`,
`reclaim` at `:815`, which additionally reparents to a hidden attic rather than to `nil`).

**Reachability:** *Any player clicking between tabs in any Ka0s addon's settings panel, on a default
profile — nine consumers wire `LibKa0s-Options-1.0`, and `options-ui-§13` makes the strip mandatory on
every page.*

**Fix direction.** Acquire tab buttons and the content panel from a pool keyed per `ctx`
(`LibKa0s-Pool-1.0`'s `AcquireKeyed`/`ReleaseAllKeyed`, with the attic reparent in `ReleaseAll`'s
`before` hook), rather than constructing per render. **Do not** hand-roll a third pool in
`OptionsWidgets.lua` — the sibling module already exists (`library-stack-§7`; anti-patterns'
"hand-rolled subsystem alongside a library that provides it").

**Coverage check.** `docs/test-cases.md` lists 239 cases over `test_options_widgets.lua`, several
asserting the *release* half (`tests/test_options_widgets.lua:2137`, `:2222` — "the first strip's
buttons were left on the host's frame"). **No case counts frames created across two renders**, so the
suite proves the old buttons are hidden and proves nothing about whether new ones were needed. That
gap is why the leak is invisible to a green gate.

---

## Medium

### F-002 — `RESULTS.md`'s hand-written half is a month stale and now contradicts its own generated table and manifest `[tests]` `[docs]`

**Where:** `docs/automated-tests/RESULTS.md:49`, `:79`, `:81`, `:119`, `:158`; contradicted by
`docs/automated-tests/20260903-161751/manifest.json`.

**Problem.** The file is banner-labelled *"generated, never hand-edited"* (`RESULTS.md:4`, and again in
`CLAUDE.md`'s documentation map), but only the **table row** is generated — every prose section beneath
it is hand-authored and was last revised around v1.8.3. Today it states:

| `RESULTS.md` says | Measured today |
|---|---|
| "499 cases" (`:49`) | **764** |
| "Clean over 12 files" (`:79`) | **18** |
| "the 8 shipped library files under `LibKa0s/`" (`:81`) | **14** |
| "Nothing is over the 1500 cap" (`:158`) | `LibKa0s/OptionsWidgets.lua` = **1838**, `tests/test_options_widgets.lua` = **2287** |
| band table: `test_options_widgets.lua` 1114, `test_options.lua` 1001 (`:154-156`) | **2287** and **1146** |

The last row is the sharp one: the **same repo's own runner already measured it** —
`manifest.json` for `20260903-161751` records `"bandFiles": 4, "overCapFiles": 2`. The generated half
knew; the prose half never followed.

**Impact.** This is the artefact the review and audit playbooks are told to cite for structural
findings. Cited as written, it asserts a cap compliance that is false and a suite size 35% of actual.

**Reachability:** *Any maintainer, reviewer or audit agent reading the standing record today — which
is the documented way to read it.* No runtime effect, so capped at Medium.

**Fix direction.** Either make the prose regeneration part of the release checkpoint that already
rewrites the table, or split the hand-written analysis out of a file whose banner promises it is
generated — a per-run `ANALYSIS.md` is the shape this repo already uses elsewhere, and it does not rot
because it is frozen and dated. Do not hand-edit numbers into the generated table
(`automated-tests`).

### F-003 — The complexity ceiling has moved from the test kit into the shipped library, and the watch list does not say so `[complexity]`

**Where:** `LibKa0s/OptionsWidgets.lua:643-677` (`drawContentPanel`); watch list at
`docs/automated-tests/RESULTS.md:119-141`.

**Problem.** The committed watch list is dated *"as of `20260823-235820`"* and names the CCN-14 top as
`Kit.run@testkit/framework.lua:394-433`, adding that "both new entries landed in the kit rather than in
the shipped library". Today's `lizard` run says otherwise: `Kit.run` has been split and now sits at
`testkit/framework.lua:668-695`, **CCN 10**; the ceiling is now
`drawContentPanel@./LibKa0s/OptionsWidgets.lua:643-677` at **CCN 14**, with
`O.RenderTabbedSchema@:1786-1838` at 12, `O.PageBanner@:1096-1144` at 11 and `O.RenderRows@:1710-1750`
at 11 behind it. Every one of those is shipped library code, and the four of them are the newest code
in the repo.

**Impact.** The release gate is "zero functions above CCN 15". The library is one decision from red on
a function nobody is watching, and the record that exists to make that visible says the pressure is in
the kit.

**Reachability:** *Only a maintainer reading the watch list, or the next release run that goes red
without warning. No runtime effect.*

**Fix direction.** Refresh the watch list at the next release regeneration and carry a disposition for
`drawContentPanel`. Note that `lizard` counts each `and`/`or` as a decision and this function is dense
defaulting (`if panel.SetFrameLevel and ctx.body.GetFrameLevel then`, four `if x and x.SetAtlas and
x.SetTexCoord`) rather than tangled control flow — so the honest remedy is a nil-tolerant texture
helper, not an arbitrary split. Do **not** propose a commit-time complexity gate (a documented
anti-pattern).

### F-004 — `test_eol.lua` is a generically-named gate scoped to one directory; seven tracked files violate the CRLF pin today `[tests]` `[line-endings]`

**Where:** `tests/test_eol.lua:29` — `local BUNDLES = "docs/automated-tests"`.

**Problem.** The case name is *"eol: every tracked bundle file carries the terminator
`.gitattributes` declares for it"*, and every mechanism in the file is path-generic — `git ls-files`,
`git check-attr eol`, a byte scan. One constant narrows it to `docs/automated-tests/`. Outside that
directory, `git ls-files --eol` reports **seven** tracked files declared `eol=crlf` sitting LF in the
working tree, two of them shipped library source:

```
i/lf w/lf attr/text=auto eol=crlf  LibKa0s/DebugLog.lua
i/lf w/lf attr/text=auto eol=crlf  LibKa0s/Pool.lua
i/lf w/lf attr/text=auto eol=crlf  tests/test_debuglog.lua
i/lf w/lf attr/text=auto eol=crlf  tests/test_pool.lua
i/lf w/lf attr/text=auto eol=crlf  docs/api/Options/version-8.7.3-docs.md
i/lf w/lf attr/text=auto eol=crlf  docs/api/Options/version-9.7.3-docs.md
i/lf w/lf attr/text=auto eol=crlf  docs/api/testkit/version-12-docs.md
```

(The two `run-automated-tests.sh` copies are correctly `eol=lf` via the carve-out.)

**Impact.** `DebugLog.lua` and `Pool.lua` are copied verbatim into every consumer's client-bound
`libs/LibKa0s/`, carrying the wrong terminator with them. The blob is LF in the index either way, so
`git status` is silent — which is precisely the invisibility this gate's own header describes, and
precisely what it does not currently look at. Runtime impact is nil (the client parses LF Lua fine);
the cost is that the pin is not actually held and every consumer inherits stragglers.

**Reachability:** *Every re-vendor of `LibKa0s/` into a consumer, today. No runtime effect, so
Medium, not High.*

**Fix direction.** Widen the gate's scope to the whole tracked set (the constant is the only change;
the assertion body already handles `unspecified`). Expect it to go red on seven files; repair each with
`rm <path> && git checkout -- <path>` in the same change, per the failure message the test already
writes. This is a **local** change — `test_eol.lua` is this repo's own suite, not the vendored kit —
but the same narrow scoping has almost certainly been copied into the consumers.

### F-005 — Two release paths in one library disagree: `Widgets` pools and reparents to an attic, `OptionsWidgets` drops to `nil` `[design]`

**Where:** `LibKa0s/Widgets.lua:799` and `:815` (`reclaim` → `SetParent(atticFrame())`) vs.
`LibKa0s/OptionsWidgets.lua:873-879` (`releaseLedger` → `SetParent(nil)`).

**Problem.** `Widgets.lua` carries a careful, well-commented pooling contract for frames it parents to
host-owned frames — hide, `ClearAllPoints`, reparent to a hidden attic, return to a free list.
`OptionsWidgets.lua`, released later and solving the identical problem for the same reason, hides and
sets parent `nil` and keeps no list. Neither file references the other, and **neither uses
`LibKa0s-Pool-1.0`**, which is a sibling module in this repo loaded before both
(`LibKa0s/LibKa0s.xml`: `Pool.lua` at position 3, `Widgets.lua` at 6, `OptionsWidgets.lua` at 10) and
whose README description is "the free/active widget pool this collection kept rewriting".

**Impact.** Three release semantics for one problem inside one library; the newest is the one that
leaks (**F-001**). The extracted abstraction the collection was told to adopt is unadopted by its own
author repo, which weakens the argument every consumer is given.

**Reachability:** *A maintainer changing either release path; the leak itself is carried by F-001. No
independent runtime effect.*

**Fix direction.** Route both through `LibKa0s-Pool-1.0` (`lib.New`/`Acquire`/`ReleaseAll`, attic
reparent in the `before` hook). Where `Pool` genuinely cannot express something, add it there
additively rather than keeping a local copy.

### F-006 — `OptionsWidgets`' diagnostic sink silently swallows every line when the host omits `print`, and disagrees with `Options`' own seam `[design]`

**Where:** `LibKa0s/OptionsWidgets.lua:696` — `local print = d.print or function() end`, against
`LibKa0s/Options.lua:289` — `local print = type(d.print) == "function" and d.print or function(line)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(line) end end`.

**Problem.** Two divergences from the shell's seam, in the same instance, over the same descriptor
field:

1. **The fallback is a no-op instead of the chat frame.** `Options.lua:283-288` states the rule in as
   many words — *"discarding them leaves nothing to grep for"* — and then `OptionsWidgets` discards
   four lines that exist purely to make an authoring defect visible: `NO_GROUPS` (`:1799`),
   `EMPTY_DROPDOWN` (`:1443`), `HEADER_FAILED` (`:1194`), `BUTTON_FAILED` (`:1325`).
2. **No type guard.** `Options` requires `type(d.print) == "function"`; `OptionsWidgets` accepts any
   truthy value and calls it. A descriptor passing `print = <table>` is silently ignored by one file
   and raises inside the other.

**Impact.** A host that omits `print` gets the shell's diagnostics in chat and the widget layer's
diagnostics nowhere — so the two most useful authoring diagnostics in the whole major (an ungrouped
page under a mandatory strip; a `string` row that renders as an empty dropdown) are the ones that
vanish.

**Reachability:** *Any host that does not supply `descriptor.print` — the field is optional and
undefaulted at the widget layer. All nine current consumers appear to supply it, so today this is a
latent seam defect rather than an active one.*

**Fix direction.** Make `__AttachWidgets` take the shell's already-constructed sink rather than
re-deriving one from `d` — one printer per instance, constructed once in `lib:New`.

### F-007 — `P.Open` allocates one slot table per bracket in the active arm, undocumented, and only the dormant arm is pinned `[perf]`

**Where:** `LibKa0s/Perf.lua:478` — `openStack[#openStack + 1] = { key = key, t0 = debugprofilestop() }`.

**Problem.** The dormant path is genuinely free and is measured — `tests/test_perf_isolation.lua:66`
runs 10,000 `Open`/`Close` pairs with the gate off and pins heap growth under 1 KB. Good. But the
`Open` docstring's stated reason for rejecting a closure-returning `Bracket(key)` is that *"a closure
per bracket would allocate"* (`Perf.lua:466-469`), and the chosen shape then allocates **a table per
`Open`** as soon as capture is on. Nothing documents that, and no case or scenario measures it.

**Impact.** The `active` arm of every two-arm capture pays GC pressure the `suspended` arm does not
(the host is inert there, so its brackets never fire). That asymmetry lands in exactly the frame-time
delta `performance` already says is unresolved below the harness's run-to-run spread — so it makes an
already-unreliable number a little more biased, in a known direction, without saying so.

**Reachability:** *Every in-client capture, in every consumer that has adopted Shape B brackets. Not
reached at all with capture off.*

**Fix direction.** Either reuse slot tables (a high-water free list on `openStack`, or two parallel
arrays `openKeys`/`openT0`), or — at minimum — state the active-arm cost in the docstring beside the
honest off-path statement it already carries, and note it in `docs/record-schema.md` so a capture's
reader knows the delta includes it. `[upstream]` in the sense that it lands here and re-vendors to
nine consumers; the fix itself is local to this repo.

### F-008 — A composed reset button with no handler renders fully enabled and does nothing, with no diagnostic `[ux]`

**Where:** `LibKa0s/OptionsCompose.lua:398-402` (`resetPosition` built whenever `not spec.frameless`,
regardless of `spec.onResetPosition`) and `:393-397` (`resetAll`, same for `spec.onResetAll`);
consumed at `LibKa0s/OptionsWidgets.lua:1319` — `if not spec.onClick then return end`.

**Problem.** `O.MasterControls` builds the canonical button pair from `spec.onResetPosition` /
`spec.onResetAll` without checking either is present. `InlineButtonPair`'s `makeBtn` then returns
early on click when `onClick` is nil. The result is a normal-looking, hover-tooltipped, enabled
"Reset position" or "Reset all settings" button that does nothing at all and reports nothing.

**Impact.** The player clicks the standard-mandated global reset and gets silence, which reads as the
addon being broken. This is exactly the authoring-defect class the file elsewhere goes out of its way
to report (`EMPTY_DROPDOWN`, `NO_GROUPS`), handled inconsistently.

**Reachability:** *A player on any host that adopts `MasterControls` while omitting one of the two
callbacks — an authoring slip with no compile-time or test-time signal. Not reachable in a
correctly-wired host.*

**Fix direction.** Report it the way this major reports its other authoring defects: a new
`lib.STRINGS` line printed once at compose time when a button spec has no `onClick`, following the
existing `EMPTY_DROPDOWN` precedent. Raising instead would be wrong — `options-ui-§12`'s reset is a
control, not a load-bearing contract, and this major's policy is report-and-render.

### F-009 — Lint's clean result covers 18 of 40 Lua files; the larger half of the tree is never linted `[lint]`

**Where:** `.luacheckrc:4` — `exclude_files = { "tests/", "docs/" }`.

**Problem.** `luacheck .` reports 0/0 over 18 files. The excluded set is 22 suite files plus three
fixtures, `tests/wow_mock.lua` and `tests/run.lua` — **~11,200 LOC**, more than the linted half. The
exclusion is documented and partly justified (`tests/_kit/` is a byte-identical copy of `testkit/`,
which *is* linted), but that argument covers 5 of the 25 excluded files and not the other 20.

**Impact.** A green `0/0` reads as "this repo is clean" and means "the shipped half is clean". The test
code is where an unused local or a shadowed `assertEqual` would silently weaken a case, and nothing
looks at it.

**Reachability:** *A maintainer reading the lint number, and any defect living in the 20 unlinted
suite files. No runtime effect.*

**Fix direction.** Narrow the exclusion to `tests/_kit/` (the vendored copy, already linted at its
master path) and lint `tests/` proper with a `files["tests/"]` stanza declaring the `_G.LK_TEST`
globals. `lint` requires 0 errors, not a narrow denominator.

---

## Low

### F-010 — The repo declares conformance to a standard ten minor versions behind the one it now implements `[docs]`

**Where:** `CLAUDE.md:3` and `README.md:3` — both read "v2.28.0". Resolved live standard is
**v2.38.0 (2026-09-02)**.

`documentation-§6`'s pointer is a substitute obligation for a library repo (`library-stack-§7`), and
the drift is not cosmetic here: `options-ui-§13`, `§15`, `§16`, `§17` and `§18` — the rules the entire
settings-revamp-v2 branch was written to implement, and which `OptionsCompose.lua` cites by number
throughout — arrived at v2.37.0 and v2.38.0. The file says the repo is built against a standard that
did not yet contain them.

**Reachability:** *A reader of either file. No runtime effect.*
**Fix direction.** Bump both pointers; keep them moving with each standards-driven change.

### F-011 — `tests/run.lua`'s suite list is hand-maintained; a renamed suite would go silently missing `[tests]`

**Where:** `tests/run.lua:112` — `suites = { "test_core", ..., "test_eol" }`.

The **load list** is correctly derived (`Loader.xmlFiles("LibKa0s/LibKa0s.xml")` at `:22`, with a good
comment explaining why — this repo is `testing-§10`'s reference implementation for exactly that). The
**suite list** beside it is 22 hand-typed names. It is complete today (verified: 22 names, 22
`tests/test_*.lua` on disk), and `Kit.assertSuiteInventory` exists in the kit and appears to guard
divergence — but the guard is the kit's, not the runner's, and the ordering-vs-globbing trade-off is
undocumented at the call site.

**Reachability:** *Only a future rename or addition, and only if the kit's inventory assertion does not
catch it. No runtime effect today.*
**Fix direction.** Add a one-line comment at `:112` naming what holds this list honest, so the next
reader does not have to find `Kit.assertSuiteInventory` to know the hand-typed list is safe.

### F-012 — The v1.25.0 release bundle records a dirty tree, so it cannot be reproduced from its own SHA `[tests]`

**Where:** `docs/automated-tests/20260903-161751/manifest.json` —
`"git": { "sha": "895cdf4…", "branch": "feat/settings-revamp-v2", "dirty": true }`.

The bundle was committed *in* `d3fc4a0` ("LibKa0s v1.25.0"), the same commit that changed
`LibKa0s/OptionsCompose.lua` and added 56 lines to `tests/test_options_compose.lua`. Those changes were
in the working tree, uncommitted, when the battery ran — so the evidence does cover the released code
(764 cases both then and now confirms it), but the recorded SHA `895cdf4` does **not** identify the
tree that was measured. `docs/releasing.md:72` asks for the battery "before the tag"; it does not
require a clean tree.

**Reachability:** *Anyone trying to reproduce a release run from its manifest. No runtime effect.*
**Fix direction.** Have `docs/releasing.md` require a clean tree for the release battery — commit the
code, run the battery, commit the bundle — or have the runner refuse to stamp a release-labelled run
as reproducible when `dirty` is true.

### F-013 — `RESULTS.md`'s Version column shows the pre-bump version for a release run `[docs]`

`docs/automated-tests/RESULTS.md:16` shows `20260903-161751` at Version **1.24.0**, while the same
row's manifest carries `"release": "1.25.0"`. Every release run will read this way, since the battery
runs before the version bump. The column silently means two different things depending on whether a
row is a release run.

**Reachability:** *A reader of the trend table. No runtime effect.*
**Fix direction.** Render the release label in the Version cell when `manifest.release` is set
(e.g. `1.24.0 → 1.25.0`), in the runner, not by hand.

---

## Upstream findings

These do not land in this repo.

### F-014 — `[standards-upstream]` The standard describes a LibKa0s that ships thirteen files; it ships fourteen

**Where (standard):** `standards/standards/library-stack.md:70` — *"ships **ten LibStub majors across
thirteen files**"*; also `standards/STANDARDS.md:57` and
`standards/standards/open-evolutions.md:13`, both repeating "ten majors across thirteen files".

**Where (reality):** `LibKa0s/LibKa0s.xml` lists **fourteen** `<Script>` entries.
`LibKa0s/OptionsScroll.lua` (`SCROLL_MINOR = 3`) is the fourteenth and is absent from the standard's
module table. This repo's own `README.md` is correct ("Four files, one major" for Options), as is
`docs/releasing.md:19` ("the fourteen in `LibKa0s/`").

**Impact.** The same class of drift `v2.34.0`'s own changelog entry called out — *"`library-stack-§7`
was describing a library three releases behind"* — has recurred. An audit counting files against the
standard files a phantom deviation, or misses a real one.

**Reachability:** *Any audit agent measuring a consumer's vendored payload against
`library-stack-§7`'s table.*

**Fix direction.** Fix in `tusharsaxena/WowAddonStandards`: add the `OptionsScroll` row to
`library-stack-§7`'s module table and correct the count in all three places, then bump the standard
version. **Not a change to this repo.**

### F-015 — `[standards-upstream]` `library-stack-§7`'s applicability list is not exhaustive, and `layout`'s 1500-LOC MUST falls in the gap

**Where (standard):** `standards/standards/library-stack.md:175-226`, whose framing is *"The three
lists below are the ones an audit of a Ka0s-owned library repo uses instead"*.

The "applies unchanged" list names 10 sections; the "does not apply" list names 9. The standard has
**26** sections. Unclassified, and therefore unauditable in either direction:
**`layout`**, `architecture`, `anti-patterns`, `performance`, `public-api`, `compat`,
`debug-logging`, `standalone-windows`, `naming-cheatsheet`, `audit-review-history`, and
`localization` beyond its `§5`.

`layout` is the one that bites today. `layout-§1` says *"MUST cap any single `.lua` file at 1500 LOC…
a >1500 file is a bug — peel it"*. This repo's own evidence reports against that rule by name
(`RESULTS.md:152` — "Files by `layout-§1` band"; the runner emits `bandFiles`/`overCapFiles` into
every manifest), so in practice it is treated as binding — yet `LibKa0s/OptionsWidgets.lua` is
**1838 LOC** and no gate, audit or register records it as a violation, because the standard never says
whether the rule applies here.

**Reachability:** *Any audit of a Ka0s-owned library repo — and this repo today, where a shipped file
is 338 lines over a cap nobody can say applies.*

**Fix direction.** Fix in `tusharsaxena/WowAddonStandards`: make `library-stack-§7`'s classification
cover **every** section (a default clause — "anything not named applies" — plus the explicit
exclusions — would do it), and state explicitly whether `layout`'s LOC cap binds a library's ship
folder. **Not a change to this repo.** Once settled, this repo either peels `OptionsWidgets.lua` at the
seam its own comments already identify (the tab strip and the content-panel chrome are one coherent
block, `:560-1095`) or records a ratified deviation row in `CLAUDE.md`'s register.
