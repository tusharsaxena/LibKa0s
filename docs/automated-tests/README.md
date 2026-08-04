# Automated test records

Every run of the four out-of-game suites, recorded. The normative rules are the standard's
[`automated-tests`](https://github.com/tusharsaxena/WowAddonStandards/blob/master/standards/standards/automated-tests.md)
section; this file is the local how-to.

## Running

```sh
tests/_kit/run-automated-tests.sh                            # all four, writes a bundle
tests/_kit/run-automated-tests.sh --suite complexity          # a subset
tests/_kit/run-automated-tests.sh --suite lint --suite tests --no-bundle   # the green gate; writes nothing
```

**This repo is where the runner comes from.** Every other Ka0s repo vendors `tests/_kit/` *from*
here; this one vendors it from its own `testkit/` one directory over, and `tests/test_kitsync.lua`
fails the build if the two copies drift by a single byte. The rule that a kit fix goes upstream and
is never patched in `tests/_kit/` still applies — upstream is just `../../testkit/` rather than
another repo. Fix there, copy across, and let `test_kitsync` confirm it.

Because LibKa0s is a **library**, not an addon, it has no `.toc`: it is loaded through each host
addon's TOC and carries per-file LibStub minors instead of one addon version. The runner derives its
identity from the repo directory and its version from the newest semver tag.

## What gates, and what only records

| Suite | Command | Gates? |
|---|---|---|
| `lint` | `luacheck .` | **yes** |
| `tests` | `lua tests/run.lua` | **yes** |
| `perf` | `lua tests/perf.lua` | no — recorded only |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded only |

`perf` and `complexity` are **measured, recorded and diffed — never used to fail a run.** A
threshold that fails a run teaches everyone to reach for `--no-verify`, after which the gate protects
nothing and the habit remains. They contribute `amber`, which is a signal rather than a stop.

**A missing tool is a skip, not a failure**, and the skip is recorded with its reason — so a green
run that measured nothing cannot be mistaken for a green run that measured everything. This repo
ships no `tests/perf.lua`, so its `perf` column is a standing `skip`: the records here say nothing
about the library's runtime cost. `RESULTS.md`'s `## Perf` section explains what that costs.

## What is here

- **`RESULTS.md`** — one row per run across all four suites, plus the current complexity watch list.
  **One file, overwritten in place**: the git history of that single path is the trend line.
- **`<YYYYMMDD-HHMMSS>/`** — one frozen bundle per run: `manifest.json`, one file per suite, and
  `ANALYSIS.md` (the write-up). Bundles are **never edited** once written and **never pruned**.

There is no `perf-runs/` beside this directory. In-game captures are taken in a live client against
a **host addon**, and a library cannot be loaded on its own — so the in-game perf evidence for this
code lives in the consumers' repos, recorded against the addon that loaded it.
