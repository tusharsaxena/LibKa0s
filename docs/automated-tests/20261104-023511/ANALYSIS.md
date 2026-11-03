# Analysis — 20261104-023511

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the first battery of the tag's eighteenth local
  re-cut, `R6-REL2` after `R6-SIM-L`)
- **Verdict:** green on the run, and **not a release record**: the release gate refuses it
- **Commit:** `d71df6f` (`feat/2026-11-01-full-skinning`), clean, the round 6 sim checkbox hosts-owe line
- **Previous run:** [`20261104-002816`](../20261104-002816/) (at `4fd5b47`), the seventeenth re-cut.

## Headline

Lint (0/0 in 298 files) and tests (4069 passed, 3 skipped, 0 failed, 4072 total) pass, and the
complexity suite, which records rather than gates a run, warned on **one function above CCN 15**
([`complexity.txt`](complexity.txt), [`manifest.json`](manifest.json): `warnings` 1, `maxCcn` 22):

| Function | CCN | Location | Came in with |
|---|---|---|---|
| `masterRows` | 22 | `LibKa0s/OptionsCompose.lua` | `R6-SIM-L` (the Sim mode row's placement beside Lock frame or Test mode) |

`complexity.warnings` is 1, so no tag is cut from this bundle (`automated-tests-§3`, *The release
gate*: zero functions above CCN 15). Perf was not measured: no `tests/perf.lua`.

## Actions

1. `masterRows` is split with no behavior change in the next `R6-REL2` commit: the Minimap button, Test
   mode and Sim-beside-Test rows go to a local helper, `masterTail`. `OptionsCompose.lua` stays at
   minor 19, which no host vendors yet.
2. The battery runs again after that commit; that run is the re-cut's release record.
