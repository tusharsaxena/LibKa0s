# Analysis — 20260823-235820

- **Addon:** LibKa0s 1.10.1 (manifest `release` 1.10.2 — the pre-tag release run, see below)
- **Verdict:** green
- **Commit:** 3a8be91 (master, dirty)
- **Previous run:** [`20260823-195133`](../20260823-195133/) — the pre-tag release run for v1.10.1

## Headline

Green: `luacheck` clean over 13 files, 531 of 531 harness cases, complexity zero above CCN 15 for the
twelfth consecutive run. NLOC +42, three cases — a one-line fix and the three cases that pin it.

**This bundle is the previous one's argument, restated by the same defect one window over.**
v1.10.1's analysis said the gap it exposed was "the one this repo already lists every release and did
not act on: nothing here draws a pixel." Three hours later a screenshot from a live client found the
identical dropped argument in `PerfPanel.lua` — `Core.MakeCloseButton(frame, P.HidePanel)`, two
arguments onto the three-argument function Core grew at minor 6 — so a host that passed no `decorate`
hook got a perf panel wearing × beside a debug console wearing the mark. Everything in this bundle was
green while that was true, and everything in the previous one was green while its own instance was.

Twice is a shape. What separates it from an ordinary regression is that **no layer can report it**:
Core receives no addon name, builds no texture path, and returns a perfectly good button. A texture
path that is never built draws nothing and **raises nothing**, so there is no error to log, no
warning to lint, and nothing an assertion can reach — the correct button and the wrong button are
indistinguishable to every question this harness knows how to ask.

The response is therefore not another case; it is a rule and a grep. `standalone-windows` now makes
the one-wrapper-per-addon pattern a **MUST** (Ka0s WoW Addon Standard v2.32.0, anti-pattern #65), and
`AUDIT.md` runs `grep -rn 'MakeCloseButton(' --include='*.lua' | grep -v '/libs/'` as a mechanical
check with a stated expected output. The wrapper does not make the mistake impossible. It makes it
**greppable**, which is the most an out-of-game toolchain can offer for a defect none of it can see.

Three cases were still added, and they follow v1.10.1's rule of testing the **argument** rather than
the appearance: the fallback path reaches Core with the name, a descriptor `addonName` wins over
`name`, and a host supplying `decorate` gets no close button from the library at all — the last one
pinning the exclusivity of the two paths, which is a stacked-button bug nothing else would catch.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260823-195133` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 13 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 531 passed, 0 skipped, 0 failed, 531 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+3 cases** — the three close-button cases in `test_perf_panel.lua` |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +42**, functions +7; every average and the max unmoved |

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 9168 | 9126 |
| Functions | 1320 | 1313 |
| Average NLOC | 6.3 | 6.3 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.7 | 48.8 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

The NLOC and function growth is entirely the three new test cases and their spy closures. The shipped
change is one argument on one line; `EnsureFrame`'s CCN is unmoved, because `d.addonName or d.name`
adds a short-circuit inside an expression `lizard` already counted the branch of.

## What this run does not cover

Unchanged from v1.10.1, and now stated for the second release running — which is itself the finding:

- **That any of it draws.** No suite renders a pixel, and this is the second consecutive release that
  exists because of something only a rendered pixel could show. Both were found by the same person
  looking at two windows side by side.
- **The `d.name` trap** — a host passing the frame-name field where a folder name is wanted gets a
  path into nowhere, and from inside the library the two strings are indistinguishable. `PerfPanel`
  minor 4 now takes `addonName` precisely so a host where they diverge has somewhere to say so; that
  a host might pass the wrong one remains untestable from here.
- **A call site in a consumer.** This harness loads the library, not the addons that vendor it, so
  the two-argument call that produced this release lived in a file no suite in this repo reads. That
  is what moved the check upstream into the standard's audit playbook rather than into `tests/`.
- **The art itself, and LibSharedMedia's real behavior.**
