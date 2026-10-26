# Analysis — 20261026-181407

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** fcdbb68 (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261026-134954 (release run at `f759a5e`, after LK-A4).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a fifth time after its local tag, still before any push, with the owner's notes
on the skins (`SF-01`..`SF-14` of Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`):

- `a8bb0ad` (SkinDefs minor 7): Azeroth, Glass, Obsidian, High Contrast and WoW Midnight retuned.
- `fcdbb68` (SkinPaint minor 4, SkinPaintControls minor 2): font sizes relative to Ka0s Default's,
  one owner font object per role and size, a distinct row hover, a dimmed disabled button label,
  Ka0s Default's square checkbox, WoW Default's single checkbox box and WoW Forever's filled primary.

Skin key 4.6.3.1.1.1.1 -> 4.7.4.1.2.1.1.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261026-134954 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3012 passed, 2 skipped, 0 failed, 3014 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: +5 (the round's new cases) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65626 NLOC, 9810 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +104 NLOC, +12 functions; max CCN 15 at both |

The complexity delta is `P.fontSize`, `enabled` and `buttonLabel` and the new test cases. The functions
at CCN 15 are the ones already there (`Sl.CliSet`, `lib.ReorderList`, `lib.GetSpellCooldown`); none of
this round's is near it.

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
