# Analysis — 20261026-222042

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** e1fca8b (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261026-193808 (release run at `ce9a2a3`, after the third round of skin notes).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended an eighth time after its local tag, still before any push, with the owner's fourth
round of skin notes (`SF-30`, `SF-31`, `SF-32` of Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`):
`afbcb85`. Ka0s Default sets every token and no primitive branches on it (SkinDefs minor 8, SkinPaint 6,
SkinPaintControls 4, SkinAce 2), Azeroth is dark, WoW Forever wears Atkinson Hyperlegible. Skin key
4.7.5.2.3.1.1 -> 4.8.6.2.4.1.2.

A first release run at `afbcb85` (not kept) measured one function at CCN 16: the named-media case in
`tests/test_skin_defs.lua`, which SF-30 grew. `e1fca8b` moves its per-token checks into a helper, and
this run measures the fixed tree.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261026-193808 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3017 passed, 2 skipped, 0 failed, 3019 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Count no; 34 cases restated under the new Ka0s Default rule |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65672 NLOC, 9809 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | -16 NLOC, -9 functions; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
