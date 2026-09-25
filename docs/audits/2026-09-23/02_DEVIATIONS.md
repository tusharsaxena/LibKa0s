# 02 — Deviations

**Standard:** v2.64.0 (2026-09-23). **Prefix:** `LK-` (stable since 2026-08-05). New IDs start at `LK-33`.

**Recurring IDs.** Six IDs recur from 2026-09-08 and keep their IDs: `LK-17d`, `LK-19`, `LK-28`,
`LK-29`, `LK-30` and `LK-32`.

**Rule set.** `library-stack-§7`'s three applicability lists (see `01_CURRENT_STATE.md`). Sections on the
*Does not apply* list produce no entries.

## Counts, with their basis

- **Headline tally (root deviations only): 12.**
- **Total including `derived from` dependents: 12.** No dependents this run, because each root below has
  its own fix.
- **By impact (roots only, and the same including dependents):** High 0, Medium 0, Low 10, Info 2.
- **MUST failures (roots only, and the same including dependents): 12.**
  - Every entry names a MUST.
  - None is reachable by a player, which is why every grade is Low or Info.
  - The failures are process records, gates, documentation and one latent event-registration shape.
- **Recorded (accepted) deviations, excluded from both tallies: 4.** These are the four register rows at
  `CLAUDE.md:73-76`. They absorb the 2026-09-08 `LK-28d` (row 3) and `LK-31` (row 4).
- **Prior run (2026-09-08):** 7 roots and 8 including dependents (Low 6 + 1 dependent, Info 1).
  - Now recorded or closed: `LK-31` (register row 4) and `LK-28d` (register row 3).
  - Recurring: `LK-19`, `LK-28`, `LK-29`, `LK-30`, `LK-17d` and `LK-32`.
  - New this run: `LK-33` to `LK-38`.

**Where the six new roots come from.**

- **The release process** (`LK-35`, `LK-36`). The rate of releases outran the written release order:
  six tags were cut with no release run, and the perf-skip sentence stopped appearing in the release notes.
- **The cap census and watch list** (`LK-33`, `LK-34`). These are two records of one fact that now
  disagree. Two over-cap rows point at closed issues and a deleted gate file, and one census row claims a
  register row that does not exist.
- **`events-frames-taint-§1`** (`LK-37`). It binds a library repo explicitly, and this is the first audit
  here to run its per-event isolation check.
- **A register evidence reference** (`LK-38`, Info). One register row cites evidence that resolves to a
  commit rather than to a bundle.

---

## Root deviations

| ID | Section | Grade | MUST? | Deviation | Fix direction |
|---|---|---|---|---|---|
| **LK-17d** | `automated-tests-§4`, anti-pattern #53 | **Low** | MUST | **Five of the ten on-notice watch-list entries carry a disposition past its shelf life or an empty cell past its first release.** (1) `tests/test_options.lua` (`RESULTS.md:163`) still says *"owed a tracked ID"*, a clock started at v1.8.3; **54** distinct release versions have shipped since, and no issue exists. (2) `LibKa0s/Widgets.lua` (`:160`) and (3) `tests/test_widgets.lua` (`:166`) each declare their own shelf life *crossed at `20260916-093057`*; **20** distinct release versions have shipped since, and the issue `:166` calls *"the action item of this run"* was never opened. (4) `LibKa0s/Options.lua` (`:157`) says *"Re-check at 1350"*; the file passed that at v1.46.0 (1460, per `CLAUDE.md:192`) and is at 1476, and the cell has not been re-ruled. (5) `LibKa0s/OptionsTabs.lua` (`:158`) has been **blank** in every release row from v1.50.0 through v1.55.0. §4 says a newly-crossed entry still blank at the next release *"has performed the ritual and skipped the point"*. **Recurs from 2026-09-08 (`LK-17d`), now wider.** | One pass over the Disposition column. Open an issue (or peel) for `test_options.lua`, `Widgets.lua` and `test_widgets.lua`, and replace each cell with *already tracked as #NN*. Re-rule `Options.lua` against its fired trigger. Write a disposition for `OptionsTabs.lua`, and, before the next release, for the two cells that are new this run (`test_prose.lua` `:162` and `test_schema.lua` `:164`). |
| **LK-33** | `layout-§1`, `automated-tests-§4` | **Low** | MUST | **The watch list's over-cap dispositions contradict the census they must point at.** Both sections say the band table and the census *"MUST agree"*, and that an over-cap cell *"points at the census row rather than ruling a second time"*. Measured: (a) `RESULTS.md:167` points `LibKa0s/OptionsWidgets.lua` at **#16**, which is **closed** `state:done`, and names `tests/test_layout_cap.lua` as the gate, a file that **no longer exists**. The census (`CLAUDE.md:130`) says **#32**. (b) `RESULTS.md:169` points `tests/test_options_widgets.lua` at **#8** (closed) where the census (`:129`) says **#33**. (c) `RESULTS.md:168` leaves `testkit/framework.lua` **blank** at a release run, although the census row (`:131`) has existed since kit revision 25. | Replace all three cells with a pointer of the form *"census row, `CLAUDE.md` § Files over the 1500-line cap"*. The runner carries the authored cell forward, so this edit lands once. |
| **LK-34** | `layout-§1`, `audit-review-history` | **Low** | MUST | **A census row names a terminal state the register does not hold.** `CLAUDE.md:131` dispositions `testkit/framework.lua` (1583) as *"Ratified deviation row"*, and `:163-165` calls it *"an owner decision … recorded here"*. The register table at `:71-76` holds four rows, `:78` says *"Four rows"*, and **none** cites `layout-§1`. `layout-§1`'s third terminal state is *"a ratified deviation row under `## Documented deviations` … carrying a re-check trigger"*, and the register's own shape (`CLAUDE.md:51-53`) is `Rule \| What differs \| Why \| Decided \| Re-check trigger`. The census row has a trigger but no Rule and no Decided date. The kit gate is green because it reads the word, not the register. | Add the fifth register row: `layout-§1`, *`testkit/framework.lua` is over the cap at 1583*, the reason already written at `:154-165`, Decided 2026-09-23, and the trigger already at `:131`. Update `:78` to *"Five rows"*. If the owner would rather track it as an issue, open one and repoint the census row instead. |
| **LK-19** | `automated-tests-§5` | **Low** | MUST | **Release runs still ship without `ANALYSIS.md`, and the release order still does not ask for one.** The v1.55.0 release bundle `20260923-144526/` has none. Since the 2026-09-08 audit, **32 of 38** release-stamped bundles have none. `grep -ci analysis docs/releasing.md` still returns **0**. One frozen write-up misreads the rule: `20260916-093057/ANALYSIS.md:60-62` calls the missing write-up on `20260916-033929` *"not a breach"*, but that bundle's `release` is `"1.38.0"`, and §5 makes a release run's write-up a MUST. **Recurs from 2026-09-08.** | Add the numbered sub-step to `docs/releasing.md` step 7: *write `<stamp>/ANALYSIS.md` per the root `AUTOMATED_TESTS.md` prompt*. Add `test -f <stamp>/ANALYSIS.md` to the hard-precondition block (`docs/releasing.md:141-160`). Do not backfill (§5); the next write-up notes the gap once and corrects `:60-62`'s reading. |
| **LK-35** | `automated-tests-§6`, `automated-tests-§3` | **Low** | MUST | **Six tags were cut with no release bundle naming them, all after the release order said this could not happen.** `docs/releasing.md:157` says *"No tag is cut without a bundle whose `release` field names it"*, citing `v1.24.0`. Taking every tag and removing every manifest `release` value leaves `v1.28.0`, `v1.29.0`, `v1.36.0`, `v1.36.1`, `v1.54.1` and `v1.54.2` after the 2026-09-08 audit. The last two were cut 5 minutes apart (2026-09-22 20:30 and 20:35). The release gate (§3, *all four suites at `pass`*) was therefore **not evaluated** for six versions vendored into eleven consumers. | Make the precondition mechanical: a check (in `docs/releasing.md` step 7, or as a `tests/test_versioning.lua` case) that the tag being cut appears as a `release` in some `docs/automated-tests/*/manifest.json`. Do not fabricate bundles for the six; name them once in the next `ANALYSIS.md` (the §5 forward-closure pattern). |
| **LK-36** | `automated-tests-§3` | **Low** | MUST | **The release notes stopped stating the perf skip.** §3 says the `perf` skip for an addon shipping no `tests/perf.lua` *"MUST be stated as such in the release notes"*. `CHANGELOG.md` carries that sentence for v1.54.0 (`:579-581`), v1.52.0, v1.51.0 and v1.50.0. It is **absent** from v1.55.0 (`:13-507`), v1.53.0 (`:583-605`), v1.49.1, v1.49.0, v1.48.1, v1.48.0 and v1.47.0 (a per-entry grep, recorded in `03_EVIDENCE.md` §E9). v1.54.1 and v1.54.2 had no run to report (`LK-35`). | Put the sentence into the release template in `docs/releasing.md` step 7, next to the manifest read, so each entry states *"Release gate (`docs/automated-tests/<stamp>/`): … Perf SKIPPED, not measured — no `tests/perf.lua`"*. The next entry states it; released entries are not rewritten. |
| **LK-28** | `localization-§5` | **Low** | MUST | **210 British spellings in 33 live authored files.** I ran the published lists (91 `BRITISH`, 30 `ALLOWED`) with `testkit/test_prose.lua`'s own matcher. By group: `tests/` **151** lines in 23 files; the live (highest-version) `docs/api/` documents **25** in 5; `docs/releasing.md` **10**; `README.md` **4**; `DEPENDENCIES.md` **1**; `tools/artwork/*.py` **19** in 2. That excludes the ratified payload hits (`LibKa0s/` 1 and `testkit/` 11, rows 1 and 2) and `CLAUDE.md`'s two quotations of them. The **560** lines in superseded `docs/api/` per-version documents are a record and are reported separately, not counted. Register row 3 ratifies the gate's *scope*, not the spellings: its trigger names the `tests/` sweep as still owed. **Recurs from 2026-09-08 (216 in 33 then).** | One sweep with the published lists over the 33 files, with `ALLOWED` removed as whole words first. Leave superseded `docs/api/` documents alone. That sweep is also half of register row 3's trigger. |
| **LK-29** | `documentation-§5`, `lint` | **Low** | MUST | **Hand-maintained figures in root `CLAUDE.md` disagree with the tree.** (a) `:268-269` says the lint scope is *"eighty files at v1.55.0"*. `luacheck .` reports **81**, and so do `DEPENDENCIES.md:124` and `docs/releasing.md:19`. Commit `ae48f3f` corrected those two after `244c752` added `tests/test_kit_eol.lua`, and missed this one. (b) `:203` records `tests/test_schema.lua` at **1101**, which was true at `06b4051`. `be91249` took it to **1233** on the same day, and `RESULTS.md:164` says 1233. (c) `:180` cites `LibKa0s/OptionsTabs.lua:39` for `__tabsMinor` / `__tabsShellMinor`, but line 39 is blank and the guard is at `:43-46`. **Recurs from 2026-09-08 (the same lint-scope figure, a different number).** | Correct all three in one commit. For (a), quote the runner's generated lint sentence rather than retyping a count. For (c), cite the symbol, which does not drift the way a line number does. |
| **LK-30** | `automated-tests-§4` | **Low** | MUST | **The warned-functions half of the watch list is still prose where §4 requires a table with a header row.** `RESULTS.md:149-151` reads `### Functions \`lizard\` warned on` followed by `None.` The emitter is unchanged: `testkit/run-automated-tests.sh:714` (`fn_table`) and `:731` (`band_table`) both `printf 'None.\n'; return` on an empty set. The kit is vendored byte-identically into eleven consumers, so every consumer's record has the same defect. **Recurs from 2026-09-08 unchanged.** | In both functions, print the header row unconditionally and emit no data rows when the set is empty (optionally one `\| — \| … \|` row). Bump the kit revision, add the API-document entry and re-vendor. |
| **LK-37** | `events-frames-taint-§1` | **Low** | MUST | **The payload registers client events raw on private frames, with no per-event isolation and no record of rejected names.** `LibKa0s/OptionsTabs.lua:102-103` and `:139-140` call `f:RegisterEvent("PLAYER_REGEN_DISABLED")` and `f:RegisterEvent("PLAYER_REGEN_ENABLED")`, and `LibKa0s/Widgets.lua:393` calls `m:RegisterEvent("GLOBAL_MOUSE_DOWN")`. §1 requires *"every `RegisterEvent` goes through a single `pcall`ed helper"*, a player-reachable record of rejected names, and AceEvent rather than a private frame. `library-stack-§7` says this section *"Binds"* here. Not reachable today: all three names exist on every supported client, and a throw would be one widget's registration, not a block. Filed because the MUST's text is unmet and no register row records why. | Owner decision. Either (a) route the three through one `pcall`ed payload helper that records a rejected name where `LibKa0s-DebugLog-1.0` can show it, or (b) file a register row: the library cannot floor on the consumer-vendored AceEvent (the argument `LibKa0s-Bus-1.0`'s no-floor note already makes), and these are widget-owned frames registering stable core events. |
| **LK-32** | `automated-tests-§5` | **Info** | MUST | **The corrected figure owed by the 2026-09-08 audit was never stated forward.** `20260908-181447/ANALYSIS.md:92` over-counts by one (`LK-32`, 2026-09-08). The next write-up, `20260916-093057/ANALYSIS.md`, mentions the bundle (`:61`) and does not correct it. **Recurs.** | The next `ANALYSIS.md` states once that `20260908-181447:92` was one too high. Nothing frozen is edited. |
| **LK-38** | `audit-review-history` | **Info** | MUST | **A register row's evidence reference resolves to a commit, not a bundle.** Register row 1 (`CLAUDE.md:73`) says *"Filed by the v1.31.0 review"*. `docs/reviews/` holds `2026-07-31`, `2026-08-05` and `2026-09-07` only. The review was committed as `1f1790c` (*"v1.31.0 review: kit 17 and the Options arm, fixed before release"*, 2026-09-12), with no frozen bundle. The rule asks that each evidence ID the row cites resolve; this one points a reader at a bundle that does not exist. | Change the row's evidence to cite commit `1f1790c` (and `docs/api/testkit/version-17-docs.md`) instead of an unnamed review. |

## Derived dependents

None this run. Each root above has an independent fix.

## Recorded deviations (accepted; excluded from every tally)

| Register row | Rule | Covers | Decided | Trigger status |
|---|---|---|---|---|
| `CLAUDE.md:73` | `localization-§5` | `.cancelled` / `IsCancelled` in two kit mocks | 2026-09-12 | Not fired. The evidence reference is `LK-38` |
| `CLAUDE.md:74` | `localization-§5` | The `minimise` icon key (issue #22) | 2026-09-07 | Not fired: no `minimize.tga`, and no alias map at `LibKa0s/Media.lua:202-207` |
| `CLAUDE.md:75` | `localization-§5` | Kit prose gate unwired, own gate over the shipped folders only. **Absorbs 2026-09-08 `LK-28d`** | 2026-09-23 | Not fired: the kit gate has no non-ASCII or retired-section case, and the sweep has not happened |
| `CLAUDE.md:76` | `compat` | `LibKa0s/Perf.lua:707-715` inline spec read. **Supersedes 2026-09-08 `LK-31`** | 2026-09-23 | Not fired: no Perf floor raise since |

---

## Checked and not recorded as deviations

- **`layout-§1`, the two Options over-cap files.** Each has an open `state:triaged` issue naming a seam
  (#32, #33), and the census names both. The rule says an audit MUST NOT re-file them.
  (`testkit/framework.lua` is the exception, as `LK-34`.)
- **Kit sync (`testing-§11`).** `diff -r testkit tests/_kit` is empty, and the gate is green.
- **Line endings.** The body is identical to canonical, with no tail. Check (e) returns **0**, and the kit
  gate is green.
- **Complexity.** 0 warnings, and the numbers reproduce the latest bundle exactly, so there is no
  anti-pattern #51. No refactor since the last bundle, so the `performance-§11` shapes have nothing to
  inspect.
- **Lint scope.** `exclude_files` is exactly `tests/_kit/`, and the harness globals are in `files["tests/"]`.
- **Generators (`layout-§1`, v2.61.0).** Both `.py` files and `gen-api-members.lua` sit under `tools/`,
  outside the payload, and `DEPENDENCIES.md` names their interpreter.
- **Inventory figures.** 15 majors, 21 files and 11 consumers agree across the manifest, the XML, the tree
  and every prose statement.
- **`library-stack-§7` substitutes.** All present: the `CLAUDE.md` compliance section, `DEPENDENCIES.md`,
  a README pointer naming v2.64.0, and a documentation map that resolves both ways. `CHANGELOG.md` is
  present, as required here.
- **`documentation-§4`.** No root `TODO.md`, and no retired `complexity.md`, `file-index.md`,
  `conventions.md` or `perf-runs/`.
- **`library-stack-§9`.** One sentinel-guarded `LSM30_Border` registration (`LibKa0s/Options.lua:294`).
- **`compat`.** The only deprecated-global site outside the owners is register row 4.
- **`architecture-§4` / `naming-cheatsheet`.** No `Ka0s_` message literal in the payload.
- **Anti-patterns #45, #47, #48, #59, #60, #62 and #63.** None has an instance: no `libs/`, no provenance
  line owed, no `LEDGER.md`, no `[status]` prefix, and `media/logos/` holds the logo only.
- **Frozen bundles.** Every prior `docs/audits/` and `docs/reviews/` bundle has one commit only.
- **`versioning-git`.** Semver, annotated tags, file minors on their own axis. The branch in use was
  requested by the owner.
- **Issues #17–#20** ("deferred to kit 16", kit now 25) are an untriaged backlog, not a store defect.
  They are left to triage.
- **`manifest.json`'s `addonVersion`** reads the pre-tag version on a release run, by design
  (`testkit/run-automated-tests.sh:93`).
