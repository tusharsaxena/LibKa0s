# Releasing LibKa0s

Two version numbers, one of which is load-bearing at runtime.

| Number | Lives in | Who reads it | When it moves |
|---|---|---|---|
| Repo semver (`v1.55.0`) | git tag, `CHANGELOG.md` heading | humans | once per release |
| File minor (integer) | `MINOR` / `DRAG_MINOR` / `WIDGETS_MINOR` / `TABS_MINOR` / `SCROLL_MINOR` / `COMPOSE_MINOR` / `PANEL_MINOR` at the top of each file in `LibKa0s/` | **LibStub, at load time** | every released change to that file |

The semver tag is a courtesy. The **file minor is the mechanism**: LibStub keeps the highest minor it
is offered for a major and discards the rest, so of the copies vendored across every installed addon,
exactly one wins. A released change that does not bump its file's minor therefore does not ship — any
host already carrying the old copy keeps running it, and nothing errors to say so.

## Order of operations

1. **Make the change**, with its test. Green gate: `lua tests/run.lua` and `luacheck .` (0/0).
   That `luacheck` figure is **scoped by `.luacheckrc`'s `exclude_files`**, not repo-wide — here it
   is eighty files at v1.55.0: everything but `tests/_kit/`, which is excluded only because
   it is a byte copy of `testkit/` and would report every finding twice. A consumer's is scoped too,
   and usually excludes `libs/` and `tests/`. 0/0
   only means something if the files carrying the seam are inside the checked set, so confirm that
   before reading a clean run as a clean adoption.
2. **Bump the minor of every file you changed** — and if you touched `testkit/`, bump
   `Kit.VERSION` too and re-vendor the kit into `tests/_kit/` here before the gate can pass. All
   twenty-one, by their exact constant names: `MINOR` in `Core.lua`, `MINOR` in `Env.lua`, `MINOR` in
   `Compat.lua`, `MINOR` in `Lifecycle.lua`, `MINOR` in `Bus.lua`, `MINOR` in `Schema.lua`, `MINOR` in
   `Pool.lua`, `MINOR` in `Item.lua`, `MINOR` in `Media.lua`, `MINOR` in `DebugLog.lua`, `MINOR` in
   `Slash.lua`, `MINOR` in `Launcher.lua`, `MINOR` in `Options.lua`, `DRAG_MINOR` in
   `WidgetsDragHandle.lua`, `WIDGETS_MINOR` in
   `OptionsWidgets.lua`, `TABS_MINOR` in `OptionsTabs.lua`, `SCROLL_MINOR`
   in `OptionsScroll.lua`, `COMPOSE_MINOR` in `OptionsCompose.lua`, `MINOR` in `Perf.lua`,
   `PANEL_MINOR` in `PerfPanel.lua`, `MINOR` in `Widgets.lua`. The secondary files carry
   their own name rather than `MINOR` because they attach to a shell that already owns that local. A
   file you did not touch does not move. Bumping the whole lib in lockstep would discard the
   narrow-skew property that made one major per module worth having.
3. **A new module is also a new row in `tests/majors.lua`'s `MAJORS`** — its major string, its files in
   `LibKa0s.xml` order, its primary, and any `paired` secondary. `tests/test_versioning.lua` iterates
   that table rather than naming files inline, so a module missing from it is a module nothing
   checks. `LibKa0s-Options-1.0` is the widest row and the one to copy: a `files` list of five and a
   `paired` array of four (`{ OptionsWidgets, __widgetsMinor, __widgetsShellMinor }`,
   `{ OptionsTabs, __tabsMinor, __tabsShellMinor }`,
   `{ OptionsCompose, __composeMinor, __composeShellMinor }`,
   `{ OptionsScroll, __scrollMinor, __scrollShellMinor }`). **A file added to an existing major moves
   that major's version key**, because the key is every file's minor in load order — the Options key
   ran three numbers through 13.12.3, four from 14.13.1.3 and five from 21.20.1.7.3. The table
   carries one row per shipped major — fifteen today, since `LibKa0s-Compat-1.0`,
   `LibKa0s-Bus-1.0` and `LibKa0s-Schema-1.0` at v1.55.0.
4. **Update `CHANGELOG.md`**: the release's version block names each file's new minor, and the entries
   say what changed. `tests/test_versioning.lua` fails if the block and any major's `lib.MODULES`
   disagree, so this is enforced rather than remembered.
5. **Write the API document for every major whose minor moved.** `docs/api/` is the source of truth
   for every public contract, versioned by folder because different consumers run different versions
   at the same time. Copy the current document to a new file named for the new version key —
   `docs/api/<Major>/version-<minors>-docs.md`, the minors joined in load order exactly as
   `lib.MODULES` reports them — then:
   - in the **new** document: `Status` → **Current**, fill in `Supersedes`, write the
     *What changed at this version* section, and give every member, descriptor field or row field the
     bump introduced a `Since` of the new minor;
   - in the **old** document: `Status` → Superseded, fill in `Superseded by`, and add the closing
     *Moving to …* section;
   - add the row to the table in [`api/README.md`](api/README.md).

   Never edit a superseded document to describe new behaviour — an adopter still on that copy has to
   be able to read what their copy actually does. A minor bump is not released until its document
   exists, and since v1.8.0 that is a gate rather than a rule:
   `tests/test_versioning.lua` derives `docs/api/<Major>/version-<minors>-docs.md` from each major's
   live `lib.MODULES` and fails naming every major whose document is missing — the same bargain
   `tests/test_kitsync.lua` strikes for `Kit.VERSION`. Bump a minor and the suite is red until the
   document is written, so step 7's green gate cannot be reached without it.

   **Then regenerate the member manifests**, in the same commit as the document:

   ```sh
   lua tools/gen-api-members.lua
   ```

   That writes `docs/api/<Major>/members-<version-key>.json` for every major — the public surface as
   data, which is what the eleven addons' degradation stubs are checked against by
   `Kit.assertSurfaceParity(stub, majorName)`. It is a generated file and never hand-edited, and
   `tests/test_versioning.lua` regenerates and compares it on every run, so a bumped minor whose
   manifest has not been written is red for the same reason a bumped minor with no document is.
6. **Regenerate the case list**: `lua tests/run.lua --list` into `docs/test-cases.md`, keeping CRLF
   (see that file's own banner for the exact command).
7. **Move every version-bearing line to the version being released, then prove the tree.** Two
   hand-maintained pointers move here and nothing reads either of them, which is exactly why they
   are inside a numbered step: both have already drifted, and neither drift was visible until
   somebody went looking.

   **The provenance template in this file** — the templated line under "Re-vendoring consumers"
   below, and the repo semver in the table at the top. It moves here, before the tag, so the tagged
   commit already says what it bundles and step 8 is a copy rather than a recollection. This is part
   of the step because the alternative is remembering, and at v1.5.0 the remembering did not happen:
   the template still read v1.4.0 while every consumer had been updated correctly by hand.

   **The standards pointer**, in `README.md`. It names the version of the Ka0s WoW Addon Standard
   this library is built to, which `library-stack-§7`'s *Substitutes* list requires of a library
   README. `CLAUDE.md` names the standard and **no version** of it, on purpose: `documentation-§6`
   asks for none there, and a second copy of the number is a second place for it to go stale. Check
   the README against the source, here, rather than leaving it to the next audit:

   ```sh
   head -1 ../WowAddonStandards/standards/STANDARDS.md
   grep -n 'v2\.' README.md | head -1
   ```

   The version the first prints must be the version the second carries. When the
   2026-09-07 review looked, `CLAUDE.md` and `README.md` both read v2.28.0 against a live v2.38.0 — ten versions of the standard
   — while `OptionsCompose.lua` cited `options-ui-§15`–`§18`, sections that arrived at v2.38.0 and
   did not exist at the version the two files claimed the library was built to. Moving the number is
   half of it: read what changed in the standard between the two, because a pointer that moves
   without anyone reading the diff lies more confidently than one that is merely stale.

   **Then the record, and the tree it is taken from.** Green gate again, then commit everything
   above — the whole release except its own evidence. The tree must be clean before the next
   command: since kit revision 15 the runner **refuses** `--release` on a dirty tree and exits 2
   before a suite runs, and there is no override flag.

   ```sh
   git status --porcelain                                # must print nothing
   tests/_kit/run-automated-tests.sh --release <X.Y.Z>
   ```

   Then a **second** commit carrying the bundle and its `RESULTS.md` row, and the tag on that. Two
   commits rather than one, deliberately: the manifest names the sha its suites actually measured,
   and the tagged tree still contains the evidence for itself. The two trees differ by the record
   and nothing else. Taking the run first and committing everything together is what produced the
   history this order replaces — of this library's twenty-nine release bundles, twenty-eight record
   `"dirty": true`, and `20260903-161751` stamps `"release": "1.25.0"` at sha `895cdf4`, a tree
   nobody can check out. Each of them reads, from a trend line, exactly like a reproducible run.

   The run itself is a step, not a nicety. Every other repo in the collection gets its release
   bundle from `/wow-addon:bump-version`; this repo has no such command and this order was the only
   place the run could be written down, so until v1.8.0 it was written down nowhere. The cost is on
   disk: the one bundle taken before this step existed, `20260805-002859`, carries `"release": null`
   on a commit later than `v1.7.0^{}` — it records a working tree nobody released rather than the
   bytes anyone got. **v1.8.0 is the first release of this library with a test record naming it.**
   `--release` is what ties a bundle to a version; without the flag the field stays null however
   carefully the run is timed.

   **The tag's preconditions, and they are hard.** Read them off the manifest the run just wrote —
   the file, not the console text, and not a memory of the console text:

   ```sh
   S=docs/automated-tests/<stamp>/manifest.json
   jq -r '.release'                     "$S"    # the version being tagged, never null
   jq -r '.git.dirty'                   "$S"    # false
   jq -r '.git.sha'                     "$S"    # the commit being tagged, or its parent
   jq -r '.suites | to_entries[] | "\(.key) \(.value.status)"' "$S"
   jq -r '.suites.complexity.warnings'  "$S"    # 0
   ```

   `lint`, `tests` and `complexity` must read `pass` and `complexity.warnings` must be zero — no
   function above CCN 15 (`automated-tests-§3`, *The release gate*). A `skip` is NOT EVALUATED
   rather than passed. `perf` is the one standing `skip` here, because this repo ships no
   `tests/perf.lua`; that is a known and recorded hole in the gate rather than a pass — see
   [`automated-tests/README.md`](automated-tests/README.md). **No tag is cut without a bundle whose
   `release` field names it.** `v1.24.0` is the reason that sentence is here: the tag exists, the
   bundles jump 1.23.0 to 1.25.0, and there is a released version of this library whose test record
   does not.
8. **Re-vendor every consumer** — see below. This is part of the release, not a follow-up, and it
   includes bumping the version named in each consumer's `CLAUDE.md` provenance line, in the same
   commit as the copy.
9. **Re-sweep the Consumers table against the source**, because it is maintained by hand and the
   wiring is not:

   ```
   for a in AbsorbTracker AuraMaster BankLedger ConsumableMaster KickCD LootHistory MultiMeters PanelMaster PartyFrameEnhanced PrettyChat WhatGroup; do
       grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' ../$a --include='*.lua' \
         | grep -v '/libs/' | grep -v '/tests/'
   done
   ```

   Every file that prints must appear in the table's third column. A second lookup site nobody
   recorded is a file the checklist never points a reviewer at — which is exactly how
   AbsorbTracker's `settings/Schema.lua` went unnamed until the 2026-08-01 v2 adoption run.

## Re-vendoring consumers

Two payloads, with different destinations and different reasons for existing.

**The library** is the inner `LibKa0s/` folder and nothing else — the twenty-one `.lua` files, the
`.xml`, `LICENSE`, and since v1.9.0 the `media/` subtree. The license lives in the ship folder so
that every `cp -r` carries the MIT notice into the consumer's zip with no per-addon step;
`LibKa0s.xml` does not load it and nothing else needs to know it is there. `docs/`, `README.md`,
`CHANGELOG.md` and `tools/` stay here — they describe or produce the payload, they are not part of
it.

**`media/` is the first payload that is not code** — `icons/`, `textures/` and `fonts/` —, and it changes two things about copying. The
`cp -r` is unchanged — it already recurses — but the consumer-side gate was not: until **kit revision
11** `vendor_sync.lua` listed one directory level and normalized line endings on everything, so it
read `media` as a file and would have mangled the comparison of any binary containing the byte pair
`0D 0A`. **A consumer re-vendoring v1.9.0 or newer must take kit revision 11 in the same commit.**
One older-payload rule still holds: art is regenerated by `tools/artwork/icon_cleaner.py` here and
committed here, never edited in a consumer.

```
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

Then add or update the provenance line in `<Addon>/CLAUDE.md`, in the same commit as the copy:

> Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.55.0 (MIT).

The version in that template is **the one being released**, not a literal to copy — at v1.5.0 the
line reads v1.5.0, and this template moves with it rather than being corrected after the fact. That
is step 7's job, and it is a step because at v1.5.0 it was a memory and the memory failed.

**`CLAUDE.md`, not `README.md`, since kit revision 9 (v1.8.1).** The line answers "which LibKa0s does
this build carry?", which is a maintainer's question on a page written for players — and `README.md`
across this collection no longer carries a bundled-library inventory at all. `vendor_sync.lua` reads
`CLAUDE.md` by default and takes a `provenanceFile` opt for a repo that keeps it elsewhere. There is
**no fallback**: a repo whose line is still in `README.md` reads as carrying none and fails, rather
than sitting half-migrated with two lines that can disagree.

What the template fixes is the **shape, not the wording**. A line that names the library and names
the version satisfies it wherever it sits in a sentence: some repos phrase it mid-sentence
(*"…it bundles [LibKa0s](…) v1.5.0"*) and that is equally correct. The gate greps `[Bb]undles`
for precisely that reason — an earlier capital-anchored sweep returned nothing for a repo that wrote
it mid-sentence and reported it as carrying no provenance line at all, which it has always had. So
both phrasings pass, and a consistency sweep that rewrites them to match the template above is
spending effort to make two true lines look alike.

That line is not decoration. Every consumer's `tests/test_vendor_sync.lua` READS it, resolves the tag
it names, and asserts both `libs/LibKa0s/` and `tests/_kit/` match the library repo **at that tag**,
file by file. So a provenance line that is ahead of the tag, or a re-vendor taken from untagged
`master`, fails there — which is exactly how the untagged kit revision was caught. Re-vendor from a
tag, and move the line in the same commit.

That line is part of the re-vendor, not a follow-up to it. It is the only artefact that answers
"which LibKa0s does this addon carry?" without grepping eight minor constants out of the vendored
source, and it is only true if it moves with the bytes — and only checkable if step 7's tag exists,
which is why the tag is not the optional half of that step.

**Run both diffs, and read the difference between them.** The first compares content with CR
ignored; if it reports anything, a copy has genuinely forked and re-vendoring is the fix. The second
compares raw bytes. If the first is empty and the second is not, **nothing has forked** — the two
checkouts merely disagree about line endings, which every repo here pins to CRLF via
`.gitattributes` and which `git status` will never show you, because the blobs are LF on both sides
either way. The fix is to renormalise whichever side drifted (`git add --renormalize .`, and if the
working tree does not flip, delete the affected paths and `git checkout -- .` to pull them back
through the filter). It is **never** an edit to `libs/`. Editing `libs/` to settle a line-ending
disagreement creates a fork to fix a fork that was not there.

**The test kit** is `testkit/`, and it goes to `<Addon>/tests/_kit/` — never to `libs/`, because
`libs/` is the ship payload and the kit must never be zipped. Under `tests/` it is already covered
by the `- tests` entry every addon's `.pkgmeta` already carries, so adopting it needs no packaging
change.

The kit carries its own revision, `Kit.VERSION` at the top of `framework.lua`, exposed to suites as
`KIT_VERSION`. It is **not** a LibStub minor and nothing negotiates on it — the gate below is still
byte-identity — but it names which copy a consumer holds, and it names that copy's API document
under [`api/testkit/`](api/testkit/). **Bump it on every released change to any file in `testkit/`,
and write the document for the new number**; `tests/test_kitsync.lua` fails if the document for the
live revision is missing, the same bargain `tests/test_versioning.lua` strikes for the library's
minors in step 5. That parity is real as of v1.8.0 and was not before it: this sentence claimed it
while `test_versioning.lua` checked `CHANGELOG.md` and nothing else, so step 5 was a rule nothing
enforced. The gate now exists — see step 5.

```
cp -r testkit/. <Addon>/tests/_kit/
diff -r --strip-trailing-cr testkit <Addon>/tests/_kit   # content — MUST be empty
diff -r testkit <Addon>/tests/_kit                       # bytes  — SHOULD be empty
```

The same reading applies: content-empty and bytes-nonempty is a line-ending divergence, fixed by
renormalising the side that drifted, never by editing the vendored copy.

In THIS repo the same check is mechanical rather than remembered: `tests/test_kitsync.lua`
compares `testkit/` against `tests/_kit/` byte for byte — every file, README included, with no
line-ending normalisation — and names the file that drifted. It exists because the commit before
it shipped a `testkit/README.md` that was never re-vendored while three documents asserted the
gate was passing; both copies worked and both suites stayed green. A consuming addon has no such
gate yet, so downstream the `diff -r` above is still yours to run.

Rules, and the reason each exists:

- **Copy the WHOLE folder, always. Never one module.** With one major per module and independent
  minors, per-module re-vendoring is exactly how cross-major skew gets manufactured: an addon ends
  up carrying a new `Perf.lua` over an old `Core.lua`, or a `Core.lua` that never arrived at all.
  The only negotiation between majors is a floor — a dependent file names the minimum minor it needs
  (`NEEDS_CORE`, at the top of every major's primary file but Core's — `Env.lua`, `Compat.lua`,
  `Lifecycle.lua`, `Bus.lua`, `Schema.lua`, `Pool.lua`, `Item.lua`, `Media.lua`, `Widgets.lua`, `DebugLog.lua`, `Slash.lua`, `Launcher.lua`,
  `Options.lua` and `Perf.lua`)
  and returns
  before `NewLibrary` if the dependency is missing or older, so the module is **absent** rather than
  half-wired. That is the honest failure, not a working one: the host's setup file reports the
  library as missing and falls back. Nothing negotiates the other direction, and the four
  paired-minor guards that protect a secondary file within a major (`OptionsWidgets`,
  `OptionsTabs`, `OptionsCompose`, `OptionsScroll`, `PerfPanel`) do not generalise across them. Whole-folder copying is the
  mitigation.
- **A partly-copied `LibKa0s-Options-1.0` fails at CALL time, not at load time.** FIVE files since
  v1.39.0. The other majors
  fail loudly and early; this one does not. If `Options.lua` itself is missing or refused, all three
  attach files bail on their own `LibStub("LibKa0s-Options-1.0", true)` lookup and the module is
  cleanly absent. But if only one of `OptionsWidgets.lua` / `OptionsTabs.lua` /
  `OptionsCompose.lua` / `OptionsScroll.lua` fails to arrive, `lib:New` still succeeds — the shell
  guards each attach step with `if lib.__AttachWidgets then … end`, `if lib.__AttachTabs then … end`,
  `if lib.__AttachCompose then … end` and `if lib.__AttachScroll then … end` — and the host holds an
  instance that looks whole until something calls `O.AttachTooltip`, `O.TabStrip`, a composer such as
  `O.MasterControls`, or `O.PatchAlwaysShowScrollbar`, which may be a panel build away. The two
  cross-file calls between `OptionsWidgets.lua` and `OptionsTabs.lua` are themselves guarded and
  degrade rather than raise (a tabbed page renders untabbed; a banner loses its tooltip), which
  narrows that window without closing it.
  Five files, one major, one copy.
- **Raising a dependency floor is a breaking change to the vendoring, not to the API.** If a change
  to `Perf.lua` needs something Core only gained this release, `NEEDS_CORE` moves with it — and every
  consumer whose `libs/` still holds the older `Core.lua` loses the whole module until it is
  re-vendored — which is another way of saying the floor is only ever safe because step 8 is not
  optional.
- **The vendored copy MUST be identical to the ship folder in content, and SHOULD be identical in
  bytes.** Both diffs above, every time. A hand-patched `libs/` copy is a fork nobody knows about —
  but a CR-only difference is not one, and treating it as one is how a `libs/` edit gets
  rationalised.
- **A library change MUST be followed by a re-vendor commit in every consumer that depends on it**,
  and that commit SHOULD be its own, so the sync is legible in history rather than buried in a feature
  diff.
- **This is the step that gets forgotten.** It already happened once, during the extraction that
  created this library: a fix landed here, AbsorbTracker was not re-vendored, and both repos' test
  suites stayed green the whole time — the library's tests passed against the library, and the addon's
  tests passed against a stale copy that still worked. An `after-the-fact` `diff -r` was the only
  thing that caught it. Nothing about "the tests are green" will tell you the copies have diverged.

Vendoring a third-party library is a one-time copy that stays stable for months. Vendoring a library
you also author is an ongoing **sync**, and the drift window is a single afternoon.

## Consumers

Tracked **per module**, because addons adopt modules independently. Step 8 re-vendors the whole
folder into every addon in this list whatever changed; the per-module column is the other question —
which hosts' descriptors a change to one module can reach.

| Module | Consumers | Where the wiring lives |
|---|---|---|
| `LibKa0s-Core-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup, AuraMaster, PartyFrameEnhanced | `core/CoreSetup.lua` (all eleven). PrettyChat is the **first host to pass `sep = ""`** — its `[PC]` tag bakes its own trailing space, so the default `" "` would double-space every line it prints. It also **declines the window-chrome half** for the same reason PanelMaster does: its only window is the debug console, which reaches Core's chrome from inside the DebugLog major. PanelMaster **declines the window-chrome half** (`SKIN`/`ApplySkin`/`MakeCloseButton`): its only standalone window is the debug console, which reaches Core's chrome from inside the DebugLog major |
| `LibKa0s-DebugLog-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup, AuraMaster, PartyFrameEnhanced | `core/DebugLogSetup.lua` (all eleven) — ConsumableMaster's was at `modules/DebugLog.lua` when this table was written and is not there now; that file no longer exists, and the lookup is at `core/DebugLogSetup.lua:59` with everyone else's. PrettyChat passes **none** of `skin` / `applySkin` / `makeCloseButton` and deleted a 424-line hand-written console to take the library's edge as-is — the first adoption where the Core-minor-3 default *was* the answer rather than something to override. **LootHistory is the second host on minor 4's `applySkin` — and both it and BankLedger have since dropped `makeCloseButton`, which as of v1.5.0 has no consumer at all** — it asserts the derived title-bar offsets rather than assuming them |
| `LibKa0s-Slash-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup, AuraMaster, PartyFrameEnhanced | PrettyChat: `settings/Slash.lua`, **plus a second lookup at `settings/Schema.lua`** — the same shape as AbsorbTracker's and found the same way, by the sweep above. `Schema.FormatValue` is the addon's ONE value renderer, and it has two consumers that are not both CLI surfaces: the descriptor's `format` hook and the `[Set]` debug trace at the write seam, so it lives beside the rows rather than in the slash file. PrettyChat is also the **second host on minor 5's `format` hook and the first to use it on a row type the library can already render** — the case this doc listed as untried: it doubles `\|` to `\|\|` so a Blizzard format string's colour escapes read as text instead of colouring the chat line, delegating to `lib.FormatValue` first so the empty-string `(none)` stays the library's. Its `parse` adapter exists for a **gap**, not an exotic type — see the note under the table. `settings/Slash.lua` (AbsorbTracker, KickCD, BankLedger, LootHistory, MultiMeters, WhatGroup, AuraMaster) — LootHistory is the **second host on minor 5's `format` hook**, for the same set-valued row shape BankLedger drove it for; ConsumableMaster: `settings/Slash.lua` — moved there from `core/SlashCommands.lua` (CM-47/CM-54); this table said the old path until the v1.7.0 sweep, which is what the step-9 re-sweep is for. PanelMaster: `settings/Slash.lua`, and it is the **first host to pass a descriptor `L`** — a plain one-key table (`RESET_ALL`), so the override path is now exercised as well as the fallback; it also carries a `parse` adapter that up-cases enum input before delegating to `lib.ParseValue`. AbsorbTracker has a **second** lookup at `settings/Schema.lua`, stashed at file load so `NS.FormatSchemaValue` can call `lib.FormatValue(row, v)` — the seam every panel widget and every `/at set` renders through PartyFrameEnhanced: `settings/Slash.lua`, **plus a second lookup at `settings/Schema.lua:294`**, found by the v1.37.0 sweep. |
| `LibKa0s-Launcher-1.0` | AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | `core/LauncherSetup.lua` (all eleven). **This cell read "none yet" until the v1.42.0 sweep**, three releases after the major shipped at v1.39.0 and after every host had adopted `launcher-§5` — the third time this table has carried that error, for the reason its own warning gave: a major that lands everywhere at once has no first host to prompt a revisit. AbsorbTracker has a **second lookup at `core/Constants.lua`**. | 
| `LibKa0s-Options-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup, AuraMaster, PartyFrameEnhanced | AuraMaster: `settings/OptionsSetup.lua`, decorated by its page files under `settings/`, which call the composers at file load; it passes `skipRestoreAll` to veto the Profiles page and every profile-backed row. PrettyChat: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. It **declines `RestoreDefaults` / `RestoreAllDefaults`** — both are row-by-row over ~171 rows, which would run its `ApplyStrings` once per row and emit one `[Set]` line per row into a 500-line console buffer; its own batch resets stay, reached through `defaultsOnClick` so `CreatePanel`'s `OnDefault` forwarding still makes the footer control and the header button one body. Its per-string editor is an AceGUI `TreeGroup` — a 200px list of the category's format strings beside one full-width editor — that `RenderGrid` cannot express either (HALF or full width, no third ratio). LootHistory: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. BankLedger: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. AbsorbTracker: `settings/OptionsSetup.lua` + `settings/UnitPanel.lua`. KickCD: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, `Panel_Widgets.lua`, `Panel_Render.lua`. ConsumableMaster: `settings/OptionsSetup.lua`, the only place the instance is built, with the addon's own half in `settings/Panel.lua` — this cell named `settings/Panel.lua` alone until the v1.30.0 sweep. MultiMeters: `settings/OptionsSetup.lua`, decorated by fourteen page files under `settings/` (`Bars`, `Columns`, `Data`, `Frame`, `General`, `Header`, `Icons`, `Profiles`, `Rows`, `Text`, `Tooltip`, `Visibility`, `Windows`, `Schema`) — the widest decoration surface of any host, and the reason its descriptor reaches the instance through a `helpers()` accessor at call time (`settings/OptionsSetup.lua:36`) rather than capturing a member: every one of those files runs after the seam. It has a **second lookup at `settings/Schema_Compose.lua:463`**, guarded on `__AttachCompose`, for the composer products that forward to `NS.Helpers` at call time. It passes `skipRestoreAll`, vetoing the Profiles page from Restore All because those rows are AceDBOptions' and resetting them deletes profiles — this cell called it the only host to do so, but AbsorbTracker, KickCD and AuraMaster pass it too. PanelMaster: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, which **wraps `RenderField` and `EnsureScroll` on the instance** for its own open-dropdown registry — the first host to need either. WhatGroup: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, and it is the **second host to wrap instance members** — `SetRenderer` and `EnsureDefaultsButton`, so both the page body and the Defaults button build on the NEXT frame rather than synchronously inside `OnShow`. It is a taint fix that addon had already shipped: Blizzard's GameMenu / Logout flows can dispatch a settings canvas's `OnShow` inside a secure-execute chain. Wrapping on the instance is load-bearing for the same reason it was for PanelMaster — `SetRenderer`'s handler resolves `EnsureDefaultsButton` from the instance at call time PartyFrameEnhanced: `settings/OptionsSetup.lua`. **The two `testModePath` adopters (compose minor 6, v1.37.0)** are PartyFrameEnhanced (`state.testMode`, replacing a `leadButton`) and AuraMaster (`state.preview`, moved from a hand-written Display-tab row, its degradation stub mirroring the row). PanelMaster, KickCD and ConsumableMaster drop the row under the standard's v2.49.0 exemption (an addon whose unlocked view is its preview omits Test mode); AuraMaster no longer does — unlocking a container leaves it draggable with its live auras still drawing (B1, 2026-09-19), so the unlocked view is no longer a preview and the exemption no longer applies. `settings/General.lua` composes the row again, now on `state.testMode`: a SESSION row driven by `/am test` and the launcher's left-click, both reaching `modules/Preview.lua`'s `Preview.SetTestMode`. AuraMaster is also the **first host on OptionsWidgets minor 21's `removeStyle = "icon"`** — the X moves to the left of every entry on its `IdList`s in `settings/GeneralSpells.lua` and `settings/Filters.lua`. `shownWhen` (minor 22): Aura Master (`settings/Layout.lua`, Layout → Anchor) and Party Frame Enhanced (`settings/ElementRows.lua`, Size & Position, pending its merge). |
| `LibKa0s-Media-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup, AuraMaster, PartyFrameEnhanced | `core/MediaSetup.lua` (all eleven; AuraMaster's came with the addon, not with the v1.9.0 pass). **This row did not exist until the v1.15.0 sweep** — the major shipped at v1.9.0, went into every consumer in the same pass, and was never added here, which is precisely the failure the re-sweep exists to catch: nine wiring sites the table pointed a reviewer at zero of. There is no first host and no second host to name, because it landed everywhere at once. Two hosts reach it for more than the font: MultiMeters resolves an icon per call site rather than caching one (`modules/Export.lua:1323`), and it is `core/LSMPatch.lua`'s reason for existing — the bar textures the library owns are registered into LibSharedMedia by the library, not by the addon. LibSharedMedia itself is OPTIONAL to the major (`LibKa0s/Media.lua:48`), so a host that has it gets the registrations and a host that does not still gets the paths |
| `LibKa0s-Widgets-1.0` | BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters | **KickCD was missing from this row until the v1.30.0 sweep**: `settings/Spells.lua` looks the major up twice, at `:740` to read the handle gutter off `ROW_BOX.HANDLE_W` rather than restating it, and at `:1001` for `ReorderList`. **ConsumableMaster joined at v1.19.0**, on `ReorderList`: `settings/Category.lua`, which drags a priority row to a new position, **plus a second lookup at `settings/StatPriority.lua:122`** for the same member, which reads its handle width the same way Category does, **and a third at `settings/MacroBar.lua:723`** for the Macro Bar's Buttons tab, which drags the bar's slots with the shown ones ahead of a dimmed hidden group (added by the v1.34.0 sweep). It is the second consumer that minor 8 waited for — MultiMeters had recorded the deviation of keeping the widget local, with "a second addon wants an orderable list" written in as the condition that ends it. MultiMeters has a **second lookup at `settings/ColumnBlocks.lua`** for the same member, and the two adopt it from opposite directions: MultiMeters' list has two groups and a clamp at the divide, ConsumableMaster's is flat. Between them they are why the member owns the gesture and no row content — their rows have nothing in common. BankLedger: `modules/Browser.lua`, which is where this widget was lifted FROM — its adoption at v1.11.1 is what found `CloseMenu()`, **plus a second lookup at `modules/Export.lua:14`** for `CloseMenu()` alone: the popup is a process-wide singleton parented to UIParent, so the export modal's own `Hide()` does not reach it. LootHistory: `core/WidgetsSetup.lua:85`, the only host to put the lookup behind a NAMED seam file rather than in the surface that draws — `NS.MakeDropdown`, `NS.HasWidgets` and `NS.CloseMenu`, with `HasWidgets` existing so a surface whose only control is a dropdown can learn of a degraded install BEFORE it builds a globally-named frame it would then have to leak. MultiMeters: `modules/Export_Modal.lua` (the lookup moved there from `modules/Export.lua`), the second adopter and the reason the widget was lifted at all; it drives two dropdowns from one export modal and calls `CloseMenu()` on that modal's hide. All of them look the major up once at file load and refuse to draw the surface at all when it answers `nil`. **None passes `glyphFont`** — the glyph column is BankLedger's store-direction case and nothing in either shipped host uses it today, which is why v1.11.0's and v1.11.1's crash on the first click reached both of them and was found by neither's suite |
| `LibKa0s-Perf-1.0` | AbsorbTracker, KickCD, ConsumableMaster, MultiMeters, AuraMaster, PartyFrameEnhanced | `core/PerfSetup.lua` (all six; AuraMaster's is built at file load, ahead of every module that takes `NS.Perf` as a load-time upvalue) — ConsumableMaster's was at `modules/PerfSetup.lua` when this table was written and is not there now. MultiMeters is the host with the deepest bucket tree, and the only one that NESTS: `renderRow` sits inside `render` because 20 players times 7 columns is 140 cells a pass, and per-row is the only grain at which "the window is slow" becomes "the window is slow because of how many rows it has" (`core/PerfSetup.lua:30-40`). A reader must never sum a parent with its children. **Declined** by BankLedger (`LIBKA0S-17`), PanelMaster (`LIBKA0S-31`), PrettyChat (`LIBKA0S-12`) and WhatGroup (`LIBKA0S-15`), all on structural grounds — none has work that runs inside a combat-gated measurement window. WhatGroup declines on two independent reasons: no hot path (zero `OnUpdate`; its one repeating timer, added 2026-08-06, is the teleport-cooldown countdown, armed only while its popup is on screen and doing one cooldown read and one `SetText` a second; otherwise a combat-gated window reaches a roster handler that fires zero times on most pulls and a combat-edge visibility check), **and** the suspend contract — it is a CAPTURE addon, so an inert arm means an LFG apply or an invite-accept inside the window is never recorded and the popup the player joined for silently does not appear. That second reason is LootHistory's, arrived at independently. PrettyChat is the strongest case of the three: a whole-repo sweep finds **zero** `OnUpdate` handlers and tickers, and its only event registration is an opt-in combat-boundary watcher (armed only for the two combat-scoped visibility modes, firing at most twice per fight) beside one one-shot `C_Timer.After(0, …)` on the settings-panel render path, so every bucket would read `0.000` by construction — and its `suspend` would have to restore Blizzard's own chat formats for the duration of the window, visibly flipping the player's chat mid-fight for a capture that can only report zero |
| `LibKa0s-Lifecycle-1.0` | AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PartyFrameEnhanced, PrettyChat, WhatGroup | `core/LifecycleSetup.lua` (ten of the eleven; **AbsorbTracker's is `core/Lifecycle.lua`**), beside `core/PerfSetup.lua`, which is the seam this major generalizes. Three hosts reach it a second time: AuraMaster from `core/PerfSetup.lua` and `modules/ContainerManager.lua`, PrettyChat from `modules/Override.lua` and `settings/Schema.lua`, WhatGroup from `core/WhatGroup.lua`. **This cell read "none yet" until the v1.42.0 sweep**, a release after every host had wired it — the fourth time this table has done that, after Media, Env and Launcher. |
| `LibKa0s-Env-1.0` | AbsorbTracker, AuraMaster, BankLedger, ConsumableMaster, KickCD, LootHistory, MultiMeters, PanelMaster, PrettyChat, WhatGroup, PartyFrameEnhanced | `core/EnvSetup.lua` (all eleven). **This row read "none yet" until the v1.19.0 sweep**, which is the second time this table has carried that exact error — the Media row did it at v1.15.0, and the note there says why: the major landed everywhere at once, so there is no first host to notice and no second host to prompt a revisit. A row claiming no consumers is worse than a row that is merely stale, because it reads as a decision rather than as an omission |
| `LibKa0s-Pool-1.0` | BankLedger, LootHistory, MultiMeters, KickCD, AuraMaster | All five look it up in `core/PoolSetup.lua` and expose it as `NS.Pool`, each keeping a local fallback so a degraded install still pools rather than allocating a frame per row per refresh. BankLedger: five sites across four files — `modules/LedgerTable.lua` and `modules/SessionWindow.lua` row pools, plus `modules/Insights.lua` and `modules/InsightsWidgets.lua`, where a nested `ReleaseAll(pool, fn)` hook releases each panel's `_rows`. LootHistory: the heaviest consumer and the leak that motivated the module — `modules/BrowserTable.lua`'s row pool plus ~36 array pools in `modules/Analytics.lua` (bars, swatches, legends, list rows). MultiMeters: `modules/Window.lua`, and the ONLY consumer that takes position from acquire order — the pooled object is the row TABLE, not the frame it wraps, with `row:Release()` as the `before` hook. It is why minor 3 exists: see the CHANGELOG. KickCD: the only KEYED consumer — `modules/IconGrid.lua` keys buttons by spellID through `NewKeyed`/`AcquireKeyed`/`ReleaseAllKeyed` so a cooldown message reaches one widget without a scan, which is why `NewKeyed` was added at minor 2. AuraMaster: an array pool per container for the preview's placeholder elements, with `modules/Preview.lua` its only caller. The live aura buttons are Blizzard's and never come from the pool. **Ordering matters to two of them.** Minor 3's guarantee — a position gets its own object back — is load-bearing for MultiMeters and for AuraMaster, where a re-dressed preview keeps every placeholder in the slot it held (its local fallback reproduces the same backward release). It is inert for the three whose redraws are event-driven and whose figures are plain, and meaningless for KickCD, where the key is the mapping |
| `LibKa0s-Item-1.0` | BankLedger, ConsumableMaster, LootHistory | `core/ItemSetup.lua` (all three). The adoption plan named BankLedger and LootHistory; **ConsumableMaster is a third that arrived without one**, which is the sort of thing only this sweep finds. MultiMeters is a deliberate NON-consumer and says so upstream — a damage meter has no item surface — so its absence here is a decision rather than a gap, unlike the six addons that simply have no reason to look it up |
| `LibKa0s-Compat-1.0` | None yet — adoption pending | New at v1.55.0. The copies it replaces are the hosts' own `core/Compat.lua` and, in AuraMaster and MultiMeters, `core/Secrets.lua`; a host keeps calling `NS.Compat.X` / `NS.Secrets.X` and only the definitions move ([Adopting it](api/Compat/version-1-docs.md#adopting-it)). |
| `LibKa0s-Bus-1.0` | None yet — adoption pending | New at v1.55.0. The stand-down record replaces the hand-written ones in PartyFrameEnhanced, AbsorbTracker, ConsumableMaster and MultiMeters; `Catalog` is open to every host that declares `Ka0s_<Addon>_<Event>` constants ([What this major is](api/Bus/version-1-docs.md#what-this-major-is)). |
| `LibKa0s-Schema-1.0` | None yet — adoption pending | New at v1.55.0. Each host's `settings/Schema.lua` keeps its rows and hands the runtime to this major; the behavior a host crosses on adoption is listed in [Adoption notes](api/Schema/version-1-docs.md#adoption-notes). |

**A gap the Slash consumers had, found by PrettyChat and closed at Slash minor 10 (v1.34.0).**
Through Slash minor 9, `lib.ParseValue` split the remainder on whitespace and a `string` row took the
first token, so a free-text row could not hold a value containing a **space**: `/pc set <path> You
receive loot: %s` stored `"You"`, and an enum entry with a space in it (an LSM font name) could not be
set at all. The value was stored, no error was raised, and only the echo showed the truncation.
PrettyChat supplied a descriptor `parse`, which slash-commands-§6 sanctions; the same bug later
reached AuraMaster's `container.name`, found by a test agent. From Slash minor 10 a `string` row
takes the whole remainder, trimmed at both ends, and an enum is matched on the full string.
PrettyChat's adapter keeps its `||` unescape; its whitespace half is redundant from v1.34.0.

AbsorbTracker vendors to `libs/LibKa0s/` and is consumer #1 for the five it drove — Core, DebugLog, Slash, Options, Perf. Media is not one of them and never was: it reached all nine consumers in one pass at v1.9.0, so it has no #1. Its `settings/UnitPanel.lua`
is the one non-obvious entry: it **decorates the library instance itself** — `NS.Helpers` *is* the
`lib:New` return, not a wrapper — with the two pieces of the old helpers file that did not
generalise, `ResetAllPositions` and `RenderUnitPanel`. A change to the Options instance surface can
therefore collide with a host member, which no other module can do.

KickCD is consumer #2 for those same five, and two of its wirings are worth knowing about before changing a
descriptor:

- **`LibKa0s-Slash-1.0` had no colour codec, and KickCD is why that surfaced.** Fixed in Slash minor
  4: `colorDecode` / `colorEncode` now exist on the Slash descriptor under the same names the
  Options one uses, and `lib.FormatValue` reads the positional shape directly so the common case
  needs no descriptor at all. KickCD had closed the gap with `get`/`parse` closures and then removed
  them by migrating its stored colour shape; neither workaround is needed now. The asymmetry
  between the two modules is gone.
- **`RenderRows` pcalls each row** as of OptionsWidgets minor 4, so one corrupt saved value or one
  throwing `values` function costs that row and nothing else — which is what KickCD's own flow
  engine did before it adopted. `RenderGrid` guards its items the same way.

Add each addon here as it adopts a module, so "every consumer" in step 8 is a list rather than a
memory. **AuraMaster is the tenth consumer, and until the v1.30.0 sweep it was on no row of this
table** and not in step 9's loop, although it had shipped carrying v1.29.0. It takes eight majors:
Core, DebugLog, Slash, Options, Media, Env, Pool and Perf. It does not look up Widgets or Item. It
is the host that found the four kit gaps revision 16 closes (#27–#30). **No addon on the standard
remains unadopted.**

**Where v1.34.0 stands in the consumers (2026-09-13).** Step 8 is done and merged. All ten
consumers bundle v1.34.0 on `master`, and each `CLAUDE.md` provenance line says so. v1.33.0 and
v1.34.0 were re-vendored in the same batch, so every `master` went from v1.32.0 straight to v1.34.0,
kit revision 19 included. Six hosts adopted `profilesPage`: AbsorbTracker, AuraMaster, KickCD and
PanelMaster on the descriptor, ConsumableMaster with `resetProfile` supplied for the tooltip alone
(its reset stays its own and never reaches `RestoreAllDefaults`), and MultiMeters through a compose
descriptor handed to `__AttachCompose`, since its Master controls are composed at file load before its
Options descriptor exists. The step-9 sweep above was run against the merged `master`s: 85 lookup
files, every one in the table; the one it found missing — ConsumableMaster's `settings/MacroBar.lua`,
the Macro Bar's Buttons drag list — was added to the Widgets row by that sweep. `WhoGotLoots` and
`BuffTextNotifications` are out of scope until they are on the standard at all.

**Where v1.48.0 stands (2026-09-21).** One LibStub minor moves, and it is a **new file**:
`WidgetsDragHandle.lua` at minor 1 (`LibKa0s-Widgets-1.0` 9.1). `Widgets.lua` does not move — it
stays at 9 — and the kit stays at revision 23. It is `lib.DragHandle`, the unlocked drag strip
AuraMaster and ConsumableMaster each drew a copy of, with the help mark at 8px rather than 14 and
dimmed to the dropdown chevron's own tint.
**What a consumer owes is more than the usual copy**: the payload folder gained a file and
`LibKa0s.xml` names it, so a re-vendor that copied only the files it already had would leave the XML
pointing at a file that is not on disk and the game would fail to load it. `cp -r LibKa0s/.` is
already the rule and already handles this; a hand-picked copy does not. No existing member,
descriptor field or row field changes, so no degradation stub moves — `DragHandle`, `DRAG_HANDLE`
and `__DragHandleMeasurer` are additions, and `docs/api/Widgets/members-9.1.json` carries them.
Adoption in AuraMaster (`modules/Anchors.lua`) and ConsumableMaster (`modules/MacroBar.lua`) is a
deletion as well as a re-vendor — roughly 60–70 and 70–75 lines respectively — and it carries two
visible changes in each host: every strip's natural width grows by 6px, and ConsumableMaster's
handle stops being a `BackdropTemplate` and its "?" becomes draggable. Steps 1–6 are done in this
repository — the gates are green (1245 cases, lint 0/0, nothing above CCN 15) — and **step 7's
record, the tag and step 8 are not**. All eleven consumers bundle v1.46.1 or earlier on `master`.

**Where v1.47.0 stands (2026-09-20).** One LibStub minor moves — `OptionsWidgets.lua` 24
(`LibKa0s-Options-1.0` 23.24.3.7.3) — and the kit stays at revision 23. It is `O.IdList`'s
`columns`: a list that asks for it packs that many entries into each Flow row, and two is the cap.
What a consumer owes: the copy of both payloads and the provenance line, and nothing more unless it
adopts `columns`. Two things arrive **without** being asked for, and only in the icon style: the X's
frame is an absolute 26px around its 16px art rather than `0.06` of the row, so the delete control
is no longer flush against the entry's own icon and its click target is 26x26 rather than 16 wide,
and the name beside it takes `0.90` rather than `0.92`. No member, descriptor field or row field is
added, so no degradation stub moves. Steps 1–7 are done in this repository — the gates are green
(1211 cases, `luacheck` 0/0, nothing above CCN 15) and both standards pointers were checked
against `../WowAddonStandards/standards/STANDARDS.md` and rolled to v2.61.0 by this step; **the
release-mode automated-test bundle, the tag and step 8 are not**. All eleven consumers bundle
v1.46.1 on `master` — this line read "ten of the eleven" when it was written, which was wrong on the
day and contradicted the step-8 paragraph below that said eleven; corrected 2026-09-21 against the
provenance line on each consumer's own `master` (LibKa0s #34). Aura Master is the host this release was written for — its Hard CC and Soft CC
spell lists are what a one-entry-per-line list made unreadable — and it carries a v1.47.0 provenance
line on its own feature branch ahead of the tag.

**Where v1.46.1 stands (2026-09-19).** A patch to v1.46.0's combat lock: `Options.lua` 23 and
`OptionsTabs.lua` 3 (`LibKa0s-Options-1.0` 23.23.3.7.3); the kit stays at revision 23. v1.46.0
registered `PLAYER_REGEN_DISABLED` / `_ENABLED` for the life of the process and covered hidden pages
at combat start, so seven consumers' stand-down suites counted a live registration, a REGEN handler
and shown frames on a stood-down addon. Now the library registers only while one of its pages is on
screen and covers only pages on screen. What a consumer owes beyond the copy and the provenance line:
a stand-down suite that runs after other suites left a settings page shown closes that page first
(`panel:Hide()` and, in the kit's mock, `panel:__fire("OnHide")`) — a page on screen is watched on
purpose — and a host test that pinned v1.45.0's close-the-window refusal is inverted. Steps 1–7 are
done; the tag and step 8 wait.

**Where v1.46.0 stood (2026-09-19).** Three LibStub minors move — `Options.lua` 22,
`OptionsWidgets.lua` 23 and `OptionsTabs.lua` 2 (`LibKa0s-Options-1.0` 22.23.2.7.3) — and the kit
stays at revision 23. It is the combat lock the Ka0s WoW Addon Standard v2.60.0 asks for
(options-ui-§2, §13; anti-pattern #88), and it is a fix to every consumer's settings window rather
than an opt-in: a page shown in combat is covered instead of closing Blizzard's window. What a
consumer owes: the copy of both payloads and the provenance line — and the removal of any
hand-rolled combat guard of its own on a settings page or a tab strip, which the standard now
forbids beside the library's. No member, descriptor field or row field is added, so no degradation
stub moves. Tagged; step 8 was taken on branches, and the stand-down failures it found are v1.46.1.

**Where v1.45.0 stood (2026-09-19).** One LibStub minor moves — `OptionsWidgets.lua` 22
(`LibKa0s-Options-1.0` 21.22.1.7.3) — and the kit stays at revision 23. What a consumer owes: the
copy of both payloads and the provenance line; nothing more unless it adopts `shownWhen`, which Aura
Master and Party Frame Enhanced do. Step 8 is done on branches: every consumer carries v1.45.0 on
`chore/libka0s-v1.45.0` (Aura Master on its feature branch), each green, none merged yet.

**Where v1.44.0 stood (2026-09-19).** One LibStub minor moves — `OptionsWidgets.lua` 21
(`LibKa0s-Options-1.0` 21.21.1.7.3) — and the kit stays at revision 23. What a consumer owes: the
copy of both payloads and the provenance line; nothing more unless it adopts `removeStyle`, which
Aura Master does on its spell lists.

**Where v1.43.0 stood (2026-09-17).** A kit-only release: **kit revision 23**, and no LibStub
minor moves, so every consumer's `libs/LibKa0s/` is byte-identical before and after. Step 8 copies
both payloads anyway, because `tests/test_vendor_sync.lua` resolves both from the tag the provenance
line names. What a consumer owes: the copy, the provenance line, and — only where its docs cite
`tests/_kit/framework.lua` by line number — re-pointed citations, since the load-time guard moves
every line below it. No suite in the eleven trips the new heap, leak, CPU or host-path gates at their
defaults (measured with revision 23 swapped into all eleven, run in parallel), so no runner raises a
budget. v1.42.0's step 8, below, is done: all eleven carried v1.42.0 before this release.

**Where v1.42.0 stood (2026-09-17).** Steps 1–7 are done in this repository; **step 8 is not**, and
it is the smallest step 8 this library has had. All eleven consumers are otherwise **current**: each
one's `CLAUDE.md` provenance line reads v1.41.0, each carries `core/LauncherSetup.lua` and
`tests/test_disabled.lua`, and each looks up `LibKa0s-Lifecycle-1.0` in its own setup file. So the
work downstream is a re-vendor of a **one-file fix** into eleven repos that have already adopted
everything around it — no new major, no new member, no descriptor field, no adoption changeset.

v1.42.0 is one change, and it removes the last exception from minor 13's rule:

- `LibKa0s-Slash-1.0` minor 14 stops refusing **a reserved verb the host never registered**. It
  answers `unknown command '<verb>'` and the help index while disabled, exactly as it already did
  while enabled. `lib.LIVE_VERBS` does not move and no member or descriptor field changes; one
  branch of the dispatcher is deleted. The usual case is `perf`: a verb is reserved always but
  **registered when wired**, so the five hosts holding a performance no-combat-path exemption —
  BankLedger, LootHistory, PanelMaster, PrettyChat and WhatGroup — ship no `perf` entry at all, and
  all five reported `/<slash> perf` answering the stand-down line within a day of adopting minor 13.
  Nothing was refused, so nothing says it was.

What a consumer owes on this re-vendor:

- **Nothing in its own code.** A host that passes no `isEnabled` is unaffected, as it was at 13.
- **One expectation in `tests/test_disabled.lua`, and only in the five above.** A host that pinned
  the refusal line for a verb it does not ship inverts that case to the unknown-command line. The
  six that pinned only their own feature verbs change nothing; those are still refused, and they are
  now the whole of what the disabled gate refuses.
- **The provenance line moves to v1.42.0 in the same commit as the copy**, as always.

The kit stays at **revision 22**, so `tests/test_vendor_sync.lua` pairs the two payloads at the
v1.42.0 tag exactly as it did at v1.41.0 — the kit bytes are identical, but both are resolved from
the tag the provenance line names, so both are copied.

**Every step 8 through v1.46.1 is done**, and so are the adoption changesets that outlived them.
All eleven consumers bundle **v1.46.1** on `master` and each `CLAUDE.md` provenance line says so —
still true on 2026-09-21, re-measured for LibKa0s #34: what has moved since sits on branches and not
on any `master`, nine consumers at v1.47.0 on `chore/revendor-libka0s-v1.47.0`, ConsumableMaster at
v1.48.1 and Aura Master at v1.49.1 on its own feature branch. So
v1.42.0's one-file Slash fix, v1.43.0's kit-only revision 23, v1.44.0's `removeStyle` and v1.45.0's
`shownWhen` have all landed downstream along with the combat lock and its patch. The two hosts that
took the opt-ins are Aura Master (both) and Party Frame Enhanced (`shownWhen`). What is **not** done
is this release's own step 8, which cannot begin before the tag.

This paragraph says where the consumers stand as of the release being prepared, so it is stale the
moment it is not rewritten. **Rewrite it at the next release**, in the same commit as step 7's other
version-bearing lines. It was carried unchanged from v1.42.0 through v1.46.1 — four releases — on
the strength of the one-line instruction that used to sit here, which is the remembering step 7
exists to replace.

WhatGroup has Core, Env, DebugLog, Media, Options and Slash — `core/CoreSetup.lua`,
`core/EnvSetup.lua`, `core/DebugLogSetup.lua`, `core/MediaSetup.lua`, `settings/OptionsSetup.lua`
(decorated by `settings/Panel.lua`) and `settings/Slash.lua` — and **declines Perf** (`LIBKA0S-15`). It is the host that drove **DebugLog minor 7**: its hand-written
sink had `pcall`'d the format since its own WG-22, and its suite went red on the first load of the
library's, which pre-stringified every vararg and then handed the sentinel to a numeric slot. It is
also the first host to wrap `SetRenderer` **and** `EnsureDefaultsButton` on the Options instance —
to keep a `C_Timer.After(0, …)` hop between a settings canvas's `OnShow` and the AceGUI frames it
builds, which is a taint fix it had already shipped.
LootHistory has Core, Env, Pool, Item, Media, Widgets, DebugLog, Slash and Options and **declines Perf** for two independent
reasons — it owns no `OnUpdate`, no repeating ticker and no repaint loop, so there is no bucket to
fill; and its `suspend` would have to stop recording the loot dropping inside window B, so an
experiment would silently cost the user real history (LIBKA0S-17, recorded in its GitHub issues). It
drove no library change: every v1.2.0 surface it needed was already there and all of them fitted.
BankLedger has Core, Env, Pool, Item, Media, Widgets, DebugLog, Slash and Options; it **declines Perf** (its capture engine never runs in combat, and the probe's windows are combat-gated, so every bucket would read 0.000 by construction — see LIBKA0S-17 in its GitHub issues).
`WhoGotLoots` and `BuffTextNotifications` are out of scope until they are on the standard at all.

## Before the first public release

Publication freezes the descriptor contract in the wild — after it, a field may be added but never
removed or repurposed, because you cannot know who has vendored what. Outstanding items to settle
first are tracked as issues on the repo.
