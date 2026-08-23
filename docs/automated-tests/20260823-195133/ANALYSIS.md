# Analysis — 20260823-195133

- **Addon:** LibKa0s 1.10.0 (manifest `release` 1.10.1 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** 407cbf4 (master, dirty)
- **Previous run:** [`20260823-191126`](../20260823-191126/) — the pre-tag release run for v1.10.0

## Headline

Green: `luacheck` clean over 13 files, 528 of 528 harness cases, complexity zero above CCN 15 for the
eleventh consecutive run. The numbers barely move — NLOC +8, two cases — because this is a patch
release correcting two things v1.10.0 got wrong in the one window it was about.

**The defect is the interesting part of this bundle, because nothing here could have caught it.**
`lib.MakeCloseButton` is a forwarder onto Core's, and it took two arguments where Core's had grown a
third. v1.10.0 therefore shipped a console whose copy and clear drew the collection's art beside a
close button that was still a multiplication sign — and every suite in the previous bundle was green
while that was true.

A dropped argument is not a failure any layer can report: Core saw no addon name and drew exactly
what it draws without one, which is a perfectly good button. The console's own tests asserted on
`copyButton.icon` and `titleBarOffsets`, both of which were correct. The only symptom was the look,
and the only thing that could see it was a screenshot from a live client. **The gap it exposes is the
one this repo already lists every release and did not act on: nothing here draws a pixel.** Two cases
now pin the argument itself rather than the appearance — that the console hands its close factory the
name for both windows, and that the forwarder passes it through to Core — which is the closest an
out-of-game suite can get to the real property.

The tooltip removal came from the same screenshot: it anchored under the control, on top of the first
line of the log.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260823-191126` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 13 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 528 passed, 0 skipped, 0 failed, 528 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+2 cases** — the two forwarder cases; the tooltip case was rewritten in place to assert its absence |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +8**, functions +4; every average and the max unmoved |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 9126 | 9118 |
| Functions | 1313 | 1309 |
| Average NLOC | 6.3 | 6.3 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.8 | 48.9 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

Removing the tooltip took `makeIconButton` from CCN 4 to 1 and dropped its unused `label` parameter,
which `luacheck` caught the moment the body stopped reading it.

## What this run does not cover

Unchanged, and this release is the argument for saying it plainly rather than listing it:

- **That any of it draws.** No suite renders a pixel, and this release exists because of something
  only a rendered pixel could show.
- **The `d.name` trap** — a host passing the frame-name field as `addonName` gets a path into
  nowhere, and from inside the library the two strings are indistinguishable.
- **The art itself, and LibSharedMedia's real behaviour.**
