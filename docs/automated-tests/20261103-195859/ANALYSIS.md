# Analysis — 20261103-195859

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the first battery of the tag's sixteenth local
  re-cut, `R5-REL` after `R5-L1` to `R5-L5`)
- **Verdict:** green on the run, and **not a release record**: the release gate refuses it
- **Commit:** `0af3b93` (`feat/2026-11-01-full-skinning`), clean, the round 5 hosts-owe note
- **Previous run:** [`20261103-160531`](../20261103-160531/) (at `ef88399`), the fifteenth re-cut.

## Headline

Lint (0/0 in 296 files) and tests (4030 passed, 3 skipped, 0 failed, 4033 total) pass, and the
complexity suite, which records rather than gates a run, warned on **two functions above CCN 15**:

| Function | CCN | Location | Came in with |
|---|---|---|---|
| `Header` | 17 | `LibKa0s/SkinPaintExtras.lua` | `R5-L3` (`S.Header`) |
| `Shell` | 18 | `LibKa0s/SkinPaint.lua` | `R5-L2` (the bare-call replay of the owner's opts) |

`complexity.warnings` is 2, so no tag is cut from this bundle (`automated-tests-§3`, *The release
gate*: zero functions above CCN 15). Perf was not measured: no `tests/perf.lua`.

## Actions

1. Both functions are split with no behavior change in the next `R5-REL` commit (`875c89c`):
   `S.Header`'s drag strips and title go to two local helpers; `S.Shell`'s no-backdrop fill and title
   face fold into the renamed `shellBody`, adding no SkinPaint function.
2. The battery runs again on that commit, [`20261103-200402`](../20261103-200402/), which is the
   re-cut's release record.
