# Analysis — 20261027-005758

- **Addon:** LibKa0s 1.78.0 (release run, `--release 1.78.0`). `addonVersion` reads the newest tag,
  the local `v1.78.0`, because a library repo has no TOC. That tag is re-cut on the commit that adds
  this bundle.
- **Verdict:** green
- **Commit:** 854ad32 (`feat/2026-10-26-skin-feedback`), clean
- **Previous run:** 20261027-001339 (release run at `f70882c`, after SF-35).

## Headline

Three suites ran and all are green. The release gate's conditions hold, per
[`manifest.json`](manifest.json): `release` is `1.78.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, no function is over CCN 15, and `blindFiles` and `crashedFiles` are both 0.
**Perf was not measured**, because the repository ships no `tests/perf.lua`. So v1.78.0 is verified
across **three** suites, not four.

## Why this run exists

v1.78.0 was extended a tenth time after its local tag, still before any push, with `SF-38` of
Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`: `fb8ff61` and `854ad32`. The Appearance tab's
Scope, "Ignore settings panel" and "Ignore fonts", per addon and copied with the skin (Skin minor 5,
SkinPaint minor 8, SkinAce minor 3, OptionsScroll minor 7, OptionsAppearance minor 2), and a page's
backdrop is never the page itself. Skin key 4.8.7.3.5.1.2 -> 5.8.8.3.5.1.3; Options key
33.3.35.4.6.10.3.12.6.3.2.5.1 -> 33.3.35.4.6.10.3.12.7.3.2.5.2.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261027-001339 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 223 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 3027 passed, 2 skipped, 0 failed, 3029 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | +8 cases (the Scope, the self-backdrop) |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 65926 NLOC, 9833 functions, avg CCN 2.0, max CCN 15, 0 warnings | [`complexity.txt`](complexity.txt) | +227 NLOC, +23 functions; max CCN 15 at both |

## Release gate

The gate holds: clean tree, release 1.78.0, three suites pass, and perf is skipped and recorded as
not measured.
