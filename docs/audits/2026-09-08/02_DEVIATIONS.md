# 02 — Deviations

**Standard:** v2.39.0 (2026-09-07). **Prefix:** `LK-` (assigned 2026-08-05, stable). New IDs continue
from `LK-28`. `LK-19` recurs from 2026-09-07 and keeps its ID; `LK-17d` recurs and **graduates** to a
root.
**Rule set:** `library-stack-§7`'s applicability list, now three lists and exhaustive. Sections in
the *Does not apply* list are recorded as such in `01_CURRENT_STATE.md` and are not listed here.

## Counts, with their basis

- **Headline tally — root deviations only: 7.**
- **Total including `derived from` dependents: 8.**
- By impact, roots only: **High 0 · Medium 0 · Low 6 · Info 1.**
- By impact, including dependents: **High 0 · Medium 0 · Low 7 · Info 1.**
- **MUST failures, roots only: 7.** Including dependents: **8.** Every entry below names a MUST; not
  one of them is reachable by a user, which is why every one is Low or Info.
- **Prior run (2026-09-07): 13 roots, 17 including dependents, of which High 1 · Medium 3 · Low 9.**
  Twelve of those thirteen roots are closed today, and the one High — `LK-16`, every composed media
  dropdown rendering empty in nine consumers — is closed in the bytes and pinned by three new cases.

**Where the remaining seven come from.** Two recur (`LK-19`, `LK-17d`). Two are **new because the
standard moved**: `library-stack-§7` gained its third applicability list at v2.39.0, so `compat`
(`LK-31`) binds this repo explicitly for the first time, and `localization-§5` published the
canonical `BRITISH`/`ALLOWED` lists and the scope a gate must read them over, which is what makes
`LK-28`/`LK-28d` measurable rather than arguable. One (`LK-29`) was **created by this cycle's own
remediation** — `M1-LK-12` narrowed the lint scope and left two documents describing the old one.
One (`LK-30`) is the half of a closed finding's fix direction that the remediation did not reach.
One (`LK-32`) is an arithmetic slip in a record frozen yesterday.

---

## Root deviations

| ID | Section | Grade | MUST? | Deviation | Fix direction |
|---|---|---|---|---|---|
| **LK-19** | `automated-tests-§5` | **Low** | MUST | **Release runs still ship with no `ANALYSIS.md`, and the process step that was supposed to stop that was never written.** §5 MUSTs the write-up for **every release** run. Both tags cut this cycle carry none: `docs/automated-tests/20260907-201015/` (release `1.26.0`) and `20260907-235828/` (release `1.27.0`). Measured today, **19 of 30 release bundles** have no write-up. `docs/releasing.md` — whose step 7 is the release procedure — **never mentions `ANALYSIS.md`**: `grep -ci analysis docs/releasing.md` returns `0`. `20260908-181447/ANALYSIS.md:90-110` discharges §5's *note the gap once* obligation, which is the other half of the rule and is now met; the missing half is the step. **Recurs from 2026-09-07 (`LK-19`, digest `LIBKA0S-A-04`).** | Add a numbered sub-step to `docs/releasing.md` step 7, between the `--release` run and the tag: *write `<stamp>/ANALYSIS.md` following the root `AUTOMATED_TESTS.md` prompt*, and add it to the hard-precondition block at `docs/releasing.md:134-153` so the tag cannot be cut without it. Do **not** backfill frozen bundles. |
| **LK-28** | `localization-§5` | **Low** | MUST | **216 British spellings in 33 live authored files, all of them outside the two directories the prose gate scans.** §5 binds *"prose in `README.md` and every file under `docs/`"* and *"code: comments, and identifiers"*, and v2.39.0 publishes the `BRITISH`/`ALLOWED` lists that make it mechanical. Swept with those lists whole: `tests/*.lua` **135** hits in 19 files, live `docs/api/*` **41** in 9, live `docs/` pages **35** in 3, `README.md`/`DEPENDENCIES.md` **5** in 2. A further **256** sit in 48 **superseded** `docs/api/version-*-docs.md`, which are a per-version record and are reported separately rather than folded in. **The shipped payload is clean** — `LibKa0s/` and `testkit/` return **0**, which is `LK-06` from 2026-09-07 closed, with its one ratified exemption (`lib.ICONS`'s `minimise`) carrying a register row. Low: comments and maintainer prose; nothing a player reads. | One sweep over the 33 live files with the published `BRITISH` list, `ALLOWED` removed as whole words first. Treat superseded `docs/api/` documents as frozen record and leave them. Then close `LK-28d`, or the 34th file re-opens this on the next commit. |
| **LK-29** | `documentation-§5`, `lint` | **Low** | MUST | **Two authored documents still describe the lint scope this cycle replaced.** `.luacheckrc:4` now reads `exclude_files = { "tests/_kit/" }` and `luacheck .` covers **51** files (`M1-LK-12`). Against that: `CLAUDE.md:177-178` says the figure is *"eighteen files today, the fourteen in `LibKa0s/` plus four under `testkit/`"*, and `DEPENDENCIES.md:120` says *"0 warnings / 0 errors, in 18 files"* with `:125-127` adding *"`tests/` and `docs/` are excluded"* — which is now flatly false. `lint` MUSTs the `0/0` be read with its scope attached; the generated `RESULTS.md:74-78` states the scope correctly, so the two hand-written copies are the ones that drifted. **Created by this cycle's own remediation.** | Update `CLAUDE.md:176-179` and `DEPENDENCIES.md:118-127` to the measured figure and the real exclusion, in one commit, and derive the wording from `RESULTS.md`'s generated sentence so the three cannot disagree again. |
| **LK-30** | `automated-tests-§4` | **Low** | MUST | **The watch list's warned-functions half is prose where §4 MUSTs a table.** §4: *"MUST carry the current complexity watch list below the table, as **two tables with header rows**: warned functions (Function / CCN / Location / Disposition), and files by `layout-§1` band."* `docs/automated-tests/RESULTS.md:99-101` renders `### Functions \`lizard\` warned on` followed by `None.` The file is generated, so the defect is in the emitter: `testkit/run-automated-tests.sh:557` returns `None.` when `CCN_WARN_ROWS` is empty, and `:574` does the same for the band table. This was named in `LK-17`'s fix direction on 2026-09-07; `M5-01` regenerated the record and left the emitter. **Cross-cutting — the kit is vendored into ten repos.** | In `fn_table()` and `band_table()`, print the header row unconditionally and emit no data rows when the set is empty. Bump `Kit.VERSION`, add the API document entry, re-vendor all nine consumers. |
| **LK-17d** | `automated-tests-§4`, anti-pattern #53 | **Low** | MUST | **A watch-list disposition has read "owed a tracked ID" across 25 release runs.** `RESULTS.md:110` starts `tests/test_options.lua`'s shelf-life clock at run `20260807-151331` and still says the entry is *"owed a tracked ID"*. Counted from the manifests, **25** release runs have shipped since that stamp (`1.9.0` … `1.27.0`); #53 caps a carried disposition at **three**. `bb9be8e` discharged two expired dispositions and left this one; the file is now 1266 lines and in the 1000–1500 band. **Graduates from a dependent to a root**: its 2026-09-07 parent `LK-17` (`RESULTS.md` stale) is closed and this survived it. | Open an issue naming the peel seam the disposition already describes — the render/refresh block, out to `tests/test_options_render.lua` — assign an owner, and replace the cell with *already tracked as #NN*. Or split the file. Either ends the clock; renewing the text does not. |
| **LK-31** | `compat` | **Low** | MUST | **The payload has no single `Compat` owner, and its two deprecated-API sites sit in two files.** `compat`: *"It is the **only** file that calls deprecated APIs and exposes shimmed versions"*, and anti-pattern #10 forbids direct calls. `LibKa0s/Env.lua:60-67` is the library's de-facto owner and shims `GetAddOnMetadata` correctly. `LibKa0s/Perf.lua:656-658` shims the spec reader **inline**, and its own comment at `:649-650` says it is *"the shape `Env.lua`'s C_AddOns shim models, applied here"* — so the duplication is knowing rather than accidental. `M1-LK-13` closed the real defect (no namespaced rung at all) and placed the fix at the call site. **Newly in scope:** at v2.38.0 `compat` appeared in neither of `library-stack-§7`'s two lists — that gap was 2026-09-07's `LK-27` — and v2.39.0's third list now says it binds. Low: both rungs are guarded, both answer today, and the failure mode is a diagnostic field reading `"?"`. | Move the spec read into `LibKa0s/Env.lua` as a named member beside `lib.GetAddOnMetadata` and have `Perf.lua` call it; bump both minors and add the API-document entries. If the placement is deliberate, that is a `## Documented deviations` row citing `compat` with a re-check trigger — not silence. |
| **LK-32** | `automated-tests-§5` | **Info** | MUST | **A frozen `ANALYSIS.md` contradicts itself by one on the figure it exists to record.** §5 MUSTs the write-up be *"evidence-backed against the bundle it sits in"*. `20260908-181447/ANALYSIS.md:92` reads *"Twenty of this repository's thirty-four bundles carry no `ANALYSIS.md`"*; `:93` in the same paragraph reads *"None of the nineteen older ones is getting one"*. Measured: 34 bundles, 15 with a write-up, **19** without — so `:93` is right and `:92` is one high. The two other figures in the same section (*30 of 34 are release runs*, *19 of those 30 carry none*) are both exact. Info: the bundle is frozen and §5 forbids editing it. | §5's own remedy: the **next** run's `ANALYSIS.md` states the corrected figure and says the previous one was one high. Nothing is edited in `20260908-181447/`. |

## Derived dependents (excluded from the headline tally and the MUST count)

| ID | Derived from | Section | Grade | Observation |
|---|---|---|---|---|
| **LK-28d** | `LK-28` | `localization-§5` (gate scope), `testing-§12` | Low | **The prose gate now carries the published lists whole and reads them over two directories.** `tests/test_prose.lua:19` sets `SHIPPED = { "LibKa0s", "testkit" }`, and `:59-63`'s listing does not recurse. `localization-§5`'s *What a gate scans* names four exclusions — vendored code, frozen bundles and released changelog entries, `locales/enGB.lua`, and a document whose subject is this rule — and `tests/`, `docs/` and `README.md` are none of them. So 216 live hits are invisible to a green suite, which is `testing-§12`'s failure mode in the gate for this very section, one scope narrower than the one `M1-LK-11` fixed. The gate's own comment at `:16-18` gives a reason for excluding `tests/` (fixtures spelling a host's field names), and that reason is a candidate for a register row rather than for silence. Does **not** graduate: it is not reachable independently of `LK-28`, and its grade is not higher. |

---

## Explicitly checked and NOT recorded as deviations

- **`layout-§1`, both over-cap files.** `tests/test_options_widgets.lua` (2398) and
  `LibKa0s/OptionsWidgets.lua` (1989) are each in one of the **three terminal states** v2.39.0 names:
  an open issue naming the seam (#8, #16) plus the census at `CLAUDE.md:102-105`, gated in both
  directions by `tests/test_layout_cap.lua`. `layout-§1` says an audit **MUST NOT** re-file against a
  file in that state. 2026-09-07's `LK-18` is **closed** by `M4-14`, and the Low grade it carried for
  want of a rule is retired by `M1-STD-08`.
- **`LK-16` / `LK-16d` — closed.** `LibKa0s/OptionsCompose.lua:240,284,313` now read
  `values = O.LSMValues("font"|"border"|"statusbar")` with no outer closure, and
  `tests/test_options_compose.lua:122,174-190` pin both the fix and the host-supplied
  table-returner contract. Issue #15 is closed `state:done`.
- **`LK-24` / `LK-24d` — closed.** The working-tree check returns **0** (was 7), and the gate that
  owns it — `tests/_kit/test_eol.lua`, kit revision 15 — reads the whole tracked set and is green.
- **`LK-21`, `LK-22` — closed.** `RESULTS.md:10-20` names the tag gate and *NOT EVALUATED*;
  `:22` and row `:26` read `passed/skipped/total`; the manifest carries `skipped` and the new
  `gates` object.
- **`LK-17` — closed.** All four standing sections and both watch-list entries are regenerated
  against `20260908-181447` and every figure in them reproduces. Its residue is `LK-30` and `LK-17d`.
- **`LK-23` — closed.** `LibKa0s/Perf.lua:656-657` takes `C_SpecializationInfo.GetSpecialization`
  first. What survives is the *placement*, filed fresh as `LK-31`.
- **`LK-26` — closed.** `README.md:3` and `CLAUDE.md:3` both read v2.39.0, matching
  `STANDARDS.md:1`.
- **`LK-20` — closed forward.** `v1.24.0` still has no bundle and never will; `docs/releasing.md:150-153`
  now states *"No tag is cut without a bundle whose `release` field names it"* and names `v1.24.0` as
  the reason. Both tags cut since carry a `release`-stamped bundle.
- **`LK-27` — closed upstream.** `library-stack-§7`'s applicability lists are now **three** and
  declared exhaustive over the Sections list, with *applies* as the default (`M1-STD-08`).
- **`LK-25`** was dismissed in the 2026-09-07 triage and the dismissal still holds:
  `RESULTS.md:82-86` frames the `perf` skip as `automated-tests-§3`'s sanctioned *nothing to run*,
  explicitly not a ratified `performance-§12` exemption, so no register row is owed.
- **The deviation register, all three `audit-review-history` MUSTs.** Read before filing. Its one row
  cites `localization-§5`, a rule the standard **did** amend at v2.39.0 — the amendment publishes a
  word list and does not add a path-fragment exception, so the row's substance is untouched and the
  row was written against the amended text. Its re-check trigger — *a `minimize.tga` beside the
  current file, or an alias map in `lib.Icon`* — has **not** fired: `LibKa0s/media/icons/` holds
  `minimise.tga` only and `lib.Icon` (`LibKa0s/Media.lua:202-207`) has no alias map. Its one
  evidence id, `LK-06` in `docs/audits/2026-09-07/`, resolves.
- **The inverse register rule, over eight closed `state:will-not-do` issues.** Only #22 declines a
  standards rule, and it has its row. #10, #21, #23, #24, #25, #26 decline enhancements, API
  proposals or scheduling; #4/#11/#13/#14/#15 are `state:done`. No row is owed and none is missing.
- **anti-pattern #45 / #47 / #48** — no `libs/`; this repo is the upstream. The equivalent gate,
  `tests/test_kitsync.lua`, is green over five cases.
- **anti-pattern #51** — a verbatim `lizard` run today reproduces `20260908-181447/complexity.txt`
  exactly. Nothing hand-edited, nothing stale in the numbers.
- **anti-pattern #53, the list as a whole** — seven entries, every one with a disposition, four of
  them pointing at issues (#7, #8, #16) or a fresh acceptance. It is not a backlog wearing a watch
  list's clothes; the one expired cell is `LK-17d`.
- **anti-pattern #70** — the wrapped tab strip's row pitch is measured once from the **inactive**
  cap atlas on a throwaway texture (`LibKa0s/OptionsWidgets.lua:411`; the measurement is `tabArtHeight()` at `:441-455`), never from the
  selected tab, and `tests/test_options_widgets.lua:1946+` asserts the selection invariance against a
  mock that now answers real per-atlas heights (`M1-LK-08`).
- **anti-patterns #60 / #62** — no `docs/pending/`, no `LEDGER.md`, no `[status]` prefix on any of
  26 issues.
- **anti-pattern #63** — `media/logos/` holds the collection logo only; no private copy of the
  shared payload.
- **`line-endings-§5`** — `.gitattributes` diffs clean against the canonical client-bound body over
  all 81 lines, with an empty tail. No appendix is claimed and none is owed.
- **`documentation-§4`** — no root `TODO.md`. No retired `complexity.md`, `file-index.md`,
  `conventions.md`, `perf-runs/`.
- **`library-stack-§7` Substitutes** — all four present and current; `CLAUDE.md`'s
  `## Documentation map` resolves in both directions.
- **`library-stack-§9`** — the `LSM30_Border` re-registration is the library's, sentinel-guarded,
  one registration per session however many consumers call it.
- **`versioning-git`** — semver through `v1.27.0`, trunk-based, per-file minors on their own axis
  and gated by `tests/test_versioning.lua`.
