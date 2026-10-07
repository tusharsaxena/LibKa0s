# 03 — Evidence

Every command below was run from the repo root (`/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s`)
at HEAD `353f286` on 2026-10-07, on a tree that was clean at audit start. Outputs are pasted as
printed. Each census states its scope. Every `file:line` below was re-read after the bundle was
drafted, and the quoted text is what that line holds.

## E0. Standard resolution and kind

- Fetched with `curl -fsSL` from `https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`:
  `AUDIT.md`, `standards/STANDARDS.md`, `standards/ADDONS.md` and the 27 section files the Sections list
  links. `STANDARDS.md` line 1: `# Ka0s WoW Addon Standard (v2.76.1, 2026-10-07)`.
- `dev-copilot-profile` printed `profile=wow`, `kind=library`, `reason=name:LibKa0s`.
- Section ranges come from `grep -cE '^### [0-9]+\.'` on each fetched section file. Examples:
  `documentation` 9, `testing` 15, `options-ui` 18, `slash-commands` 8, `library-stack` 9.
  `anti-patterns` runs to #92.

## E1. Green gate (bounded runner)

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded luacheck .
Total: 0 warnings / 0 errors in 153 files                # exit 0
$ ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua
2087 passed, 0 failed, 2 skipped, 2089 total             # exit 0
  SKIP  suite inventory: tests/_kit/test_prose.lua is declined, and the decline is recorded — CLAUDE.md carries a `## Documented deviations` row keyed `localization-§5` …
  SKIP  diagnostics contract: an addon that opts out lands the report and leaves logging off — this addon keeps the default …
$ ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua --list | diff <(tr -d '\r' < docs/test-cases.md) <(tr -d '\r' < -)
(no output: the generated inventory is current)
```

- **Scope:** `.luacheckrc:4` `exclude_files = { "tests/_kit/" }`, so luacheck covered the 153 authored
  Lua files.
- **Kit gates wired** (`tests/run.lua`):
  - `:94` `"test_versioning", "test_kitsync", "test_prose",`
  - `:103` `{ name = "test_eol", dir = "tests/_kit/" },`
  - `:104` `{ name = "test_layout_cap", dir = "tests/_kit/" },`
  - `:106` `{ name = "test_lizard_sighted", dir = "tests/_kit/" },`

## E2. Complexity (sighted suite, run as written) — `LK-17d`, Checked

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle
LibKa0s 1.70.0 — automated tests — 20261007-161354
  complexity  pass  — 0 warnings (fun rate 0.00), 42163 NLOC / 6382 funcs, avg NLOC 6.7, avg CCN 2.0 (max 15), avg tokens 54.3 (recorded, non-gating)
  verdict: green
  record:  newest bundle 20261007-102304 measured 6b401e1, 6 commit(s) behind HEAD — its figures describe a tree this one is no longer
```

- The newest bundle's `manifest.json` reads `release: "1.70.0"`, `git.sha 6b401e1…`, `dirty: false`.
  Its complexity block is `{"warnings": 0, "maxCcn": 15, "nloc": 42163, "functions": 6382,
  "bandFiles": 6, "overCapFiles": 0, "blindFiles": 0}`. That is identical to the run above, so there
  is no drift.
- `git log 6b401e1..HEAD` shows 6 commits, and `git diff --stat 6b401e1..HEAD -- '*.lua'` is empty.
- `testkit/framework.lua:20` reads `Kit.VERSION = 37`.

### Watch-list shelf life (`LK-17d`)

The command reads `RESULTS.md` as it stood at the commit that added each release bundle's manifest, and
prints the band rows:

```sh
for b in 20260926-182957 20260929-113624 20260930-183150 20261001-001312 20261001-133255 \
         20261002-012529 20261002-232612 20261004-143758 20261006-134107 20261007-102304; do
  c=$(git log --format=%h -1 -- docs/automated-tests/$b/manifest.json)
  git show $c:docs/automated-tests/RESULTS.md | grep -E '^\| 1000'
done
```

These ten bundles are the release runs for v1.62.0, v1.63.0, v1.64.0, v1.65.0, v1.66.0, v1.67.0,
v1.68.0, v1.68.1, v1.69.0 and v1.70.0. The mapping from tag to bundle is §E8. In all ten:

- `LibKa0s/OptionsIdList.lua`, `LibKa0s/OptionsIds.lua` and `LibKa0s/OptionsWidgets.lua` begin
  `**Accepted 2026-09-26 (\`LK-ATS-01\`, issue [\`#32\`]…`;
- `LibKa0s/OptionsTabs.lua` begins `**Peeled 2026-09-26 (\`LK-ATS-03\`), then accepted at 1293**`.

`LibKa0s/Options.lua` carries *"Re-ruled 2026-10-01 at v1.65.0 (`DG-LIB-01`): accepted"* in the v1.65.0
through v1.70.0 runs, which is 7 runs.

Current text, `docs/automated-tests/RESULTS.md`:

- `:189` `| 1000–1500 (on notice) | \`LibKa0s/OptionsIdList.lua\` | 1246 | **Accepted 2026-09-26 (\`LK-ATS-01\`, issue [\`#32\`]…`
- `:190` `| … \`LibKa0s/OptionsIds.lua\` | 1359 | **Accepted 2026-09-26 …`
- `:191` `| … \`LibKa0s/OptionsTabs.lua\` | 1349 | **Peeled 2026-09-26 (\`LK-ATS-03\`), then accepted at 1293** …`
- `:192` `| … \`LibKa0s/OptionsWidgets.lua\` | 1444 | **Accepted 2026-09-26 …`
- `:188` `| … \`LibKa0s/Options.lua\` | 1288 | … **Re-ruled 2026-10-01 at v1.65.0 (\`DG-LIB-01\`): accepted** at 1282 …`

The issue store (`gh issue list --state all --limit 200 --json number,title,state,labels`) shows the
cited tracker as closed: `32 CLOSED bug,state:triaged,severity:low … LibKa0s/OptionsWidgets.lua is still
over layout-§1's cap after the chrome peel (2812)`.

The rule, from the fetched `automated-tests.md` (§4): *"an entry accepted across **three consecutive
release runs** is either fixed or converted into a tracked deviation with an ID and an owner, and the
watch list then points at the tracker."*

## E3. Lint ignore list — Checked

```
$ ~/.claude/dev-copilot/bin/ka0s-bounded luacheck . --enable 212 432 --only 212/self 212/event 432/self -q
Total: 152 warnings / 0 errors in 153 files
$ ~/.claude/dev-copilot/bin/ka0s-bounded luacheck . --no-config --std lua51 --exclude-files 'tests/_kit/*' --only 212/self 212/event 432/self -q
Total: 152 warnings / 0 errors in 153 files
```

- `.luacheckrc:64` reads `ignore = { "212/self", "212/event", "432/self" }`, with the reason at
  `:55-63`.
- The standard's own template (`lint`) carries `"212/self"` and `"212/event"`.
- `LK_TEST` is in `files["tests/"]` and not in top-level `read_globals`.

## E4. Line endings — Checked

```
$ test -f .gitattributes && echo present                 → present
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes   → 26:* text=auto eol=crlf
$ grep -nE '^\*\.(sh|py) text eol=lf$' .gitattributes      → 36:*.sh text eol=lf / 37:*.py text eol=lf
$ grep -c ' binary' .gitattributes                         → 23
$ tr -d '\r' < .gitattributes | head -84 | diff - <canonical client-bound body, line-endings.md:166-249>
  → BODY-IDENTICAL; tail after line 84: 0 lines
$ git ls-files -z | xargs -0 -I{} sh -c '…(AUDIT.md (e), verbatim)…' | wc -l
0
```

The check (e) scope is the whole tracked set with no exclusions.

## E5. Layout census and kit sync — Checked

```
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs wc -l | sort -rn | head
  65431 total
   1458 testkit/mock_base.lua
   1444 LibKa0s/OptionsWidgets.lua
   1359 LibKa0s/OptionsIds.lua
   1349 LibKa0s/OptionsTabs.lua
   1288 LibKa0s/Options.lua
   1246 LibKa0s/OptionsIdList.lua
    999 LibKa0s/DebugLog.lua
$ git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | wc -l
153
$ diff -r testkit tests/_kit && echo KIT-SYNC-EMPTY
KIT-SYNC-EMPTY
```

- **Scope:** authored Lua (`layout-§1`'s denominator). `tests/` is in, `tests/_kit/` is out, and there
  is no `libs/`. Nothing is over 1500 lines, and six files are in the band.
- `CLAUDE.md:94` reads `### Files over the 1500-line cap`, nested under `CLAUDE.md:69`
  `## Documented deviations`. `CLAUDE.md:125` reads *"**Nothing is over the cap today**…"*.

### `LK-29` (stale headroom figure)

- `CLAUDE.md:213`: `` - `testkit/mock_base.lua` (1458 with kit revision 37's two `mock_lines.lua` lines; …``
- `CLAUDE.md:219`: `file to the cap, with 44 lines of room; its \`RESULTS.md\` re-check trigger is 1490 lines, or any kit`
- `docs/automated-tests/RESULTS.md:193`: `| 1000–1500 (on notice) | \`testkit/mock_base.lua\` | 1458 | **On notice, re-read 2026-09-30 (\`DL-LIB-01\`): 44 lines from breach.** …`
- `wc -l < testkit/mock_base.lua` gives `1458`, and 1500 − 1458 = 42.
- `git log -1 -S'1458 with kit revision 37' -- CLAUDE.md` gives `ca0e3d7 2026-10-06 TL-LK-01: kit
  revision 37 - the mock answers Line regions (mock_lines.lua)`. The line count moved in that commit
  and the headroom figure did not.

## E6. Inventory — Checked

```
$ grep -c 'major = "LibKa0s-' tests/majors.lua      → 15
$ grep -c '<Script file=' LibKa0s/LibKa0s.xml       → 34
$ git ls-files 'LibKa0s/*.lua' | wc -l              → 34
$ lua -e '<sum #files per major in tests/majors.lua>'
  Widgets 5, DebugLog 3, Slash 2, Options 10, Perf 4, the other ten 1 each; total 34
$ git ls-files 'LibKa0s/media/icons/*.tga' | wc -l  → 113
$ git ls-files 'LibKa0s/media/textures/*' | wc -l   → 7
```

These agree with `library-stack-§7` (*"fifteen LibStub majors across thirty-four files"*) and with
`README.md`'s table at `:85-105`.

## E7. US-English sweep — `LK-28`

- **Scope.** The command was
  `git ls-files | grep -vE '^docs/(audits|reviews|adoption|superpowers)/|^docs/automated-tests/[0-9]|^tests/_kit/|\.(tga|png|ttf|json|otf)$' | grep -vE '^docs/api/'`.
  The newest `*-docs.md` of each `docs/api/<major>/` was added back, along with `docs/api/README.md`
  and `docs/api/CONSUMERS.md`, for 196 files in all.
  - **Excluded:** the frozen dated stores that `localization-§5` names, superseded per-version API
    documents, binaries, and the vendored copy of the kit.
- **Matcher.** The published lists from `testkit/prose_lists.lua` (`BRITISH`, then `ALLOWED` removed as
  whole words first), applied line by line with a scratch script outside the repo.

```
TOTAL 183 lines in 15 files
CHANGELOG.md 72                 # every hit at :1516 or later = v1.56.0's entry and older (released records)
CLAUDE.md 2                     # :73, :74 — register rows 1 and 2 quoting their own exemptions
LibKa0s/Media.lua 1             # :94 "minimise" — register row 2
docs/adoption-prompt.md 18      # LK-28
docs/adoption-report.md 4       # LK-28
testkit/mock_base.lua 5, testkit/mock_record.lua 6, tests/test_mock_ace.lua 6   # register row 1
testkit/prose_lists.lua 17, testkit/prose_selftests.lua 7, testkit/test_prose.lua 1, tests/test_prose.lua 41  # the gate quoting its lists
tools/artwork/icon_cleaner.py 1 # :93 "minimise": "minus" — the generator for row 2's key
docs/api/Media/version-4-docs.md 1   # :177 the `minimise` key — row 2
docs/api/README.md 1            # :353 `IsCancelled()` — a C_Timer API identifier (row 1's substance)
```

- **Unratified: 22 lines.**
  - `docs/adoption-prompt.md`: `:23` colour, `:68` Colour, `:242` colours, `:243` colour, `:257`
    modelling, `:313` judgement, `:325` coloured, `:347` judgement, `:360` colour, `:396` standardised,
    `:496` colours, `:501` colour, `:529` artefact, `:585` colour, `:590` behaviour, `:663` summarise,
    `:692` renormalise, `:725` colour.
  - `docs/adoption-report.md`: `:148` judgement, `:177` summarise, `:197` licence, `:235` behaviour.
  - Example: `docs/adoption-prompt.md:23` reads *"…KickCD found the colour-shape"*.
- **Both files are live documents.** `CLAUDE.md`'s `## Documentation map` has a row for each:
  `docs/adoption-prompt.md` *"The brief handed to a consumer repo adopting a major"* and
  `docs/adoption-report.md` *"The collection-wide adoption state"*.
  - `git log --format='%h %ad %s' --date=short -5 -- docs/adoption-prompt.md` shows `cfefa99`
    2026-10-04, `8f55167` 2026-10-02, `389a65b` 2026-10-01, `0cc0d6e` 2026-10-01 and `662da79`
    2026-09-26. All five post-date the 2026-09-24 sweep.
- Register row 3 (`CLAUDE.md:75`) classifies the file as a record: *"…21 in `docs/adoption-prompt.md`,
  and 23 in `testkit/test_prose.lua` itself…"*, within *"The other 1109 are records this repo must not
  rewrite or does not write at all"*.

## E8. Release process — Checked (closes `LK-19`, `LK-35`, `LK-36`)

```
$ for t in v1.55.0 … v1.70.0: grep -l "\"release\": *\"${t#v}\"" docs/automated-tests/*/manifest.json
v1.55.0: 20260923-144526   v1.56.0: 20260924-040553   v1.57.0: 20260924-225548   v1.58.0: 20260924-234934
v1.59.0: 20260925-170346   v1.60.0: 20260926-034006   v1.61.0: 20260926-121411   v1.62.0: 20260926-182957
v1.63.0: 20260929-092750 20260929-111323 20260929-113624   v1.64.0: 20260930-151415 20260930-153012 20260930-183150
v1.65.0: 20261001-000959 20261001-001312   v1.66.0: 20261001-122702 20261001-133255   v1.67.0: 20261002-012529
v1.68.0: 20261002-231003 20261002-231513 20261002-232612   v1.68.1: 20261004-143758   v1.69.0: 20261006-134107
v1.70.0: 20261007-102304
```

- Each release run's final bundle, from `20260924-040553` on, lists `ANALYSIS.md`. `20260923-144526`
  (v1.55.0) does not; it is the gap `LK-19` named, and it is not back-filled.
- `docs/releasing.md:135` reads `1. **Write \`docs/automated-tests/<stamp>/ANALYSIS.md\`** per the
  uniform analysis prompt…`, and `:180` reads `test -f docs/automated-tests/<stamp>/ANALYSIS.md && echo
  present`.
- A per-entry count of perf-skip lines in `CHANGELOG.md` is 1 or more for every entry from v1.56.0 to
  v1.70.0. Example, `CHANGELOG.md:76-78`: *"Release gate (`docs/automated-tests/20261007-102304/`): …
  Perf SKIPPED, not measured — no `tests/perf.lua` — so the gate covered three suites, not four."*
- `docs/automated-tests/20260924-040553/ANALYSIS.md:126` reads *"**Six tags shipped with no bundle.**
  `v1.28.0`, `v1.29.0`, `v1.36.0`, `v1.36.1`, `v1.54.1` and"*.
- `:140` of the same file reads *"**`20260908-181447/ANALYSIS.md:92` over-counted by one**"*, which
  closes `LK-32`.
- `docs/automated-tests/RESULTS.md:179-180` holds the warned-functions header row and its separator,
  which closes `LK-30`.

## E9. Compat — `LK-39`

```
$ git ls-files 'LibKa0s/*.lua' | xargs grep -nE '\b(GetAddOnMetadata|IsAddOnLoaded|GetSpellInfo|…|GetSpecializationInfo)\b' | grep -v '^LibKa0s/Compat.lua'
LibKa0s/Env.lua:60:function lib.GetAddOnMetadata(addonName, field)
LibKa0s/Env.lua:61:  if C_AddOns and C_AddOns.GetAddOnMetadata then
LibKa0s/Env.lua:62:    return C_AddOns.GetAddOnMetadata(addonName, field)
LibKa0s/Env.lua:64:  if GetAddOnMetadata then
LibKa0s/Env.lua:65:    return GetAddOnMetadata(addonName, field)
LibKa0s/OptionsIdList.lua:485:    local api = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
LibKa0s/OptionsIds.lua:52:  local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(key)
LibKa0s/Perf.lua:411-416 … (register row 4)
```

- `LibKa0s/Env.lua:52-53` reads *"The reader moved under `C_AddOns` in 10.x and the bare global is
  deprecated but still present, / so both rungs are live…"*.
- The fetched `compat.md` worked case reads *"`GetAddOnMetadata` behind `C_AddOns.GetAddOnMetadata` in a
  library-absent stub (the global survives only as the newer namespace's member)"*, under *"A dead
  fallback rung is deleted, not shimmed … **MUST** be deleted rather than kept … wherever it sits"*.
- `git log -S'IsAddOnLoaded' -- LibKa0s/OptionsIdList.lua` gives `008a87a 2026-10-02 CA-LK-02:
  OptionsIdList minor 3 - the help art checks addonName against the loaded addons…`.
- The read-globals that admit both are `.luacheckrc:8` (`"C_AddOns", "GetAddOnMetadata",`) and `:9`
  (`"IsAddOnLoaded",   -- the deprecated rung of the id list help-art guard (OptionsIdList minor 3)`).
- The test that pins the Env rung is `tests/test_env.lua:31`: `test("env: GetAddOnMetadata falls back to
  the deprecated bare global", function()`.
- Not run: the live-client check is the owner's (`/dump GetAddOnMetadata, IsAddOnLoaded`).

## E10. Events — register row 5 trigger — Checked

```
$ git ls-files 'LibKa0s/*.lua' | xargs grep -nE 'RegisterEvent|RegisterUnitEvent' | (non-comment, non-helper lines)
LibKa0s/OptionsCombat.lua:90:      f:RegisterEvent("PLAYER_REGEN_DISABLED")
LibKa0s/OptionsCombat.lua:91:      f:RegisterEvent("PLAYER_REGEN_ENABLED")
LibKa0s/OptionsCombat.lua:127:    f:RegisterEvent("PLAYER_REGEN_DISABLED")
LibKa0s/OptionsCombat.lua:128:    f:RegisterEvent("PLAYER_REGEN_ENABLED")
LibKa0s/OptionsRegistry.lua:92:  f:RegisterEvent("PLAYER_REGEN_ENABLED")
LibKa0s/Widgets.lua:392:    m:RegisterEvent("GLOBAL_MOUSE_DOWN")
```

- These are the same three frames row 5 names. No new name was added, and the new files
  (`WidgetsLineChart.lua`, `WidgetsAutocomplete.lua`) register no events.
- The helper family is at `LibKa0s/Core.lua:478` (`function lib.SafeRegisterEvent(target, event,
  handler, rejected)`) through `:497`.

## E11. Register evidence ids — `LK-42`

```
$ grep -rn 'LibKa0s-A-07\|LibKa0s-A-10\|LibKa0s-A-03' docs/audits docs/reviews
(no output)
$ grep -rln 'LibKa0s-A-' docs/ CLAUDE.md
docs/api/testkit/version-26-docs.md
docs/automated-tests/20260924-040553/ANALYSIS.md
CLAUDE.md
$ grep -n 'LibKa0s-A-' ../Ka0sAddonsCommonTasks/docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/05_TRACEABILITY.md
68:| LibKa0s-A-03 | low | C14 | LK-32 | M1 |
72:| LibKa0s-A-07 | low | C12 | LK-29 | M1 |
75:| LibKa0s-A-10 | info | C03 | LK-30 | M1 |
$ grep -n 'LibKa0s-A-0[37]\b\|LibKa0s-A-10\b' ../Ka0sAddonsCommonTasks/docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/01_CONSOLIDATED_FINDINGS.md
276:  - **LibKa0s-A-10** `info` (audit LK-37; corrected) — Payload registers client events raw …
1151: - **LibKa0s-A-07** `low` (audit LK-28; corrected) — 210 British spellings in 33 live authored files
1284: - **LibKa0s-A-03** `low` (audit LK-17d; confirmed) — Five of ten on-notice watch-list dispositions …
```

- `CLAUDE.md:75`: *"…That sweep landed on 2026-09-24 (`LK-29`, resolving the 2026-09-23 audit's
  `LibKa0s-A-07`)…"*.
- `CLAUDE.md:77`: *"…Filed as `LibKa0s-A-10` by the 2026-09-23 audit…"* and *"2026-09-24, executing
  `LK-30` of the 2026-09-23 remediation plan"*.
- `CLAUDE.md:335`: *"…2026-09-23 audit (`LibKa0s-A-03`) found seven band files…"*.
- This repo's own `docs/audits/2026-09-23/02_DEVIATIONS.md` gives `LK-29` as *"Hand-maintained figures
  in root `CLAUDE.md` disagree with the tree"* and `LK-30` as *"The warned-functions half of the watch
  list is still prose…"*. These are different findings from the plan items the register means.
- The rows that do resolve:
  - row 1: `1f1790c`, and `docs/api/testkit/version-17-docs.md` exists;
  - row 2: `LK-06` is at `docs/audits/2026-09-07/02_DEVIATIONS.md:34`;
  - row 4: `LK-31` is at `docs/audits/2026-09-08/02_DEVIATIONS.md:41`;
  - row 6: `../LootHistory/docs/superpowers/specs/2026-10-06-timeline-ledger-design.md` exists, with 3
    `F3` hits.

## E12. Register triggers — Checked

- **Row 2.** `ls LibKa0s/media/icons | grep -i minim` returns `minimise.tga` only.
  `LibKa0s/Media.lua:202` is `function lib.Icon(addonName, name, vendorPath)`, and `:206` is
  `return base .. ICON_DIR .. "\\" .. name`. There is no alias map.
- **Row 3.** `testkit/test_prose.lua` has no non-ASCII or retired-section case. `grep -n -i
  'ascii\|retired' testkit/test_prose.lua` finds only comments. `testkit/prose_lists.lua:78-83`
  (`SKIPPED_DIRS`) names `docs/audits/ … docs/superpowers/, docs/investigations/` and does not name
  `docs/api/` or `docs/adoption/`.
- **Row 4.** `LibKa0s/Perf.lua:23` reads `local NEEDS_CORE = 1` and `:34` reads
  `local NEEDS_LIFECYCLE = 1`. `git log --since="2026-09-23 00:00" -S'NEEDS_' -- 'LibKa0s/Perf*.lua'`
  is empty. `LibKa0s/Compat.lua:270` is `function lib.GetSpecialization()` and `:289` is
  `function lib.GetSpecializationInfo(index)`.
- **Row 5.** See §E10.
- **Row 6.** `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | xargs grep -l LineChart`, run in
  each sibling, finds LootHistory `core/WidgetsSetup.lua`, `modules/Timeline.lua` and
  `tests/test_libka0s.lua`. WhatGroup's `tests/loader.lua` lists the file in a load list and draws
  nothing. Every sibling's `CLAUDE.md` provenance line names `v1.70.0`.

## E13. Issue store — `LK-40`, inverse rule

```
$ gh issue list --state all --limit 200 --json number,title,state,labels,createdAt
44 issues; open: #3, #5, #6, #43, #44 (all state:triaged)
32  CLOSED  bug,state:triaged,severity:low          LibKa0s/OptionsWidgets.lua is still over layout-§1's cap after the chrome peel (2812)
33  CLOSED  enhancement,state:triaged,severity:low  tests/test_options_widgets.lua is still over layout-§1's cap after the chrome peel (3219)
37  CLOSED  enhancement,state:triaged,severity:low  tests/test_widgets.lua: split by widget family (1493, seven lines from the cap)
39  CLOSED  enhancement,state:triaged,severity:low  testkit/test_prose.lua: peel the narrowing/coverage machinery (1486, fourteen lines from the cap)
state:will-not-do: #10, #21, #22, #23, #24, #25, #26
```

- No `[status]` title prefixes. No `docs/pending/`. Every issue has one `state:` and one `severity:`
  label.
- `gh` subcommands only, never GraphQL.
- The will-not-do issues are plan-scope or API declines:
  - #23–#26: *"declined — kit 15 is additive"*, *"… cycle does not ship"*, and similar;
  - #10: the dropdown skin's owner;
  - #21: *"Rebind lib.MakeCloseButton: declined — the library cannot infer the vendor path"*;
  - #22: the `minimise` key, which already has register row 2.

  None declines a binding MUST or SHOULD, so none owes a row.

## E14. Citation sweep — `LK-41`, Checked

- **Range check.** The scope was the live set: `git ls-files`, minus the frozen stores and binaries, for
  383 files. The sweep was `grep -noE "\b(<27 section names>)-§[0-9]+"`, then an awk range check
  against §E0's counts.
  - Output: 3353 citations, **0** out of range.
- **Retired and bare forms.**
  - `git ls-files 'LibKa0s/*.lua' 'testkit/*' | xargs grep -noE '§[0-9]+\.[0-9]+' | wc -l` gives `0`.
  - The bare continuation form (`(^|[^a-z-])§[0-9]+`) gives `48`. These are noted, not filed.
- **`LK-41`.** `LibKa0s/Slash.lua:267` reads `-- (slash-commands.md:34). A store missing any of them is
  no store, so nothing is half-called.`
  - The fetched `slash-commands.md:34` reads *"- The lib depends on **LibStub and
    `LibKa0s-Core-1.0` and nothing else** — no AceEvent, AceGUI or AceConsole…"*, which is in §1
    (`### 2. Verb naming` is at `:36`).
  - `gh issue view 43` reads *"Ship it with the next LibKa0s release that touches the payload"*.
  - v1.69.0 and v1.70.0 both touched the payload: `WidgetsLineChart.lua` and `WidgetsAutocomplete.lua`.

## E15. Documentation map, frozen bundles, substitutes — Checked

- **Documentation map.**
  - `.md` files under `docs/` outside `audits/`, `reviews/`, `automated-tests/<stamp>/`, `adoption/`,
    `superpowers/` and `api/`: `docs/adoption-prompt.md`, `docs/adoption-report.md`,
    `docs/automated-tests/README.md`, `docs/automated-tests/RESULTS.md`,
    `docs/fast-gate-adoption-prompt.md`, `docs/record-schema.md`, `docs/releasing.md` and
    `docs/test-cases.md`. Each has a map row.
  - `docs/api/README.md` and `docs/api/CONSUMERS.md` fall under the `docs/api/` row, and CONSUMERS has
    its own.
  - All 13 map rows resolve with `[ -e path ]`.
- **Frozen bundles.** `git log --format=%h -- <bundle> | wc -l` is 1 for each of `docs/audits/{2026-08-05,
  2026-09-07,2026-09-08,2026-09-23}` and `docs/reviews/{2026-07-31,2026-08-05,2026-09-07,2026-09-23}`.
  No `docs/automated-tests/2026*` bundle has more than 1.
- **Substitutes.**
  - `README.md:3` reads *"Built to the **[Ka0s WoW Addon Standard](…)**, v2.76.0,"*.
  - `CLAUDE.md:41` is `## Standards compliance (read first)`.
  - `DEPENDENCIES.md` is present.
  - `test -f TODO.md` is false.
- **Tags.** `git cat-file -t v1.70.0` and `v1.69.0` both give `tag`.
- **`library-stack-§9`.** `LibKa0s/Options.lua:312` reads `local currentVersion =
  AceGUI:GetWidgetVersion("LSM30_Border") or 1`, and `:314` reads
  `AceGUI:RegisterWidgetType("LSM30_Border", function()`.

## E16. Upstream observation U1 (not counted)

- `LibKa0s/OptionsWidgets.lua:33` reads `-- host that trips this floor has a broken copy rather than an
  unlucky one. The floor is also`.
- `:37` reads `local Pool = LibStub and LibStub("LibKa0s-Pool-1.0", true)`, and `:38` reads
  `local NEEDS_POOL = 1`.
- `LibKa0s/OptionsNav.lua:20-22` carries the same Pool floor.
- The fetched `library-stack.md:118` cites *"(`OptionsWidgets.lua:33`, `OptionsTabs.lua:38`)"*.
  `OptionsTabs.lua:38` resolves correctly.
