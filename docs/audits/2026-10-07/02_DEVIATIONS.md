# 02 — Deviations

**Standard:** v2.76.1 (2026-10-07). **Prefix:** `LK-` (stable since 2026-08-05). New IDs start at `LK-39`.
**Rule set:** `library-stack-§7`'s applicability lists (see `01_CURRENT_STATE.md`). Sections on the
*Does not apply* list produce no entries.

## Counts, with their basis

- **Headline tally (root deviations only): 7.**
- **Total including `derived from` dependents: 7.** There are no dependents this run, because each
  root has its own fix.
- **By impact grade:**

  | Grade | Roots | Including dependents |
  |---|---|---|
  | High | 0 | 0 |
  | Medium | 0 | 0 |
  | Low | 6 | 6 |
  | Info | 1 | 1 |

- **MUST failures: 6** (the same with or without dependents). `LK-41` is a SHOULD.
- **No player can reach any of these.** Every one is a record, a document, an issue label or a dead
  fallback rung, which is why every grade is Low or Info. Each entry still names the MUST it fails.
- **Recorded (accepted) deviations: 6**, the six register rows at `CLAUDE.md:73-78`. They are excluded
  from both tallies.
- **Prior run (2026-09-23):** 12 roots, 12 including dependents (Low 10, Info 2).
  - Closed since: `LK-19`, `LK-30`, `LK-32`, `LK-33`, `LK-34`, `LK-35`, `LK-36` and `LK-38`.
  - Recorded as register row 5: `LK-37`.
  - Recurring: `LK-17d`, `LK-28` and `LK-29`.
  - New this run: `LK-39`, `LK-40`, `LK-41` and `LK-42`.

---

## Root deviations

| ID | Section | Grade | MUST? | Deviation | Fix direction |
|---|---|---|---|---|---|
| **LK-17d** | `automated-tests-§4`, `performance-§10`, anti-pattern #53 | **Low** | MUST | **Five of the six band entries on the watch list have read *Accepted* across 7 to 10 consecutive release runs, past the three-run shelf life.** Four were ruled at the v1.62.0 run (`20260926-182957`): `OptionsIdList.lua`, `OptionsIds.lua` and `OptionsWidgets.lua` (*"Accepted 2026-09-26"*), and `OptionsTabs.lua` (*"then accepted at 1293"*). They have been carried verbatim through the v1.63.0, v1.64.0, v1.65.0, v1.66.0, v1.67.0, v1.68.0, v1.68.1, v1.69.0 and v1.70.0 runs, ten runs in all. `Options.lua` was re-ruled at v1.65.0 and has been carried through 7 runs since. The tracker three of the cells cite is issue #32, which is **closed**, and `LK-ATS-01`, a finished sweep item. Neither is a tracked deviation with an owner. The sixth entry (`testkit/mock_base.lua`) reads *On notice* and is not counted. **Recurs from 2026-09-23 with the same shape.** | For each of the five, either peel on the seam its cell already names, or convert it into a tracked deviation: one open `state:triaged` issue per file naming the seam and the trigger, with the cell then reading *already tracked as #NN*. Re-rule at the next release run; do not renew. |
| **LK-28** | `localization-§5` | **Low** | MUST | **22 British-spelling lines in two live docs.** `docs/adoption-prompt.md` has 18 (*colour*, *modelling*, *judgement*, *standardised*, *colours*, *artefact*, *behaviour*, *summarise*, *renormalise*). `docs/adoption-report.md` has 4 (*judgement*, *summarise*, *licence*, *behaviour*). Both have rows in the `## Documentation map` (`CLAUDE.md:418`ff), both are briefs handed to consumer sessions, and `docs/adoption-prompt.md` has been edited in place five times since the 2026-09-24 sweep (most recently `cfefa99`, 2026-10-04). **New evidence against register row 3's reasoning:** row 3 (`CLAUDE.md:75`) lists *"21 in `docs/adoption-prompt.md`"* among *"records this repo must not rewrite or does not write at all"*. A file that is rewritten in place and registered as a live doc is not a record, and no `localization-§5` named exclusion covers it. The row's decision about which gate to run is not reopened; only its classification of these two files is. **Recurs from 2026-09-23 (the same rule, narrowed from 210 lines to 22).** | One spelling sweep of the two files with the published lists (`testkit/prose_lists.lua`). Add both to the scope `tests/test_prose.lua` gates as live docs. Strike *"21 in `docs/adoption-prompt.md`"* from row 3's record list in the same change. |
| **LK-29** | `documentation-§5` | **Low** | MUST | **A hand-maintained headroom figure disagrees with the tree.** `CLAUDE.md:219` says `testkit/mock_base.lua` is *"The closest file to the cap, with 44 lines of room"*, and `docs/automated-tests/RESULTS.md:193`'s authored Disposition cell says *"44 lines from breach"*. Both sit beside the measured figure of **1458** (`CLAUDE.md:213`, `RESULTS.md:193`'s LOC column). 1500 − 1458 = **42**. The 44 was true at 1456 and was not updated when kit revision 37 (`ca0e3d7`, 2026-10-06) added two lines. **Recurs from 2026-09-23 (a different figure).** | Correct both to 42, or drop the derived figure and keep only the measured line count and the trigger (1490). The second option cannot drift. |
| **LK-39** | `compat` (*A dead fallback rung is deleted, not shimmed*) | **Low** | MUST | **Two inline addon-API ladders in the payload keep a deprecated global as their last rung.** `LibKa0s/Env.lua:64-65` falls back to the bare `GetAddOnMetadata`, which is the compat section's own worked case of a dead rung (*"the global survives only as the newer namespace's member"*). `LibKa0s/OptionsIdList.lua:485` falls back to the bare `IsAddOnLoaded`, from the same 10.x move under `C_AddOns`, added at OptionsIdList minor 3 (`008a87a`, 2026-10-02). **The payload contradicts the standard on a fact.** `LibKa0s/Env.lua:52-53` says *"the bare global is deprecated but still present, so both rungs are live"*. Not reachable: on any client the `C_AddOns` rung answers first. | Check the live client first (`/dump GetAddOnMetadata, IsAddOnLoaded`). **If either is nil:** delete that rung (Env minor 2; OptionsIdList minor 4), retire the `tests/test_env.lua:31` fallback case, and drop the matching `.luacheckrc:8-9` read-globals. **If either is present:** the standard's worked example is wrong for retail. File that upstream against `compat` and keep the rung. |
| **LK-42** | `audit-review-history` (*evaluate every row's re-check trigger, and resolve every evidence id the row cites*) | **Low** | MUST | **Register evidence ids do not resolve to the bundle they name.** Row 3 (`CLAUDE.md:75`) cites *"the 2026-09-23 audit's `LibKa0s-A-07`"*. Row 5 (`:77`) says *"Filed as `LibKa0s-A-10` by the 2026-09-23 audit"*. The band prose (`:335`) cites *"2026-09-23 audit (`LibKa0s-A-03`)"*. `docs/audits/2026-09-23/` contains no `LibKa0s-A-*` id; those are the cross-repo consolidation's renumbering (Ka0sAddonsCommonTasks `docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/05_TRACEABILITY.md:68,72,75`), and they map to this repo's `LK-17d`, `LK-28` and `LK-37`. Rows 3 and 5 also cite the cross-repo plan items `LK-29` and `LK-30` (*"executing `LK-30` of the 2026-09-23 remediation plan"*). Those strings **collide** with this repo's own 2026-09-23 audit ids, which name different findings: `LK-29` is the hand-maintained figures and `LK-30` is the watch-list emitter. A reader who resolves them under `docs/audits/` lands on the wrong finding. | Replace each `LibKa0s-A-NN` with this repo's id: `LK-28` (row 3), `LK-37` (row 5) and `LK-17d` (`:335`). Qualify each cross-repo plan item with its bundle (*Ka0sAddonsCommonTasks `docs/2026-09-23-…/` item `LK-30`*), or cite this repo's commit instead. |
| **LK-41** | `documentation-§6` (*Citing the standard*) | **Low** | SHOULD | **One shipped comment cites the standard by `file:line`.** `LibKa0s/Slash.lua:267` reads *"(slash-commands.md:34)"*. It still resolves today: `slash-commands.md:34` is in `slash-commands-§1` and still says the library depends on *"LibStub and `LibKa0s-Core-1.0` and nothing else"*. It goes stale on the next upstream reflow. Tracked as open issue #43 (`state:triaged`), which defers the fix to *"the next LibKa0s release that touches the payload"*. Two such releases, v1.69.0 and v1.70.0, have shipped since without it. | `(slash-commands-§1)`, with a Slash minor bump, in the next release that touches `Slash.lua`, or sooner. Close #43 `state:done` in that change. |
| **LK-40** | `audit-review-history` (*Pending-audit decisions live in GitHub issues*) | **Info** | MUST | **Four closed issues carry an open-only status label.** #32, #33, #37 and #39 are `CLOSED` and labeled `state:triaged`. The status table binds `state:triaged` to issue state **open**, so a label query and the issue state now disagree. Each issue's work was done: #32 and #33 by the 2026-09-26 id peel and suite split, #37 by the `test_widgets.lua` split and #39 by kit revision 29. | Relabel all four `state:done` (`gh issue edit <n> --remove-label state:triaged --add-label state:done`). Space the four calls out. |

## Derived dependents

None this run.

## Recorded deviations (accepted; excluded from every tally)

| Register row | Rule | Covers | Decided | Trigger status | Evidence ids |
|---|---|---|---|---|---|
| `CLAUDE.md:73` | `localization-§5` | `.cancelled` / `IsCancelled` in two kit mocks and `tests/test_mock_ace.lua` | 2026-09-12; extended 2026-09-24 | Not fired | `1f1790c` and `docs/api/testkit/version-17-docs.md` resolve |
| `CLAUDE.md:74` | `localization-§5` | The `minimise` icon key (issue #22) | 2026-09-07 | Not fired: no `minimize.tga`, and no alias map in `lib.Icon` (`LibKa0s/Media.lua:202-207`) | `LK-06` resolves to `docs/audits/2026-09-07/02_DEVIATIONS.md:34` |
| `CLAUDE.md:75` | `localization-§5` | Kit prose gate unwired; this repo runs its own gate | 2026-09-23 | Not fired: `testkit/test_prose.lua` has no non-ASCII or retired-section case, and the kit's frozen exclusions (`testkit/prose_lists.lua:78-83`) do not name `docs/api/` or `docs/adoption/`. **Its record classification is reopened for two files by `LK-28`**, and its ids fail to resolve (`LK-42`) | `LibKa0s-A-07` and `LK-29` do not resolve here (`LK-42`) |
| `CLAUDE.md:76` | `compat` | Perf's inline spec read | 2026-09-23 | Not fired: no Perf floor raise since (`NEEDS_CORE = 1`, `NEEDS_LIFECYCLE = 1`, `LibKa0s/Perf.lua:23,34`) | `LK-31` resolves to `docs/audits/2026-09-08/02_DEVIATIONS.md:41`; `Compat.lua:270` and `:289` resolve |
| `CLAUDE.md:77` | `events-frames-taint-§1` | Three widget-owned raw `RegisterEvent` sites | 2026-09-24 | Not fired: still exactly three sites, no new event names. **Absorbs 2026-09-23 `LK-37`** | `LibKa0s-A-10` and `LK-30` do not resolve here (`LK-42`) |
| `CLAUDE.md:78` | `library-stack-§7` | `LineChart` promoted with one consumer | 2026-10-06; accepted 2026-10-07 | Not fired: only LootHistory draws a chart (`core/WidgetsSetup.lua`, `modules/Timeline.lua`) | LootHistory spec `docs/superpowers/specs/2026-10-06-timeline-ledger-design.md` resolves |

No row's cited rule has changed in a way that would end it.

## Upstream observations (WowAddonStandards; not counted here)

- **U1.** `library-stack-§7` (*Inter-module dependencies*) puts the Options→Pool floor at
  `OptionsWidgets.lua:33` and `OptionsTabs.lua:38`.
  - At v1.70.0, `OptionsWidgets.lua:33` is a comment line. The lookup and floor are at `:37-39`.
  - A third attach file also floors on Pool: `LibKa0s/OptionsNav.lua:20-22`. The sentence names two.
  - Fix: cite by symbol (`NEEDS_POOL`) rather than line, and name all three files.
- **U2.** The compat worked case (`GetAddOnMetadata` is a dead rung) and `LibKa0s/Env.lua:52-53`
  (*"deprecated but still present"*) cannot both be true. `LK-39` resolves which one is wrong.
- **U3.** `library-stack-§7` says its three lists classify every section, but some subsections appear in
  none of them:
  - `localization-§1`–`§4`;
  - `testing-§2`–`§8` and `§12`–`§15`;
  - `documentation-§8`/`§9`.

  They default to *applies* and produce nothing here, but the claim that the lists are exhaustive is
  not true of the text.

## Checked and not recorded as deviations

- **`layout-§1`.** Nothing is over the cap. The census and the watch list agree (0 over cap), and the
  kit gate is wired.
- **Line endings.** The body is byte-identical to the canonical client-bound file with no tail, check
  (e) is 0, and `test_eol` is green.
- **Lint scope.** Only `tests/_kit/` is excluded, and the harness global is in `files["tests/"]`.
  - The ignore list suppresses 152 warnings across three codes. Two of them (`212/self`, `212/event`)
    are the standard's own template. The third (`432/self`) carries its reason at `.luacheckrc:55-63`.
    The list is narrow, not blanket.
- **Complexity.** 0 warnings, max CCN 15, and the figures reproduce the newest bundle exactly, so there
  is no anti-pattern #51. Kit revision 37 is at least 35, `test_lizard_sighted` is wired and
  `blindFiles` is 0.
  - No refactor since 2026-09-23 needs the `performance-§11` shape check. The peels (`PerfSampler.lua`,
    `SlashParse.lua`, `WidgetsReorder.lua`, test splits) each moved code unchanged.
- **Release process.** Every tag from v1.55.0 on has a release bundle, with `ANALYSIS.md` from v1.56.0
  on, and a release-gate sentence stating the perf skip.
- **Inventory figures.** 15 majors and 34 files agree across `tests/majors.lua`, `LibKa0s.xml`,
  `library-stack-§7` at v2.76.1, the README table and the doc map. The 113 icons and 7 textures match
  the README.
- **Citations.** 3353 `filename-§N` citations across the live set, 0 out of range, and 0 retired dotted
  forms in the payloads.
  - 48 bare continuation references (`debug-logging-§4, §8`) appear in `LibKa0s/` and `testkit/`. A
    reader decodes them in context. They are neither malformed nor retired, so they are noted, not
    filed.
- **`library-stack-§7` Substitutes.** All present. README names v2.76.0 against today's v2.76.1, but
  v2.76.1 was published after v1.70.0's release check, so that is not filed.
- **`library-stack-§9`.** There is one sentinel-guarded re-registration.
- **`documentation-§4`.** There is no `TODO.md`.
- **`documentation-§9`.** No authored Lua sits in an addon source folder, so the rule has no instance.
- **The inverse register rule.** The seven `state:will-not-do` issues decline plan scope or API changes,
  not a binding MUST or SHOULD, so no register row is owed.
- **Frozen bundles.** Every bundle under `docs/audits/`, `docs/reviews/` and `docs/automated-tests/` has
  a single commit.
- **Anti-patterns #45, #47, #48, #59, #60, #62 and #63.** None has an instance: there is no `libs/` here,
  no provenance line is owed, there is no `LEDGER.md`, there is no `[status]` title prefix, and
  `media/logos/` holds logos only.
- **`versioning-git`.** Tags are annotated, and file minors are on their own axis.
