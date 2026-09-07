# 05 — Execution plan

Ordered, checkable remediation. Each step names its deviation ID(s) and the check that proves it
done. This is the hand-off to a separate remediation engagement; **this audit executed none of it**.

**The tally these sprints close: 13 root deviations and 4 dependents — 17 in total.** Sprint 1 closes
the only High. Sprints 2–5 are the twelve Low/Medium roots, ordered so the cheap upstream fixes
(sprint 3) land before the nine consumer re-vendors they would otherwise duplicate.

---

## Sprint 1 — the shipped defect (LK-16, LK-16d)

The only High, the only defect in bytes a player runs, and the only step that should not wait for
anything below it.

| # | Step | Deviation | Done when |
|---|---|---|---|
| 1.1 | Add three characterization cases to `tests/test_options_compose.lua` — `H.FontGroup`, `H.BorderGroup`, `H.BarGroup`, each asserting `type(rows[n].values()) == "table"`. Commit them **red**. | LK-16d | `lua tests/run.lua` reports 3 failures, each naming the composer group. |
| 1.2 | Change `LibKa0s/OptionsCompose.lua:231,275,304` to `values = O.LSMValues("<type>")`. | LK-16 | The three cases pass; `764 + 3` total, 0 failed. |
| 1.3 | Bump `OptionsCompose.lua` to **minor 3**; add the version block to `CHANGELOG.md`; create `docs/api/Options/version-14.13.3.3-docs.md`. | LK-16 | `tests/test_versioning.lua` green — it gates both the changelog block and the API document. |
| 1.4 | Release v1.26.0: green gate, `tests/_kit/run-automated-tests.sh --release 1.26.0`, **write `ANALYSIS.md`**, commit, tag. | LK-16, LK-19 | `docs/automated-tests/<stamp>/manifest.json` reads `"release": "1.26.0"` and `ANALYSIS.md` sits beside it. |
| 1.5 | Re-vendor all nine consumers; in ConsumableMaster, **remove the `settings/MacroBar.lua` `lsmValues` workaround** issue #15 records, and its explanatory comment. | LK-16 | Each consumer's `tests/test_vendor_sync.lua` green; `grep -rn lsmValues ../ConsumableMaster/settings/` empty. |
| 1.6 | Close issue #15 with `state:done`. | LK-16 | `gh issue view 15` shows `state:done`. |

## Sprint 2 — the two over-cap files, then the record that denied them (LK-18, LK-17, LK-17d)

Order is load-bearing: regenerating the watch list first means regenerating it twice.

| # | Step | Deviation | Done when |
|---|---|---|---|
| 2.1 | Peel `LibKa0s/OptionsWidgets.lua` (1838) at the tab-strip seam (`:593+`) into `LibKa0s/OptionsTabs.lua`, minor 1. Add it to `LibKa0s/LibKa0s.xml` in dependency order and to `MAJORS` in `tests/run.lua`. Pair it by version to the Options table, as `OptionsWidgets.lua` already is. | LK-18 | Both files under 1500; `tests/test_versioning.lua` green (it will demand the new composite API key). |
| 2.2 | Split `tests/test_options_widgets.lua` (2287) into `tests/test_options_tabs.lua`; add both to the declared suite list. | LK-18 | Both under 1500; `Kit.assertSuiteInventory` green in both directions; case count unchanged. |
| 2.3 | Open a tracked issue for `tests/test_options.lua` (1146 LOC) with an owner, matching #7/#8's shape. | LK-17d | Issue exists with `state:triaged` and an assignee. |
| 2.4 | Regenerate all four standing sections of `RESULTS.md` — cases (`:49`, `:58`), lint files (`:79-81`), the perf section, and the `as of` stamp (`:119`) — against the newest bundle. | LK-17 | No figure in the prose disagrees with the top table row. |
| 2.5 | Rebuild the watch list as **two tables with header rows**: `Function \| CCN \| Location \| Disposition` (one row: none, ceiling `Kit.run` at CCN 14) and `Band \| File \| LOC \| Disposition`, the latter reflecting 2.1/2.2 and citing #7, #8 and 2.3's new issue. | LK-17, LK-17d | Both tables present with headers; no entry reads "accepted" without an ID and an owner. |

## Sprint 3 — one kit revision, nine re-vendors (LK-21, LK-22)

Both edits are in the same file. Landing them together costs one re-vendor round instead of two.

| # | Step | Deviation | Done when |
|---|---|---|---|
| 3.1 | In `testkit/run-automated-tests.sh`, make the header-matches branch also **replace the prose block between the H1 and the header row** with the current lead-in, preserving every row below. | LK-21 | Running the suite against this repo rewrites `RESULTS.md:9-11` to the four-checkpoint text and leaves all 31 rows intact. |
| 3.2 | Extend the summary regex (`:195`) to capture `N skipped`; carry `TESTS_SKIP` into the row cell as `passed/skipped/total` and into `suites.tests.skipped`. **Keep the `Tests` column name** — changing it trips the warn-and-leave-alone branch in ten repos. | LK-22 | A run with a deliberately skipped case shows a non-zero middle figure in the row and in the manifest. |
| 3.3 | Kit revision → 15; `docs/api/testkit/version-15-docs.md`; copy to `tests/_kit/`. | LK-21, LK-22 | `tests/test_kitsync.lua` green — same files, byte-identical, runner mode 100755 in both copies. |
| 3.4 | Re-vendor `tests/_kit/` into all nine consumers; run each suite once so each `RESULTS.md` picks up the corrected lead-in. | LK-21, LK-22 | Each consumer's `RESULTS.md:9-…` carries the tag-gate sentence, with its row history intact. |

## Sprint 4 — prose, provenance and the register (LK-06, LK-06d, LK-23, LK-25, LK-26)

Small, independent, and every one of them ships in a single library release plus one re-vendor.

| # | Step | Deviation | Done when |
|---|---|---|---|
| 4.1 | Widen `tests/test_prose.lua:113`'s `BRITISH` list (at minimum `minimis`, `centre`, `cancelled`, `labelled`, `travelled`, `organis`, `optimis`, `initialis`, `customis`, `licence`), with carve-outs recorded beside it. Commit **red**. | LK-06d | The case fails naming all 11 current hits. |
| 4.2 | Sweep the comment and chat-string hits: `Options.lua:118`, `OptionsWidgets.lua:593,596`, `OptionsCompose.lua:7`, `Widgets.lua:951`, `Perf.lua:723,864,948,1029,1063`. Bump each touched file's minor. | LK-06 | 4.1's case green; each touched file has a changelog line. |
| 4.3 | `Media.lua:94` — add `"minimize"` as a live catalog key beside `"minimise"`; document `"minimise"` as deprecated with its removal condition in `CHANGELOG.md` and the Media API document. **Do not remove it** (`library-stack-§7`, additive-only). | LK-06 | Both keys resolve; `docs/api/Media/version-4-docs.md` names the deprecation. |
| 4.4 | `LibKa0s/Perf.lua:615` — take `C_SpecializationInfo.GetSpecialization` first, falling back to the global, in `Env.lua:60-66`'s shape. Add `C_SpecializationInfo` to `.luacheckrc` `read_globals` with a reason. Add a case that defines the modern API and asserts the new arm. | LK-23 | New case green; `luacheck .` 0/0; `grep -n 'C_SpecializationInfo' LibKa0s/Perf.lua` returns a hit. |
| 4.5 | Add the `performance-§9` row to `CLAUDE.md`'s `## Documented deviations` table and delete the `**None ratified today.**` sentence at `:69`. | LK-25 | The register has one row citing rule, reason, Decided date and re-check trigger. |
| 4.6 | `README.md:3` and `CLAUDE.md:3` → **v2.38.0**. Add a "check the standard-version pointer" line to `docs/releasing.md`'s order. | LK-26 | `grep -rn 'v2\.28\.0' README.md CLAUDE.md` empty. |
| 4.7 | Release, with a bundle and an `ANALYSIS.md`; re-vendor the nine. | LK-06, LK-23, LK-19 | Bundle manifest names the release; `ANALYSIS.md` present. |

## Sprint 5 — process, and the tree (LK-19, LK-20, LK-24, LK-24d)

| # | Step | Deviation | Done when |
|---|---|---|---|
| 5.1 | `docs/releasing.md` step 7 — add the `ANALYSIS.md` sub-step after the gate read, and make the bundle a **precondition of the tag** rather than a companion to it. | LK-19, LK-20 | The order names the write-up and says a tag without a bundle is not a release. |
| 5.2 | Note the **v1.24.0** bundle gap in the next release's `ANALYSIS.md`. Do **not** backfill a bundle or edit a frozen run. | LK-20 | The gap is written down once, in a live document. |
| 5.3 | Widen `tests/test_eol.lua` from `BUNDLES = "docs/automated-tests"` (`:29`) to the whole tracked set — only `trackedFiles()` (`:37-56`) changes; keep the NUL guard at `:107`. Update the file header to say what it now covers. Commit **red**. | LK-24d | The case fails naming the 7 stragglers. |
| 5.4 | `git add --renormalize .`, review, then `rm <path> && git checkout -- <path>` per straggler. | LK-24 | `line-endings-§7`'s check (e) prints **0**; 5.3's case green. |
| 5.5 | Re-vendor the widened `test_eol.lua`'s kit dependencies if any, and run each consumer's own check once — four of eleven repos held stragglers when this check was last corrected. | LK-24 | Each consumer's (e) count recorded. |

## Sprint 6 — upstream, not here (LK-27)

| # | Step | Deviation | Done when |
|---|---|---|---|
| 6.1 | Open a PR against `WowAddonStandards` proposing a third disposition in `library-stack-§7` for the twelve unlisted sections, or a stated default with the two lists as exceptions. | LK-27 | PR open, naming all twelve. |
| 6.2 | In the same PR: correct §7's module table from *"ten majors across thirteen files"* / three Options files to **fourteen** files, naming `OptionsCompose.lua`. | LK-27 | The standard's inventory matches `LibKa0s/LibKa0s.xml`. |
| 6.3 | In the same PR: reconcile §7's "does not apply" retirement of `automated-tests/README.md` and `RESULTS.md` against the `automated-tests` section that mandates both. | LK-27 | The two lists no longer read as contradicting each other. |

---

## Verification, at the end of every sprint

```sh
lua tests/run.lua        # 0 failed, and the skipped figure read rather than dropped
luacheck .               # 0 warnings / 0 errors
lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
git ls-files -z | xargs -0 -I{} sh -c '
  set -- $(git check-attr text eol -- "{}" | sed "s/.*: //")
  [ "$1" = unset ] && exit
  cr=$(tr -dc "\r" < "{}" | wc -c); lf=$(tr -dc "\n" < "{}" | wc -c)
  case "$2" in crlf) [ "$lf" -gt 0 ] && [ "$cr" -ne "$lf" ] && echo "{}";;
               lf)   [ "$cr" -gt 0 ] && echo "{}";; esac' 2>/dev/null | wc -l
```

The `lizard` invocation is **verbatim from the standard**. A locally improved one produces numbers
that cannot be compared with the committed report, which is the entire point of running it.
