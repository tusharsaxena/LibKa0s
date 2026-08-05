# `testkit` — version 8

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **8** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased — on `master` after v1.7.0 |
| Status | **Current** |
| Supersedes | [version 7](version-7-docs.md) — adds the skip status, `vendor_sync.lua`, `Loader.xmlFiles`, the suite-inventory gate and `Kit.assertSurfaceParity` |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `8` |

## What changed at this version

**The largest revision since version 2, and the first to add a file to the Lua payload.** Five
changes, all in service of one idea: a test that cannot look must say so, and a list that is
hand-typed must be pinned.

| | |
|---|---|
| `Kit.skip(reason)` | A third case status. Never a pass, never a failure, never an exit code. |
| `testkit/vendor_sync.lua` | The consumer-side vendored-payload gate, once, instead of six copies. |
| `Loader.xmlFiles(xmlPath)` | The vendored-library load list, derived from the XML rather than re-typed. |
| `Kit.assertSuiteInventory(dir, suites)` | The suite list pinned in both directions; `loadSuites` no longer skips a declared-but-absent suite in silence. |
| `Kit.assertSurfaceParity(live, degraded, label)` | A degraded-path stub's surface asserted as a set, not member by member. |

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
