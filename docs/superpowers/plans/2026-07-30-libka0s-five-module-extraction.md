# LibKa0s: the five-module extraction — implementation plan

Executes [`2026-07-30-libka0s-five-module-extraction-design.md`](../specs/2026-07-30-libka0s-five-module-extraction-design.md).
Read the spec first — this plan does not restate its reasoning, only its consequences.

**Branch:** `feature/libka0s-five-module-extraction` in both repos.
`LK/` = `LibKa0s`, `AT/` = `AbsorbTracker`.

## Progress

| M | What | Status |
|---|---|---|
| M1 | Prerequisites — strict LibStub mock, TOC-derived load list, N-major versioning | **done** |
| M2 | `testkit/` extracted; both repos consume it | **done** |
| M3 | `LibKa0s-Core-1.0` + Perf consumes it | **done** |
| M4 | `LibKa0s-DebugLog-1.0` | **done** |
| M5 | `LibKa0s-Slash-1.0` | **done** |
| M6 | `LibKa0s-Options-1.0` | **done** |
| M7 | Documentation | **done** |
| M8 | `/wow-addon:review` gate | **done** |
| M9 | In-game smoke tests | **done — all passed** |
| M10 | `WowAddonStandards` — consume-the-library rewrite (v2.15.0) | **done** |
| M11 | the `wow-addon` plugin + the new-addon context pack | **done** |
| M12 | `LibKa0s/docs/adoption-prompt.md` for all five modules | **done** |

State at completion: **AbsorbTracker 449 passed / 0 failed, LibKa0s 342 passed / 0 failed,
`luacheck .` 0/0 in both.** `diff -r` empty for `LibKa0s` → `libs/LibKa0s` and for `testkit` →
`tests/_kit`. The `tests/perf.lua` parity figures are unchanged from the pre-extraction baseline —
`paintPass` 12.0 api/iter and 312.0 bytes/iter, `probeOverheadOn` 312.3 bytes/iter — which is the
artefact proving that none of the five extractions touched the measured paths.

All five modules are extracted and the documentation is caught up. M9 (in-game) is the hard stop:
it needs a live client, so nothing in `WowAddonStandards`, the plugin or the adoption prompt moves
until someone runs it.

### Where the work is

Both repos are on `feature/libka0s-five-module-extraction`, both trees clean. One commit per
milestone per repo, library first:

| M | LibKa0s | AbsorbTracker |
|---|---|---|
| M1+M2 | `daf26b2` testkit + N-major versioning | `8a8cd20` adopt the kit, derive the load list |
| M3 | `4a248d5` Core + Perf's secret-guard fix | `a701d89` consume Core, delete `core/Util.lua` |
| M4 | `bfb22cc` DebugLog | `90a9555` consume it, delete `core/DebugLog.lua` |
| M5 | `d2d90bb` Slash | `ee02774` consume it, `/at reset` takes a path |
| M6 | `cc29f8e` Options (3 files) + kit comment | `952b375` consume it, delete the four toolkit files |
| — | | `2e53fdd` doc recount (not a milestone) |
| M7 | `9d82849` per-module README order, releasing.md, kit re-vendor | `771affa` retire the four toolkit files from docs |
| — | `d9f4c33` plan: record M7 | |
| M8 | `995e19a` review fixes across all five majors, all 8 minors bumped | `ef71076` review fixes + re-vendor |
| — | `39b1203` plan: record M8 | |
| M10 | `WowAddonStandards` `810df67` standard v2.15.0 | |
| M12 | `f938727` adoption prompt for all five modules | |
| M11 | `WowAddonStandards` `8dbffb1` context pack + audit; `wow-addon` `9505a04` plugin agents | |

### The working method, established over M3–M5

Each of these caught something the previous step missed, so the order is not incidental:

1. **Recon before code.** A parallel read across the spec's normative sections, the AbsorbTracker
   implementation being replaced, its consumers, its suites, and the previous milestone as the
   template. The spec is frequently silent where the plan is specific — when they disagree, the
   SOURCE wins under the parity rule, and the gap gets recorded rather than guessed at.
2. **Failing tests first, and confirm they fail for the stated reason.** Not "the suite is red" —
   the individual message. M4 wrote the module before seeing the reds individually and paid for it.
3. **Then the module, then the consumer.**
4. **Adversarial verification before committing.** Three passes: code against spec, a test audit
   that MUTATES the implementation to find assertions that cannot fail, and a stale-doc sweep. This
   has found a real defect in every milestone it has run on — including one in M5 that would have
   shipped, and four assertions in M4 that were green and worthless.
5. **Fix, re-verify by mutation, regenerate `docs/test-cases.md`, record deviations, then ask.**

The gate, every time, in both repos: `lua tests/run.lua` green, `luacheck .` 0/0,
`diff -r LibKa0s/LibKa0s AbsorbTracker/libs/LibKa0s` empty, `diff -r LibKa0s/testkit
AbsorbTracker/tests/_kit` empty, and `lua tests/perf.lua`'s `probeOverheadOn` still 312.3 bytes/iter.

### Read before starting M8

- The **Open items carried forward** section below — it holds the known defects in this plan and its
  spec, and the standing rules that have each already cost a milestone.
- M9 cannot be automated. It needs a live client, and M10–M12 are gated on it by design: writing a
  normative section from a design rather than from a verified extraction is how a standard acquires
  rules that do not survive their second implementation. The checklist is now in
  `AT/docs/smoke-tests.md` rather than only in the spec.

---

## Global constraints

Carried forward from the Perf plan, plus what this extraction adds.

- **Lua 5.1 only.** `luac -p <file>` syntax-checks one file.
- **CRLF everywhere**, both repos, pinned by `.gitattributes`. No BOM.
- **Non-ASCII as decimal byte escapes** in Lua — `\226\128\148` for the em dash, never a literal.
- **Green gate before every commit, in whichever repo the commit lands:** `lua tests/run.lua` all
  green, `luacheck .` reporting `0 warnings / 0 errors`.
- **`diff -r LK/LibKa0s AT/libs/LibKa0s` empty** and **`diff -r LK/testkit AT/tests/_kit` empty**
  after every milestone that touches either. Nothing about "the tests are green" will tell you the
  copies have diverged — that already happened once during the Perf extraction.
- **Never edit `AT/libs/`.** A library problem is a finding to fix upstream and re-vendor, never a
  local patch. The next re-vendor silently reverts it.
- **Descriptor contracts are additive-only within `-1.0`.** Once a field exists, its meaning is
  frozen.
- **Every instance owns its own frames.** No lib-level singleton frame, ever. Frames are named from
  `d.name` so `/framestack` attributes them and two hosts cannot collide.
- **Re-vendoring is whole-folder, always.** Never per-module — that is how cross-major minor skew
  gets manufactured.
- **No auto-commit.** Each milestone ends by asking. No version bump on either repo unless asked.
- **Regenerate `docs/test-cases.md` and move the README `[tests]` badge count in the same change**
  that alters the suite. The count only, never the version.

### Per-milestone file-minor discipline

Every file changed in a milestone bumps its own `MINOR`, and `CHANGELOG.md` gains a line containing
the literal substring `<FileBasename> minor <N>` — `test_versioning.lua` fails otherwise. A file not
touched does not move.

---

## M1 — Prerequisites: make the later milestones honest

Nothing is extracted here. This milestone exists so every later one is provable, exactly as the
Perf plan's Task 1 existed to give later tasks a harness to be green against.

### Files

- Modify `AT/tests/wow_mock.lua` — strict LibStub.
- Modify `AT/tests/loader.lua` — `readTOCOrder`.
- Modify `AT/tests/run.lua`, `AT/tests/perf.lua` — consume the derived list.
- Create `AT/tests/test_loadorder.lua`.
- Modify `LK/tests/run.lua`, `LK/tests/test_versioning.lua` — N majors.

### Step 1 — the failing tests

In `AT/tests/test_loadorder.lua`:
- `loadorder: the TOC and tests/run.lua agree on file order` — `readTOCOrder` output equals the
  runner's list.
- `loadorder: tests/perf.lua uses the same list`.
- `loadorder: LibStub errors on a missing major without the silent flag` — expected to fail now.
- `loadorder: LibStub returns nil for a missing major with the silent flag`.

### Step 2 — verify they fail

Expect `loadorder: LibStub errors on a missing major without the silent flag` to FAIL with
`assertError expected an error, got nil` — the mock's `__call` currently drops `silent` and
`GetLibrary` never errors.

### Step 3 — fix the LibStub mock

Replace `AT/tests/wow_mock.lua`'s `__call = function(self, n) return self:GetLibrary(n) end` with
LibKa0s's strict form: forward `silent`, and `error()` on a missing major when it is absent. Re-run
the whole suite and **report what it catches** — this is the point of doing it first.

### Step 4 — TOC-derived load order

Port `readTOCOrder(root, tocName)` from `KickCD/tests/loader.lua` into `AT/tests/loader.lua`: parse
the TOC, skip `^libs/` and non-`.lua`, return paths in order. `run.lua` and `perf.lua` build their
list from it, prefixed by the explicit `libs/LibKa0s/*.lua` entries (which the TOC references only
through the XML). Keep `_G.AT_TEST` and the lifecycle kick untouched.

### Step 5 — generalise `test_versioning.lua`

`LK/tests/run.lua` binds one handle, `T.lib = mocks.LibStub("LibKa0s-Perf-1.0")`, and
`test_versioning.lua` hard-codes the two Perf filenames and the panel-pairing assertion. Replace
with a table iterated per major:

```lua
T.majors = {
  { major = "LibKa0s-Perf-1.0", files = { "Perf", "PerfPanel" } },
}
```

Every case iterates it. Adding a major later is one row. Do this **before** the first new module
lands, not after.

### Gate & commit

Both repos green. Regenerate `AT/docs/test-cases.md`, move the badge. Commit (ask).

---

## M2 — `testkit/`: the shared harness

### Files

- Create `LK/testkit/{framework.lua,loader.lua,mock_base.lua,README.md}`.
- Create `AT/tests/_kit/` (vendored copy).
- Modify `LK/tests/run.lua`, `LK/tests/wow_mock.lua`, `AT/tests/run.lua`, `AT/tests/wow_mock.lua`.
- Modify `LK/docs/releasing.md` — add the `testkit` re-vendor row.

### Interfaces produced

```lua
-- framework.lua
Kit.test(name, fn) / assertEqual / assertTrue / assertFalse / assertNil / assertNear / assertError
Kit.expose(t)              -> the _G.<X>_TEST table
Kit.runSuites(dir, names)  -- collect-then-run; honours --list; sets the exit code
-- loader.lua
Loader.makeEnv(mocks)      -- WITH __newindex writing through to _G
Loader.load / loadAll / loadSource / readTOCOrder
-- mock_base.lua
base()                     -> a fresh universal mock table per call
base.__stubFrame           -- so an addon can build extra frame-shaped objects
```

### Step 1 — the failing tests

`LK/tests/test_testkit.lua`:
- `kit: collect-then-run registers without executing` (`--list` must not run bodies).
- `kit: the --list renderer emits the banner, per-suite headings and the totals table`.
- `kit: the loader env writes globals through to _G`.
- `kit: LibStub errors without the silent flag, returns nil with it`.
- `kit: CreateTexture and CreateFontString return distinct objects, not the frame`.
- `kit: readTOCOrder skips libs/ and non-lua lines and preserves order`.

The distinct-objects case will fail against AbsorbTracker's current stub, which returns the frame
itself for both. WhatGroup makes distinct objects a documented correctness requirement, and
`PerfPanel.lua` carries a `__label`/`__state` workaround that exists *because* of the weaker stub.
Fixing it in the base is in scope; removing the PerfPanel workaround is **not** (that is a Perf
change with its own minor bump and no consumer benefit yet) — leave it and note it.

### Step 2 — build the kit

`framework.lua` from `AT/tests/run.lua`'s assertion core and `--list` renderer, which are
line-for-line identical to LibKa0s's. Add `assertNil` (WhatGroup, KickCD), `assertNear`
(PanelMaster), `assertError` (KickCD). Adopt the long four-line banner, the
`| Suite | Cases |` / `|-------|------:|` totals table, in-renderer CRLF, and declared-suite-order
grouping (spec D4). Both repos' `docs/test-cases.md` are regenerated in this milestone; the
**totals must not move** — only the markup around them. Diff them to prove it.

`loader.lua` from AbsorbTracker's (the one with `__newindex`), plus LibKa0s's `loadSource` and
KickCD's `readTOCOrder`.

`mock_base.lua`: the universal surface — `CreateFrame` with a KickCD-fidelity stub, `UIParent`,
`UISpecialFrames`, `DEFAULT_CHAT_FRAME`, `GameTooltip`, strict `LibStub` with a real `NewLibrary`,
time/string/`wipe`/`strtrim`, `C_Timer` with a fireable queue, `InCombatLockdown`, `UnitName` /
`UnitClass` / `GetRealmName`, `StaticPopupDialogs`, the `Settings` canvas API, `hooksecurefunc`,
`GetLocale`, and the four Ace fakes (AceDB with a faithful `copyDefaults`, AceAddon **including the
AceConsole `:Print` clobber**, the AceEvent `(message, target)` registry, the AceGUI widget factory
with `ScrollFrame` extras, `__created`, `RegisterWidgetType` / `GetWidgetVersion`).

`README.md` carries the fidelity rules, adapted from KickCD's 30-line rationale comment — the best
statement of them in the collection.

### Step 3 — both repos consume it

`AT/tests/wow_mock.lua` becomes a thin extender: `local base = dofile("tests/_kit/mock_base.lua")`,
then override `__absorbs` / `UnitGetTotalAbsorbs` / `__maxHealth` / `UnitHealthMax` /
`AbbreviateNumbers` / `C_ClassColor`. Plain per-key overwrite, no merge machinery.

`AT/tests/run.lua` shrinks to load list + lifecycle + suite list. **`_G.AT_TEST` keeps its exact key
set, so not one existing test file changes.** That is the acceptance criterion for this milestone.

`LK/tests/run.lua` consumes its own kit — the kit's real dogfood test.

### Gate & commit

Both suites green with **zero edits to any existing `test_*.lua`**. `diff -r` empty. Regenerate both
`docs/test-cases.md`, move both badges. Commit (ask).

---

## M3 — `LibKa0s-Core-1.0`

### Files

- Create `LK/LibKa0s/Core.lua`; modify `LK/LibKa0s/LibKa0s.xml`, `LK/LibKa0s/Perf.lua`.
- Create `LK/tests/test_core.lua`; modify `LK/tests/run.lua`, `LK/CHANGELOG.md`, `LK/README.md`.
- Create `AT/core/CoreSetup.lua`; **delete** `AT/core/Util.lua`.
- Modify `AT/AbsorbTracker.toc`, `AT/core/AbsorbTracker.lua`, `AT/core/PerfSetup.lua` (comment),
  `AT/tests/test_util.lua`.

### Interfaces produced

Per spec §4.1: `lib.IsConcatSafe`, `lib.SafeToString`, `lib.SECRET`, `lib.SKIN`, `lib.ApplySkin`,
`lib.MakeCloseButton`, and `lib:New{prefix, sep, sink}` returning `printer.Print` / `printer.Format`.

### Step 1 — the failing tests

`LK/tests/test_core.lua`, carrying `AT/tests/test_util.lua`'s `secretMock` **verbatim** — its
comment is the spec for what a correct detector must do (the mock makes `..` succeed and
`table.concat` fail, so a `..`-based probe fails the suite):

- `core: IsConcatSafe is false for a table.concat-hostile value, true for a plain one`.
- `core: SafeToString renders a secret as lib.SECRET and passes nil/booleans through`.
- `core: Print joins with a space, prefixes verbatim, and routes through the injected sink`.
- `core: a function prefix is re-read on every call` — the WhatGroup load-order case.
- `core: Format applies the format string with pre-stringified args` — the ConsumableMaster form.
- `core: ApplySkin no-ops on a frame without SetBackdrop`.
- `core: MakeCloseButton returns nil when CreateFrame is unavailable`.
- **`core: Perf's own stringifier renders a secret as <secret>`** — the regression test for the live
  bug. Expected to FAIL before Step 3.

### Step 2 — verify they fail

`attempt to index a nil value (LibKa0s-Core-1.0 is not registered)` for the first seven; the Perf
case fails with the secret rendered as its raw value rather than `<secret>`.

### Step 3 — write `Core.lua`, and point Perf at it

Standard preamble: header comment, `MAJOR, MINOR = "LibKa0s-Core-1.0", 1`, `NewLibrary` guard,
`lib.MAJOR/lib.MINOR`, `lib.MODULES.Core = MINOR`.

Then **Perf consumes Core** (spec D2/§3.3), which is four separate edits:

1. `Perf.lua` — delete the broken private `safeToString`; call `core.SafeToString`. Add the
   `NEEDS_CORE` guard at the top per spec §3.2, so a missing Core makes Perf *absent* (host stub
   fires) rather than nil-erroring at first use.
2. `Perf.lua` header comment — "Depends on LibStub and nothing else" is no longer true. Rewrite it
   to name Core and to state what the invariant actually protects: **no addon framework**, so a
   non-Ace addon can still adopt Perf.
3. `PerfPanel.lua` — replace the private `BACKDROP` and skin calls with `core.SKIN` /
   `core.ApplySkin`, and default the close button to `core.MakeCloseButton` when the host supplies
   no `decorate`. This makes the file's own "the library knows nothing about a host's chrome"
   comment true as written for the first time. Keep the `decorate` field (additive-only contract),
   and **leave AbsorbTracker's existing `decorate` alone** so the diff stays honest.
4. Bump `Perf` and `PerfPanel` minors; `CHANGELOG.md` names both.

Add `core: Perf refuses to register when Core is below NEEDS_CORE` to the suite, driven through
`loadSource` — the tool for exactly this already exists in the kit's loader.

### Step 4 — AbsorbTracker consumes it

`AT/core/CoreSetup.lua`, following `PerfSetup.lua`'s shape exactly, including a member-answering
degradation stub. It must publish `NS.Print`, `NS.Util.print`, `NS.SafeToString`, `NS.IsConcatSafe`
— and **`NS.Util.print` and `NS.Print` must be the identical function value** (spec §4.3), because
four settings files capture `local print = NS.Print` at load and `core/AbsorbTracker.lua` reclaims
it after the AceConsole clobber by repointing at that same object.

Delete `AT/core/Util.lua`. Update the TOC. Update `AT/core/PerfSetup.lua:10-11`, which currently
says it "sits immediately after core/Util.lua in the TOC for exactly that reason" — that file will
no longer exist.

Move the four Core-seam cases out of `AT/tests/test_util.lua`; the two DebugLog cases stay until M4.

### Gate & commit

Both green. `diff -r` empty. `CHANGELOG.md` names `Core minor 1` and `Perf minor 2`. Commit (ask).

---

## M4 — `LibKa0s-DebugLog-1.0`

### Files

- Create `LK/LibKa0s/DebugLog.lua`; modify `LibKa0s.xml`, `CHANGELOG.md`, `README.md`.
- Create `LK/tests/test_debuglog.lua`; modify `LK/tests/run.lua`.
- Create `AT/core/DebugLogSetup.lua`; **delete** `AT/core/DebugLog.lua`.
- Modify `AT/AbsorbTracker.toc`, `AT/tests/test_debuglog.lua`, `AT/tests/test_util.lua`.

### Interfaces produced

Descriptor per spec §5.1. Instance surface: `.buffer`, `FormatPlain`, `FormatColored`, `Add`,
`Clear`, `Show`, `Hide`, `Toggle`, `IsShown`, `SetEnabled`, `IsEnabled`, `RefreshHeader`,
`ShowCopy`, `UpdateScrollBar`, `UpdateStatus`, `ConsoleCheckbox`, `BufferSize`, `LastLine`,
`FindLine`, `_toggleClickForTest`; lib-level `lib.MakeCloseButton` re-exported from Core.

### Step 1 — the failing tests

`LK/tests/test_debuglog.lua` — the pure half: both formatters against the exact standard strings
(`6f8faf` timestamp, `c9a66b` tag, `||` rendering one literal pipe, the plain mirror carrying no
colour codes); the 500-line cap; `Clear` wiping log and buffer together; `SetEnabled`'s single write
path (flag → header → chat ack with `40ff40`/`ff4040` → `[Debug]` bracket at **both** transitions →
`[Init]` on enable only); the disable line landing *after* the flag flips (written through `Add`,
not the gated sink); the sink being zero-allocation when off; every vararg passing through
`safeToString`; two instances owning separate frames.

### Step 2 — verify they fail, then write it

### Step 3 — AbsorbTracker consumes it

`AT/core/DebugLogSetup.lua` with the descriptor and a member-answering stub. Two things must not
change:

- **`.buffer` keeps its name.** Seven suites index it directly — `test_database`, `test_debuglog`,
  `test_perf`, `test_slash`, `test_slashcmds`, `test_util`, `test_visibility`.
- **All 16 `NS.Debug(...)` call sites stay byte-identical.** `git diff` proving that is the parity
  artefact for this milestone.

`initSummary` becomes a host callback returning the version/schema/profile line — bringing
AbsorbTracker into line with the five sisters that already factor it out.

**Keep `decorate` lazy.** `PerfSetup`'s `decorate` calls `NS.DebugLog.MakeCloseButton`, and it is
safe today only because `decorate` fires at frame-build time, not load time. The obvious tidy-up —
resolving the factory into a `local` at `:New` time — reintroduces an ordering hazard. Write the
invariant into the file.

### Gate & commit

Both green. Perf's own suite must still pass unchanged. Commit (ask).

---

## M5 — `LibKa0s-Slash-1.0`

### Files

- Create `LK/LibKa0s/Slash.lua`; modify `LibKa0s.xml`, `CHANGELOG.md`, `README.md`.
- Create `LK/tests/test_slash.lua`; modify `LK/tests/run.lua`.
- Rewrite `AT/settings/Slash.lua`; modify `AT/settings/Schema.lua`, `AT/tests/test_slash.lua`,
  `AT/tests/test_slashcmds.lua`.

### Interfaces produced

```lua
Slash:New{
  slash, aliases, commands,        -- host-owned NS.COMMANDS, passed in (spec §5.4)
  print, version,
  get, set, findRow, applyDefault, allRows,
  parse,                           -- AbsorbTracker's type-aware parser, adopted as canonical
  groupKey,                        -- list-grouping strategy; AT returns "bar / player"
}
Sl.OnSlash(msg) / Sl.PrintHelp() / Sl.HelpRows() / Sl.LandingRows()
Sl.BuildListLines() / Sl.CliList/CliGet/CliSet/CliReset/CliResetAll/CliVersion
Sl.SetRowAnnotator(fn)             -- MirrorNote
```

### Step 1 — the failing tests

Library suite: dispatch (empty → help; unknown verb → error + help; alias rewrite; verb lowercased,
argument case preserved); the help header and row formats; `FormatKV` gold-key/white-value with no
trailing colon; `FormatSchemaValue` across bool / number+`fmt` / string / empty-string `(none)` /
colour tuple / key-set; `BuildListLines` ordering, `Available settings` header and the 2- and
4-space indents; the parser clamping to `max`, rejecting an out-of-enum string, parsing `r g b a`,
and accepting `true/false/on/off/1/0/yes/no`; `CliReset` resetting one path and rejecting an unknown
one; the annotator firing at exactly the three sites and never on `reset`/`resetall`.

Row formatting per spec D3: one formatter, uppercase hex, single-spaced em dash, **white**
description. `HelpRows()` adds the two-space indent; `LandingRows()` does not.

### Step 2 — verify they fail, then write it

### Step 3 — AbsorbTracker consumes it

The riskiest string work in the programme. `AT/settings/Slash.lua` drops from 446 lines to a
descriptor plus `NS.COMMANDS` plus the host verbs. **`NS.COMMANDS` stays in `settings/Slash.lua`**
— it is *not* relocated to `settings/Schema.lua` where the sisters keep it, because
`NS.SlashCommands = NS.COMMANDS` and the About page both depend on it and moving it buys nothing.

Host verbs stay host verbs: `lock`, `unlock`, `toggle`, `test`, `update`, `resetposition`, `perf`.

**`reset` converges to `reset <path>`** (spec D1). Delete `runReset`, `RESET_PAGES` and the
page-validation branch. Rewrite `test_slashcmds.lua`'s reset block against the new behaviour —
this block is *rewritten, not retargeted*, and it is the only sanctioned exception to the
no-weakened-assertions rule in this programme.

~~Add one host test that did not exist before: the Bar page's Defaults button still resets every
Bar setting across all three units.~~ **It already exists** — `tests/test_helpers.lua:385`, across
all three units, predating this branch. Verify it, do not duplicate it. That is where
`/at reset bar`'s behaviour now lives, and it was already pinned.

`settings/About.lua` switches to `Sl.LandingRows()` and its rendered output changes (spec D3).
Every *other* user-visible string is preserved. Any further assertion that has to change is
reported, not silently edited.

### Gate & commit

Both green. Commit (ask).

---

## M6 — `LibKa0s-Options-1.0`

The largest and the only one that can break the addon's **load** rather than its panel.

### Files

- Create `LK/LibKa0s/{Options.lua,OptionsWidgets.lua,OptionsScroll.lua}`; modify `LibKa0s.xml`,
  `CHANGELOG.md`, `README.md`.
- Create `LK/tests/{test_options.lua,test_options_widgets.lua}`; modify `LK/tests/run.lua` and add a
  fixture schema + fixture db to the kit.
- Create `AT/settings/OptionsSetup.lua` and `AT/settings/UnitPanel.lua`.
- **Delete** `AT/settings/{Panel.lua,Helpers.lua,ScrollPatch.lua,Widgets.lua}`.
- Modify `AT/AbsorbTracker.toc`, `AT/settings/About.lua`, `AT/tests/{test_helpers.lua,test_widgets.lua}`,
  `AT/tests/test_perf.lua` (`loadDegraded`).

### Step 1 — the failing tests, and the one that matters most

Library suite per spec §7.1, parameterised on the fixture schema.

**Then extend `AT/tests/test_perf.lua`'s `loadDegraded()` to the full file list** and assert
`#NS.Schema` equals the normal environment's. This is the R1 guard and the highest-value new test
in the programme: today `loadDegraded()` stops at `settings/Slash.lua` and never loads a page file,
so it would stay green straight through a total load failure.

### Step 2 — verify they fail, then write the three files

`Options.lua` — panel shell, registry, ctx, header, defaults button, `RegisterOptionsPage` /
`CreateOptionsPanel` / `OpenOptionsPanel` (with the combat **refusal**, never a defer) /
`expandMainCategory`, `RefreshAllPanels`, `RestoreDefaults`, `RestoreAllDefaults` with its
`afterRestoreAll` hook, `LSMValues`, and the `__panels()` / `__panelFor(pageKey)` test seams.

`OptionsWidgets.lua` — five makers (checkbox, slider, dropdown, colour picker, **edit box**),
`RenderField`, `SessionCheckbox`, `RenderRows` with `solo` / `skipRender` / `afterGroup` /
`pairWith`, `Section`, `AddSpacer`, `InlineButtonPair`, `AttachTooltip`, the layout constants.
Colour storage is a descriptor codec (AbsorbTracker's `{r,g,b,a}` vs KickCD's array). The 50 ms
throttle uses `descriptor.scheduleTimer`.

`OptionsScroll.lua` — the always-shown scrollbar patch, with the marker renamed
`_ka0sAlwaysScrollbar` and `test_widgets.lua`'s assertion updated in the same commit (it is the only
thing pinning the patch).

### Step 3 — AbsorbTracker consumes it

`AT/settings/OptionsSetup.lua` with the descriptor and a **load-completing** stub carrying
`LSMValues`, `SECTION_HEADING_H` and `RestoreAllDefaults` — the three members page files touch at
load time (spec §6.3).

`AT/settings/UnitPanel.lua` takes `RenderUnitPanel` and `ResetAllPositions` unchanged. **Do not
simplify the two-tier header refresher** — always re-sync the checkbox, re-render only when the
mirror flag changed. Three tests pin it, and it exists because the panel once lied.

### Gate & commit

Both green. `diff -r` empty. Commit (ask).

---

## M7 — Documentation

### Files

`AT/docs/{ARCHITECTURE.md,file-index.md,module-map.md,settings-panel.md,testing.md,agent-context.md,common-tasks.md,smoke-tests.md}`,
`AT/README.md`, `AT/CLAUDE.md`, `AT/.luacheckrc`;
`LK/{README.md,CHANGELOG.md}`, `LK/docs/releasing.md`.

### Content

- `LK/README.md` gains a descriptor table and a public-surface table **per module** — the shape the
  Perf module established.
- `LK/docs/releasing.md`: per-file minors for all eight files; whole-folder-only re-vendoring; the
  `testkit` → `tests/_kit` row; the Consumers list tracked **per module**, since addons adopt
  modules independently.
- `AT/docs/settings-panel.md` is substantially rewritten — it currently documents four toolkit files
  that will no longer exist, in detail.
- `AT/docs/smoke-tests.md` gains the spec §10 checklist.
- Regenerate both `docs/test-cases.md`; move both README badge counts.

### Gate & commit

Both green. Commit (ask).

---

## M8 — Review gate (yours)

`/wow-addon:review` on AbsorbTracker, and on LibKa0s. Findings triaged and fixed on this branch
before anything downstream is touched. **Hard stop.**

## M9 — In-game smoke tests (yours)

Spec §10, as a numbered checklist with expected output, including the perf parity capture. **Hard
stop.** Nothing in `WowAddonStandards`, the plugin, or the adoption prompt moves until this passes.

Writing a normative section from a design rather than from a working, verified extraction is how a
standard acquires rules that do not survive their second implementation.

---

## M10 — `WowAddonStandards`

Rewrite `debug-logging.md`, `options-ui.md`, `slash-commands.md`, `testing.md` and
`library-stack.md` to "consume the library, supply these descriptor fields", demoting the
implementation detail to rationale. `performance.md` is the precedent for the wording — **and is
itself amended**, because spec D2 makes Perf depend on Core, so its normative "LibStub and nothing
else" becomes "LibStub and `LibKa0s-Core-1.0`, and no addon framework". `slash-commands.md` records
`reset <path>` as the collection-wide shape now that AbsorbTracker has converged (spec D1). Add
anti-patterns for hand-rolling a console, editing `libs/`, and forking the toolkit. Extend
`library-stack.md` for a multi-module LibKa0s and the inter-module rules. Update `AUDIT.md` and
`NEW_ADDON.md` so a fresh audit does not flag a compliant lib-consuming addon and a new addon is
born consuming LibKa0s. Bump the index version and date.

**Promote these two working rules to normative text.** Both are carried in this plan's global
constraints, both have already cost time when forgotten, and neither is written down anywhere a
future agent or a fresh addon would find it:

- **A vendored `libs/` folder is read-only.** A library defect is a finding to fix upstream and
  re-vendor whole-folder — never a local patch, because the next re-vendor silently reverts it and
  the revert looks like a regression with no cause. `library-stack.md` is the home; the existing
  "editing `libs/`" anti-pattern above is the hook, but it needs the *whole-folder* half stated too,
  since per-module re-vendoring is how cross-major minor skew gets manufactured.
- **Per-file minor discipline, mechanically enforced.** Every file changed in a change bumps its own
  `MINOR`, and `CHANGELOG.md` gains a line containing the literal substring `<FileBasename> minor
  <N>`. The point is not the convention but that a test asserts it — `test_versioning.lua` is the
  reference implementation, and it belongs in `testing.md` as a required suite for any addon that
  publishes per-file versions, alongside the two cases the multi-major layout forced: no file may
  register under a major it does not belong to, and file basenames must be unique across majors.

## M11 — the `wow-addon` plugin

Update the standards-audit and review agents (they encode the standard's expectations and will
otherwise flag a compliant addon) and the new-addon command. The survey has the file-by-file list.

## M12 — `LibKa0s/docs/adoption-prompt.md`

Rewrite for all five modules plus the perf run, across the remaining seven addons. Keep the existing
prompt's shape; replace its central assumption — Perf needed only a descriptor, these four require
deleting files the addon currently owns. Carry the per-addon risk notes: KickCD is riskiest for
Options and for Core (no secret guard at all — migrating it is a behaviour change, not a refactor);
ConsumableMaster is riskiest for the harness; prettychat is riskiest for Core.

Adoption order: **KickCD first**, per the Perf precedent — the most structurally complex, so the
most likely to expose a descriptor assumption that only held for AbsorbTracker.

---

## Open items carried forward

*Everything known-outstanding, in one place. A deviation records a decision already taken; this
records work not yet done. Anything finished here gets struck from the list in the same commit that
finishes it.*

### Defects in this plan and its spec, found during execution

- **Spec §7.1 (line ~586) still lists `reset <page>` under "Stays in AbsorbTracker".** D1 deletes it.
  §7.1 is stale and D1 governs, being the later explicit decision. Fix when the spec is next touched;
  do not follow §7.1 on this point.
- **M5's "Interfaces produced" block lists `Sl.CliResetAll` but no `Sl.CliReset`**, while its Step 1
  test list requires "CliReset resetting one path and rejecting an unknown one". Both members exist
  and are needed; the interface block was simply short.
- **M5 Step 3 asks for a host test that already existed.** "The Bar page's Defaults button still
  resets every Bar setting across all three units" is `AT/tests/test_helpers.lua:385`, and predates
  this branch. Recorded as M5c; the plan text above still asks for it and should not be followed
  literally.
- ~~**M6 schedules "a fixture schema + fixture db to the kit", but M5 needed them first.**~~ Settled
  in M6 as **M6b** below: neither fixture went into the kit, and M6 wrote its own rather than
  reusing M5's, for a reason recorded there.

### Deferred work with a known trigger

- **M2a — the frame-stub fidelity fix.** `CreateTexture`/`CreateFontString` still return the frame
  itself. Fixing it moves `AT/tests/perf.lua`'s `api/iter` parity figure and edits assertions in
  `test_display.lua`, so it needs its own change, its own test updates and a fresh baseline. It is
  the reason several suites reach for `__label`/`titleText`-style recorded fields instead of reading
  a font string back.
- **D3's cost lands in M12.** BankLedger, LootHistory and PanelMaster render their landing pages in
  the *About* shape, not the `/at help` shape. Converging AbsorbTracker means all three change when
  they adopt. The spec names this as the accepted direct cost of D3; it is not to be re-litigated,
  only paid.
- **The two user-visible changes need eyes in-game (M9).** `/at reset <path>` replacing the page
  form, and the About page's command rows re-rendering in the help colours. Neither is caught by any
  automated check in either repo — the About page has no rendered-output assertion at all.

- **`AT/tests/test_widgets.lua`'s `sorting` case cannot fail.** "A row with explicit `sorting` keeps
  that order instead of sorting" runs against `fontFlags`, whose values sort alphabetically into
  their own declared order — so an implementation that ignored `sorting` entirely would pass it.
  Found by mutation while auditing the library's equivalent (M6c), which was reshaped; this one
  predates the branch and is the addon's own to fix, with a schema row whose declared order is not
  its alphabetical one. Not urgent: the library's case now covers the behaviour, and this one is
  merely uninformative rather than wrong.

- **Six AbsorbTracker `.lua` files are LF on disk, not CRLF**: `settings/Schema.lua`,
  `settings/Widgets.lua`, `tests/run.lua`, `tests/test_display.lua`, `tests/test_schema.lua`,
  `tests/test_widgets.lua`. `.gitattributes` pins `*.lua eol=crlf`, but git compares normalised
  content, so an LF working file reads as unmodified and nothing flags it. It is invisible to the
  repo and to the packager (which builds from a fresh checkout, and therefore gets CRLF), so it is
  cosmetic — but an edit script that splits on `\r\n` silently does nothing to these six. Check the
  file's own convention before editing it. Worth one normalising commit of its own; not worth
  churning six files inside an unrelated milestone.

### Standing rules that keep being rediscovered

- **`sed -i` with a `$` anchor never matches a CRLF line.** It reports success and changes nothing.
  This silently left a dangling `test_util` entry in a suite list for a whole milestone (M4h). Use a
  CRLF-aware edit for anything anchored to end-of-line.
- **A suite listed in a runner but missing from disk is skipped, not failed.** So is a library file
  omitted from a hand-maintained load list — the dependent module just refuses to register and the
  runner measures a stub. Both have happened (M3c, M4h). `test_loadorder.lua` now covers the second.
- **Restore a mutated file from a `cp` backup, never from `git checkout`.** During a milestone the
  work is uncommitted, so `git checkout <file>` reverts it to HEAD rather than to what you had a
  moment ago. This destroyed an entire M5 rewrite (M5k). Back up, mutate, run, restore, diff.
- **`and`/`or` is not a conditional when the value can be `false`.** It has now silently eaten a
  legitimate value twice, in two different modules, three milestones apart (M4c, M5g). Spell the
  `if` out whenever the middle term is host-supplied.
- **A test that cannot fail is worse than no test**, because it reads as coverage. Every case
  asserting a NEGATIVE — a thing not resolved, a value not written, a note not appended — needs a
  mutation run against it before it is believed (M5h, M5i, and four in M4).
- **Line count is not a proxy for duplication removed.** M5e: `settings/Slash.lua` did not shrink,
  because a descriptor plus the degradation stub §6.3 mandates cost what the extracted logic saved.
  What matters is that no copy of a formatter, a parser or a rendered string remains downstream.

---

## Deviations from the spec, decided here

*Flagged rather than smuggled in.* Filled in during execution, per the Perf plan's convention.

**D3a — the help-row indent stays chat-only.** Carried from spec D3. "Converge on the `/at help`
shape" is applied to the *colouring and spacing* but not to the two-space leading indent. An indent
exists to sit a chat line under a header; in an AceGUI `Label` on a settings panel it reads as a
mistake. `HelpRows()` indents, `LandingRows()` does not. One line to reverse if that call is wrong.

**M2a — the frame-stub fidelity fix is deferred, not done.** The plan put "`CreateTexture` and
`CreateFontString` return distinct objects" in M2's scope. It is **not** in the shipped kit, and the
reason is evidence found while writing it:

- `AT/tests/perf.lua` memoises frame proxies *because* `bar.valueText` and `bar.statusBar` are
  currently the same table. Distinct objects change the `api/iter` figure — which is the parity gate
  every later milestone is measured against.
- `AT/tests/test_display.lua` counts `Show`/`Hide` calls that presently land on one shared object,
  and documents that aliasing in a comment.

So the fix would have moved the baseline and edited existing suites in the same milestone whose
acceptance criterion is "no existing suite changes" — it would have destroyed the instrument while
calibrating it. It is recorded as a known divergence in `testkit/README.md` and
`testkit/mock_base.lua`, with the reason, and is a change of its own with its own test updates and
a fresh baseline.

**M2b — three mechanical call-site edits in existing suites.** The acceptance criterion held for
*behaviour*: not one assertion changed, and no suite's expectations moved. Three path/signature
updates were unavoidable: `LK/tests/test_perf_isolation.lua` and `LK/tests/test_perf_panel.lua`
switch `dofile("tests/loader.lua")` to `tests/_kit/loader.lua`, and their three `Loader.load` /
`Loader.loadSource` calls gain the kit's explicit `NS` argument (passed as `nil`, since library
chunks take no arguments). Recorded here so "zero edits" is not claimed more broadly than it holds.

**M2c — three things did not go into the shared base**, each because the base would have been wrong
rather than merely large:

- **`C_AddOns`** — it is the target of every addon's Compat metadata shim, and those shims are
  tested by swapping `_G.C_AddOns` to nil to reach the deprecated-global fallback. The loader env
  resolves mocks *before* `_G`, so a base-level stub shadows the swap and makes the fallback branch
  unreachable. Three AbsorbTracker `test_compat` cases failed and said so. Each repo stubs it in its
  own extender.
- **`UnitClass`** — universal in name, but its *values* are fixture data the suites assert on
  (LibKa0s expects a Death Knight, AbsorbTracker a Mage, and AbsorbTracker's class-colour table is
  keyed on the token). The base now reads class and token from `__context` — the more faithful
  shape, since the localised name and the uppercase token are different strings — and each repo
  overrides the two fields.
- **`strsplit` / `strtrim`** — neither consumer calls them. A hand-rolled reimplementation of a WoW
  string function that nothing exercises is a subtly-wrong shared helper waiting to be adopted by
  the next addon. The first addon that needs one adds it to its own extender with a test.

**M2d — the stopwatch mock adopted LibKa0s's shape, not AbsorbTracker's.** An ordered log of
`clear`/`play`/`pause` rather than three counters: the *order* is the only observable difference
between an armed window and a recording one, and counters report identical totals for a correct run
and one that played before it cleared.

**M3a — Core's degradation stub keeps working fallbacks, and says "not installed" once.** §6.3 says
the five stubs each answer "with an honest 'not installed' line rather than silence". That wording
reads straight for Perf, DebugLog, Slash and Options, whose members are *features*. It does not
read straight for Core, whose members are the *mechanism every other line is emitted through*: a
printer that answered "LibKa0s is not installed" instead of printing would make every `/at` command
in the addon say nothing else, and five settings files capture `local print = NS.Print` at load, so
a no-op or a nil there takes the settings UI down with it.

So `core/CoreSetup.lua`'s stub carries the pre-library implementations — the `table.concat` probe,
the stringifier, the `[AT]`-prefixed printer, about fifteen lines — and emits the honest line ONCE,
ahead of the first line the addon prints. The user is told; the addon keeps working. The duplicate
algorithm this milestone exists to end is not reintroduced on the shipped path: it exists only in
the branch taken when the library is absent, and `tests/test_coresetup.lua` loads the addon without
the library to exercise it, rather than hand-stubbing.

**M3b — three mechanical retargetings in existing LibKa0s suites.** D2 gives Perf a dependency, so
every test that builds a fresh env and loads `Perf.lua` into it has to load `Core.lua` first, exactly
as the client does. `tests/test_perf_panel.lua`'s panel-less case and `tests/test_perf_isolation.lua`'s
`loadCopies()` gained one `Loader.load("LibKa0s/Core.lua", …)` each. No assertion changed and no
expectation moved.

**M3c — `tests/perf.lua`'s library list had already rotted, and now has a test.** §6.2 named
`AT/tests/perf.lua` as the load list that is not under the green gate. It is worse than "rots
silently": omitting `Core.lua` there raises nothing at all, because Perf then refuses to register,
`NS.Perf` falls back to `PerfSetup.lua`'s degradation stub, and the runner goes on printing a
`probeOverheadOn` figure measured on a stub with no probe in it — 312.0 bytes/iter instead of 312.3,
a change small enough to read as noise. It was caught by comparing against the figure this plan
records, which is the only reason it was caught at all.

M1's TOC derivation does not cover this: the TOC reaches the library through
`libs\LibKa0s\LibKa0s.xml`, which `Loader.tocFiles` deliberately skips, so the library half of both
runners' lists is necessarily hand-maintained. `AT/tests/test_loadorder.lua` gains a case that parses
the vendored XML and asserts both `tests/run.lua` and `tests/perf.lua` load every file it lists, in
its order. Every later milestone adds a file to that XML, so this is the gate that makes M4–M6
provable rather than merely green.

**M3d — one AbsorbTracker suite the plan did not list.** M3's file list has the four Core-seam cases
simply moving out of `AT/tests/test_util.lua`. Moving them out and stopping there would delete the
addon's only coverage of the seam: the *algorithm* is LibKa0s's to test, but *that AbsorbTracker is
wired to it* is AbsorbTracker's, and deleting `core/Util.lua` would otherwise leave nothing to fail
if `CoreSetup.lua` published nothing at all. `AT/tests/test_coresetup.lua` covers the four things
only this repo can break: that `NS.SafeToString`/`NS.IsConcatSafe` are the library's own function
values and not a leftover copy, that a printed line carries the `[AT]` tag, that `NS.Print` and
`NS.Util.print` are one object across the AceConsole reclaim, and the degraded build.

**M4a — `print` does NOT default to a Core printer instance.** The descriptor table says `print`
"defaults to Core's", but §3.2 rule 1 forbids a `Core:New` result crossing between modules, and
Core's printer requires a `prefix` DebugLog has no way to know. So the default writes to
`DEFAULT_CHAT_FRAME` untagged — which is Core's *default sink*, the part of "Core's" that can
travel — and the descriptor documents that a host wanting its tag passes its own printer, which
every Ka0s addon does. `safeToString` genuinely does default to Core's, because that one is a
stateless function and rule 1 permits exactly that.

**M4b — `lib.MakeCloseButton` is re-exported from Core, on the plan's authority, not the spec's.**
The spec never mentions it; all three of its `MakeCloseButton` references are Core to Perf. But the
plan's M4 interface list names it, and the live code needs it: `core/PerfSetup.lua` hands
`NS.DebugLog.MakeCloseButton` to Perf through `decorate`, so dropping the member breaks the perf
panel's close button. Re-exporting the *same function object* rather than a wrapper is what makes
"one factory" true — a test asserts the identity. Note this freezes a new name into `-1.0`
forever, which is why it is recorded here rather than assumed.

**M4c — a second test seam, `_frameForTest`.** The visibility callback is hooked to the frame's
OnShow/OnHide rather than called from `Show()`/`Hide()`, deliberately: Esc and the close button both
hide the window without going through either method, and a host whose settings checkbox mirrors
visibility has to follow those too. The headless mock's `Show()` tracks visibility without firing
OnShow, so the only way to exercise the hook is to drive the handler directly. Same justification as
the existing `_toggleClickForTest`, and written into the file next to it.

**M4d — `.luacheckrc` gained `432/self`.** A module whose instance carries methods defines them as
`function D:Method()` inside the `lib:New` body, so each one's implicit `self` shadows New's own.
The shadowing is the point, and the outer `self` is the one the config's existing paragraph already
says never to read. M5 and M6 have the same shape, so this is a one-time config change rather than a
per-file annotation.

**M4e — `AT/tests/test_util.lua` is deleted, not modified.** The plan's file list says "modify". It
held exactly two cases by the start of M4, both of them the shared sink's, and both moved upstream.
Leaving a suite file with no cases in the runner's list is worse than deleting it: the framework
silently skips a listed file that does not exist, so an empty one reads as coverage that is not
there.

**M4f — the buffer cap is tested for the first time.** `MAX_BUFFER = 500` and the
`table.remove(buffer, 1)` eviction have shipped since the console was written, and no addon suite
ever wrote 501 lines, so the eviction path had never once executed under test. The upstream case
writes `MAX_BUFFER + 10` lines and asserts both that the length holds at the cap and that the line
dropped is the OLDEST — a cap that evicted the newest would keep the length correct and the console
useless.

**M4g — `DebugLogSetup.lua` keeps `DebugLog.lua`'s TOC slot, not the one §6.1 draws.** The spec's
core block puts `core\\DebugLogSetup.lua` immediately after `core\\CoreSetup.lua` and before
`core\\PerfSetup.lua`. The shipped TOC leaves it where `core/DebugLog.lua` was, after
`core\\LSMPatch.lua` — so `PerfSetup` still loads *first*, exactly as it did before the extraction.

Recorded rather than silently taken, because it is load-bearing in a way that reads like an
oversight. `core/PerfSetup.lua`'s `decorate` reaches for `NS.DebugLog.MakeCloseButton`, and it is
allowed to only because `decorate` fires at frame-build time, long after every file has loaded —
which is the invariant the plan says to write into the file, and which exists *because* of this
ordering. Moving DebugLogSetup up to where §6.1 draws it would make `NS.DebugLog` already present
when PerfSetup loads, and the next reader would then delete the lazy-lookup comment as pointless,
re-arming the hazard for whichever addon adopts next with the opposite order. Zero TOC churn was
also the stated goal of §3.1. `tests/test_perf.lua`'s `loadDegraded()` list mirrors the real order
for the same reason.

**M4h — the review pass rewrote more of M4 than it flagged.** Worth recording because the findings
were not stylistic. Three were behavioural drift I had introduced while transcribing the console:
the Copy and Clear title-bar buttons ended up in the opposite order with different widths, the
title-bar divider silently took the *status* divider's colour and inset, and the drag bar lost its
one-pixel inset — every one of them a host literal that had quietly failed to find a home, and every
one inherited by all seven addons that adopt. One was a live hazard: `ApplySkin` indexed
`skin.bg[1]` unguarded while the descriptor documents `skin` only as "overrides Core.SKIN", so a
host passing a plain WoW backdrop table would raise *after* the frame was assigned but *before*
`Hide()` and the Esc wiring — a visible, un-closable console that `EnsureFrame` would never rebuild.
The skin call now runs after both, alongside the scroll sync, for the reason that comment already
gave.

Four more were tests that could not fail: the console title assertion reduced to `frame ~= nil`
(the mock's `CreateFontString` returns the frame itself), `ShowCopy` asserted only that `pcall`
survived, `Hide` "never builds" was unfalsifiable because the builder ends in `Hide()` anyway, and
the coloured formatter's *delivery* was pinned nowhere — swapping it for the plain one left both
suites green. Each is now driven through a real seam (`frame.titleText`, a new `D:CopyText()`, the
`_frameForTest` build probe, and a recorder rawset on the message frame), and each was confirmed by
mutating the implementation and watching the case go red.

And one was the failure mode this plan keeps rediscovering: `tests/run.lua` still listed
`test_util`, deleted in this very milestone. The framework skips a listed-but-missing suite by
design, so the run stayed green at 432 with a dangling pointer — the same silent load-list rot as
M3c, one milestone later, in a file M4 had already edited. The cause was mechanical: a `sed`
expression anchored with `$`, which never matches a CRLF line ending, reported success and changed
nothing.

**M5a — the reset block is nine cases, and only five were rewritten.** D1 suspends the
no-weakened-assertions rule for "`tests/test_slashcmds.lua`'s reset block". That block is not what
it looks like: seven cases sit under the `reset / resetall / resetposition` banner and two more hide
a few hundred lines away under `qualified per-unit slash paths`. Of the nine, only the five taking a
PAGE argument describe behaviour D1 removes. `resetall` (two cases) and `resetposition` (two) both
survive untouched — `resetposition` is a host verb the plan keeps, and `resetall` is in M5's own
interface list. Rewriting those four would have been an unsanctioned weakening wearing D1's
exemption, so the line was drawn at five.

One of the five inverts rather than dies. "`/at reset` lower-cases the page name" encoded a rule
that was only safe because pages were a closed lower-case set; a path is case-sensitive, so the
replacement asserts the opposite — `reset UNITS.PLAYER.BARWIDTH` must NOT resolve. A mechanical
retarget would have installed the wrong contract while staying green.

**M5b — four cases that have nothing to do with reset used it as teardown.** `slash("reset bar")`
was the cleanup line in the colour-parse case and three profile cases. With the verb's meaning
changed those stop cleaning up, leaving `barColor` at `{0.1, 0.2, 0.3, 0.4}` and `barWidth` at 456
for every later case in a suite that shares one database — a cascade in the mirror and profile
blocks that would have looked nothing like a reset problem. All four now call
`NS.Helpers.RestoreDefaults("bar")`, which is what they always meant.

**M5c — the test the plan asks for already exists.** M5's Step 3 says to add "one host test that did
not exist before: the Bar page's Defaults button still resets every Bar setting across all three
units", because "nothing currently pins the equivalence". `tests/test_helpers.lua:385` pins exactly
that, across all three units, and has since before this branch. Nothing was added; the plan is wrong
rather than the suite being short, and D1's "the capability is not lost, only the CLI route to it"
was already under test.

**M5d — D3 is scoped to the command-row formatter and nothing else.** The decision says "uppercase
hex, single spaces around the em dash, white description", and every hex code it names belongs to
the help/landing ROW. The `/at list` header (`33ff99`), its group headings (`3399ff`) and the mirror
note (`808080`) are lower-case today, are a different formatter, and were left exactly as they are —
recasing them would be a user-visible change outside what was asked for. The library carries them as
lower-case strings with a comment saying why, and a case pins them.

**M5e — the AbsorbTracker file did not shrink.** §6.1 predicts `settings/Slash.lua` "shrinks from
446 lines"; it is 462. The duplicated logic genuinely left — the dispatcher, the help renderer, both
formatters, the list builder and the parser are all gone — but a descriptor and the member-answering
degradation stub §6.3 requires cost about what they saved. The stub deliberately carries NO copy of
the row formatter, the parser or the key/value shape: hand-copying the strings whose drift the
extraction exists to end is the duplicate `testing-§8` most specifically forbids, so a degraded help
row renders plainly and the schema verbs say which library is missing. Line count was the wrong
proxy for the thing being measured.

**M5f — D3 had no test behind it anywhere, in either repo.** Grepping both AbsorbTracker slash
suites for the em dash, the two-space help indent and the four-space list indent returns nothing:
colour escapes were pinned, spacing never was, and the About page has no rendered-output assertion at
all (`test_widgets.lua` only pcalls its OnShow). The convergence could therefore have gone in either
direction with both suites green. It is pinned upstream now — the formatter byte for byte, the
indent difference between `HelpRows` and `LandingRows`, and the list's own colours — and each of
those was confirmed by mutating the implementation and watching the case fail.

**M5g — the `and`/`or` idiom collapsed a stored `false`, and nearly shipped.** The library's
`read(path)` was written `type(d.get) == "function" and d.get(path) or nil`. A stored `false` makes
the whole chain yield nil, so every unticked checkbox in a host addon — `locked`,
`showOnlyInCombat`, two of the three `enabled` flags, all nine `useClassColor*` toggles — would have
rendered as `nil` instead of `false` in `/at list`, `/at get` and every `set` echo. `FormatValue`
itself was correct; the value was destroyed two calls earlier.

Both suites were green. The upstream fixture's only false-valued bool was never read back through
`CliGet` or `CliList`, and no AbsorbTracker case asserted a false bool's rendered line — a gap that
predates the extraction. It is the same idiom, in the same shape, as the one M4c fixed in DebugLog's
prefix resolution three milestones earlier. Both are now spelled out with an explicit `if`, both
carry a comment saying why, and a regression case in each repo pins a stored `false` rendering as
`false`.

**M5h — two assertions about case-sensitivity could not fail.** `/at reset UNITS.PLAYER.BARWIDTH`
was asserted to leave the value alone and print "Setting not found" — but the lower-cased form is
*also* not a registered path, so both halves held whether or not the implementation folded case.
Confirmed by mutation: adding `path = path:lower()` to `CliReset` left both cases passing. They now
assert the ECHOED path, which is the only thing that differs between the two implementations.

**M5i — D3 was unguarded in the repo where it is visible.** Three mutations to the row formatter —
lower-casing the hex, replacing the em dash, dropping the chat indent — each left AbsorbTracker at
436 passed / 0 failed. The About page's rows were reached only by a `pcall` smoke test that asserts
nothing, so the deliberate visible change had no regression net under it and a silent revert to the
old shape would have shipped green. Two cases now pin the landing rows byte for byte and their
relationship to the chat form, and all three mutations fail.

**M5j — the host kept two dead copies of what moved.** `NS.ParseSchemaValue` and its five private
helpers were still in `settings/Schema.lua`, unreachable in production (the descriptor passes no
`parse`, so the library's parser is what runs) and still under test — and already drifting, since
the library's `allowedValues` had gained a `tostring` the host copy never got. Deleted, along with
the four downstream cases duplicating LibKa0s's own. `NS.FormatSchemaValue` was a live second
implementation, kept only for the `[Set]` debug line; it is now a delegate, so the `/at get` echo
and the debug line cannot disagree.

**M6a — the layout constants live in `Options.lua`, in one table, not in `OptionsWidgets.lua`.**
M6's plan text assigns "the layout constants" to `OptionsWidgets.lua`. Four of the nine are the
shell's: `PADDING_X`, `HEADER_TOP`, `HEADER_HEIGHT` and `DEFAULTS_W` decide where the header sits
and therefore where the body starts, and `Options.lua` is the only file that reads them. Splitting
the table would have put the two halves of one measurement in two files, and they are not
independent — `HEADER_HEIGHT` decides where the body begins and `ROW_VSPACER` decides how it fills,
so a header that moved without its rows following looks broken in exactly the way nobody files a
bug about. `lib.LAYOUT` holds all nine; `OptionsWidgets.lua` reads it rather than keeping a copy;
the three cross-slice values a host needs are re-exported on the instance under the names
`settings/Helpers.lua` published them under, so no page file or suite changed.

**M6b — the Options fixture is a third file, not a promotion of `fixture_slash.lua`.** The open item
above asked M6 to reuse or promote M5's fixture rather than write a second one. It wrote a third,
and the reason is the row SHAPE rather than tidiness.

`fixture_slash.lua`'s rows are chosen to reach the parser and formatter branches — a clamped number,
an enum, an empty string, a colour — and carry no `group`, `label`, `order`, `solo` or `skipRender`,
because the dispatcher reads none of them. Every branch the Options module has is in exactly those
fields. Bolting them on would either mutate a table two suites share, or leave each fixture carrying
the other's dead weight. Promoting the shared half — a store, a `deepCopy` and a `byPath` index,
about twenty lines — into the kit would additionally have made a test fixture something that must be
mirrored to `tests/_kit/` and re-vendored into every consuming addon, for twenty lines neither
consumer's own suites use.

What the third file is NOT is a second copy of anything the first one tests: no parser, no
formatter, no dispatcher. It is a schema, a store and three structural readers.

**M6c — the Options fixture's schema was reshaped twice by the mutation audit, and three assertions
were unfalsifiable before it.** Each was green, each read as coverage, and each was found by
mutating the implementation rather than by reading the test:

- **`solo` flushing the row in progress.** The solo row led its group, so the group's own Section
  heading flushed the pending row anyway and a maker that ignored `solo` entirely still left it
  alone on its line. Deleting the flush left the suite at 329/0. The fixture now orders a non-solo
  row ahead of it in the same group.
- **Slider snapping being relative to `min`.** The row under test ran 0.05–1 in 0.05 steps, and a
  `min` that is an exact multiple of `step` makes the two implementations agree on every input.
  Snapping from zero left the suite green. The fixture's `barHeight` now runs 15–105 in 10s.
- **An explicit `sorting` beating the alphabetical default.** The enum was `NONE` / `OUTLINE` /
  `THICKOUTLINE`, which sorts alphabetically into its own declared order, so ignoring `sorting`
  changed nothing. Replaced with `TOP` / `CENTER` / `BOTTOM`. Worth noting that
  **`AT/tests/test_widgets.lua` carries the same weakness on `fontFlags`** and has since before this
  branch; it is not M6's to fix, and it is recorded in the open items below.

The alphabetical case was also strengthened from "non-decreasing" to the exact sequence: `pairs`
order is arbitrary in Lua, so a dropped `table.sort` could satisfy a monotonicity check by luck.

**M6d — one mechanical retargeting in an existing AbsorbTracker suite, and it is a real seam
change.** `tests/test_helpers.lua`'s "EnsureDefaultsButton is a safe no-op without AceGUI" nil'd
`NS.AceGUI`. Since the extraction `NS.Helpers` IS the LibKa0s-Options instance and stashes AceGUI on
ITSELF (library-stack-§4 — one lookup, not one per builder); `NS.AceGUI` is the copy the library
hands the host for its own page files, through the descriptor's `onAceGUI`. In game the two are
always the same object, so the case now nils `NS.Helpers.AceGUI` — the same scenario read at the
seam the code under test actually uses. No assertion changed.

The only other existing-suite edit is the planned one: `test_widgets.lua`'s
`_atAlwaysScrollbar` → `_ka0sAlwaysScrollbar`, in the same change as the rename.

**M6e — `NS.Helpers` IS the instance, not a table decorated from it.** The alternative was a host
table copying the library's members across. Two things then break. `settings/UnitPanel.lua` and
`settings/About.lua` decorate the same table the library's own members live on, so `RenderUnitPanel`
reaches `RenderRows` through `Helpers` exactly as every page file does; and a suite that swaps a
member out to spy on it — `tests/test_helpers.lua` does precisely that with `ResetAllPositions`, to
prove the panel button and `/at resetposition` are one implementation — is swapping the one the
library's own callers see. A copy-across would have made that assertion pass while proving nothing.

It also means forty-odd call sites across the page files and the suites kept indexing `NS.Helpers`
unchanged, which is the parity artefact §7.2 asks for in a milestone with no numeric output.

**M6f — `loadDegraded()` derives its list from the TOC rather than naming files.** The plan says to
"extend it to the full file list". Extending a hand-maintained list is the failure mode this
programme has now hit twice (M3c, M4h), and the loader already parses the TOC for the main runner.
It is one call. The R1 case that rides on it was confirmed by two mutations: reverting the list to
its pre-M6 stopping point at `settings/Slash.lua` failed **that case alone**, at 433/1 — which is
the plan's claim about the old list proved rather than asserted — and removing `LSMValues` from the
degradation stub took the whole degraded environment down with it.

**M5k — `git checkout <file>` destroyed an uncommitted rewrite mid-milestone.** Restoring one
mutated file after a mutation test, `git checkout settings/Slash.lua` reverted the entire M5 rewrite
to HEAD, because the milestone was not yet committed. The file was rebuilt from the edit record and
verified identical in behaviour, but the lesson is cheaper learned than repeated: during a
milestone, restore a mutated file from a `cp` backup taken immediately before the mutation, never
from git. `cp` the file, mutate, run, `cp` back, and diff against the backup to prove the restore.

**M7a — the doc rewrite broke the byte-identity gate it was documenting.** M7 improved
`LK/testkit/README.md` and did not re-vendor it, so `diff -r testkit tests/_kit` failed in LibKa0s
and `diff -r LK/testkit AT/tests/_kit` failed downstream — while three separate documents
(`LK/README.md`, `LK/docs/releasing.md`, `AT/docs/file-index.md`) asserted in the same change that
the gate passes. The three `.lua` files were identical throughout; only the README diverged, which
is exactly why nothing caught it: no test loads a README, and both suites stayed green. This is
`releasing.md`'s own "the step that gets forgotten" happening inside the commit that documents it.
The kit is not only code — every file under `testkit/` is vendored, and the mirror check is the
only thing that says so.

**M7b — the rewrite made one correct claim wrong, and a mutation-style audit found it.** The
pre-M7 text said the `NS.Debug` call sites span "five files" and was right; the rewrite changed it
to "sixteen call sites across six files" by counting a `grep` hit that is a COMMENT in
`core/DebugLogSetup.lua`, and by counting the binding site as a call site. Truth is fifteen calls
across five files. The lesson is the one M4 and M5 already paid for in tests, restated for prose: a
count copied from a `grep | wc -l` is not verified, because `grep` does not know what a call site
is. Every count this milestone wrote was re-derived from the source, and this is the one that was
re-derived carelessly.

**M7c — two stale code comments were fixed inside a documentation milestone.** `core/CoreSetup.lua`
said five settings files capture `local print = NS.Print` (four do — `Schema`, `Slash`,
`OptionsSetup`, `General`) and `defaults/Profile.lua` said four master toggles (three — `hidden`
went in the v4 migration). Both are comment-only, neither moves a byte of behaviour, and both were
the SOURCE the docs had been copying, so fixing the docs without them would have left the next
writer to reintroduce the error from the code. AbsorbTracker publishes no per-file minors, so
neither edit owes a version bump.

**M7d — 69 references to the deleted files survive on purpose.** `docs/audits/` and
`docs/superpowers/` are frozen dated documents — an audit that described the tree as it was is not
stale, it is a record, and rewriting it would destroy the only evidence of what was true then. The
13 remaining hits in live docs are deliberate archival references: `complexity.md`'s extraction
table and its struck-through CCN rows, `file-index.md`'s note on the old TOC slot, `testing.md`'s
history line. The grep the plan asks for before declaring M7 finished returns 82, and 82 is the
right answer.

**M8a — the review gate paid for itself twice, in the two places nothing else was looking.**
Four High and seven Medium in LibKa0s, three High and six Medium in AbsorbTracker, no Critical. The
two that would have reached users were both invisible to every existing check: Options' default
`print` was a silent no-op alone among the five majors, so a host omitting it got a combat refusal
that vanished with nothing to grep for; and `Slash.FormatValue` fed three branches to
`string.format` unguarded, where a WoW secret raises exactly as it does in `table.concat`. The
invariant that made the second one safe — a stored settings value is never a combat-protected one
— was real, but written down nowhere and enforced nowhere.

**M8b — one finding was rejected, and the rejection got a test.** The review wants
`RestoreDefaults` to pass `ctx.unit` so it matches `RenderSchema`. Resetting every unit is the
DELIBERATE behaviour: it is where `/at reset <page>` went under D1, and `test_helpers.lua` pins it
across all three units. What was real is that the asymmetry was undocumented, so the next reader
"fixes" it and silently narrows a host's page reset. It is now commented, and a new upstream case
fails if anyone makes exactly the proposed change. A rejected finding that leaves no artefact gets
re-found and re-accepted by the next reviewer.

**M8c — F-008's mirror-refresher fix is deferred on instrument grounds, not merit.** Gating the
re-render on `ctx.panel:IsShown()` is a real improvement, but the behaviour is carried over VERBATIM
from the deleted `settings/Helpers.lua` and predates this branch; it is latency across three pages,
not a correctness bug; and M9's entire purpose is to confirm the extraction changed nothing visible.
Changing panel rebuild behaviour immediately before that pass would muddy the only instrument that
can detect a regression it introduced. Same reasoning as M2a. It is now the top item for the change
after M9.

**M8d — the new kit-sync gate caught a real divergence within an hour of existing.** F-011 asked
for `testkit/` ↔ `tests/_kit/` to be mechanical rather than remembered, because M7a had just shipped
a README that was never re-vendored. The en-US comment sweep in this very milestone touched
`testkit/mock_base.lua`; the suite went red naming that exact file before the re-vendor. A gate that
fires on its author, in the change that adds it, is the strongest evidence it was needed.

**M8e — two parallel agents collided on one test file, and the loss was silent.** Writing cases
into `tests/test_helpers.lua`, one worker was whole-file-overwritten by another and its cases
vanished with the suite still green — a smaller number passing reads exactly like a smaller number
of cases. It was caught only because the worker re-counted. The fix was to give it a file it owned
(`tests/test_optionssetup.lua`). When fanning work out, partition by FILE and treat a shared test
file as a write conflict, not a merge.

**M8f — an upstream fix invalidated a downstream assertion, correctly.** LibKa0s F-007 stopped
`RenderRows` writing `nil` into the caller's hook tables; AbsorbTracker's `test_widgets.lua` carried
an assertion pinning exactly that mutation, and it went red on re-vendor. This is the mirror check
working as designed — the assertion was testing a library implementation detail rather than a
behaviour, which is why it broke. Retargeted to what matters: the caller's table survives, and a
second render pairs again.

**M8g — all eight library minors moved, for a comment-only sweep.** The en-US fix touches every
file, and the per-file discipline says a changed file bumps. That looks disproportionate and is not:
re-vendoring is whole-folder regardless, so the cost of bumping eight is zero, while the cost of
skipping one is a file whose next real change ships against a host that already has it.

**M10a — the standard contradicted the verified practice, and the contradiction was normative.**
`library-stack-§3` carried a standing MUST to "vendor only libs the addon actually `LibStub(\"X\")`
— vendor what you use, nothing more. Prune dead weight." Against a multi-module umbrella that
licenses exactly what anti-pattern #48 now forbids: an auditor sweeping for dead weight would delete
the unwired module files, and four of the five majors refuse to register without Core. Resolved by
separating the SHIP PAYLOAD (whole folder, always) from ADOPTION (per module, on the addon's own
schedule) — both halves had a real basis, which is why it had survived unnoticed.

**M10b — a rule was deleted with the code it sat beside, leaving its rationale orphaned.** The
rewrite removed options-ui's `C_Timer.After(0, ...)` body-deferral MUST along with the hand-rolled
snippet it accompanied. §9's long account of the misdiagnosed group-utility GameMenu taint survived
— so the section kept the story and lost the instruction, which is the exact failure mode the
"preserve the reasoning" rule exists to prevent, running in reverse. Restored.

**M10c — the verifier corrected the ground truth, not just the output.** The recon file the writers
worked from was generated before M8 and said Options performs no descriptor validation and defaults
`print` to a no-op. M8 changed both. The verifier checked the standard's claims against SOURCE rather
than against the recon, found the standard right and the recon stale, and said so. A verification
pass that only compares output to its own inputs cannot catch this class at all.

**M11a — the tooling would have false-flagged the reference addon.** `events-frames-taint` still
handed the author the `IsConcatSafe`/`SafeToString` implementation to write and named AbsorbTracker's
`core/Util.lua` as the reference — a file this extraction deleted. `AUDIT.md` says to walk every
section, so an auditor would have grepped for a locally-defined stringifier, not found one, and filed
a MUST deviation against the addon that defines compliance. Found by having the verifier EXECUTE the
audit against AbsorbTracker rather than read the audit's instructions.

**M11b — the new-addon context pack scaffolded an addon that errors at load.** It is dropped
verbatim into every new addon. `OnInitialize` called `NS.Settings:Register()`, which nothing in the
pack defines; the `OptionsSetup` snippet never published the three entry points the pack's own page
files and entry file then call; `core/Util.lua` was in the starter tree and TOC with no snippet
anywhere; `Namespace.lua` was listed twice. None of this is caught by any test in any repo, because
a documentation template has no suite — the next new addon was the test.

**M11c — a MUST that leaves no artifact is not auditable, and saying so is part of writing it.**
`testing-§12` requires mutation-verifying any case that asserts a negative. Mutation leaves nothing
behind, so an audit can neither confirm nor refute it and would have recorded a deviation against
every compliant addon forever. The section now states that absence is recorded as *unverified* rather
than as a deviation, and a SHOULD asks the case to name the mutation that reddens it — which is also
the cheapest way for the next author to re-run the check instead of re-deriving it.
