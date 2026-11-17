# Analysis — 20261117-113302

- **Addon:** LibKa0s 1.105.0 (release run, `--release 1.105.0`; `addonVersion` is the tag the
  runner's `git describe` found nearest this commit, the local, unpushed `v1.105.0`, still cut at
  `11f8d3f`, and `release` is the version this run is for)
- **Verdict:** green
- **Commit:** `12cf13d` (`feat/2026-11-16-libka0s-75-plus`), clean: the fourth `SR2-REL` record
  commit, the v1.105.0 release record amended for `SR2-L5` (Ka0sAddonsCommonTasks
  `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR2_SMOKE_ROUND2.md`, the owner's option C of the
  `SR2-L3` review call, 2026-11-17). Since the previous run the branch gained the third re-close's
  run commit, `SR2-L5` (a primary button hovers by its fill) and this record commit. v1.105.0 is
  not released, so this is the same release re-measured: SkinDefs minor 28 and SkinDefsOthers
  minor 10 are reused, SkinPaintControls moves 17 -> 18 (its one bump on this branch), the Skin key
  is 18.1.28.10.19.19.1.1.18.4.9, and the kit stays at revision 57. The record (this bundle, its
  `RESULTS.md` row and the changelog's release-gate line) follows as one commit; none of it is read
  by a suite.
- **Previous run:** [`20261117-105631`](../20261117-105631/) (at `b3b5c24`), the third re-close,
  now three commits behind.

## Headline

Green on the three suites that ran, and the release gate's conditions hold off
[`manifest.json`](manifest.json): `release` is `1.105.0`, `git.dirty` is `false`, lint, tests and
complexity are `pass`, `complexity.warnings` is 0, max CCN is 15, `blindFiles` and `crashedFiles` are
0. **Perf was not measured**: this repository ships no `tests/perf.lua`, so v1.105.0 was verified
across **three** suites, not four. No function is above CCN 15, so no split was needed.

## Suites

| Suite | Status | Result | Artifact | Moved since 20261117-105631 |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 372 files | [`lint.txt`](lint.txt) | No |
| tests | pass | 4944 passed, 3 skipped, 0 failed, 4947 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | Yes: 4934 -> 4947 |
| perf | skip | not measured: no `tests/perf.lua` | none | No (still skip) |
| complexity | pass | 0 over CCN 15, max 15 | [`complexity.txt`](complexity.txt) | Yes: NLOC, function count |

| Metric | Value |
|---|---|
| Total NLOC | 111148 |
| Functions | 15939 |
| Avg NLOC / function | 6.8 |
| Avg CCN | 2.1 |
| Max CCN | 15 |
| Avg tokens / function | 60.7 |
| Warnings (CCN > 15) | 0 |
| Warning rate (`Fun Rt` / `nloc Rt`) | 0.00 / 0.00 |
| Files in the 1000–1500 band | 13 |
| Files over the 1500 cap | 0 |
| Blind files (parity mismatch) | 0 |
| Crashed files (lizard raised) | 0 |

Perf is the one suite that is not a clean pass: a standing skip, not a regression, because the
repository ships no offline scenarios (see [`../README.md`](../README.md)).

## What moved

- **Payload:** three files of the Skin major. `SkinDefs.lua` (minor 28, reused): the tokens
  `btnPrimary.hoverBg` (color) and the optional pair `btnPrimary.hoverBgTop` /
  `btnPrimary.hoverBgBottom`, Ka0s Default's hover fill its link orange at half. `SkinDefsOthers.lua`
  (minor 10, reused): each skin's own primary hover fill, a gradient pair exactly where its
  `btnPrimary.bg` is one. `SkinPaintControls.lua` (minor 17 -> 18): `S.Button`'s primary repaints
  its box in `btnPrimary.hoverBg` on enter and `btnPrimary.bg` on leave, its label kept at
  `btnPrimary.text`; a disabled primary does not hover, and a remapped `bg` without a `hoverBg`
  keeps its fill. No kit file changed.
- **Contract changes:** the Skin key moves to 18.1.28.10.19.19.1.1.18.4.9 (its document and members
  manifest, renamed in `SR2-L5`). No member moved, so the members manifest lists the same surface.
  The `CHANGELOG.md` block's re-pin list carries the `SR2-L5` line (a case pinning a primary's
  hovered label at `btnPrimary.hover` or its fill unchanged under the pointer, a host list of the
  schema's names, and a host skin that sets its own `btnPrimary.bg` without a `hoverBg`, which
  resolves to Ka0s Default's). The `SR2-L3` exemption of four primaries is gone.
- **Lint:** 372 files, unchanged.
- **Tests:** 4934 -> 4947 (4931 -> 4944 run): `tests/test_footer_button_hover.lua` 33 -> 46, the
  exemption and its pins removed and replaced by the fill floor (ΔE00 of rest and hover fill at
  least 20 in every skin), the label's contrast on the hover fill, the gradient pairing, and the
  skin picker's Apply repainting its fill and back in all nine skins. The three skips are still
  declared skips, not passes.
- **Complexity:** NLOC 111036 -> 111148 and functions 15927 -> 15939. Avg NLOC, avg CCN, avg tokens
  and the max did not move.

## Complexity watch list

### Functions the complexity suite warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/SkinPaintControls.lua` | 1092 | Moved by `SR2-L5` (1073 -> 1092 at minor 18), 8 under its 1100 trigger. The minor half of its trigger fires again; the peel adds a shipped file and a re-vendor, so it is the lead's and the owner's call (`CLAUDE.md`'s band census row) |
| 1000–1500 (on notice) | the other twelve files of the previous run | see [`../RESULTS.md`](../RESULTS.md) | Unchanged by `SR2-L5`. `LibKa0s/OptionsSkinPicker.lua` holds at 1399 (1 under its 1400 trigger). `LibKa0s/Skin.lua` (1121, trigger 1100) and `tests/test_media.lua` (1048, the next-face trigger) still carry triggers that fired before this release, left to the lead |

Thirteen, nothing over 1500. `LibKa0s/SkinDefs.lua` (553), `LibKa0s/SkinDefsOthers.lua` (893) and
`tests/test_footer_button_hover.lua` (327) stay out of the band.

## Preview and simulation data

- **Answer:** Refreshed (the release's answer stands; `SR2-L5` adds nothing to it)
- **Asked:** 2026-11-17, by hand
- **Files reviewed:** the `git log` of `LibKa0s/Sim*.lua`, `LibKa0s/Widgets.lua`,
  `tests/fixture_sim_panel.lua`, `tests/test_sim_*.lua` and `tests/test_widgets_teststrip.lua`
  since the previous run.
- **Commits since the previous run touching them:** 0
- **Note:** `SR2-L5` moves a primary button's hover in the Skin major only (SkinDefs,
  SkinDefsOthers, SkinPaintControls); no Sim or Widgets minor and no fixture moved.

## Actions

1. Re-cut the local tag `v1.105.0` (the lead), after this record commit: it still points at
   `11f8d3f`, the first re-close's record commit, which precedes `SR2-L3`, `SR2-L4` and `SR2-L5`.
   Push the tag only on the owner's go-ahead.
2. Re-copy the re-cut tag into every addon (`SR2-<ABBR>` of the same bundle), with the amended
   *What a consumer owes* in each re-vendor commit; a host suite that pins a moved token value, a
   sim button's hover color, a 2px popup or menu edge, or a primary's hovered label or unchanged
   fill re-pins it, and a host skin that sets its own `btnPrimary.bg` adds a `btnPrimary.hoverBg`.
3. **Owner call carried from `SR2-L3` is settled:** option C (`SR2-L5`) ends the four-primary
   exemption.
4. **Standards pointer:** v2.112.2, unchanged (`SR2-STD`'s v2.113.0 wording is unreleased).
5. **Band:** `LibKa0s/SkinPaintControls.lua` (1092, minor half fired), `LibKa0s/Skin.lua` and
   `tests/test_media.lua` carry fired triggers, the lead's rulings.
6. **Kit note**, carried: `tests/_kit/run-automated-tests.sh` refuses a git worktree, so release runs
   need the main checkout or a clean clone.
