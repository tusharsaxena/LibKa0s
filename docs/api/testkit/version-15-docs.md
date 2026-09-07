# `testkit` — version 15

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **15** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.27.0 |
| Status | **Current** |
| Supersedes | [version 14](version-14-docs.md) — `stubFrame` tracks a real enabled state |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `15` |

## What changed at this version

Three files change and one is new. `run-automated-tests.sh` rewrites the **record**, `mock_base.lua`
grows a geometry surface that **answers nothing until a test asks it to**, `framework.lua` grows a
second calling form for `Kit.assertSurfaceParity` that names the live surface instead of building it
and learns to load a suite that ships in the kit, and **`test_eol.lua` is the first suite the kit
itself carries**. `loader.lua` and `vendor_sync.lua` are untouched. Every assertion, every loader
behaviour and every existing mock answer is exactly what version 14 shipped — including `GetHeight`,
which still returns 0 for every frame nobody armed, and including `assertSurfaceParity`'s original
four-argument form, which is unchanged down to its message text.

**This is the one revision so far whose adoption moves a consumer's case count**, by exactly one, in
each of the nine — because a suite arrives that the repo did not have. Say so in the same commit
that re-vendors: `docs/test-cases.md` and the README `[tests]` badge move with it.

What moves in the record, in five places.

| | Was | Is at 15 |
|---|---|---|
| The skipped count | Dropped. The summary regex could not span `, N skipped`, so the total read empty and fell back to `passed + failed` | Read by label, reported in the console line, in the manifest as `suites.tests.skipped`, and in the table's **Tests** cell |
| The **Tests** cell | `passed/total` | `passed/skipped/total`, under the same column name |
| The **Version** cell on a release run | `$ADDON_VERSION` — the version being *replaced* | `version → release` when the manifest carries a `release` |
| The lead-in | Written only when `RESULTS.md` was absent or its header mismatched, so no existing repository could ever receive a correction to it | Regenerated on every run |
| The complexity watch list and the four standing sections | Never written by the runner at all | Generated from this run's own `lizard` output and its manifest |

### Why: a skipped case was reading as a case that did not exist

`framework.lua` has printed `N passed, N failed, N skipped, N total` since the skip status was added
at kit 8. The runner's regex was
`'[0-9]+ passed, [0-9]+ failed(, [0-9]+ total)?'`, which cannot span `, N skipped` — so the match
stopped at `failed`, `awk '{print $5}'` read past the end of it, `TESTS_TOTAL` came back empty and
fell back to `passed + failed`. A suite with three declared skips recorded as a suite three cases
smaller, on every row of every consumer's trend line, and the manifest had no `skipped` key to
contradict it with.

The figures are now read **by their labels** rather than by field position. That is the actual fix:
the summary has grown a column twice, and both times a positional read broke silently on the way
past — `$5` meant "total" before the skip column existed and means "skipped" after it.

```json
"tests": { "status": "pass", "passed": 773, "failed": 0, "skipped": 0, "total": 773, ... }
```

`suites.tests.skipped` is additive. Nothing reads it as a gate: `automated-tests-§3`'s release gate
evaluates `status` and `failed`, and a skip is **NOT EVALUATED** there rather than passed.

### Why: a release run was filed against the version it replaced

`--release X.Y.Z` is produced **before** the tag (`automated-tests-§6`), so the `.toc` still carries
the outgoing version while the run is the incoming one's evidence. Rendering `$ADDON_VERSION` alone
attributed each release's numbers to its predecessor: this repo's own `RESULTS.md` carries a row
reading `Version 1.24.0` whose manifest says `"release": "1.25.0"`. The cell now reads
`1.24.0 → 1.25.0`, which is both facts and no guess.

### Why: the corrected lead-in could not reach a single repository

The runner had two write paths. An `awk` that inserted one row beneath the header, and a
create-the-file branch that carried the header, the lead-in and everything else. The second was
reached only when `RESULTS.md` was **absent** or its column set had changed — which, in a repository
that has ever run this script, is never. So the four-checkpoint lead-in, written to replace a
two-sentence version that reads as *"perf and complexity gate nothing"* (false at the release gate),
sat in unreachable code while ten repositories carried the text it was meant to replace.

At 15 the file is **regenerated whole on every run**, rows preserved in order and the new row
prepended. Generated prose can then move with the script that generates it, which is the point of
generating it.

The one guard that stays is the one that matters: a `RESULTS.md` whose **header** is not the current
column set is still left completely alone, with a warning. Rewriting it would drop every previous
row, and that is the one thing a trend line must never do.

### Why: the watch list and the standing sections had no producer

`automated-tests-§4` **MUST**s a complexity watch list — two tables, warned functions and files by
`layout-§1` band — and a short standing section for each of the four suites. `documentation-§3`
calls `RESULTS.md` generated and never hand-edited. Until this revision the runner wrote one table
row and a fixed lead-in and **nothing else**, so both rules could not be honoured by anybody: the
mandated narrative had no generator, and hand-writing it violated the other rule.

The state on the far side of that collision was not a badly-graded file. It was no file: the record
went stale in ten of ten repositories. `MultiMeters/docs/automated-tests/RESULTS.md` headed a
hand-written watch list *"Current as of `20260809-195454`"* and reported **"None — `lizard` reports 0
warnings"** directly above a table row recording **19**; this repository's own test-suite section
opened with **"499 cases"** against a suite running 764.

The standard settled it at v2.39.0 (`automated-tests-§4`, *the one boundary*) and this is the code
half. Everything below the table is now the runner's, generated from the run that measured it.

### Why: four repositories filed a case none of them could write

`mock_base.lua` answered `GetHeight()` with 0 for every frame and defined no `SetAtlas` at all.
`OptionsWidgets.lua` measures the tab strip's row pitch off the **unselected** tab art — it asks a
probe texture to take an atlas at the art's own size and reads the height back — so under that stub
the measurement always came back 0, always took the `L.TAB_H` fallback, and every `options-ui-§13`
geometry-invariance assertion passed **vacuously**. AbsorbTracker, MultiMeters, PanelMaster and
PrettyChat each filed the missing case; not one of them could write it, because the fidelity it needs
lives in the kit and nowhere else.

Three members answer it, and all three are additive:

| Member | What it does |
|---|---|
| `f:SetAtlas(name, useAtlasSize)` | Records `f.__atlas` always, and — when `useAtlasSize` is given, the same argument that makes a real texture take the art's dimensions — records the size the kit publishes for that atlas |
| `f:__setGeom(w, h)` | **The opt-in.** Records a size *and* arms the frame, so `GetHeight`/`GetWidth` answer. Called with no arguments it arms and lets production dress the frame |
| `mock.__atlasSizes` | The published fixture `SetAtlas` reads, reachable from a consumer's finished mock |

**The arming is the whole design, and it was arrived at the hard way.** The obvious shape — have
`SetAtlas` write geometry and `GetHeight` answer it — was written first, and three of this repo's own
widget cases went red immediately: `tabArtHeight()` began measuring 28 where it had always fallen
back to 37, and the strip re-wrapped underneath cases that had never mentioned geometry. Production
calls `SetAtlas` on a probe texture no test holds a handle to, so a `SetAtlas` that armed geometry on
its own is the kit-16 flip arriving by accident, a revision early, in ten repositories at once. The
opt-in therefore belongs to the **test**, never to the code under test.

**The atlas figures are a fixture, not a measurement.** Nothing in `__atlasSizes` was read off a
client. They are stand-ins chosen so that art the client draws at different heights answers at
different heights here — the two tab families are 28 and 33, the pair this repo's own tab suite has
used as its stand-in since the strip was written. That difference is the load-bearing property: a
fixture answering one number for every atlas could not fail a selection-invariance assertion, which
is how anti-pattern #70 shipped green the first time. A case must read the figure it expects **out of
the table** rather than restating it, or it goes red for the wrong reason the day a real measurement
corrects the fixture. A consumer that needs an atlas the collection has not needed yet adds the entry
in its own `tests/wow_mock.lua`.

### Why: nine hand-written stubs and no way to check them

Nine addons carry a `settings/OptionsSetup.lua` degradation arm that mirrors the
`LibKa0s-Options-1.0` surface — MultiMeters 384 lines, AbsorbTracker 369, KickCD 351, PrettyChat 265,
WhatGroup 258, BankLedger 230, PanelMaster 217, LootHistory 199, ConsumableMaster 185. A stub is a
second implementation of somebody else's surface, so it drifts the moment the library grows a member
the host starts calling, and it drifts **silently**: the live path stays green and the degraded path
raises in exactly the install the stub exists for. AbsorbTracker's stub omits `SetRenderer` outright
today, with every suite in that repository green.

`Kit.assertSurfaceParity` has existed since revision 8 and only three of the nine call it, because
its four-argument form asks the caller to produce the live half first — a grep, a derivation, a
comment explaining the derivation. Revision 15 adds a second form that takes the **name**:

```lua
T.assertSurfaceParity(stubbedHelpers, "LibKa0s-Options-1.0")
```

| | Form one, unchanged | Form two, new at 15 |
|---|---|---|
| Call | `assertSurfaceParity(live, degraded, label, ignore)` | `assertSurfaceParity(stub, majorName, ignore)` |
| Selected by | anything but a string in the second position | a **string** in the second position |
| The live half | supplied by the caller | resolved from the registered surface source |
| Compared | every key of `live` | `Kit.publicMembers(live)` only |
| Reporting | all divergences in one message | all divergences in one message |

**What "public" means, and why the form needs its own answer.** `Kit.publicMembers(t)` returns every
string key that is neither LibStub bookkeeping — `MAJOR`, `MINOR`, `MODULES` — nor `__`-prefixed,
sorted, as `{ name, kind }` records. Those exclusions are the difference between a gate that gets
adopted and one that does not. No degradation stub in this collection carries `MINOR`, and rightly
so: `MAJOR` and `MINOR` are how the *library* answers "which copy am I", and a stub that answered
them would be claiming to be the library it stands in for. The `__` keys are a major's internals,
reached by a sibling file inside the same major and by nothing else. Reported raw, the Options major
alone hands a stub author **ten** divergences that are all correct omissions, and a gate whose first
run is ten false positives is a gate that acquires an `ignore` list the size of its own output.

**Where the name resolves.** The kit has no LibStub, no mock and no addon namespace, and `_G.LibStub`
is not it either — `loader.lua` hands each chunk a mocked environment rather than writing into `_G`,
so a kit that reached for the global would resolve nothing headlessly and report every stub as fine.
The harness registers the source once, in either shape it naturally has:

```lua
Kit.setSurfaceSource(mocks.LibStub)                         -- a callable: src(name, true)
Kit.setSurfaceSource{ ["LibKa0s-Options-1.0"] = NS.Helpers } -- a table: name -> live surface
```

The callable shape answers the **library table** for a major. The table shape is for the far commoner
case in this collection, where the stub mirrors an **instance** — every `OptionsSetup.lua` arm stubs
`NS.Helpers`, which is what `lib:New(descriptor)` returned, and the kit could never have built that
for itself because it needs the host's descriptor. `Kit.setSurfaceSource` returns the source that was
registered before it, so a case that swaps one in can put the old one back.

`Kit.expose` wires the callable shape **automatically** when the exposed table carries `mocks` or
`mock` with a `LibStub` on it, and only when nothing is registered yet — so a repo whose stubs mirror
library tables registers nothing, and a repo that registered its own keeps it.

**It fails rather than passes when it cannot look.** An unresolvable name, a source that raises, a
name that answers something other than a table, no source at all: every one of those is a failure
naming the fix, never a quiet pass. Same bargain `assertSuiteInventory` strikes when it cannot list a
directory.

**What a consumer writes.** Three lines, and the reference implementation is
the library repo's `tests/test_surface_parity.lua`:

```lua
test("parity: the Options stub carries the whole live surface", function()
  T.assertSurfaceParity(degradedNS.Helpers, "LibKa0s-Options-1.0", { RenderGrid = true })
end)
```

The member list each major publishes as data lives beside its API document, at
`docs/api/<Major>/members-<versionKey>.json` in the library repo — generated from the live surface by
`tools/gen-api-members.lua`, and regenerated and compared on every run of the library's own suite. It
is the list this assertion enforces, which is what a stub author should be reading.

### Why: a line-ending gate scoped to one directory found nothing outside it

`test_eol.lua` has been LibKa0s' own suite since revision 10, written alongside the fix to the
bundle writer, and it asked git about `docs/automated-tests/` and nothing else. That scope was the
whole defect: `line-endings-§7` MUSTs the pin be checked **mechanically**, and ten of ten
repositories failed it while the one repository that owned a gate ran it green — over 176 of its 508
tracked paths. Two of the files it could not see, `LibKa0s/DebugLog.lua` and `LibKa0s/Pool.lua`, are
in the **shipped** payload, which is why `diff -r LibKa0s <Addon>/libs/LibKa0s` — a SHOULD-be-empty
check in `docs/releasing.md` — reported thousands of phantom lines in nine repositories on every
re-vendor.

At this revision it reads the whole `git ls-files` set and it lives **in the kit**, so the gate is
inherited rather than re-typed nine times. A shell redirect is not the only way to write a file past
git's clean filters — sed, an editor across a WSL mount, any generator that opens a path for writing
— so the set to hold to the pin is the set git tracks.

**One shell-out, not one per path.** `git ls-files -z | git check-attr text eol --stdin -z` answers
both attributes for the whole repository in a single pass. Asked per path, `check-attr` measured
about 17ms, which is some nine seconds added to every run in ten repositories — the cost at which a
gate acquires a flag to switch it off.

**It reads bytes only where git converts them.** A path whose `eol` is `unspecified` has nothing to
be held to. A path whose `text` is `unset` is skipped for the same reason: `binary` unsets `text` and
says nothing about `eol`, so a marked asset still answers `eol: crlf` from a global pin, and holding
a `.tga` to a terminator count would be a red about an image. That is the rule the runner already
applies when it writes a bundle, and the two must not disagree. The NUL-byte guard stays behind it,
for a binary nobody remembered to mark. Everything it declines to do, it declines loudly: no
`io.popen`, no git, no answer from `check-attr` and it **fails** rather than passing.

#### The suite-list entry, and why the inventory scans the kit

A suites entry may now carry its own directory:

```lua
Kit.run{
  dir = "tests/",
  suites = { "test_schema", ..., { name = "test_eol", dir = "tests/_kit/" } },
}
```

`Kit.assertSuiteInventory` scans `tests/_kit/` for `test_*.lua` alongside `dir`, and a kit suite that
is on disk and undeclared is a **failure** naming the entry to add. That closes the way this kind of
file actually goes wrong: it arrives with a re-vendor rather than with a commit somebody wrote, so
without the scan the copy lands, nobody wires it, and the run stays green over a gate that never
executed. The scan is guarded on `tests/_kit/framework.lua` existing, so a repo that vendors the kit
somewhere else is never asked about it.

`loadSuites` now `loadfile`s a suite and calls the chunk with the kit as `...` rather than
`dofile`ing it. A kit-shipped suite cannot read the exposed table the way a repo's own suites do —
that table's global name is the consumer's (`LK_TEST`, `AT_TEST`, `KICKCD_TEST`, …) and the kit is
never told what it is — so `local Kit = ...` is how it reaches `test` and `fail`. Every existing
suite ignores the argument and is unaffected.

### What revision 16 will do, and why it is not this one

`GetHeight` and `GetWidth` read `(self.__geomLive and self.__geomH) or 0`. Revision 16 deletes the
`self.__geomLive and` from those two lines and every frame answers what was recorded on it. That is a
real change to a mock roughly **308 test files across ten repositories** lean on: every assertion
that passes today *because* geometry answers zero flips with it. Shipping both halves together is the
version of this that reddens nine suites on one afternoon, so the surface lands here and the default
moves once each consumer has adopted the opt-in where it needs geometry.

Until then the interval is covered by an operator rather than by a case, and that is named rather
than left as a gap: revision 15's own `TabStrip` rewrite is proved headless only by a `CreateFrame`
count, and the case that would pin band geometry under selection is exactly the one this revision
cannot express.

## The one boundary

**Exactly one cell in `RESULTS.md` is authored: the watch list's `Disposition`.**

The runner carries a disposition forward **verbatim** while its entry is unchanged, and leaves the
cell **blank** where the entry is new. A blank disposition is the record telling its owner that
something crossed a threshold and nobody has ruled on it yet — which is a stronger signal than a
sentence somebody was supposed to remember to write.

What counts as "the same entry":

- **Functions table** — the same `Function` at the same `Location`, where Location is the **file**,
  not a line range. Pinning the key to line numbers would blank every disposition in a file the
  moment anything above it grew a line, which is exactly the re-arguing the boundary exists to stop.
  Where a file holds two warned functions of the same name — MultiMeters has `Cell` twice in
  `modules/Row.lua` — the measured **CCN** breaks the tie. A tie the CCN cannot break either leaves
  the cell blank: attaching one entry's ruling to a different entry is worse than asking for a new
  one.
- **Band table** — the same `File` in the same `Band`. A file that crossed from *on notice* to *over
  cap* is a new entry and is owed a fresh ruling.

A disposition is never invented, and one that still applies is never dropped — those are the two
ways a runner can destroy the only judgment this file carries.

**If a generated sentence is wrong, the fix is here, in LibKa0s, and reaches the consumer on its
next re-vendor.** Editing the vendored `tests/_kit/` copy is forbidden by `testing-§1` and is
reverted silently by that re-vendor, after which the record is stale again.

## What the generated sections say

`## Test suite` — the case count split into passed / failed / skipped, the bundle's `test-cases.md`
named as the authority, and the trend: flat across three or more runs (which is the coverage-gap
signal the table cannot show), unchanged, or moved, with both figures.

`## Lint` — warnings, errors and file count, plus **what `.luacheckrc` excludes**, restated every
run. A `0/0` means nothing without its scope.

`## Perf` — the scenario count, or a `skip` that says **which** of `automated-tests-§3`'s two
sanctioned reasons it is: no `tests/perf.lua` at all (the record is silent about runtime cost), or a
tooling gap on this host (install it and re-run).

`## Complexity watch list` — the run's max CCN, function count, warned count and band counts, then
the two tables, then the reading note that `lizard` scores every `and`/`or` short-circuit as a
decision.

## For consumers: the count moves by exactly one, and the record moves

The Lua surface **grows** at this revision — `SetAtlas`, `__setGeom`, `__atlasSizes`,
`publicMembers`, `setSurfaceSource` and `assertSurfaceParity`'s second form — and still nothing
answers differently, so none of that gains or loses a case. That was measured rather than assumed:
the new `mock_base.lua` was dropped into all nine consumers' `tests/_kit/` and every one of them ran
to the same total it ran before — 547, 831, 749, 841, 699, 1496, 763, 300 and 528.

**`test_eol.lua` is the one case that does move the total**, `+1` in each of the nine, none of which
has an EOL gate of its own today. Expect that repo's number to read one higher the moment the entry
is wired, and move `docs/test-cases.md` and the README `[tests]` badge in the same commit. Expect it
to be **red** on the first run in most of them: this gate is the reason the stragglers are known
about at all, and the repair it names — `rm <path> && git checkout -- <path>`, per path — is the
working-tree sweep, not a change to the kit.

Expect, on the first run after re-vendoring:

- the **Tests** column gains a middle figure — `773/773` becomes `773/0/773`. Older rows keep the
  two-part shape and are preserved untouched; the trend reads across the change, because both shapes
  end in the total;
- the lead-in above the table is replaced with the four-checkpoint text;
- a complexity watch list and four standing sections appear below the table, with **every
  disposition blank** — there was no generated table to carry them forward from. Ruling on those
  blanks is the owner's step 3 in `AUTOMATED_TESTS.md`, and it is a one-time cost;
- any hand-written prose below the table is replaced. Copy a disposition worth keeping into the
  generated table's cell **in the same commit**, or it is gone.

That last point is the only sharp edge in this revision, and it is deliberate: hand-written prose
below the table is the thing being retired.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

One line is configuration rather than copying: `{ name = "test_eol", dir = "tests/_kit/" }` in the
runner's suite list. The inventory assertion fails until it is there and names the entry, so this
cannot be forgotten quietly — and it is the only thing to switch on. Everything else in the kit is
live the moment the bytes land.

Expect `+1` on the total, expect the EOL gate to be red until the working tree is repaired, and
expect nothing else to move; if something else does, the failure is not this kit revision.

## Vendoring

Whole-folder, from the library repo's root — the same cwd `docs/releasing.md` assumes:

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**Never edit `tests/_kit/` in a consumer.** A kit problem is a finding to fix here and re-vendor; a
local patch is a fork nobody knows about, and the next re-vendor silently reverts it.

LibKa0s is a consumer on the same terms as every addon: it reaches its own kit through `tests/_kit/`
rather than into `testkit/` directly, so `diff -r testkit tests/_kit` is the same gate here as it is
downstream, and a kit change that would break a consumer breaks this repo first.

## Bumping the revision

1. Change the kit, with its test.
2. Bump `Kit.VERSION` at the top of `testkit/framework.lua`.
3. Write `docs/api/testkit/version-<N>-docs.md`; mark this one `Superseded` and fill in its
   `Superseded by`. `tests/test_kitsync.lua` fails if the document for the live version is missing.
4. Re-vendor into `tests/_kit/` here **and** into every consumer's `tests/_kit/`, then run each
   repo's suite.
5. Add the row to [`../README.md`](../README.md).
