# Analysis — 20261104-002116

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the first battery of the tag's seventeenth local
  re-cut, `R6-REL` after `R6-L1`)
- **Verdict:** green on the run, and **not a release record**: the release gate refuses it
- **Commit:** `62ba52f` (`feat/2026-11-01-full-skinning`), clean, the independent review's fix to `R6-L1`
- **Previous run:** [`20261103-200402`](../20261103-200402/) (at `875c89c`), the sixteenth re-cut.

## Headline

Lint (0/0 in 297 files) and tests (4053 passed, 3 skipped, 0 failed, 4056 total) pass, and the
complexity suite, which records rather than gates a run, warned on **one function above CCN 15**
([`complexity.txt`](complexity.txt), [`manifest.json`](manifest.json): `warnings` 1, `maxCcn` 18):

| Function | CCN | Location | Came in with |
|---|---|---|---|
| `paintEye` | 18 | `LibKa0s/OptionsSkinPicker.lua` | `R6-L1` (the eye's lit or dimmed state and its per-mode tooltip) |

`complexity.warnings` is 1, so no tag is cut from this bundle (`automated-tests-§3`, *The release
gate*: zero functions above CCN 15). Perf was not measured: no `tests/perf.lua`.

## Actions

1. `paintEye` is split with no behavior change in the next `R6-REL` commit: the tooltip's per-mode
   wording goes to a local helper, `eyeTip`. `OptionsSkinPicker.lua` stays at minor 11, which no host
   vendors yet.
2. The battery runs again after that commit and the round 6 hosts-owe line; that run is the re-cut's
   release record.
