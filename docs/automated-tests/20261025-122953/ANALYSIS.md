# Analysis — 20261025-122953

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.78.0`; `addonVersion` reads the newest pushed
  tag because a library repo has no TOC; the local `v1.78.0` tag is re-cut on the commit that adds
  this bundle)
- **Verdict:** green
- **Commit:** dfbd0a1 (`feat/2026-10-25-skinning`), clean
- **Previous run:** 20261025-113223 (release run at `d8ac604`, after LK-A1).

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, 0 functions over CCN 15. **Perf was not measured**: the repository ships no
`tests/perf.lua`, so v1.78.0 is verified across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a second time after its local tag, before any push. LootHistory's LH-03 found a
library gap: the skin schema had no bind-state colors. `LK-A2` (`dfbd0a1`, SkinDefs minor 5, Skin key
4.5.2.1.1.1.1) adds nine Semantic tokens (`sem.bound*`, `sem.bound*Alt`, `sem.danger`) whose Ka0s
Default values are LootHistory's current constants, with Azeroth and High Contrast overriding for a
3:1 contrast floor.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261025-100830 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3004 passed, 2 skipped, 0 failed, 3006 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: +2 (LK-A2 token and contrast cases) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65399 NLOC, 9782 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +59 NLOC, +3 functions; max CCN 15 at both |

## Release gate

Holds: clean tree, release 1.78.0, three suites pass, perf skipped and recorded as not measured.
