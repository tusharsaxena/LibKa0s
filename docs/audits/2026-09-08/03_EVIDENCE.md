# 03 — Evidence

Every `file:line` below was re-read at the moment this document was written and the cited text is
quoted beside it. Every count was produced by the command shown, run from the repo root, with its
scope stated. No figure is carried over from the 2026-09-07 bundle; where a number is compared
against that run it is re-measured here first.

**Environment.** Repo root `/mnt/d/.../GIT/LibKa0s`, branch `master`, HEAD `9668a29`, tree clean.
Standard resolved from `WowAddonStandards@master`, `standards/STANDARDS.md:1` reading
`# Ka0s WoW Addon Standard (v2.39.0, 2026-09-07)`.

---

## E1 — Lint

```
$ luacheck .
...
Total: 0 warnings / 0 errors in 51 files
```

**Scope:** the whole repo minus `.luacheckrc:4`'s `exclude_files = { "tests/_kit/" }`. That covers
`LibKa0s/` (14), `testkit/` (5), `tests/` outside `_kit/` (31, fixtures and `wow_mock.lua`
included) and `tools/` (1) — 51 files, counted by
`git ls-files '*.lua' | grep -v '^tests/_kit/' | sed -E 's|/.*||' | sort | uniq -c`. It excludes only
the 5 files under `tests/_kit/`.

```
$ git ls-files '*.lua' | wc -l
56
$ git ls-files '*.lua' | grep -c '^tests/_kit/'
5
```

Config, verbatim:

- `.luacheckrc:4` — `exclude_files = { "tests/_kit/" }`
- `.luacheckrc:57-59` — `files["tests/"] = {` / `  globals = { "LK_TEST" },` / `}`

Both are exactly `lint`'s v2.39.0 template shape: the exclusion narrowed to the vendored kit, and
the harness global in the `files["tests/"]` stanza rather than in top-level `read_globals`. No
blanket `ignore` was added to buy the green: `.luacheckrc:46` is
`ignore = { "212/self", "212/event", "432/self" }`, three codes, each with a comment above it at
`:37-45`. **Backs `01_CURRENT_STATE.md` and `LK-29`.**

## E2 — Headless suite

```
$ lua tests/run.lua
...
795 passed, 0 failed, 0 skipped, 795 total
```

**Scope:** the 22-suite list pinned by `Kit.assertSuiteInventory`, loading the payload through
`tests/run.lua:24` — `Loader.loadAll(Loader.xmlFiles("LibKa0s/LibKa0s.xml"), nil, mocks)` — which is
the derived load list `testing-§9` asks for. Green lines relied on elsewhere in this bundle:

- `PASS  kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included`
- `PASS  kitsync: the runner is mode 100755 in the git index, in BOTH copies`
- `PASS  eol: every tracked file carries the terminator .gitattributes declares for it`
- `PASS  prose: no British spelling in the shipped library or the shipped kit`
- `PASS  layoutcap: every authored file over 1500 lines is named in the CLAUDE.md census`
- `PASS  layoutcap: no census row outlives the breach it records`
- `PASS  every deviation id the register cites is assigned by a bundle in docs/audits/`
- `PASS  versioning: every major's live version has its API document on disk`
- `PASS  versioning: every major's published member manifest matches its live surface`

## E3 — Vendored Ka0s-owned library drift

**Not applicable, and stated rather than skipped.** `library-stack-§7`'s `diff -r` check runs in a
*consumer*; this repo is the source. There is no `libs/` here at all:

```
$ ls -d libs 2>&1
ls: cannot access 'libs': No such file or directory
```

The equivalent gate this repo owes is the kit-sync one — `testkit/` against its own vendored copy at
`tests/_kit/` — and it is green (E2). It asserts the same file set, byte identity across every file
including `README.md`, and mode `100755` on the runner in both copies.

## E4 — Line-ending policy (`line-endings`, all five properties)

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

(b) is the **client-bound** pin, which is what `library-stack-§7` names explicitly for this repo:
it ships Lua into every consumer's `libs/`, and a library repo has no `.toc` for
`line-endings-§2`'s discriminator to read.

**(e) — the working tree against the declared pin. One number, one command:**

```
$ git ls-files -z | xargs -0 -I{} sh -c '
    set -- $(git check-attr text eol -- "{}" | sed "s/.*: //")
    [ "$1" = unset ] && exit
    cr=$(tr -dc "\r" < "{}" | wc -c); lf=$(tr -dc "\n" < "{}" | wc -c)
    case "$2" in crlf) [ "$lf" -gt 0 ] && [ "$cr" -ne "$lf" ] && echo "{}";;
                 lf)   [ "$cr" -gt 0 ] && echo "{}";; esac' 2>/dev/null | wc -l
0
```

**Scope:** every path `git ls-files` returns — payload, kit, tests, tools, all of `docs/` including
the frozen bundles, and the binaries, which the `text=unset` guard drops because git converts
nothing there. Nothing is excluded. **The 2026-09-07 bundle reported 7 for this repo; that bundle is
frozen and is not edited.** The difference is real repair, not a different command: `M1-LK-10`
re-checked out the seven stragglers and widened the gate.

**§5, the canonical body.** The canonical client-bound body was extracted from
`line-endings.md`'s first fenced `gitattributes` block (81 lines):

```
$ n=81; diff <(head -n "$n" .gitattributes | tr -d '\r') /tmp/canon_client.gitattributes
(no output)
$ tail -n +82 .gitattributes | tr -d '\r' | grep -m1 .
(no output; exit 1)
```

Body byte-clean, tail empty — no `§5 appendix` claimed and none owed. The only extension-less tracked
files are `LICENSE` and `LibKa0s/LICENSE`, both text, so §4's extension-keyed list reaches everything
binary this repo holds:

```
$ git ls-files | grep -vE '\.[A-Za-z0-9]+$'
LICENSE
LibKa0s/LICENSE
```

**§7's owner.** `testkit/framework.lua:20` — `Kit.VERSION = 15`, which is the revision §7 names, and
`tests/_kit/test_eol.lua` is present and run (E2). Its own header states the widened scope at
`testkit/test_eol.lua:14-15`: *"IT READS THE WHOLE TRACKED SET, and did not until revision 15."*
So (e) has an owner here and the audit is confirming a gate rather than substituting for one.

## E5 — Complexity, measured verbatim

```
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
...
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 or nloc > 1000000 or parameter_count > 100)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
     14564       6.7     2.0       51.5     1993            0      0.00    0.00
```

`lizard` version 1.24.0. The invocation is `performance-§10`'s exact string, unmodified.

**Drift against the latest bundle:** none. `docs/automated-tests/20260908-181447/complexity.txt`
ends with the identical footer, and `manifest.json` records `"nloc": 14564, "functions": 1993,
"avgCcn": 2.0, "maxCcn": 14, "warnings": 0, "bandFiles": 5, "overCapFiles": 2`. No function crossed
a threshold and no file entered or left the 1000–1500 band since that run. The bundle's stamp is
`20260908-181447` — **today** — so nothing here is stale (anti-pattern #51 has no instance).

**LOC census, the same denominator `CLAUDE.md:99` publishes:**

```
$ git ls-files '*.lua' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn | head -8
  24288 total
   2398 tests/test_options_widgets.lua
   1989 LibKa0s/OptionsWidgets.lua
   1493 tests/test_widgets.lua
   1266 tests/test_options.lua
   1232 LibKa0s/Widgets.lua
   1206 LibKa0s/Perf.lua
   1036 LibKa0s/Options.lua
```

**Scope:** every tracked `.lua` except `tests/_kit/`, which `layout-§1` carves out as vendored. Two
over the cap, five in the band — matching the manifest exactly. The census table at
`CLAUDE.md:102-105` carries both over-cap files with an issue each, and
`tests/test_layout_cap.lua` gates membership in both directions (E2). **Backs the "not recorded"
entry for `layout-§1`.**

## E6 — The complexity watch list read as a decision record

`docs/automated-tests/RESULTS.md:105-113` — seven rows, every one with a non-empty `Disposition`.
Counted by hand from that table: three read **Accepted** (`LibKa0s/Options.lua`,
`LibKa0s/Widgets.lua`, `tests/test_widgets.lua`), two point at an issue with an owner
(`LibKa0s/Perf.lua` → #7; both over-cap rows → #16 and #8, ruled on 2026-09-08 at `M4-14`), and one
reads *"owed a tracked ID"*.

That last one, verbatim, `RESULTS.md:110`:

> `| 1000–1500 (on notice) | \`tests/test_options.lua\` | 1266 | **NEWLY CROSSED at \`20260807-151331\` (v1.8.3), by one line — owed a tracked ID.** …`

**How many release runs it has carried that.** Counted from the manifests rather than from memory:

```
$ python3 -c "
import json,glob,os
rows=[(os.path.basename(os.path.dirname(f)), json.load(open(f)).get('release')) for f in sorted(glob.glob('docs/automated-tests/2026*/manifest.json'))]
after=[r for s,r in rows if s>'20260807-151331' and r]
print(len(after)); print(after)"
25
['1.9.0', '1.9.1', '1.9.2', '1.10.0', '1.10.1', '1.10.2', '1.11.0', '1.11.1', '1.11.2', '1.12.0',
 '1.13.0', '1.14.0', '1.15.0', '1.16.0', '1.17.0', '1.18.0', '1.18.1', '1.19.0', '1.20.0', '1.21.0',
 '1.22.0', '1.23.0', '1.25.0', '1.26.0', '1.27.0']
```

**Scope:** all 34 bundle manifests under `docs/automated-tests/`; a run counts as a release run only
where `manifest.release` is non-null. **25 against anti-pattern #53's cap of 3. Backs `LK-17d`.**

Corroborating, the disposition text itself has survived 29 commits of that file:

```
$ for c in $(git log --format=%h -- docs/automated-tests/RESULTS.md); do
    git show $c:docs/automated-tests/RESULTS.md 2>/dev/null | grep -q 'owed a tracked ID' && echo hit; done | wc -l
29
```

**Reading the numbers.** Max CCN is 14 and no function warns, so nothing in this repo needs the
dense-defaulting-versus-tangle distinction today. The three highest —
`(anonymous)@125-166` in `testkit/test_eol.lua` (14), `list@1178-1219` (13) and
`paintMenuRow@126-159` (13) in `LibKa0s/Widgets.lua` — are all below the threshold.

**Complexity refactors since the last audit.** `M1-LK-03` (`40a071b`) reworked the tab strip to
acquire from `LibKa0s-Pool-1.0`. Checked against `performance-§11` and the four forbidden shapes:
the helpers are named for what they do (`newTabButton`, `dressTab`), the pools are per-`ctx` and
created once rather than per call (no #43), the behavior is pinned by
`tests/test_options_widgets.lua`'s existing strip cases plus the new pool cases, and no
`t.k = stored.k or D.k` defaulting was introduced over a settings table (#54 has no instance — this
repo has no SavedVariables).

## E7 — `ANALYSIS.md` at release

```
$ python3 -c "
import json,glob,os
tot=noan=rel=relnoan=0
for f in sorted(glob.glob('docs/automated-tests/2026*/manifest.json')):
    d=os.path.dirname(f); tot+=1
    has=os.path.exists(d+'/ANALYSIS.md'); r=json.load(open(f)).get('release')
    noan+= not has
    if r: rel+=1; relnoan+= not has
print('bundles',tot,'without ANALYSIS',noan); print('release runs',rel,'without ANALYSIS',relnoan)"
bundles 34 without ANALYSIS 19
release runs 30 without ANALYSIS 19
```

**Scope:** every dated directory under `docs/automated-tests/`; all 34 carry a `manifest.json`, so
nothing is missed by keying on it.

The two releases cut **this cycle**, both without a write-up:

```
$ ls docs/automated-tests/20260907-201015/ docs/automated-tests/20260907-235828/ | grep -c ANALYSIS
0
$ grep -o '"release": [^,]*' docs/automated-tests/20260907-201015/manifest.json
"release": "1.26.0"
$ grep -o '"release": [^,]*' docs/automated-tests/20260907-235828/manifest.json
"release": "1.27.0"
```

The release procedure never names the artifact:

```
$ grep -ci analysis docs/releasing.md
0
```

**Scope:** the whole file, case-insensitive, so no heading, step or checklist line is missed.
`docs/releasing.md:134-153` is the hard-precondition block — five `jq` reads off the manifest plus
*"No tag is cut without a bundle whose `release` field names it"* at `:150-151` — and `ANALYSIS.md`
is in none of them. **Backs `LK-19`.**

The forward-closure half of §5 **is** discharged, at
`docs/automated-tests/20260908-181447/ANALYSIS.md:90-110`, headed
*"The `ANALYSIS.md` gap, noted once, and this repository is where most of it is"*. Two of its three
figures reproduce exactly — `:101-102`, *"thirty of the thirty-four are release runs, and nineteen of
those thirty carry no `ANALYSIS.md`"*. One does not: `:92` reads *"Twenty of this repository's
thirty-four bundles carry no `ANALYSIS.md`"* while `:93` reads *"None of the nineteen older ones is
getting one"*, and the measured figure is **19**. **Backs `LK-32`.**

## E8 — `localization-§5`, swept with the published lists

The sweep copies `localization-§5`'s `BRITISH` and `ALLOWED` arrays **whole** out of the fetched
`standards/standards/localization.md` — 84 `BRITISH` substrings, 32 `ALLOWED` whole words — removes
`ALLOWED` as whole words first (delimiting on `[a-z]+` over the lowercased line), then runs the
substrings over what remains. Script: `/tmp/british3.py`.

**Scope, stated in full.** Swept: every tracked `.lua`, `.md` and `.sh`. Excluded, and each named
rather than pattern-inferred — `tests/_kit/` (vendored, `localization-§5` exclusion 1);
`docs/audits/`, `docs/reviews/`, `docs/adoption/`, `docs/superpowers/` and
`docs/automated-tests/<stamp>/` (frozen dated bundles, exclusion 2); `CHANGELOG.md` (released
entries, exclusion 2); `tests/test_prose.lua` (the gate's own copy of the lists, exclusion 4);
`docs/test-cases.md` (generated); `LibKa0s/media/`, `media/`, `tools/artwork/` (binary). The
ratified register exemption — `minimise` in `LibKa0s/Media.lua` and in the register row itself — is
subtracted.

| Bucket | Hits | Files |
|---|---|---|
| `LibKa0s/` — the shipped payload | **0** | 0 |
| `testkit/` — the shipped kit | **0** | 0 |
| `tools/` | **0** | 0 |
| `tests/*.lua` | 135 | 19 |
| `docs/api/` — **live** document per major | 41 | 9 |
| `docs/` — live pages | 35 | 3 |
| `README.md`, `DEPENDENCIES.md` | 5 | 2 |
| **Live total** | **216** | **33** |
| `docs/api/` — **superseded** version documents | 256 | 48 |

Worst live files: `tests/test_slash.lua` 24, `tests/test_debuglog.lua` 22,
`docs/adoption-prompt.md` 21, `tests/test_options_widgets.lua` 19,
`docs/api/Slash/version-7-docs.md` 14. Samples, re-read and quoted:

- `docs/api/Slash/version-7-docs.md:31` — *"validation, colour tuples — on the view that a CLI silently
  accepting a value it cannot honour is"*
- `tests/test_debuglog.lua:53` — `test("dbg: FormatColored colours the timestamp and tag; pipe and content default", function()`
- `README.md:183` — *"remembered `diff -r` — every file, README included, no line-ending normalisation."*
- `DEPENDENCIES.md:98` — *"| NumPy | The recolour, solidify and normalize stages are array work…"*
- `docs/releasing.md` carries 10, `docs/adoption-report.md` 4.

**The payload's zero is the closure of 2026-09-07's `LK-06`**, and it is not the gate's word for it —
the same lists over the same two directories return nothing. **Backs `LK-28`.**

**Why the suite cannot see the 216.** `tests/test_prose.lua:19` — `local SHIPPED = { "LibKa0s", "testkit" }`,
with `:16-18` explaining the choice: *"The directories whose BYTES SHIP. `tests/` is deliberately not
here: its prose never leaves this repo…"*. `shippedFiles()` at `:59-63` iterates `SHIPPED` and does
not recurse. `localization-§5`'s scope is source, `README.md` and everything under `docs/`, and its
four permitted exclusions do not include `tests/`, `docs/` or the README. **Backs `LK-28d`.**

The list-adoption half of `M1-LK-11` **is** correct: `tests/test_prose.lua:125-160` carries `BRITISH`
and `ALLOWED` verbatim, both complete, with `:104-110` recording that the previous six-substring
private list *"stayed green for months while `CANCELLED` shipped in the chat text Perf.lua writes"*.
That is 2026-09-07's `LK-06d` closed.

## E9 — The lint-scope documents (`LK-29`)

Three descriptions of one config, re-read today:

- **Truth**, `.luacheckrc:4` — `exclude_files = { "tests/_kit/" }`, and `luacheck .` reports
  `0 warnings / 0 errors in 51 files` (E1).
- **Generated, correct**, `docs/automated-tests/RESULTS.md:74-78` — *"**0 warnings / 0 errors over 51
  files** (`luacheck .`). … `.luacheckrc` sets `exclude_files = { "tests/_kit/" }`, so those paths are
  not in it."*
- **Authored, stale**, `CLAUDE.md:177-178` — *"That `luacheck` figure is **scoped by `.luacheckrc`'s
  `exclude_files`**, not repo-wide — eighteen files today, the fourteen in `LibKa0s/` plus four under
  `testkit/`."*
- **Authored, stale and now false**, `DEPENDENCIES.md:120` —
  `luacheck .                                          # 0 warnings / 0 errors, in 18 files`
  and `:125-127` — *"the fourteen files in `LibKa0s/` plus the four in `testkit/`; `tests/` and
  `docs/` are excluded, so 0/0 only means something if what you changed is inside that set."*

`tests/` is **not** excluded; `.luacheckrc:57-59`'s `files["tests/"]` stanza exists precisely
because it is linted. The commit that changed this is `4b8e2ed` (`M1-LK-12: lint the test tree, so a
clean run means more than half the Lua`).

## E10 — `automated-tests-§4`, the watch list's shape (`LK-30`)

`docs/automated-tests/RESULTS.md:99-101`, verbatim:

```
### Functions `lizard` warned on

None.
```

§4 MUSTs *"two tables with header rows: warned functions (Function / CCN / Location / Disposition),
and files by `layout-§1` band"*. The band table has its header (`RESULTS.md:105-106`); the functions
table does not exist. The file is runner output — `RESULTS.md:3-5` says so — so the emitter is the
site:

- `testkit/run-automated-tests.sh:556` — `fn_table() {`
- `testkit/run-automated-tests.sh:557` — `if [ -z "$CCN_WARN_ROWS" ]; then printf 'None.\n'; return; fi`
- `testkit/run-automated-tests.sh:558` — `printf '| Function | CCN | Location | Disposition |\n|---|---|---|---|\n'`
- `testkit/run-automated-tests.sh:574` — the identical early return in `band_table()`

The header line is emitted only after the emptiness check returns. The band table happens to be
non-empty in this repo, so only the functions half is visible here — but the same shape will produce
prose in any consumer whose band is clear. **Cross-cutting; `testkit/` is vendored into ten repos.**

## E11 — `compat` (`LK-31`)

Two deprecated-API sites in the payload, both re-read:

- `LibKa0s/Env.lua:60-67` — `function lib.GetAddOnMetadata(addonName, field)` / `if C_AddOns and
  C_AddOns.GetAddOnMetadata then` … `if GetAddOnMetadata then` … `return nil`. This is the shim shape,
  exposed as a member, in the module `library-stack-§7` describes as *"the handful of client facts
  every addon reads, read one way"*.
- `LibKa0s/Perf.lua:656-658` — `local specIndex = C_SpecializationInfo and
  C_SpecializationInfo.GetSpecialization` / `    or GetSpecialization` / `if specIndex and
  GetSpecializationInfo then`. Inline, at the call site, exposed as nothing.

The second site's own comment, `LibKa0s/Perf.lua:649-650`: *"Namespaced rung first, deprecated global
second, nil where neither is there — the shape `Env.lua`'s C_AddOns shim models, applied here because
the spec reader moved the same way."* Whole-payload sweep for further sites:

```
$ grep -nE 'GetSpecialization|GetAddOnMetadata|GetSpellInfo|GetItemInfo|GetContainerNumSlots' LibKa0s/*.lua | grep -v '^\S*:[0-9]*: *--'
LibKa0s/Env.lua:60:function lib.GetAddOnMetadata(addonName, field)
LibKa0s/Env.lua:61:  if C_AddOns and C_AddOns.GetAddOnMetadata then
LibKa0s/Env.lua:62:    return C_AddOns.GetAddOnMetadata(addonName, field)
LibKa0s/Env.lua:64:  if GetAddOnMetadata then
LibKa0s/Env.lua:65:    return GetAddOnMetadata(addonName, field)
LibKa0s/Env.lua:80:  local v = lib.GetAddOnMetadata(addonName, "Version")
LibKa0s/Perf.lua:656:      local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
LibKa0s/Perf.lua:657:          or GetSpecialization
LibKa0s/Perf.lua:658:      if specIndex and GetSpecializationInfo then
LibKa0s/Perf.lua:661:              local _, name = GetSpecializationInfo(index)
```

**Scope:** `LibKa0s/*.lua` only — the shipped payload — with comment-only lines dropped. Two owners,
where `compat` MUSTs one.

## E12 — The deviation register, all three `audit-review-history` MUSTs

**MUST 1 — read it before filing.** `CLAUDE.md:64-68`. One row, `Rule` = `localization-§5`, `What
differs` = *"`lib.ICONS` keeps `minimise`, the one British spelling left in the shipped payload"*,
`Decided` = *"2026-09-07, executing `M1-LK-11`"*. That gap is therefore **accepted**, not re-filed —
which is why `LK-28`'s sweep subtracts it and why the payload figure is 0 rather than 1.

**MUST 2 — has the cited rule changed?** Yes: `localization-§5` was amended at v2.39.0 to publish the
`BRITISH`/`ALLOWED` lists and the gate-reading rules. Reported here as the MUST requires. The
amendment does not add a path-fragment exception to §5's four exceptions, so the row's substance
stands, and the row was authored on 2026-09-07 against the amended text (`CLAUDE.md:3` reads
v2.39.0). No action.

**MUST 3 — evaluate the trigger against the tree, and resolve every evidence id.**

- Trigger: *"A `minimize.tga` shipped beside the current file, or an alias map in `lib.Icon`."*

```
$ ls LibKa0s/media/icons/ | grep -i minim
minimise.tga
$ grep -c alias LibKa0s/Media.lua
0
```

  Neither condition holds. **The trigger has not fired; the row is not asserting a dead deviation.**
- The claim it rests on, re-read: `LibKa0s/Media.lua:202-207` — `function lib.Icon(addonName, name,
  vendorPath)` … `return base .. ICON_DIR .. "\\" .. name`. The key **is** the last path segment, as
  the row says. The silent-failure argument it cites at `Media.lua:190-196` is there:
  *"A texture that does not load draws nothing and raises nothing."*
- Evidence id: `LK-06` in `docs/audits/2026-09-07/`. Resolves —
  `docs/audits/2026-09-07/02_DEVIATIONS.md` carries `**LK-06**` in its root table. This is also
  gated: `tests/test_register.lua` runs *"every deviation id the register cites is assigned by a
  bundle in `docs/audits/`"*, green in E2.
- The key itself, re-read: `LibKa0s/Media.lua:94` —
  `  "close", "minimise", "expand", "lock", "unlock", "settings", "segment", "reset", "export",`

## E13 — The issue store, and the inverse register rule

```
$ gh issue list --state all --limit 200 --json number,title,state,labels,url
26 issues
```

Every issue carries exactly one `state:` label and one `severity:` label. No title carries a
`[status]` prefix (anti-pattern #62 — checked over all 26 titles). No `docs/pending/`:

```
$ ls docs/pending 2>&1
ls: cannot access 'docs/pending': No such file or directory
```

**Closed `state:will-not-do`, each checked against the inverse rule** (*a ratified decline with no
register row is itself the finding*):

| Issue | What it declines | Register row owed? |
|---|---|---|
| #10 | An API/design proposal — the flat dropdown skin's owner | No — an enhancement, not a standards rule |
| #21 | A proposal to make `lib.MakeCloseButton` infer its vendor path | No — the resulting row belongs to BankLedger (`M5-02`), not here; read in full, the decline is about an API signature |
| #22 | **Renaming the `minimise` icon key** — a `localization-§5` rule | **Yes, and it exists** — `CLAUDE.md:68` |
| #23 | Scheduling: flipping the shared mock's `GetHeight` default in this plan | No |
| #24 | A proposal to publish a no-op Options surface from the library | No |
| #25 | Hand-editing a `RESULTS.md` figure — a decline **to violate** a rule | No |
| #26 | Scheduling: cutting a tag beyond v1.26.0/v1.27.0 | No |

No missing register row. The one decline that *is* a standards decline has its row, and the row's
trigger and evidence both resolve (E12).

**Open issues relied on by the "not recorded" entries:** #7 (`LibKa0s/Perf.lua` band, `state:triaged`),
#8 (`tests/test_options_widgets.lua` over cap, `state:triaged`), #16 (`LibKa0s/OptionsWidgets.lua`
over cap, `state:triaged`). All three are open with an owner, which is what makes `layout-§1`'s
second terminal state hold. Note for the record: #7's title says *"(1163 LOC)"* while the file is
**1206** today — the issue is a band record, not a breach record, and `RESULTS.md:108` carries the
current figure, so this is an observation rather than a finding.

## E14 — `library-stack-§7` and `§9`

**Payload shape.**

```
$ grep -c '<Script' LibKa0s/LibKa0s.xml
14
$ grep -o 'file="[^"]*"' LibKa0s/LibKa0s.xml
file="Core.lua" file="Env.lua" file="Pool.lua" file="Item.lua" file="Media.lua"
file="Widgets.lua" file="DebugLog.lua" file="Slash.lua" file="Options.lua"
file="OptionsWidgets.lua" file="OptionsCompose.lua" file="OptionsScroll.lua"
file="Perf.lua" file="PerfPanel.lua"
```

Ten majors across fourteen files, exactly as `library-stack-§7`'s corrected table states — the
correction (`OptionsCompose.lua`) landed at v2.39.0 as `M1-STD-15`, closing 2026-09-07's
`LIBKA0S-A-14`.

**§9, new at v2.39.0.** `LibKa0s/Options.lua:269` — `function lib.__PatchLSM30Border()`;
`:270` — `if lib.__lsmBorderPatched then return false end`. The sentinel lives on the library table,
so N vendored copies loaded in one session produce one registration. `:277-279` wraps *whatever the
registry holds*, not a name it reimplements. Compliant; this is `M1-LK-05`.

## E15 — `library-stack-§7` Substitutes

- `CLAUDE.md:37` — `## Standards compliance (read first)` (anti-pattern #34 has no instance).
- `CLAUDE.md:3` — *"LibKa0s adheres to the **Ka0s WoW Addon Standard** (v2.39.0)"*.
- `README.md:3` — *"Built to the **[Ka0s WoW Addon Standard](…)**, v2.39.0"*. Matches
  `STANDARDS.md:1`. **2026-09-07's `LK-26` closed.**
- `DEPENDENCIES.md` present at the root (its lint sentence is `LK-29`).
- `CHANGELOG.md` present, and `tests/test_versioning.lua` asserts *"the changelog accounts for the
  version every file is at"* (green, E2).
- `CLAUDE.md:137-166` — `## Documentation map`. Checked in both directions:

```
$ git ls-files 'docs/*.md' | grep -vE '^docs/(audits|reviews|adoption/|superpowers)/' \
    | grep -vE '^docs/automated-tests/[0-9]{8}-' | grep -vE '^docs/api/[A-Za-z]+/version-'
docs/adoption-prompt.md
docs/adoption-report.md
docs/api/README.md
docs/automated-tests/README.md
docs/automated-tests/RESULTS.md
docs/fast-gate-adoption-prompt.md
docs/record-schema.md
docs/releasing.md
docs/test-cases.md
```

  Every one has a row; `docs/api/README.md` and the per-version documents are covered by the
  `docs/api/` row. Every row resolves to a file that exists. The five frozen/generated directories
  are named once each at `CLAUDE.md:146-147`. No orphan page, no dangling row.

## E16 — `LK-16` / `LK-16d`, closed

- `LibKa0s/OptionsCompose.lua:240` — `      values = O.LSMValues("font"),`
- `LibKa0s/OptionsCompose.lua:284` — `      values = O.LSMValues("border"),`
- `LibKa0s/OptionsCompose.lua:313` — `      values = O.LSMValues("statusbar"),`

No outer `function() … end`. The regression gate that was missing:
`tests/test_options_compose.lua:122` — *"red under: wrapping O.LSMValues in an outer `function() …
end`, which hands enumList a…"*, and `:174-190` — *"compose: a host whose own LSMValues returns a
TABLE lands a frozen list, which is the breach"*. Issue #15 is `CLOSED` / `state:done` /
`severity:critical` (E13).

## E17 — anti-pattern #70, the wrapped strip's pitch

- `LibKa0s/OptionsWidgets.lua:403` — *"IT WAS BROKEN EXACTLY THERE. TabStrip recorded the pitch from
  the FIRST tab it drew, whichever"*
- `LibKa0s/OptionsWidgets.lua:411` — *"So the pitch is measured ONCE, from the INACTIVE cap atlas, on
  a throwaway texture -- never read"*
- `LibKa0s/OptionsWidgets.lua:441` — `local function tabArtHeight()`, whose docstring at `:436-440`
  says *"the UNSELECTED tab art's own height"*
- `tests/test_options_widgets.lua:1948` — `test("widgets: a wrapped strip's geometry is IDENTICAL for
  every value of the selection",`
- `tests/test_options_widgets.lua:1363` — the case's own note that a harness answering *"one
  number for every atlas could not fail the selection-invariance case below"*, which is why
  `M1-LK-08` gave the mock real per-atlas geometry

Measured from an unselected state, cached once, and pinned by a case that can actually fail.
Compliant.
