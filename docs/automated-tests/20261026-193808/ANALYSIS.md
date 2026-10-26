# Analysis — 20261026-193808

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** ce9a2a3 (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261026-190317 (release run at `d7a610e`, after the second round of skin notes).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a seventh time after its local tag, still before any push, with the owner's third
round of skin notes (`SF-25`, `SF-26` of Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`):
`ce9a2a3`, data only (SkinDefs still minor 7, never shipped). WoW Default's idle tabs wear the active
tab art, so they stand as tall as the selected one, and its inputs, dropdowns and nav rail take a 1px
edge. Skin key 4.7.5.2.3.1.1, unchanged.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261026-190317 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3017 passed, 2 skipped, 0 failed, 3019 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | No (one case's assertions grew) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65688 NLOC, 9818 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +2 NLOC; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
