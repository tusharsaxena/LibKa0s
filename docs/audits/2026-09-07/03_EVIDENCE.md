# 03 — Evidence

Every `file:line` below was re-read and its text quoted beside it before this file was written.
Every count below was produced by the command printed with it, run from
`/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s` on **2026-09-07**, and each command's **scope**
— what it swept and what it did not — is stated. No figure is carried over from the 2026-08-05
bundle or from memory.

**A note on one number.** The line-ending straggler count below (**7**) is far lower than a
pre-v2.28.1 audit would have reported for the same tree, because the old command counted every
binary and every JSON file as a stray. The 2026-08-05 bundle is frozen and is not edited; the two
numbers are not comparable and this paragraph is why.

---

## 1. Lint — `lint`

```
$ luacheck --version
Luacheck: 1.2.0
$ luacheck .
...
Checking testkit/vendor_sync.lua                  OK

Total: 0 warnings / 0 errors in 18 files
```

**Scope:** whole repo, minus `.luacheckrc:4`'s `exclude_files = { "tests/", "docs/" }`. The 18 files
are the 14 `.lua` in `LibKa0s/` and the 4 in `testkit/`. **No test code is linted.** That exclusion
is disclosed in `CLAUDE.md:116-118` — *"That `luacheck` figure is **scoped by `.luacheckrc`'s
`exclude_files`**, not repo-wide — eighteen files today, the fourteen in `LibKa0s/` plus four under
`testkit/`."* — and in `DEPENDENCIES.md:120`.

## 2. Headless suite — `testing-§1`

```
$ lua -v
Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio
$ lua tests/run.lua
...
  PASS  kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included
  PASS  prose: no British spelling in the shipped library or the shipped kit
  PASS  prose: no retired §N.M section reference in the shipped library or the shipped kit
  PASS  eol: every tracked bundle file carries the terminator .gitattributes declares for it

764 passed, 0 failed, 0 skipped, 764 total
```

**Scope:** the 22 suites declared at `tests/run.lua:112-118`. Note the last three PASS lines: each
is a gate whose *scope* is narrower than its name, and two of them are findings — see §7 and §8.

## 3. Complexity — `automated-tests-§1`, `performance-§10`

The standard's invocation, verbatim:

```
$ lizard --version
1.24.0
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
...
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
     13678       6.6     1.9       51.1     1900            0      0.00    0.00
```

**Scope:** repo root, excluding `./libs/*` (absent here) and `./tests/_kit/*`. Covers `LibKa0s/`,
`testkit/` and `tests/`.

**Drift against the newest bundle: none.**
`docs/automated-tests/20260903-161751/complexity.txt`'s footer reads the identical line —
`13678 6.6 1.9 51.1 1900 0 0.00 0.00`. The record is **not** stale in its numbers (anti-pattern #51
does not fire on the measurement). Bundle stamp `20260903-161751`, four days old; its
`manifest.json` reads `"addonVersion": "1.24.0", "release": "1.25.0"`.

**But `manifest.json` also carries `"bandFiles": 4, "overCapFiles": 2`** — and nothing reads those
fields. Measured directly:

```
$ find LibKa0s testkit tests -name '*.lua' -not -path 'tests/_kit/*' | xargs wc -l | sort -rn | head -7
  22457 total
   2287 tests/test_options_widgets.lua
   1838 LibKa0s/OptionsWidgets.lua
   1493 tests/test_widgets.lua
   1232 LibKa0s/Widgets.lua
   1163 LibKa0s/Perf.lua
   1146 tests/test_options.lua
```

**Scope:** `LibKa0s/`, `testkit/`, `tests/`, excluding the vendored `tests/_kit/`. Two files over
`layout-§1`'s 1500 cap; four in the 1000–1500 band. **LK-18.**

## 4. Watch list as a decision record — `automated-tests-§4`, anti-pattern #53

`docs/automated-tests/RESULTS.md:119` — *"Current state as of [`20260823-235820`](20260823-235820/)
— not that run's diff."* The newest table row (`:15`) is
`| [`20260903-161751`](20260903-161751/) | 1.24.0 | 0/0 | 18 | 764/764 | skip | 13678 | 1900 | 6.6 | 1.9 | 14 | 0 | **green** |`.
The watch list is **eight runs behind its own table**.

`RESULTS.md:158` — *"Nothing is over the 1500 cap."* Contradicted by §3 above. **LK-18, LK-17.**

`RESULTS.md:49` — *"499 cases, spread across the library's own surfaces and the kit it vendors"* —
against 764. `RESULTS.md:58` — *"The count is now flat at 499 across three runs"*. **LK-17.**

`RESULTS.md:79-81` — *"Clean over 12 files: 0 warnings, 0 errors. … `luacheck .` covers the 8 shipped
library files under `LibKa0s/` plus the 4 Lua sources in `testkit/`"* — against 18 and 14. **LK-17.**

The commit that corrected exactly these figures elsewhere and skipped this file:

```
$ git show --stat ab221d4 | tail -4
 DEPENDENCIES.md | 10 +++++-----
 README.md       | 18 ++++++++++--------
 2 files changed, 15 insertions(+), 13 deletions(-)
```

Its message reads *"`DEPENDENCIES.md` carried the same arithmetic one file behind: `luacheck .`
covers 18 files, not 12"* — the same sentence `RESULTS.md:79` still gets wrong.

**Accepted-disposition streak.** `RESULTS.md:151-157` — *"The new row is owed what the other two now
have: an issue with an owner … Its shelf-life clock starts at v1.8.3"*. Releases since v1.8.3, from
the same table:

```
$ gh issue list --state all --limit 200 --json number,title,state,labels --jq '.[] | select(.title|test("test_options")) | "\(.number) \(.state) \(.title)"'
8 OPEN test_options_widgets.lua sits in the layout-§1 on-notice band (1114 LOC)
```

**Scope:** all issues, open and closed. Only `test_options_widgets.lua` has one; **`test_options.lua`
has no issue**, and 23 release runs (v1.9.0 … v1.25.0) have shipped since its clock started. §4 caps
that at three. **LK-17d.**

## 5. The `LSMValues` double-wrap — **LK-16**

`LibKa0s/Options.lua:764-776` (the definition, which already returns the closure):

```lua
  function O.LSMValues(mediaType)
    return function()
      local LSM = type(d.getLSM) == "function" and d.getLSM() or nil
```

`LibKa0s/OptionsCompose.lua:231`, `:275`, `:304` (the three call sites, each wrapping it again):

```lua
      values = function() return O.LSMValues("font") end,
      values = function() return O.LSMValues("border") end,
      values = function() return O.LSMValues("statusbar") end,
```

`LibKa0s/OptionsWidgets.lua:78-79` (where it becomes an empty dropdown):

```lua
  local v = type(row.values) == "function" and row.values() or row.values
  if type(v) ~= "table" then return {} end
```

`row.values()` answers a **function**, so `type(v) ~= "table"` and the widget draws with no entries.

**Recorded, not fixed.** Issue #15, `state:untriaged`, `severity:high`, open:

```
$ gh issue list --state all --limit 200 --json number,title,state,labels
… {"number":15,"state":"OPEN","title":"OptionsCompose: media rows double-wrap O.LSMValues, so every
composed font/border/texture dropdown renders empty","labels":[bug, state:untriaged, severity:high]}
```

**Scope:** all 15 issues on this repo. The bytes are shipped: `CHANGELOG.md:15-18` puts
`OptionsCompose minor 2` in v1.25.0, the tag consumers re-vendor today.

**No test can catch it.** `tests/test_options_compose.lua` carries exactly one `values` assertion:

```
$ grep -n 'values\|LSM' tests/test_options_compose.lua
274:  assertEqual(rows[2].values, O.VISIBILITY_VALUES, "visibility is a dropdown, not a boolean")
```

**Scope:** the whole composer suite. Nothing calls `rows[n].values()` and asserts a table. **LK-16d.**

## 6. British spelling in the shipped payload — **LK-06**

```
$ grep -rniE 'minimis|organis|optimis|initialis|serialis|customis|prioritis|centre|licence|analyse|favourite|defence|labelled|modelled|cancelled|travelled' LibKa0s/*.lua testkit/*.lua | wc -l
11
```

**Scope:** the two **shipped** directories only — `LibKa0s/*.lua` and `testkit/*.lua`, non-recursive,
so `LibKa0s/media/` is excluded. `tests/`, `docs/`, `CHANGELOG.md` and the frozen bundles were **not**
swept: `CHANGELOG.md` is released history that stays, and `tests/` prose never leaves this repo.

The hits that matter, re-read:

- `LibKa0s/Media.lua:94` — `"close", "minimise", "expand", "lock", "unlock", "settings", "segment", "reset", "export",`
  A **public catalog key**, which `library-stack-§7`'s additive-only rule makes permanent surface.
- `LibKa0s/Perf.lua:723` — `add("capture: %s  (%s, schema %d, v%s)", record.label ~= "" and record.label or "unlabelled",`
- `LibKa0s/Perf.lua:864` — `P.Log("run started \226\128\148 %s", P.label or "unlabelled")`
- `LibKa0s/Perf.lua:948` — `P.Log("run CANCELLED \226\128\148 measurements discarded, nothing saved")`
- `LibKa0s/Perf.lua:1029` — `P.Announce("perf run |cff40ff40STARTED|r \226\128\148 %s", P.label or "unlabelled")`
- `LibKa0s/Perf.lua:1063` — `out[#out + 1] = "perf run |cffcc5252CANCELLED|r \226\128\148 nothing saved"`

Five of those six are text a **player sees** in chat or in the perf log.

**Why the green gate does not see them.** `tests/test_prose.lua:113`:

```lua
local BRITISH = { "colour", "grey", "behaviour", "synthesise", "normalis", "recognis" }
```

Six substrings. anti-pattern #46 names `centre`, `cancelled` and `-ise`/`-isation`, none of which
this list can match. The case passes today against a payload that fails the rule. **LK-06d.**

## 7. Line endings — `line-endings`

```
$ test -f .gitattributes && echo present
present
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes
26:* text=auto eol=crlf
$ grep -n '^\*\.sh text eol=lf$' .gitattributes
34:*.sh text eol=lf
$ grep -c ' binary$' .gitattributes
20
```

The pin is correct for this repo's **kind**: `library-stack-§7` names `LibKa0s` client-bound
explicitly — *"the library ships Lua into every consumer's client-bound `libs/` folder, so it is
**client-bound** and takes the CRLF pin"* — which is exactly what `.gitattributes:15-17` says.

**Body diff against `line-endings-§5`'s canonical client-bound file** (extracted from the fetched
section, repo copy stripped of CR for comparison):

```
$ diff /tmp/canon_ga.txt /tmp/repo_ga.txt && echo "IDENTICAL (modulo CRLF)"
IDENTICAL (modulo CRLF)
```

81 lines, byte-for-byte. This is **not** the `*.sh`-only near-miss `line-endings-§1` names.

**(e) — does the working tree agree with the pin?** Run exactly as `line-endings-§7` writes it:

```
$ git ls-files -z | xargs -0 -I{} sh -c '
    set -- $(git check-attr text eol -- "{}" | sed "s/.*: //")
    [ "$1" = unset ] && exit
    cr=$(tr -dc "\r" < "{}" | wc -c); lf=$(tr -dc "\n" < "{}" | wc -c)
    case "$2" in crlf) [ "$lf" -gt 0 ] && [ "$cr" -ne "$lf" ] && echo "{}";;
                 lf)   [ "$cr" -gt 0 ] && echo "{}";; esac' 2>/dev/null | wc -l
7
```

**Scope:** every path `git ls-files` tracks — the whole repo including `docs/`, `tests/`, the frozen
bundles and `tools/` — with `binary`-marked paths skipped by the `text: unset` test. Reported as
**one** finding; the fix is a single `git add --renormalize .` plus a re-checkout, so the files are
not enumerated here. Two of the seven are **shipped payload**, and both are fully LF
(`cr=0, lf=793` and `cr=0, lf=226`) — written by a tool that bypassed git's filters, not
half-converted. **LK-24.**

**Why the repo's own gate is green anyway** — `tests/test_eol.lua:29`:

```lua
local BUNDLES = "docs/automated-tests"
```

The gate walks `git ls-files -- docs/automated-tests` and nothing else, so it is structurally blind
to all seven. Its own header (`:1`) calls it *"the working-tree line-ending gate over the
automated-test bundles"*. **LK-24d.**

## 8. `RESULTS.md`'s lead-in, and the fix that cannot reach it — **LK-21**

`docs/automated-tests/RESULTS.md:9-11`:

```
**`lint` and `tests` gate. `perf` and `complexity` are recorded and never fail a run** —
they are read and compared, not thresholded. A `skip` is a suite that did not run at all,
which is never the same as a pass.
```

No commit checkpoint; no tag gate; no *"zero functions above CCN 15"*; no *NOT EVALUATED*.
`automated-tests-§4` requires all four.

The corrected text **exists**, at `testkit/run-automated-tests.sh:425-432`:

```sh
            printf '**`lint` and `tests` gate the run and gate the commit** (`testing-§4`).\n'
            printf '**`perf` and `complexity` never fail a run and never block a commit** — they are recorded,\n'
            …
            printf '**The tag is gated on all four suites at `pass`, plus zero functions above CCN 15**\n'
```

and it sits inside the branch reached only when the file is absent — `:407` is
`elif [ -f "$RESULTS" ]; then` (the *"older column set … not touching it"* warning) and `:413` is the
`else` that creates the file. An existing `RESULTS.md` never gets the new prose. This repo has one,
and so does every consumer. **Cross-cutting.**

## 9. The dropped `skipped` figure — **LK-22**

`testkit/run-automated-tests.sh:195`:

```sh
    line="$(printf '%s\n' "$clean" | grep -oE '[0-9]+ passed, [0-9]+ failed(, [0-9]+ total)?' | tail -1)"
```

The harness prints `764 passed, 0 failed, 0 skipped, 764 total` (§2 above). The regex matches only
`764 passed, 0 failed`, so `$5` is empty and `:200` falls back:

```sh
            [ -z "$TESTS_TOTAL" ] && TESTS_TOTAL=$(( TESTS_PASS + TESTS_FAIL ))
```

The row at `:388` is `$(cell tests "$TESTS_PASS/$TESTS_TOTAL")` and the manifest at `:369` is
`", \"passed\": $TESTS_PASS, \"failed\": $TESTS_FAIL, \"total\": $TESTS_TOTAL, $GATE_COMMIT"`.

```
$ grep -c 'TESTS_SKIP' testkit/run-automated-tests.sh
0
```

**Scope:** the runner's whole source. There is no skipped-count variable at all — the three
`skipped` matches in the file are prose in comments (`:295`, `:432`, `:486`), never a captured
figure. `automated-tests-§4`: *"The `tests`
column **MUST** carry the **skipped** figure alongside passed and total, and **MUST NOT** fold a skip
into either."* Today `skipped` is 0, so no published number is wrong yet — a latent wrong total in
ten repos.

## 10. Release-run records — **LK-19**, **LK-20**

```
$ tot=0; miss=0; for d in docs/automated-tests/2*/; do
    r=$(python3 -c "import json;print(json.load(open('$d/manifest.json')).get('release'))");
    if [ "$r" != "None" ]; then tot=$((tot+1)); [ -f "$d/ANALYSIS.md" ] || { miss=$((miss+1)); echo "MISSING: $(basename $d) release=$r"; }; fi; done;
  echo "release runs=$tot missing ANALYSIS.md=$miss"
MISSING: 20260806-180959 release=1.8.1
MISSING: 20260807-102629 release=1.8.2
MISSING: 20260807-105553 release=1.8.2
MISSING: 20260824-024124 release=1.11.0
MISSING: 20260824-031024 release=1.11.1
MISSING: 20260825-021432 release=1.14.0
MISSING: 20260825-032030 release=1.15.0
MISSING: 20260825-142319 release=1.16.0
MISSING: 20260825-172722 release=1.17.0
MISSING: 20260826-165334 release=1.18.0
MISSING: 20260826-185819 release=1.18.1
MISSING: 20260827-110439 release=1.19.0
MISSING: 20260827-153332 release=1.20.0
MISSING: 20260831-160633 release=1.21.0
MISSING: 20260831-180722 release=1.22.0
MISSING: 20260831-185425 release=1.23.0
MISSING: 20260903-161751 release=1.25.0
release runs=28 missing ANALYSIS.md=17
```

**Scope:** all 31 bundles under `docs/automated-tests/`; the 3 with `"release": null` are ordinary
runs and are excluded (§5 makes the write-up a MUST at release, a SHOULD otherwise). 12 of the 17
are consecutive: v1.14.0 through v1.25.0.

**And one release has no bundle at all:**

```
$ git tag --sort=-v:refname | head -4
v1.25.0
v1.24.0
v1.23.0
v1.22.0
```

The listing above goes `release=1.23.0` → `release=1.25.0`. No bundle names **v1.24.0**.
`automated-tests-§6`: *"MUST produce a full four-suite bundle as part of every release … before the
tag."* **LK-20.**

`docs/releasing.md:76` **does** run the bundle and `:88-91` **does** read the release gate — so
`LK-07` and `LK-08` from the 2026-08-05 run are **closed**. What step 7 never names is the write-up.

## 11. Deprecated API called directly — **LK-23**

`LibKa0s/Perf.lua:615-618`:

```lua
      if GetSpecialization and GetSpecializationInfo then
          local index = GetSpecialization()
          if index then
              local _, name = GetSpecializationInfo(index)
```

`compat` names both as deprecated post-11.x and gives the replacement,
`C_SpecializationInfo.GetSpecialization()`. There is no such branch here. The repo already knows the
shape — `LibKa0s/Env.lua:60-66`:

```lua
function lib.GetAddOnMetadata(addonName, field)
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    return C_AddOns.GetAddOnMetadata(addonName, field)
  end
  if GetAddOnMetadata then
    return GetAddOnMetadata(addonName, field)
  end
```

The guard means the failure is silent: `ctx.spec` stays `"?"` (`:608`) in every consumer's perf
record the day the globals go.

```
$ grep -n 'GetSpecialization\|C_SpecializationInfo' LibKa0s/*.lua
LibKa0s/Perf.lua:615:      if GetSpecialization and GetSpecializationInfo then
```

**Scope:** the whole shipped payload. One site; no `C_SpecializationInfo` anywhere.

## 12. The register, and the decision that is not in it — **LK-25**

`CLAUDE.md:64-70`:

```
## Documented deviations

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|

**None ratified today.** The table is here empty on purpose…
```

But `docs/automated-tests/RESULTS.md:97-99` ratifies one:

```
**This repo ships no `tests/perf.lua`, so `perf` is a permanent `skip` — not a pass, and not a
transient tooling gap.** That is the first of `automated-tests-§3`'s two sanctioned reasons…
```

and `:113-115` records the disposition *"dated, with the condition that would reopen it"*, pointing
at `docs/automated-tests/README.md` § *Why that skip is permanent*.

```
$ ls tests/perf.lua
ls: cannot access 'tests/perf.lua': No such file or directory
```

`library-stack-§7` substitute 4 and `CLAUDE.md:47-53` both make that table the **single** home of a
ratified decision — *"The reasoning may live in an audit or review bundle and the row cites it, but a
deviation not in the register is not ratified."* The reasoning is excellent and the row is absent.

**The inverse check, run and clean.** The one `state:will-not-do` issue is #10, *"the flat dropdown
skin belongs to OptionsWidgets makeDropdown, not to each consumer"* — a declined **enhancement**, not
a declined standards rule, so it owes no register row. No register row cites a rule the standard has
since changed (the register is empty).

## 13. Checks that passed, with the command that proved it

```
$ ls docs/complexity.md docs/perf-runs docs/pending docs/file-index.md docs/conventions.md
ls: cannot access 'docs/complexity.md': No such file or directory
ls: cannot access 'docs/perf-runs': No such file or directory
ls: cannot access 'docs/pending': No such file or directory
ls: cannot access 'docs/file-index.md': No such file or directory
ls: cannot access 'docs/conventions.md': No such file or directory
```

Retired artefacts all absent (`documentation-§3`, `performance-§8`, anti-pattern #60).

```
$ grep -nE '§[0-9]+\.[0-9]+' README.md CLAUDE.md DEPENDENCIES.md docs/releasing.md docs/record-schema.md \
    docs/adoption-prompt.md docs/adoption-report.md docs/fast-gate-adoption-prompt.md docs/test-cases.md \
    docs/automated-tests/README.md docs/automated-tests/RESULTS.md LibKa0s/*.lua testkit/*.lua tests/*.lua
tests/fixture_options.lua:33:    -- string + no `values` list, declared as a free-text row. The fifth widget type (spec §5.2),
```

**Scope:** the live doc set and all authored Lua — deliberately **excluding** `CHANGELOG.md` (released
history), `docs/superpowers/`, `docs/adoption/`, `docs/reviews/`, `docs/audits/` and the frozen
`docs/automated-tests/<run>/` bundles, none of which is edited. The single hit cites a **design
spec's own** numbering, not the standard's retired global scheme. `documentation-§5` **clean**.

```
$ git ls-files -s testkit/run-automated-tests.sh tests/_kit/run-automated-tests.sh
100755 c35d42398128ba52382ac9c9a7a8874c3baacc83 0	testkit/run-automated-tests.sh
100755 c35d42398128ba52382ac9c9a7a8874c3baacc83 0	tests/_kit/run-automated-tests.sh
```

Same blob, same mode, in both copies — `automated-tests-§2` and `testing-§11` clean. The harness lives
under `tests/`, never `libs/`, as §7 requires; there is no `libs/` here at all.

`tests/run.lua:24` — `Loader.loadAll(Loader.xmlFiles("LibKa0s/LibKa0s.xml"), nil, mocks)` — the load
list is **derived**, not re-typed. `testkit/framework.lua:277` — `function Kit.assertSuiteInventory(dir, suites)`
— pins the declared suite list in both directions, with distinct messages per direction (`:300-308`).
`testing-§9` **clean**; `LK-09` closed.

`tests/test_versioning.lua:165` — `test("versioning: every major's live version has its API document on disk", function()`
— `testing-§10` **clean**; `LK-15` closed.

`CLAUDE.md:76-105`'s `## Documentation map` — every live `.md` under `docs/` has a row or falls under
one of the five named frozen directories, and every row resolves. Checked in both directions against
`find docs -maxdepth 1 -name '*.md'` and `find docs -mindepth 1 -maxdepth 1 -type d`. **Clean.**
