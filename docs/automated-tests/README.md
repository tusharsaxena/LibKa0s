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

"Does it gate?" has no single answer, because there are **two checkpoints** and a suite answers
differently at each. The columns name both.

| Suite | Command | Gates the run and the commit? | Gates the tag? |
|---|---|---|---|
| `lint` | `luacheck .` | **yes** (`testing-§4`) | **yes** |
| `tests` | `lua tests/run.lua` | **yes** (`testing-§4`) | **yes** |
| `perf` | `lua tests/perf.lua` | no — recorded only | **yes** |
| `complexity` | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | no — recorded only | **yes**, plus zero functions above CCN 15 |

`perf` and `complexity` are **measured, recorded and diffed — never used to fail a run, and never
used to block a commit.** A threshold that fails a run teaches everyone to reach for `--no-verify`,
after which the gate protects nothing and the habit remains. They contribute `amber`, which is a
signal rather than a stop.

At the tag they are not decoration. **The release gate requires all four suites at `pass` plus zero
functions above CCN 15** (`automated-tests-§3`, *The release gate*), evaluated by
`/wow-addon:bump-version` from the release run's `manifest.json` — not by this script, whose exit
code is unchanged by either suite. Saying "`perf` and `complexity` do not gate" without naming the
checkpoint is the half-truth this section used to carry; `RESULTS.md` carries the same correction in
its runner-emitted lead-in.

**A missing tool is a skip, not a failure**, and the skip is recorded with its reason — so a green
run that measured nothing cannot be mistaken for a green run that measured everything. A `skip` is
never a pass, and **at the release gate it is NOT EVALUATED rather than passed**: install the tool
and re-run. A `—` is a suite that was not selected, which is a different fact again.

This repo ships no `tests/perf.lua`, so its `perf` column is a standing `skip`: the records here say
nothing about the library's runtime cost, and the release gate's `perf` arm has nothing to evaluate
here. `RESULTS.md`'s `## Perf` section explains what that costs.

## What is here

- **`RESULTS.md`** — one row per run across all four suites, plus the current complexity watch list.
  **One file, overwritten in place**: the git history of that single path is the trend line.
- **`<YYYYMMDD-HHMMSS>/`** — one frozen bundle per run: `manifest.json`, one file per suite, and
  `ANALYSIS.md` (the write-up). Bundles are **never edited** once written and **never pruned**.

There is no `perf-runs/` beside this directory. In-game captures are taken in a live client against
a **host addon**, and a library cannot be loaded on its own — so the in-game perf evidence for this
code lives in the consumers' repos, recorded against the addon that loaded it.
