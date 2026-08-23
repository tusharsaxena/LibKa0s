# Analysis — 20260823-144602

- **Addon:** LibKa0s 1.8.3 (manifest `release` 1.9.0 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** a2297b509207636066b33066248609bfd8f72df7 (master, dirty)
- **Previous run:** [`20260807-151331`](../20260807-151331/) — the pre-tag release run for v1.8.3

## Headline

Green, and the **release run for v1.9.0** (`docs/releasing.md` step 7). Both gating suites pass —
`luacheck` clean over 13 files, 513 of 513 harness cases passing with nothing skipped — and
`complexity` records zero functions above CCN 15 for the eighth consecutive run, so
`automated-tests-§3`'s release gate is met.

The numbers move for a reason with no precedent in this repo: **v1.9.0 is the first release to ship
something that is not code.** `LibKa0s-Media-1.0` adds one Lua file and, behind it,
`LibKa0s/media/` — 49 icon TGAs and a font, 472KB of payload where every previous release measured
in kilobytes of text. None of that weight appears in any figure below, and that is the point worth
recording: **lint, lizard and the harness all measure Lua**, so a payload of binaries is invisible to
every suite in the battery except the one case in `tests/test_media.lua` that lists the directory and
compares it against the catalog. If the art and the catalog ever disagree, that case is the only
thing in this bundle that will say so.

`luacheck`'s file count goes 12 → 13 (`LibKa0s/Media.lua`, which is inside `.luacheckrc`'s checked
set, so its 0/0 is a real 0/0). Tests are up 11 (502 → 513): nine new `media:` cases and two the kit
change did not add but did have to keep green.

**The kit moved, and that is the item to carry forward.** Revision 11 changes `vendor_sync.lua` — the
gate every consumer runs against its own vendored payload — so the blast radius of this release is
larger than the module it publishes. It is covered here only indirectly: this repo runs the gate
against itself (`tests/test_kitsync.lua` proves `testkit/` and `tests/_kit/` are byte-identical), but
the recursion and binary-compare paths it fixes are exercised for real only in a consumer, against a
tag whose payload has a subdirectory — which does not exist until v1.9.0 is tagged. **MythicMeters is
the first consumer to run it, and until it does, those two paths are tested by construction rather
than in anger.**

## Suites

| Suite | Status | Result | Artifact | Moved since `20260807-151331` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 13 files | [`lint.txt`](lint.txt) | **+1 file** — `LibKa0s/Media.lua`; still clean |
| tests | pass | 513 passed, 0 skipped, 0 failed, 513 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+11 cases** — nine `media:` cases plus the two `prose:` cases the directory-skip fix kept green |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip, see below |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +186, functions +20**; max CCN unmoved at 14 |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`, totals and averages both:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 8862 | 8676 |
| Functions | 1269 | 1249 |
| Average NLOC | 6.4 | 6.3 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.9 | — |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

Nothing in `Media.lua` comes near the band: its largest function is `RegisterLSM` at CCN 4, and the
rest are a table lookup and a concatenation apiece. The max of 14 is where it has been for eight
runs, in code this release did not touch.

## Why `perf` is a skip and not a pass

This repo ships no `tests/perf.lua`, so the suite has no scenarios to run. **A skip is not a pass** —
it is a suite that did not run at all, and `automated-tests-§3`'s release gate is four suites at
`pass`. The gate is therefore met on three of four with one standing, recorded hole, exactly as it
was at v1.8.0 through v1.8.3. See [`README.md`](../README.md) for why a library with no in-game
pipeline has nothing to measure offline, and why that judgement is worth re-examining now that the
library ships art: a texture path is not a hot loop, but `Media.Icon` is called once per control per
layout pass in the consumer, which is the first thing here that a consumer's own perf run will see.

## What this run does not cover

- **The art itself.** No suite opens a TGA. `tests/test_media.lua` checks that every catalog name has
  a file and every file has a name, and that each font ships beside its license — it does not check
  that a file is a valid 64×64 white RGBA TGA. A corrupt icon passes this battery and draws nothing
  in the client, silently, which is the failure mode the whole module is written around.
- **The vendored payload in anger.** See the headline: kit revision 11's recursion and binary compare
  land for real in the first consumer to re-vendor v1.9.0.
- **LibSharedMedia's real behaviour.** `RegisterLSM` is driven against a stub. That the real LSM
  accepts the triple, and that the face then appears in a consumer's font dropdown, is an in-game
  check and belongs in the consumer's smoke tests.
