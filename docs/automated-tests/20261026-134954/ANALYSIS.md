# Analysis — 20261026-134954

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  which is now the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the
  commit that adds this bundle.
- **Verdict:** green
- **Commit:** f759a5e (`feat/2026-10-25-skinning`), clean
- **Previous run:** 20261025-134526 (release run at `d6b5bec`, after LK-A3).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a fourth time after its local tag, still before any push. In the owner's smoke
test, moving LootHistory from WoW Forever to WoW Midnight crashed the client with a
`STACK_OVERFLOW` inside `EditBox:SetFontObject`. `LK-A4` is the fix: `1e21c1f` (SkinPaint minor 3,
Skin key 4.6.3.1.1.1.1) and its review follow-up `f759a5e`.

- The client's EditBox answers `GetFontObject` with an anonymous font object, so `P.font` now
  records a prior font object only when it is a named font that is not the target itself.
  Otherwise it records the face and puts it back by path, along with the target's own shadow.
- `P.unfont` re-checks the recorded object before handing it back.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261025-134526 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3007 passed, 2 skipped, 0 failed, 3009 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: +1 (the LK-A4 EditBox case) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65522 NLOC, 9798 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +52 NLOC, +14 functions; max CCN 15 at both |

The complexity delta covers `namedFont` and `priorOf` in `SkinPaint.lua`, plus the new test case
and its fake EditBox's methods. No function moved above CCN 15.

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
