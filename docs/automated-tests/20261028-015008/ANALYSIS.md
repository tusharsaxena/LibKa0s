# Analysis — 20261028-015008

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** 3974846 (`feat/2026-10-28-skin-round5`), clean
- **Previous run:** 20261027-030736 (release run at `42b04c1`, after SF-44).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended again after its local tag, still before any push, with `R5-01` to `R5-04` of
Ka0sAddonsCommonTasks `docs/2026-10-28-SKIN_ROUND5/`:

- `247ccf4` R5-01: a scroll corridor and one flat knob in every skin. `scroll.thumbFill` and
  `scroll.thumbTexture` are retired (SkinDefs 10, SkinPaintControls 7, OptionsScroll 8).
- `91513c4` + `8d3142b` R5-02: a window's edge and inner rule drawn on a holder above its children
  (SkinPaint 9).
- `f58852c` R5-03: one font family per skin; Barlow and Cinzel leave the payload (Media 8,
  SkinDefs 11).
- `3974846` R5-04: arrow art desaturated before it is tinted, in `icon.arrow`; WoW Forever's check
  mark in its tan (SkinDefs 12, SkinPaint 10, SkinPaintControls 8).

Skin key 5.9.8.3.6.1.3 -> 5.12.10.3.8.1.3; Media key 7.1 -> 8.1.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261027-030736 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3030 passed, 2 skipped, 0 failed, 3032 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Same total: +2 skin-defs cases (corridor and knob contrast, arrow and check accent), -2 control cases (the retired thumb fill); several cases renamed |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 66175 NLOC, 9855 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +95 NLOC, +6 functions; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.

## Note

One case, "tool windows skin: without a registered owner each window is the previous minors' paint",
failed twice during this round while the machine was under load, and passed in this run and in 40
repeated runs of a snapshot. It may be timing-sensitive; it is recorded here, not waived.
