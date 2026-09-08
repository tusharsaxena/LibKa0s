# Analysis — 20260908-181447

- **Library:** LibKa0s 1.27.0
- **Verdict:** green
- **Commit:** e1377a3 (`feat/2026-09-07-audit-review-remediation`), clean
- **Previous run:** [`20260907-235828`](../20260907-235828/) — the v1.27.0 release run

## Headline

Three suites pass and one is a permanent skip. Lint 0/0 over 51 files, 795 cases with none failed and
none skipped, `lizard` warns on nothing at max CCN 14 across 1993 functions, and `perf` skips because
this repository ships no `tests/perf.lua`.

This is a small run by design. The previous one was the **v1.27.0 release bundle**, and the library
has moved four test cases and 188 NLOC since. What makes this bundle worth taking is not the delta;
it is that this is the library's own first run through the runner it owns.

## The kit's own repository could never run the kit

`testkit/run-automated-tests.sh` lives here and is vendored whole into ten repositories. Until kit
revision 14 it required a `.toc` to establish identity and version, and an embeddable library has no
`.toc` — it is loaded by its host's. So the one repository that owns the runner was the one
repository that could not execute its output path, which is why two kit bugs survived five revisions.
Identity now falls back to the repo directory and version to the newest semver tag.

The consequence is visible two rows up in the table. `20260907-235828`'s Version cell reads
**`1.26.0 → 1.27.0`**, because `--release` runs before the tag exists and a cell rendering the
current version alone would attribute a release's evidence to its predecessor. This library's own
record used to do exactly that.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260907-235828` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 51 files | [`lint.txt`](lint.txt) | 49 → 51 files; 0/0 unchanged |
| tests | pass | 795 passed, 0 skipped, 0 failed, 795 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | 791 → 795 |
| perf | skip | no `tests/perf.lua` | — | Unchanged, and permanent |
| complexity | pass | 0 warnings, max CCN 14 | [`complexity.txt`](complexity.txt) | Flat: same max, same band, same cap set |

**On the `perf` skip.** The first of `automated-tests-§3`'s two sanctioned reasons — *nothing to
run*. The library ships `LibKa0s/Perf.lua`, the in-game capture harness every host addon uses, and
has no offline scenarios of its own; the record is therefore silent about the library's own runtime
cost. A skip is never a pass, and at the release gate it is NOT EVALUATED.

**Complexity in full.**

| Metric | `20260907-235828` | This run |
|---|---|---|
| Total NLOC | 14376 | 14564 |
| Functions | 1983 | 1993 |
| Avg NLOC / function | 6.6 | 6.7 |
| Avg CCN | 2.0 | 2.0 |
| Max CCN | 14 | 14 |
| Avg tokens / function | 51.3 | 51.5 |
| Warnings (CCN > 15) | 0 | 0 |
| Files 1000–1500 | 5 | 5 |
| Files over 1500 | 2 | 2 |

The three highest are the kit's own `(anonymous)@125-166` in `testkit/test_eol.lua` (14) and two in
`LibKa0s/Widgets.lua`, `list@1178-1219` (13) and `paintMenuRow@126-159` (13). Nothing is near the
threshold.

## What moved

- **lint** — 49 → 51 files at 0/0.
- **tests** — 791 → 795. `docs/test-cases.md` is byte-identical to this bundle's
  [`test-cases.md`](test-cases.md), and this repository ships no README test badge — it is a library
  repo, and `library-stack-§7`'s applicability list is what binds here — so no count claim moves in
  this commit.
- **complexity** — nothing. Same maximum, same five band files, same two over the cap, every one at
  the line count it carried at the release run.

## The band, and the file seven lines from breach

Five files on notice and two over the cap, all seven with a disposition:

- **`tests/test_widgets.lua` at 1493** is the one to read. It is seven lines under `layout-§1`'s
  1500 cap — the closest any file in this collection sits to it. It grew 951 → 1209 → 1296 → 1350 →
  1493 through the ReorderList and settings-revamp-v2 work and has been flat since. It mirrors
  `LibKa0s/Widgets.lua` and so has no seam of its own; a suite that peels before its module commits
  to a partition the module has not chosen. The next case added to it puts this library in breach,
  and it wants an owner before it crosses rather than after.
- `LibKa0s/OptionsWidgets.lua` (1989) and `tests/test_options_widgets.lua` (2398) are the two
  breaches, both ruled on at `M4-14` and tracked as issues **#16** and **#8**.
- `LibKa0s/Perf.lua` (1206) is issue **#7**, and it is not a violation — the file is under the cap,
  and the issue records the band position rather than a breach.
- `tests/test_options.lua` (1266) crossed at `20260807-151331` by one line and carries its own note.
- `LibKa0s/Options.lua` (1036) is 36 lines into the band and 464 clear of the cap.

## The `ANALYSIS.md` gap, noted once, and this repository is where most of it is

Twenty of this repository's thirty-four bundles carry no `ANALYSIS.md` — more than half, and the
majority of the collection's whole gap. None of the nineteen older ones is getting one. Writing an
analysis today into a folder stamped in August would date a reading to a day nobody took it, which is
worse than a gap, because a gap is legible and a backdated record is not. Fixed forward: this bundle
has one, and every bundle from here gets one at the time of its run. Collection-wide the gap stands
at 37 of 95.

The reason it is concentrated here is that this repository runs the battery on every version bump —
thirty-four bundles against seven to nine in each addon. What is **not** an excuse, and is worth
writing down rather than leaving to be inferred: **thirty of the thirty-four are release runs, and
nineteen of those thirty carry no `ANALYSIS.md`.** The standard MUSTs an analysis for a release run
specifically. So these are not ordinary intermediate runs missing an optional file; they are the
exact case the rule names, from v1.11.0 through v1.27.0 with barely a break, and the v1.27.0 bundle
immediately before this one is among them.

That is a real gap and it is not closed by backfilling. An analysis is a reading taken at a run, and
one written a month later into a folder stamped in August is a different artifact wearing the same
name. It closes by every release run from here writing one at the time, which
`/wow-addon:bump-version` is the place to enforce.

## Actions

None in this bundle. `tests/test_widgets.lua` is the one thing to act on before it acts on its own,
and it belongs in the issue store rather than here.
