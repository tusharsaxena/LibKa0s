# 04 — Technical design

How to close each gap in `02_DEVIATIONS.md`. Keyed to deviation IDs. Nothing here is executed by this
audit.

## Ordering constraints, stated once

1. **LK-16 is upstream of a re-vendor and nothing else blocks it.** It is the only High and the only
   defect in shipped bytes. It should ship on its own minor, ahead of everything below.
2. **LK-21 and LK-22 both change `testkit/run-automated-tests.sh`.** Land them in **one** kit
   revision, not two — every kit revision costs nine consumer re-vendors, and the two edits touch
   adjacent code.
3. **LK-17 must land after LK-18**, or it is regenerated against numbers that are about to change.
4. **LK-24's renormalize touches the whole tree.** Run it last in any sprint, or it buries the real
   diff of everything else.

## LK-16 — the `LSMValues` double-wrap (High)

**Files:** `LibKa0s/OptionsCompose.lua`, `docs/api/Options/`, `CHANGELOG.md`, `tests/test_options_compose.lua`.

`O.LSMValues(mediaType)` is *already* the deferred form: it returns a closure. The composer must hand
that closure to the row, not a closure that returns it.

```lua
-- LibKa0s/OptionsCompose.lua:231, :275, :304
-  values = function() return O.LSMValues("font") end,
+  values = O.LSMValues("font"),
```

**Shape of the change:** three one-line edits. `OptionsCompose.lua` goes to **minor 3**; the Options
major's version key becomes `14.13.3.3` (Options 14 / OptionsWidgets 13 / OptionsCompose 3 /
OptionsScroll 3), so `docs/api/Options/version-14.13.3.3-docs.md` must exist before the release —
`tests/test_versioning.lua:165` will otherwise go red, which is the gate working.

**Risk.** Low, and the low risk is itself worth checking: `enumList` already accepts *"a table, or a
function returning one"*, and `O.LSMValues(...)` is the second of those, so nothing downstream needs
to change. The one thing to confirm is that no consumer has already worked around the defect by
re-pointing the row at its own reader — issue #15 records that **ConsumableMaster did exactly that**,
in `settings/MacroBar.lua`'s `lsmValues`. That workaround must come out in the same re-vendor, or the
addon keeps a private list that no longer tracks LSM registrations.

**LK-16d — the characterization case.** Add to `tests/test_options_compose.lua`, before the fix, so
it is red first:

```lua
test("compose: a media row's values() answers a table, not another function", function()
  local rows = H.FontGroup{ page = "p", group = "g", prefix = "bar." }
  assertEqual(type(rows[1].values()), "table", "enumList calls values() once and needs a table back")
end)
```

Mirror it for `H.BorderGroup` and `H.BarGroup`. This is the mutation the current suite dies under and
does not: `testing-§12`.

## LK-17 / LK-18 — the watch list, and the two over-cap files

**LK-18 first.** `LibKa0s/OptionsWidgets.lua` at 1838 LOC is the shipped one and the one that
matters. `layout-§1` allows peeling into 2–3 siblings in the same folder; the tab-strip block
starting at `:593` (`makeTab`, the label anchoring, the strip packing) is a self-contained surface
and is the natural seam — `LibKa0s/OptionsTabs.lua`, a fifth file of the Options major at minor 1.

**Two constraints that decide the shape:**

- A **new file in an existing multi-file major** must be listed in `LibKa0s/LibKa0s.xml` in dependency
  order and added to `MAJORS` in `tests/run.lua:26+`; `tests/test_versioning.lua` then requires it in
  the changelog block and requires the major's API document at the new composite key.
- `library-stack-§7`'s *"a multi-file major can fail at CALL time"* rule applies: the new file
  attaches to the Options table, so it must re-attach whenever the table underneath it came from a
  different copy — the same pairing `OptionsWidgets.lua` already does.

`tests/test_options_widgets.lua` at 2287 splits along the same seam, into
`tests/test_options_tabs.lua`. Both new suites go into `tests/run.lua`'s declared list;
`Kit.assertSuiteInventory` enforces that in both directions, so a forgotten entry is red rather than
silent.

**Then LK-17.** Regenerate all four standing sections of `RESULTS.md` and both watch-list tables
against the newest bundle. Concretely:

- `:49` and `:58` — 764 cases, 22 suites, the real movement history.
- `:79-81` — 18 files, the 14 in `LibKa0s/` plus 4 in `testkit/`.
- `:119` — the "as of" stamp moves to the newest run.
- The **functions** half of the watch list becomes a real table with the mandated header
  (`Function | CCN | Location | Disposition`) and one row reading *None — highest is `Kit.run` at
  CCN 14*, rather than a prose "**None.**". `automated-tests-§4` mandates *two tables with header
  rows*; a section that says "None" in prose is the ritual without the shape.
- The **band** table gains the `over the 1500 cap` rows for both files, with the peel above as their
  disposition, and drops them again once the peel lands.

**LK-17d.** `tests/test_options.lua` (now 1146 LOC) is owed the issue its row has promised for 23
release runs. Open it with the same shape as #7 and #8 — file, LOC, why a split is declined today,
the peel seam, the 1500 trigger, an owner — and change its disposition to *Already tracked as #N*.

## LK-19 / LK-20 — the release record

**Files:** `docs/releasing.md` only. No code.

Step 7 already runs the bundle (`:76`) and reads the gate (`:88-91`). It needs two additions:

- a sub-step, after the gate read and before the commit: *write `<bundle>/ANALYSIS.md` following the
  root `AUTOMATED_TESTS.md` prompt — totals **and** averages, each suite's figure linked to its
  artifact in the same directory*;
- a sentence making the bundle a **precondition of the tag**, not a companion to it, so a v1.24.0
  cannot recur.

**Explicitly not designed:** backfilling the 17 missing `ANALYSIS.md` files. Frozen runs are never
edited, and a write-up composed four months late is not what §5 asks for. The next release starts the
record; the gap is named in that release's analysis.

## LK-21 / LK-22 — one kit revision, two fixes

**File:** `testkit/run-automated-tests.sh`, then `tests/_kit/` byte-copy, then nine consumer
re-vendors. `tests/test_kitsync.lua` enforces the copy.

**LK-21 — make the lead-in rewritable.** The current structure is: append-if-header-matches /
warn-if-header-differs / create-if-absent. Add a fourth behavior to the *first* branch — when the
header matches, also **replace everything between the H1 and the header row** with the current
lead-in, preserving every row below.

The `MUST NOT` this brushes against is about **dropping rows**, not about refreshing prose: §4 says
*"MUST NOT silently recreate the file when its column set has changed. Rewriting the header drops
every previous row."* Rewriting the prose above a header that already matches drops nothing, and it
is the only mechanism by which nine existing repos will ever get the corrected sentence. The
alternative — a hand edit per repo — is exactly the drift the generated lead-in exists to prevent.

**LK-22 — read and carry the skipped figure.**

```sh
-  line="$(printf '%s\n' "$clean" | grep -oE '[0-9]+ passed, [0-9]+ failed(, [0-9]+ total)?' | tail -1)"
+  line="$(printf '%s\n' "$clean" | grep -oE '[0-9]+ passed, [0-9]+ failed(, [0-9]+ skipped)?(, [0-9]+ total)?' | tail -1)"
```

with `TESTS_SKIP` parsed alongside, the row cell becoming `passed/skipped/total`, the header's
`Tests` column renamed to `Tests p/s/t`, and `suites.tests.skipped` added to the manifest.

**The header rename is the risk**, and it is a designed one: changing the column set trips the
warn-and-leave-alone branch in every repo, and the row for that run is lost to the table (it survives
in the manifest). Either accept one lost row per repo and migrate the headers by hand, or keep the
column name and change only its contents. **Prefer the second** — the header string is not the
contract, the three numbers inside it are — and say so in the kit's changelog so the next reader does
not "fix" the name.

**Kit revision** goes to 15; `docs/api/testkit/version-15-docs.md` must exist
(`tests/test_kitsync.lua` gates it).

## LK-06 — British spelling in the shipped payload

**Two different changes, and conflating them is the trap.**

**The comments and the chat strings** are a plain sweep: `centre/centred → center/centered`
(`Options.lua:118`, `OptionsWidgets.lua:593,596`), `unlabelled → unlabeled` (`Perf.lua:723,864,1029`),
`CANCELLED → CANCELED` (`Perf.lua:948,1063`), `unlabelled → unlabeled` (`OptionsCompose.lua:7`),
`travelled → traveled` (`Widgets.lua:951`). Each touched file bumps its minor; each is a released
change to that file and `library-stack-§7` is explicit that a released change without its bump does
not ship.

**`"minimise"` at `Media.lua:94` is not a sweep** — it is a **public catalog key**, and §7's
additive-only rule says a field *"may be added in a later minor, never removed or repurposed: once
several addons have vendored copies, you cannot know who holds what."* So:

1. Add `"minimize"` as a live key resolving to the same `.tga`. The art file
   `LibKa0s/media/icons/minimise.tga` may keep its name or be added under both; a rename alone breaks
   any consumer that hard-coded the path.
2. Keep `"minimise"` registered, documented as deprecated, for at least one major's worth of releases.
3. Say so in `CHANGELOG.md` and in the Media API document, with the removal condition.

**LK-06d — widen the gate in the same change**, or the sweep regresses on the next feature, which is
the failure `tests/test_prose.lua:4-6` already names. `BRITISH` at `:113` gains at minimum
`minimis`, `centre`, `cancelled`, `labelled`, `travelled`, `organis`, `optimis`, `initialis`,
`customis`, `licence`. Note the false-positive risk each addition carries and record the carve-outs
beside the list as the existing comment already does for Blizzard symbols — `licence` in a vendored
upstream licence header, for instance, which is why `LibKa0s/media/` stays unscanned.

## LK-23 — the deprecated spec API

**File:** `LibKa0s/Perf.lua`, minor bump, re-vendor.

```lua
-  if GetSpecialization and GetSpecializationInfo then
-      local index = GetSpecialization()
+  local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization)
+      or GetSpecialization
+  if getSpec and GetSpecializationInfo then
+      local index = getSpec()
```

Same guarded shape `LibKa0s/Env.lua:60-66` already uses for `GetAddOnMetadata`. Add
`C_SpecializationInfo` to `.luacheckrc`'s `read_globals` beside the existing `GetSpecialization`
entry, with the one-line reason the file's other entries carry.

**Risk.** The headless mock does not define `C_SpecializationInfo`, so the fallback arm is what the
suite exercises today; add a case that defines it and asserts the new arm is taken, or the change is
untested in the direction it was made for.

## LK-24 — the working tree

```sh
git add --renormalize .
git status                          # review
# then, per straggler:
rm <path> && git checkout -- <path>
```

Then re-run `line-endings-§7`'s check (c) and confirm **0**. Two of the seven are shipped payload, so
this also removes a spurious source of byte difference in every consumer's vendored copy.

**LK-24d** — widen `tests/test_eol.lua` from `BUNDLES = "docs/automated-tests"` (`:29`) to the whole
tracked set. The per-path `check-attr` logic at `:60-67` and the byte counter at `:80-89` already
generalize; only `trackedFiles()` at `:37-56` changes, dropping the `-- "<BUNDLES>"` pathspec. Keep
the NUL guard at `:107` — it is what stops the widened gate from reading 130 `.tga` files as text.
The gate's header comment should be updated to say what it now covers, since its current text sells
it as bundle-scoped on purpose.

## LK-25 — the register row

**File:** `CLAUDE.md`, one row, no code.

```
| `performance-§9` | No `tests/perf.lua`; the zero-overhead scenario is not a scenario here | Scenarios stay per-addon (`performance-§9`); the on-path evidence is held instead as a case, `tests/test_perf_isolation.lua:66` — 10,000 dormant Open/Close pairs under 1 KB heap growth | 2026-08-25 | A consumer needs a shared scenario, or the sampler's cost while capture is ON is questioned |
```

and delete the `**None ratified today.**` sentence at `:69`, which becomes false the moment the row
lands. The surrounding paragraph about §7's "does not apply" list not being a register stays — it is
correct and it is the distinction that keeps the register honest.

## LK-26 — the standard-version pointer

`README.md:3` and `CLAUDE.md:3`, `v2.28.0` → `v2.38.0`, in the same commit as this bundle's first
remediation. Add a line to `docs/releasing.md`'s order: *check the pointer against
`WowAddonStandards`' current version*, so it moves on a schedule rather than at an auditor's
discretion. Two copies of one string is drift waiting to happen; if a third place ever wants it,
derive it rather than copy it.

## LK-27 — upstream

Not remediable here. Raise against `WowAddonStandards`: `library-stack-§7`'s applicability lists are
not exhaustive, and twelve sections fall through them. Propose a third disposition —
*"Applies where the rule is about code rather than about an addon's folders"* — naming `layout`,
`architecture`, `performance`, `compat`, `anti-patterns`, `naming-cheatsheet`, `public-api`,
`standalone-windows`, `events-frames-taint`, `debug-logging`, `audit-review-history` and
`open-evolutions`, or state a default and make the two existing lists the exceptions.

While there, two smaller upstream notes worth the same PR:

- §7's module table says **"ten LibStub majors across thirteen files"** and gives Options three files.
  The repo ships **fourteen**: `OptionsCompose.lua` joined the major at minor 1 and is at minor 2 in
  v1.25.0. The standard's own inventory of the library is one file behind.
- §7's "does not apply" list retires `documentation-§3`'s *five verification-and-record docs*,
  including `automated-tests/README.md` and `automated-tests/RESULTS.md` — while `automated-tests`
  sits in the "applies, unchanged" list and mandates both. The requirement survives by a different
  route, which is fine, but the two lists read as contradicting each other and an auditor has to
  reconcile them by hand.
