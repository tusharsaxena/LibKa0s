# Analysis — 20261028-120744

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** 2224a8c (`feat/2026-10-28-skin-round5`), clean
- **Previous run:** 20261028-015008 (release run at `3974846`, after R5-04).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended again after its local tag, still before any push, with `R5-09` of
Ka0sAddonsCommonTasks `docs/2026-10-28-SKIN_ROUND5/`: `2224a8c`, Azeroth's window frame as thin as
the other skins' (a 1px edge under its gold inner rule, from 3px). SkinDefs minor 13; Skin key
5.12.10.3.8.1.3 -> 5.13.10.3.8.1.3.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261028-015008 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3031 passed, 2 skipped, 0 failed, 3033 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +1 case (the window frame's thickness) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 66184 NLOC, 9856 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +9 NLOC, +1 function; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
