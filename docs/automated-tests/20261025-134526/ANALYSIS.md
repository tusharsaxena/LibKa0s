# Analysis — 20261025-134526

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.78.0`; `addonVersion` reads the newest pushed
  tag because a library repo has no TOC; the local `v1.78.0` tag is re-cut on the commit that adds
  this bundle)
- **Verdict:** green
- **Commit:** d6b5bec (`feat/2026-10-25-skinning`), clean
- **Previous run:** 20261025-122953 (release run at `dfbd0a1`, after LK-A2).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, 0 functions over CCN 15. **Perf was not measured**: the repository ships no
`tests/perf.lua`, so v1.78.0 is verified across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a third time after its local tag, before any push. LootHistory's LH-04 found a
second token gap; `LK-A3` (`d6b5bec`, SkinDefs minor 6, Skin key 4.6.2.1.1.1.1, 235 tokens) adds
eleven tokens (`text.value`, `text.bodyAlt`, `text.subtle`, `text.highlight`, `gtip.value`,
`gtip.subtle`, `icon.dim`, `sem.goodAlt`, `sem.badAlt`, `sem.warbandAlt`, `sem.unknown`) found by one
sweep over every LootHistory surface still to be skinned, each reproducing today's constant exactly
under Ka0s Default.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261025-100830 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3006 passed, 2 skipped, 0 failed, 3008 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: +2 (LK-A3 token and contrast cases) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65470 NLOC, 9784 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +71 NLOC, +2 functions; max CCN 15 at both |

## Release gate

Holds: clean tree, release 1.78.0, three suites pass, perf skipped and recorded as not measured.
