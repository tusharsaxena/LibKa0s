# Analysis — 20261025-113223

- **Addon:** LibKa0s 1.77.0 (release run, `--release 1.78.0`; `addonVersion` reads the newest pushed
  tag because a library repo has no TOC; the local `v1.78.0` tag is re-cut on the commit that adds
  this bundle)
- **Verdict:** green
- **Commit:** d8ac604 (`feat/2026-10-25-skinning`), clean
- **Previous run:** 20261025-100830 (release run at `dc52324`), the first close of v1.78.0.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, 0 functions over CCN 15. **Perf was not measured**: the repository ships no
`tests/perf.lua`, so v1.78.0 is verified across **three** suites, not four.

## Why this run exists

v1.78.0 was extended after its local tag, before any push. The owner's in-game BugSack showed
LibSharedMedia "invalid file" errors from every addon loading after LootHistory: LootHistory vendors
Media minor 6, LibStub keeps the highest minor, and minor 6's `RegisterLSM` offered the new skin
faces and Glass art at each caller's own (v1.77.0) folder, which lacks them. LSM-3.0 validates the
file before its first-registration-wins check. `LK-A1` (`d8ac604`, Media minor 7) skips a key LSM
already holds. Between the two runs: `fb7b7a3` (CHANGELOG/`releasing.md` only) and `d8ac604`.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261025-100830 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3002 passed, 2 skipped, 0 failed, 3004 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: +1 (the LK-A1 held-key case) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65340 NLOC, 9779 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +43 NLOC, +4 functions; max CCN 15 at both |

## Release gate

Holds: clean tree, release 1.78.0, three suites pass, perf skipped and recorded as not measured.
