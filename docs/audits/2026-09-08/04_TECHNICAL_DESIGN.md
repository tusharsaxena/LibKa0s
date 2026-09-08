# 04 — Technical design

Remediation design for the seven roots and one dependent in `02_DEVIATIONS.md`. Nothing here is a
change to the **shipped payload's behavior**: `LK-31` moves one shim between two payload files and
bumps two minors, and everything else is documents, one shell function in the kit, and one issue.
That is the honest shape of this run — the repository's defects are in its record and its process,
not in its bytes.

**Ordering constraints, up front.**

1. **`LK-30` is a kit change, so it decides whether a release is needed.** `testkit/` is vendored
   into nine consumers, and `library-stack-§7` makes a kit edit a re-vendor trigger. Either it
   lands with `LK-31`'s payload change under one tag, or it waits for the next tag that is being cut
   anyway. It **MUST NOT** be hand-applied to `RESULTS.md` — that is exactly the hand-edit
   `automated-tests-§4`'s boundary forbids, and the next run reverts it.
2. **`LK-19` must land before the next tag**, because the tag is the checkpoint it governs. It is a
   documentation change with no code dependency, so it can go first and alone.
3. **`LK-28` and `LK-28d` are one change or neither.** Sweeping 216 spellings and leaving the gate
   at two directories guarantees the 217th arrives on the next commit.
4. **`LK-29` is independent and takes ten minutes.**

---

## LK-19 — the release procedure never names `ANALYSIS.md`

**Section:** `automated-tests-§5`. **Files:** `docs/releasing.md`.

The rule has two halves and this repo has one. The forward-closure half — *note the gap once, do not
backfill* — is discharged at `20260908-181447/ANALYSIS.md:90-110`. The other half is that **every
release run MUSTs a write-up**, and there is no place in the release procedure that says so, which
is why two tags were cut this cycle without one while an open finding said they would be.

**Shape of the change.** `docs/releasing.md` step 7 already has the right structure: a `--release`
run, then a hard-precondition block read off the manifest (`:134-153`), then the tag. Insert the
write-up between the run and the preconditions, as a numbered sub-step, and add it to the
precondition list so the tag is gated on the file existing rather than on remembering it:

```
   7c. Write `docs/automated-tests/<stamp>/ANALYSIS.md`, following the prompt in the root
       `AUTOMATED_TESTS.md`. It is a MUST at release (`automated-tests-§5`) — the reading is taken
       at the run, and one written later into a folder stamped weeks ago is a different artifact
       wearing the same name. Link each suite's artifact; report complexity with totals AND
       averages.

   ... in the precondition block:
   test -f "docs/automated-tests/<stamp>/ANALYSIS.md"   # the write-up, or no tag
```

**Why not automate it.** The runner cannot write the analysis — it is a reading, not an output, and
`automated-tests-§4`'s boundary keeps generated and authored apart on purpose. What the *procedure*
can do is refuse to proceed without it, which is what the precondition line buys.

**Risk:** none. **Verification:** `grep -c ANALYSIS docs/releasing.md` is non-zero, and the next
release bundle carries the file.

**Explicitly not done:** no frozen bundle gains an `ANALYSIS.md`. Nineteen never will.

---

## LK-28 + LK-28d — US English outside the shipped payload

**Sections:** `localization-§5` (root), plus `testing-§12` for the gate. **Files:** 33 live authored
files, and `tests/test_prose.lua`.

Do the gate first, then the sweep, in that order — a red gate is the worklist, and it also proves
the sweep is complete rather than asserting it.

**Step 1 — widen the gate's scan scope.** `tests/test_prose.lua:19`'s
`SHIPPED = { "LibKa0s", "testkit" }` becomes two sets, because the two gates in that file want
different scopes and only one of them is about what ships:

- the existing payload scan stays exactly as it is — it is the one whose failures reach a player,
  and its zero is worth keeping legible on its own;
- a second scan covers **authored text**: `README.md`, `CLAUDE.md`, `DEPENDENCIES.md`, the live
  `docs/` pages, `docs/api/` and `tests/`, with `localization-§5`'s four exclusions named **file by
  file or directory by directory** as the section requires — `tests/_kit/` (vendored),
  `docs/audits/`, `docs/reviews/`, `docs/adoption/`, `docs/superpowers/`,
  `docs/automated-tests/<stamp>/` and `CHANGELOG.md` (frozen record), and `tests/test_prose.lua`
  itself (the gate's own copy of the lists).

`listDir` does not recurse today, and `docs/api/` is two levels deep, so this needs a recursive walk
or — better and cheaper — `git ls-files`, which the EOL gate already shells out for and which
answers the tracked set in one call. Reuse that shape rather than adding a second directory walker.

**The superseded-`docs/api/` question, decided rather than left open.** 256 of the 472 hits are in
48 superseded per-version API documents. Those are a **record of what a released minor said**, and
`library-stack-§7` treats them that way — a superseded document is never edited to describe new
behavior. Rewriting their prose is editing a record. **The design excludes them by construction:**
the gate scans only the **live** document per major, resolved from the `MODULES` registry the
versioning suite already reads, so a new release automatically brings its own document into scope
and retires the previous one from it. That is a rule with a producer, not a hand-maintained skip
list.

**Step 2 — the sweep.** 216 hits, 33 files, and every one is a comment, a docstring or maintainer
prose. Mechanical: apply the published `BRITISH` list with `ALLOWED` removed as whole words first.
Two things to watch, both from `localization-§5`'s exceptions:

- **Blizzard and third-party symbols are reproduced verbatim.** None of the 216 is one — the payload
  scan already proves the identifiers are clean — but the sweep runs over test files full of API
  names and must not touch them.
- **Quoted external text keeps its wording.** `docs/adoption-prompt.md` and
  `docs/adoption-report.md` quote consumer repos' own notes in places. A quote stays; the
  surrounding prose does not.

**Risk:** low, and it is entirely of the *wrong word substituted in a quote* kind. No behavior
changes. **Verification:** the widened gate is green, and a re-run of the audit's own sweep
(`03_EVIDENCE.md` E8) returns 0 for the live buckets.

**If the sweep is declined for `tests/`** — the gate's current comment argues for it — that is a
`## Documented deviations` row in `CLAUDE.md` citing `localization-§5`, naming `tests/` as the
excluded tree, and carrying a re-check trigger. Not a comment in the gate. `library-stack-§7` makes
the register the single home of a ratified decision, and a reason living only in the file it excuses
is what this audit found rather than what it accepts.

---

## LK-29 — two documents describing a lint scope that no longer exists

**Sections:** `documentation-§5`, `lint`. **Files:** `CLAUDE.md`, `DEPENDENCIES.md`.

`M1-LK-12` changed `.luacheckrc` and did not change the two files that describe it. The generated
`RESULTS.md` got it right because it reads the config; the two hand-written copies did not because
nothing reads them.

**Shape of the change.** Replace both passages with wording derived from the generated sentence, so
there is one phrasing and three copies of it rather than three phrasings:

- `CLAUDE.md:176-179` — the figure becomes 51, the exclusion becomes `tests/_kit/`, and the reason
  becomes the real one: the kit is a byte copy of `testkit/`, linted here as source.
- `DEPENDENCIES.md:120` — the inline comment becomes `# 0 warnings / 0 errors, in 51 files`.
- `DEPENDENCIES.md:125-127` — delete *"`tests/` and `docs/` are excluded"*, which is false, and say
  what is actually excluded.

**The structural half, which is the point.** Three copies of one fact will drift again. Two options,
and the second is preferred:

1. Add the figure to `docs/releasing.md`'s step order as a thing to re-read, alongside the standards
   pointer `M1-LK-14` already put there.
2. **Stop quoting the number in prose.** `CLAUDE.md` and `DEPENDENCIES.md` name the *config* and
   point at `RESULTS.md`'s generated line for the count. A document that carries no figure cannot
   carry a stale one, and the count already has a producer.

**Risk:** none. **Verification:** `grep -rn '18 files\|eighteen' CLAUDE.md DEPENDENCIES.md` is
empty, and no document contradicts `.luacheckrc:4`.

---

## LK-30 — the warned-functions watch list is prose where §4 wants a table

**Section:** `automated-tests-§4`. **Files:** `testkit/run-automated-tests.sh`, and by copy
`tests/_kit/run-automated-tests.sh`.

**Shape of the change.** In `fn_table()` (`:556`) and `band_table()` (`:573`), move the header
`printf` above the emptiness guard and drop the `None.` branch:

```sh
fn_table() {
    printf '| Function | CCN | Location | Disposition |\n|---|---|---|---|\n'
    [ -z "$CCN_WARN_ROWS" ] && return
    ...
}
```

An empty table under its header reads correctly — *these are the columns, and nothing crossed* —
and it means a reader diffing two runs sees a row appear rather than a paragraph turn into a table.

**Then the parser.** The runner reads the previous `RESULTS.md` to carry dispositions forward
(`PRIOR_FN`, `PRIOR_BAND`). Check that a header-only table round-trips through it — the current
input for an empty set is the literal `None.`, and the parser must not read a bare header as a
malformed row. Add a case to the kit's own suite for the empty-set rendering, since this is a shape
no consumer can fix locally.

**Blast radius.** `testkit/` is vendored into nine consumers, so this is `Kit.VERSION` 15 → 16, an
API document entry under `docs/api/testkit/`, a `tests/test_kitsync.lua` re-sync, and nine re-vendor
commits. That cost is why this is scheduled with a release rather than on its own.

**Risk:** the runner overwrites `RESULTS.md` in place and `automated-tests-§4` forbids dropping
rows. Verify against a scratch copy before committing, and confirm the run after the change
preserves all 34 table rows.

---

## LK-17d — a disposition 25 release runs past its shelf life

**Section:** `automated-tests-§4`, anti-pattern #53. **Files:** the issue store; then
`RESULTS.md`'s one authored cell.

`tests/test_options.lua` is 1266 lines, under the cap, and the entry is a **band** entry, not a
breach. anti-pattern #53 is not asking for a split; it is asking for the decision to stop being
renewed by default. The repo has already done this twice — #7 for `LibKa0s/Perf.lua`, #8 and #16 for
the two over-cap files — so the shape exists and is proven.

**Shape of the change.** Open one issue, `state:triaged` / `severity:low`, owner `@tusharsaxena`,
carrying what the disposition already knows: the file crossed at `20260807-151331` by one line, the
peel seam is the render/refresh block out to `tests/test_options_render.lua`, and the hard trigger is
`crosses 1500 → split`. Then replace `RESULTS.md:110`'s cell with *"Already tracked as `#NN`"* plus
the seam in one sentence.

**Why the cell may be edited by hand.** `Disposition` is the **one authored cell** in the file
(`automated-tests-§4`, *the one boundary*), and the runner carries it forward verbatim while the
entry is unchanged. This is the sanctioned edit, and it is the only one in this bundle.

**Risk:** none. **Verification:** no cell in `RESULTS.md`'s watch list reads *owed* or *accepted*
without either an issue link or a fresh date.

---

## LK-31 — two deprecated-API owners where `compat` wants one

**Section:** `compat`. **Files:** `LibKa0s/Env.lua`, `LibKa0s/Perf.lua`.

**Shape of the change.** `Env.lua` is already the payload's client-facts owner and already models the
two-rung shim. Add the spec reader beside `lib.GetAddOnMetadata`:

```lua
--- The player's current specialization name, or nil.
--- Namespaced rung first, deprecated global second, nil where neither answers.
function lib.SpecName()
  local getIndex = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization)
                or GetSpecialization
  if not (getIndex and GetSpecializationInfo) then return nil end
  local index = getIndex()
  if not index then return nil end
  local _, name = GetSpecializationInfo(index)
  return name
end
```

`Perf.lua:656-664` collapses to `ctx.spec = Env and Env.SpecName() or "?"`, preserving today's `"?"`
default exactly.

**The dependency this creates, and why it is acceptable.** `Perf` would now floor on
`LibKa0s-Env-1.0`. `library-stack-§7` already permits exactly one second edge beyond Core
(`DebugLog` → `Widgets`), and adding a second is a decision, not a detail: it is a **re-vendor
trigger** and **MUST** be called out as one in the changelog entry. Two ways to avoid it, and the
second is preferred:

1. Take the edge, declare the minor floor, `return` before `NewLibrary` when it is unmet, and say so
   in the changelog. Correct, and it costs every consumer a re-vendor to keep `Perf`.
2. **Promote the shim into `Core`** — nine of the ten majors already floor on Core, so no new edge
   exists and no floor moves. `library-stack-§7` also allows the sibling to keep its duplicate copy
   until a floor raise happens for other reasons, **commented as a deliberate duplication at both
   copies**. That is the cheapest correct answer and it is the one this design recommends.

**Minors and documents.** Whichever placement, the file that gains the member bumps its minor, the
file that loses the inline branch bumps its minor, both get their `docs/api/` entries, and
`tests/test_versioning.lua` will refuse the commit until they do.

**The alternative that is also compliant:** a `## Documented deviations` row citing `compat`,
stating that this library's client-fact shims live at the module that owns the fact rather than in
one file, with a re-check trigger at a third shim. If the placement is deliberate, this is the
change to make — but the current state, where it is deliberate and written only in a code comment,
is neither.

**Risk:** low. The behavior is byte-identical on any client where either rung answers, and a
characterization cases already pin it: `tests/test_perf_core.lua:583` (*"lib: Context captures
character, spec, zone and group"*) and `:599` (*"lib: Context takes the namespaced spec reader before
the bare global"*). **Verification:**
the suite green, the versioning suite green, `03_EVIDENCE.md` E11's grep returns one owner.

---

## LK-32 — a frozen analysis one high on its own figure

**Section:** `automated-tests-§5`. **Files:** none this cycle.

§5 forbids editing a frozen bundle and states the remedy: *"if the reading was wrong, the next run's
analysis says so, and this one stands as what was believed at the time."*

**Shape of the change.** The **next** `ANALYSIS.md` includes one sentence: `20260908-181447`'s
figure of twenty was one high — the measured count was nineteen, which is what its own next sentence
said — and gives today's count.

**Prevention, which is worth more than the correction.** The gap figure is derivable:
`bundles − bundles-with-ANALYSIS.md`, over `docs/automated-tests/`. If the analysis prompt in
`AUTOMATED_TESTS.md` asked for it as a command's output rather than as a count, this class of slip
would not recur. Worth raising upstream when `LK-19`'s release step is written, since both touch the
same prompt.

**Risk:** none.
