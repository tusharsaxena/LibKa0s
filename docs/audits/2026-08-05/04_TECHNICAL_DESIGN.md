# 04 — Technical design (remediation)

How to close the fifteen deviations. Keyed to the IDs in `02_DEVIATIONS.md`. This audit is
**read-only**; nothing here has been applied.

Three properties constrain every change below:

1. **Additive-only API.** `library-stack-§7` forbids removing or repurposing a descriptor field or
   public member within a major. Nothing in this plan touches a signature; LK-13's only code change
   is a **comment**.
2. **Per-file minors and the changelog are coupled mechanically.** `tests/test_versioning.lua` fails
   if a file's live minor and `CHANGELOG.md` disagree. Any edit to a `LibKa0s/*.lua` file that ships
   must bump that file's minor **and** add its changelog line, and then triggers a re-vendor in eight
   consumers (`docs/releasing.md:65-80`). This makes LK-06's comment sweep inside `LibKa0s/` and
   LK-13's comment fix **release-coupled**, and that dominates the sequencing in `05_EXECUTION_PLAN.md`.
3. **`tests/_kit/` is never edited.** LK-08's `RESULTS.md` sentence and LK-09's optional
   `Loader.xmlFiles()` are `testkit/` changes, followed by a `Kit.VERSION` bump, a kit API document,
   a re-vendor into `tests/_kit/`, and eight consumer re-vendors (`testing-§1`, `testing-§11`).

---

## Group 1 — The root doc set (LK-01, LK-02, LK-03)

**New file: `CLAUDE.md` (root, stub).** `documentation-§2`'s five ordered parts, library-adapted:

1. `# CLAUDE.md — LibKa0s`
2. Adherence line naming the standard and `https://github.com/tusharsaxena/WowAddonStandards`.
3. `## Standards compliance (read first)` — the canonical wording at `documentation-§6:163-183`,
   verbatim in substance. Add one sentence, because this repo needs it and no addon does: *this repo
   is the library, so rules written for an addon (TOC, `.pkgmeta`, locales, player-facing README) are
   N/A here and are recorded as such in `docs/audits/`, not silently ignored.*
4. Read-the-docs pointer list → `docs/ARCHITECTURE.md`, `docs/testing.md`, `docs/api/README.md`,
   `docs/releasing.md`, `docs/record-schema.md`, `docs/automated-tests/README.md`.
5. Green-gate line: `lua tests/run.lua` + `luacheck .`.

**Must NOT** become a full agent brief (#26) and **must NOT** point at an in-repo scaffolding pack
(#49). Target length: under 60 lines.

**`README.md` — the standard reference (LK-02, place 2).** A library README has no player badge row,
so the honest form of place 2 is the badge on its own plus a one-line adherence sentence directly
under the H1:

```markdown
[![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)](https://github.com/tusharsaxena/WowAddonStandards)

Built to the **Ka0s WoW Addon Standard**. This repo is the shared library, not an addon — see
`CLAUDE.md` for which of the standard's rules apply here and which are N/A.
```

Note the underscore, not `%20` (`documentation-§1:42`) — even though CurseForge never renders this
one, the collection uses one spelling. **Risk:** none; additive markdown.

**New file: `DEPENDENCIES.md` (root).** Three groups, every entry evidence-cited:

| Group | Entries | Evidence to cite |
|---|---|---|
| Runtime (in-game) | **None.** The library is vendored by copy into each host's `libs/`; a player installs nothing. | `README.md:25-38`, `library-stack-§3` |
| Development | `lua5.1` (**hard requirement** — the kit uses `setfenv`, 5.1-only), `luacheck` (**`sudo luarocks install luacheck`** — a Lua package, *not* pipx), `lizard` (`pipx install lizard` — PEP 668 makes plain `pip` fail on Ubuntu 24.04), `git`, `bash`, POSIX `ls` | `testkit/loader.lua` `setfenv`; `.luacheckrc`; `manifest.json` `host` block; `tests/_kit/run-automated-tests.sh`; `tests/test_kitsync.lua` |
| Release / assets | **None.** No packaging step, no image tooling, no vendored binaries. Say so explicitly, per `documentation-§7`. | — |

Plus a verify line per tool (`lua -v`, `luacheck --version`, `lizard --version`) and a closing
"commands this repo is verified with" section **pointing at** `docs/testing.md` rather than
restating it. The luacheck-vs-lizard install-channel distinction is the one that has already burned
this collection (`CHANGELOG.md` Unreleased) and must be stated as a warning, not a footnote.

---

## Group 2 — The `docs/` trio and topic-detail docs (LK-04, LK-05, LK-11, LK-12)

**`docs/testing.md` (LK-04).** Move — not copy — the verify material out of `README.md:122-159`,
leaving a two-line pointer behind. Contents: the two gate commands; the runner's
`--suite lint --suite tests --no-bundle` fast path; Lua 5.1 and why; `lua tests/run.lua --list >
docs/test-cases.md` and the CRLF note; what `test_versioning.lua` and `test_kitsync.lua` enforce and
why a green run without them means less than it looks; pointers to `docs/test-cases.md`,
`docs/smoke-tests.md` and `DEPENDENCIES.md`. **Risk:** the README's `## Development` section is
referenced by `docs/releasing.md:17-22`; update that cross-reference in the same change.

**`docs/ARCHITECTURE.md` (LK-05).** Library-adapted section set, with the N/A ones stated rather than
dropped:

- **Overview** — what the library is, what "one major per module" buys, and the two-contract rule
  (additive-only API vs. clean-break record schema).
- **Module Map** — the five majors, their files, and the **dependency graph with floors**: which
  minor of `Core` each dependent requires and what happens when it is unmet (return before
  `NewLibrary` ⇒ major absent, host falls back to its stub). This is the single most useful thing
  the file adds over `README.md:196-230`.
- **Descriptor surfaces** — one line per major pointing into `docs/api/<Major>/`; no signatures
  restated (a second copy of a contract drifts — `README.md:44-45`).
- **The `L` seam** — `rawget`, and why (`README.md:83-120`, summarized with a pointer).
- **Persistence** — `<Addon>PerfDB`, pointer to `docs/record-schema.md`.
- **Taint notes** — the `Settings` / `SettingsPanel` / `HideUIPanel` reaches and their guards, with
  the `.luacheckrc:14-17` comment as the source, plus the two `InCombatLockdown` guards the review's
  mutation probes reddened.
- **Known limitations** — no offline perf scenarios (LK-13), no in-game coverage of its own
  (LK-12), the ungated load lists until LK-09 lands.
- **N/A with reasons** — Settings Schema, Message Bus, Event Subscriptions, Slash Commands table.

**`README.md` layout block (LK-11).** Add `automated-tests/` and `audits/` rows. One-line change.

**`docs/smoke-tests.md` + `docs/performance.md` (LK-12).** Both short and honest rather than padded:

- `docs/smoke-tests.md` — a library cannot be loaded alone, so this file names *what only a live
  client can prove for this code* (the console renders, the settings canvas builds and refuses in
  combat, the perf panel's steps advance, the stopwatch calls) and points at the consumers' suites
  that actually run those checks. That is a real document, not a placeholder.
- `docs/performance.md` — the library's own performance page: what is bracketed inside the library
  itself (nothing today), what the harness can and cannot resolve, and a pointer to
  `docs/api/Perf/` and `docs/record-schema.md` for the protocol. Should state LK-13's gap in one line
  so the two records agree.

`docs/perf-runs/README.md` stays **absent** — the reason is already written down.

---

## Group 3 — Release process (LK-07, LK-08, LK-14, LK-15)

**`docs/releasing.md` — a new numbered step (LK-07, LK-14).** Between the current 6 (regenerate the
case list) and 7 (move the provenance template, tag):

> **6a. Produce the release bundle.** From a **clean** tree —
> `git status --porcelain` empty — run `tests/_kit/run-automated-tests.sh --release <X.Y.Z>`. A
> bundle whose `manifest.json` reads `"dirty": true` is not release evidence: its numbers cannot be
> tied to any commit. Commit the bundle **before** the tag, so the tagged commit carries it.

Numbering after this is `7 → 8`, `8 → 9`, `9 → 10`; the internal cross-references at
`docs/releasing.md:61` ("step 8 is a copy") must move with them.

**`docs/releasing.md` — the release gate (LK-08).** A short subsection under the order of operations:

> **The gate at the tag is not the gate at a commit.** A commit is gated on `lua tests/run.lua` +
> `luacheck .` and nothing else — a threshold on every commit is routed around with `--no-verify`,
> after which it protects nothing. The **tag** is gated on the release bundle's `manifest.json`
> showing **all four** suites at `pass` and `suites.complexity.warnings == 0` (no function above
> CCN 15). A `skip` is **not** a pass; it blocks as NOT EVALUATED. The one narrow exception is this
> repo's standing `perf` skip — no `tests/perf.lua` exists, which is a different fact from a
> scenario that failed or a tool that was missing — and it **must be stated as such in the release
> notes** every time (`automated-tests-§3`). Report every failed gate, not the first; bump, tag and
> push nothing when one fails.

**`docs/automated-tests/README.md` (LK-08).** Add a `Gates at the tag?` column to the table at
`:29-34`, or a paragraph under it, so "no — recorded only" is never read without its checkpoint.
Cheapest correct edit: change the two `no — recorded only` cells to
`no at commit — **yes at the tag**` and add the release-gate paragraph below.

**`RESULTS.md` (LK-08, generated).** Do **not** hand-edit — `RESULTS.md:3-4` says it is overwritten in
place, and a hand-edited generated record reads as measured. The sentence at `RESULTS.md:9-11` is
emitted by `testkit/run-automated-tests.sh`; extend it there to name the release checkpoint, then
bump `Kit.VERSION`, write the kit API document, re-vendor `tests/_kit/`, and let
`tests/test_kitsync.lua` confirm. The next run rewrites `RESULTS.md` with the corrected banner.
**Risk:** this is a collection-wide change — every consumer's `RESULTS.md` banner changes on its next
run. That is the intended blast radius; the sentence is wrong in eight repos today.

**`docs/releasing.md:143-146` (LK-15).** Two options, in order of preference:

1. **Make the claim true.** Add a case to `tests/test_versioning.lua`: for each row of `MAJORS`, join
   the live `lib.MODULES` minors in `files` order, and assert
   `docs/api/<Major>/version-<joined>-docs.md` exists on disk. This is the same shape
   `test_kitsync.lua` already uses for the kit revision, so the implementation is a copy, and it
   closes the actual inversion — the five majors vendored into eight addons are the ones that need
   the gate, not the single-consumer kit.
2. If (1) is deferred, correct the sentence to say the library half is a **convention enforced by
   step 5**, not by a test.

**Risk on (1):** the version key format is "minors joined in load order" (`README.md:61-68`), which
is `6.6.3` for Options and `6.3` for Perf — the joiner must use the `files` order from `MAJORS`, not
`pairs(lib.MODULES)`, which is unordered. Getting that wrong yields a false red on every release.

---

## Group 4 — Test integrity (LK-09, LK-10)

**LK-09 — the derivation gate.** Two assertions, one new suite (`tests/test_loadlist.lua`) or two
cases appended to `test_versioning.lua`:

- **Library files vs. the XML.** Read `LibKa0s/LibKa0s.xml`, extract `file="([^"]+)"` in document
  order, prefix `LibKa0s/`. Publish the runner's actual list through `Kit.expose`
  (`tests/run.lua:64-72`, add `loadList = <the table>`) and assert **sequence** equality — set
  equality alone would miss a reordering, and Core must load first. Also assert every path exists on
  disk.
- **Suites vs. `tests/`.** Shell out for the directory listing the way `tests/test_kitsync.lua`
  already does (no LuaFileSystem — `testing-§3`), collect `test_*.lua`, and assert the set matches
  `Kit.run`'s `suites` list both ways. A file on disk that is not listed is the failure the review
  measured; a listed suite missing from disk is skipped-not-failed by design, so the assertion is
  what makes it visible.

**Design decision to make before implementing:** whether the XML parser belongs in
`testkit/loader.lua` as `Loader.xmlFiles(path)`, beside `Loader.tocFiles`. It should — every
consumer's runner spells out the library's files by hand (`testing-§9:151-153`) and has exactly this
gap. But that is a kit change with the full re-vendor tail, so the local version can land first and
be promoted once a second consumer wants it (`library-stack-§7`'s two-consumer bar). Land it locally,
comment it as a promotion candidate.

**LK-10 — falsifiable assertions.** Rewrite `tests/test_perf_core.lua:15-23` using
`T.assertError` (`testkit/framework.lua:64-71`), asserting the library's own message text per
missing field, and add the `-- red under:` comment naming the mutation
(`no-op required(d, "name", "string") at Perf.lua:290`). No implementation change. Then re-run the
mutation to confirm the case now reddens — the point of the rule is the run, not the rewrite.

**Sweep, not a spot fix.** While in the file, grep the whole suite for the same shape
(`pcall` + `assertFalse` with no message assertion) and convert each; the review found this one by
mutation, and mutation is not something the next audit can repeat cheaply for 480 cases.

---

## Group 5 — Prose and comments (LK-06, LK-13)

**LK-06 — the spelling sweep.** Split by blast radius, because the two halves are not the same
change:

| Half | Files | Coupling |
|---|---|---|
| **Free** | `README.md`, `docs/releasing.md`, `docs/adoption-prompt.md`, `docs/adoption-report.md`, `docs/api/` **current** documents only, `tests/*.lua`, `testkit/*.lua` docs/comments | None. `tests/` and `docs/` are luacheck-excluded; no minor bump. |
| **Release-coupled** | `LibKa0s/*.lua` (31 comment hits across 5 files) | Each edited file must bump its minor, add its `CHANGELOG.md` line, and trigger a re-vendor in eight consumers. |

Preserve, do not sweep: `docs/adoption/`, `docs/reviews/`, `docs/superpowers/` (frozen history);
**superseded** `docs/api/` documents (`docs/releasing.md:53-55` — never edited after they stop being
current); quoted external text in `CHANGELOG.md` released blocks. `docs/test-cases.md` is generated
and follows its suite names on the next `--list`.

**Recommendation:** do the free half now, and fold the `LibKa0s/*.lua` half into the **next release
that already touches each file** rather than manufacturing eight minor bumps and eight consumer
re-vendors for comment spellings. That is a judgment the standard permits (`localization-§5` fixes
prose, and no key or identifier is involved here — see `03_EVIDENCE.md` LK-06), and it should be
written down in `CLAUDE.md` so the next sweep does not re-litigate it.

**LK-13 — `tests/perf.lua`.** Minimum viable scope, per `performance-§9`:

- **Scenario 1 (required): zero overhead when off.** Loop `P.Open(...)`/`P.Close(t0, ...)` N times
  with capture off; measure **allocation** (full `collectgarbage("collect")` either side) and call
  counts, and compare against the same loop with the calls absent. Assert on those deterministic
  quantities only — **never** wall-clock (`performance-§9`, `testing-§7`).
- **Scenario 2 (recommended): the on path**, so the off/on ratio is a number the library can quote
  instead of the current comment.
- Then correct `LibKa0s/Perf.lua:377-378` to say what was measured — a **comment** change, so it
  bumps `Perf.lua`'s minor and needs its changelog line, but changes no behavior and no signature.
- The runner picks `tests/perf.lua` up automatically as its `perf` suite, which flips the manifest's
  standing `skip` to a `pass` and removes LK-08's narrow release-gate exception. Update
  `RESULTS.md`'s `## Perf` prose (generated — via the emitter) and
  `docs/automated-tests/README.md:38-42` accordingly.

---

## Ordering constraints (feed into `05_EXECUTION_PLAN.md`)

- LK-01 must land before LK-02's place 3 (the section lives in the file).
- LK-04 and LK-05 must land before LK-01's pointer list can point at them (or the stub ships with
  dead links).
- LK-11 should land in the same change as LK-04/LK-05 — the layout block is where the new docs get
  listed.
- LK-08's `RESULTS.md` half depends on the `testkit/` change, which depends on a `Kit.VERSION` bump
  and a kit API document, and drags a re-vendor tail. Its `docs/` half has no such dependency and
  should not wait for it.
- LK-13's `tests/perf.lua` must exist before LK-08's release-gate wording can drop the `perf`-skip
  exception. Until then the exception is correct and must be stated.
- LK-06's release-coupled half and LK-13's comment fix both touch `LibKa0s/Perf.lua`; do them in one
  change so `Perf.lua` bumps once.
- LK-09 and LK-10 are independent of everything else and are the two that most improve what the
  suite actually proves. They are cheap and they gate future work honestly — do them first.
</content>
