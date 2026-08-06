# `testkit` — version 8

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **8** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.8.0 |
| Status | Superseded |
| Supersedes | [version 7](version-7-docs.md) — adds the skip status, `vendor_sync.lua`, `Loader.xmlFiles`, the suite-inventory gate, `Kit.assertSurfaceParity`, and fixes the runner's clock and its executable bit |
| Superseded by | [version 9](version-9-docs.md) — `vendor_sync.lua` reads the provenance line from `CLAUDE.md` |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `8` |

## What changed at this version

**The largest revision since version 2, and the first to add a file to the Lua payload.** Six
changes, all in service of one idea: a test that cannot look must say so, a list that is hand-typed
must be pinned, and a number that is recorded must be a measurement.

| | |
|---|---|
| `Kit.skip(reason)` | A third case status. Never a pass, never a failure, never an exit code. |
| `testkit/vendor_sync.lua` | The consumer-side vendored-payload gate, once, instead of six copies. |
| `Loader.xmlFiles(xmlPath)` | The vendored-library load list, derived from the XML rather than re-typed. |
| `Kit.assertSuiteInventory(dir, suites)` | The suite list pinned in both directions; `loadSuites` no longer skips a declared-but-absent suite in silence. |
| `Kit.assertSurfaceParity(live, degraded, label)` | A degraded-path stub's surface asserted as a set, not member by member. |
| `run-automated-tests.sh` | Millisecond durations that cannot be negative, a recorded timing source, the file itself `100755` in the index, a `RESULTS.md` lead-in that names the checkpoint, and `suites.<name>.gates`. |

**Adoption is additive except for one item.** A consumer on version 7 keeps working after
re-vendoring, with a single exception: `Kit.assertSuiteInventory` runs automatically when
`Kit.run` is given an explicit `opts.dir`, and it converts a previously silent asymmetry between
`tests/test_*.lua` and the declared suite list into a failure. Check both directions before
re-vendoring, or pass `suiteInventory = false` while migrating.

---

## `Kit.skip(reason)` — the third status

```lua
local T = _G.AT_TEST
T.test("libs/LibKa0s is the release the README says this addon bundles", function()
  local tag = siblingTag()
  if not tag then
    T.skip("../LibKa0s checkout absent — the vendored payload was not compared")
  end
  assertVendorSync(tag, ...)
end)
```

**Why it exists.** A case that cannot look — no sibling checkout, no `git`, a fixture the platform
cannot produce — used to be written as a bare `return`. A bare `return` registers as **PASS**. Six
repos in this collection did exactly that, so six green gates were reporting "checked, fine" for a
check that never ran, and the one number everybody reads (the `[tests]` badge) was counting them.

**How it is implemented, and why.** `Kit.skip` raises a sentinel error, which is what lets it be
called *from inside a case body at any depth* — inside a helper, inside a loop — without
restructuring the case into a predicate plus a body. `Kit.run` recognises the sentinel and reports
`  SKIP  <name> — <reason>`.

**Two properties are non-negotiable.**

- **A skip is never folded into `passed`.** The README `[tests]` badge and `docs/test-cases.md`
  count passes. A skip counted as a pass is the original lie in a new place.
- **A skip never changes the exit code.** `Kit.run` still exits `failed == 0 and 0 or 1`. The same
  script is the commit gate, and the release gate reads `suites.tests.failed` out of the run
  manifest. A skip is *not evaluated* — a fact for the release flow to judge, not a failure to be
  re-litigated inside the runner.

The run's tail line grew a column:

```
478 passed, 0 failed, 2 skipped, 480 total
```

### Declared skips, and what `--list` can and cannot see

`Kit.test(name, fn, skipReason)` takes an optional third argument. With it, the case is a
**declared** skip: `fn` is never called, the run reports SKIP, and the `--list` inventory renders
the case with a `(skipped: <reason>)` suffix so `docs/test-cases.md` discloses it.

A skip decided *inside* a body cannot appear in `--list`, and this is deliberate rather than an
omission. `--list` is a pure filter over the registry and executes nothing — that is the property
that makes the generated inventory unable to disagree with what actually runs (see the header of
`framework.lua`). Running bodies to find out which ones skip would give `--list` a second code path
through every suite, which is the exact defect the collect-then-run design removes. Runtime skips
are disclosed by the run output and by the automated-test bundle.

`T.skip` is merged into the exposed table by `Kit.expose`, alongside `test` and the assertions.

---

## `testkit/vendor_sync.lua` — one gate, not six copies

**The first file added to the Lua payload since version 1.** The consumer-side vendored-payload gate
was ~150 lines copy-pasted into six repos with a one-line delta (`local T = _G.AT_TEST` versus
`_G.LH_TEST`). Every copy carried the same bare `return` that registered as PASS, and the same header
claiming the skip "is said in the case name" when neither case name mentioned it. Six copies is six
chances to fix one problem six different ways.

```lua
-- tests/test_vendor_sync.lua, in full
local VendorSync = dofile("tests/_kit/vendor_sync.lua")
VendorSync.register(_G.AT_TEST, {})
```

A **factory**, not auto-registration, so the consumer keeps ownership of its test global and its case
names — the names are what `docs/test-cases.md` counts, and swapping a hand-copied gate for this one
must not move a repo's numbers.

| `opts` key | Default | What it is |
|---|---|---|
| `root` | `"."` | the consuming repo root, as the suite sees it |
| `sibling` | `<root>/../LibKa0s` | the library checkout tags are read out of |
| `probe` | `"HEAD:LibKa0s/Core.lua"` | the ref that answers "is the sibling there at all?" |
| `readmePattern` | `"[Bb]undles %[LibKa0s%]%b() (v[%d%.]+)"` | how the provenance line is spelled |
| `pairs` | `libs/LibKa0s` + `tests/_kit` | `{ case, tag, local_, label }` per compared payload |

No repo in the collection needs a `readmePattern` override: the lowercase/mid-sentence leniency is
already in the shipped pattern, because LootHistory writes the line that way.

### What it compares, and the one normalization

The gate compares a **working-tree file** against a **`git show` blob**, and those are not the same
representation. The blob is LF. The working tree is CRLF in eight of the nine repos, because their
`.gitattributes` pins `text=auto eol=crlf`. So it reads raw bytes in binary mode and applies
**exactly one** normalization — **CR stripped from the working-tree side, nothing else** — which
compares the file to the blob it round-trips to.

The consequence, stated plainly so nobody has to infer it:

| Difference | Result |
|---|---|
| a single content byte | **FAIL** |
| the file set on either side | **FAIL** |
| line endings only (CRLF vs LF) | **PASS**, deliberately |
| sibling checkout absent | **SKIP**, with the reason, exit code unchanged |

Line endings are decided per checkout by `.gitattributes` — the same commit legitimately materialises
as CRLF in one repo and LF in another — so treating them as a content fork would redden every
consumer for a fact about their checkout rather than about their bytes.

The normalization-free equivalent is `git hash-object <working-tree file>` against the sibling's blob
sha, which makes git do the round-trip instead. It draws the same line in the same place and is the
better shape if this is ever rewritten rather than moved.

**This is scoped to the blob-versus-worktree comparison.** The library-side pair — `testkit/` versus
`tests/_kit/`, two working-tree directories in one checkout — normalizes nothing, because there both
sides are subject to the same `.gitattributes` and a line-ending difference really is a defect.

### Two properties of living inside the kit

- **The gate is inside the payload it checks.** A consumer that locally patches `tests/_kit/` breaks
  this file's own byte-identity assertion, which is the right outcome: the fix for a kit problem is
  upstream and re-vendor, never a local edit.
- **LibKa0s cannot run it.** There is no sibling to compare against from inside the library repo,
  which is why `register` is called by the consumer and `tests/test_kitsync.lua` remains the
  library-side equivalent.

### Adopting it is one commit, not two

The gate compares **file sets**. The first re-vendor lands `tests/_kit/vendor_sync.lua` while the
consumer's OLD in-repo gate is still running, so the new file has to appear on both sides at the same
time: **re-vendor and rewrite are one commit**, against a LibKa0s tag that already carries the file.
Both payloads move together — the provenance line is the gate's input and it is compared against
`libs/LibKa0s/` *and* `tests/_kit/`, so bumping the line while copying only one of them reddens the
other.

---

## `Loader.xmlFiles(xmlPath)` — the vendored-library list, derived

```lua
Loader.loadAll(Loader.xmlFiles("libs/LibKa0s/LibKa0s.xml"), NS, mocks)
Loader.loadAll(Loader.tocFiles("AbsorbTracker.toc"), NS, mocks)
```

Returns the `.lua` files a `<Ui>` XML pulls in, **in XML order**, as forward-slash paths **prefixed
with the XML's own directory** — `libs/LibKa0s/Core.lua`, not `Core.lua` — so the result feeds
`Loader.loadAll` directly. The prefixing is the whole ergonomic difference between a helper a runner
adopts and one it has to wrap.

**Why.** `Loader.tocFiles`'s own comment names the gap it leaves: a vendored library is pulled in
through its own XML, which a TOC scan cannot see, so every runner in the collection re-typed the same
eight-entry list — nine repos, and AbsorbTracker twice (`tests/run.lua` and `tests/perf.lua`). One of
those copies named **six** of the eight files, and nothing noticed: a short load list does not raise,
it just leaves a module undefined for whichever cases never reach it.

| Property | Behaviour |
|---|---|
| Order | XML order, preserved — `LibKa0s.xml` is load-order-sensitive |
| Path shape | forward slashes, `\` converted, prefixed with the XML's directory |
| Comments | a line opening with `<!--` is skipped, so a commented-out entry does not load |
| Non-`.lua` `file=` attributes | ignored |
| Missing XML | **raises** `cannot open <path> (tests run from the repo root)` |

That last row is deliberate. Returning an empty list on a typo'd path loads nothing at all and reads
exactly like a clean run.

It is line-based and flat on purpose: `LibKa0s.xml` is a flat list of `<Script file="…"/>` with no
nested `<Include>`s, and a real XML parser here would be a dependency bought to solve a problem
nobody has.

---

## The suite list, pinned in both directions

**This is the one change in version 8 that is not additive.** It converts a silence into a failure,
so a consumer must be in balance on the commit that adopts it.

### `loadSuites` no longer skips a declared-but-absent suite

Through version 7, a `suites` entry naming a file that was not on disk was skipped, and the comment
in `framework.lua` called that deliberate — *"so a suite can be listed while it is being written
without taking the whole run down with it."* The convenience is real. The silence is not worth it: a
renamed or deleted suite left the run with no signal at all, and the run stayed green while covering
less than it did the day before.

It now raises, naming the path and its position in the list.

### The write-in-progress affordance, made explicit

```lua
Kit.run{
  dir = "tests/",
  suites = {
    "test_core",
    { name = "test_migration", pending = "schema v4 lands next week" },
  },
}
```

A `pending` entry registers a **declared skip** instead of registering nothing: the run prints
`SKIP  test_migration.lua: suite not written yet — schema v4 lands next week`, and `--list` writes it
into `docs/test-cases.md` with its reason. The intent is now data, and it is disclosed.

Declaring `pending` on a suite whose file *does* exist is an error — that is the original silence
wearing the affordance's clothes.

### `Kit.assertSuiteInventory(dir, suites)`

Globs `<dir>test_*.lua` (via `ls -A`, falling back to `dir /b`; no LuaFileSystem dependency) and
compares it against the declared list **in both directions**. Every divergence in both directions is
reported in one message — a list that has drifted has usually drifted more than once.

| Direction | Message says |
|---|---|
| declared, not on disk | `… is declared in the suites list (position N) but is not on disk — delete the entry or write the file` |
| on disk, not declared | `… exists but is not declared in the suites list — add "…" to the runner; it is running zero cases today` |

The two messages are worded differently on purpose: the two fixes are different, and a single
"suite list mismatch" would make the reader work out which one they have.

A `pending` entry is exempt from the first direction, because it is declared-and-deliberately-absent.
If the listing itself comes back empty the assertion **fails** rather than passing — a gate that goes
quiet when it cannot look is worse than no gate.

It is exported through `Kit.expose` as `T.assertSuiteInventory`, so a repo that prefers to own the
assertion as a named case (BankLedger and PanelMaster already do) can call it directly.

### It runs automatically

`Kit.run` calls it **before** loading the suites whenever `opts.dir` is given explicitly. A runner
that auto-discovers its suites and passes no `dir` sits outside the assertion's premise and is left
alone.

```lua
Kit.run{ dir = "tests/", suites = { … }, suiteInventory = false }   -- documented opt-out
```

`suiteInventory = false` exists for a repo mid-migration. It is not a setting to leave switched off.

---

## `Kit.assertSurfaceParity(live, degraded, label, ignore)`

```lua
-- Members from: grep -n "^function Sl\.\|^Sl\.[A-Z]" libs/LibKa0s/Slash.lua
T.test("the Slash stub carries the whole live surface", function()
  T.assertSurfaceParity(liveSlash, degradedSlash, "Slash stub")
end)
```

Walks `live`'s keys and reports two kinds of divergence:

| Divergence | Why it matters |
|---|---|
| a key present in `live`, absent from `degraded` | the stub is missing a member the addon calls on the degraded path |
| a key that is a **function** live and something else degraded | `Helpers.Refresh = UI and UI.Refresh` can leave `false` or a non-function in place; a check that only asks "is the key set?" waves it through and the call site raises anyway |

**Every divergence is reported in one message.** A stub written from a stale surface is typically
wrong in several places, and first-one-only turns that into one test run per missing member.

`ignore` encodes "this member is live-only, on purpose" **as data**, either as a set
(`{ HelpHeader = true }`) or as an array (`{ "HelpHeader" }`). Without it an intentional omission and
a bug are indistinguishable, and the usual resolution for that is to delete the case.

Exported through `Kit.expose` as `T.assertSurfaceParity`.

**Honest limits, so nobody over-claims.** It cannot catch a stub with the right member set and a
*wrong implementation* — a stub re-implementing the library's line format, or a hand-copied ack
string, are `debug-logging-§7` violations and stay addon-side. And it needs both halves loadable in
one process, which is what the degraded arm built from a partial file list gives you; never
hand-stub the member under test, or the case asserts the test's own typing.

## `run-automated-tests.sh` — the clock, and the executable bit

### Durations are measured in milliseconds, and clamped

Through version 7 every suite was timed with `t0=$(date +%s)` — **whole seconds** — and reported as
`$(( DUR * 1000 ))`. Two consequences, both visible in committed bundles:

- a suite that took 300ms recorded `0`, which reads exactly like a suite that did not run;
- a second boundary crossed the wrong way recorded a **negative** duration. `-1000` and `-2000` are
  committed in five repos' manifests. Those bundles are frozen evidence and are **not** rewritten.

Version 8 resolves one millisecond clock at the top of the script and uses it for every timestamp:

| Preference | Source | Granularity |
|---|---|---|
| 1 | `date +%s%3N` (GNU coreutils) | 1ms |
| 2 | `$EPOCHREALTIME` (bash ≥ 5.0) | 1µs, truncated to 1ms |
| 3 | `date +%s` × 1000 | 1s |

Every emitted duration goes through `elapsed_ms`, which **clamps at zero**. A backwards clock now
records `0` — an unhelpful number, but not an impossible one.

**`host.timingSource` in `manifest.json` names which of the three was used**, beside the tool
versions, because it is the same kind of fact. A run recorded on a host that could only offer
second granularity says so, instead of presenting rounded seconds as though they were milliseconds.

**The two operands of a subtraction must come from the same clock — this is the trap.** Converting
the per-suite timers to milliseconds while leaving the run-level `RUN_START` in seconds produces
epoch-milliseconds minus epoch-seconds: roughly **1.7 × 10¹²**, written into the run-level
`durationMs` of every future manifest. It is **positive**, so it passes any "no negative duration"
check. The check that catches it is *the run duration is within an order of magnitude of the sum of
the suite durations*, and that is the check to run after touching this block.

### The runner is `100755` in the index, and gated

`testkit/run-automated-tests.sh` and `tests/_kit/run-automated-tests.sh` are both mode **`100755`**
in the git index, and `tests/test_kitsync.lua` fails if either is not.

All nine repos in the collection shipped it `100644`, source included, and nobody could see it:
every repo sets `core.fileMode=false`, so git never complains, and this tree is DrvFs, so `ls -l`
reports `rwxrwxrwx` for a file the index calls non-executable. **`ls -l` is not evidence here.** The
gate reads `git ls-files -s`, and any equivalent check downstream must do the same.

**The bit does not travel with `cp`, and it is not in the file's bytes** — the byte-identity case
cannot see it, which is why it needs its own gate. A consumer re-vendoring this revision still runs
`git update-index --chmod=+x tests/_kit/run-automated-tests.sh` **once**. The difference is that
after this, forgetting is loud rather than surviving three audit cycles.

### The emitted `RESULTS.md` lead-in names the checkpoint

Through version 7 the runner wrote this above every repo's trend table:

> **`lint` and `tests` gate. `perf` and `complexity` are recorded and never fail a run** —

Every clause is true, and the paragraph is misleading, because it names no checkpoint. There are
**two** — the commit and the tag — and perf and complexity answer differently at each. Read alone it
says *"these two gate nothing"*, which `automated-tests-§3`'s release gate contradicts. Nine repos
were written up for carrying that sentence and **none of them wrote it**: the runner did, on every
run, which is also why hand-editing the nine copies would have been undone by the next run.

The lead-in now states, per suite: `lint` and `tests` gate the run **and** the commit (`testing-§4`);
`perf` and `complexity` never fail a run and never block a commit; the **tag** is gated on all four
suites at `pass` plus **zero** functions above **CCN 15**, evaluated by `/wow-addon:bump-version`
from the run's `manifest.json`, where a `skip` is **NOT EVALUATED** rather than a pass.

It is written only when `RESULTS.md` does not yet exist. **A repo with an existing `RESULTS.md`
keeps the old paragraph until someone replaces it by hand** — the runner will not rewrite a file
whose rows are the trend line.

### `suites.<name>.gates`, beside the legacy `gating`

```jsonc
"suites": {
  "lint":       { "status": "pass", "durationMs": 245, …,
                  "gating": true,  "gates": { "commit": true,  "release": true } },
  "complexity": { "status": "pass", "durationMs": 270, …,
                  "gating": false, "gates": { "commit": false, "release": true } }
}
```

`gating` is a **boolean** and there are **two** checkpoints, so it could only ever describe one of
them. It described the run, which made `"gating": false` on perf and complexity the same half-truth
as the old lead-in, in machine-readable form. `gates` names both.

**Neither field is read by anything, and that is the point of documenting them.**
`/wow-addon:bump-version` evaluates the release gate from **`suites.<name>.status`** and
**`suites.complexity.warnings`** — never from `gating`, and never from `gates`. Both fields are
descriptive; `gates` is the honest description. **Do not build a gate on either**: a consumer that
started reading `gates.release` would be taking its release policy from a string the runner hardcodes
rather than from the measurements, which is how a decorative field becomes load-bearing by accident.

The legacy `gating` boolean is retained for **one revision** so nothing reading it breaks on the way
past. It is scheduled for removal at version 9.

## Compatibility

The kit surface is **additive-only** on the same terms as the library: a function or seam may be
added in a later revision, never removed or repurposed, so a suite written against version 1 keeps
working unmodified.

The difference is what happens when copies disagree. The library negotiates — LibStub compares
minors and the highest wins. The kit does not: a consumer whose `tests/_kit/` differs from this
repo's `testkit/` by a single byte is **out of sync**, not on an older supported version, and the
fix is always to re-vendor rather than to read an older document.

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

## Moving to version 9

[Version 9](version-9-docs.md) changes one thing: `vendor_sync.lua` reads the provenance line out of
the consumer's **`CLAUDE.md`**, not its `README.md`, and names the file through the new
`provenanceFile` opt. `readmePattern` is still accepted under its new name `provenancePattern`, so no
call site breaks — but there is **no fallback to `README.md`**. A repo that re-vendors without moving
its line fails the case rather than passing on the old location.

The change is visible outside `tests/_kit/`: the first case's name becomes *"libs/LibKa0s is the
LibKa0s release CLAUDE.md says this addon bundles"*, so `docs/test-cases.md` must be regenerated in
the same commit as the re-vendor.

`suites.<name>.gating` was scheduled for removal at version 9 by the section above. It is still
emitted there; the removal is deferred, not cancelled.
