# Changelog

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans. Each
**file** separately carries a LibStub **MINOR** integer that increments on every released change to
that file — that is what LibStub compares when it picks a winner between vendored copies, and a
released change that forgets its bump silently does not reach any host that already has the old copy.

Every release therefore opens with a version block naming each file's live minor.
`tests/test_versioning.lua` enforces that the block and every major's `lib.MODULES` agree, so the two
cannot drift. Release order is in
[docs/releasing.md](docs/releasing.md).

## v1.7.0 — 2026-08-04

Versions in this release: **Core minor 4**, **DebugLog minor 7**, **Slash minor 6**,
**Options minor 6**, **OptionsWidgets minor 6**, **OptionsScroll minor 3**, **Perf minor 6**,
**PerfPanel minor 3**. `DebugLog.lua` and `PerfPanel.lua` are unchanged and do not move.

**testkit revision 6** carries two runner fixes, both found by this pass and both silent until it.
`Max CCN` was read from lizard's `!!!! Warnings` block, so it reported `0` for any addon that had
reached zero warnings — the exact moment the number matters most. And `RESULTS.md` rows never
appended in a CRLF repo: the guard matches the header as a substring while the awk that inserts the
row compares it exactly, so the guard passed, nothing was written, and the branch that warns was
never reached. Every consumer is CRLF-pinned, so every run in every addon dropped its row with no
message. Neither was caught earlier because LibKa0s is the only repo whose suite runs the kit
against itself, and it has no `RESULTS.md`. **Consumers must re-vendor and regenerate.**

A complexity pass across the whole collection found the same shapes hand-written in three, four and
six repos at once. Five of them earned promotion here — the test being *present in 2+ repos with the
same semantics, no per-addon escape hatches, a stable abstraction rather than a coincidence of
today's code*. Everything else in this release is internal restructuring: no chat string, event
registration, SavedVariables key or slash output changes, and every existing descriptor keeps
working untouched.

### `LibKa0s-Slash-1.0` gains the sub-command vocabulary — `SplitVerb`, `FindCommand`, `CommandRows`, `ParseBool`

Two hosts had already copied byte-identical `lowerFirst` / `findCommand` file-locals out of this
dispatcher, and both had then hand-rolled a *second* command-row format beside the library's own —
which is exactly the drift the shared formatter exists to end, one level down. All four are
lib-level and stateless, in the shape `FormatRow` / `FormatKV` already set:

- `lib.SplitVerb(rest)` — verb lowercased, remainder's case and internal spacing preserved. The
  asymmetry is the contract: a verb is an identifier, a remainder is user data, and AceDB profile
  names and schema paths are both case-sensitive.
- `lib.FindCommand(list, name)` — linear scan of the `{ name, description, handler }` array the
  `commands` descriptor field has always taken, so a sub level reuses this major's vocabulary
  rather than inventing one.
- `lib.CommandRows(prefix, commands, indent)` — the instance-local `rows(indent)` generalized.
  `Sl:HelpRows` and `Sl:LandingRows` are now one-liners over it, so every level renders through one
  formatter by construction.
- `lib.ParseBool(word)` — the eight-word set `lib.STRINGS.ERR_BOOL` already advertises, as a
  module-level constant table. `nil` means *not a boolean word*, never *false*, which is what lets
  a caller implement toggle-on-absent. Three copies existed, one of them already inside this file
  and unreachable.

The dispatcher itself is deliberately **not** promoted: its control flow is genuinely per-host
(bare `/kcd debug` toggles a window, `/cm priority <cat>` resolves a category between the two
levels), and owning it would cost four escape hatches to save six lines.

### `LibKa0s-Options-1.0` gains `O.BuildLandingPage` and `O.TextRow`

Three hosts each defined a function literally named `Helpers.BuildMainContent` rendering the same
page, with the same four constants at the same values and the same guard pairs; the only real
differences were the logo path and where the one-liner came from. Every primitive underneath it was
already in this major — `EnsureScroll`, `ClearScroll`, `AddSpacer`, `Section` — and `buildMain(ctx)`
was already the seam it hangs off, so the copies were host-side only because the *body* was.

- `O.TextRow(ctx, text, opts)` — a full-width Label, left-justified, added to the scroll. It owns
  the `if w.label and w.label.SetJustifyH` / `SetFontObject` guard pair **once**; that pair was
  written out 28 times across six repos, and every copy is a place for one half to be forgotten,
  which fails silently and only in game.
- `O.BuildLandingPage(ctx, spec)` — logo, one-liner, then a heading and its rows per section.
  `spec.notes` may be a function, called at render time, because a host reading its TOC Notes
  cannot resolve it at declaration; `spec.sections[i].rows` is a function for the same reason, so a
  re-render picks up a command added since registration.
- `lib.LAYOUT` gains `LANDING_LOGO` (300), `LANDING_GAP_LOGO` (8), `LANDING_GAP_DESC` (12) and
  `LANDING_GAP_HEAD` (6) — the four constants the three hosts had already agreed on.
  `LANDING_GAP_HEAD` must stay equal to `SECTION_BOTTOM_SPACER`, which `O.Section` already emits,
  so the page does not draw a second gap under every heading. `tests/test_options.lua` pins that.
- **The descriptor is unchanged.** A host reaches the landing page through the `buildMain(ctx)` it
  already had — `buildMain = function(ctx) O.BuildLandingPage(ctx, spec) end` — and a host wanting
  extra content below calls `O.BuildLandingPage` as line one of its own body. The shell deliberately
  does *not* sniff for a spec field and install a renderer on the host's behalf: that would change
  what `lib:New` **does** rather than add to what it offers, and it would make "what draws my main
  page?" unanswerable from the host's own source. `lib:New` answers exactly what it answered at
  minor 5.

### `LibKa0s-Core-1.0` gains `lib.RGBA`

Promoted mainly because **this library had two disagreeing copies**: `Slash.FormatValue` read both
storage shapes, `OptionsWidgets.decodeColor` read only the keyed one — so the library's own CLI
could render a color its own widget could not decode.

`lib.RGBA(c, dr, dg, db, da)` returns four numbers, never a table, from either the keyed
`{ r =, g =, b =, a = }` or the positional `{ r, g, b, a }` shape. Whichever shape wins, wins for
all four channels, so a `{ r = 1 }` cannot borrow its green from `c[2]`; each channel then falls
back independently, so a three-element color still gets its alpha. Absence is tested with `== nil`
rather than `or`, which is what makes a stored `false` survive — `0` was never at risk, since `0` is
truthy in Lua and `(0 or 99)` is `0`. The defaults are per-channel
parameters and are deliberately not defaulted — the call sites across the collection genuinely
disagree, and inventing a house default would silently recolor one of them.

**The library's own two call sites do not adopt it yet.** `Slash.lua` and `Options.lua` declare
`NEEDS_CORE = 1`, and `docs/releasing.md` treats raising that floor as a breaking change to the
*vendoring* — every consumer still carrying a stale `Core.lua` would lose the whole major. This is
the same reason `enumList` is duplicated verbatim between the two majors rather than hoisted. So
`lib.RGBA` ships for hosts now, and the library folds its own copies in only alongside a floor
raise made for other reasons.

### `LibKa0s-Perf-1.0` gains `P.Open` / `P.Close`

A measurement bracket for **multi-exit** functions, which is where the old ergonomics discouraged
instrumenting exactly the code that most needed it: one adopter's four-exit poll function needed
its own `if __t0 then P.Note(...) end` per exit, and its comment records that the instrumentation
was originally omitted for that reason — an omission that then cost 73.9 ms of unattributed time in
the first live capture.

`P.Open()` returns `debugprofilestop()` or `nil` when the probe is off; `P.Close(t0, key)` treats a
`nil` `t0` as a silent no-op, which collapses every exit to one unconditional statement. Not a
closure-returning `Bracket`: a per-bracket closure would allocate on a path whose entire contract
is costing nothing when disabled. `P.Note` is unchanged, so an existing host keeps working
untouched.

### Internal: every function in `LibKa0s/` is now under CCN 15

`Core.ApplySkin`, `Slash.FormatValue`, `Perf`'s report builder, `OptionsWidgets`' row renderer and
`OptionsScroll`'s gutter patch were each above the collection's complexity cap. They are now
module-level dispatch tables, named file-locals and small builders — `applyBackdrop` /
`ensureInnerBorder` / `applyInnerBorder` / `applyAccents`, `colorChannel`, `addFpsLines` /
`addBucketLines` / `addNestingNote` / `stepState` / `armStates`, `startRow` / `startGroup` /
`drawRow` / `endGroup` / `takeOnce` / `renderRowGuarded`, `thumbOf` / `stepButtons` /
`forceGutter`. Behavior is identical; the tables and the helpers are built once at file load, so
nothing on a hot path gained a per-call allocation.

## v1.6.3 — 2026-08-04

**No library file moved.** `testkit` revision **4 → 5**; `run-automated-tests.sh` only. Three changes
to `RESULTS.md`, all about what the trend table can be trusted to say.

### The table carries size and averages, not just totals

Run · Version · Lint w/e · **Files** · Tests · Perf · **NLOC** · **Funcs** · **Avg NLOC** ·
**Avg CCN** · Max CCN · CCN warn · Verdict.

An average without its total, or a total without its average, cannot be read across a change in
size — which is the one thing a trend line exists to do.

### A suite that was not selected renders as `—`, not as its zeroed counters

`--suite lint` previously wrote `0/0` into the Tests column, indistinguishable from a full run that
found no tests. The trend line would have carried that forever. `skip` (tool absent) and `—` (not
asked for) are different facts about *why* a number is missing, and both differ from zero.

### A changed column set no longer silently recreates the file

The runner appends by matching the header. When it does not match — an older column set — it now
warns and leaves the file alone, rather than starting a fresh table and dropping every previous row.
That is the one failure a trend line cannot survive, and it would have happened on the first run
after any future column change.

## v1.6.2 — 2026-08-04

**No library file moved.** `testkit` revision **3 → 4**; `run-automated-tests.sh` only.

### The manifest records all eight of `lizard`'s footer fields

```
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
      7532       6.5     1.7       45.9     1047            2      0.00    0.02
```

Revision 3 kept the totals and `AvgCCN` and dropped `Avg.NLOC`, `Avg.token`, `Fun Rt` and `nloc Rt`
on the floor, which meant a run's analysis could only ever report totals.

The averages are what make one run comparable to another **across a change in size**. A total that
rose because the addon grew is a different fact from an average that rose because it got denser, and
only the second is a complexity signal — so totals alone make a growing addon look like a degrading
one, every release, until nobody reads the row. `suites.complexity` now carries `nloc`, `functions`,
`avgNloc`, `avgCcn`, `maxCcn`, `avgToken`, `warnings`, `warnFunRatio`, `warnNlocRatio`, `bandFiles`
and `overCapFiles`, and the console line reports them too.

## v1.6.1 — 2026-08-04

**No library file moved.** `testkit` revision **2 → 3**; `run-automated-tests.sh` only.

Two fixes, both found by *using* revision 2 across the collection rather than by a test — which is
the argument for adopting a new kit widely and quickly rather than in one repo.

### Artifacts are written without ANSI escapes

`luacheck` and the harness colour their output when they believe a terminal is attached, and the raw
escapes were landing verbatim in `lint.txt` and `tests.txt`:

```
Checking core/Compat.lua    <0x1b>[0m<0x1b>[32m<0x1b>[1mOK<0x1b>[0m
```

Unreadable in an editor, and pure noise in a diff between two runs — which is most of what a stored
artifact is *for*. The parsers had always stripped colour for their own use; the stored evidence now
gets the same treatment (`strip_ansi` on every emitted artifact, plus `--no-color` where `luacheck`
supports it, probed once rather than assumed).

### Run directories are stamped in local time, `YYYYMMDD-HHMMSS`

Was `YYYY-MM-DD-HHMMSS` in UTC. A record is read by the person who ran it, usually minutes later, and
a folder name that disagrees with their clock costs a mental conversion on every glance. The manifest's
`startedAt` now carries an explicit UTC **offset** (`2026-08-04T17:03:11+05:30`) rather than a `Z`, so
the instant stays unambiguous once the record outlives the machine — local for reading, offset for
arithmetic.

"Local" is the *machine's* timezone: a host left on `Etc/UTC` stamps UTC and is behaving correctly.
A developer expecting their own wall clock sets the system timezone, not the runner.

## v1.6.0 — 2026-08-04

**Core minor 3**, **DebugLog minor 7**, **Slash minor 5**, **Options minor 5**,
**OptionsWidgets minor 5**, **OptionsScroll minor 2**, **Perf minor 5**, **PerfPanel minor 3**.
**No library file moved** — this release is entirely `testkit/`, whose revision goes **1 → 2**.

### `testkit` — the consolidated automated-test runner

`testkit/run-automated-tests.sh` is new, and it is the only executable in the kit. It runs the four
out-of-game suites — `luacheck`, the headless `tests/run.lua` harness, the offline `tests/perf.lua`
scenarios and `lizard` — and records every result as one frozen bundle under
`docs/automated-tests/<YYYYMMDD-HHMMSS>/`, then rolls the run into `docs/automated-tests/RESULTS.md`.
The normative rules for the artifact are the standard's (`automated-tests`); this is the tool that
produces it.

It lives in the kit rather than in each addon for the reason the rest of the kit does: it must be
byte-identical in nine places, and the vendoring gate already enforces exactly that.

Two properties are load-bearing and deliberate:

- **`lint` and `tests` gate; `perf` and `complexity` do not.** The latter two are measured, recorded
  and diffed, never used to fail the run. `performance-§9`/`§10` are explicit that a wall-clock or
  complexity threshold which fails a run teaches everyone to reach for `--no-verify`, after which
  the gate protects nothing and the habit remains. Folding them into a red/green battery would have
  quietly reversed both rules.
- **A missing tool is a skip, not a failure**, and the skip is recorded *with its reason*, so a
  green run that measured nothing cannot be mistaken for a green run that measured everything.

### The harness summary is parsed in both shapes it comes in

The collection ships two summary lines — `N passed, N failed, N total` and the older
`N passed, N failed`. Matching only the first recorded **0 passed, 0 failed, 0 total** for every
addon using the second, while the run still reported **green** off the harness's zero exit code. A
green run reporting zero tests is the precise failure this runner exists to make impossible, and it
was caught on the first adoption sweep rather than by a test, which is worth recording.

Both shapes now parse, and a zero-exit run whose count cannot be read is recorded as a **skip with
that reason**, never a pass: reporting green off an unparsed summary is worse than reporting a
failure, because it is believed.

### `*.sh text eol=lf` is now required, here and in every consumer

Everything in this collection is CRLF, pinned by `.gitattributes`. A `#!/usr/bin/env bash` line
followed by CRLF makes the kernel look for an interpreter literally named `bash\r`, and every
`case`/`in` becomes a syntax error — so a CRLF-pinned repo that ships a `.sh` must carve it out.
Without that line the vendored runner is broken on **every** checkout rather than in one
contributor's, and it fails identically for everyone, which is the kind of breakage that reads as
"the script is wrong" rather than "the checkout is wrong".

Re-vendoring also now ends with `chmod +x tests/_kit/run-automated-tests.sh`: `cp` does not reliably
carry the executable bit across filesystems.

### Kit revision 1 → 2

Nothing in the Lua surface changed. No suite, mock seam or assertion behaves differently, and a
consumer upgrading from revision 1 re-vendors the folder and gains one file. The revision moved
because the kit's **file set** moved, which is what the byte-identity gate compares — a consumer
still holding four files fails `test_vendor_sync.lua` on the set comparison before it ever reaches a
content diff. Full surface: [`docs/api/testkit/version-2-docs.md`](docs/api/testkit/version-2-docs.md).

## v1.5.0 — 2026-08-02

**Core minor 3**, **DebugLog minor 7**, **Slash minor 5**, **Options minor 5**,
**OptionsWidgets minor 5**, **OptionsScroll minor 2**, **Perf minor 5**, **PerfPanel minor 3**.
Only `DebugLog.lua` moved.

### `DebugLog` — the gated sink can no longer raise on a format it cannot fill

`D.Debug(tag, fmt, ...)` routes every vararg through `safeToString` and then hands the results to
`string.format`. That covers a `%s` slot, which is what the guard was written against — but a WoW
combat "secret" is a **number**, and a host logging one through a **numeric** slot
(`NS.Debug("Absorb", "total=%d", UnitGetTotalAbsorbs("player"))`) handed `"<secret>"` to `%d`, where
`string.format` raises exactly as the unguarded secret would have.

That put the raise back on precisely the path this sink exists to protect (debug-logging-§4): an
unguarded secret reaching a log line inside a repeating ticker kills the ticker, and the feature
stays dead until `/reload`. The pre-stringification made the common case safe and left the case the
guard was *for* no safer than before.

The format is now `pcall`'d, and on failure the line still **lands** — the format string verbatim,
then the stringified arguments, space-joined — because a dropped line is the other way to lose the
diagnostic. A satisfiable format renders byte-for-byte as it did at minor 6, so **no consumer's
output changes**: the only behaviour that moved is a path that previously threw.

Found by **WhatGroup**, the sixth adopter, whose hand-written console had guarded this since its
WG-22 and whose suite went red on the first load of the library's sink. `tests/test_debuglog.lua`
gains the case for the repair and a second one pinning that an ordinary format is *not* routed
through the fallback.

## v1.4.0 — 2026-08-02

**The shipped payload is byte-identical to v1.3.1.** No file in `LibKa0s/` changed, so no LibStub
minor moved: **Core minor 3**, **DebugLog minor 6**, **Slash minor 5**, **Options minor 5**,
**OptionsWidgets minor 5**, **OptionsScroll minor 2**, **Perf minor 5**, **PerfPanel minor 3** —
every one of them exactly where v1.3.1 left it. A consumer that re-vendors gains no library change.

What this release is for is the **test kit** and the **documentation**, and the kit is the part that
is not cosmetic: `testkit/` now carries a revision, so a consumer can be re-vendored against a
release rather than against whatever `master` happened to hold.

### `testkit` — the kit carries a revision (`Kit.VERSION = 1`)

The kit is still not a LibStub major: it registers nothing, no load order depends on it, and two
copies never negotiate — the vendoring gate is byte-identity, not version comparison. What it could
not do before is answer *which* kit a consumer holds, reachable only by diffing against this repo at
the right commit. `Kit.VERSION` at the top of `framework.lua`, reaching suites as `KIT_VERSION`
through `Kit.expose`, answers it and names the kit's API document.

One number for all three files, because they vendor as one folder and are never adopted separately —
the opposite of `LibKa0s/`, where a per-file minor exists precisely because a host may hold a
different vendored copy of each major.

Two gates come with it in `tests/test_kitsync.lua`: `Kit.VERSION` must be a positive integer that
reaches the exposed table, and the API document for the live revision must exist. That is the bargain
`tests/test_versioning.lua` already strikes for the library's minors — a bump cannot land without its
document.

**This is why the release exists at all.** prettychat pins its vendored kit to the LibKa0s tag its
README provenance line names, and asserts it file by file. Kit revision 1 was on `master` and in no
tag, so it could not be vendored into prettychat without that gate failing — correctly. Six other
consumers took the kit anyway, because none of them has an equivalent check, which left their
provenance lines naming a release their `tests/_kit/` no longer matched. Tagging this release is what
makes all seven honest again.

### `docs/api/` — the API reference is versioned by folder

Every public contract now lives in `docs/api/<Major>/version-<minors>-docs.md`, one document per
**shipped** version, frozen once that version stops being current. The version key is the file
minors joined in load order — exactly what `lib.MODULES` reports — so the number read from the game
names the file:

```
/dump LibStub("LibKa0s-Options-1.0").MODULES
--> { Options = 5, OptionsWidgets = 5, OptionsScroll = 2 }
--> docs/api/Options/version-5.5.2-docs.md
```

Thirteen documents, backfilled from source at each tag rather than from memory: Core 2–3, DebugLog
3–6, Slash 4–5, Options 3.3.2/4.4.2/5.5.2, Perf 5.3, and testkit 1. Every table carries a `Since`
column naming the minor a member arrived in. Minors below the v1.0.0 tuple are named in the index and
left undocumented — they existed only en route to the first tag and no consumer ever vendored one.

The reason it is folder-versioned rather than left to git: consumers re-vendor independently, so at
any moment two of them may be on different minors of the same major, and both need an answer to
"what does *my* copy do?".

`README.md` collapses from 792 lines to a map that points at `docs/api/` rather than restating it,
and `docs/releasing.md` gains **step 5** — write the new version's document, mark the old one
superseded — which renumbered tag to 7 and re-vendor to 8.

### Adoption

prettychat is **consumer #7**, taking Core, DebugLog, Slash and Options and declining Perf on the
clearest structural grounds in the collection (`LIBKA0S-12`). It is the first host to pass
`sep = ""`, and the first to use Slash minor 5's `format` hook on a row type the library can already
render. PanelMaster (#6) and LootHistory were recorded earlier in the same window. Only WhatGroup
remains a target.

prettychat also found a gap worth naming here: **a free-text `string` row cannot hold a value
containing a space.** `lib.ParseValue` splits the remainder on whitespace and `parseString` returns
the first token, so `/pc set <path> You receive loot: %s` stores `"You"` — silently, with only the
echo showing it. A descriptor `parse` is the sanctioned workaround and prettychat supplies one, but
this is the ordinary row the `dialogControl = "EditBox"` widget writes, not an exotic type.

### Internals

Ten Markdown files renormalised to the CRLF `.gitattributes` mandates, and four stale step
references in `docs/releasing.md` repointed after the step-5 insertion.

## v1.3.1 — 2026-08-02

Versions in this release: **DebugLog minor 6**. Every other file is unchanged.

### `LibKa0s-DebugLog-1.0` — `makeCloseButton` is documented as the wrong answer

No behaviour change. The field's documentation was written from the point of view of the two hosts
that asked for it and read as an invitation: *"for a host whose other windows close with a different
one"*. Both of them took it, passed their main window's 24×24 class-coloured ×, and shipped debug
consoles and copy windows that matched their own addon and no other — while the three hosts that
passed nothing wore Core's thin 18×18 ×.

That is the same root cause as v1.3.0's border split, one field along, and the same answer: the
**edge** is shared across every Ka0s window (`Core.SKIN`), but the **close control on a
library-drawn window is the library's**. The descriptor comment now says so, notes that the field
has no consumer, and narrows it to a close control that is genuinely *different in kind* rather than
merely the host's own. `standalone-windows` in the Ka0s WoW Addon Standard carries the normative
half.

A regression guard comes with it: a console built with no `makeCloseButton` must reach
`Core.MakeCloseButton` exactly twice — once for the console, once for the copy window. It spies on
the `core` table rather than on the returned button, because `lib.MakeCloseButton` forwards through
that table at call time, so a default that stopped being Core's would stop reaching the counter.

## v1.3.0 — 2026-08-02

One change, and it is a **look** change rather than an API one: the Ka0s window edge is now defined
in the library instead of in whichever host happened to draw it.

Versions in this release: **Core minor 3**, **DebugLog minor 5**. Every other file is unchanged.

### `LibKa0s-Core-1.0` — the window edge is the flat 1px Ka0s double border

`lib.SKIN` changes VALUES, which no release before this one has done. Read the note below before
taking it.

Five consoles side by side did not read as one suite of addons. BankLedger and LootHistory draw
every window with a flat 1px black edge, a 1px light-grey highlight synthesised just inside it, a
gold title and a grey divider under the title bar — and passed `applySkin` at DebugLog minor 4
specifically so their consoles would keep matching their own windows. AbsorbTracker, ConsumableMaster
and KickCD passed nothing and got this library's 12px `UI-Tooltip-Border` with a black divider and an
untinted title. The two groups looked like different addons, which is the one thing a shared skin
exists to prevent.

The definition moved to where the majority of the drawn surface already was:

```lua
lib.SKIN = {
  bgFile      = "Interface\\Buttons\\WHITE8x8",
  edgeFile    = "Interface\\Buttons\\WHITE8x8",   -- was UI-Tooltip-Border
  edgeSize    = 1,                                -- was 12
  insets      = { left = 1, right = 1, top = 1, bottom = 1 },   -- was 3
  bg          = { 0.06, 0.06, 0.08, 0.92 },       -- was 0.06, 0.06, 0.07, 0.95
  border      = { 0, 0, 0, 1 },                   -- unchanged
  innerBorder = { 0.24, 0.24, 0.27, 0.85 },       -- new
  divider     = { 0.24, 0.24, 0.27, 0.85 },       -- new
  title       = { 1.0, 0.82, 0.0 },               -- new
}
```

`lib.ApplySkin` grows to make the three calls a table could never describe — the inner-border child
frame (built once, re-tinted thereafter), the title tint and the divider tint — each guarded on both
the skin key and the frame member being present, so a copy window with no divider and a perf panel
with no divider are both fine, and a caller handing it a plain WoW backdrop table still gets a plain
backdrop rather than a raise.

It also takes an **optional second argument**, `ApplySkin(frame, skin)`, defaulting to `lib.SKIN`.
That is what lets DebugLog's descriptor `skin` override reach this one implementation instead of a
second copy of the same calls.

**This is not an additive change and it should not be read as one.** No field is removed or
repurposed and no signature breaks — but every host that passes no `applySkin` sees its debug console
and its perf panel change appearance on the next re-vendor. That is the intent, it is the standard's
call to make rather than the library's, and `standalone-windows` in the Ka0s WoW Addon Standard now
specifies these values normatively so the next addon inherits them without a decision. A host that
genuinely wants something else still has `applySkin` and the `skin` table.

### `LibKa0s-DebugLog-1.0` — one skin implementation, and a divider that is not hardcoded black

`defaultApplySkin` is now a one-line delegate to `core.ApplySkin(f, skin)`, so the console and the
copy window wear exactly what every other Ka0s window wears. The divider's creation-time colour comes
from the skin rather than from a hardcoded `SetColorTexture(0, 0, 0, 1)` — that literal was invisible
while the default border was also black, and became a visible mismatch the moment the border did not
have to be.


`ApplySkin` decides on the **type** of what a frame answered, never on its truthiness. A frame is a
table with a metatable and this library cannot assume what that metatable does with a key it has
never heard of — a consumer's test mock answers *every* key with a function, so `frame.innerBorder`
read back truthy, the build-once guard never fired, and the tint then indexed a function and raised.
That is the whole reason "run each existing consumer's suite" is a release step: it took fourteen of
that addon's cases down and nothing in this repo would have noticed.

`applySkin` and `makeCloseButton` are unchanged and still default to the library's own. What changed
is why a host would pass them: no longer to rescue itself from a default that did not match its
windows, but for chrome that differs in SHAPE rather than colour, or to keep a console tracking the
host's own re-skin seam.

## v1.2.0 — 2026-08-01

Four gaps, all found by adoption rather than by review. Two are the same shape — a host could
express what it needed everywhere except at one hook nobody had asked for. The third is different
and worse: two majors in this library disagreed about what one schema row IS. The fourth is worse
again: every host on the options module has been shipping a settings canvas half-wired to Blizzard,
and the half that was missing is the one the user clicks.

Versions in this release: **Core minor 2**, **DebugLog minor 4**, **Slash minor 5**,
**Options minor 5**, **OptionsWidgets minor 5**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

### `LibKa0s-DebugLog-1.0` — the host can own its window chrome

Two optional descriptor fields, `applySkin` and `makeCloseButton`, both defaulting to exactly what
minor 3 did. No existing consumer changes.

BankLedger and LootHistory draw every window with a flat 1px `WHITE8X8` double border, a synthesised
inner-border child frame, a gold title tint and a grey divider, and close them with a 24x24
class-coloured x. `Core.SKIN` is a 12px `UI-Tooltip-Border` and `Core.MakeCloseButton` is an 18x18
fixed-red x. Adopting the console meant either redesigning every window such a host owns, or
declining a module whose two formatters are already byte-identical to the host's own — a 357-line
deletion turned down over chrome.

The `skin` field that already existed cannot close the gap: it is a TABLE, so it reaches the three
backdrop calls and nothing else. An inner-border frame, a title tint and a divider tint are calls,
not fields. `applySkin` is therefore a function that owns the whole job, for the console and the copy
window alike, and it is handed the fully-built frame — `frame.title` and `frame.divider` are already
assigned, so a host's existing "tint whatever this window has" helper works unmodified. It runs at
the same point the library's own did, after the Hide and the Esc wiring, so a surprise inside a
host's skin still cannot strand a visible window nobody can close.

### The title-bar offsets are derived rather than hard-coded

Falls out of the above, and would have been a real defect without it. Copy | Clear | Close read right
to left with a six-pixel gap each, anchored by absolute offset (not chained) because a close-button
factory may answer nil. Minor 3 hard-coded `-30` and `-78`, which are correct only for an 18-wide
button — a host supplying a 24-wide one would have had Clear's right edge land exactly on that
button's left edge and the gap would have vanished.

The offsets now come from the button's measured width, falling back to Core's 18 when `GetWidth`
is not yet positive (a frame before its first layout pass, or a headless stub). For every existing
consumer the arithmetic yields `-30` and `-78` unchanged. The computed values are recorded on
`frame.titleBarOffsets`, for the same reason `frame.titleText` is recorded: an anchor cannot be read
back through the frame API, so that is the only handle a host's own test has on it.

### `LibKa0s-Slash-1.0` — a host can render a value type the library does not know

One optional descriptor field, `format`, defaulting to `lib.FormatValue`. No existing consumer
changes.

It closes an asymmetry rather than adding a feature. `parse` has been a descriptor field since
`-1.0`, so a host has always been able to teach this CLI to READ a value type the library does not
know — and had no way to teach it to WRITE one back. `lib.FormatValue` handles colour, number, bool
and empty string, then falls through to Core's `SafeToString`.

That fallback is the problem. `SafeToString` probes `table.concat`, which refuses a table, so a row
whose stored value is a SET renders as `<secret>` — the CLI telling a user that a plain settings
value is combat-protected. BankLedger stores its muted-store list exactly that way
(`type = "table"`, rendered `{BANK, GUILD_BANK}` or `(none)` by the code the library replaces), and
prettychat needs `|` doubled to `||` so a stored chat pattern renders literally. Neither is
expressible through `colorDecode`, which only fires on a colour row, or through `SetRowAnnotator`,
which appends a suffix after the closing `|r`.

The hook is handed the value **as stored** and takes precedence over `colorDecode`: a host
supplying both is saying it owns rendering, and decoding first would hand the hook something other
than what the host wrote.

### `LibKa0s-Options-1.0` — a numeric enum renders as a dropdown, not a slider

`O.RenderField` sent every `type = "number"` row to `makeSlider` without ever consulting `values`.
But `LibKa0s-Slash-1.0` has treated a number carrying a `values` list as a constrained **enum**
since `-1.0` — `parseNumber` refuses a value outside the list rather than clamping, and its comment
calls the shape *"a NUMERIC dropdown"* and warns that clamping *"lands BETWEEN two entries, and the
renderer then has no label for what is stored"*.

That renderer did not exist. So a host with such a row — BankLedger has two, a retention preset and
a quality threshold — got a CLI that validated an enum and a panel that drew a 0-to-1 slider over
it, because neither row declares `min`/`max`/`step`. Two majors, one row, two answers.

`RenderField` now routes a number row with a non-empty enum list to `makeDropdown`. `makeDropdown`
needed no change: it is type-agnostic and stores the numeric key unmodified.

**Inferred from `values`, not opted into with a `dialogControl`.** Slash infers, and an opt-in here
would leave the two majors still disagreeing for any row that declares `values` and nothing else —
which is the whole defect. The `enumList` duplication comment already states the requirement: *"The
two readers MUST agree — a CLI that accepts a value the dropdown cannot display is worse than either
being wrong alone."* The inference is safe in the failure direction: a `values` function that
answers empty falls through to `makeSlider`, which is exactly the old behaviour.

Additive for every existing consumer: no row in AbsorbTracker, KickCD or ConsumableMaster is a
number carrying `values`, so not one widget changes. The library's own fixture had no such row
either, which is structurally why the gap survived — every dropdown case in the suite was
`type = "string"`. It has one now.

### `LibKa0s-Options-1.0` — `CreatePanel` stamps the Blizzard canvas contract

Blizzard's Settings window calls three methods on a frame handed to
`RegisterCanvasLayout(Sub)category`: **`OnCommit`** when the user applies, **`OnDefault`** from the
window's own **footer** defaults control, and **`OnRefresh`** on re-show. This library declared none
of them.

So every host on it shipped a canvas whose footer Defaults control did nothing — and all three
consumers did exactly that, without noticing, because the header Defaults button this library *does*
build kept working and looks equivalent to the user. Two controls that appear to do the same thing,
one of them dead, is worse than never having offered the second.

`CreatePanel` now stamps all three. `OnCommit` and `OnRefresh` are inert **by design** rather than by
omission: a host's writes land immediately through its own single write seam (options-ui-§41), so
there is no staged state to apply, and `SetRenderer` already owns re-show, so a second refresh path
would race the renderer it duplicates.

**`OnDefault` is a forwarder, not an assignment**, and the ordering is the whole reason. Every host
parks its click handler on the panel *after* `CreatePanel` returns — the Defaults button does not
exist yet, since `EnsureDefaultsButton` builds it on first OnShow — so
`panel.OnDefault = panel.defaultsOnClick` inside `CreatePanel` would capture `nil` forever while
looking perfectly correct. Resolving through the panel at call time also keeps the footer control and
the header button ONE implementation, which is what matters, rather than two that can drift. A page
with no defaults action gets a callable no-op — the point, since the footer control is not per-page
and can be clicked while a landing page is open.

Additive: no consumer set any of the three, so nothing is overwritten. It is not, however,
invisible — **three shipped addons gain a working footer Defaults control** from the re-vendor. That
is the fix, and it is a user-visible behaviour change rather than a silent repair.

Bumping the shell's MINOR makes `OptionsWidgets.lua` and `OptionsScroll.lua` re-attach on load,
because both guard on `__…ShellMinor == lib.MINOR`. That is the designed behaviour — a replaced
shell must be re-bound — and neither file's own minor moves.

## v1.1.1 — 2026-08-01

A payload release. **No code changed and no file minor moved** — every module is byte-for-byte what
v1.1.0 shipped, so a host that re-vendors gains one file and changes no behaviour.

Versions in this release: **Core minor 2**, **DebugLog minor 3**, **Slash minor 4**,
**Options minor 4**, **OptionsWidgets minor 4**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

### `LICENSE` ships inside the library folder

The vendored copy in every consumer held nine `.lua`/`.xml` files and nothing else — no licence, no
copyright header on any file, and no adopter's README naming the library at all. Each one was
publishing an addon zip containing MIT-licensed code with no indication it was there or what it was
under.

`LICENSE` is now part of the ship folder rather than repo furniture, so `cp -r LibKa0s/. <Addon>/libs/LibKa0s/`
carries it with no per-addon step and the `diff -r` gate keeps its shape. That is the whole change.

The reason it is its own version rather than a quiet amend: v1.1.0 is tagged and published, so the
tag cannot move, and three consumers now carry a payload that is v1.1.0 **plus one file**. A number
that names it is cheaper than a footnote explaining it.

Per-file copyright headers were considered and deliberately declined — they would touch all eight
files and bump all eight minors, which is a real release for a change that alters no behaviour.

## v1.1.0 — 2026-08-01

Three gaps found by adoption rather than by review, all of them things a host had worked around
in its own setup file first.

Versions in this release: **Core minor 2**, **DebugLog minor 3**, **Slash minor 4**,
**Options minor 4**, **OptionsWidgets minor 4**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

### A raising row costs that row — `OptionsWidgets.lua`

`RenderRows` pcalls each row. Options minor 3 guarded each page BUILDER; this is the more common
failure and the one a host cannot pre-empt — one corrupt saved value, or a `values` function that
raises because the media library it queries is half-loaded. Unguarded, it propagated out of
AceGUI's layout pass, every row after it never drew, and the user saw a panel that stopped
mid-way with nothing naming the row. `docs/releasing.md` carried this as a known gap; it is closed.

### `RenderGrid` — the caller-driven sibling of `RenderRows`

`RenderRows` is schema-driven: it walks declared rows, emits a `Section` when `group` changes, and
pairs them automatically. `RenderGrid(ctx, items)` is the other half — the caller decides what goes
in each cell and in what order, and a cell may be a schema row or `{ make = fn }` for a bespoke
widget. `wide = true` breaks an item onto its own full-width row.

That distinction is what a host needs for a list whose LENGTH is not in the schema: one checkbox
per macro, per unit, per spell. Every host had a hand-rolled copy of this loop, which is the
duplication this library exists to end — ConsumableMaster's `Helpers.Grid` was the third. Items are
guarded individually, like rows.

### `LSMValues` never hands back an empty list — `Options.lua`

An empty list made the row unusable rather than merely unpopulated: a dropdown with no options
cannot be opened, and the CLI's allowed-values check refuses every value, including the one already
stored. A media row whose library has not loaded yet now offers a single `None` placeholder, which
is what the one host that had noticed was already doing in its own wrapper.

`None` is a literal rather than a locale key, deliberately: it is also the STORED value, so a
translated one would be written into the host's SavedVariables.

## v1.0.0 — 2026-08-01

The first tagged release. Five majors — Core, DebugLog, Slash, Options and Perf — vendored into
AbsorbTracker, KickCD and ConsumableMaster. The file minors below are what LibStub actually
compares; the tag is the courtesy number for humans.

Versions in this release: **Core minor 2**, **DebugLog minor 3**, **Slash minor 4**,
**Options minor 3**, **OptionsWidgets minor 3**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

Grouped by major, newest first. A file's entries live under the major that owns it, so "what changed
in Perf" is one heading rather than a hunt.

### The page registry grew a renderer seam, a guard and a second tier — `Options.lua`

Three regressions a host could not work around, all of which ConsumableMaster's adoption declined
the whole registry over.

**One raising page builder no longer costs every page after it.** `CreateOptionsPanel` ran the
builders in a bare loop, so a single failure left a half-registered options tree with nothing
naming which page did it. Each builder is pcall'd separately now and reports its key; `O.__pages()`
is what actually built. A page registered *after* the build is built immediately rather than queued
behind a drain that has already happened — queued, it silently never appeared.

**A panel opened during combat refuses.** `O.SetRenderer(ctx, fn)` declares how a page draws
itself, and the library owns *when*: first show, and again after a refresh marked it dirty while it
was hidden. It also builds the Defaults button there (the AceGUI skinning reason, unchanged) and
closes the Settings window with the canonical grey notice under lockdown. That last one matters
because the Blizzard AddOns sidebar reaches a panel **without** going through `OpenOptionsPanel` —
so the one guard that existed was bypassed on exactly the path a user is most likely to take
mid-fight. A raising renderer is reported rather than propagated: inside AceGUI's own dispatch it
would take the click handling of every widget on the frame with it.

**Refreshing is two things, and they now have two names.** `RefreshAllPanels` is STRUCTURAL — it
re-runs the page's renderer, so rows that appeared or disappeared are drawn. `RefreshScalars` is IN
PLACE — refreshers only, no rebuild — and it is what every widget maker's own `set()` calls, since
writing a value does not change which rows exist. A page that is not on screen is flagged dirty and
re-renders on its next show instead of being rebuilt fifteen times per keystroke.

`RefreshAllPanels` keeps its name and gains the renderer, which is the one thing here that changes
meaning for an existing host. The migration is opt-in and costs nothing: a ctx that never went
through `SetRenderer` has no renderer to re-run, so both tiers fall back to running its refreshers
ungated, exactly as before. A host adopts the registry one page at a time, or never.

### Alpha, tooltips and live sliders — `OptionsWidgets.lua`

`hasAlpha` defaults to **true** now. This is a flipped default, and the only one in this release.
The old `row.hasAlpha and true or false` made a declared `false` indistinguishable from an absent
field, so no host could express "no alpha" even deliberately — while the colour codec beside it
models alpha as a first-class component of every colour it stores (`a or 1` on write, `c.a or 1` on
read). Suppressing the slider by default contradicted the codec: a stored alpha the user could
never reach. A host that wants the old behaviour writes `hasAlpha = false`, which it can say for
the first time.

The old default was entirely uncovered — the only assertion read a fixture row that declared
`hasAlpha = true`, so nothing anywhere pinned the false. The fixture now carries a row declaring
neither (that is the one proving the default) and a second declaring `false`, because a default
nothing asserts is a default nothing protects.

A tooltip body reads `row.tooltip` first and falls back to `row.desc`. Every Ka0s host's schema
declares `tooltip`; this library invented `desc`. Reading only `desc` therefore blanked the body on
every widget of any host on the standard's own shape — the label still renders, so it fails
silently and only in game. Both names are accepted; nothing has to move.

Sliders can commit on the drag. `sliderCommit = "change"` on the descriptor, or `commitOn` on a
single row, adds a throttled `OnValueChanged` write alongside the `OnMouseUp` one; the default
stays release-only and an unchanged host is untouched. It exists because a page whose number rows
drive something visible while dragging — a bar's width, a button's scale — has no preview without
it, and there was no hook to ask for one. The drag reuses the colour picker's re-armed single timer
rather than the per-frame write a host would write by hand: a 60 Hz drag otherwise fans a refresh
pass out across every registered panel sixty times a second. Live commits snap to the row's step
exactly as the release commit does, or the release would silently correct what the drag stored.

`SetIsPercent` reads `row.isPercent` instead of being hardcoded false, which is the whole reason
that field exists in the schema.

### Colours: the positional shape renders, and hosts get a codec — `Slash.lua`

`lib.FormatValue` reads both stored colour shapes now. The named keys win when present, so a host
storing `{ r =, g =, b =, a = }` renders exactly as before; a host storing `{ r, g, b, a }`
POSITIONALLY used to render every colour as `{0.00, 0.00, 0.00, 1.00}`.

That is the shape the Ka0s options colour widget itself writes — this library's own
`OptionsWidgets.lua` documents the divergence and takes a codec for it, while `Slash.lua` had no
hook at all: `kv()` called the lib-level formatter directly, so a host could not even override it.
Two majors, one collection, opposite assumptions about the same stored value. It shipped green
because nothing outside the Slash suite asserts a rendered colour's VALUE.

`colorDecode` / `colorEncode` join the Slash descriptor under the same names the Options descriptor
already uses, so a host passes one pair to both majors. `CliSet` encodes into the host's shape
before writing, and both echo sites — `CliSet`'s and `CliReset`'s — read back through it.

### Enum rows: the ordered-array shape is read now — `Slash.lua`, `OptionsWidgets.lua`

Both enum readers accept the Ka0s options schema's own shape — an **ordered array** of
`{ value =, text = }` — alongside AceGUI's key map. The array's position is its order, so a row
declared `{ {value="RIGHT"}, {value="LEFT"} }` offers Right then Left in the dropdown and lists
`RIGHT, LEFT` in the CLI's allowed values.

It has never worked. `allowedValues` iterated `pairs(row.values)` and returned the sorted
`tostring`'d KEYS, and the dropdown handed the raw table to `SetList` — so a standard-shaped row
offered `1, 2` as its allowed values and mapped index to table. Every Ka0s addon declares enums
this way, which is why the options row makers and the schema CLI were both declined during
ConsumableMaster's adoption: one defect, two majors, ~250 lines that could not move.

`enumList` is duplicated **verbatim** in both files rather than hoisted into `Core.lua`. Hoisting
would raise `NEEDS_CORE` in two majors, which `docs/releasing.md` calls a breaking change to the
vendoring — every consumer carrying a stale `Core.lua` would lose both majors outright. The two
copies must agree or the CLI accepts a value the dropdown cannot display, so a cross-major parity
case renders each fixture enum and asserts the CLI accepts every option the dropdown offers, in
both shapes. That is the guarantee the duplication buys.

Three shapes were actually in play, not two. `{ SHORT = true }` — a key *set* — is what both
fixtures and several host rows declare, and its labels rendered as the literal string `"true"` in a
real client. Nothing caught it because the AceGUI mock records the list without reading its text.
A set now labels each entry with its key, which is the only honest label it has.

Two behaviour changes fall out, both deliberate:

- A `type = "number"` row **carrying a values list** now rejects an out-of-list value instead of
  clamping it. Clamping lands between two entries, and the renderer then has no label for what is
  stored — the row reads blank and the user cannot tell what they set. A number row *without* a
  list clamps exactly as before.
- A `type = "string"` row **without** a values list now accepts free text. The old reader walked an
  empty allowed-list and therefore refused every value, so `dialogControl = "EditBox"` rows shipped
  un-settable from the CLI.

### `interface` was always 0 — `Perf.lua`

A record's `interface` field is read from `GetBuildInfo()`'s fourth return now, not from
`GetAddOnMetadata(name, "Interface")`.

Blizzard does not serve `Interface` through the addon-metadata API — it serves `Title`, `Notes`,
`Author`, `Version` and `X-*` — so the old lookup answered nil and **every record ever emitted
stamped `"interface":0`**, making an archived capture unattributable to a game build. Confirmed
against a live 12.0.7 client: `C_AddOns.GetAddOnMetadata("KickCD", "Interface")` returns nothing.

This repo had a case pinning the field at `120007`, and it passed throughout — because
`tests/wow_mock.lua` stubbed `GetAddOnMetadata` to return `"120007"` for **any field asked of it**.
A stub that silently succeeds is worse than no stub (kit fidelity rule 1), and this is what that
rule costs when it is broken: the one case written to catch this exact failure could only ever pass.
The mock now answers only the fields Blizzard actually serves, and supplies `GetBuildInfo`.

The semantics shift slightly and for the better: the field is the **client's** interface version
rather than the host's TOC line. For a current addon they agree; when they disagree the client's is
the one that explains the capture.

### The `L` trap — `DebugLog.lua`, `Slash.lua`, `Perf.lua`

An `L` override is now resolved with `rawget` rather than a plain index, in all three modules that
take one.

Every Ka0s host's locale table carries a metatable fallback that answers an unknown key **with the
key** — the standard mandates it (anti-patterns #2). A plain index therefore accepted that
synthesised string for *every* key, so a host that passed its addon-wide locale table made these
modules' own `STRINGS` unreachable and rendered raw keys in place of English. It fails for every
string at once, cannot fail in a headless case that only checks a label is non-empty, and is visible
only in game.

It shipped: KickCD's perf panel rendered `Ka0s KickCDPANEL_TITLE_SUFFIX` and seven `STEP_*` keys.
AbsorbTracker was unaffected because it passes no `L` at all.

`rawget` asks the only question that matters — did the host actually put a value here? A genuine
entry still overrides; a fallback-only table correctly falls through. **Additive and
behaviour-preserving for every existing consumer**: a real entry is `rawget`-visible, so no host that
was working changes.

`PerfPanel.lua` does NOT bump: it receives `tr` as a parameter from `Perf.lua`, so the fix reaches
the step panel without the file changing.

The README's per-module descriptor tables previously said *"hosts on the Ka0s standard pass their
`NS.L`"*, which was precisely the advice that caused this. Corrected, and a **The `L` trap** section
added to the README and to `docs/adoption-prompt.md` with the one-line assertion that catches it:
a rendered label must not match `^[A-Z][A-Z0-9_]+$`.

### Review fixes — all five majors

Found by the `/wow-addon:review` gate on this branch and fixed before it merged. Every file's
minor moves, because every file changed: the en-US sweep below is comment-only but touches all
eight, and whole-folder re-vendoring is mandatory anyway.

- **`Options.lua`** — `EnsureDefaultsButton` reached `O.AttachTooltip` without the guard its own
  closing comment claimed, so a vendored copy missing `OptionsWidgets.lua` raised from the
  library's shell on the first panel `OnShow` rather than degrading. Guarded, like the sibling
  reach into `PatchAlwaysShowScrollbar` already was.
- **`Options.lua`** — the default `print` was a silent no-op alone among the five majors, so a
  host that omitted it got a combat refusal and a missing-AceGUI notice that vanished with nothing
  to grep for. It now falls back to `DEFAULT_CHAT_FRAME`, matching Core, DebugLog and Slash. The
  library still cannot supply the host's tag, so the descriptor's `print` remains the intended path.
- **`Options.lua`** — `:New` now raises on a missing `mainPanelName`. It is the one field whose
  entire purpose is lost silently: a nil yields an anonymous canvas that `/framestack` cannot
  attribute, with nothing visible in game. The other fields' documented no-validation gap stands.
- **`Options.lua`** — `CreateOptionsPanel` is idempotent. A second call registered a duplicate
  Blizzard category and appended a second ctx per page, permanently doubling the `RefreshAllPanels`
  fan-out.
- **`OptionsWidgets.lua`** — `RenderRows` implemented both one-shot hooks by writing `nil` into
  the tables the CALLER owns, so a host that hoisted its `afterGroup`/`pairWith` to a file-level
  constant silently lost every inline button and paired widget on the second render — which a
  per-unit page does on every unit switch. The bookkeeping is now the library's. One-shot semantics
  per call are unchanged.
- **`Slash.lua`** — `FormatValue` fed three of its branches to `string.format` unguarded, and a
  WoW secret raises there exactly as it does in `table.concat`. The invariant that made this safe
  — a stored settings value is never a combat-protected one — was real but written down nowhere
  and enforced nowhere. Guarded at the input, so every ordinary rendered value is byte-identical.
- **`DebugLog.lua`** — `lib.MakeCloseButton` snapshotted Core's function VALUE at file load.
  LibStub upgrades a major in place, so a newer `Core.lua` over an unchanged `DebugLog.lua` left
  the console drawing the old button while `MODULES.Core` truthfully reported the new minor. Now a
  forwarder through the `core` table, the shape `PerfPanel.lua` already used.
- **`DebugLog.lua`** — `D:Add` did not route its message through the secret-safe stringifier,
  though the gated sink and `initSummary` both did. It is public, ungated by design, and the path a
  host's perf output takes.
- **All eight files, and `testkit/mock_base.lua`** — en-US spelling in comments, per the standard.
  Comments only; no string literal moved.

`tests/test_kitsync.lua` is new and closes the gap that let the previous commit ship a
`testkit/README.md` that was never re-vendored: `testkit/` and `tests/_kit/` are now compared
byte for byte, README included, with no line-ending normalisation, and the failure names the file.
It caught a real divergence during this very change.

### `LibKa0s-Options-1.0`

- New module `LibStub("LibKa0s-Options-1.0")` — the Blizzard settings-canvas shell, the schema-row
  to AceGUI translation and the two-column flow engine, in three files under one major
  (`Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua`). `lib:New{ parentTitle, get, set,
  applyDefault, rowsForPage, allRows, … }` returns an instance owning its own panel registry, so
  one addon's Defaults button can never run another's refreshers. The basenames are namespaced
  because the changelog check below plain-searches one file for `<Basename> minor <N>`, and
  `Widgets.lua`/`Panel.lua` are exactly what a future window module would want.
- Five widget types ship in `-1.0`, not four: the edit box (`dialogControl = "EditBox"`) is here
  because adding a type later is additive but retrofitting one into a frozen dispatch table is not.
  No AbsorbTracker row uses it; KickCD's label rows do.
- Colour storage is a descriptor codec rather than a baked-in shape, because AbsorbTracker stores
  `{r=,g=,b=,a=}` and KickCD stores arrays, and picking a winner would force one of them to
  translate at every read site in the addon. The 50 ms colour-drag throttle likewise takes the
  host's `scheduleTimer`: embedding AceTimer would be this library's second dependency breach.
- `OpenOptionsPanel` REFUSES under combat and never defers-and-replays, and the gate lives inside
  the open rather than in a host's dispatcher, so a `/run` script is refused too.
- The always-shown scrollbar marker is `_ka0sAlwaysScrollbar`. AceGUI pools ScrollFrames across
  every addon in a session, so per-addon marker names would let two addons each patch a widget the
  other had already patched.

### `LibKa0s-Slash-1.0`

- New module `LibStub("LibKa0s-Slash-1.0")` — the slash dispatcher, the help renderer, the schema
  CLI (`list`/`get`/`set`/`reset`/`resetall`/`version`) and the type-aware value parser. The parser
  is the reason this shape won rather than the coercing one the other copies carry: a number clamps
  to its row's range instead of storing a value the panel cannot honour, a string outside its enum
  is refused with the allowed values listed, and a colour parses `r g b [a]` instead of printing a
  table address. `SetRowAnnotator` lets a host append a note at the three sites that render a
  setting — list, get and set — and at no others.
- The COMMANDS table stays the host's and is passed into the descriptor. A host renders the same
  table on its own About page, so a library owning it would force the options module to consume
  this one — and two libraries reaching for each other is a real dependency cycle.

### `LibKa0s-DebugLog-1.0`

- New module `LibStub("LibKa0s-DebugLog-1.0")` — the on-screen debug console, which was the most
  duplicated thing in the collection: seven hand-transcribed copies of a window the standard already
  specifies down to the hex codes. `lib:New{ name, title, font, isEnabled, setEnabled, … }` returns
  an instance owning its own buffer and its own frames, with every frame global derived from `name`
  so two addons cannot collide on `UISpecialFrames`. The enable flag stays the host's: the library
  reads and writes it through the `isEnabled`/`setEnabled` pair rather than keeping a second copy
  that its slash command and its settings panel would disagree with. `initSummary` makes the
  `[Init]` line a host callback, which is what five of the sister addons already do.
- The buffer cap is now covered: no addon suite ever wrote 501 lines, so the eviction path had never
  run under test.

### `LibKa0s-Core-1.0`

- New module `LibStub("LibKa0s-Core-1.0")` — the two seams every other module sits on. The
  secret-safe seam (`IsConcatSafe`, `SafeToString`, `SECRET`) carries AbsorbTracker's canonical
  `table.concat` probe, the only detector that fails on what a real combat-protected value actually
  fails on; the window chrome seam (`SKIN`, `ApplySkin`, `MakeCloseButton`) holds the backdrop and
  the close × a host's windows share. `lib:New{ prefix, sep, sink }` returns the prefixed,
  secret-safe chat printer, with `prefix` re-read on every call so a host whose tag constant loads
  later can pass a function instead of capturing nil forever.

### `LibKa0s-Perf-1.0`

- **Fixed:** a combat-protected value logged by a perf run rendered as its raw self, then raised
  inside the host's `table.concat(buffer, "\n")` when the user pressed Copy — killing the Copy
  button for the rest of the session. `Perf minor 2` deletes the private stringifier that caused it
  (it branched on `type()`, and a secret *is* a string or a number) in favour of
  `Core.SafeToString`. Perf now declares a minimum Core and refuses to register below it, so a
  missing Core makes the probe absent — which a host's setup stub reports honestly — rather than
  present and nil-erroring mid-run.
- `PerfPanel minor 2` takes its backdrop from `Core.SKIN` instead of a private lookalike, and draws
  Core's close button when the host supplies no `decorate`. `decorate` itself is unchanged and still
  takes precedence; the contract is additive-only.
- Initial extraction from AbsorbTracker (issue
  [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17)) — the probe, the record schema, the
  guided run, and the step panel, as `LibStub("LibKa0s-Perf-1.0")`.
- Still minor 1: the whole-branch review's fixes fold into the initial extraction rather than
  following it, since nothing has been released yet. A panel now re-attaches whenever the probe
  beneath it came from a different vendored copy; `:New()` reads `lib` rather than `self` throughout,
  so a LibStub minor upgrade cannot leave an instance reporting one schema while emitting another;
  `descriptor.buckets` entries are validated; `ring` is clamped to at least one record; panel labels
  re-resolve on every repaint; and a panel click prints exactly what typing the same command prints.
- `lib.MODULES` publishes the live minor of every file in the major, so version skew across vendored
  copies is answerable from in-game rather than by reading source.

### Documentation

- Documentation: the descriptor contract, the `suspend`/`resume` host contract, the public surface,
  and the record schema (v2) are written up in `README.md` and `docs/record-schema.md` (issue
  [#4](https://github.com/tusharsaxena/LibKa0s/issues/4)).
