# Proposed changes — LibKa0s, 2026-08-05

Design document for the six findings in [`01_FINDINGS.md`](01_FINDINGS.md). Nothing here is urgent;
nothing here changes shipped behavior for a consumer except one added guard (C-5) and one cleared
field (C-6), both of which only fire on paths that are broken or discarded today.

**Standards conformance basis.** Ka0s WoW Addon Standard **v2.21.0 (2026-08-04)**, resolved from
`standards/STANDARDS.md`. `anti-patterns` and `testing` fetched over the network; the rest read from
the local read-only checkout of the standards repo after two `curl` fetches timed out. Every change
below is checked against it and none introduces a new deviation.

**Upstream change-set: none.** This repo *is* the upstream. It vendors no third-party library and no
foreign code — `tests/_kit/` is this repo's own `testkit/` re-vendored into itself, and
`test_kitsync.lua` holds the two byte-identical. Consequently **no change below targets
`tests/_kit/`**; C-1 and C-2 land in `tests/`, C-3 in `tests/`, C-4/C-5/C-6 in `LibKa0s/`. The one
consequence that does cross repos is the re-vendor obligation created by C-5 and C-6 (see *Release
consequences*).

---

## HLD

### Theme A — make the last two remembered couplings mechanical (C-1, C-2)

*Findings: F-001, F-002.*

This repo has done the hard version of this work already: `test_versioning.lua` turns
`library-stack-§7`'s minor/changelog coupling into a test, and `test_kitsync.lua` turns a remembered
`diff -r` into a byte-identity gate. Two couplings were left behind, and both are named in
`docs/releasing.md` as steps a human performs:

1. a new shipped file must reach `LibKa0s.xml` **and** `tests/run.lua`'s `loadAll` **and** `MAJORS`
   (step 3 mentions only the third);
2. a bumped minor must get an API document (step 5), enforced for the kit and not for the majors.

Both fail silently, both are cheap to gate, and the repo already owns the idioms. The theme is
finishing the job, not starting a new one.

*Alternative considered and rejected:* make the kit's `loadSuites` fatal on a missing file
(`testkit/framework.lua:99-108`). Rejected — the skip is deliberate ("so a suite can be listed while
it is being written"), the kit is vendored to eight consumers, and a kit change forces eight
re-vendor commits to fix a problem that belongs to one repo's own `run.lua`.

*Alternative considered and rejected:* add an `xmlFiles()` derivation to `testkit/loader.lua`
mirroring `tocFiles`. Rejected for now under `library-stack-§7`'s promotion bars: **one** consumer
(this repo) needs it, so bar 1 is unmet, and `testing-§9` already tells consumers to spell the
library's files out explicitly. Revisit only if a second Ka0s-owned library repo appears.

*Trade-off accepted:* C-1 adds a small XML parser to the suite. It is a regex over
`<Script file="..."/>` and will not survive an exotic XML rewrite — acceptable, because the file it
parses is eight lines this repo controls, and a failure is a red suite rather than a wrong result.

### Theme B — say what things cost, exactly (C-3, C-4)

*Findings: F-003, F-004.*

Two claims in the repo are stronger than what is actually true or actually checked: a test that says
it pins four descriptor requirements and pins three, and a docstring that says a bracket costs "one
boolean test and nothing else" when it costs two calls as well. Both are honesty repairs. Neither
changes behavior.

*Alternative considered and rejected for C-4:* change `P.Open`/`P.Close` to match
`performance-§2`'s inline shape. Rejected outright — the API is **additive-only within a major**
(`library-stack-§7`), consumers are already on `Perf.lua` minor 6, and the pair exists for a
documented reason with a measured 73.9 ms behind it. The claim is wrong; the API is not.

*Alternative considered and deferred for C-4:* ship a full `tests/perf.lua`. `performance-§9` says
scenarios **SHOULD** stay per-addon, so this repo is not obliged. C-4 proposes the one scenario that
genuinely cannot live downstream (see LLD) and leaves the rest to consumers.

### Theme C — two small correctness/clarity fixes in `Perf` (C-5, C-6)

*Findings: F-005, F-006.*

A missing bucket key should fail where it is wired, not mid-fight; a cancelled run should not leave
its identity behind for the next report to wear. Both are a line each.

---

## LLD

### C-1 — gate `run.lua`'s two load lists against their sources

**Covers:** F-001. **Files:** `tests/run.lua`, `tests/test_versioning.lua` (or a new
`tests/test_loadlists.lua`), `docs/releasing.md`, `docs/test-cases.md` (regenerated).

Publish what the runner actually loaded, then assert it against the XML:

```lua
-- tests/run.lua
local LIB_FILES = { "LibKa0s/Core.lua", "LibKa0s/DebugLog.lua", ... }   -- unchanged list, now named
Loader.loadAll(LIB_FILES, nil, mocks)
...
_G.LK_TEST = Kit.expose{ ..., libFiles = LIB_FILES, suites = SUITES }
```

Two new cases:

- **`loadlists: every file in LibKa0s.xml is loaded by the suite, in XML order`** — read
  `LibKa0s/LibKa0s.xml`, collect `<Script file="(.-)"/>` in order, prefix `LibKa0s/`, and
  `assertEqual(table.concat(got, ", "), table.concat(T.libFiles, ", "), …)`. This is
  `testing-§9`'s "publish what it loaded through `Kit.expose` and compare against a fresh derivation"
  with the XML standing in for the TOC. Collect every mismatch before failing
  (`testing-§10`'s SHOULD).
- **`loadlists: every tests/test_*.lua on disk is a declared suite`** — list `tests/` with the same
  `ls -A` / `dir /b` shell fallback `tests/test_kitsync.lua:38-59` already uses (and its
  fail-when-it-cannot-look rule: a gate that goes quiet is worse than no gate), filter
  `^test_.*%.lua$`, and compare the set against `T.suites`.

Also add the missing half-sentence to `docs/releasing.md:31-37`: a new module is a new row in
`MAJORS` **and** a new entry in `loadAll`, and both are now tested.

*Risk:* low. Pure test addition. Both cases must be shown red before they are trusted — the
falsification procedure is in `03_SMOKE_TESTS.md` and it is the same experiment used to find the
defect.

*Standards:* `testing-§9` (both silent failure modes), `testing-§10` (collect misses before failing),
`testing-§12` (the new cases assert a *set equality*, not a negative, and are falsified by the
documented mutation). No new deviation.

### C-2 — gate the API document for every shipped major

**Covers:** F-002. **Files:** `tests/test_versioning.lua`, `docs/releasing.md`,
`docs/test-cases.md` (regenerated).

One case, iterating the `majors` table the suite already walks:

```lua
test("versioning: every major's live version has an API document", function()
  local missing = {}
  for _, m in ipairs(majors) do
    local lib = libFor(m.major)
    if lib and type(lib.MODULES) == "table" then
      local parts = {}
      for i, file in ipairs(m.files) do parts[i] = tostring(lib.MODULES[file]) end   -- load order
      local path = ("docs/api/%s/version-%s-docs.md"):format(m.major, table.concat(parts, "."))
      local f = io.open(path, "r"); if f then f:close() else missing[#missing + 1] = path end
    end
  end
  table.sort(missing)
  assertEqual(table.concat(missing, ", "), "", "a minor bump is not released until its document exists")
end)
```

The key is composed from `lib.MODULES` in `files` order, which is exactly what
`docs/api/README.md` (*Reading the version key*) specifies — `Core` → `4`, `Options` → `6.6.3`,
`Perf` → `6.3`. Green today for all five.

Then fix `docs/releasing.md:146`, which currently claims this bargain already exists for the majors.

*Risk:* low, with one real consequence worth stating: **from this change on, a minor bump cannot be
committed before its API document is written.** That is the intent (`library-stack-§7`,
`docs/releasing.md:55`), and it makes the commit gate stricter in the same way the changelog case
already does.

*Standards:* `library-stack-§7` (coupling mechanical rather than remembered), `testing-§10` (the
versioning suite is where per-file-minor obligations are pinned). No new deviation.

### C-3 — assert *what* the descriptor validation raised

**Covers:** F-003. **Files:** `tests/test_perf_core.lua`, `docs/test-cases.md` (regenerated).

```lua
-- before
local ok = pcall(function() lib:New({ sv = "X", suspend = ..., resume = ... }) end)
T.assertFalse(ok, "missing name must error")

-- after
local err = T.assertError(function() lib:New({ sv = "X", suspend = ..., resume = ... }) end,
  "missing name must error")
T.assertTrue(err:find("descriptor.name must be a string", 1, true) ~= nil,
  "and must say which field, got: " .. err)
-- red under: replace `required(d, "name", "string")` in Perf.lua with a no-op — without the message
-- assertion this still passes, because P.slash indexes d.name and raises on its own.
```

Same for `sv`, `suspend`, `resume`. `Kit.assertError` (`testkit/framework.lua:64-71`) already returns
the message; no kit change is needed. Case name and count are unchanged, so
`docs/test-cases.md`'s total stays 480 for this change alone.

*Risk:* none. If the four messages do not match, that is the finding surfacing, not a regression.

*Standards:* `testing-§12` (MUST NOT treat "it raised" as sufficient; SHOULD record the reddening
mutation in the case's own comment). No new deviation.

### C-4 — correct the bracket cost claim, and pin it with one scenario

**Covers:** F-004. **Files:** `LibKa0s/Perf.lua` (comment only), the **current** API document
`docs/api/Perf/version-6.3-docs.md`, optionally a new `tests/perf.lua`.

Comment change at `LibKa0s/Perf.lua:378-381`:

> …so a call site pays **two calls and one boolean test**, and allocates nothing on either path.
> `performance-§2`'s inline form (`local t0 = P.on and debugprofilestop()`) stays the right shape on a
> **per-frame** path, where those two call frames are the cost §2 exists to avoid; this pair is for
> **multi-exit** functions, where the alternative is a per-exit `if t0 then` branch or — as happened —
> no instrumentation at all.

API document: one paragraph in *Bracketing a multi-exit function* saying the same thing, plus the
sentence that the adopting addon's `performance-§9` zero-overhead scenario must cover whichever form
it uses. **This is an edit to the current document only** — never to a superseded one
(`docs/api/README.md`, *Adding a version*), and it is a clarification of existing behavior, not a
`Since` entry, so it does **not** require a minor bump.

Optional, recommended: a minimal `tests/perf.lua` with exactly one scenario —
`Open`+`Close`-with-capture-off over a fixed loop, versus the same loop unbracketed, versus the same
loop with the inline `P.on` idiom — asserting **only** on bytes allocated per iteration (which should
be zero for all three) and reporting call counts. **MUST NOT** assert on wall-clock time
(`performance-§9`). If added, it must **not** appear in `docs/test-cases.md` or any pass count
(`testing-§7`), and it is outside the green gate.

*Expected effect on the record:* the `perf` suite in the next `docs/automated-tests/` bundle moves
from `skip` to a recorded result, and `RESULTS.md`'s `## Perf` section — which currently states
plainly that the record is silent about runtime cost — is rewritten to say what was measured.
`automated-tests-§3`'s release gate is unaffected either way (`perf` does not gate).

*Risk:* low. No shipped behavior changes. The scenario is the only part that can rot, and
`performance-§9`'s wall-clock ban is the rule that keeps it from becoming a flake generator.

*Standards:* `performance-§2` (the inline idiom and its stated cost), `performance-§9` (offline
runner rules: no wall-clock assertions, deterministic quantities only, per-addon by default),
`testing-§7` (scenarios are not test cases), `library-stack-§7` (additive-only — which is why the API
is not touched). No new deviation.

### C-5 — refuse a bucket write with no key

**Covers:** F-005. **Files:** `LibKa0s/Perf.lua`, `tests/test_perf_core.lua`,
`docs/test-cases.md` (regenerated), `CHANGELOG.md`, `docs/api/Perf/version-<new>-docs.md`.

```lua
function P.Note(key, ms)
  if type(key) ~= "string" then return end   -- ON path only; a keyless bracket must not raise mid-capture
  ...
```

Return silently rather than raising: `P.Note` runs inside a live capture, and a raise there kills
whatever ticker was measuring. Pair it with a case asserting that `P.Close(t0)` with no key leaves
`__buckets()` untouched and does not raise — that is a negative assertion, so it carries its
`-- red under: remove the type guard in P.Note` comment (`testing-§12`).

*Risk:* low, with one honest downside: a genuine typo now fails quietly instead of loudly. Mitigated
by `testing-§8`'s existing requirement on consumers — "every declared bucket is reached by a real
bracket, driving each bucket's genuine entry point" — which is the check that catches a typo'd key,
and catches it in the consumer's own suite where it belongs.

*Standards:* `performance-§2` (the guard is on the **on** path; the off path through `P.Close`'s
`if not t0 then return end` is untouched, so "MUST NOT allocate, concatenate, format, or call
anything else inside a bracket while capture is off" still holds), `library-stack-§7` (behavior
change inside an existing member ⇒ `Perf.lua` minor bump, changelog entry, new API document — see
*Release consequences*). No new deviation.

### C-6 — clear the capture context on cancel

**Covers:** F-006. **Files:** `LibKa0s/Perf.lua`, `tests/test_perf_run.lua`,
`docs/test-cases.md` (regenerated), `CHANGELOG.md`, `docs/api/Perf/version-<new>-docs.md`.

In `P.Cancel` (`LibKa0s/Perf.lua:836`), beside `P.label = nil`:

```lua
P.label   = nil
P.context = nil   -- a discarded run must not lend its who/where to the next report
```

`P.ContextLines(nil)` already returns `{}` (`LibKa0s/Perf.lua:535-536`) and `BuildRecord` stores
`context = P.context` unconditionally, so a nil context yields a record with no context block rather
than a raise. The typed `report`/`dump` verbs stay ungated — that is deliberate
(`LibKa0s/Perf.lua:469-475`) and correct.

*Risk:* low. One behavior change on a path whose data is already discarded.

*Standards:* `performance-§8` (the record schema is a data contract; `context` remains an optional
field and the schema number does not move — a record with no context is already representable, since
`Context()` degrades every lookup to `"?"`). Same minor-bump obligation as C-5. No new deviation.

---

## Release consequences

C-5 and C-6 change `LibKa0s/Perf.lua`. Under `library-stack-§7` and `docs/releasing.md` that means,
in order: bump `MINOR` in `Perf.lua` to 7 (and **only** that file — no lockstep bumps); add the
`Perf.lua minor 7` changelog entry, which `tests/test_versioning.lua:107-128` will demand; write
`docs/api/Perf/version-7.3-docs.md` and mark `6.3` superseded with its *Moving to …* section; add the
row to `docs/api/README.md`; regenerate `docs/test-cases.md` with
`lua tests/run.lua --list`; then **re-vendor the whole `LibKa0s/` folder into every consumer as its
own commit**. Once C-2 lands, the missing API document blocks the commit rather than the release,
which is the point.

C-1, C-2 and C-3 touch only `tests/` and `docs/`, need no minor bump, and need no re-vendor.

## Regression pressure on the pass count

`docs/test-cases.md` and any quoted count **must move in the same change** that moves them
(`testing-§5`), never as a follow-up:

| Change | Cases added | Total after |
|---|---|---|
| C-1 | +2 | 482 |
| C-2 | +1 | 483 |
| C-3 | 0 (existing case strengthened) | 483 |
| C-4 | 0 (scenarios are not cases — `testing-§7`) | 483 |
| C-5 | +1 | 484 |
| C-6 | +1 | 485 |

This repo has no README `[tests]` badge (it is a library, not a player-facing addon), so there is no
badge to move — only `docs/test-cases.md`.

## Expected complexity movement

None of C-1…C-6 adds a branch to a function anywhere near the CCN 15 threshold; today's maximum is 12
(`Sl:CliSet`). C-5 adds one guard to `P.Note`, whose current CCN is 2. No watch-list entry is expected
to move, and `LibKa0s/Perf.lua` stays inside the 1000–1500 band at roughly 1054 lines. The next
release's regeneration should confirm this rather than anyone running `lizard` into the repo now.
