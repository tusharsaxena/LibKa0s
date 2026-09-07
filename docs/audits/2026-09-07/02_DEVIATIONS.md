# 02 — Deviations

**Standard:** v2.38.0 (2026-09-02). **Prefix:** `LK-` (assigned 2026-08-05, stable). New IDs continue
from `LK-16`; `LK-06` and `LK-13` recur from the 2026-08-05 run and keep their IDs.
**Rule set:** `library-stack-§7`'s applicability list. Addon-only sections are recorded as N/A in
`01_CURRENT_STATE.md` and are **not** listed here.

**Digest mapping.** The consolidated cross-repo digest for this run numbers these `LIBKA0S-A-01`…`-14`
in the order below; the `LK-` IDs are this repo's stable ones and are what a future run reuses.

## Counts, with their basis

- **Headline tally — root deviations only: 13.**
- **Total including `derived from` dependents: 17.**
- By impact, roots only: **High 1 · Medium 3 · Low 9 · Info 0.**
- By impact, including dependents: **High 1 · Medium 4 · Low 12.**
- **MUST failures, roots only: 12.** Including dependents: **16.** One root — `LK-27` — is not a
  MUST failure: it is a defect in the standard's own text, not in this repo.
- **Eleven of the twelve root MUST failures are Low or Medium by impact.** That is not the rules
  being optional; it is a library repo whose defects are overwhelmingly in its **record** rather
  than in its **bytes**. The one High is in the bytes, and it is the one to fix first.

## Root deviations

| ID | Digest | Section | Grade | MUST? | Deviation | Fix direction |
|---|---|---|---|---|---|---|
| **LK-16** | A-01 | `options-ui-§16` (+ `library-stack-§7` additive-contract) | **High** | MUST | **Every composed font / border / bar-texture dropdown in the shipped payload renders empty.** `LibKa0s/OptionsCompose.lua:231,275,304` declare `values = function() return O.LSMValues("font") end`, but `O.LSMValues` already **returns the deferred closure** (`LibKa0s/Options.lua:764-776`). `enumList` calls `row.values()`, gets a *function*, and `LibKa0s/OptionsWidgets.lua:79` returns `{}`. Recorded as open issue [#15](https://github.com/tusharsaxena/LibKa0s/issues/15) (`state:untriaged`, `severity:high`) but **untriaged and unfixed in v1.25.0**, the tag consumers are re-vendoring today. | Drop the extra wrapper: `values = O.LSMValues("font")` (it is already the deferred form). Bump `OptionsCompose.lua` to minor 3, add the API document, re-vendor every consumer. |
| **LK-17** | A-02 | `automated-tests-§4` (anti-pattern #51) | **Medium** | MUST | **`RESULTS.md`'s four standing sections and its watch list are stale, and one of them asserts something false.** The watch list is headed *"Current state as of `20260823-235820`"* (`:119`) while the newest row is `20260903-161751` (`:15`); it states *"Nothing is over the 1500 cap"* (`:158`) while **two files are** (LK-18); the test-suite section says *"499 cases"* (`:49`) against 764; the lint section says *"Clean over 12 files"* and *"the 8 shipped library files"* (`:79-81`) against 18 and 14. `ab221d4` corrected exactly these figures in `README.md` and `DEPENDENCIES.md` and did not touch this file. | Regenerate all four standing sections and both watch-list tables against `20260903-161751`. Give the warned-functions half a real table with a header row (`automated-tests-§4` mandates two tables, not one table and a prose "None"). |
| **LK-18** | A-03 | `layout-§1` | **Low** | MUST | **Two tracked Lua files breach the 1500-LOC hard cap** — `LibKa0s/OptionsWidgets.lua` at **1838** and `tests/test_options_widgets.lua` at **2287**. `layout-§1` calls a >1500 file *"a bug — peel it"*. `20260903-161751/manifest.json` already records `"overCapFiles": 2`; nothing reads that field and the watch list contradicts it. Low by impact: structural, not reachable by a user. | Peel `OptionsWidgets.lua` along the widget-family seam (the tab-strip block at `:593+` stands alone); split `test_options_widgets.lua` by widget family. Record both as over-cap rows in the watch list in the same change. |
| **LK-19** | A-04 | `automated-tests-§5` | **Low** | MUST | **17 of 28 release runs carry no `ANALYSIS.md`**, including the 12 most recent consecutive releases (v1.14.0 → v1.25.0) and the current v1.25.0 bundle `20260903-161751`. §5 makes it a MUST *at release*. `docs/releasing.md`'s step 7 runs the bundle and reads the gate but never names the write-up. | Add the `ANALYSIS.md` write-up as an explicit numbered sub-step of `docs/releasing.md` step 7, following the root `AUTOMATED_TESTS.md` prompt. Frozen bundles are not backfilled; the next release starts the record. |
| **LK-20** | A-05 | `automated-tests-§6` | **Low** | MUST | **`v1.24.0` is tagged with no release bundle at all.** `git tag` lists `v1.24.0`; no `manifest.json` under `docs/automated-tests/` carries `"release": "1.24.0"` — the sequence goes `1.23.0` → `1.25.0`. §6 requires a four-suite bundle as part of **every** release, before the tag. | Note the gap in the next `ANALYSIS.md` rather than fabricating a bundle. Make `docs/releasing.md` step 7 a hard precondition of tagging. |
| **LK-21** | A-06 | `automated-tests-§4` | **Low** | MUST | **`RESULTS.md`'s lead-in still carries the retired half-truth, and the fix can never reach it.** `:9-11` reads *"`lint` and `tests` gate. `perf` and `complexity` are recorded and never fail a run"* — no commit checkpoint, no tag gate, no *"zero functions above CCN 15"*, no *NOT EVALUATED*. The corrected text exists in the emitter (`testkit/run-automated-tests.sh:425-432`) but sits in the **`else` branch that only fires when `RESULTS.md` does not exist** (`:413`). Every repo that already has the file — this one and all nine consumers — keeps the old sentence forever. **Cross-cutting.** | Teach the emitter to rewrite the prose block **above** the header row while preserving every row below it (the MUST-NOT is about dropping rows, not about refreshing prose); bump `Kit.VERSION`, re-vendor. A one-time hand edit here fixes one repo of ten. |
| **LK-22** | A-07 | `automated-tests-§4` | **Low** | MUST | **The `skipped` figure is dropped from both the trend row and the manifest.** §4: *"The `tests` column MUST carry the skipped figure alongside passed and total, and MUST NOT fold a skip into either."* The row is `$TESTS_PASS/$TESTS_TOTAL` (`testkit/run-automated-tests.sh:388`); the manifest emits `passed`/`failed`/`total` only (`:369`); and the parser's regex `[0-9]+ passed, [0-9]+ failed(, [0-9]+ total)?` (`:195`) cannot match the harness's own `"N passed, N failed, N skipped, N total"` line, so `TESTS_TOTAL` falls through to `passed + failed` (`:200`). Today 0 skips, so no number is wrong yet — a latent wrong total in ten repos. **Cross-cutting.** | Extend the regex to read the skipped field, carry `TESTS_SKIP` into the row (`passed/skipped/total`) and into `suites.tests.skipped`; bump `Kit.VERSION`, re-vendor. |
| **LK-06** | A-08 | `localization-§5` (anti-pattern #46) | **Medium** | MUST | **British spellings survive in the shipped payload, in the classes the gate does not look for.** 11 hits across `LibKa0s/*.lua`, including the **public catalog key `"minimise"`** (`LibKa0s/Media.lua:94`) — which the additive-only rule makes permanent surface — and user-visible chat text `"unlabelled"` (`LibKa0s/Perf.lua:723,864,1029`) and `"CANCELLED"` (`:948,1063`). anti-pattern #46 names `centre`, `cancelled` and `-ise` explicitly. Recurs from 2026-08-05; the *comment* sweep landed, the identifier and string classes did not. | Sweep `minimis→minimiz`, `centre/centred→center/centered`, `cancelled→canceled`, `unlabelled→unlabeled`, `travelled→traveled`. `"minimise"` is a **key consumers bind against**: add `"minimize"` as the live key, keep `"minimise"` as an alias for one major, deprecate in the changelog. |
| **LK-24** | A-09 | `line-endings-§1`, `line-endings-§6` | **Low** | MUST | **7 tracked files disagree with the declared CRLF pin**, two of them shipped payload. The `.gitattributes` body is byte-perfect; the working tree is not. Reported as **one** finding per the playbook — the fix is a single `git add --renormalize .` plus a re-checkout. Command and output in `03_EVIDENCE.md`. | `git add --renormalize .`, then `rm`/`git checkout --` the stragglers, then re-run the check. Widen the repo's own gate — see LK-24d. |
| **LK-23** | A-10 | `compat` | **Medium** | MUST | **`LibKa0s/Perf.lua:615-618` calls the deprecated `GetSpecialization` / `GetSpecializationInfo` globals directly**, guarded only for presence, with no `C_SpecializationInfo` path — while `LibKa0s/Env.lua:60-66` already models the exact shim shape for `GetAddOnMetadata`. When Blizzard removes the globals the guard passes silently and every consumer's perf record records `spec = "?"` forever. Reachable on a path users do run (a perf capture), degraded rather than broken. *(`compat` is addon-shaped and in neither §7 list — see LK-27 — but the rule it states is about calls, not about a folder.)* | Add the `C_SpecializationInfo.GetSpecialization()` branch ahead of the globals, in the same guarded shape `Env.lua` uses. Bump `Perf.lua` minor; re-vendor. |
| **LK-25** | A-12 | `documentation-§3` / `library-stack-§7` (register) | **Low** | MUST | **A ratified decline lives outside the register.** The permanent `perf` skip — no `tests/perf.lua`, so `performance-§9`'s zero-overhead scenario does not exist here — is argued at length in `docs/automated-tests/RESULTS.md:93-116` and in `docs/automated-tests/README.md` § *Why that skip is permanent*, and it is a real, dated decision. `CLAUDE.md:64-74`'s `## Documented deviations` register is **empty** and states *"None ratified today."* §7 makes that table the single home of a ratified decision; a decision recorded only in a record file is not ratified. Underlying decline recurs from `LK-13`. | Add one row: `| performance-§9 | No tests/perf.lua; no zero-overhead scenario | scenarios stay per-addon (performance-§9); the on-path evidence is held as tests/test_perf_isolation.lua:66 | 2026-08-25 | a consumer needs a shared scenario, or the sampler's on-cost is questioned |`. Then delete the "None ratified today" sentence. |
| **LK-26** | A-11 | `library-stack-§7` (substitute 3), `documentation-§5` | **Low** | MUST | **The standard-version pointer is ten minor versions stale, in both places that carry it.** `README.md:3` reads *"Built to the Ka0s WoW Addon Standard, v2.28.0"* and `CLAUDE.md:3` reads *"adheres to the Ka0s WoW Addon Standard (v2.28.0)"*. The current standard is **v2.38.0 (2026-09-02)**. §7 substitute 3 requires the README pointer to **name the version the repo is written against**; `documentation-§5` forbids the doc set drifting. Two copies of one string is also drift waiting to happen. | Move both to v2.38.0 in the same commit as this bundle's remediation, and add the bump to `docs/releasing.md`'s order so it moves with the audit rather than between audits. |
| **LK-27** | A-13 | `library-stack-§7` | **Low** | — | **Upstream: §7's applicability lists are not exhaustive, and the standard does not say what an auditor should do with the remainder.** Twelve sections appear in **neither** list — `layout`, `architecture`, `performance`, `compat`, `anti-patterns`, `naming-cheatsheet`, `public-api`, `standalone-windows`, `events-frames-taint`, `debug-logging`, `audit-review-history`, `open-evolutions`. Two of this run's findings (LK-18 against `layout-§1`, LK-23 against `compat`) sit in that gap and were filed on judgment, which is exactly what a checkable standard is supposed to remove. **Scope: standards-upstream.** | Add a third disposition to §7 — *"Applies where the rule is about code rather than about an addon's folders"* — naming each remaining section, or state a default and let the two named lists be the exceptions. |

## Derived dependents (excluded from the headline tally and the MUST count)

| ID | Digest | Derived from | Section | Grade | Observation |
|---|---|---|---|---|---|
| **LK-16d** | A-01d | `LK-16` | `testing-§12` | Medium | **No case pins `values()` on a composed media row.** `tests/test_options_compose.lua` has 29 functions and exactly one `values` assertion (`:274`), against the visibility dropdown; nothing calls `rows[n].values()` and asserts a table. A gate over the composers exists and cannot fail on their headline defect. Graduates the moment LK-16 is closed without it. |
| **LK-17d** | A-02d | `LK-17` | `automated-tests-§4` (anti-pattern #53) | Low | **The third band row has carried "owed a tracked ID" across 23 release runs.** `RESULTS.md:151-157` starts `tests/test_options.lua`'s shelf-life clock at v1.8.3 and says it is *"owed what the other two now have: an issue with an owner"*. v1.9.0 through v1.25.0 have shipped since; no issue exists, and the file is now 1146 LOC. §4 caps that at **three** consecutive release runs. |
| **LK-06d** | A-08d | `LK-06` | `testing-§12` | Low | **The prose gate's word list is six substrings** — `tests/test_prose.lua:113`: `colour`, `grey`, `behaviour`, `synthesise`, `normalis`, `recognis`. It cannot see `minimis`, `centre`, `cancelled`, `labelled`, `travelled`, `organis`, `optimis`, `initialis`, `customis`, `licence`, `analyse`. A gate that green-lights the spellings actually present in the payload is green against nothing. |
| **LK-24d** | A-09d | `LK-24` | `line-endings-§7` | Low | **The repo's own eol gate is scoped to one directory.** `tests/test_eol.lua:29` sets `BUNDLES = "docs/automated-tests"`, so it is structurally blind to the two shipped payload files and three `docs/api/` pages that fail today. The gate's own header calls it *"the working-tree line-ending gate"*. Widen it to `git ls-files` whole-repo — the per-path `check-attr` logic already generalizes. |

## Explicitly checked and NOT recorded as deviations

- **anti-pattern #45 / #48** — no `libs/` exists; this repo is the upstream. The equivalent gate
  (`testkit/` ↔ `tests/_kit/` byte-identity, `tests/test_kitsync.lua`) is **green**, 5 cases.
- **anti-pattern #47** — this repo *is* the library; there is nothing to hand-roll.
- **anti-pattern #51 (the numbers)** — a verbatim `lizard` run today reproduces
  `20260903-161751/complexity.txt` **exactly**: 13678 NLOC, 1900 functions, avg CCN 1.9, 0 warnings.
  No drift, no hand-editing. Only the surrounding prose is stale (LK-17).
- **anti-pattern #53 (the list as a whole)** — the watch list is short and two of its three entries
  carry real, owner-bearing dispositions (#7, #8). It is not a backlog wearing a watch list's
  clothes. The third entry is LK-17d.
- **anti-pattern #60 / #62** — no `docs/pending/LEDGER.md`, no `docs/pending/`, no `[status]` title
  prefix on any of 15 issues.
- **anti-pattern #63** — `media/logos/` holds the collection logo only. No private copy of the
  shared payload.
- **Retired docs** — `docs/complexity.md`, `docs/perf-runs/`, `docs/file-index.md`,
  `docs/conventions.md` all absent.
- **`documentation-§5`** — no retired `§N.M` reference to the standard anywhere in the live doc set
  or the shipped payload. The one dotted-number hit in `tests/fixture_options.lua:33` cites a design
  spec's own numbering, not the standard.
- **`documentation-§7`** — `DEPENDENCIES.md` is evidence-based, three-grouped, carries the PEP-668
  `pipx` workaround and a verify line per tool, and was corrected to 18 files at `ab221d4`.
- **`testing-§9`** — closed. `LK-09` from the prior run is fixed: the load list derives from
  `LibKa0s.xml` (`tests/run.lua:24`) and the suite list is pinned both ways
  (`testkit/framework.lua:277-316`).
- **`testing-§10`** — closed. `LK-15` from the prior run is fixed:
  `tests/test_versioning.lua:165-189` gates the API document per major.
- **`documentation-§2/§3` register purpose** — `CLAUDE.md`'s `## Documentation map` resolves in both
  directions. No orphan page, no dangling row.
- **`line-endings-§5`** — `.gitattributes` diffs **clean** against the canonical client-bound body.
- **`lint`** — 0/0 over 18 files, with the narrower-than-repo scope disclosed in `CLAUDE.md:116-118`
  and `DEPENDENCIES.md:120` rather than hidden.
- **`versioning-git`** — semver tags through `v1.25.0`, trunk-based, per-file minors on their own
  axis and gated by `tests/test_versioning.lua`.
- **Issue #10** (`state:will-not-do`) — a declined **enhancement**, not a declined standards rule.
  It owes no register row, and the inverse rule is therefore not triggered by it.
