# Analysis — 20260823-183503

- **Addon:** LibKa0s 1.9.1 (manifest `release` 1.9.2 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** 63d79df (master, dirty)
- **Previous run:** [`20260823-150620`](../20260823-150620/) — the pre-tag release run for v1.9.1

## Headline

Green, and the **release run for v1.9.2** (`docs/releasing.md` step 7). Both gating suites pass —
`luacheck` clean over 13 files, 517 of 517 harness cases with nothing skipped — and `complexity`
records zero functions above CCN 15 for the tenth consecutive run.

**The payload grew by a quarter and almost none of it is visible here.** The icon set goes 49 → 113
and seven generated statusbar textures join it: `LibKa0s/media/` is 473,590 bytes against 373,733 at
v1.9.1 — +99,857, of which the textures are 2,548 (they are two-color and compress to 364 bytes
each). Lua NLOC moves by 83, which is the catalog listing 64 more strings and one new accessor. Every
suite in this battery measures Lua, so the whole art delta reaches these numbers as a table of
names.

That is the standing gap this repo now carries, and it is worth restating each release rather than
noting once: **nothing here opens a TGA.** `tests/test_media.lua` checks the catalogs against the
directories in both directions — a name with no file, a file with no name, and now a texture key that
reads like a filename — but not that a file is a valid 64×64 or 256×32 image. A corrupt or
wrong-sized texture passes this battery and draws nothing in the client, silently.

Tests are up 3 on v1.9.1: the texture inventory case, the extensionless-path case for `Texture`, and
the key-is-the-label case. The last one is the interesting one to keep — it asserts that every
`TEXTURES` key reads as a display label and every file reads as a path, because that key is the
string a player's profile stores and a texture registered under its filename would leave them with a
saved setting that looks like a path in every dropdown that shows it.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260823-150620` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 13 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 517 passed, 0 skipped, 0 failed, 517 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+3 cases** — the three texture cases |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +83, functions +4**; max CCN unmoved at 14 |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 8952 | 8869 |
| Functions | 1274 | 1270 |
| Average NLOC | 6.4 | 6.4 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 49.1 | 48.9 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

`Media.lua`'s largest function is `RegisterLSM` at CCN 6, up from 4 — it walks two catalogs now
instead of one. Nothing else in the file branches at all.

## What this run does not cover

- **The art itself**, as above — the largest thing in this release is the thing least measured here.
- **The generator's determinism.** `bar_textures.py` is pure synthesis, so re-running it must leave
  `git status` clean. Nothing asserts that; it is a manual check at the moment the art changes.
- **The vendored payload in a consumer.** Kit revision 11's recursion and binary compare have still
  only run against this repo's own copy — MythicMeters exercises them on the re-vendor that follows
  this tag, and that is the first real test of both.
- **LibSharedMedia's real behaviour.** `RegisterLSM` is driven against a stub, and the statusbar
  registration is new. That the real LSM accepts the triple, and that seven textures then appear in a
  consumer's bar-texture dropdown under their Ka0s names, is an in-game check and belongs in that
  consumer's smoke tests.
