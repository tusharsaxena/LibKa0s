# Analysis — 20261002-231003

- **Addon:** LibKa0s 1.68.0 (release run, `--release 1.68.0`; `addonVersion` reads 1.67.0, the last tag)
- **Verdict:** green
- **Commit:** 1382135 (`feat/2026-10-02-drag-attach`), clean
- **Previous run:** 20261002-012529 (1.67.0, release run, at `7e07c83`, green)

## Headline

Green on the three suites that ran, off [`manifest.json`](manifest.json): `release` is `1.68.0`,
`git.dirty` is `false`, lint, tests and complexity are `pass`, `complexity.warnings` is 0 and
`complexity.blindFiles` is 0. **Perf was not measured**: this repository ships no `tests/perf.lua`,
so the run covered **three** suites, not four.

**The tag is not cut from this run.** It brought one file into the `layout-§1` 1000–1500 band with no
disposition: `tests/test_widgets_draghandle.lua`, 901 → 1123, with WidgetsDragHandle minor 4's ten
placement-hook cases. This repository's practice is to give such cases a suite of their own while
the seam is obvious (v1.32.0, v1.33.0 and v1.48.0 did), so they peel first (`DA-LK-04`) and the
release run is taken again on that tree. This bundle is committed as the record of a green run that
was superseded, not refused.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261002-012529 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 144 files | [`lint.txt`](lint.txt) | No (144 files, 0/0) |
| tests | pass | 2023 passed, 2 skipped, 0 failed, 2025 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 2015 → 2025 (+10) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 warnings, max CCN 15, 40783 NLOC / 6132 functions | [`complexity.txt`](complexity.txt) | band 6 → 7, blind 0 flat |

**`tests` carries two skips**, the same two as at v1.67.0's release run: the kit's own
`tests/_kit/test_prose.lua`, declined under `CLAUDE.md`'s `localization-§5` deviation row, and the
diagnostics contract's opt-out case, a declared skip in a repo that keeps the default.

## What moved

- **tests**: 2015 → 2025 (+10), all in `tests/test_widgets_draghandle.lua`, for `tooltipPlace`.
- **complexity**: NLOC 40568 → 40783, functions 6095 → 6132, average CCN 2.0 flat, max CCN 15 flat.
  `LibKa0s/WidgetsDragHandle.lua` put the hook in four small helpers (`dhPlacer`,
  `dhTooltipLines`, `dhDrawTooltip`, `dhShowPlaced`), none near CCN 15.
- **band**: 6 → 7, the seventh being `tests/test_widgets_draghandle.lua` (above).

## Actions

1. Peel the placement-hook cases to `tests/test_widgets_draghandle_place.lua` (`DA-LK-04`).
2. Take the release run again on the peeled tree; that bundle carries the release-gate line and the
   tag.
