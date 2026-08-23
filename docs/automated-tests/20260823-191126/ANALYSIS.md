# Analysis — 20260823-191126

- **Addon:** LibKa0s 1.9.2 (manifest `release` 1.10.0 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** 5be1117 (master, dirty)
- **Previous run:** [`20260823-183503`](../20260823-183503/) — the pre-tag release run for v1.9.2

## Headline

Green, and the **release run for v1.10.0** (`docs/releasing.md` step 7). All three evaluated suites
pass: `luacheck` clean over 13 files, 526 of 526 harness cases with nothing skipped, and complexity
back to **zero functions above CCN 15**.

**Back to zero, because the first attempt at this run was not.** v1.9.2 shipped 113 icons that this
library then drew none of; v1.10.0 is the release where its own two windows start using them, and
the icon path added enough branching to `DebugLog.lua`'s `EnsureFrame` to take it to **CCN 16** — one
over `automated-tests-§3`'s release ceiling. That bundle was discarded rather than recorded, the
strip's construction was lifted into `buildTitleControls` (CCN 8), and `EnsureFrame` came down to 5
from the 14 it had been carrying for ten releases. The gate did exactly what it is for: the function
was already the largest thing in the file and this change would have made it permanent.

That is the honest reading of the complexity delta below. NLOC is up 166 and function count up 35 —
almost all of it the new helper, the icon-button factory in `DebugLog` and the two-branch close
control in `Core` — while **average CCN and max CCN are unmoved**. The work got wider, not deeper.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260823-183503` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 13 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 526 passed, 0 skipped, 0 failed, 526 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+9 cases** — five on `MakeCloseButton`, four on the console's title bar |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +166, functions +35**; max CCN unmoved at 14 after the refactor |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 9118 | 8952 |
| Functions | 1309 | 1274 |
| Average NLOC | 6.3 | 6.4 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.9 | 49.1 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

## The new test shapes, and why they look unusual

Five of the nine new cases spy on **calls** rather than reading state back. The kit's stub frame
answers 0 from `GetWidth` forever and no-ops every other capitalized method, so `GetTexture()` on a
headless texture cannot tell you what was drawn on it. `tests/test_core.lua` therefore swaps
`CreateFrame` for a recorder for the duration of a case. That is the kit's documented way round the
limitation, and it is the right assertion anyway: what matters is that the button was handed the path
Media answers with, not that a stub remembered it.

## What this run does not cover

- **That any of this draws.** The whole release is about what two windows look like, and no suite
  here renders a pixel. A close control with a valid path to a missing file, a tooltip that never
  appears, an icon at the wrong size — all pass this battery. The evidence is a screenshot from a
  live client, and it belongs in the consumer's smoke tests.
- **The `d.name` trap.** `DebugLog`'s documentation says plainly not to pass the frame-name field as
  `addonName`; nothing enforces it, because from inside the library the two strings are
  indistinguishable and both produce a path.
- **The art itself, and LibSharedMedia's real behaviour** — unchanged from the last two runs, and
  still the two standing holes in what this repo can check out of game.
