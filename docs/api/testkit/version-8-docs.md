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
