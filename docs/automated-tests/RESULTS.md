# Automated test results

<!-- Regenerated whole by tests/_kit/run-automated-tests.sh on every run. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->
<!-- Everything here is generated EXCEPT the watch list's Disposition column. -->

One row per run. The frozen evidence for each is in the dated folder beside this file;
the analysis of a given run is its `ANALYSIS.md`.

**`lint` and `tests` gate the run and gate the commit** (`testing-§4`).
**`perf` and `complexity` never fail a run and never block a commit** — they are recorded,
read and compared, not thresholded (`performance-§9`, `performance-§10`).

**The tag is gated on all four suites at `pass`, plus zero functions above CCN 15**
(`automated-tests-§3`, *The release gate*), evaluated by `/wow-addon:bump-version` from the
`manifest.json` the release run writes — not by this script, whose exit code is unchanged.

A `skip` is a suite that did not run at all. It is never a pass, and at the release gate it is
**NOT EVALUATED** rather than passed: install the tool and re-run. A `—` is a suite that was
not selected, which is a different fact again.

The **Tests** cell reads `passed/skipped/total`.

| Run | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260921-144300`](20260921-144300/) | 1.49.1 → 1.50.0 | 0/0 | 72 | 1264/0/1264 | skip | 25125 | 3567 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-120741`](20260921-120741/) | 1.49.0 → 1.49.1 | 0/0 | 72 | 1255/0/1255 | skip | 24945 | 3541 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-111809`](20260921-111809/) | 1.48.1 → 1.49.0 | 0/0 | 72 | 1251/0/1251 | skip | 24870 | 3527 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-040120`](20260921-040120/) | 1.48.0 → 1.48.1 | 0/0 | 72 | 1246/0/1246 | skip | 24800 | 3522 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-033457`](20260921-033457/) | 1.47.0 → 1.48.0 | 0/0 | 72 | 1245/0/1245 | skip | 24790 | 3520 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260920-194447`](20260920-194447/) | 1.46.1 → 1.47.0 | 0/0 | 70 | 1211/0/1211 | skip | 24089 | 3401 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-214428`](20260919-214428/) | 1.46.0 → 1.46.1 | 0/0 | 70 | 1195/0/1195 | skip | 23727 | 3351 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-211837`](20260919-211837/) | 1.45.0 → 1.46.0 | 0/0 | 70 | 1189/0/1189 | skip | 23599 | 3335 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-162209`](20260919-162209/) | 1.44.0 → 1.45.0 | 0/0 | 69 | 1168/0/1168 | skip | 23027 | 3250 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-093635`](20260919-093635/) | 1.43.0 → 1.44.0 | 0/0 | 68 | 1159/0/1159 | skip | 22789 | 3222 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260917-201018`](20260917-201018/) | 1.42.0 → 1.43.0 | 0/0 | 67 | 1154/0/1154 | skip | 22700 | 3209 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260917-005828`](20260917-005828/) | 1.41.0 → 1.42.0 | 0/0 | 65 | 1141/0/1141 | skip | 22348 | 3171 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260916-230957`](20260916-230957/) | 1.40.0 → 1.41.0 | 0/0 | 65 | 1141/0/1141 | skip | 22347 | 3171 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260916-212818`](20260916-212818/) | 1.39.0 → 1.40.0 | 0/0 | 65 | 1140/0/1140 | skip | 22323 | 3171 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260916-184458`](20260916-184458/) | 1.39.0 | 0/0 | 61 | 1071/0/1071 | skip | 21225 | 3011 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-130819`](20260916-130819/) | 1.38.0 → 1.39.0 | 0/0 | 61 | 1069/0/1069 | skip | 21193 | 3008 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-093057`](20260916-093057/) | 1.38.0 | 0/0 | 57 | 1044/0/1044 | skip | 20678 | 2929 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-033929`](20260916-033929/) | 1.37.0 → 1.38.0 | 0/0 | 57 | 1044/0/1044 | skip | 20678 | 2929 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-015507`](20260916-015507/) | 1.36.2 → 1.37.0 | 0/0 | 57 | 1042/0/1042 | skip | 20658 | 2927 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260915-140452`](20260915-140452/) | 1.36.2 → 1.36.2 | 0/0 | 57 | 1041/0/1041 | skip | 20635 | 2925 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260915-135323`](20260915-135323/) | 1.36.2 → 1.36.2 | 0/0 | 57 | 1041/0/1041 | skip | 20585 | 2922 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260915-133630`](20260915-133630/) | 1.36.1 → 1.36.2 | 0/0 | 57 | 1040/0/1040 | skip | 20552 | 2920 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260914-010923`](20260914-010923/) | 1.35.0 → 1.35.0 | 0/0 | 57 | 1028/0/1028 | skip | 20354 | 2891 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260914-001514`](20260914-001514/) | 1.35.0 → 1.35.0 | 0/0 | 57 | 1020/0/1020 | skip | 20148 | 2857 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-233500`](20260913-233500/) | 1.35.0 → 1.35.0 | 0/0 | 57 | 1015/0/1015 | skip | 20036 | 2844 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-180115`](20260913-180115/) | 1.35.0 → 1.35.0 | 0/0 | 56 | 972/0/972 | skip | 18454 | 2626 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-094012`](20260913-094012/) | 1.34.0 → 1.35.0 | 0/0 | 56 | 966/0/966 | skip | 18295 | 2603 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-002423`](20260913-002423/) | 1.33.0 → 1.34.0 | 0/0 | 55 | 909/0/909 | skip | 17104 | 2425 | 6.5 | 1.9 | 14 | 0 | **green** |
| [`20260912-214123`](20260912-214123/) | 1.32.0 → 1.33.0 | 0/0 | 55 | 897/0/897 | skip | 16958 | 2405 | 6.5 | 1.9 | 14 | 0 | **green** |
| [`20260912-190219`](20260912-190219/) | 1.31.0 → 1.32.0 | 0/0 | 54 | 885/0/885 | skip | 16622 | 2346 | 6.5 | 1.9 | 14 | 0 | **green** |
| [`20260912-185115`](20260912-185115/) | 1.31.0 → 1.32.0 | 0/0 | 53 | 881/0/881 | skip | 16548 | 2333 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260912-151813`](20260912-151813/) | 1.31.0 → 1.31.0 | 0/0 | 53 | 869/0/869 | skip | 16270 | 2279 | 6.6 | 2.0 | 14 | 0 | **green** |
| [`20260912-145039`](20260912-145039/) | 1.30.0 → 1.31.0 | 0/0 | 53 | 860/0/860 | skip | 16133 | 2252 | 6.6 | 2.0 | 14 | 0 | **green** |
| [`20260912-103140`](20260912-103140/) | 1.29.0 → 1.30.0 | 0/0 | 51 | 819/0/819 | skip | 14918 | 2043 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260912-101914`](20260912-101914/) | 1.29.0 → 1.30.0 | 0/0 | 51 | 814/0/814 | skip | 14836 | 2031 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260908-181447`](20260908-181447/) | 1.27.0 | 0/0 | 51 | 795/0/795 | skip | 14564 | 1993 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260907-235828`](20260907-235828/) | 1.26.0 → 1.27.0 | 0/0 | 49 | 791/0/791 | skip | 14376 | 1983 | 6.6 | 2.0 | 14 | 0 | **green** |
| [`20260907-201015`](20260907-201015/) | 1.25.0 | 0/0 | 18 | 769/769 | skip | 13798 | 1920 | 6.6 | 1.9 | 13 | 0 | **green** |
| [`20260903-161751`](20260903-161751/) | 1.24.0 | 0/0 | 18 | 764/764 | skip | 13678 | 1900 | 6.6 | 1.9 | 14 | 0 | **green** |
| [`20260831-185425`](20260831-185425/) | 1.22.0 | 0/0 | 17 | 705/705 | skip | 12460 | 1768 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260831-180722`](20260831-180722/) | 1.21.0 | 0/0 | 17 | 703/703 | skip | 12414 | 1762 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260831-160633`](20260831-160633/) | 1.20.0 | 0/0 | 17 | 701/701 | skip | 12334 | 1751 | 6.4 | 1.9 | 13 | 0 | **green** |
| [`20260827-153332`](20260827-153332/) | 1.19.0 | 0/0 | 17 | 694/694 | skip | 12116 | 1725 | 6.4 | 1.9 | 13 | 0 | **green** |
| [`20260827-110439`](20260827-110439/) | 1.18.1 | 0/0 | 17 | 672/672 | skip | 11667 | 1675 | 6.4 | 1.9 | 13 | 0 | **green** |
| [`20260826-185819`](20260826-185819/) | 1.18.0 | 0/0 | 17 | 654/654 | skip | 11123 | 1617 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260826-165334`](20260826-165334/) | 1.17.0 | 0/0 | 17 | 653/653 | skip | 11072 | 1606 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-172722`](20260825-172722/) | 1.16.0 | 0/0 | 17 | 649/649 | skip | 11024 | 1598 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-142319`](20260825-142319/) | 1.15.0 | 0/0 | 17 | 647/647 | skip | 10988 | 1596 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-032030`](20260825-032030/) | 1.14.0 | 0/0 | 17 | 628/628 | skip | 10807 | 1570 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-021432`](20260825-021432/) | 1.13.0 | 0/0 | 14 | 587/587 | skip | 10261 | 1482 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260824-185459`](20260824-185459/) | 1.12.0 | 0/0 | 14 | 577/577 | skip | 9917 | 1447 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-153936`](20260824-153936/) | 1.11.2 | 0/0 | 14 | 568/568 | skip | 9847 | 1432 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-133151`](20260824-133151/) | 1.11.1 | 0/0 | 14 | 555/555 | skip | 9717 | 1410 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-031024`](20260824-031024/) | 1.11.0 | 0/0 | 14 | 553/553 | skip | 9680 | 1406 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-024124`](20260824-024124/) | 1.10.2 | 0/0 | 14 | 549/549 | skip | 9640 | 1401 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-235820`](20260823-235820/) | 1.10.1 | 0/0 | 13 | 531/531 | skip | 9168 | 1320 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-195133`](20260823-195133/) | 1.10.0 | 0/0 | 13 | 528/528 | skip | 9126 | 1313 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-191126`](20260823-191126/) | 1.9.2 | 0/0 | 13 | 526/526 | skip | 9118 | 1309 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-183503`](20260823-183503/) | 1.9.1 | 0/0 | 13 | 517/517 | skip | 8952 | 1274 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260823-150620`](20260823-150620/) | 1.9.0 | 0/0 | 13 | 514/514 | skip | 8869 | 1270 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260823-144602`](20260823-144602/) | 1.8.3 | 0/0 | 13 | 513/513 | skip | 8862 | 1269 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260807-151331`](20260807-151331/) | 1.8.2 | 0/0 | 12 | 502/502 | skip | 8676 | 1249 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-114658`](20260807-114658/) | 1.8.2 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-105553`](20260807-105553/) | 1.8.1 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-102629`](20260807-102629/) | 1.8.1 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-022509`](20260807-022509/) | 1.8.1 | 0/0 | 12 | 498/498 | skip | 8557 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260806-180959`](20260806-180959/) | 1.8.0 | 0/0 | 12 | 498/498 | skip | 8557 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260805-123655`](20260805-123655/) | 1.7.0 | 0/0 | 12 | 498/498 | skip | 8555 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260805-002859`](20260805-002859/) | 1.7.0 | 0/0 | 11 | 480/480 | skip | 7975 | 1201 | 6.1 | 1.8 | 12 | 0 | **green** |

## Test suite

**1264 cases** — 1264 passed, 0 failed, 0 skipped. The generated inventory
[`20260921-144300/test-cases.md`](20260921-144300/test-cases.md) is the authority on which cases existed at this run;
`docs/test-cases.md` is that same list at HEAD.

Moved **1255 → 1264** since the previous run.

No case reported a `skip`, so passed and total agree and nothing in this row claims coverage
that was not exercised.

## Lint

**0 warnings / 0 errors over 72 files** (`luacheck .`).

Read that figure with its scope attached: `.luacheckrc` excludes 1 path(s) from it — `tests/_kit/` —
so nothing under them is in the count above. A `0/0` that never moves is partly a statement about
what was never looked at, which is why the exclusions are NAMED here on every run rather than left
to whoever thinks to open `.luacheckrc`.

## Perf

**This repo ships no `tests/perf.lua`, so `perf` is a permanent `skip`** — the first of
`automated-tests-§3`'s two sanctioned reasons, *nothing to run*, rather than a ratified
`performance-§12` no-combat-path exemption. The record is therefore **silent about runtime
cost**: nothing in this file says this addon is fast or cheap, only that the question was
never asked.

## Complexity watch list

Current as of [`20260921-144300`](20260921-144300/) — **this run's measurement, not its diff.** Max CCN **15** across 3567
functions, **0** of them warned on; 9 file(s) in the 1000–1500 band and 2 over the 1500 cap
(`layout-§1`).

Every row below is generated from this run's own `lizard` output. **The `Disposition` column is
the one authored cell in this file** (`automated-tests-§4`, *the one boundary*): it is carried
forward verbatim while its entry is unchanged, and left **blank** when the entry is new — a blank
cell is this file saying something crossed and nobody has ruled on it yet.

### Functions `lizard` warned on

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1465 | **Accepted, re-ruled at v1.33.0 after crossing its re-check at 1200.** It went 1114 → 1260 for the font preload (Options minor 17): a self-contained library-level block, `preloadState` through `lib.__PreloadFonts`, and its two trigger sites in `lib:New`, most of it the reasoning comments. The corrected `count` docstrings added a few lines more. It sits 240 lines clear of the cap, and no function in the file warns on CCN. It is still the panel builder every host addon enters the library through, so a split would be a published surface change rather than an internal tidy. If it needs a seam, the preload block is the first one, at the cost of a new file, a new minor and a pairing guard. It went 1260 → 1284 at v1.34.0 (Options minor 18), all of it comments: the `profilesPage` descriptor entry and the three Reset-all tooltip strings in `lib.STRINGS`, plus one argument on the `__AttachCompose` call. Re-check at 1350. |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1197 |  |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1308 | **Already tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7)** (owner: @tusharsaxena). Not a violation — the file is under `layout-§1`'s 1500 cap; the issue records the decision and its trigger so it is not re-argued each run. Was 1052; it grew for the observed-containment record and the keyed `Open`/`Close` bracket. Still the only shipped file in the band and the widest surface the consumers bind against. Worst function in the file is `groupContext` at CCN 11 and the file's avg CCN is 3.4, so this is breadth, not knots; the sampler and the group/scenario bookkeeping are the peel seam if it crosses 1500. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1232 | **Accepted.** Unchanged since the v1.27.0 release run. It holds two of the library's three highest-CCN functions — `list@1178-1219` and `paintMenuRow@126-159`, both at 13 — so density and size want reading together here. Per-widget files are the seam if it needs one; each widget is already a self-contained constructor. Re-check at 1350. **Shelf life crossed at `20260916-093057`:** it has been carried as a bare *Accepted* since v1.27.0, far beyond `automated-tests-§4`'s three consecutive release runs, and is now owed either a peel or a tracked deviation ID with an owner. Its avg CCN is 4.4, the highest of any file in the band, so this one is real control flow rather than `or`-defaulting. |
| 1000–1500 (on notice) | `testkit/framework.lua` | 1227 |  |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1446 | **On notice, and eighteen lines from breach.** It was 1471 at the v1.32.0 run, gained 7 at kit revision 18 for AceDB's per-event callback key, and 4 at kit revision 19 for the keyless `OnProfileReset`, all comment. It is a flat builder of independent fakes, so its length is breadth, not tangle. The peel seam is the Ace fakes, the CallbackHandler registry through AceGUI, which could move to a kit file the builder loads. That is a kit revision of its own, and every consumer would re-vendor it. **The next kit change that adds more than eighteen lines peels first, or opens an issue naming that seam before it crosses.** Re-check at 1490. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1307 | **NEWLY CROSSED at `20260807-151331` (v1.8.3), by one line — owed a tracked ID.** 968 → 1001, from the three cases covering `O.RefreshPanel`. Same shape as the row above: a flat list of independent cases, so length is case count, not tangle, and nothing in the file warns on CCN. Under the 1500 cap, so a split is declined today; the peel seam is the render/refresh block, large enough to stand alone as `tests/test_options_render.lua`. Its `automated-tests-§4` clock starts at v1.8.3. **That clock expired long ago** — re-read at `20260916-093057`, the row has said *owed a tracked ID* across eleven minor versions and no ID exists. Either file it or peel it; do not re-accept it a twelfth time. |
| 1000–1500 (on notice) | `tests/test_slash.lua` | 1327 | **NEWLY CROSSED at `20260913-002423` (v1.34.0).** 968 → 1034, from the six cases pinning Slash minor 10's whole-remainder string parse. A flat list of independent cases, so length is case count, not tangle, and nothing in the file warns on CCN; 466 lines clear of the cap. It mirrors `LibKa0s/Slash.lua` (670), so it has no seam of its own before the module has one; the parser block (`ParseBool` through `ParseValue`) is the natural peel, as `tests/test_slash_parse.lua`. Re-check at 1350. |
| 1000–1500 (on notice) | `tests/test_widgets.lua` | 1493 | **Accepted, and it is seven lines from breach.** The closest any file in this collection sits to `layout-§1`'s 1500 cap. It grew 951 → 1209 → 1296 → 1350 → 1493 across the ReorderList and settings-revamp-v2 work and has been flat since the v1.27.0 release run. It mirrors `LibKa0s/Widgets.lua`, so it has no seam of its own — a suite that peels before its module commits to a partition the module has not chosen. **The next case added to it puts this library in breach**, which is a harder problem than the two already tracked, and it wants an issue before it crosses rather than after. Split by widget family the moment `Widgets.lua` is split, and not later. **Re-read at `20260916-093057`:** still 1493, still seven lines clear, and also now past the three-release shelf life on a bare *Accepted*. The issue this row has been asking for is the action item of this run. |
| > 1500 (over cap) | `LibKa0s/OptionsWidgets.lua` | 3583 | **Ruled on 2026-09-08 (`M4-14`), tracked as [`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16)** (owner: @tusharsaxena). A breach, not a band entry: `layout-§1` was revised this cycle to say the cap binds a library's own payload folder, which is the question the 2026-09-07 audit graded Low for want of an answer. The issue names the seam — the tab and page chrome (`:378` art block, `:871`-`:1349` members) out to `OptionsTabs.lua`, leaving the widgets and the flow engine; the two halves share no local in either direction. Not peeled this cycle: the remediation plan forbids splitting, and a payload peel here costs an `LibKa0s.xml` row, a LibStub minor and the pairing guard. `CLAUDE.md` § *Files over the 1500-line cap* is the census and `tests/test_layout_cap.lua` reddens if this file ever drops off it. |
| > 1500 (over cap) | `tests/test_options_widgets.lua` | 3882 | **Ruled on 2026-09-08 (`M4-14`), tracked as [`#8`](https://github.com/tusharsaxena/LibKa0s/issues/8)** (owner: @tusharsaxena). That issue's own hard trigger — *crosses 1500 → split* — has fired; it was rewritten from an on-notice record (1114) into the breach record it now is. The seam changed with it: **not** by widget family, but along whatever seam `LibKa0s/OptionsWidgets.lua` peels on ([`#16`](https://github.com/tusharsaxena/LibKa0s/issues/16)), in that file's own commit — `testing-§1` pairs one suite with one module, and a suite peeled on a partition the module has not chosen leaves two files that no longer pair. |

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of
`t.k = rec.k or D.k` defaulting lines scores high with no visible branching at all: a large CCN
here usually means *this function defaults or guards a lot of fields* rather than *this function
is tangled*, and the two want different fixes (`performance-§10`).

