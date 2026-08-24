# Analysis — 20260824-133151

- **Addon:** LibKa0s 1.11.1 (manifest `release` 1.11.2 — the pre-tag release run)
- **Verdict:** green
- **Commit:** 40861da (feat/widgets-dropdown, dirty)
- **Previous run:** [`20260824-031024`](../20260824-031024/) — the pre-tag release run for v1.11.1

## Headline

Green: `luacheck` clean over 14 files, 555 of 555 harness cases, complexity zero above CCN 15 for the
fourteenth consecutive run. The numbers barely move — NLOC +37, functions +4, two cases — because
this is a patch release fixing one argument in one line.

**The defect is the interesting part of this bundle, and unlike the last one, this suite could have
caught it and did not.** `LibKa0s-Widgets-1.0` built a menu row's optional glyph `FontString` with
no font and then set its text on every paint; the live client answers that with
`FontString:SetText(): Font not set`, so the first click on any dropdown this major built raised —
in every host, not only in one that names no `glyphFont`, because the face is set only on a row that
*has* a glyph and every glyphless row took the same route to the same unconditional `SetText`.

553 cases went green over it. The widget suite's `FontString` stand-in stored any string it was
handed, so a `FontString` with no font was indistinguishable from one with a face. **A consuming
addon had already modelled this exact error** — MultiMeters' `tests/wow_mock.lua` raises it, with a
comment recording the load the live client took down at `BuildFrame` when it hit it. The consumer had
been burned by the class of bug and encoded the lesson; the library it now vendors had not.

So the fidelity moves here too, which is the part of this release worth more than the one-line fix:
`tests/test_widgets.lua`'s frame factory now gives a `FontString` its own identity, records the
template it was built from, and raises on `SetText` when it has neither font nor template. The two
new cases build **real** rows rather than the recording stand-ins every other case seeds, because it
is the row's *creation* that was wrong and a seeded row bypasses `makeMenuRow` entirely — the gap
that let a whole suite pass over a crash on first click.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260824-031024` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 14 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 555 passed, 0 skipped, 0 failed, 555 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+2 cases** — both in `test_widgets.lua`, both building real rows |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +37**, functions +4; every average and the max unmoved |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 9717 | 9680 |
| Functions | 1410 | 1406 |
| Average NLOC | 6.3 | 6.3 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.6 | 48.6 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

The whole NLOC move is test code — the factory's own `SetText`, `GetStringWidth` and
`CreateFontString`, and the two new cases. `Widgets.lua` gains one argument and loses nothing.

## What this run does not cover

Unchanged, and this release is a second argument for saying it plainly:

- **That any of it draws.** No suite renders a pixel. This release does not need one — the mock now
  models the client's own error — but the previous release did, and nothing here has changed that.
- **Every other place a mock is friendlier than the client.** `Font not set` was one; it was found
  because a consumer had met it in a live client, not because anything here looked for it. There is
  no inventory of the rest.
- **The `d.name` trap**, the art itself, and LibSharedMedia's real behavior.
