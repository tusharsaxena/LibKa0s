# 05 — Execution plan

Hand-off for the separate remediation engagement. Seven roots and one dependent, keyed to
`02_DEVIATIONS.md` and designed in `04_TECHNICAL_DESIGN.md`. Nothing here is High or Medium, so
nothing here is urgent — the ordering below is about **cost**, not about risk.

**Read the counts the same way `02_DEVIATIONS.md` states them:** headline tally **7 roots**, total
**8 including the one dependent**, MUST failures **7 roots / 8 including the dependent**. The
step-to-deviation map at the end accounts for all eight, once each.

**Two hard rules for this work.**

- `docs/automated-tests/RESULTS.md` is **generated**. The only cell anyone may edit by hand is the
  watch list's `Disposition` (Step 4). Every other figure in it is fixed by fixing the runner.
- Frozen bundles are never edited. `LK-32` is corrected forward, in the next run's write-up, and no
  file under `docs/automated-tests/2026*/` is touched by any step below.

---

## Sprint 1 — the record catches up with the code (no release, no re-vendor)

Four steps, all documents and one issue, none of them touching the payload or the kit. This sprint
can land on `master` in an afternoon and closes **four of the seven roots**.

### Step 1 — `docs/releasing.md` gains the `ANALYSIS.md` sub-step · `LK-19`

1. Insert sub-step 7c between the `--release` run and the tag preconditions in
   `docs/releasing.md` step 7: write `docs/automated-tests/<stamp>/ANALYSIS.md` from the root
   `AUTOMATED_TESTS.md` prompt, linking each suite's artifact and reporting complexity with totals
   **and** averages.
2. Add `test -f "docs/automated-tests/<stamp>/ANALYSIS.md"` to the hard-precondition block at
   `docs/releasing.md:134-153`, beside the five `jq` reads, so the tag is gated on the file.
3. Do **not** backfill any of the 19 bundles that carry none.

- **Check:** `grep -ci analysis docs/releasing.md` is non-zero (it is `0` today, `03_EVIDENCE.md`
  E7); the precondition block names the file.
- **Done when:** the next release bundle carries an `ANALYSIS.md` written at the run.

### Step 2 — the two lint-scope sentences · `LK-29`

1. `CLAUDE.md:176-179` — 51 files, `exclude_files = { "tests/_kit/" }`, and the real reason (the kit
   is a byte copy of `testkit/`, linted here as source).
2. `DEPENDENCIES.md:120` — `# 0 warnings / 0 errors, in 51 files`.
3. `DEPENDENCIES.md:125-127` — delete *"`tests/` and `docs/` are excluded"*, which is false against
   `.luacheckrc:4` and against the `files["tests/"]` stanza at `:57-59`.
4. Preferred structural fix: stop quoting the figure in either document and point at
   `RESULTS.md`'s generated sentence, which already has a producer.

- **Check:** `grep -rn '18 files\|eighteen' CLAUDE.md DEPENDENCIES.md` is empty; no document
  contradicts `.luacheckrc:4`.

### Step 3 — the expired watch-list disposition · `LK-17d`

1. Open one issue: `tests/test_options.lua` in the 1000–1500 band, `state:triaged`,
   `severity:low`, owner `@tusharsaxena`. Body carries what `RESULTS.md:110` already knows — crossed
   at `20260807-151331` by one line, seam is the render/refresh block out to
   `tests/test_options_render.lua`, hard trigger `crosses 1500 → split`.
2. Replace the `Disposition` cell at `RESULTS.md:110` with *"Already tracked as `#NN`"* plus the
   seam in one sentence. **This is the one sanctioned hand edit in this plan**
   (`automated-tests-§4`, *the one boundary*).

- **Check:** no cell in the watch list reads *owed* or *accepted* without an issue link or a date
  from this cycle; `gh issue list --label "state:triaged"` returns the new issue.
- **Why now:** 25 release runs against anti-pattern #53's cap of 3 (`03_EVIDENCE.md` E6).

### Step 4 — the US English sweep, gate first · `LK-28d` then `LK-28`

1. **Widen the prose gate** (`tests/test_prose.lua`). Keep the payload scan exactly as it is; add a
   second scan over authored text, sourced from `git ls-files` rather than a second directory
   walker, with `localization-§5`'s exclusions named path by path: `tests/_kit/`, `docs/audits/`,
   `docs/reviews/`, `docs/adoption/`, `docs/superpowers/`, `docs/automated-tests/<stamp>/`,
   `CHANGELOG.md`, and `tests/test_prose.lua` itself.
2. **Scope `docs/api/` to the live document per major**, resolved from the `MODULES` registry the
   versioning suite already reads. The 48 superseded documents are a per-version record and stay as
   written.
3. Run the suite. It goes **red with roughly 216 hits across 33 files**; that list is the worklist.
4. Sweep, applying `localization-§5`'s exceptions: Blizzard and third-party symbols verbatim, quoted
   external text unchanged.
5. Green.

- **Check:** the suite is green; a re-run of `03_EVIDENCE.md` E8's sweep returns 0 for every live
  bucket; `LibKa0s/` and `testkit/` stay at 0.
- **If `tests/` is deliberately excluded instead:** that is a `## Documented deviations` row in
  `CLAUDE.md` citing `localization-§5` with a re-check trigger — not a comment in the gate. The
  reason currently sits at `tests/test_prose.lua:16-18` and nowhere else, which is the state
  `library-stack-§7` says is not ratified.
- **Order matters:** doing the sweep first and the gate second means the 34th file arrives on the
  next commit and nothing notices.

---

## Sprint 2 — the payload and the kit (one release, one re-vendor wave)

Two steps, both of which move bytes that nine consumers vendor. `library-stack-§7` makes either one
a re-vendor trigger, so they land together under one tag or they wait for the next tag being cut for
another reason. **Do not schedule this sprint on its own account** — neither item is reachable by a
user, and a re-vendor wave for two Low findings is a poor trade.

### Step 5 — one owner for the deprecated-API shims · `LK-31`

1. Choose the placement, and write the choice down:
   - **Recommended:** promote the spec reader into `LibKa0s/Core.lua`, which nine of the ten majors
     already floor on, so **no new inter-module edge and no floor moves**. Comment the deliberate
     duplication at both copies if `Env.lua` keeps one (`library-stack-§7`).
   - **Alternative:** put it in `LibKa0s/Env.lua` beside `lib.GetAddOnMetadata` and give `Perf` a
     declared minor floor on `LibKa0s-Env-1.0`, `return`ing before `NewLibrary` when unmet. This is
     a second inter-module edge and a **re-vendor trigger that MUST be called out in the changelog**.
2. Collapse `LibKa0s/Perf.lua:656-664` to a single call, preserving the `"?"` default exactly.
3. Bump the minor on every file that changed; add the `docs/api/` entry for each.
   `tests/test_versioning.lua` refuses the commit until both are done.
4. If the current split is instead judged correct: a `## Documented deviations` row citing `compat`
   with a re-check trigger at a third shim site. One of the two, not neither.

- **Check:** `03_EVIDENCE.md` E11's grep shows one owner; `tests/test_perf_core.lua:583` and `:599`
  stay green unchanged; full suite green.

### Step 6 — the watch list's empty table · `LK-30`

1. `testkit/run-automated-tests.sh` — in `fn_table()` (`:556`) and `band_table()` (`:573`), move the
   header `printf` above the emptiness guard and delete the `None.` branch.
2. Confirm the disposition parser (`PRIOR_FN`, `PRIOR_BAND`) round-trips a header-only table and
   does not read a bare header as a malformed row.
3. Add a kit-suite case for the empty-set rendering — no consumer can fix this shape locally.
4. `Kit.VERSION` 15 → 16, an API document under `docs/api/testkit/`, re-sync `tests/_kit/`
   (`tests/test_kitsync.lua` enforces byte identity).

- **Check:** a fresh run emits `| Function | CCN | Location | Disposition |` with no data rows, and
  **all 34 existing table rows survive** — `automated-tests-§4` forbids dropping a row.

### Step 7 — the release, and the wave

Only if Sprint 2 ran. `docs/releasing.md` steps 1–7 including the new 7c from Step 1; then re-vendor
`libs/LibKa0s/` and `tests/_kit/` into all nine consumers, moving each one's
`Bundles [LibKa0s](…) vX.Y.Z (MIT).` line in root `CLAUDE.md` in the **same commit** as the bytes.

- **Check:** every consumer's `tests/test_vendor_sync.lua` green against the new tag.

---

## Carried forward, not scheduled

### `LK-32` — the next run's `ANALYSIS.md` corrects the figure

Not a step in this plan, because §5 forbids editing the frozen bundle. Whoever writes the next
`ANALYSIS.md` adds one sentence: `20260908-181447:92`'s *"Twenty … carry no `ANALYSIS.md`"* was one
high, the measured count was nineteen — which is what `:93` says in the same paragraph — and states
today's count. Worth raising upstream at the same time: `AUTOMATED_TESTS.md`'s prompt should ask for
that figure as a command's output rather than as a count, and the slip stops being possible.

---

## Step → deviation map

| Step | Deviations | Sprint | Blast radius |
|---|---|---|---|
| 1 | `LK-19` | 1 | one document |
| 2 | `LK-29` | 1 | two documents |
| 3 | `LK-17d` | 1 | one issue, one authored cell |
| 4 | `LK-28d`, `LK-28` | 1 | one gate, 33 files of prose |
| 5 | `LK-31` | 2 | payload; two minors; re-vendor |
| 6 | `LK-30` | 2 | kit; `Kit.VERSION`; re-vendor ×9 |
| 7 | *(none — the release that carries 5 and 6)* | 2 | ten repos |
| — | `LK-32` | carried | none |

All eight entries appear exactly once. **Sprint 1 closes 4 roots and 1 dependent; Sprint 2 closes
2 roots; 1 root (`LK-32`) closes forward at the next run.**

## What this plan deliberately does not do

- **No file is peeled.** `tests/test_options_widgets.lua` (2398) and `LibKa0s/OptionsWidgets.lua`
  (1989) are over the cap and are in a terminal compliant state — issues #8 and #16 plus the census
  at `CLAUDE.md:102-105`, gated by `tests/test_layout_cap.lua`. `layout-§1` says an audit **MUST
  NOT** re-file against them, and this plan takes that at face value. `tests/test_widgets.lua` at
  1493 is seven lines from breach and wants an issue **before** it crosses; that belongs to whoever
  next adds a case to it, not to this bundle.
- **No frozen bundle gains a file, and none loses one.** Nineteen bundles will never have an
  `ANALYSIS.md`.
- **No superseded `docs/api/` document is rewritten** for spelling. They are the record of what a
  released minor said.
- **No release is cut for its own sake.** Sprint 2 rides a tag that is happening anyway.
