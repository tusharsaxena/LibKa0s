# 04 — Technical design

All twelve roots are Low or Info, and none touches a user-reachable path. The remediation splits into
four independent tracks. Only **Track C** (the kit emitter, `LK-30`) and **Track D**'s option (a)
(`LK-37`) change payload or kit bytes. Those two force a release and a re-vendor into the eleven
consumers. Everything else is documentation, records or the release procedure, and ships in a docs-only
commit.

**Ordering constraint for the wider sweep.** This repo is upstream of the eleven consumers. If Track C
(or D(a)) lands, it must land and be tagged **before** any consumer re-vendors in this cycle, so the
consumers take one re-vendor, not two. Tracks A and B change nothing a consumer copies, so they can land
at any time.

---

## Track A: the release procedure (`LK-19`, `LK-35`, `LK-36`, `LK-32`)

**Root cause.** `docs/releasing.md` step 7 describes the release run and the manifest preconditions
(`:141-160`). Three things the standard requires at a release are not written into it, or are written as
prose with no check behind them:

- the `ANALYSIS.md` (`automated-tests-§5`);
- a bundle for the tag being cut (`automated-tests-§6`), stated at `:157` but unchecked;
- the perf-skip sentence in the release notes (`automated-tests-§3`).

Releases went out at a rate of up to two within five minutes (v1.54.1 and v1.54.2), and the unchecked
steps fell away.

**Design.** Turn step 7's precondition block into a checklist that fails loudly, with four additions:

1. **Bundle exists for the tag (`LK-35`).**
   `grep -l "\"release\": \"<X.Y.Z>\"" docs/automated-tests/*/manifest.json` must print exactly one path.
   A mechanical owner is optional but cheap: a `tests/test_versioning.lua` case asserting that the
   `CHANGELOG.md`'s top `## vX.Y.Z` heading appears as a `release` in some manifest. It would be red
   between the version bump and the release run, so either scope it to run only under `--release`, or
   keep it as a step rather than a case.
   **Decision needed:** a step or a test. The design recommends the step, plus a *post-tag* check in the
   next run's `ANALYSIS.md`.
2. **`ANALYSIS.md` written (`LK-19`).** A numbered sub-step between the release run and the tag: write
   `<stamp>/ANALYSIS.md` per the `AUTOMATED_TESTS.md` prompt. Then `test -f <stamp>/ANALYSIS.md` goes
   into the hard preconditions. The two-commit order at `:124-126` already places the bundle commit before
   the tag, and the write-up rides in that commit.
3. **Release-notes sentence (`LK-36`).** Add a template line to step 7, filled in from the manifest:
   `Release gate (\`docs/automated-tests/<stamp>/\`): lint <w>/<e> in <files> files, <passed> tests <failed> failed, complexity <warnings> over CCN 15. Perf SKIPPED, not measured — no \`tests/perf.lua\` — so the gate covered three suites, not four.`
   v1.54.0's entry (`CHANGELOG.md:579-581`) is the model.
4. **Forward closure (`LK-32`, `LK-35`, `LK-19`).** The next release's `ANALYSIS.md` carries one short
   *Record corrections* paragraph:
   - `20260908-181447/ANALYSIS.md:92` was one too high;
   - `20260916-093057/ANALYSIS.md:60-62` misread a release run's missing write-up as "not a breach";
   - six tags (`v1.28.0`, `v1.29.0`, `v1.36.0`, `v1.36.1`, `v1.54.1`, `v1.54.2`) shipped with no
     release bundle;
   - 32 of 38 release bundles since 2026-09-08 carry no write-up.

   `automated-tests-§5` forbids backfilling, so nothing frozen is touched.

**Risk.** A checklist is still a remembered thing. The `LK-35` test is the one piece that would make the
coupling mechanical, which is the direction `library-stack-§7` prefers. That is why it is offered.

## Track B: the cap census, the watch list and root `CLAUDE.md` (`LK-17d`, `LK-33`, `LK-34`, `LK-29`, `LK-38`, `LK-28`)

**`LK-33`: make the over-cap cells point at the census.** In `docs/automated-tests/RESULTS.md`, replace
the Disposition cells at `:167`, `:168` and `:169` with *"See the census row, `CLAUDE.md` § Files over the
1500-line cap"*. Optionally append the terminal state in a word (*issue #32*, *issue #33*, *register
row*). The runner carries authored cells forward while an entry is unchanged
(`automated-tests-§4`'s boundary), so this is a one-time edit.

This is the **one** authored cell type in a generated file, and editing it is permitted. Do it in the
same commit as a fresh run, or directly: `RESULTS.md` is overwritten on each run, but the Disposition
column is read back from the previous copy.

**`LK-17d`: work the band's dispositions.** Three need a tracked ID, which means an issue each, filed
`state:triaged`, `severity:low`, naming the seam the cell already describes:

- `tests/test_options.lua`: the render/refresh block, out to `tests/test_options_render.lua`;
- `LibKa0s/Widgets.lua`: per-widget files;
- `tests/test_widgets.lua`: split with `Widgets.lua`, by widget family.

Replace each cell with *already tracked as #NN*.

- **`Options.lua`.** Re-rule against its fired 1350 trigger. It is 24 lines from the cap and is the
  entry point every host builds through, so the credible disposition is an issue naming the font-preload
  block as the first peel.
- **`OptionsTabs.lua`, `test_prose.lua` and `test_schema.lua`.** Write a disposition for each blank cell.
  `test_prose.lua` at 1499 is **one line** from the cap, and it is kit code vendored into eleven
  consumers, so it wants an issue now, not after a breach.

Do not peel anything in this track. The cells are the deliverable, and any peel is its own release.

**`LK-34`: a register row for `testkit/framework.lua`.** Add a fifth row at `CLAUDE.md:77`:

- **Rule:** `layout-§1`.
- **What differs:** `testkit/framework.lua` is 1583 lines, over the cap.
- **Why:** condense `:154-165`. The fix could not be deferred, and peeling in the same revision would
  move 596 lines of vendored inventory into a new file in the revision that changes its behavior.
- **Decided:** 2026-09-23, owner decision.
- **Re-check trigger:** the next kit revision touching the suite inventory, or the first consumer
  re-vendor that reports it (`:131` already carries this).

Change `:78`'s *"Four rows"* and its sentence to five. Change the census row's cell to *"Register row
(`layout-§1`, 2026-09-23)"*.

If the owner prefers an issue, open it instead and repoint `:131`. Either way the census and the register
stop disagreeing.

**`LK-29`: correct the three `CLAUDE.md` figures.**

- `:268-269`: "eighty" becomes "eighty-one". Better, stop typing a count: point at the lint sentence the
  runner generates in `RESULTS.md` (*"0 warnings / 0 errors over 81 files"*), so there is one source.
- `:203`: `tests/test_schema.lua` (1101) becomes 1233. Re-run the band command once and re-check all ten
  figures in the same edit.
- `:180`: replace `LibKa0s/OptionsTabs.lua:39` with the symbol (`lib.__tabsMinor` / `lib.__tabsShellMinor`
  in `LibKa0s/OptionsTabs.lua`), which does not drift.

**`LK-38`: register row 1 evidence.** Change *"Filed by the v1.31.0 review"* to *"Filed by the v1.31.0
review (commit `1f1790c`, recorded in `docs/api/testkit/version-17-docs.md`)"*.

**`LK-28`: US-English sweep.**

- **Scope.** The 33 live files: `tests/` (23), the five highest-version `docs/api/` documents,
  `docs/releasing.md`, `README.md`, `DEPENDENCIES.md` and the two `tools/artwork/*.py`.
- **Method.** Mechanical, with the published lists. Remove `ALLOWED` whole words first, as the gate does.
- **Hazard 1: quoted spellings.** `docs/api/Core/version-7-docs.md:212-214` and the matching Slash lines
  quote the British forms *as the thing that was fixed* (`colour` → `color`). Those are documentation of
  the rule. Leave them, or rephrase so they do not spell the word. Do not blindly rewrite them into
  `color` → `color`.
- **Hazard 2: identifiers.** Test fixtures that spell a host's field names (`tests/test_prose.lua:16-18`'s
  reason) may be third-party identifiers. Check each `tests/` hit before rewriting, and ratify any real
  identifier the way rows 1 and 2 do.
- **Out of scope.** Superseded `docs/api/` documents are a per-version record and are left alone.
- **Pay-off.** Completing the `tests/` half satisfies half of register row 3's trigger.

## Track C: the watch-list emitter (`LK-30`, kit change)

In `testkit/run-automated-tests.sh`, change `fn_table()` (`:713-728`) and `band_table()` (`:730-…`) so an
empty set prints the header row and separator and then either nothing or a single `| — | — | — | — |`
row. Drop the `None.` early return.

This is a kit revision (25 to 26):

- bump `Kit.VERSION`;
- add a `docs/api/testkit/version-26-docs.md` entry and regenerate `members-*.json`
  (`lua tools/gen-api-members.lua`);
- add a `CHANGELOG.md` entry;
- sync `testkit/` to `tests/_kit/` in the same commit, so `test_kitsync` stays green;
- have the self-tests assert the header for an empty set.

The change is purely presentational, and every consumer's next run regenerates its `RESULTS.md` with the
header. Re-vendor into all eleven.

**Ordering.** Batch this with any other kit change planned this cycle, so consumers re-vendor once.

## Track D: raw event registrations (`LK-37`, owner decision first)

Two acceptable outcomes:

- **(a) Code.** Add a module-local `safeRegister(frame, event)` in the payload that `pcall`s
  `frame:RegisterEvent(event)`, records a rejected name in a library table (`lib.__rejectedEvents`), and
  exposes it through `LibKa0s-DebugLog-1.0` or the Core printer when a host's debug console is open. Use
  it at `OptionsTabs.lua:102-103,139-140` and `Widgets.lua:393`.
  - **Cost:** minors for `OptionsTabs.lua` and `Widgets.lua` (and whichever file owns the helper), API
    document entries, and a re-vendor.
  - **Risk:** the helper must not raise, and must not print per event per frame.
- **(b) Register row (recommended).** File the row `events-frames-taint-§1` in `CLAUDE.md`. The reasoning:
  - the library cannot take AceEvent-3.0 as a floor, because it is consumer-vendored and the payload
    cannot contain it (`library-stack-§6`; `LibKa0s-Bus-1.0` makes the same argument);
  - these are widget-owned frames, not an event dispatcher;
  - the three names are core client events present on every supported build, so an unknown-name throw
    would lose one widget's registration and never a block.

  Re-check trigger: the payload registers any event added after the current expansion, or a fourth
  registration site appears.

(b) is proportionate to a Low with no reachable failure, and it keeps the payload unchanged in a cycle
whose main work is downstream.

---

## Out of scope for this remediation

- **Peeling any over-cap or band file.** Issues #32 and #33 own those peels, and each is its own release.
- **Rewriting frozen bundles**, including the two `ANALYSIS.md` files `LK-32` and `LK-19` cite.
- **Issues #17–#20** (consumer items deferred to kit 16). They belong to `/wow-addon:issue-triage`, not
  to this plan.
