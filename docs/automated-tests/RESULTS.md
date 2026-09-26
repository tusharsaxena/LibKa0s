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

**Commit** is the short sha the run measured and **Tree** is whether that tree was clean at the
time. Both are read from git by the runner; neither is ever typed. A **dirty** row measured bytes
that no sha can bring back, so it is kept as an experiment honestly labeled rather than dropped —
and a release record is refused outright on a dirty tree, so no release row can be one.

A row reading `unknown` in both cells was recorded before the runner emitted them. That is what
the record holds about those runs — it is not `clean`, and it is not reconstructed from git
archaeology, for the same reason a skip is never a pass (`automated-tests-§4`).

| Run | Commit | Tree | Version | Lint w/e | Files | Tests | Perf | NLOC | Funcs | Avg NLOC | Avg CCN | Max CCN | CCN warn | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [`20260926-193105`](20260926-193105/) | `5dc9f5d` | clean | 1.62.0 | 0/0 | 122 | 1747/1/1748 | skip | 36218 | 5050 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260926-182957`](20260926-182957/) | `e636e9d` | clean | 1.61.0 → 1.62.0 | 0/0 | 122 | 1747/1/1748 | skip | 36218 | 5050 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260926-160448`](20260926-160448/) | `cf38896` | clean | 1.61.0 | 0/0 | 100 | 1744/1/1745 | skip | 35854 | 5039 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260926-121411`](20260926-121411/) | `7cbe02c` | clean | 1.60.0 → 1.61.0 | 0/0 | 100 | 1744/1/1745 | skip | 35854 | 5039 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260926-034006`](20260926-034006/) | `2fdca6e` | clean | 1.59.0 → 1.60.0 | 0/0 | 98 | 1729/1/1730 | skip | 35354 | 4975 | 6.5 | 2.0 | 15 | 0 | **green** |
| [`20260925-170346`](20260925-170346/) | `e8faa5d` | clean | 1.58.0 → 1.59.0 | 0/0 | 93 | 1676/1/1677 | skip | 34348 | 4820 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260924-234934`](20260924-234934/) | `02999d0` | clean | 1.57.0 → 1.58.0 | 0/0 | 93 | 1665/1/1666 | skip | 34110 | 4787 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260924-225548`](20260924-225548/) | `281f26f` | clean | 1.56.0 → 1.57.0 | 0/0 | 92 | 1661/1/1662 | skip | 33910 | 4766 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260924-040553`](20260924-040553/) | `326494e` | clean | 1.55.0 → 1.56.0 | 0/0 | 92 | 1647/1/1648 | skip | 33581 | 4706 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260923-144526`](20260923-144526/) | `ae48f3f` | clean | 1.54.2 → 1.55.0 | 0/0 | 81 | 1484/1/1485 | skip | 30419 | 4248 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260922-202214`](20260922-202214/) | unknown | unknown | 1.53.0 → 1.54.0 | 0/0 | 73 | 1277/0/1277 | skip | 25542 | 3594 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260922-170122`](20260922-170122/) | unknown | unknown | 1.52.0 → 1.53.0 | 0/0 | 72 | 1277/0/1277 | skip | 25362 | 3590 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260922-095841`](20260922-095841/) | unknown | unknown | 1.51.0 → 1.52.0 | 0/0 | 72 | 1276/0/1276 | skip | 25354 | 3589 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260922-022127`](20260922-022127/) | unknown | unknown | 1.50.0 → 1.51.0 | 0/0 | 72 | 1270/0/1270 | skip | 25262 | 3580 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-144300`](20260921-144300/) | unknown | unknown | 1.49.1 → 1.50.0 | 0/0 | 72 | 1264/0/1264 | skip | 25125 | 3567 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-120741`](20260921-120741/) | unknown | unknown | 1.49.0 → 1.49.1 | 0/0 | 72 | 1255/0/1255 | skip | 24945 | 3541 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-111809`](20260921-111809/) | unknown | unknown | 1.48.1 → 1.49.0 | 0/0 | 72 | 1251/0/1251 | skip | 24870 | 3527 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-040120`](20260921-040120/) | unknown | unknown | 1.48.0 → 1.48.1 | 0/0 | 72 | 1246/0/1246 | skip | 24800 | 3522 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260921-033457`](20260921-033457/) | unknown | unknown | 1.47.0 → 1.48.0 | 0/0 | 72 | 1245/0/1245 | skip | 24790 | 3520 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260920-194447`](20260920-194447/) | unknown | unknown | 1.46.1 → 1.47.0 | 0/0 | 70 | 1211/0/1211 | skip | 24089 | 3401 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-214428`](20260919-214428/) | unknown | unknown | 1.46.0 → 1.46.1 | 0/0 | 70 | 1195/0/1195 | skip | 23727 | 3351 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-211837`](20260919-211837/) | unknown | unknown | 1.45.0 → 1.46.0 | 0/0 | 70 | 1189/0/1189 | skip | 23599 | 3335 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-162209`](20260919-162209/) | unknown | unknown | 1.44.0 → 1.45.0 | 0/0 | 69 | 1168/0/1168 | skip | 23027 | 3250 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260919-093635`](20260919-093635/) | unknown | unknown | 1.43.0 → 1.44.0 | 0/0 | 68 | 1159/0/1159 | skip | 22789 | 3222 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260917-201018`](20260917-201018/) | unknown | unknown | 1.42.0 → 1.43.0 | 0/0 | 67 | 1154/0/1154 | skip | 22700 | 3209 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260917-005828`](20260917-005828/) | unknown | unknown | 1.41.0 → 1.42.0 | 0/0 | 65 | 1141/0/1141 | skip | 22348 | 3171 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260916-230957`](20260916-230957/) | unknown | unknown | 1.40.0 → 1.41.0 | 0/0 | 65 | 1141/0/1141 | skip | 22347 | 3171 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260916-212818`](20260916-212818/) | unknown | unknown | 1.39.0 → 1.40.0 | 0/0 | 65 | 1140/0/1140 | skip | 22323 | 3171 | 6.6 | 2.0 | 15 | 0 | **green** |
| [`20260916-184458`](20260916-184458/) | unknown | unknown | 1.39.0 | 0/0 | 61 | 1071/0/1071 | skip | 21225 | 3011 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-130819`](20260916-130819/) | unknown | unknown | 1.38.0 → 1.39.0 | 0/0 | 61 | 1069/0/1069 | skip | 21193 | 3008 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-093057`](20260916-093057/) | unknown | unknown | 1.38.0 | 0/0 | 57 | 1044/0/1044 | skip | 20678 | 2929 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-033929`](20260916-033929/) | unknown | unknown | 1.37.0 → 1.38.0 | 0/0 | 57 | 1044/0/1044 | skip | 20678 | 2929 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260916-015507`](20260916-015507/) | unknown | unknown | 1.36.2 → 1.37.0 | 0/0 | 57 | 1042/0/1042 | skip | 20658 | 2927 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260915-140452`](20260915-140452/) | unknown | unknown | 1.36.2 → 1.36.2 | 0/0 | 57 | 1041/0/1041 | skip | 20635 | 2925 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260915-135323`](20260915-135323/) | unknown | unknown | 1.36.2 → 1.36.2 | 0/0 | 57 | 1041/0/1041 | skip | 20585 | 2922 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260915-133630`](20260915-133630/) | unknown | unknown | 1.36.1 → 1.36.2 | 0/0 | 57 | 1040/0/1040 | skip | 20552 | 2920 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260914-010923`](20260914-010923/) | unknown | unknown | 1.35.0 → 1.35.0 | 0/0 | 57 | 1028/0/1028 | skip | 20354 | 2891 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260914-001514`](20260914-001514/) | unknown | unknown | 1.35.0 → 1.35.0 | 0/0 | 57 | 1020/0/1020 | skip | 20148 | 2857 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-233500`](20260913-233500/) | unknown | unknown | 1.35.0 → 1.35.0 | 0/0 | 57 | 1015/0/1015 | skip | 20036 | 2844 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-180115`](20260913-180115/) | unknown | unknown | 1.35.0 → 1.35.0 | 0/0 | 56 | 972/0/972 | skip | 18454 | 2626 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-094012`](20260913-094012/) | unknown | unknown | 1.34.0 → 1.35.0 | 0/0 | 56 | 966/0/966 | skip | 18295 | 2603 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260913-002423`](20260913-002423/) | unknown | unknown | 1.33.0 → 1.34.0 | 0/0 | 55 | 909/0/909 | skip | 17104 | 2425 | 6.5 | 1.9 | 14 | 0 | **green** |
| [`20260912-214123`](20260912-214123/) | unknown | unknown | 1.32.0 → 1.33.0 | 0/0 | 55 | 897/0/897 | skip | 16958 | 2405 | 6.5 | 1.9 | 14 | 0 | **green** |
| [`20260912-190219`](20260912-190219/) | unknown | unknown | 1.31.0 → 1.32.0 | 0/0 | 54 | 885/0/885 | skip | 16622 | 2346 | 6.5 | 1.9 | 14 | 0 | **green** |
| [`20260912-185115`](20260912-185115/) | unknown | unknown | 1.31.0 → 1.32.0 | 0/0 | 53 | 881/0/881 | skip | 16548 | 2333 | 6.5 | 2.0 | 14 | 0 | **green** |
| [`20260912-151813`](20260912-151813/) | unknown | unknown | 1.31.0 → 1.31.0 | 0/0 | 53 | 869/0/869 | skip | 16270 | 2279 | 6.6 | 2.0 | 14 | 0 | **green** |
| [`20260912-145039`](20260912-145039/) | unknown | unknown | 1.30.0 → 1.31.0 | 0/0 | 53 | 860/0/860 | skip | 16133 | 2252 | 6.6 | 2.0 | 14 | 0 | **green** |
| [`20260912-103140`](20260912-103140/) | unknown | unknown | 1.29.0 → 1.30.0 | 0/0 | 51 | 819/0/819 | skip | 14918 | 2043 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260912-101914`](20260912-101914/) | unknown | unknown | 1.29.0 → 1.30.0 | 0/0 | 51 | 814/0/814 | skip | 14836 | 2031 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260908-181447`](20260908-181447/) | unknown | unknown | 1.27.0 | 0/0 | 51 | 795/0/795 | skip | 14564 | 1993 | 6.7 | 2.0 | 14 | 0 | **green** |
| [`20260907-235828`](20260907-235828/) | unknown | unknown | 1.26.0 → 1.27.0 | 0/0 | 49 | 791/0/791 | skip | 14376 | 1983 | 6.6 | 2.0 | 14 | 0 | **green** |
| [`20260907-201015`](20260907-201015/) | unknown | unknown | 1.25.0 | 0/0 | 18 | 769/769 | skip | 13798 | 1920 | 6.6 | 1.9 | 13 | 0 | **green** |
| [`20260903-161751`](20260903-161751/) | unknown | unknown | 1.24.0 | 0/0 | 18 | 764/764 | skip | 13678 | 1900 | 6.6 | 1.9 | 14 | 0 | **green** |
| [`20260831-185425`](20260831-185425/) | unknown | unknown | 1.22.0 | 0/0 | 17 | 705/705 | skip | 12460 | 1768 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260831-180722`](20260831-180722/) | unknown | unknown | 1.21.0 | 0/0 | 17 | 703/703 | skip | 12414 | 1762 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260831-160633`](20260831-160633/) | unknown | unknown | 1.20.0 | 0/0 | 17 | 701/701 | skip | 12334 | 1751 | 6.4 | 1.9 | 13 | 0 | **green** |
| [`20260827-153332`](20260827-153332/) | unknown | unknown | 1.19.0 | 0/0 | 17 | 694/694 | skip | 12116 | 1725 | 6.4 | 1.9 | 13 | 0 | **green** |
| [`20260827-110439`](20260827-110439/) | unknown | unknown | 1.18.1 | 0/0 | 17 | 672/672 | skip | 11667 | 1675 | 6.4 | 1.9 | 13 | 0 | **green** |
| [`20260826-185819`](20260826-185819/) | unknown | unknown | 1.18.0 | 0/0 | 17 | 654/654 | skip | 11123 | 1617 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260826-165334`](20260826-165334/) | unknown | unknown | 1.17.0 | 0/0 | 17 | 653/653 | skip | 11072 | 1606 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-172722`](20260825-172722/) | unknown | unknown | 1.16.0 | 0/0 | 17 | 649/649 | skip | 11024 | 1598 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-142319`](20260825-142319/) | unknown | unknown | 1.15.0 | 0/0 | 17 | 647/647 | skip | 10988 | 1596 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-032030`](20260825-032030/) | unknown | unknown | 1.14.0 | 0/0 | 17 | 628/628 | skip | 10807 | 1570 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260825-021432`](20260825-021432/) | unknown | unknown | 1.13.0 | 0/0 | 14 | 587/587 | skip | 10261 | 1482 | 6.3 | 1.9 | 13 | 0 | **green** |
| [`20260824-185459`](20260824-185459/) | unknown | unknown | 1.12.0 | 0/0 | 14 | 577/577 | skip | 9917 | 1447 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-153936`](20260824-153936/) | unknown | unknown | 1.11.2 | 0/0 | 14 | 568/568 | skip | 9847 | 1432 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-133151`](20260824-133151/) | unknown | unknown | 1.11.1 | 0/0 | 14 | 555/555 | skip | 9717 | 1410 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-031024`](20260824-031024/) | unknown | unknown | 1.11.0 | 0/0 | 14 | 553/553 | skip | 9680 | 1406 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260824-024124`](20260824-024124/) | unknown | unknown | 1.10.2 | 0/0 | 14 | 549/549 | skip | 9640 | 1401 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-235820`](20260823-235820/) | unknown | unknown | 1.10.1 | 0/0 | 13 | 531/531 | skip | 9168 | 1320 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-195133`](20260823-195133/) | unknown | unknown | 1.10.0 | 0/0 | 13 | 528/528 | skip | 9126 | 1313 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-191126`](20260823-191126/) | unknown | unknown | 1.9.2 | 0/0 | 13 | 526/526 | skip | 9118 | 1309 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260823-183503`](20260823-183503/) | unknown | unknown | 1.9.1 | 0/0 | 13 | 517/517 | skip | 8952 | 1274 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260823-150620`](20260823-150620/) | unknown | unknown | 1.9.0 | 0/0 | 13 | 514/514 | skip | 8869 | 1270 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260823-144602`](20260823-144602/) | unknown | unknown | 1.8.3 | 0/0 | 13 | 513/513 | skip | 8862 | 1269 | 6.4 | 1.9 | 14 | 0 | **green** |
| [`20260807-151331`](20260807-151331/) | unknown | unknown | 1.8.2 | 0/0 | 12 | 502/502 | skip | 8676 | 1249 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-114658`](20260807-114658/) | unknown | unknown | 1.8.2 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-105553`](20260807-105553/) | unknown | unknown | 1.8.1 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-102629`](20260807-102629/) | unknown | unknown | 1.8.1 | 0/0 | 12 | 499/499 | skip | 8636 | 1242 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260807-022509`](20260807-022509/) | unknown | unknown | 1.8.1 | 0/0 | 12 | 498/498 | skip | 8557 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260806-180959`](20260806-180959/) | unknown | unknown | 1.8.0 | 0/0 | 12 | 498/498 | skip | 8557 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260805-123655`](20260805-123655/) | unknown | unknown | 1.7.0 | 0/0 | 12 | 498/498 | skip | 8555 | 1237 | 6.3 | 1.9 | 14 | 0 | **green** |
| [`20260805-002859`](20260805-002859/) | unknown | unknown | 1.7.0 | 0/0 | 11 | 480/480 | skip | 7975 | 1201 | 6.1 | 1.8 | 12 | 0 | **green** |

## Test suite

**1748 cases** — 1747 passed, 0 failed, 1 skipped. The generated inventory
[`20260926-193105/test-cases.md`](20260926-193105/test-cases.md) is the authority on which cases existed at this run;
`docs/test-cases.md` is that same list at HEAD.

Unchanged from the previous run at 1748 cases.

**1 case(s) reported a `skip`.** A skip is counted in the total and never in `passed`, and at
the release gate it is NOT EVALUATED rather than passed (`automated-tests-§3`).

## Lint

**0 warnings / 0 errors over 122 files** (`luacheck .`).

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

Current as of [`20260926-193105`](20260926-193105/) — **this run's measurement, not its diff.** Max CCN **15** across 5050
functions, **0** of them warned on; 10 file(s) in the 1000–1500 band and 0 over the 1500 cap
(`layout-§1`).

Every row below is generated from this run's own `lizard` output. **The `Disposition` column is
the one authored cell in this file** (`automated-tests-§4`, *the one boundary*): it is carried
forward verbatim while its entry is unchanged, and left **blank** when the entry is new — a blank
cell is this file saying something crossed and nobody has ruled on it yet.

### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.

### Files by `layout-§1` band

| Band | File | LOC | Disposition |
|---|---|---|---|
| 1000–1500 (on notice) | `LibKa0s/Options.lua` | 1261 | **Peeled 2026-09-26 (`LK-ATS-04`), then accepted at 1261** (`CLAUDE.md` § *The band's terminal states, ruled 2026-09-24*). The 2026-09-24 *Accepted* had outlived its shelf life (`ATS-03`); the page registry and its combat park (one caller, state nothing else in the shell reads) were a seam, and moved unchanged to `LibKa0s/OptionsRegistry.lua` (263) at Options minor 26. **Re-check trigger: the next member added to `Options.lua`, or 1400 lines**; the reset walk is the next seam. |
| 1000–1500 (on notice) | `LibKa0s/OptionsIdList.lua` | 1193 | **Accepted 2026-09-26 (`LK-ATS-01`, issue [`#32`](https://github.com/tusharsaxena/LibKa0s/issues/32); `CLAUDE.md` § *Files over the 1500-line cap*, the id peel's rulings).** New file, moved unchanged out of `LibKa0s/OptionsWidgets.lua`: `O.IdList` and its entry-line layout, one piece of machinery. **Re-check trigger: 1350 lines.** |
| 1000–1500 (on notice) | `LibKa0s/OptionsIds.lua` | 1358 | **Accepted 2026-09-26 (`LK-ATS-01`, issue [`#32`](https://github.com/tusharsaxena/LibKa0s/issues/32); `CLAUDE.md` § *Files over the 1500-line cap*, the id peel's rulings).** New file, moved unchanged out of `LibKa0s/OptionsWidgets.lua`: id resolution, suggestions and the input. **Re-check trigger: 1450 lines**; the suggestion half (the module-scope suggestions-while-typing block and the dropdown members) is the seam, to a file of its own. |
| 1000–1500 (on notice) | `LibKa0s/OptionsTabs.lua` | 1293 | **Peeled 2026-09-26 (`LK-ATS-03`), then accepted at 1293** (`CLAUDE.md` § *The band's terminal states, ruled 2026-09-24*). The 2026-09-24 *Accepted* ("no second seam inside it") had outlived its shelf life (`ATS-03`, `ATS-06`); the combat lock's page chrome was that seam, and moved unchanged to `LibKa0s/OptionsCombat.lua` (249) at OptionsTabs minor 6. **Re-check trigger: the next member added to `OptionsTabs.lua`, or 1400 lines**; the tabbed page is the next seam. |
| 1000–1500 (on notice) | `LibKa0s/OptionsWidgets.lua` | 1422 | **Accepted 2026-09-26 (`LK-ATS-01`, issue [`#32`](https://github.com/tusharsaxena/LibKa0s/issues/32); `CLAUDE.md` § *Files over the 1500-line cap*, the id peel's rulings).** New to the band: it came off the census (3852) when the id surface moved out to `LibKa0s/OptionsIds.lua` and `LibKa0s/OptionsIdList.lua`. What is left is the makers, the choice grid, the landing page and the flow engine. **Re-check trigger: 1450 lines, or the next maker added**; the flow engine (`flowRows`, the switched sections) is the seam at either. |
| 1000–1500 (on notice) | `LibKa0s/Perf.lua` | 1319 | **Tracked as [`#7`](https://github.com/tusharsaxena/LibKa0s/issues/7)** (open; owner: @tusharsaxena). Under the cap; the issue records the decision and its trigger. 1308 → 1319 with `LK-20`'s minor 13 (raw `false` state fields, the depth reset at window edges). Worst function `groupContext` at CCN 11, so this is breadth, not knots; the sampler and the group/scenario bookkeeping are the peel seam if it crosses 1500. |
| 1000–1500 (on notice) | `LibKa0s/Widgets.lua` | 1266 | **Tracked as [`#36`](https://github.com/tusharsaxena/LibKa0s/issues/36)** (open, filed 2026-09-24 by `LK-32`; `CLAUDE.md` § *The band's terminal states, ruled 2026-09-24*): split into per-widget files, `ReorderList` first. 1232 → 1266 with `LK-21`'s minor 10. Replaces the bare *Accepted* carried since v1.27.0, which had outlived `automated-tests-§4`'s three-release shelf life. |
| 1000–1500 (on notice) | `testkit/mock_base.lua` | 1454 | **On notice, re-read 2026-09-24 (`LK-33`): 46 lines from breach.** 1446 → 1454 at kit revision 26 (`testkit/mock_events.lua`'s load, hook and install lines, and the shown-by-default flip's comment). Kit revisions 20, 22 and 26 each peeled a family of fakes to its own file (`mock_ids.lua`, `mock_record.lua`, `mock_events.lua`) rather than appending, and that is the rule for the next one. The peel seam is the Ace fakes, the CallbackHandler registry through AceGUI. **Re-check trigger: 1490 lines, or any kit change that adds more than 30 lines here**; either peels first or opens an issue naming that seam before it crosses. |
| 1000–1500 (on notice) | `tests/test_options.lua` | 1339 | **Tracked as [`#35`](https://github.com/tusharsaxena/LibKa0s/issues/35)** (open, filed 2026-09-24 by `LK-32`; `CLAUDE.md` § *The band's terminal states, ruled 2026-09-24*): the render/refresh block peels to `tests/test_options_render.lua`. This is the tracked ID the cell had asked for since v1.8.3. 1307 → 1339 during the 2026-09-23 remediation. |
| 1000–1500 (on notice) | `tests/test_schema.lua` | 1335 | **Tracked as [`#38`](https://github.com/tusharsaxena/LibKa0s/issues/38)** (open, filed 2026-09-24 by `LK-32`; `CLAUDE.md` § *The band's terminal states, ruled 2026-09-24*): split by pipeline stage, the write stage onward first. 1101 when new at v1.55.0, 1233 at that release run, 1335 after `LK-22` and `LK-23`; the batch cases already went to `tests/test_schema_batch.lua`. |

`lizard` counts every `and`/`or` short-circuit as a decision, so in Lua a run of
`t.k = rec.k or D.k` defaulting lines scores high with no visible branching at all: a large CCN
here usually means *this function defaults or guards a lot of fields* rather than *this function
is tangled*, and the two want different fixes (`performance-§10`).

