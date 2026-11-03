# Analysis — 20261101-195248

- **Addon:** LibKa0s 1.85.0 (release run, `--release 1.85.0`, the tag's third local re-cut; the
  manifest's `addonVersion` is read from the newest tag)
- **Verdict:** green
- **Commit:** d9a045a (`feat/2026-11-01-full-skinning`), clean
- **Previous run:** [`20261101-140800`](../20261101-140800/) (`--release 1.85.0`, at `fb01cee`), the
  second re-cut, and the baseline for *What moved* below.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.85.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `complexity.blindFiles` is 0 and
`complexity.crashedFiles` is 0. **Perf was not measured**: this repository ships no
`tests/perf.lua`, so v1.85.0 was verified across **three** suites, not four.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261101-140800 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 289 files | [`lint.txt`](lint.txt) | Yes: 280 → 289 files |
| tests | pass | 3902 passed, 3 skipped, 0 failed, 3905 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 3761 → 3905 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | Yes: 12031 → 12454 functions; max CCN 15 at both, warnings 0 at both |

| Metric | Value |
|---|---|
| Total NLOC | 86231 |
| Functions | 12454 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 59.6 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 9 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

**`perf` was not measured**, for the same sanctioned reason as every run of this repository
(`automated-tests-§3`, no `tests/perf.lua`, nothing to run). The record says nothing about runtime
cost. **`tests` carries three skips**, one more than the previous run. The new one is
`test_skin_values`, declared with no `Kit.skinValues` in this repo's runner, a declared skip and not a pass.

## What moved

Against [`20261101-140800`](../20261101-140800/), six commits: `9776130`, that run's own record;
`430354d`, the owner's rulings of 2026-11-01 and the gaps the flips found; `229e388`, the survivors of
that commit's mutation pass; `97a46c6`, kit revision 50's two suites; `95b5252`, the review of those,
with Media minor 12's `Solid` border; and `d9a045a`, step 8 of `docs/releasing.md`.

- **The rulings.** Eight shipped skins and the eui source state their own `bar.bg`, `bar.border`,
  `icon.border`, `glow.color` and `cover.dim`, Ka0s Default's do not move, and no `sem.*` line moved
  against `v1.84.0`. Azeroth, High Contrast, WoW Default and WoW Midnight take a real
  `bar.borderStyle`. A skin's None defers to the player's Show border and stored style, and a real
  style wins.
- **tests** 144 more cases, mostly `tests/test_skin_host_gaps.lua`, `tests/test_widgets_menu.lua` and
  the kit's two suites.
- **lint** nine more files, the kit's four new ones and five new test files. The copies in `tests/_kit/`
  are outside the checked set.
- **complexity** 423 more functions, max CCN unchanged.
- **the band** is unchanged in membership at nine. `LibKa0s/Skin.lua` moves 1071 → 1090 and
  `LibKa0s/SkinPaint.lua` 1018 → 1023. Two files stand just under its floor: `LibKa0s/Widgets.lua` at
  999 and `LibKa0s/SkinPaintExtras.lua` at 997.

## Mutation pass

Separate from this run, seventeen mutants of the rulings, in a scratch clone: the deferral, its
thickness, a real style winning, the numeric segment, `S.BarBorder`'s three answers, one value per
skin, the real-style list, Ka0s Default's constant, the `Solid` registration, the eui source and the
composer's two `disabledIf` branches. All seventeen failed the case that names them, and a comment-only
control passed.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

Nine, nothing over 1500, none newly crossed. `LibKa0s/Skin.lua` and `LibKa0s/SkinPaint.lua` moved and
their dispositions in `CLAUDE.md` carry the new figures. `LibKa0s/SkinPaint.lua` gained no function, so
the tenth row's trigger does not fire. `LibKa0s/Skin.lua` is 10 under its 1100 trigger.

## Preview and simulation data

- **Answer:** Current
- **Asked:** 2026-11-01, the lead's call under the owner's run guidelines, standing for this re-cut;
  the owner was not asked
- **Files reviewed:** `LibKa0s/Widgets.lua` moved, minors 20 to 21, in the shared menu and the
  dropdown. `lib.TestStrip` and its helpers did not move, past header notes. `Sim.lua`,
  `SimTimeline.lua`, `SimPanel.lua`, `SimPanelRender.lua`, `tests/fixture_sim_panel.lua`, every
  `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua` did not move, and all ran green here
- **Commits since the previous cut touching them:** `430354d`, `229e388`, `95b5252`, on `Widgets.lua`
- **Effect:** look only. The Sim panel's two `W.Dropdown` pickers take the one-line label. No scenario,
  step, control or strip API moved, and step 5's list of hosts stands.

## Actions

1. The local annotated tag `v1.85.0` is deleted and re-cut on the commit that adds this bundle. It was
   never pushed (`git ls-remote` shows no such tag). The branch push, the merge to `master` and the
   tag push wait on the owner.
2. Step 8 re-vendors the re-cut tag into every consumer on the run's branch. Kit revision 50's two
   suites go in each `tests/run.lua` by the pair, and M3's `FS-<p>-GATE` commit adopts them.
3. No host owes a numeric-path repair. AuraMaster and MultiMeters are the two hosts keyed by number,
   and neither handed the library a numeric path.
4. In-client smoke is the owner's and none is marked passed here.
