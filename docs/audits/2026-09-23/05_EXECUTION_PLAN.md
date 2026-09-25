# 05 — Execution plan

The plan is ordered so nothing a consumer vendors changes twice. Every step names its deviation ID(s)
and ends green (`lua tests/run.lua` 0 failed, `luacheck .` 0/0) before it commits. Figures below are the
ones measured in `03_EVIDENCE.md`, and they agree with `02_DEVIATIONS.md`:

- 12 roots, 0 dependents;
- 210 British lines in 33 files;
- 6 unbundled tags since 2026-09-08;
- 32 of 38 release bundles since 2026-09-08 without `ANALYSIS.md`;
- 5 expired or blank band dispositions;
- 3 over-cap cells in disagreement with the census.

## Sprint 1: records and registers (docs-only, no release, no re-vendor)

1. [ ] **`LK-34`.** Add register row 5 (`layout-§1`, `testkit/framework.lua`, Decided 2026-09-23, with
   its trigger) at `CLAUDE.md:77`. Change `:78` to *"Five rows"*. Repoint the census cell at `:131` to
   the row. *(Or, by owner choice, open an issue and repoint `:131` at it.)*
2. [ ] **`LK-38`.** In register row 1 (`CLAUDE.md:73`), cite commit `1f1790c` and
   `docs/api/testkit/version-17-docs.md` as the v1.31.0 review's evidence.
3. [ ] **`LK-29`.** Make three corrections in root `CLAUDE.md`:
   - `:268-269`: lint scope to 81, or a pointer to `RESULTS.md`'s generated lint sentence;
   - `:203`: `tests/test_schema.lua` to 1233, after re-running
     `git ls-files '*.lua' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn` and re-checking every band
     figure in `:185-218`;
   - `:180`: cite `lib.__tabsMinor` / `lib.__tabsShellMinor` by symbol.
4. [ ] **`LK-17d`.** File three issues (`state:triaged`, `severity:low`), for `tests/test_options.lua`,
   `LibKa0s/Widgets.lua` and `tests/test_widgets.lua`, each naming the seam its current cell describes.
   Space the `gh issue create` calls out; do not burst them.
5. [ ] **`LK-17d`.** Open an issue for `testkit/test_prose.lua` (1499, one line from the cap, kit code).
   Decide `LibKa0s/Options.lua`'s re-rule (issue naming the font-preload peel, or a written acceptance
   with a new trigger below 1500).
6. [ ] **`LK-17d`, `LK-33`.** Edit the Disposition column of `docs/automated-tests/RESULTS.md`:
   - `:157` (Options), `:160` (Widgets), `:163` (test_options) and `:166` (test_widgets): *already
     tracked as #NN*;
   - `:158` (OptionsTabs), `:162` (test_prose) and `:164` (test_schema): a written disposition;
   - `:167`, `:168` and `:169`: *"See the census row, `CLAUDE.md` § Files over the 1500-line cap"*.

   Confirm with a no-bundle run (`tests/_kit/run-automated-tests.sh --suite complexity --no-bundle`, or
   the next full run) that the cells carry forward.
7. [ ] **`LK-19`, `LK-35`, `LK-36`.** Rewrite `docs/releasing.md` step 7:
   - an `ANALYSIS.md` sub-step, plus `test -f <stamp>/ANALYSIS.md` in the hard-precondition block
     (`:141-160`);
   - a `grep -l "\"release\": \"<X.Y.Z>\"" docs/automated-tests/*/manifest.json` precondition that must
     print exactly one path;
   - the release-notes *Release gate … Perf SKIPPED …* template line (model: `CHANGELOG.md:579-581`).

   After this step, `grep -ci analysis docs/releasing.md` must print at least 1.
8. [ ] Commit Sprint 1 as one docs-only change. There is no release and no re-vendor.

**Checkpoint.** After Sprint 1, `LK-17d`, `LK-29`, `LK-33`, `LK-34` and `LK-38` are closed. `LK-19`,
`LK-35` and `LK-36` are closed in procedure, and are verified by the first release that follows it.

## Sprint 2: US-English sweep (`LK-28`, no payload bytes)

9. [ ] Re-run the `03_EVIDENCE.md` §E12 counter to confirm the 210-line, 33-file baseline at the
   then-current HEAD. Re-run it; do not retype the figure.
10. [ ] Sweep `tests/` (151 lines, 23 files). Check each hit for a third-party identifier (see the reason
    in `tests/test_prose.lua:16-18`) before rewriting. Any genuine identifier gets a register row in the
    shape of rows 1 and 2.
11. [ ] Sweep `docs/releasing.md` (10), `README.md` (4), `DEPENDENCIES.md` (1), `tools/artwork/*.py` (19)
    and the five live `docs/api/` documents (25). Leave the quoted "was → is" lines in
    `docs/api/Core/version-7-docs.md:212-214` and their Slash twins as they are, or rephrase them; do not
    rewrite the quoted word into itself. Never touch superseded `docs/api/` versions.
12. [ ] Re-run the counter: the target is 0 outside ratified rows and superseded records. Update register
    row 3's measured figures (`CLAUDE.md:75`), since half of its trigger (the `tests/` sweep) is now met.
    Record whether the row survives on the other half.
13. [ ] Commit.

## Sprint 3: upstream code (kit revision 26, and optionally payload minors), then release

Run this sprint **before** any consumer re-vendor in the current cycle, so consumers take one copy.

14. [ ] **`LK-37`: owner decision.** Choose (b), a register row `events-frames-taint-§1` in `CLAUDE.md`,
    which is recommended and needs no bytes. Or choose (a), the `pcall`ed `safeRegister` helper at
    `LibKa0s/OptionsTabs.lua:102-103,139-140` and `LibKa0s/Widgets.lua:393`, with minors, API docs and
    tests.
15. [ ] **`LK-30`.** In `testkit/run-automated-tests.sh`, make `fn_table()` (`:713`) and `band_table()`
    (`:730`) print the header row for an empty set, and add a self-test. Bump `Kit.VERSION` 25 → 26,
    write `docs/api/testkit/version-26-docs.md`, and regenerate the manifests
    (`lua tools/gen-api-members.lua`). Sync `testkit/` to `tests/_kit/` in the same commit, then confirm
    `diff -r testkit tests/_kit` is empty.
16. [ ] Release by the rewritten step 7 (Sprint 1), in this order:
    - version bump and `CHANGELOG.md` entry;
    - `--release` run on a clean tree;
    - `ANALYSIS.md`, which includes the *Record corrections* paragraph for `LK-32`, `LK-19` and `LK-35`;
    - the *Release gate … Perf SKIPPED* sentence in the entry;
    - the bundle commit;
    - the tag.
17. [ ] Push the branch and the tag only as the owner directs, and do not merge without the owner's
    go-ahead.
18. [ ] Re-vendor the whole `LibKa0s/` payload and `testkit/` into all eleven consumers
    (`docs/releasing.md` step 8), bumping each consumer's `CLAUDE.md` provenance line in the same commit.
    Then run step 9's Consumers-table re-sweep.

## Verification (close-out)

19. [ ] Run `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)' | wc -l` and `luacheck .`. They must
    agree with every prose copy of the lint scope (`CLAUDE.md`, `DEPENDENCIES.md`, `docs/releasing.md`).
20. [ ] In `RESULTS.md`, confirm:
    - no blank Disposition cell in the band table;
    - every over-cap cell points at the census;
    - `### Functions \`lizard\` warned on` renders a header row even when empty.
21. [ ] Confirm the new tag appears as a `release` in exactly one manifest, and that the bundle carries
    `ANALYSIS.md`.
22. [ ] Leave this audit bundle (`docs/audits/2026-09-23/`) frozen. The next audit re-measures.

| Deviation | Step(s) | Changes payload/kit bytes? |
|---|---|---|
| LK-17d | 4, 5, 6 | No |
| LK-19 | 7, 16 | No |
| LK-28 | 9–13 | No (comments/docs/tests; `tools/` is not shipped) |
| LK-29 | 3 | No |
| LK-30 | 15, 18 | **Kit**, re-vendor ×11 |
| LK-32 | 16 | No |
| LK-33 | 6 | No |
| LK-34 | 1 | No |
| LK-35 | 7, 16, 21 | No |
| LK-36 | 7, 16 | No |
| LK-37 | 14 | No under (b); **payload** under (a) |
| LK-38 | 2 | No |
