# Analysis — 20261026-190317

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** d7a610e (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261026-181407 (release run at `fcdbb68`, after the first round of skin notes).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a sixth time after its local tag, still before any push, with the owner's second
round of skin notes (`SF-16`..`SF-22` of Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`):
`d7a610e` (SkinPaint minor 5, SkinPaintExtras minor 2, SkinPaintControls minor 3). Every labeled
string takes the skin's face, dark labels are shadowless, primary buttons differ from normal ones in
every skin, sliders are one shape, and Azeroth is darker in an Atkinson body. Skin key 4.7.5.2.3.1.1.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261026-181407 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3017 passed, 2 skipped, 0 failed, 3019 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: +5 (the round's new cases) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65686 NLOC, 9818 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +60 NLOC, +8 functions; max CCN 15 at both |

The complexity delta is `darkColor` and `P.label` and the new test cases; the functions at CCN 15 are
the ones already there.

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
