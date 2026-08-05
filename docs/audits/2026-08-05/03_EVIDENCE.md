# 03 — Evidence

Every claim in `01_CURRENT_STATE.md` and `02_DEVIATIONS.md`, sourced. Mechanical checks were **run**,
from the repo root, on 2026-08-05, at HEAD `a29fd63`; the real commands and their real output are
below. Nothing here is inferred from reading code.

---

## A. Mechanical checks

### A1. Resolving the standard

```
$ RAW=https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master
$ curl -fsSL "$RAW/AUDIT.md" -o AUDIT.md                      # 158 lines
$ curl -fsSL "$RAW/standards/STANDARDS.md" -o STANDARDS.md     # 142 lines
$ for f in $(sections from STANDARDS.md Sections list); do curl -fsSL "$RAW/standards/standards/$f"; done
$ ls sec | wc -l
25
$ diff -r sec <WowAddonStandards>/standards/standards && echo SECTIONS_IDENTICAL
SECTIONS_IDENTICAL
```

`STANDARDS.md:1` — `# Ka0s WoW Addon Standard (v2.21.0, 2026-08-04)`. **Version audited against.**

### A2. `luacheck .` — PASS

```
$ luacheck .
Checking LibKa0s/Core.lua                         OK
Checking LibKa0s/DebugLog.lua                     OK
Checking LibKa0s/Options.lua                      OK
Checking LibKa0s/OptionsScroll.lua                OK
Checking LibKa0s/OptionsWidgets.lua               OK
Checking LibKa0s/Perf.lua                         OK
Checking LibKa0s/PerfPanel.lua                    OK
Checking LibKa0s/Slash.lua                        OK
Checking testkit/framework.lua                    OK
Checking testkit/loader.lua                       OK
Checking testkit/mock_base.lua                    OK

Total: 0 warnings / 0 errors in 11 files
```

**0 warnings / 0 errors, 11 files** — matches `docs/automated-tests/20260805-002859/manifest.json`
(`"lint": { "status": "pass", "warnings": 0, "errors": 0, "files": 11 }`). Scope is `.luacheckrc:4`
`exclude_files = { "tests/", "docs/" }`, disclosed at `RESULTS.md:34-42`.

### A3. Headless runner — PASS

```
$ lua5.1 tests/run.lua
... (tail)
  PASS  versioning: every paired secondary file records which primary it attached to
  PASS  kitsync: Kit.VERSION is a positive integer and reaches the exposed table
  PASS  kitsync: the kit revision has an API document
  PASS  kitsync: testkit/ and tests/_kit/ hold the same set of files
  PASS  kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included

480 passed, 0 failed, 480 total
```

**480/480** — matches the manifest (`"tests": { "passed": 480, "failed": 0, "total": 480 }`).

### A4. Generated inventory freshness — PASS

```
$ lua5.1 tests/run.lua --list > /tmp/tc.md
$ diff /tmp/tc.md docs/test-cases.md >/dev/null && echo TESTCASES_IDENTICAL
TESTCASES_IDENTICAL
```

`docs/test-cases.md` regenerates **byte-identical**. `testing-§5` satisfied.

### A5. Complexity — RUN, verbatim invocation, **zero drift**

Invocation taken verbatim from `AUDIT.md:109` / `performance-§10`. No added flags, no narrowed path,
no re-tuned threshold.

```
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
...
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
==========================================================================================
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
------------------------------------------------------------------------------------------
      7975       6.1     1.8       47.5     1201            0      0.00    0.00
```

Compared against the latest bundle, `docs/automated-tests/20260805-002859/complexity.txt` (tail):

```
      7975       6.1     1.8       47.5     1201            0      0.00    0.00
```

**Identical on every field** — nloc 7975, avg NLOC 6.1, avg CCN 1.8, avg token 47.5, 1201 functions,
**0 warnings**. Manifest agrees: `"complexity": { "warnings": 0, "maxCcn": 12, "nloc": 7975,
"functions": 1201, "avgCcn": 1.8, "avgNloc": 6.1, "avgToken": 47.5, "bandFiles": 2,
"overCapFiles": 0 }`.

**Drift recorded: none.**
- Functions that crossed a `lizard` threshold since the bundle: **none** (0 warnings then, 0 now).
- Files that entered `layout-§1`'s 1000–1500 band since the bundle: **none**. Still exactly two —
  `tests/test_options_widgets.lua` 1114, `LibKa0s/Perf.lua` 1052 (`wc -l`), both listed at
  `RESULTS.md:86-87`. Nothing over the 1500 cap.
- Highest CCN in scope: **12**, `Sl:CliSet` (`LibKa0s/Slash.lua:527-550`), then `groupContext`
  (`LibKa0s/Perf.lua:496-510`) at 11 — exactly what `RESULTS.md:68-71` records.
- Staleness of the bundle's own stamp: `manifest.json` `"startedAt": "2026-08-05T00:28:59+05:30"`,
  audited the same day. **Not stale.** Its provenance *is* weak — `"git": { "sha":
  "64c1b8a721a3510ed77c378278b289c287969383", "branch": "master", "dirty": true }` — see A9/LK-14.
- `docs/complexity.md`: **absent** (`ls docs/complexity.md` → No such file). Correctly retired
  (`automated-tests-§7`). No anti-pattern #51 record here.

Watch-list reading (`AUDIT.md:122-130`): `RESULTS.md:64-74` records **zero** warned functions with
the note "That is a result, not an empty section", and `RESULTS.md:84-88` records two band files with
`Accepted` dispositions. `git log --oneline -- docs/automated-tests/RESULTS.md` returns **one**
commit (`58fb6f4`), so no entry can have carried a disposition across three consecutive release runs.
**Anti-pattern #53 does not apply.** `RESULTS.md:73-74` says so itself: "this is the first recorded
run … Read it as a baseline until a second row exists."

### A6. Vendored Ka0s-owned library drift

`AUDIT.md:96-107` calls for `diff -r <LibRepo>/<Lib> <Addon>/libs/<Lib>` per Ka0s-owned vendored
library.

- **`libs/` diff — N/A.** This repo *is* the source repo; it has no `libs/` folder at all
  (`find . -type f` lists none). There is no vendored copy that could have drifted.
- **`testkit` diff — RUN, empty.** The half that *does* apply here, because this repo consumes its
  own kit on the same terms as every addon (`README.md:156-159`, `tests/run.lua:4-8`):

```
$ diff -r testkit/ tests/_kit/ && echo KIT_EMPTY_DIFF
KIT_EMPTY_DIFF
```

Also gated in-suite: `tests/test_kitsync.lua` — "testkit/ and tests/_kit/ hold the same set of files"
and "every kit file is byte-identical … README included" both PASS in A3. **Anti-pattern #45: not
present.** No file is missing on either side, so **#48 is not present** either.

### A7. Runner artifact audit (`automated-tests-§2`)

```
$ ls -l testkit/run-automated-tests.sh tests/_kit/run-automated-tests.sh
-rwxrwxrwx 1 tushar tushar 24111 Aug  5 00:51 testkit/run-automated-tests.sh
-rwxrwxrwx 1 tushar tushar 24111 Aug  5 00:51 tests/_kit/run-automated-tests.sh

$ file tests/_kit/run-automated-tests.sh
tests/_kit/run-automated-tests.sh: Bourne-Again shell script, Unicode text, UTF-8 text executable, with very long lines (407)
```

Vendored ✔, executable ✔, LF (no "with CRLF line terminators" — contrast `README.md`, which `file`
reports as CRLF) ✔. `.gitattributes:22` — `*.sh   text eol=lf`, with the `bash\r` rationale written
above it at `.gitattributes:18-21` ✔. `docs/automated-tests/README.md` ✔ and
`docs/automated-tests/RESULTS.md` ✔ both exist.

### A8. `make test` / `tests/perf.lua`

```
$ ls tests/perf.lua
ls: cannot access 'tests/perf.lua': No such file or directory
```

Not run — the file does not exist. This is the standing documented state, not a tooling gap
(`RESULTS.md:46-49`, `manifest.json` `"perf": { "status": "skip", "skipReason": "no tests/perf.lua —
this addon ships no offline scenarios" }`). Evidence for **LK-13**. No `Makefile` in the repo.

### A9. Bundle provenance

```
$ git rev-list -n1 v1.7.0
6ce8548a8f02a2e521c0e483adf149eaf20c986c
$ git log --oneline -1 64c1b8a
64c1b8a docs: sync the stale version claims to v1.7.0
```

`manifest.json` records `"addonVersion": "1.7.0"`, `"release": null`, `"git": { "sha": "64c1b8a…",
"dirty": true }`. The bundle was taken from an **uncommitted** tree, at a commit that is **not** the
`v1.7.0` tag. Evidence for **LK-07** and **LK-14**.

---

## B. Per-deviation evidence

### LK-01 — no root `CLAUDE.md` (`documentation-§2`)

```
$ ls
CHANGELOG.md  LICENSE  LibKa0s  README.md  docs  testkit  tests
```

Root carries `README.md`, `CHANGELOG.md`, `LICENSE`, `.luacheckrc`, `.gitattributes`, `.gitignore` —
no `CLAUDE.md`, no `DEPENDENCIES.md`. `documentation` opening paragraph: "Root of the repo ships
exactly three docs plus `LICENSE` … a **full** `README.md`, a **stub** `CLAUDE.md`, and
`DEPENDENCIES.md`."

### LK-02 — the standards reference in zero durable places (`documentation-§6`, #34)

```
$ grep -rn "WowAddonStandards" --include='*.md' . | grep -vE '^\./docs/(adoption|reviews|superpowers)/'
docs/adoption-prompt.md:75:1. **The standard** — <https://github.com/tusharsaxena/WowAddonStandards> — fetched with
docs/automated-tests/README.md:4:[`automated-tests`](https://github.com/tusharsaxena/WowAddonStandards/blob/master/standards/standards/automated-tests.md)
```

Two incidental in-body links, neither in a required place. `README.md:1-230` contains **no** badge
row and no adherence line — `grep` returns nothing from it. `documentation-§6:151` — "The reference
**MUST** appear in **all three** of these places (a Ka0s addon missing any of them is
non-compliant — anti-pattern #34)". Place 1 is N/A (no `.toc` anywhere in the repo — `find` returns
none); places 2 and 3 are both absent.

### LK-03 — no `DEPENDENCIES.md` (`documentation-§7`)

Absent (see LK-01 listing). The dependencies the repo actually has, all evidenced:

- `lua5.1` — `testkit/loader.lua` `setfenv` usage; `testing-§3`.
- `luacheck` — `.luacheckrc:1-45`; `manifest.json` `"luacheck": "Luacheck: 1.2.0"`.
- `lizard` — `manifest.json` `"lizard": "1.23.0"`; `docs/automated-tests/README.md:33`.
- `git`, `bash`, POSIX `ls` — `tests/_kit/run-automated-tests.sh`; `tests/test_kitsync.lua`'s
  directory listing.

The section's own worked example is live in this repo's history: `CHANGELOG.md` (Unreleased) —
"The luacheck skip hint said `pipx install luacheck`. luacheck is a **Lua** package —
`sudo luarocks install luacheck` — and the wrong hint had already been copied into two of the
plugin's command specs."

### LK-04 — no `docs/testing.md` (`documentation-§3`)

```
$ ls docs
adoption  adoption-prompt.md  adoption-report.md  api  automated-tests
record-schema.md  releasing.md  reviews  superpowers  test-cases.md
```

No `testing.md`. The material is at `README.md:122-145` (`## Development` — green gate, `--list`
regeneration) and `README.md:147-159` (`### The shared test kit`).

### LK-05 — no `docs/ARCHITECTURE.md` (`documentation-§3`)

Not in the `ls docs` above. `README.md:196-230` (`## Repo layout`) is a file tree with one-line
annotations; there is no module map with the inter-module floors and failure modes, which is what
`documentation-§3` asks the file for.

### LK-06 — British spellings (`localization-§5`)

```
$ grep -rnoE '\b(colour|coloured|grey|behaviour|synthesise[ds]?|normalis(ed|ation)|licence|...)\b' \
    --include='*.md' --include='*.lua' --include='*.sh' .
README.md:50:colour       README.md:95:synthesised     README.md:114:synthesises
README.md:159:normalisation
LibKa0s/DebugLog.lua:180:coloured      LibKa0s/DebugLog.lua:216:synthesised
LibKa0s/DebugLog.lua:230:grey (x2)     LibKa0s/DebugLog.lua:242:colour
LibKa0s/DebugLog.lua:253:coloured      LibKa0s/DebugLog.lua:306:grey
LibKa0s/Core.lua:76:grey  :77:synthesised  :77:grey  :78:colour  :79:colours  :100:colour  :257:synthesised
LibKa0s/Slash.lua:78,80,86:colour  :227:normalised  :401,404:synthesised  :427:Colour  :438,540:colour
LibKa0s/OptionsWidgets.lua:32:colour  :56:normalised  :538,633:colour  :635,711:behaviour
LibKa0s/Perf.lua:306:synthesised
CHANGELOG.md: 36 hits   docs/api/: 69 hits   tests/: 79 hits   testkit/: 4 hits
docs/releasing.md: 7   docs/automated-tests/: 24   docs/test-cases.md: 24
docs/adoption-prompt.md: 14   docs/adoption-report.md: 3
```

Counted per area:

```
$ for d in README.md CHANGELOG.md LibKa0s testkit tests docs/api docs/releasing.md \
           docs/record-schema.md docs/automated-tests docs/test-cases.md \
           docs/adoption-prompt.md docs/adoption-report.md; do ... done
4   README.md
36  CHANGELOG.md
31  LibKa0s
4   testkit
79  tests
69  docs/api
7   docs/releasing.md
0   docs/record-schema.md
24  docs/automated-tests
24  docs/test-cases.md
14  docs/adoption-prompt.md
3   docs/adoption-report.md
```

**Mitigation, measured.** Filtering `LibKa0s/*.lua` hits to non-comment lines returns **nothing** —
every one of the 31 shipped-payload hits is inside a `--` comment. Sample:
`LibKa0s/Slash.lua:427` — `-- One row per colour channel: named key, positional index, default.`;
`LibKa0s/Slash.lua:78` — `-- Colour storage is the HOST's shape, not the library's`. No identifier,
no descriptor field and no host-visible string is affected, so the fix carries no API risk.

`localization-§5` scope: "**code**: comments, and identifiers"; "prose in `README.md` and every file
under `docs/`". Exemptions the section grants and this repo can claim: frozen research/history
("Quoted external text … a changelog line") and Blizzard symbols — neither covers authored comments,
the README, `docs/api/` current documents, or `docs/releasing.md`.

### LK-07 — no bundle in the release order (`automated-tests-§6`)

`docs/releasing.md:15-81`, steps 1–9:

```
1. Make the change, with its test. Green gate: `lua tests/run.lua` and `luacheck .` (0/0).
2. Bump the minor of every file you changed …
3. A new module is also a new row in `tests/run.lua`'s `MAJORS` …
4. Update `CHANGELOG.md` …
5. Write the API document for every major whose minor moved …
6. Regenerate the case list …
7. Move the provenance template … **Green gate again**, then commit and tag the repo semver.
8. Re-vendor every consumer …
9. Re-sweep the Consumers table against the source …
```

No step runs `tests/_kit/run-automated-tests.sh`. `automated-tests-§6:196-199` — "**MUST** produce a
full four-suite bundle as part of **every release**, in the same change that bumps the version …
**before** the tag." Manifest provenance in A9 confirms the one existing bundle is not that artifact.

### LK-08 — the release gate is unstated (`automated-tests-§3`)

`docs/automated-tests/README.md:29-40`:

```
| Suite        | Command   | Gates? |
| `lint`       | luacheck. | **yes** |
| `tests`      | ...       | **yes** |
| `perf`       | ...       | no — recorded only |
| `complexity` | ...       | no — recorded only |

`perf` and `complexity` are **measured, recorded and diffed — never used to fail a run.** …
They contribute `amber`, which is a signal rather than a stop.
```

`RESULTS.md:9-11`:

```
**`lint` and `tests` gate. `perf` and `complexity` are recorded and never fail a run** —
they are read and compared, not thresholded. A `skip` is a suite that did not run at all,
which is never the same as a pass.
```

Both are correct **about the run**, and neither names the other checkpoint.
`automated-tests-§3:99-119` requires the release gate — all four at `pass` and
`suites.complexity.warnings == 0` at the tag, a `skip` treated as NOT a pass, and the one narrow
`perf`-has-no-`tests/perf.lua` exception stated in the release notes.

```
$ grep -n "CCN\|all four\|release gate" docs/releasing.md
(no matches)
```

Note for the fix: `RESULTS.md:3` — `<!-- The newest run is prepended by
tests/_kit/run-automated-tests.sh. -->` — it is generated, so the fix belongs in the emitter.

### LK-09 — ungated load lists (`testing-§9`)

`tests/run.lua:17-19`:

```lua
Loader.loadAll({ "LibKa0s/Core.lua", "LibKa0s/DebugLog.lua", "LibKa0s/Slash.lua",
  "LibKa0s/Options.lua", "LibKa0s/OptionsWidgets.lua", "LibKa0s/OptionsScroll.lua",
  "LibKa0s/Perf.lua", "LibKa0s/PerfPanel.lua" }, nil, mocks)
```

against `LibKa0s/LibKa0s.xml:2-9`:

```xml
<Script file="Core.lua"/><Script file="DebugLog.lua"/><Script file="Slash.lua"/>
<Script file="Options.lua"/><Script file="OptionsWidgets.lua"/><Script file="OptionsScroll.lua"/>
<Script file="Perf.lua"/><Script file="PerfPanel.lua"/>
```

They agree **today**; nothing asserts that they will. `tests/run.lua:76-80` names twelve suites; the
`tests/` directory holds twelve `test_*.lua`, again with nothing asserting it. Contrast
`tests/run.lua:21-25`, whose comment states the gate that *does* exist for the MAJORS table: "a major
added to the XML but forgotten here surfaces as a versioning failure instead of as silence" — true
for `MAJORS`, not for the load list eight lines above it.

Measured (2026-08-05 review, `docs/reviews/2026-08-05/01_FINDINGS.md` F-001): adding
`LibKa0s/Extra.lua` (body `error(...)`) to the XML only, and adding a deliberately failing unlisted
suite, each left the run at **480/480 green**. `testing-§9:160-171` names both as its two silent
failure modes.

### LK-10 — an unfalsifiable case (`testing-§12`)

`tests/test_perf_core.lua:15-23`:

```lua
test("lib: New requires a name, an sv global and a suspend/resume pair", function()
  local ok = pcall(function() lib:New({ sv = "X", suspend = function() end, resume = function() end }) end)
  T.assertFalse(ok, "missing name must error")
  ...
```

Four `pcall`/`assertFalse` pairs; none asserts **what** was raised.
`testing-§12:261` — "**MUST NOT** treat *"it raised"* as sufficient. Assert on **what** it raised."
Measured (review F-003): no-op'ing `required(d, "name", "string")` at `LibKa0s/Perf.lua:290` leaves
the suite **480/480 green**, because `LibKa0s/Perf.lua:328` indexes `d.name` and raises anyway.
`Kit.assertError` exists at `testkit/framework.lua:64-71`, and the adjacent case
(`tests/test_perf_core.lua:27` — "New rejects a bucket entry with no key, in the library's own
words") already uses it correctly, with an explanatory comment.

### LK-11 — README layout drift (`documentation-§5`)

`README.md:213-225`:

```
tests/               -- this repo's own test harness, consuming testkit/ through tests/_kit/
docs/                -- development docs (not shipped)
  api/               -- THE API REFERENCE …
  releasing.md       -- the two version numbers, the release order, the re-vendor rule
  record-schema.md   -- the capture record, field by field
  adoption-prompt.md -- the per-addon adoption prompt
  adoption-report.md -- the reusable adoption-fidelity report, run per date into adoption/
  adoption/          -- frozen dated adoption reports, one folder per run
  test-cases.md      -- generated case inventory
  reviews/           -- frozen dated review bundles
  superpowers/       -- the extraction plans and design specs, kept as the record of why
```

`docs/automated-tests/` — the trend line and every run bundle — is not listed. `docs/audits/` is not
listed (it is created by this run).

### LK-12 — missing topic-detail docs (`documentation-§3`)

```
$ ls docs/perf-runs
ls: cannot access 'docs/perf-runs': No such file or directory
```

No `docs/smoke-tests.md`, no `docs/performance.md`, no `docs/perf-runs/README.md` in the `ls docs`
listing under LK-04. The `perf-runs` absence **is** written down —
`docs/automated-tests/README.md:47-51`:

```
There is no `perf-runs/` beside this directory. In-game captures are taken in a live client against
a **host addon**, and a library cannot be loaded on its own — so the in-game perf evidence for this
code lives in the consumers' repos, recorded against the addon that loaded it.
```

Per `AUDIT.md:87-89`, an omission with the reason written down is a decision, not a gap — so that one
is recorded as accepted. The other two carry no such note.

### LK-13 — no zero-overhead scenario (`performance-§9`)

`tests/perf.lua` absent (A8). `RESULTS.md:44-56` states the consequence in the standard's own terms:

```
**This repo ships no `tests/perf.lua`, so `perf` is a permanent `skip` — not a pass, and not a
transient tooling gap.** The record is therefore **silent about runtime cost**. …
LibKa0s **is** the perf instrumentation for the collection … and `performance-§9`'s zero-overhead
evidence, that bracketed instrumentation costs nothing when capture is off, does not exist for the
library that supplies the brackets.
```

The unverified claim it leaves standing, `LibKa0s/Perf.lua:377-378`:

```lua
--- Open a bracket. Returns nil when the probe is off, so a call site pays one boolean test and
--- nothing else, and allocates nothing on either path.
```

Review F-004 measured the call-site cost as **two function calls plus the test**; the allocation half
of the claim is correct. Nothing in the repo holds the number.

### LK-14 — bundle from a dirty tree (`automated-tests-§1`)

See A9. `manifest.json` `"dirty": true`, sha `64c1b8a` ≠ tag `6ce8548`.

### LK-15 — an untrue enforcement claim (`documentation-§5` / `testing-§10`)

`docs/releasing.md:143-146`:

```
byte-identity — but it names which copy a consumer holds, and it names that copy's API document
under [`api/testkit/`](api/testkit/). **Bump it on every released change to any file in `testkit/`,
and write the document for the new number**; `tests/test_kitsync.lua` fails if the document for the
live revision is missing, the same bargain `test_versioning.lua` strikes for the library's minors.
```

The kit half is true — `tests/run.lua` A3 output shows `PASS  kitsync: the kit revision has an API
document`. The library half is not: `tests/test_versioning.lua:107-128` reads `CHANGELOG.md` and
searches for `"<FileBasename> minor <N>"`; there is no assertion anywhere in the suite that
`docs/api/<Major>/version-<minors>-docs.md` exists. `docs/releasing.md:56` — "A minor bump is not
released until its document exists" — is therefore an unenforced convention for the five majors, and
an enforced gate for the one-consumer kit.

---

## C. Compliance evidence (claims made in `01_CURRENT_STATE.md`)

| Claim | Citation |
|---|---|
| Five majors, eight files, one aggregate XML | `LibKa0s/LibKa0s.xml:1-10`; `README.md:47-53` |
| One LibStub major per module, per-file minors | `docs/releasing.md:5-13`, `:23-30` |
| Dependency floors return before `NewLibrary` | `README.md:27-32`, `:55-57`; `tests/test_perf_isolation.lua` (7 PASS cases in A3) |
| `lib.MODULES` published per major | `README.md:61-68`, `:168-178` |
| `testkit/` is a sibling of the ship folder | `README.md:210-212`; `find` shows `./testkit/` at repo root |
| Repo consumes its own kit as a consumer | `tests/run.lua:4-12`; `README.md:156-159` |
| Versioning suite meets `testing-§10` | `tests/test_versioning.lua` — 7 PASS cases in A3; misses collected before failing at `:112-127` |
| Kit-sync suite meets `testing-§11` | `tests/test_kitsync.lua` — 4 PASS cases in A3, README included |
| `.luacheckrc` justifies its `globals` and `ignore` | `.luacheckrc:27-28`, `:29-40` |
| `layout-§1` 1500 cap met | `wc -l`: max 1114 (`tests/test_options_widgets.lua`), 1052 (`LibKa0s/Perf.lua`) |
| `RESULTS.md` watch list is two tables, band as a column | `RESULTS.md:64-88` |
| `RESULTS.md` carries standing prose for all four suites | `RESULTS.md:17-32` (tests), `:34-42` (lint), `:44-56` (perf), `:58-88` (complexity) |
| MIT license ships inside the payload | `LibKa0s/LICENSE`; `README.md:209` |
| No `TODO.md`, no `docs/agent-context.md` | `find . -type f` — neither present |
| Frozen review history retained | `docs/reviews/2026-07-31/`, `docs/reviews/2026-08-05/` — five artifacts each |
</content>
