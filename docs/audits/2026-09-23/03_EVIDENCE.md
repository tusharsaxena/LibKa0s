# 03 — Evidence

Every command below was run from the repository root (`/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s`)
at `46ccaa6` on 2026-09-23. Each output shown is the real output. Every `file:line` cited in this bundle
was re-read before writing, and the cited text is quoted next to it.

**Runner note.** `ka0s-bounded` was not on `PATH`, but it exists at
`~/.claude/wow-addon/bin/ka0s-bounded`. `luacheck`, `lua tests/run.lua` and `lizard` all ran through it,
and all exited 0. No run exited 124 or 137.

**Default census scope.** `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'` covers the authored Lua
this repo tracks: `LibKa0s/`, `testkit/`, `tests/` (minus the vendored `tests/_kit/`) and `tools/`. There is
no `libs/` here. Any other scope is stated where it is used.

---

## E0. The standard resolved

```sh
curl -fsSL "$RAW/AUDIT.md"; curl -fsSL "$RAW/standards/STANDARDS.md"
# then each of the 27 files the Sections list links, and standards/ADDONS.md
```

- **Result.** Every fetch succeeded, and no fetch returned an empty file.
- **Version.** `STANDARDS.md:1` reads `# Ka0s WoW Addon Standard (v2.64.0, 2026-09-23)`.
- **Classification check.** `library-stack-§7`'s three lists (fetched `library-stack.md:211-260`) were
  compared against the 27 Sections entries, and every section is classified.

## E1. Authored Lua census, the cap, and the band

```sh
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | wc -l
81
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs wc -l | sort -rn | awk '$1>=1000'
  48609 total
   4086 tests/test_options_widgets.lua
   3922 LibKa0s/OptionsWidgets.lua
   1583 testkit/framework.lua
   1499 testkit/test_prose.lua
   1493 tests/test_widgets.lua
   1476 LibKa0s/Options.lua
   1446 testkit/mock_base.lua
   1327 tests/test_slash.lua
   1308 LibKa0s/Perf.lua
   1307 tests/test_options.lua
   1233 tests/test_schema.lua
   1232 LibKa0s/Widgets.lua
   1197 LibKa0s/OptionsTabs.lua
```

- **Totals.** 3 files are over the cap and 10 are in the band. These match `manifest.json`'s
  `"bandFiles": 10, "overCapFiles": 3` (`docs/automated-tests/20260923-144526/manifest.json`).
- **Generated-data exemptions.** The repo declares none (`tests/run.lua:71`
  `Kit.layoutCap = { hub = "CLAUDE.md" }`, with no `exempt` set), so nothing is subtracted.

Census rows:

- `CLAUDE.md:129`: `| \`tests/test_options_widgets.lua\` | 4086 | Issue [#33](…) — …`
- `CLAUDE.md:130`: `| \`LibKa0s/OptionsWidgets.lua\` | 3922 | Issue [#32](…) — …`
- `CLAUDE.md:131`: `| \`testkit/framework.lua\` | 1583 | Ratified deviation row — kit revision 25's \`resolveDir\` / \`adviceDir\` pair (\`testkit/framework.lua:569\` and \`:598\`) …`
  - Its citations resolve: `testkit/framework.lua:569` reads `local function resolveDir(entryDir, runnerDir)`
    and `:598` reads `local function adviceDir(kitDir, root)`.
  - Its named seam runs from `:483` (`-- ── suite loading ──`) to `Kit.assertSuiteInventory` at `:1048`,
    which ends at `:1078`. That matches the row's "lines 483–1078".

## E2. The deviation register and its triggers (`LK-34`, `LK-38`, recorded rows)

The register sits at `CLAUDE.md:69` (`## Documented deviations`) with its table at `:71-76`, and `:78`
reads `**Four rows.** Two are not prose at all — …`.

```sh
$ sed -n '71,76p' CLAUDE.md | cut -d'|' -f2
 Rule | --- | `localization-§5` | `localization-§5` | `localization-§5` | `compat`
```

No row cites `layout-§1` (`LK-34`). The register's shape is `CLAUDE.md:53`: ``| Rule | What differs | Why | Decided | Re-check trigger |``.
`CLAUDE.md:163-165` reads: *"It is an owner decision and it is recorded here rather than assumed: if the
preference is an issue instead, the row is replaced by one and nothing else in this pass changes."*

**Row 2's trigger** (a `minimize.tga`, or an alias map):

```sh
$ ls LibKa0s/media/icons | grep -i minim
minimise.tga
```

`LibKa0s/Media.lua:202` reads `function lib.Icon(addonName, name, vendorPath)` and `:206` reads
`return base .. ICON_DIR .. "\\" .. name`. There is no alias map, so the trigger has **not fired**.

**Row 4's citations.**

- `LibKa0s/Perf.lua:707-708` reads
  `local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization` / `or GetSpecialization`.
- `:712` reads `local _, name = GetSpecializationInfo(index)`.
- `LibKa0s/Compat.lua:270` reads `function lib.GetSpecialization()` and `:289` reads
  `function lib.GetSpecializationInfo(index)`.

All four resolve. The trigger (a Perf floor raise) has not fired, because v1.55.0 moves no existing
file's minor (`CHANGELOG.md:16-18`).

**Row 3's trigger** (the kit gate grows a non-ASCII case and a retired-section case): the case names in
`testkit/test_prose.lua` (`:896`, `:934`, `:1018`, `:1030`, `:1056`, `:1134`–`:1483`) contain neither.
The trigger has **not fired**.

**Evidence IDs.**

```sh
$ grep -c 'LK-06' docs/audits/2026-09-07/02_DEVIATIONS.md
3
$ grep -c 'LK-31' docs/audits/2026-09-08/04_TECHNICAL_DESIGN.md docs/audits/2026-09-08/05_EXECUTION_PLAN.md
docs/audits/2026-09-08/04_TECHNICAL_DESIGN.md:3
docs/audits/2026-09-08/05_EXECUTION_PLAN.md:2
$ ls docs/reviews
2026-07-31  2026-08-05  2026-09-07
$ git log --all --format='%h %cs %s' | grep -i 'v1.31.0 review'
1f1790c 2026-09-12 v1.31.0 review: kit 17 and the Options arm, fixed before release
```

Row 1 (`CLAUDE.md:73`) says *"Filed by the v1.31.0 review"*. No bundle exists for it, and the reference
resolves to a commit (`LK-38`).

## E3. Issue store

```sh
$ gh issue list --state all --limit 200 --json number,title,state,labels \
    --jq '.[] | "\(.number)\t\(.state)\t\([.labels[].name]|join(","))\t\(.title)"'
```

- **Count.** The command returned 34 issues.
- **The census issues.** #32 (`OPEN bug,state:triaged` "LibKa0s/OptionsWidgets.lua is still over
  layout-§1's cap after the chrome peel (2812)") and #33 (`OPEN enhancement,state:triaged`).
- **The issues `RESULTS.md` still cites.** #16 (`CLOSED bug,state:done` "LibKa0s/OptionsWidgets.lua sits
  over layout-§1's 1500-line cap (1989)") and #8 (`CLOSED enhancement,state:done` "tests/test_options_widgets.lua
  sits over layout-§1's 1500-line cap (2398)"). Both are closed.
- **Perf.** #7 is `OPEN state:triaged` ("Perf.lua sits in the layout-§1 on-notice band").
- **Missing issues.** No issue exists for `tests/test_options.lua`, `LibKa0s/Widgets.lua` or
  `tests/test_widgets.lua` (`LK-17d`).
- **Declines.** The `state:will-not-do` issues are #10 and #21–#26. Only #22 declines a standards rule,
  and register row 2 carries it.
- **Hygiene.** There is no `[status]` title prefix, and every issue has a `state:` label.

## E4. Lint

```sh
$ ~/.claude/wow-addon/bin/ka0s-bounded luacheck .
…
Checking tests/wow_mock.lua                       OK
Checking tools/gen-api-members.lua                OK

Total: 0 warnings / 0 errors in 81 files
exit 0
```

**Scope.** `.luacheckrc:4` reads `exclude_files = { "tests/_kit/" }`, so the run covered all 81 authored
files and excluded only the vendored kit. `.luacheckrc:67` reads `files["tests/"] = {`, and `:56` reads
`ignore = { "212/self", "212/event", "432/self" }`.

**The lint count against its three prose copies (`LK-29` (a)):**

- `CLAUDE.md:268-269`: *"… not repo-wide — eighty / files at v1.55.0, everything but `tests/_kit/` …"* is
  **wrong**.
- `DEPENDENCIES.md:124`: `luacheck .  # 0 warnings / 0 errors, in 81 files` is right.
- `docs/releasing.md:19`: *"is eighty-one files at v1.55.0"* is right.

```sh
$ git ls-tree -r --name-only 06b4051 | grep '\.lua$' | grep -v '^tests/_kit/' | wc -l
80
$ git log --diff-filter=A --name-only --format='%h' 06b4051..HEAD -- '*.lua'
244c752
tests/test_kit_eol.lua
$ git show ae48f3f --stat
 CHANGELOG.md | CLAUDE.md | DEPENDENCIES.md | docs/releasing.md | docs/test-cases.md
```

`ae48f3f`'s change to `CLAUDE.md` was the `framework.lua` 1571 → 1583 row only
(`git show ae48f3f -- CLAUDE.md`). It did not touch `:269`.

## E5. Headless suite

```sh
$ ~/.claude/wow-addon/bin/ka0s-bounded lua tests/run.lua
…
  PASS  layoutcap self-test: the exempt set takes folders as well as paths

1484 passed, 0 failed, 1 skipped, 1485 total
exit 0
```

The one skip is:

```text
SKIP  suite inventory: tests/_kit/test_prose.lua is declined, and the decline is recorded — CLAUDE.md
carries a `## Documented deviations` row keyed `localization-§5`: … — tests/test_prose.lua runs in its place
```

**Wiring.**

- `tests/run.lua:85` reads `"test_versioning", "test_kitsync", "test_prose",`.
- `tests/run.lua:95` reads `{ name = "test_layout_cap", dir = "tests/_kit/" },`.
- `git ls-files tests/test_layout_cap.lua` prints nothing, so the local copy is gone.

**Inventory currency.**

```sh
$ diff -q docs/test-cases.md docs/automated-tests/20260923-144526/test-cases.md && echo SAME
SAME
```

## E6. Kit sync (`testing-§11`)

```sh
$ diff -r --strip-trailing-cr testkit tests/_kit && echo "kit diff (content) EMPTY"
kit diff (content) EMPTY
$ diff -r testkit tests/_kit >/dev/null && echo "kit diff (bytes) EMPTY"
kit diff (bytes) EMPTY
$ git ls-files -s testkit/run-automated-tests.sh tests/_kit/run-automated-tests.sh
100755 31ff9b3e… 0	testkit/run-automated-tests.sh
100755 31ff9b3e… 0	tests/_kit/run-automated-tests.sh
```

`testkit/framework.lua:20` reads `Kit.VERSION = 25`.

## E7. Complexity (verbatim invocation)

```sh
$ ~/.claude/wow-addon/bin/ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
…
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
     30419       6.6     2.0       52.1     4248            0      0.00    0.00
exit 0
```

**Against the latest bundle.** `docs/automated-tests/20260923-144526/complexity.txt` has the identical
footer, so there is **zero drift**. The manifest reads `"git": { "sha": "ae48f3f…", "dirty": false }` and
`"release": "1.55.0"`.

```sh
$ git rev-list --count ae48f3f..HEAD
4
$ git diff --stat ae48f3f HEAD
 docs/automated-tests/20260923-144526/{complexity.txt,lint.txt,manifest.json,test-cases.md,tests.txt}
 docs/automated-tests/RESULTS.md | docs/releasing.md
 7 files changed, 7710 insertions(+), 88 deletions(-)
```

No code changed after the measurement.

## E8. Watch list: shelf life and census agreement (`LK-17d`, `LK-33`)

`docs/automated-tests/RESULTS.md` is the watch list. Each row is quoted up to the start of its
Disposition cell:

- `:157`: `| 1000–1500 (on notice) | \`LibKa0s/Options.lua\` | 1476 | **Accepted, re-ruled at v1.33.0 after crossing its re-check at 1200.** … Re-check at 1350. |`
  - The file was 1460 at v1.46.0 (`CLAUDE.md:192`: *"then 1460 at v1.46.0 with minor 22's combat lock"*).
- `:158`: `| 1000–1500 (on notice) | \`LibKa0s/OptionsTabs.lua\` | 1197 |  |`
- `:160`: `| … | \`LibKa0s/Widgets.lua\` | 1232 | **Accepted.** … **Shelf life crossed at \`20260916-093057\`:** … now owed either a peel or a tracked deviation ID with an owner.`
- `:162`: `| … | \`testkit/test_prose.lua\` | 1499 |  |`
- `:163`: `| … | \`tests/test_options.lua\` | 1307 | **NEWLY CROSSED at \`20260807-151331\` (v1.8.3), by one line — owed a tracked ID.** … do not re-accept it a twelfth time.`
- `:164`: `| … | \`tests/test_schema.lua\` | 1233 |  |`
- `:166`: `| … | \`tests/test_widgets.lua\` | 1493 | **Accepted, and it is seven lines from breach.** … The issue this row has been asking for is the action item of this run.`
- `:167`: `| > 1500 (over cap) | \`LibKa0s/OptionsWidgets.lua\` | 3922 | **Ruled on 2026-09-08 (\`M4-14\`), tracked as [\`#16\`](…)** … \`tests/test_layout_cap.lua\` reddens if this file ever drops off it.`
- `:168`: `| > 1500 (over cap) | \`testkit/framework.lua\` | 1583 |  |`
- `:169`: `| > 1500 (over cap) | \`tests/test_options_widgets.lua\` | 4086 | **Ruled on 2026-09-08 (\`M4-14\`), tracked as [\`#8\`](…)** …`

**Release runs since each clock started.** Scope: every `docs/automated-tests/2*/manifest.json` whose
`release` is a version string, counting distinct versions.

```sh
$ bash -c 'for since in 20260807-151331 20260916-093057; do for d in docs/automated-tests/2*/; do
    s=$(basename $d); [[ "$s" > "$since" ]] || continue
    grep -o "\"release\": *\"[0-9][^\"]*\"" $d/manifest.json | sed "s/.*: *//"; done | sort -u | wc -l; done'
54
20
```

**`OptionsTabs.lua` blank across release rows.** Scope: the last six commits touching `RESULTS.md`.

```sh
$ for c in $(git log --format=%h -6 -- docs/automated-tests/RESULTS.md); do …; done
== 6f9c5e0 (v1.55.0)  `LibKa0s/OptionsTabs.lua` 1197 [BLANK]   `testkit/framework.lua` 1583 [BLANK]
== 8081886 (v1.54.0)  `LibKa0s/OptionsTabs.lua` 1197 [BLANK]
== 44758ed (v1.53.0)  `LibKa0s/OptionsTabs.lua` 1197 [BLANK]
== 610aee1 (v1.52.0)  `LibKa0s/OptionsTabs.lua` 1197 [BLANK]
== f5e3a1d (v1.51.0)  `LibKa0s/OptionsTabs.lua` 1197 [BLANK]
== c45833c (v1.50.0)  `LibKa0s/OptionsTabs.lua` 1197 [BLANK]
```

**Census vs watch list (`LK-33`).**

| File | `RESULTS.md` says | Census says | Issue state |
|---|---|---|---|
| `LibKa0s/OptionsWidgets.lua` | `#16` (`:167`) | `#32` (`CLAUDE.md:130`) | #16 CLOSED, #32 OPEN |
| `tests/test_options_widgets.lua` | `#8` (`:169`) | `#33` (`CLAUDE.md:129`) | #8 CLOSED, #33 OPEN |
| `testkit/framework.lua` | blank (`:168`) | "Ratified deviation row" (`CLAUDE.md:131`) | none |

## E9. Release records (`LK-19`, `LK-35`, `LK-36`)

**Tags with no release bundle.** Scope: every tag against every manifest `release` value.

```sh
$ for m in docs/automated-tests/2*/manifest.json; do grep -o '"release": *"[^"]*"' $m | sed 's/.*: *"//;s/"//'; done | sort -uV > rel.txt
$ git tag | sed 's/^v//' | sort -V > tags.txt
$ grep -vxF -f rel.txt tags.txt
1.0.0 1.1.0 1.1.1 1.2.0 1.3.0 1.3.1 1.4.0 1.5.0 1.6.0 1.6.1 1.6.2 1.6.3 1.7.0 1.24.0 1.28.0 1.29.0 1.36.0 1.36.1 1.54.1 1.54.2
```

- **Before the convention.** `v1.0.0` to `v1.7.0` predate it: `docs/releasing.md` records v1.8.0 as the
  first release with a test record.
- **`v1.24.0`** is the case `docs/releasing.md:157-160` itself names: *"**No tag is cut without a bundle
  whose `release` field names it.** `v1.24.0` is the reason that sentence is here"*.
- **After the 2026-09-08 audit:** `v1.28.0` (2026-09-09 01:22), `v1.29.0` (2026-09-09 01:35), `v1.36.0`
  (2026-09-15 01:04), `v1.36.1` (2026-09-15 10:49), `v1.54.1` (2026-09-22 20:30:14) and `v1.54.2`
  (2026-09-22 20:35:26), read with `git log -1 --format='%ci' v<tag>`.

**Missing `ANALYSIS.md`.** Scope: every bundle.

```sh
$ ls -d docs/automated-tests/2*/ | wc -l            # 74 bundles
$ ls docs/automated-tests/2*/ANALYSIS.md | wc -l    # 23 write-ups
# release-stamped bundles: 68, of which 51 have no ANALYSIS.md
$ bash -c '… [[ "$s" > "20260908-181447" ]] …'
release bundles after 20260908-181447: 38; without ANALYSIS: 32
$ grep -ci analysis docs/releasing.md
0
```

**A frozen write-up misreading the rule.** `docs/automated-tests/20260916-093057/ANALYSIS.md:60-62`
reads: *"`20260916-033929` shipped **without** an `ANALYSIS.md`, … The playbook treats that file as
recommended outside releases and mandatory at one, so this is not a breach"*. Against that:

```sh
$ grep -o '"release": *"[^"]*"' docs/automated-tests/20260916-033929/manifest.json
"release": "1.38.0"
```

**The perf-skip statement, per `CHANGELOG.md` entry.** Scope: the 13 newest entries.

```sh
$ for v in v1.55.0 … v1.47.0; do awk -v V=$v '/^## v/{p=($2==V)} p' CHANGELOG.md \
    | grep -qiE 'tests/perf.lua|perf SKIP|perf.{0,40}skip' && echo "$v yes" || echo "$v NO"; done
v1.55.0 NO v1.54.2 NO v1.54.1 NO v1.54.0 yes v1.53.0 NO v1.52.0 yes v1.51.0 yes v1.50.0 yes
v1.49.1 NO v1.49.0 NO v1.48.1 NO v1.48.0 NO v1.47.0 NO
```

`CHANGELOG.md:579-581` (v1.54.0) is the shape that is owed: *"Release gate
(`docs/automated-tests/20260922-202214/`): lint 0/0 in 73 files, 1277 tests 0 failed, complexity 0 over
CCN 15. Perf SKIPPED, not measured — no `tests/perf.lua` — so the gate covered three suites, not four."*
The v1.55.0 entry spans `:13-507`.

**`LK-32` not corrected forward.** `20260908-181447/ANALYSIS.md:92` reads *"Twenty of this repository's
thirty-four bundles carry no `ANALYSIS.md`"*. The next write-up, `20260916-093057/ANALYSIS.md`, mentions
that bundle only at `:61` and states no correction.

## E10. The watch-list emitter (`LK-30`)

- `testkit/run-automated-tests.sh:714` reads `if [ -z "$CCN_WARN_ROWS" ]; then printf 'None.\n'; return; fi`.
- `testkit/run-automated-tests.sh:731` reads `if [ -z "$CCN_BAND_ROWS" ]; then printf 'None.\n'; return; fi`.
- `docs/automated-tests/RESULTS.md:149-151` reads ``### Functions `lizard` warned on`` / (blank) / `None.`

## E11. Line endings

```sh
$ test -f .gitattributes && echo present          # present
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes
26:* text=auto eol=crlf
$ grep -nE '^\*\.(sh|py) text eol=lf$' .gitattributes
36:*.sh text eol=lf
37:*.py text eol=lf
$ grep -c ' binary$' .gitattributes
20
$ git ls-files -z | xargs -0 -I{} sh -c '…(AUDIT.md step 4 check (e), verbatim)…' 2>/dev/null | wc -l
0
$ n=84; head -n $n .gitattributes | tr -d '\r' | diff canon_client.gitattributes - && echo "BODY IDENTICAL"
BODY IDENTICAL
$ tail -n +85 .gitattributes | wc -l
0
```

- **Canonical body.** `canon_client.gitattributes` is the fetched `line-endings.md:166-249`, the
  *Client-bound repos — the eleven addons and `LibKa0s`* block, which is 84 lines.
- **Scope of (e).** The whole tracked set, with nothing excluded.

## E12. British spellings (`LK-28`)

**Method.** The lists are `testkit/test_prose.lua:158-197` verbatim (`BRITISH` 91 and `ALLOWED` 30,
confirmed by `print(#BRITISH, #ALLOWED)` giving `91 30`). The matcher is that file's `britishIn`
(`:844-859`): whole-word `ALLOWED` removal, then a substring scan. The counter script sits in the session
scratchpad and is not tracked.

**Scope.** `git ls-files`, excluding:

- `tests/_kit/`;
- the frozen stores `docs/{audits,reviews,adoption,superpowers}/` and `docs/automated-tests/<stamp>/`;
- `CHANGELOG.md` (released entries);
- the generated `docs/test-cases.md`;
- both prose gates, whose subject is the rule;
- binaries.

```text
docs/api (live+superseded)   560 lines  93 files
tests/                       151 lines  23 files
root docs/other               26 lines   5 files   (README.md 4, CLAUDE.md 2, DEPENDENCIES.md 1, tools/artwork/icon_cleaner.py 18, tools/artwork/bar_textures.py 1)
testkit/                      11 lines   2 files   (mock_base.lua 5, mock_record.lua 6 — register row 1)
docs/ live pages              10 lines   1 file    (docs/releasing.md)
LibKa0s/                       1 line    1 file    (Media.lua — register row 2)
```

**Live (highest-version) `docs/api/` documents:** `Core/version-7-docs.md` 6, `DebugLog/version-12-docs.md` 1,
`Media/version-3-docs.md` 3, `Slash/version-14-docs.md` 14 and `Widgets/version-9-docs.md` 1. That is
25 lines in 5 files. The other 535 are in superseded per-version records.

**Arithmetic for `LK-28`.** The ratified hits are excluded: `LibKa0s/` 1, `testkit/` 11, and `CLAUDE.md` 2
(`:73` `cancelled` and `:74` `minimis`, both quotations of ratified identifiers).

| Group | Lines | Files |
|---|---|---|
| `tests/` | 151 | 23 |
| Live `docs/api/` | 25 | 5 |
| `docs/releasing.md` | 10 | 1 |
| `README.md` | 4 | 1 |
| `DEPENDENCIES.md` | 1 | 1 |
| `tools/artwork/*.py` | 19 | 2 |
| **Total** | **210** | **33** |

**Samples, re-read.**

- `README.md:95`: `| \`LibKa0s-DebugLog-1.0\` | The on-screen debug console: movable window, colour-coded log, …`
- `docs/releasing.md:64`: `Never edit a superseded document to describe new behaviour — …`
- `docs/api/Slash/version-14-docs.md:31`: `… a CLI silently accepting a value it cannot honour is`
- `DEPENDENCIES.md:100`: `| NumPy | The recolour, solidify and normalize stages, …`

**The narrowed gate.** `tests/test_prose.lua:19` reads `local SHIPPED = { "LibKa0s", "testkit" }`. That
scope is ratified by register row 3 (`CLAUDE.md:75`), which is why 2026-09-08's `LK-28d` is recorded
rather than filed.

## E13. Stale `CLAUDE.md` figures and citations (`LK-29` (b) and (c))

```sh
$ git show 06b4051:tests/test_schema.lua | wc -l       # 1101
$ wc -l < tests/test_schema.lua                        # 1233
$ git show be91249 --stat | tail -2
 tests/test_schema.lua | 132 ++++++++…
```

- `CLAUDE.md:203` reads *"… and `tests/test_schema.lua` (1101), new at v1.55.0 with"*.
- `CLAUDE.md:180` reads *"`LibKa0s/OptionsTabs.lua:39`, following `__widgetsShellMinor`)"*.
- `LibKa0s/OptionsTabs.lua:39` is blank.
- `LibKa0s/OptionsTabs.lua:43-46` reads `if lib.__tabsMinor and lib.__tabsMinor >= TABS_MINOR` /
  `and lib.__tabsShellMinor == lib.MINOR then return end` / `lib.__tabsMinor      = TABS_MINOR` /
  `lib.__tabsShellMinor = lib.MINOR`.

## E14. Raw event registrations in the payload (`LK-37`)

Scope: the payload (`git ls-files 'LibKa0s/*.lua'`).

```sh
$ git ls-files 'LibKa0s/*.lua' | xargs grep -nE ':Register(Unit)?Event\('
LibKa0s/OptionsTabs.lua:102:      f:RegisterEvent("PLAYER_REGEN_DISABLED")
LibKa0s/OptionsTabs.lua:103:      f:RegisterEvent("PLAYER_REGEN_ENABLED")
LibKa0s/OptionsTabs.lua:139:    f:RegisterEvent("PLAYER_REGEN_DISABLED")
LibKa0s/OptionsTabs.lua:140:    f:RegisterEvent("PLAYER_REGEN_ENABLED")
LibKa0s/Widgets.lua:393:    m:RegisterEvent("GLOBAL_MOUSE_DOWN")
```

- **No `pcall`.** None of the five is wrapped in one, and the payload has no rejected-name record.
- **Unregister paths.** `OptionsTabs.lua:105-106` (`f:UnregisterEvent(...)`) shows the combat-lock frame
  does let go when no page is shown.
- **What this is not.** It is not a stand-down finding, since `slash-commands-§7` does not bind here.

## E15. Other compliance evidence

- **Majors and files.**
  - `grep -c 'major = "LibKa0s-' tests/majors.lua` gives `15`, and `grep -c '<Script file=' LibKa0s/LibKa0s.xml` gives `21`.
  - `git ls-files LibKa0s | grep -c '\.lua$'` gives `21`.
  - `README.md:13` reads *"One LibStub major per module. Fifteen"*.
- **Consumers.** `ls -d ../*/libs/LibKa0s/Perf.lua | wc -l` gives `11`.
- **Standard pointer.** `README.md:3` reads *"Built to the **[Ka0s WoW Addon Standard](…)**, v2.64.0"*.
- **`library-stack-§9` sentinel.** `LibKa0s/Options.lua:294` reads `if lib.__lsmBorderPatched then return false end`.
- **`compat` sweep.** Scope: the payload minus `Compat.lua` and `Env.lua`, over a fixed list of deprecated
  globals. It returns only `LibKa0s/Perf.lua:707-712` (register row 4) and
  `LibKa0s/OptionsWidgets.lua:398` (`C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(key)`, the
  namespaced form).
- **Message literals.** `git ls-files '*.lua' ':!tests/_kit' | xargs grep -nE '(Send|Register)Message\("Ka0s_'`
  returns only `tests/test_mock_record.lua:88`, a fixture.
- **Generators.** `git ls-files '*.py' '*.sh'` returns `testkit/run-automated-tests.sh`,
  `tests/_kit/run-automated-tests.sh`, `tools/artwork/bar_textures.py` and `tools/artwork/icon_cleaner.py`.
  `DEPENDENCIES.md:98` reads *"| Python 3 | Both tools are Python scripts …"*.
- **Documentation map.** Scope: tracked `docs/*.md` outside the frozen stores and `docs/api/`.

  ```sh
  $ git ls-files 'docs/*.md' | grep -vE '^docs/(audits|reviews|adoption|superpowers|api)/' | grep -vE '^docs/automated-tests/[0-9]'
  docs/adoption-prompt.md
  docs/adoption-report.md
  docs/automated-tests/README.md
  docs/automated-tests/RESULTS.md
  docs/fast-gate-adoption-prompt.md
  docs/record-schema.md
  docs/releasing.md
  docs/test-cases.md
  ```

  All eight have rows at `CLAUDE.md:244-251`, and every row target exists.
- **Frozen bundles.** `git log --format=%h -- docs/audits/2026-08-05` shows 1 commit, and the same holds
  for `2026-09-07`, `2026-09-08` and `docs/reviews/2026-09-07`.
- **Tag type.** `git cat-file -t v1.55.0` gives `tag`, and `git cat-file -t v1.54.2` gives `tag`.
- **`addonVersion` source.** `testkit/run-automated-tests.sh:93` reads
  `ADDON_VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' …)"`.

## Checks recorded as not applicable

Each of these has nothing to bind to in a library repo (`library-stack-§7`, *Does not apply*, or no
instance):

- the `diff -r` of a vendored `libs/LibKa0s/` and the provenance line (this repo is the source);
- the TOC, `## IconTexture` and `.pkgmeta` checks;
- the `docs/` tier-model checks (a)–(f);
- the launcher and settings-panel content checks;
- the `slash-commands-§7` disabled-state census;
- the re-vendor bundle store check (`docs/revendor/`);
- the close-button wrapper grep (the library defines `MakeCloseButton` and does not consume it);
- the media seam (`core/MediaSetup.lua`).
