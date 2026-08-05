# Review findings — LibKa0s, 2026-08-05

**Verdict: ship-ready, minor issues.** No Critical and no High findings. Every out-of-game suite is
green today, the committed evidence agrees with a fresh run in every number, and the shipped code is
in unusually good shape: eight of nine mutation probes into load-bearing guards were caught by the
suite. What is left is six findings about the repo's *own* gates and one docstring that overstates a
cost — worth fixing, none of them urgent, none of them user-facing.

**This repo is the shared library, not an addon.** It is judged here as a library: API surface,
versioning/embedding contract, what it must refuse to do for its consumers, and its own test and
complexity health. Addon-shaped rules that do not apply are listed under *Rules recorded N/A*, with
the reason.

**Standards cross-check: performed.** Ka0s WoW Addon Standard **v2.21.0 (2026-08-04)**, resolved from
`standards/STANDARDS.md`. `anti-patterns` and `testing` were fetched over the network; the remainder
were read from the local read-only checkout at
`/mnt/d/Profile/Users/Tushar/Documents/GIT/WowAddonStandards/standards/standards/` after two `curl`
fetches timed out. Sections used: `library-stack-§7`, `testing-§8`/`§9`/`§10`/`§12`,
`performance-§2`/`§9`/`§10`, `options-ui-§2`/`§9`, `automated-tests`.

---

## Measurement run

Everything below was executed today, from the repo root, before any finding was written. Scratch
output went to
`/tmp/claude-1000/-mnt-d-.../scratchpad/libka0s-review/`; **no committed artifact was touched** and
`git status --porcelain` is empty.

| Suite | Command | Result |
|---|---|---|
| luacheck | `luacheck .` | **pass** — 0 warnings / 0 errors in 11 files |
| Headless tests | `lua5.1 tests/run.lua` | **pass** — 480 passed, 0 failed, 480 total |
| `--list` inventory | `lua5.1 tests/run.lua --list > <scratch>/list.md` | **pass** — byte-identical to `docs/test-cases.md` (32,938 bytes each; `diff` exit 0) |
| Offline perf runner | `lua5.1 tests/perf.lua` | **skipped — no `tests/perf.lua` in this repo.** This is a standing, documented state, not a tooling gap (`docs/automated-tests/RESULTS.md`, *## Perf*). Every runtime-cost claim below is therefore marked **unverified**. |
| Complexity | `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` | **pass** — 0 functions over CCN 15; max CCN **12** (`Sl@527-550@./LibKa0s/Slash.lua`, i.e. `Sl:CliSet`), then `groupContext@496-510@./LibKa0s/Perf.lua` at 11. nloc 7975, 1201 functions, avg CCN 1.8, avg NLOC 6.1 |
| `make test` | — | **skipped — no `Makefile` at the repo root.** Not a convention this repo uses. |
| Vendor sync | `diff -r testkit/ tests/_kit/` | **pass** — no differences. (This repo is both the kit's source and one of its consumers; `tests/test_kitsync.lua` gates the same property in the suite.) |

**Committed artifacts vs. the fresh run — no disagreements found.**

- `docs/test-cases.md` — current. Byte-identical to today's `--list`; total 480 matches the run.
- `docs/automated-tests/RESULTS.md` and bundle `20260805-002859` (`manifest.json`: sha
  `64c1b8a…`, addonVersion 1.7.0, `dirty: true`) — current. Every recorded figure reproduces
  exactly: lint 0/0 over 11 files, tests 480/480, nloc 7975, 1201 functions, avg CCN 1.8, avg NLOC
  6.1, **max CCN 12**, CCN warnings 0. Its watch list is also accurate: no warned functions, and the
  two 1000–1500 band files (`tests/test_options_widgets.lua` 1114, `LibKa0s/Perf.lua` 1052) are still
  the only two. Read the zero as the baseline it says it is — one recorded run is not a streak.
- `docs/performance.md`, `docs/perf-runs/` — absent by design in this repo (see N/A list).

**Mutation probes (my own, not the repo's).** Because a green suite proves nothing about
falsifiability, I mutated nine load-bearing lines one at a time, ran the suite, and restored from a
`cp` backup each time (`testing-§12`'s procedure). Eight went red; one did not. Reported as F-003.
Caught: bucket `within` nesting (5 red), boolean fast-path in `SafeToString` (2), `IsConcatSafe`
bypass (9), `CreateOptionsPanel` idempotence (1), `ClearScroll` refresher reset (2), `hasAlpha`
default (2), JSON key sorting (2), `P.Close` nil-`t0` no-op (1), `SetEnabled` boolean coercion (1),
`OpenToCategory` ID-vs-object (1), numeric-enum dropdown inference (3), and **both** `InCombatLockdown`
guards in `Options.lua` (3). The combat guards are genuinely covered — an earlier probe that
suggested otherwise was my own failed substitution, re-run and corrected.

**In-client checks are deliberately absent from this block.** They are in `03_SMOKE_TESTS.md`.

---

## Medium

### F-001 — `tests/run.lua`'s two hand-maintained load lists have no gate against their sources `[tests]` `[design]`

`tests/run.lua:16-18` spells out the library's eight files by hand, and `tests/run.lua:75-81` spells
out the twelve suite files by hand. Neither is checked against its source of truth
(`LibKa0s/LibKa0s.xml:2-9` and the contents of `tests/`), and the kit's loader skips a missing suite
silently by design (`testkit/framework.lua:99-108`).

**Measured, both directions, today:**

- I added `tests/test_probe_unlisted.lua` containing a single case that calls `T.fail(...)`. The run
  stayed **480 passed, 0 failed** and exit 0 — the suite contributed nothing and nothing said so.
- I added `LibKa0s/Extra.lua` (whose body is a bare `error(...)`) and a matching
  `<Script file="Extra.lua"/>` line to `LibKa0s.xml`. The run stayed **480 passed, 0 failed** — a
  file that ships to eight consumers and raises on load in the client was never executed by any test.
  `luacheck` was the only tool that noticed it existed (12 files instead of 11), and lint does not
  execute.

Both files were removed and the tree verified clean.

*Impact:* these are exactly the two silent failure modes `testing-§9` names — "a suite named in the
runner's list but missing from disk is skipped, not failed" and "a library file omitted from the load
list makes the dependent module refuse to register … and the suite happily measures the stub". They
are live here, in the repo that `testing-§10` names as the **reference implementation** for this
family of gates. The existing coverage is real but partial: a file *already in* `MAJORS` that drops
out of `loadAll` is caught loudly (`tests/test_versioning.lua:43-57`); a *new* file, and any suite
file, is not. `docs/releasing.md:31-37` codifies the `MAJORS` half of the ritual and is silent about
the `loadAll` half sitting six lines above it in the same file.

*Fix direction:* derive both lists, or assert them. `Loader.tocFiles` (`testkit/loader.lua:74-88`)
has no XML sibling, so the compliant shape is a new case that parses `<Script file="…"/>` out of
`LibKa0s/LibKa0s.xml` and compares it, in order, against the list `run.lua` published through
`Kit.expose` — which is precisely what `testing-§9`'s "publish what it loaded through `Kit.expose`
and compare against a fresh derivation" prescribes — plus a second case comparing the declared
`suites` against `tests/test_*.lua` on disk. Do **not** "fix" it by making a missing suite fatal in
the kit: that behavior is deliberate (`testkit/framework.lua:99-100`) and the kit is vendored to
eight consumers.

### F-002 — the API-document release gate is claimed to exist and does not, for the five shipped majors `[tests]` `[design]`

`docs/releasing.md:146` states that `tests/test_kitsync.lua` fails when the live kit revision has no
API document, *"the same bargain `test_versioning.lua` strikes for the library's minors."* It does
not strike that bargain. `tests/test_versioning.lua:107-128` checks the **CHANGELOG**, not
`docs/api/`; none of its seven cases opens a file under `docs/api/`. The only API-document gate in the
repo is `tests/test_kitsync.lua:79-92`, and it covers the kit alone.

*Impact:* `docs/releasing.md:55` says "A minor bump is not released until its document exists", and
`docs/api/README.md` calls that directory "the source of truth for every LibKa0s public contract" —
for five majors across eight files vendored into eight addons. That rule is remembered, not
mechanical, which is the exact failure mode `library-stack-§7` warns about ("Remembered coupling
fails on precisely the release where it matters — the small one, shipped in a hurry"). The priority
is inverted: the kit — one folder, byte-identity gated, no version negotiation — is enforced, while
the five negotiated majors whose older copies are a *supported running state* are not. All five
documents happen to be present today (Core 4, DebugLog 7, Slash 6, Options 6.6.3, Perf 6.3), so this
is a gap in the gate, not a missing document.

*Fix direction:* one case in `tests/test_versioning.lua`, iterating the same `majors` table it
already walks, composing the version key from `lib.MODULES` in `files` order exactly as
`docs/api/README.md` specifies, and failing when
`docs/api/<Major>/version-<key>-docs.md` cannot be opened — the shape `test_kitsync.lua:79-92`
already proves. Then correct the sentence at `docs/releasing.md:146`.

### F-003 — a descriptor-validation case asserts only *that* it raised, and one of its four arms cannot go red `[tests]`

`tests/test_perf_core.lua:15-23` checks four required descriptor fields with bare
`T.assertFalse(ok, …)` and never looks at the message.

**Measured:** replacing `required(d, "name", "string")` (`LibKa0s/Perf.lua:290`) with a no-op leaves
the suite at **480 passed, 0 failed**. The case stays green because `P.slash = d.slash or ("/" ..
d.name:lower())` (`LibKa0s/Perf.lua:328`) raises anyway — with `attempt to index field 'name' (a nil
value)` instead of the library's own framed `LibKa0s-Perf: descriptor.name must be a string`. The
other three arms do go red under the same treatment.

*Impact:* the case reads as coverage of the descriptor contract and covers three-quarters of it.
`testing-§12` is explicit: **MUST NOT** treat *"it raised"* as sufficient — assert on **what** it
raised. The kit ships `Kit.assertError` for exactly this and returns the message
(`testkit/framework.lua:64-71`), and the very next case in the same file
(`tests/test_perf_core.lua:26-40`) already does it right, asserting on
`descriptor.buckets[1].key must be a string`. This is a local slip, not a habit — and worth stating
plainly that eight further probes across `Core`, `Perf`, `Options`, `OptionsWidgets` and `DebugLog`
all went red, so the suite is otherwise mutation-robust.

*Fix direction:* switch the four arms to `assertError` and assert each message names its field. Add
`-- red under: …` naming the mutation, per `testing-§12`'s SHOULD. Do **not** delete or weaken the
case.

### F-004 — the `P.Open`/`P.Close` docstring understates the pair's off-path cost, and nothing measures it `[perf]` `[naming]`

`LibKa0s/Perf.lua:378-381` says the pair returns nil when the probe is off "**so a call site pays one
boolean test and nothing else**, and allocates nothing on either path." The allocation half is
correct. The cost half is not: a bracketed region pays **two Lua function calls** — `P.Open` and
`P.Close` — plus the boolean test inside `Open`, on every traversal, capture on or off.

That matters because `performance-§2` mandates the inline shape
(`local t0 = Perf.on and debugprofilestop()` / `if t0 then Perf.Note(...) end`) and states its cost as
"one upvalue read, one field read and one boolean test — **no call**, no table lookup through `NS`,
no allocation". The pair is a deliberate and well-argued ergonomics trade for multi-exit functions
(`LibKa0s/Perf.lua:382-399`, `docs/api/Perf/version-6.3-docs.md:302-325`, and the 73.9 ms of
unattributed time that motivated it), and `P.Note` is untouched so the §2 idiom remains available.
The defect is the claim, not the API.

*Impact, and it is **unverified** by measurement:* there is no `tests/perf.lua` in this repo, so the
delta between the pair and the inline idiom on the off path is a number nobody in the collection
holds. A consumer reading that docstring has no reason to keep the inline idiom on a per-frame path,
and `performance-§2`'s required evidence (`performance-§9`'s zero-overhead scenario) then has to come
from the consumer's own runner, which the API document does not say.

*Fix direction:* correct the docstring to state the real cost and name the trade; add one sentence to
the current API document telling a host to use the inline `P.on` idiom on per-frame paths and the
pair on multi-exit ones, and that the adopting addon's zero-overhead scenario must cover whichever it
uses. `performance-§9` says scenarios **SHOULD** stay per-addon, so shipping a full `tests/perf.lua`
here is optional rather than required — but a single library-local scenario pinning
`Open`+`Close`-with-capture-off against the same region unbracketed is the only place that one number
can honestly be produced, and is worth having. Do **not** change the API to satisfy §2; that would
break the additive-only contract for consumers already on minor 6.

---

## Low

### F-005 — `P.Close(t0, key)` with a missing key raises mid-capture, not at wiring time `[design]`

`LibKa0s/Perf.lua:367-376`: `P.Note` assigns `buckets[key] = b`, so a host that writes `P.Close(t0)`
— easy to do, since the key is the second argument and the first is the one that reads as the
subject — raises `table index is nil`. On the off path `P.Close` returns at line 408 and the typo is
invisible; it surfaces only **inside a live capture**, in a user's session, mid-fight.

*Impact:* small, but it is the opposite of the fail-early care this file shows everywhere else — the
descriptor raises with a framed message for a missing `name`, `sv`, `suspend`, `resume`
(`LibKa0s/Perf.lua:280-293`) and for a bucket entry with no key (`:343-349`).

*Fix direction:* one guard at the top of `P.Note` returning early on a non-string key, or an
equivalent in `P.Close`. It costs one type test on the **on** path only, so `performance-§2`'s
"MUST NOT allocate, concatenate, format, or call anything else inside a bracket while capture is off"
is untouched.

### F-006 — a typed `perf report` after `perf cancel` prints an empty report stamped with the discarded run's context `[ux]`

`P.Cancel` (`LibKa0s/Perf.lua:822-840`) clears `run`, `armed`, `recording`, `label` and — through
`P.Reset` — the buckets, arms, completions and review marks. It does **not** clear `P.context`, which
`P.BuildRecord` reads at `LibKa0s/Perf.lua:574`. `SUBS.report` and `SUBS.dump`
(`LibKa0s/Perf.lua:975-988`) are reachable as typed commands regardless of phase, deliberately
(`LibKa0s/Perf.lua:469-475`), so `<slash> perf report` after a cancel emits a `capture: unlabelled`
block with `who:` / `where:` / `group:` lines describing the run that was just thrown away, over
`(not sampled)` arms and no buckets.

*Impact:* cosmetic, and the panel gets it right — `Progress()` locks both review rows once `completed`
is cleared. But a report that carries a real character, realm, spec and zone reads as a capture of
something, and these records are read weeks later.

*Fix direction:* clear `P.context` in `Cancel` alongside `P.label`. Keeping the typed verbs ungated is
the right call and should not change.

---

## Rules recorded N/A (library repo, not an addon)

Listed so a reader can tell "does not apply" from "not checked". None of these is a finding.

- **`toc-file`, TOC load order, `## Interface:`, `## SavedVariables:`, `.pkgmeta`, per-version TOCs** —
  N/A. The ship payload is a folder loaded through one aggregate `LibKa0s.xml`
  (`library-stack-§7`); the library has no TOC by definition, which is also why testkit revision 7
  exists (`CHANGELOG.md`, *Unreleased*).
- **`testing-§9`'s TOC derivation, literally** — N/A in its literal form (`Loader.tocFiles` needs a
  TOC). Its *purpose* is not N/A, which is F-001.
- **`documentation-§1`'s player-facing README structure, the `[tests]` badge, `## What's new`,
  `## Screenshots`, `docs/ARCHITECTURE.md`, `docs/smoke-tests.md`** — N/A. These describe an addon a
  player installs. This README is correctly written for the maintainer adopting the library, and
  points at `docs/api/` rather than restating contracts.
- **`performance-§4`–`§8` (`perf` slash verb, `<Addon>PerfDB`, the capture protocol,
  `docs/perf-runs/`)** — N/A as *this repo's* obligations. LibKa0s supplies the machinery; the verb,
  the SavedVariables global, the protocol run and the committed records all belong to the host
  addon. `Perf.lua:870-876` refuses to register a slash command of its own, correctly.
- **`options-ui-§2` combat registration** — checked and **not** a finding. `options-ui-§170` states
  that category registration itself never taints, so the absence of a lockdown guard around
  `Settings.RegisterAddOnCategory` (`LibKa0s/Options.lua:548-571`) is correct. Both `InCombatLockdown`
  guards that *do* matter (panel open at `:637`, canvas `OnShow` at `:463`) are present and are
  covered by three cases — verified by mutation.
- **Secret-value / protected-API leakage** — checked across all eight shipped files, none found. The
  seam is centralized in `Core.IsConcatSafe`/`SafeToString` (`LibKa0s/Core.lua:54-72`) and probes
  `table.concat` rather than `..`, which is the correct detector; `Slash.lua:95-135` guards every
  formatter's **input**; `DebugLog.lua:511-539` wraps `string.format` in a `pcall` with a
  line-still-lands fallback. Bypassing `IsConcatSafe` reddens 9 cases.
- **Deprecated APIs** — none found. `C_AddOns` and `GetBuildInfo` are declared in `.luacheckrc`;
  `Settings.RegisterCanvasLayoutCategory` + `RegisterAddOnCategory` are used, not
  `InterfaceOptions_AddCategory`; `Settings.OpenToCategory` is passed `mainCategory:GetID()`
  (`LibKa0s/Options.lua:571`, `:645`), not the frame — the mutation that swaps them reddens a case.
- **Dead code** — not applicable in the usual sense. Every `lib.*` and instance member here is
  published API for eight consumers; a member with no in-repo caller is the normal state for a
  library. Nothing was flagged.
