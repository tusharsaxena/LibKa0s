# 04 — Execution plan

Six milestones. M0 is upstream and blocks only M5. M1 is the only milestone with user-visible
runtime impact and goes first.

---

## M0 — Upstream: the standard catches up to the library

**Repo: `tusharsaxena/WowAddonStandards`. No commit lands in LibKa0s in this milestone.**

| Task | Role | Findings | Files |
|---|---|---|---|
| T0.1 | standards-editor | F-014 (U-1) | `standards/standards/library-stack.md` (§7 table, `:70`), `standards/STANDARDS.md:57`, `standards/standards/open-evolutions.md:13` |
| T0.2 | standards-editor | F-015 (U-2) | `standards/standards/library-stack.md:175-226` |
| T0.3 | standards-editor | — | `standards/STANDARDS.md` version + dated changelog entry covering both |

T0.1 and T0.2 touch the same file and **must serialize**. Do them as one upstream pass: if C-8 later
peels `OptionsWidgets.lua`, U-1's file count changes again, so settle the applicability question
(T0.2) before publishing the count (T0.1).

**Done when:** the standard names fourteen files including `OptionsScroll`, its applicability
classification covers all 26 sections, and it states whether `layout`'s 1500-LOC cap binds a library's
ship folder. The version at the top of `STANDARDS.md` has moved.

**Exit criterion in LibKa0s:** none. This milestone produces no commit here. Its consumption in this
repo is **T5.1** (the pointer bump) and **M5** (the C-8 decision) — never folded into a task that
edits this repo's own files.

---

## M1 — Stop the frame leak

| Task | Role | Findings / Changes | Files |
|---|---|---|---|
| T1.1 | lua-refactorer | C-1 (F-001) — split `makeTab` into `newTabButton` + `dressTab`; make `drawContentPanel` build-once/re-anchor | `LibKa0s/OptionsWidgets.lua` |
| T1.2 | lua-refactorer | C-1 — route both through `LibKa0s-Pool-1.0`, per-`ctx` pools, attic reparent in the `before` hook | `LibKa0s/OptionsWidgets.lua` |
| T1.3 | test-author | C-1 — four new cases (reuse count, current-`onSelect`, atlas on re-dress, no cross-`ctx` sharing) | `tests/test_options_widgets.lua` |
| T1.4 | release-scribe | C-1 — `WIDGETS_MINOR` 13→14, changelog version block, new `docs/api/Options/version-14.14.2.3-docs.md`, regenerate `docs/test-cases.md` | `LibKa0s/OptionsWidgets.lua`, `CHANGELOG.md`, `docs/api/`, `docs/test-cases.md` |

**Test-first.** T1.3 is written **before** T1.1/T1.2 and must go **red** first — the reuse-count case
fails against today's code by construction. A green new case before the refactor means the case cannot
fail and is worthless.

**Serialization.** T1.1 → T1.2 → T1.4 all touch `LibKa0s/OptionsWidgets.lua` and **must serialize**.
T1.3 touches only `tests/test_options_widgets.lua` and is written first, then re-run after each of
T1.1 and T1.2.

**Done when:** `lua5.1 tests/run.lua` green at ~768; `luacheck .` 0/0; `docs/test-cases.md`
regenerated in the same commit; smoke tests C-1, C-1b, C-1c, C-1d and T-1 pass in a consumer.

### CHECKPOINT 1 — human verification before anything else moves

The leak fix is the only change with runtime impact and the only one that touches a surface
`options-ui-§13` makes mandatory in nine addons. Verify **in the client** (`03_SMOKE_TESTS.md` C-1
through C-1d, plus T-1 for taint) before starting M2. A pooled widget that reuses stale state is the
failure mode here, and it is not visible headlessly.

---

## M2 — One pool, one release contract

| Task | Role | Findings / Changes | Files |
|---|---|---|---|
| T2.1 | lua-refactorer | C-2 (F-005) — migrate `handlePool`/`boxPool`/`reclaim` onto `LibKa0s-Pool-1.0`; `__row` clear and attic reparent move into the `before` hook | `LibKa0s/Widgets.lua` |
| T2.2 | release-scribe | C-2 — `Widgets` `MINOR` 9→10, changelog block, `docs/api/Widgets/version-10-docs.md` | `LibKa0s/Widgets.lua`, `CHANGELOG.md`, `docs/api/` |

**Parallelizable with M3 and M4** — disjoint file sets (`LibKa0s/Widgets.lua` vs. `tests/test_eol.lua`
+ `.luacheckrc` vs. `LibKa0s/Options.lua`).

**Serialization within:** T2.1 → T2.2, same file.

**Regression gate:** the existing `tests/test_widgets.lua` Cancel/reclaim cases must stay green
**unchanged**. Do not edit them to accommodate the migration — a red there means the `before` hook is
missing a step, which is exactly what those cases are for.

**Done when:** suite green at the M1 count (no new cases owed — the behaviour is unchanged); smoke
test C-2 passes.

---

## M3 — Widen the two narrow gates

| Task | Role | Findings / Changes | Files |
|---|---|---|---|
| T3.1 | test-author | C-4 (F-004) — drop `BUNDLES`, rename the case, widen to the whole tracked set | `tests/test_eol.lua` |
| T3.2 | repo-hygiene | C-4 — repair the seven LF stragglers (`rm` + `git checkout --`) | `LibKa0s/DebugLog.lua`, `LibKa0s/Pool.lua`, `tests/test_debuglog.lua`, `tests/test_pool.lua`, `docs/api/Options/version-8.7.3-docs.md`, `docs/api/Options/version-9.7.3-docs.md`, `docs/api/testkit/version-12-docs.md` |
| T3.3 | lint-owner | C-5 (F-009) — narrow `exclude_files` to `tests/_kit/`; add a `files["tests/"]` stanza for `LK_TEST` | `.luacheckrc` |
| T3.4 | lua-refactorer | C-5 — clear whatever the newly-linted suites warn on | `tests/*.lua` |
| T3.5 | release-scribe | C-4 — regenerate `docs/test-cases.md` (the case **renamed**, so the inventory moves even though the count does not) | `docs/test-cases.md` |

**Order.** T3.1 must land **before** T3.2 and go red on exactly seven files — that red is the
evidence the widened gate works. Repairing first and then widening produces a green gate with no
proof it can fail.

**Note on T3.2:** two of the seven are `LibKa0s/DebugLog.lua` and `LibKa0s/Pool.lua`, whose *bytes*
change (LF → CRLF) while their content does not. This is **not** a released change to either file and
**must not** bump either minor — a terminator is not a code change, and a spurious minor bump would
make LibStub prefer a copy that differs from its predecessor in nothing. State that in the commit
message.

**Serialization.** T3.1 → T3.2 → T3.5 (all gated by the same test). T3.3 → T3.4 (`.luacheckrc` before
the fixes it surfaces). The two chains touch disjoint files and are **parallelizable** with each other
and with M2 and M4 — except that T3.4 edits `tests/*.lua`, which **collides with T1.3 and with M4's
test tasks**. Sequence T3.4 after M1 is closed and after M4's test edits, or serialize it last.

**Done when:** `test_eol` is green over the whole tracked tree with `git ls-files --eol | grep "w/lf"`
showing only the two `.sh` files; `luacheck .` 0/0 over ~40 files.

### CHECKPOINT 2 — before M4

Confirm the widened `test_eol` went red and was seen to go red. A gate that was green the first time
it ran wide is a gate that is still narrow somewhere.

---

## M4 — One diagnostic policy

| Task | Role | Findings / Changes | Files |
|---|---|---|---|
| T4.1 | lua-refactorer | C-6 (F-006) — `lib:New` stores `O.__print`; `__AttachWidgets` reads it instead of re-deriving from `d` | `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua` |
| T4.2 | lua-refactorer | C-7 (F-008) — `lib.STRINGS.DEAD_BUTTON`; `makeBtn` reports at build time | `LibKa0s/Options.lua`, `LibKa0s/OptionsWidgets.lua` |
| T4.3 | test-author | C-6, C-7 — a widget-layer diagnostic reaches `DEFAULT_CHAT_FRAME` with no descriptor `print`; a handler-less composed button is reported | `tests/test_options_widgets.lua`, `tests/test_options_compose.lua` |
| T4.4 | perf-owner | C-10 (F-007) — free-list the `Open` slot; docstring the active-arm cost; `docs/record-schema.md` note | `LibKa0s/Perf.lua`, `docs/record-schema.md` |
| T4.5 | test-author | C-10 — an **active**-arm allocation case beside the existing dormant one | `tests/test_perf_isolation.lua` |
| T4.6 | release-scribe | Minors: `Options` 14→15, `OptionsWidgets` 14→15, `Perf` 7→8; changelog block; new API docs; regenerate `docs/test-cases.md` | `CHANGELOG.md`, `docs/api/`, `docs/test-cases.md` |

**Dependency.** T4.2 **depends on** T4.1 — without one printer per instance, the new `DEAD_BUTTON`
line is swallowed for exactly the sloppily-wired host it is written for, and the change would ship
doing nothing.

**Serialization.** T4.1 → T4.2 → T4.6, all touching `LibKa0s/Options.lua` and
`LibKa0s/OptionsWidgets.lua`. **These files also collide with M1** — M4 must not start until M1 is
closed and Checkpoint 1 has passed. T4.4/T4.5 touch `LibKa0s/Perf.lua` and
`tests/test_perf_isolation.lua` only and are **parallelizable** with T4.1-T4.3.

**Done when:** suite green at ~772; smoke tests C-6, C-7 pass; the active-arm perf case is green with
a stated bound and was seen red before T4.4.

---

## M5 — The 1838-line file

**Blocked on M0/T0.2.** Do not start until the standard says whether `layout`'s cap binds here.

| Task | Role | Findings / Changes | Files |
|---|---|---|---|
| T5.1 | docs-owner | C-9 (F-010) — bump the standards pointer to the version M0 published | `CLAUDE.md:3`, `README.md:3` |
| T5.2 | docs-owner | C-9 (F-011) — one comment naming what holds the suite list honest | `tests/run.lua:112` |
| T5.3a | *(if the cap binds)* lua-refactorer | C-8 (F-015) — peel the chrome block into `LibKa0s/OptionsChrome.lua` with `__chromeMinor`/`__chromeShellMinor`; add the `<Script>` line and the `MAJORS` row | `LibKa0s/OptionsWidgets.lua`, `LibKa0s/OptionsChrome.lua`, `LibKa0s/LibKa0s.xml`, `tests/run.lua` |
| T5.3b | *(if it does not)* docs-owner | C-8 — a ratified row in `## Documented deviations` citing this review | `CLAUDE.md` |

**T5.3a is large and risky.** It changes the file count the standard just published (U-1 lands at
fifteen), adds a fifth Options file with a new probe-minor pair, and moves ~690 lines. If it runs, it
gets its own checkpoint and its own release. It touches `LibKa0s/OptionsWidgets.lua`, so it **must
serialize after M1 and M4**.

T5.1 and T5.2 are **parallelizable** with everything — disjoint, doc-only.

**Done when:** the pointers are current and either the file is under 1500 or a deviation row exists
with a rule reference, an owner and a re-check trigger.

---

## M6 — Release, and the evidence that goes with it

Runs last, once every code milestone is closed. This is the **only** milestone that regenerates
anything into the repo.

| Task | Role | Findings / Changes | Files |
|---|---|---|---|
| T6.1 | release-scribe | Clean tree, then the full four-suite battery, frozen as `docs/automated-tests/<stamp>/` | `docs/automated-tests/` |
| T6.2 | release-scribe | C-3 (F-002, F-003) — reduce `RESULTS.md` to header + reading rules + table; move the four narrative sections into that run's `ANALYSIS.md`, corrected against the fresh numbers, with a refreshed watch list naming the real ceiling | `docs/automated-tests/RESULTS.md`, `docs/automated-tests/<stamp>/ANALYSIS.md` |
| T6.3 | kit-owner | C-9 (F-013) — Version cell renders `<version> → <release>`; `Kit.VERSION` 14→15; `docs/api/testkit/version-15-docs.md` | `testkit/run-automated-tests.sh`, `testkit/framework.lua` |
| T6.4 | kit-owner | C-9 — **re-vendor `testkit/` → `tests/_kit/` as a whole folder**, its own commit | `tests/_kit/` |
| T6.5 | release-scribe | C-3 (F-012) — `docs/releasing.md` requires a **clean tree** for the release battery | `docs/releasing.md` |
| T6.6 | release-scribe | Semver tag; the provenance line every consumer's `test_vendor_sync.lua` resolves | `CHANGELOG.md`, git tag |

**T6.4 is a copy, never an edit.** `tests/_kit/` is this repo's own vendored copy of `testkit/` and is
held byte-identical by `tests/test_kitsync.lua`. Editing it directly is the fork the standard forbids
even though both halves live here.

**Serialization.** T6.3 → T6.4 (the copy follows the source). T6.5 before T6.1 (so the battery runs
under the new clean-tree rule). T6.1 → T6.2 (the bundle must exist before its analysis).
T6.6 last, and only after both payloads are final — a provenance line ahead of its tag is the failure
`docs/releasing.md:161-170` describes.

### CHECKPOINT 3 — before the tag

Verify by hand that `RESULTS.md`'s newly-generated row and the fresh `complexity.txt` agree with the
`ANALYSIS.md` written beside them, and that the banner's "generated, never hand-edited" is now true of
everything left in the file. F-002 exists because that claim was false; shipping it still false would
be the same defect with a new date on it.

---

## Concurrency map

```
M0 (upstream, no LibKa0s commit) ─────────────────────────────┐
                                                              │
M1 (OptionsWidgets.lua) ── CHECKPOINT 1 ──┬── M2 (Widgets.lua)         [parallel]
                                          ├── M3 (test_eol, .luacheckrc) [parallel]
                                          └── M4 (Options*, Perf)        [after M1]
                                                              │
                                          CHECKPOINT 2 ───────┤
                                                              ▼
                                              M5 (needs M0 + M1 + M4)
                                                              ▼
                                              M6 ── CHECKPOINT 3 ── tag
```

**Must serialize — shared files:**

| File | Tasks | Why |
|---|---|---|
| `LibKa0s/OptionsWidgets.lua` | T1.1, T1.2, T1.4, T4.1, T4.2, T5.3a | Five tasks, one file. This is the critical path. |
| `LibKa0s/Options.lua` | T4.1, T4.2 | Same body (`lib:New`) |
| `tests/test_options_widgets.lua` | T1.3, T4.3, T3.4 | T3.4's lint fixes must land after both test-authoring tasks |
| `docs/test-cases.md` | T1.4, T3.5, T4.6, T6.1 | Regenerated, never merged — each run overwrites |
| `CHANGELOG.md` | T1.4, T2.2, T4.6, T6.6 | One version block per release; if M1-M4 ship as one release, this is one edit, not four |
| `LibKa0s/LibKa0s.xml`, `tests/run.lua` | T5.3a, T5.2 | Only if the peel runs |

**Genuinely parallelizable (disjoint):** T2.1/T2.2 · T3.1/T3.2 · T3.3 · T4.4/T4.5 · T5.1/T5.2.

**Critical path:** T1.3 → T1.1 → T1.2 → T1.4 → *Checkpoint 1* → T4.1 → T4.2 → T4.6 → (T5.3a) → T6.1 →
T6.2 → T6.6.

---

## Commit strategy

One commit per task, except where a minor bump and its API document must land with the code that
earned them — those go in the same commit as the code (`docs/releasing.md`).

```
fix(options): pool the tab strip's buttons and content panel      [T1.1-T1.4, F-001]
refactor(widgets): reorder-list pools move onto LibKa0s-Pool-1.0   [T2.1-T2.2, F-005]
test(eol): the gate covers the tracked tree, not one directory     [T3.1, F-004]
fix(eol): seven files land CRLF, as .gitattributes has always said [T3.2, F-004]
chore(lint): luacheck reads the test tree too                      [T3.3-T3.4, F-009]
fix(options): one printer per instance, and it never swallows      [T4.1, F-006]
fix(options): a composed button with no handler says so            [T4.2, F-008]
perf(perf): Open reuses its slot instead of allocating one         [T4.4-T4.5, F-007]
docs: the standards pointer, and what holds the suite list honest  [T5.1-T5.2, F-010, F-011]
docs(automated-tests): the record says what the runner measured    [T6.2, F-002, F-003]
testkit: revision 15 — the Version cell names the release          [T6.3]
testkit: re-vendor testkit/ into tests/_kit/                       [T6.4]
LibKa0s v1.26.0: <headline>                                        [T6.6]
```

Two rules that are not negotiable:

- **The re-vendor (T6.4) is its own commit** and contains nothing but the folder copy.
- **No commit lands with a red suite or a non-zero lint.** `lua5.1 tests/run.lua && luacheck .` is the
  gate before every one of them, and T3.1's deliberate red is resolved by T3.2 inside the same
  working session — it is a red that is *seen*, not a red that is *committed*.
