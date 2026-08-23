# Releasing LibKa0s

Two version numbers, one of which is load-bearing at runtime.

| Number | Lives in | Who reads it | When it moves |
|---|---|---|---|
| Repo semver (`v1.9.2`) | git tag, `CHANGELOG.md` heading | humans | once per release |
| File minor (integer) | `MINOR` / `WIDGETS_MINOR` / `SCROLL_MINOR` / `PANEL_MINOR` at the top of each file in `LibKa0s/` | **LibStub, at load time** | every released change to that file |

The semver tag is a courtesy. The **file minor is the mechanism**: LibStub keeps the highest minor it
is offered for a major and discards the rest, so of the copies vendored across every installed addon,
exactly one wins. A released change that does not bump its file's minor therefore does not ship — any
host already carrying the old copy keeps running it, and nothing errors to say so.

## Order of operations

1. **Make the change**, with its test. Green gate: `lua tests/run.lua` and `luacheck .` (0/0).
   That `luacheck` figure is **scoped by `.luacheckrc`'s `exclude_files`**, not repo-wide — here it
   is twelve files, the eight in `LibKa0s/` plus four under `testkit/`, because `tests/` and `docs/`
   are excluded. A consumer's is scoped too, and usually excludes `libs/` and `tests/`. 0/0 only
   means something if the files carrying the seam are inside the checked set, so confirm that before
   reading a clean run as a clean adoption.
2. **Bump the minor of every file you changed** — and if you touched `testkit/`, bump
   `Kit.VERSION` too and re-vendor the kit into `tests/_kit/` here before the gate can pass. All eight, by their exact constant names: `MINOR` in
   `Core.lua`, `MINOR` in `DebugLog.lua`, `MINOR` in `Slash.lua`, `MINOR` in `Options.lua`,
   `WIDGETS_MINOR` in `OptionsWidgets.lua`, `SCROLL_MINOR` in `OptionsScroll.lua`, `MINOR` in
   `Perf.lua`, `PANEL_MINOR` in `PerfPanel.lua`. The secondary files carry their own name rather than
   `MINOR` because they attach to a shell that already owns that local. A file you did not touch does
   not move. Bumping the whole lib in lockstep would discard the narrow-skew property that made one
   major per module worth having.
3. **A new module is also a new row in `tests/run.lua`'s `MAJORS`** — its major string, its files in
   `LibKa0s.xml` order, its primary, and any `paired` secondary. `tests/test_versioning.lua` iterates
   that table rather than naming files inline, so a module missing from it is a module nothing
   checks. `LibKa0s-Options-1.0` is the most recent row added that way, and the one to copy: it is
   the first with a `files` list of three and a `paired` array of two
   (`{ OptionsWidgets, __widgetsMinor, __widgetsShellMinor }`,
   `{ OptionsScroll, __scrollMinor, __scrollShellMinor }`). The table carries one row per shipped
   major — five today.
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
6. **Regenerate the case list**: `lua tests/run.lua --list` into `docs/test-cases.md`, keeping CRLF
   (see that file's own banner for the exact command).
7. **Move the provenance template in this file to the version being released** — the templated line
   under "Re-vendoring consumers" below, and the repo semver in the table at the top. It moves here,
   before the tag, so the tagged commit already says what it bundles and step 8 is a copy rather than
   a recollection. This is a numbered step because the alternative is remembering, and at v1.5.0 the
   remembering did not happen: the template still read v1.4.0 while every consumer had been updated
   correctly by hand. **Green gate again**, then — before the tag — **run the full battery and freeze
   the release bundle**:

   ```sh
   tests/_kit/run-automated-tests.sh --release <X.Y.Z>
   ```

   This is a step, not a nicety. Every other repo in the collection gets its release bundle from
   `/wow-addon:bump-version`; this repo has no such command and this order was the only place the
   run could be written down, so until v1.8.0 it was written down nowhere. The cost is on disk:
   the one bundle taken before this step existed, `20260805-002859`, carries `"release": null` on a
   commit later than `v1.7.0^{}` — it records a working tree nobody released rather than the bytes
   anyone got. **v1.8.0 is the first release of this library with a test record naming it.**
   `--release` is what ties a bundle to a version; without the flag the field stays null however
   carefully the run is timed.

   Read the four suites before tagging: **the release gate is all four at `pass` plus zero functions
   above CCN 15** (`automated-tests-§3`), and a `skip` is NOT EVALUATED rather than passed. `perf` is
   a standing `skip` here because this repo ships no `tests/perf.lua`; that is a known and recorded
   hole in the gate, not a pass — see [`automated-tests/README.md`](automated-tests/README.md).

   Then commit — the bundle and `RESULTS.md` row belong in the release commit, so the tagged tree
   contains the evidence for itself — and tag the repo semver.
8. **Re-vendor every consumer** — see below. This is part of the release, not a follow-up, and it
   includes bumping the version named in each consumer's `CLAUDE.md` provenance line, in the same
   commit as the copy.
9. **Re-sweep the Consumers table against the source**, because it is maintained by hand and the
   wiring is not:

   ```
   for a in AbsorbTracker BankLedger ConsumableMaster KickCD LootHistory PanelMaster PrettyChat WhatGroup; do
       grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' ../$a --include='*.lua' \
         | grep -v '/libs/' | grep -v '/tests/'
   done
   ```

   Every file that prints must appear in the table's third column. A second lookup site nobody
   recorded is a file the checklist never points a reviewer at — which is exactly how
   AbsorbTracker's `settings/Schema.lua` went unnamed until the 2026-08-01 v2 adoption run.

## Re-vendoring consumers

Two payloads, with different destinations and different reasons for existing.

**The library** is the inner `LibKa0s/` folder and nothing else — the nine `.lua` files, the
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

> Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.9.2 (MIT).

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
  (`NEEDS_CORE`, at the top of each of `DebugLog.lua`, `Slash.lua`, `Options.lua` and `Perf.lua`)
  and returns
  before `NewLibrary` if the dependency is missing or older, so the module is **absent** rather than
  half-wired. That is the honest failure, not a working one: the host's setup file reports the
  library as missing and falls back. Nothing negotiates the other direction, and the three
  paired-minor guards that protect a secondary file within a major (`OptionsWidgets`,
  `OptionsScroll`, `PerfPanel`) do not generalise across them. Whole-folder copying is the
  mitigation.
- **A partly-copied `LibKa0s-Options-1.0` fails at CALL time, not at load time.** The other majors
  fail loudly and early; this one does not. If `Options.lua` itself is missing or refused, both
  attach files bail on their own `LibStub("LibKa0s-Options-1.0", true)` lookup and the module is
  cleanly absent. But if only one of `OptionsWidgets.lua` / `OptionsScroll.lua` fails to arrive,
  `lib:New` still succeeds — the shell guards its attach step with `if lib.__AttachWidgets then … end`
  and `if lib.__AttachScroll then … end` — and the host holds an instance that looks whole until
  something calls `O.AttachTooltip` or `O.PatchAlwaysShowScrollbar`, which may be a panel build away.
  Three files, one major, one copy.
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
| `LibKa0s-Core-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, PanelMaster, PrettyChat, WhatGroup | `core/CoreSetup.lua` (all eight). PrettyChat is the **first host to pass `sep = ""`** — its `[PC]` tag bakes its own trailing space, so the default `" "` would double-space every line it prints. It also **declines the window-chrome half** for the same reason PanelMaster does: its only window is the debug console, which reaches Core's chrome from inside the DebugLog major. PanelMaster **declines the window-chrome half** (`SKIN`/`ApplySkin`/`MakeCloseButton`): its only standalone window is the debug console, which reaches Core's chrome from inside the DebugLog major |
| `LibKa0s-DebugLog-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, PanelMaster, PrettyChat, WhatGroup | `core/DebugLogSetup.lua` (AbsorbTracker, KickCD, BankLedger, LootHistory, PanelMaster, PrettyChat, WhatGroup); ConsumableMaster: `modules/DebugLog.lua`. PrettyChat passes **none** of `skin` / `applySkin` / `makeCloseButton` and deleted a 424-line hand-written console to take the library's edge as-is — the first adoption where the Core-minor-3 default *was* the answer rather than something to override. **LootHistory is the second host on minor 4's `applySkin` — and both it and BankLedger have since
dropped `makeCloseButton`, which as of v1.5.0 has no consumer at all** — it asserts the derived title-bar offsets rather than assuming them |
| `LibKa0s-Slash-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, PanelMaster, PrettyChat, WhatGroup | PrettyChat: `settings/Slash.lua`, **plus a second lookup at `settings/Schema.lua`** — the same shape as AbsorbTracker's and found the same way, by the sweep above. `Schema.FormatValue` is the addon's ONE value renderer, and it has two consumers that are not both CLI surfaces: the descriptor's `format` hook and the `[Set]` debug trace at the write seam, so it lives beside the rows rather than in the slash file. PrettyChat is also the **second host on minor 5's `format` hook and the first to use it on a row type the library can already render** — the case this doc listed as untried: it doubles `\|` to `\|\|` so a Blizzard format string's colour escapes read as text instead of colouring the chat line, delegating to `lib.FormatValue` first so the empty-string `(none)` stays the library's. Its `parse` adapter exists for a **gap**, not an exotic type — see the note under the table. `settings/Slash.lua` (AbsorbTracker, KickCD, BankLedger, LootHistory, WhatGroup) — LootHistory is the **second host on minor 5's `format` hook**, for the same set-valued row shape BankLedger drove it for; ConsumableMaster: `settings/Slash.lua` — moved there from `core/SlashCommands.lua` (CM-47/CM-54); this table said the old path until the v1.7.0 sweep, which is what the step-9 re-sweep is for. PanelMaster: `settings/Slash.lua`, and it is the **first host to pass a descriptor `L`** — a plain one-key table (`RESET_ALL`), so the override path is now exercised as well as the fallback; it also carries a `parse` adapter that up-cases enum input before delegating to `lib.ParseValue`. AbsorbTracker has a **second** lookup at `settings/Schema.lua`, stashed at file load so `NS.FormatSchemaValue` can call `lib.FormatValue(row, v)` — the seam every panel widget and every `/at set` renders through |
| `LibKa0s-Options-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory, PanelMaster, PrettyChat, WhatGroup | PrettyChat: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. It **declines `RestoreDefaults` / `RestoreAllDefaults`** — both are row-by-row over ~171 rows, which would run its `ApplyStrings` once per row and emit one `[Set]` line per row into a 500-line console buffer; its own batch resets stay, reached through `defaultsOnClick` so `CreatePanel`'s `OnDefault` forwarding still makes the footer control and the header button one body. Its per-string editor is a 40/60 three-row block that `RenderGrid` cannot express either (HALF or full width, no third ratio). LootHistory: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. BankLedger: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. AbsorbTracker: `settings/OptionsSetup.lua` + `settings/UnitPanel.lua`. KickCD: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, `Panel_Widgets.lua`, `Panel_Render.lua`. ConsumableMaster: `settings/Panel.lua`. PanelMaster: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, which **wraps `RenderField` and `EnsureScroll` on the instance** for its own open-dropdown registry — the first host to need either. WhatGroup: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, and it is the **second host to wrap instance members** — `SetRenderer` and `EnsureDefaultsButton`, so both the page body and the Defaults button build on the NEXT frame rather than synchronously inside `OnShow`. It is a taint fix that addon had already shipped: Blizzard's GameMenu / Logout flows can dispatch a settings canvas's `OnShow` inside a secure-execute chain. Wrapping on the instance is load-bearing for the same reason it was for PanelMaster — `SetRenderer`'s handler resolves `EnsureDefaultsButton` from the instance at call time |
| `LibKa0s-Perf-1.0` | AbsorbTracker, KickCD, ConsumableMaster | `core/PerfSetup.lua` (first two); ConsumableMaster: `modules/PerfSetup.lua`. **Declined** by BankLedger (`LIBKA0S-17`), PanelMaster (`LIBKA0S-31`), PrettyChat (`LIBKA0S-12`) and WhatGroup (`LIBKA0S-15`), all on structural grounds — none has work that runs inside a combat-gated measurement window. WhatGroup declines on two independent reasons: no hot path at all (zero `OnUpdate`, zero tickers, zero repeating timers; the only code reachable in a combat-gated window is a roster handler that fires zero times on most pulls), **and** the suspend contract — it is a CAPTURE addon, so an inert arm means an LFG apply or an invite-accept inside the window is never recorded and the popup the player joined for silently does not appear. That second reason is LootHistory's, arrived at independently. PrettyChat is the strongest case of the three: a whole-repo sweep finds **zero** `RegisterEvent`, `OnUpdate`, `C_Timer` and tickers, so every bucket would read `0.000` by construction — and its `suspend` would have to restore Blizzard's own chat formats for the duration of the window, visibly flipping the player's chat mid-fight for a capture that can only report zero |

**A gap the Slash consumers should know about, found by PrettyChat.** `lib.ParseValue` splits the remainder on whitespace and `parseString` returns `args[1]`, so a free-text `string` row cannot hold a value containing a **space**: `/pc set <path> You receive loot: %s` stores `"You"`. Every value in that addon's schema is a Blizzard format string, so it supplies a descriptor `parse` — which slash-commands-§6 sanctions, and which is why this is filed as a note rather than a defect. But the shortfall is not addon-specific, and the next host with a free-text row will hit it silently: the value is stored, no error is raised, and only the echo shows the truncation.

AbsorbTracker vendors to `libs/LibKa0s/` and is consumer #1 for all five. Its `settings/UnitPanel.lua`
is the one non-obvious entry: it **decorates the library instance itself** — `NS.Helpers` *is* the
`lib:New` return, not a wrapper — with the two pieces of the old helpers file that did not
generalise, `ResetAllPositions` and `RenderUnitPanel`. A change to the Options instance surface can
therefore collide with a host member, which no other module can do.

KickCD is consumer #2 for all five, and two of its wirings are worth knowing about before changing a
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
memory. **No addon on the standard remains unadopted.** `WhoGotLoots` and `BuffTextNotifications`
are out of scope until they are on the standard at all.
WhatGroup has Core, DebugLog, Options and Slash — `core/CoreSetup.lua`, `core/DebugLogSetup.lua`,
`settings/OptionsSetup.lua` (decorated by `settings/Panel.lua`) and `settings/Slash.lua` — and
**declines Perf** (`LIBKA0S-15`). It is the host that drove **DebugLog minor 7**: its hand-written
sink had `pcall`'d the format since its own WG-22, and its suite went red on the first load of the
library's, which pre-stringified every vararg and then handed the sentinel to a numeric slot. It is
also the first host to wrap `SetRenderer` **and** `EnsureDefaultsButton` on the Options instance —
to keep a `C_Timer.After(0, …)` hop between a settings canvas's `OnShow` and the AceGUI frames it
builds, which is a taint fix it had already shipped.
LootHistory has Core, DebugLog, Slash and Options and **declines Perf** for two independent
reasons — it owns no `OnUpdate`, no repeating ticker and no repaint loop, so there is no bucket to
fill; and its `suspend` would have to stop recording the loot dropping inside window B, so an
experiment would silently cost the user real history (LIBKA0S-17, recorded in its GitHub issues). It
drove no library change: every v1.2.0 surface it needed was already there and all of them fitted.
BankLedger has Core, DebugLog, Slash and Options; it **declines Perf** (its capture engine never runs in combat, and the probe's windows are combat-gated, so every bucket would read 0.000 by construction — see LIBKA0S-17 in its GitHub issues).
`WhoGotLoots` and `BuffTextNotifications` are out of scope until they are on the standard at all.

## Before the first public release

Publication freezes the descriptor contract in the wild — after it, a field may be added but never
removed or repurposed, because you cannot know who has vendored what. Outstanding items to settle
first are tracked as issues on the repo.
