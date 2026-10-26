# Analysis — 20261027-001339

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** f70882c (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261026-222042 (release run at `e1fca8b`, after the fourth round of skin notes).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a ninth time after its local tag, still before any push, with `SF-35` of
Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`: `f70882c`. A fill or wash is drawn as a region
of its own target at the bottom of BACKGROUND, no longer on a fill holder one frame level down, which
tied the target's parent (the owner's in-client probe of Loot History's title bar on Azeroth).
SkinPaint minor 7, SkinPaintControls minor 5, SkinPaintExtras minor 3; Skin key 4.8.6.2.4.1.2 ->
4.8.7.3.5.1.2.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261026-222042 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3019 passed, 2 skipped, 0 failed, 3021 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +2 cases (the probe's layout, the alpha reset); four restated |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65699 NLOC, 9810 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +27 NLOC, +1 function; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
