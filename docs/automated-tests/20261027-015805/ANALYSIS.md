# Analysis — 20261027-015805

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** 0920b9a (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261027-005758 (release run at `854ad32`, after SF-38).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended an eleventh time after its local tag, still before any push, with `SF-41` of
Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`: `9d62ae1` and `0920b9a`. "Ignore settings
panel" applies live with no reload: the Options chrome hands every target the skin painted back from
the Skin major's records, every tint records the color it replaced, and the nav rail's colors are
saved. No minor moves (each touched file is already at this extension's minor); the keys stay
5.8.8.3.5.1.3 (Skin) and 33.3.35.4.6.10.3.12.7.3.2.5.2 (Options).

A first release run at `9d62ae1` (not kept) measured `paintPage` at CCN 17; `0920b9a` splits it.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261027-005758 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3028 passed, 2 skipped, 0 failed, 3030 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +1 case (every chrome piece back to stock); two restated |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 66007 NLOC, 9840 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +81 NLOC, +7 functions; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
