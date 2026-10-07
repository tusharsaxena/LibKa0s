# 05 — Execution plan

The hand-off to the remediation engagement. Every step is keyed to a deviation ID in
`02_DEVIATIONS.md`. Seven roots, no dependents: Low 6, Info 1, with 6 MUST failures. Six register rows
are accepted and are not in this plan.

## Sprint 1 — documents and records (no release, no payload bytes)

1. [ ] **`LK-42`.** In `CLAUDE.md`, change the three citations:
   - `:75` `LibKa0s-A-07` → `LK-28`
   - `:77` `LibKa0s-A-10` → `LK-37`
   - `:335` `LibKa0s-A-03` → `LK-17d`

   Then qualify or replace the cross-repo plan items `LK-29` (`:75`) and `LK-30` (`:77`, Decided column)
   with their bundle path or the commit sha. Edit no frozen record.
2. [ ] **`LK-28`.** Sweep `docs/adoption-prompt.md` (18 lines) and `docs/adoption-report.md` (4 lines)
   to US English, using the lines in `03_EVIDENCE.md` §E7. In the same change:
   - extend `tests/test_prose.lua`'s live-doc case to read both files;
   - strike *"21 in `docs/adoption-prompt.md`"* from register row 3's record list (`CLAUDE.md:75`).

   Verify with `lua tests/run.lua` (green, with the case now covering both files).
3. [ ] **`LK-29`.** Remove the derived headroom figure, or correct it to 42, at `CLAUDE.md:219` and in
   the authored Disposition cell at `docs/automated-tests/RESULTS.md:193`.
4. [ ] **`LK-17d`.** Open five `state:triaged` / `severity:low` issues, spacing the creates out:
   `LibKa0s/OptionsWidgets.lua`, `LibKa0s/OptionsIds.lua`, `LibKa0s/OptionsIdList.lua`,
   `LibKa0s/OptionsTabs.lua` and `LibKa0s/Options.lua`. Each names its seam and its re-check trigger
   (`04_TECHNICAL_DESIGN.md` § `LK-17d`).
   - Rewrite the five Disposition cells (`RESULTS.md:188-192`) to *already tracked as [#NN]*.
   - Point `CLAUDE.md`'s band rulings at the issues.
   - Alternatively, the owner rules a peel for any file, which moves that file to its own release cycle.
5. [ ] **Gate.** Run `lua tests/run.lua` (0 failed) and `luacheck .` (0/0), both through `ka0s-bounded`.
   Commit Sprint 1 as `LK-42 + LK-28 + LK-29 + LK-17d: …`, or one commit per ID.

**Checkpoint after Sprint 1:** `LK-17d`, `LK-28`, `LK-29` and `LK-42` are closed.

## Sprint 2 — issue store

6. [ ] **`LK-40`.** Run `gh issue edit <n> --remove-label state:triaged --add-label state:done` for #32,
   #33, #37 and #39, spacing the calls out.
   - Verify that `gh issue list --state closed --label state:triaged --json number` returns `[]`.
   - Record it in `exceptions.tsv` with that command, since no commit carries it.

## Sprint 3 — payload release (owner precondition first)

7. [ ] **`LK-39`, precondition.** The owner runs `/dump GetAddOnMetadata, IsAddOnLoaded` in the live
   retail client and records the output.
8. [ ] **`LK-39`, branch 1** (a global is nil):
   - delete the dead rung or rungs (`LibKa0s/Env.lua:64-66`, `LibKa0s/OptionsIdList.lua:485`);
   - rewrite `Env.lua:52-55`;
   - bump Env to minor 2 and/or OptionsIdList to minor 4;
   - replace `tests/test_env.lua:31`;
   - drop the matching `.luacheckrc:8-9` read-globals.

   **Branch 2** (both present): file the `compat` worked-case correction upstream, and add a register
   row here instead.
9. [ ] **`LK-41`.** In the same release, change `LibKa0s/Slash.lua:267` to `(slash-commands-§1)`, bump
   the Slash shell to minor 20 and close #43 `state:done`.
10. [ ] **Release** per `docs/releasing.md`:
    - CHANGELOG version block, with the perf-skip sentence;
    - API documents, then `lua tools/gen-api-members.lua`;
    - the release run (`tests/_kit/run-automated-tests.sh --release <X.Y.Z>`);
    - `ANALYSIS.md`, noting the `LK-17d` conversion and that the 2026-10-07 audit's `LK-42` corrected the
      register citations;
    - the tag, which needs the owner's go-ahead.

    Then re-vendor all eleven consumers (`/dev-copilot:wow-revendor-libka0s`), each carrying its
    provenance line in the same commit.

**Checkpoint after Sprint 3:** `LK-39` and `LK-41` are closed. Every consumer's `diff -r` against the
new tag is empty.

## Upstream (WowAddonStandards), for the consolidated plan

11. [ ] **U1.** `library-stack-§7`: cite the Options→Pool floor by symbol and name `OptionsNav.lua`.
12. [ ] **U2.** `compat`: correct or confirm the `GetAddOnMetadata` worked case, depending on step 7.
13. [ ] **U3.** `library-stack-§7`: classify, or stop claiming as exhaustive, the subsections no list
    names.

## Traceability

| ID | Steps | Touches payload? | Release? |
|---|---|---|---|
| LK-42 | 1 | No | No |
| LK-28 | 2 | No | No |
| LK-29 | 3 | No | No |
| LK-17d | 4 | No (or a peel, by owner ruling) | No |
| LK-40 | 6 | No (issue store) | No |
| LK-39 | 7, 8, 10 | **Yes** (Env, OptionsIdList) | **Yes**, re-vendor ×11 |
| LK-41 | 9, 10 | **Yes** (Slash) | Rides on the `LK-39` release |
