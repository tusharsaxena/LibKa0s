# `testkit` — version 28

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, **`inventory.lua`**, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **28** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.62.0 |
| Status | **Current** |
| Supersedes | [version 27](version-27-docs.md) — the shared diagnostics contract |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `28` |

Everything revision 27 describes is unchanged here except what follows. One file is added,
`inventory.lua`. One file changes: `framework.lua`, whose `Kit.VERSION` is 28 and which no longer
holds the code that moved. No member is added, removed or renamed, no case is added, removed or
renamed, no mock changes, and no behavior changes.

## What changed

### The suite inventory moves to `inventory.lua`

`framework.lua` had been in `layout-§1`'s 1000–1500 band since revision 26 peeled `asserts.lua` out
of it (1381, and 1386 at revision 27). Its band entry had been carried as *Accepted* across six
release runs, past `automated-tests-§4`'s three-release shelf life, and revision 26 had already named
the next seam: the suite inventory. This revision peels it, unchanged, into `inventory.lua`, which
takes `framework.lua` from 1386 lines to 920, out of the band.

What moved, byte for byte apart from one level of indentation:

- **The suite inventory.** `Kit.assertSuiteInventory` and everything only it reaches: the gate-rule
  table (`KIT_GATE_RULE`), the register hosts, the `## Documented deviations` reader and the decline
  matcher, the declaration fold, the three collectors (missing, undeclared and the vendored kit's
  holes) and the set of declines already reported.
- **The path helpers the inventory keys on**: `fileExists`, `normDir`, `isAbsoluteDir`, `rootOf`,
  `relToRoot`, `resolveDir`, `adviceDir`, `suiteEntry` and `listDir`.

Why it is a seam: the inventory's one piece of state, the declines already reported, is read by
nothing else, and it reaches the rest of the kit only through `Kit.test` (a recorded decline is
registered as a declared skip) and `fail`. The path helpers are pure functions of their arguments.

What stayed in `framework.lua`: the resource guard, the registry, `Kit.skip`, `Kit.expose`, the
suite loader (`loadSuites`, with the host-path gate and the CPU ceiling it applies to a suite's load),
the command line, the `--list` renderer, the shard driver and the runner.

**The shape follows `asserts.lua`.** `inventory.lua` returns `function(Kit, fail)`, which installs
`Kit.assertSuiteInventory` on the kit table it is handed and returns the helpers `framework.lua`
still calls (`fileExists`, `normDir`, `rootOf`, `resolveDir`, `adviceDir`, `suiteEntry`) and the
three internals the kit exposes to its own self-tests. `framework.lua` loads it once, where the path
helpers used to stand and before `loadSuites`, from its own folder, found the way it finds
`asserts.lua` (the local that finds it is renamed `kitFolder`, since it now finds two files). So
`Kit.assertSuiteInventory` is on the kit table exactly when it was before, and `Kit.expose` copies it
as it did.

**The self-test internals are unchanged.** `Kit.__loadSuites`, `Kit.__normDir`,
`Kit.__resolveDir`, `Kit.__adviceDir`, `Kit.__deviationRows`, `Kit.__declineFor` and
`Kit.__kitGateRule` name the same functions and the same table they did at revision 27.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change, no case name changes, so `docs/test-cases.md` does
not change, and the run's totals are the same before and after. A copy that leaves out
`inventory.lua` fails at load, when `framework.lua` reaches for it, rather than running with no
inventory: copy the whole folder, as the kit's README says.
