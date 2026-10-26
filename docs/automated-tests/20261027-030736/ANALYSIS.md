# Analysis — 20261027-030736

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** 42b04c1 (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261027-015805 (release run at `0920b9a`, after SF-41).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a twelfth time after its local tag, still before any push, with `SF-44` of
Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`: `42b04c1`. `scroll.thumbFill`, a flat fill
over the scroll bar's own thumb, for Obsidian, High Contrast, Ember, WoW Default and WoW Midnight
(SkinDefs minor 9, SkinPaintControls minor 6). Skin key 5.8.8.3.5.1.3 -> 5.9.8.3.6.1.3.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261027-015805 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3030 passed, 2 skipped, 0 failed, 3032 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +2 cases (the thumb fill) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 66080 NLOC, 9849 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +73 NLOC, +9 functions; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
