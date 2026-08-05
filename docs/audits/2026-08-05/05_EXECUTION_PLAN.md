# 05 — Execution plan

Ordered remediation for the fifteen deviations in `02_DEVIATIONS.md`, designed in
`04_TECHNICAL_DESIGN.md`. This is the hand-off to the separate remediation engagement — **this audit
applied none of it.**

**Standing rule for every step:** the green gate (`lua tests/run.lua` 480/480 and `luacheck .` 0/0)
must be clean before each commit (`testing-§4`). Any step touching a `LibKa0s/*.lua` file also bumps
that file's minor, adds its `CHANGELOG.md` line, and enters the re-vendor queue
(`docs/releasing.md:65-80`).

---

## Sprint 1 — Make the suite prove what it claims (LK-09, LK-10)

Cheapest, highest value, and independent of every other sprint. Do it first so later sprints land
against a suite that can fail.

- [ ] **1.1 — LK-10.** Rewrite the four `pcall`/`assertFalse` pairs at
      `tests/test_perf_core.lua:15-23` to `T.assertError` with the library's own message text per
      missing descriptor field. Copy the shape from the adjacent case at `:27`.
- [ ] **1.2 — LK-10.** Re-run the review's mutation to prove the rewrite: `cp LibKa0s/Perf.lua`
      to a backup (**never** `git checkout` — `testing-§12:258-260`), no-op
      `required(d, "name", "string")` at `LibKa0s/Perf.lua:290`, run the suite, confirm it now goes
      **red**, restore from the backup. Add the `-- red under:` comment naming that mutation.
- [ ] **1.3 — LK-10 (sweep).** `grep -n "pcall" tests/*.lua`; convert every other case that asserts
      only *that* it raised. Record the count converted in the commit message.
- [ ] **1.4 — LK-09.** Add the XML-derivation case: parse `LibKa0s/LibKa0s.xml` for `file="…"` in
      document order, publish `tests/run.lua`'s actual load list through `Kit.expose`, assert
      **sequence** equality (not just set) and on-disk existence of every path.
- [ ] **1.5 — LK-09.** Add the suite-list case: shell out for the `tests/` listing the way
      `tests/test_kitsync.lua` does, assert the `test_*.lua` set and `Kit.run`'s `suites` list match
      **both ways**.
- [ ] **1.6 — LK-09.** Prove both cases can fail: add a `<Script file="Extra.lua"/>` line to the XML
      only and confirm red; revert. Add an unlisted `tests/test_zzz_probe.lua` and confirm red;
      delete. Comment each case with its mutation.
- [ ] **1.7 — LK-09.** Regenerate `docs/test-cases.md` (`lua tests/run.lua --list > docs/test-cases.md`)
      — the case count moved.

**Done when:** the two silent failure modes the 2026-08-05 review measured both go red, and
`docs/test-cases.md` is byte-fresh.

---

## Sprint 2 — The root and `docs/` doc set (LK-04, LK-05, LK-11, LK-12, LK-01, LK-02, LK-03)

Order inside the sprint matters: the pointer targets must exist before the stub points at them.

- [ ] **2.1 — LK-05.** Write `docs/ARCHITECTURE.md` (Overview, Module Map with dependency floors,
      descriptor surfaces as pointers into `docs/api/`, the `rawget` `L` seam, persistence pointer,
      taint notes, known limitations, and the N/A sections stated with reasons).
- [ ] **2.2 — LK-04.** Write `docs/testing.md`; **move** the verify material out of
      `README.md:122-159`, leaving a pointer. Update the cross-reference at `docs/releasing.md:17-22`
      in the same commit.
- [ ] **2.3 — LK-12.** Write `docs/smoke-tests.md` (what only a live client can prove for this code;
      point at the consumers' suites) and `docs/performance.md` (what is bracketed, what the harness
      resolves, pointers to `docs/api/Perf/` and `docs/record-schema.md`, and LK-13's gap in one
      line). Leave `docs/perf-runs/` absent — its reason is already recorded at
      `docs/automated-tests/README.md:47-51`.
- [ ] **2.4 — LK-11.** Update `README.md:213-225` — add `automated-tests/` and `audits/`, and the
      three new `docs/` files from 2.1–2.3.
- [ ] **2.5 — LK-01.** Write the root `CLAUDE.md` stub: H1, adherence line,
      `## Standards compliance (read first)` verbatim in substance plus the library-N/A sentence,
      the pointer list (now all live), the green-gate line. Keep it under ~60 lines; it is a stub
      (#26).
- [ ] **2.6 — LK-02.** Add the linked standard badge and adherence line under `README.md:1`.
      Underscore, not `%20`. Note inside `CLAUDE.md` that place 1 (TOC `## X-Standard:`) is
      structurally N/A here, so a future audit reads it as a decision rather than a gap.
- [ ] **2.7 — LK-03.** Write root `DEPENDENCIES.md`: Runtime (none, with the vendored-by-copy
      reason) / Development (`lua5.1` hard + why, `luacheck` via **luarocks**, `lizard` via
      **pipx**, `git`, `bash`, POSIX `ls`) / Release-assets (none, stated explicitly). Every entry
      cites its evidence; every tool gets its verify command; the closing verified-commands section
      points at `docs/testing.md` rather than restating it.

**Done when:** root holds exactly `README.md`, `CLAUDE.md`, `DEPENDENCIES.md` + `LICENSE` (plus
dotfiles), the trio exists under `docs/`, and the standards reference is in both available places.

---

## Sprint 3 — The release process (LK-07, LK-08 docs half, LK-14, LK-15)

- [ ] **3.1 — LK-15.** Add the API-document case to `tests/test_versioning.lua`: for each `MAJORS`
      row, join the live `lib.MODULES` minors **in `files` order** and assert
      `docs/api/<Major>/version-<joined>-docs.md` exists. Verify it reproduces today's five keys
      (`Core/version-4`, `DebugLog/version-7`, `Slash/version-6`, `Options/version-6.6.3`,
      `Perf/version-6.3`) before trusting it. Regenerate `docs/test-cases.md`.
- [ ] **3.2 — LK-15.** With 3.1 landed, `docs/releasing.md:143-146`'s "the same bargain" sentence is
      true — confirm the wording still reads correctly; if 3.1 is deferred, correct the sentence
      instead.
- [ ] **3.3 — LK-07, LK-14.** Insert step **6a** into `docs/releasing.md`'s order of operations:
      clean tree (`git status --porcelain` empty), run
      `tests/_kit/run-automated-tests.sh --release <X.Y.Z>`, commit the bundle **before** the tag.
      State that a `"dirty": true` manifest is not release evidence. Renumber 7→8, 8→9, 9→10 and fix
      the internal reference at `docs/releasing.md:61`.
- [ ] **3.4 — LK-08.** Add the release-gate subsection to `docs/releasing.md`: commit is gated on
      lint + harness only; the **tag** is gated on all four suites at `pass` and
      `suites.complexity.warnings == 0`; a `skip` blocks as NOT EVALUATED; the standing
      no-`tests/perf.lua` exception must be stated in the release notes each time; report every
      failed gate; bump/tag/push nothing when one fails.
- [ ] **3.5 — LK-08.** Change `docs/automated-tests/README.md:29-34`'s two `no — recorded only`
      cells to `no at commit — **yes at the tag**`, and add the release-gate paragraph under the
      table.

**Done when:** a reader of `docs/releasing.md` alone can cut a compliant release, and no document in
the repo says "never gates" without naming the checkpoint.

---

## Sprint 4 — Measure what the library costs (LK-13, then LK-08's exception)

- [ ] **4.1 — LK-13.** Write `tests/perf.lua` with the required zero-overhead scenario: N iterations
      of `P.Open`/`P.Close` with capture **off**, allocation measured with a full collect either
      side, compared against the same loop with the calls absent. Deterministic quantities only —
      **no** wall-clock assertions.
- [ ] **4.2 — LK-13.** Add the on-path scenario so the off/on ratio is a number the repo holds.
- [ ] **4.3 — LK-13.** Correct `LibKa0s/Perf.lua:377-378` to state what 4.1 measured (the review
      measured two function calls plus the boolean test; the allocation half of the claim is
      correct). Bump `Perf.lua`'s minor, add its `CHANGELOG.md` line. **Fold LK-06's `Perf.lua`
      comment spellings into this same edit** so the file bumps once.
- [ ] **4.4 — LK-13.** Confirm `tests/perf.lua` stays **out** of `tests/run.lua`'s suite list
      (`testing-§7`) and that the vendored runner picks it up as the `perf` suite.
- [ ] **4.5 — LK-08.** With `perf` now producing a real result, drop the narrow no-`tests/perf.lua`
      exception from 3.4's wording and from `docs/automated-tests/README.md:38-42`.

**Done when:** the manifest's `perf` reads `pass` rather than `skip`, and the "free when off" claim
is evidence rather than a comment.

---

## Sprint 5 — The spelling sweep (LK-06)

Split so the free half does not wait on a release.

- [ ] **5.1 — free half.** Sweep `README.md`, `docs/releasing.md`, `docs/adoption-prompt.md`,
      `docs/adoption-report.md`, **current** `docs/api/` documents, `tests/*.lua`, `testkit/*.lua`.
      Preserve: `docs/adoption/`, `docs/reviews/`, `docs/superpowers/`, **superseded** `docs/api/`
      documents, and quoted external text in released `CHANGELOG.md` blocks.
- [ ] **5.2 — free half.** If `testkit/` prose changed, that is a kit change: bump `Kit.VERSION`,
      write the kit API document, re-vendor into `tests/_kit/`, let `tests/test_kitsync.lua` confirm,
      and queue the eight consumer re-vendors.
- [ ] **5.3 — free half.** Regenerate `docs/test-cases.md` if any suite or case name changed.
- [ ] **5.4 — release-coupled half.** For each of `LibKa0s/Core.lua`, `DebugLog.lua`, `Slash.lua`,
      `OptionsWidgets.lua` (and `Perf.lua`, already done in 4.3): fix the comment spellings **in the
      next release that already touches that file**, bumping its minor and adding its changelog line
      then. Do **not** manufacture eight minor bumps and eight consumer re-vendors for comment
      spellings alone.
- [ ] **5.5.** Record 5.4's deferral in `CLAUDE.md` as a decision with its reason, so the next audit
      reads it as a decision rather than as an open gap, and add a `grep` to the release order's
      step 1 so the sweep is not forgotten on the release that does touch the file.

**Done when:** the free-half grep returns zero hits outside frozen history and superseded API
documents, and the deferral of the rest is written down.

---

## Sprint 6 — Promote the derivation gate (optional, `library-stack-§7`)

Only after a **second** consumer wants it — the two-consumer bar exists precisely so this does not
happen on frequency alone.

- [ ] **6.1.** Promote Sprint 1's XML parser to `Loader.xmlFiles(path)` in `testkit/loader.lua`,
      beside `Loader.tocFiles`. Every consumer's runner spells the library's files out by hand
      (`testing-§9:151-153`) and has the same gap, so this is a genuine shared shape with the same
      semantics — not a shape flag would have to configure (`library-stack-§7`'s three bars).
- [ ] **6.2.** Bump `Kit.VERSION`, write the kit API document under `docs/api/testkit/`, re-vendor
      into `tests/_kit/`, confirm via `tests/test_kitsync.lua`, queue the consumer re-vendors.
- [ ] **6.3.** Rewrite this repo's local version to consume the promoted helper.

---

## Not scheduled

- **`docs/perf-runs/README.md`** — deliberately absent; the reason is recorded and stands.
- **Review findings F-005 / F-006** (`P.Close(t0)` with no key raising on the on-path; `P.Cancel`
  leaving `P.context` set) — real defects, but no MUST/SHOULD covers them. They belong to the
  review's own execution plan at `docs/reviews/2026-08-05/04_EXECUTION_PLAN.md`, not to this audit.
- **The `RESULTS.md` banner sentence (LK-08's generated half)** — designed in
  `04_TECHNICAL_DESIGN.md` Group 3 but deliberately unscheduled here: it changes the banner in eight
  repos on their next run, so it wants its own decision rather than a checkbox inside a doc sprint.
  Schedule it with 6.2's re-vendor wave if that happens; otherwise as a standalone kit release.

---

## Re-audit trigger

Re-run `/wow-addon:standards-audit` after Sprint 3, into `docs/audits/<new date>/` — never by editing
this folder. Ten of the fifteen deviations close in Sprints 1–3; the re-audit measures that and
re-checks the complexity drift and the `diff -r testkit tests/_kit` from a clean tree.
</content>
