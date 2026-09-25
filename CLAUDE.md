# CLAUDE.md — LibKa0s

LibKa0s adheres to the **Ka0s WoW Addon Standard** —
<https://github.com/tusharsaxena/WowAddonStandards>. This file names no version of it on purpose:
`documentation-§6` asks for none here, and the one pointer that carries a version is the README's,
which `library-stack-§7`'s *Substitutes* list requires and `docs/releasing.md` step 7 checks.

**Read this first: LibKa0s is a library repo, not an addon.** It is in scope for the standard and it
is audited, but against **`library-stack-§7`'s applicability list**, not the addon rule set
(`standards/ADDONS.md` → *Ka0s-owned library repos*). There is no TOC, no player-facing README, no
settings canvas, no slash surface, no SavedVariables file and no CurseForge package here — every one
of those binds the **consumer** that wires a module in, and is audited there. Auditing this repo
against the addon sections manufactures findings the standard never meant.

What that leaves, concretely:

- **Applies unchanged:** `testing-§1`, `testing-§9`, `testing-§10`, `testing-§11` (the headless
  suite, the derived-and-pinned load lists, the versioning suite and the kit-sync gate — `§10` names
  this repo as the reference implementation for that family of gates); `lint`; `automated-tests`;
  `versioning-git`; `line-endings` (the library ships Lua into every consumer's client-bound
  `libs/`, so it takes the CRLF pin — named explicitly upstream because a library repo has no `.toc`
  and `line-endings-§2`'s discriminator would otherwise read it as non-client); `localization-§5`
  (US English in authored text — a British spelling here is vendored into eleven consumers and
  becomes eleven findings); `documentation-§5`; `documentation-§7`.
- **Does not apply:** `documentation-§1`'s player-facing README structure and badge row;
  `documentation-§2`'s addon `CLAUDE.md` stub as written (this file is the substitute);
  `documentation-§3`'s `docs/` trio (`ARCHITECTURE.md`, `testing.md`, `smoke-tests.md`), its five
  verification-and-record docs (`test-cases.md`, `performance.md`, `perf-analysis/README.md`,
  `automated-tests/README.md`, `automated-tests/RESULTS.md`) **and its whole topic-detail tier
  model** (Tier 1's `scope.md`, `module-map.md`, `schema.md`, `settings-panel.md`,
  `data-flow.md`, `common-tasks.md`; Tier 2; the `## Documentation map` section of an
  `ARCHITECTURE.md` that does not exist here) — a library has no settings canvas, no SavedVariables
  and no in-game pipeline, so four of the six Tier 1 docs have no subject; `toc-file`, `options-ui`,
  `slash-commands`, `preview-mode`, `launcher`, `savedvariables`, `packaging`.
- **Substitutes this repo must carry:** this `CLAUDE.md` with the section below, a root
  [`DEPENDENCIES.md`](DEPENDENCIES.md), and a README pointer to the standard. A root
  [`CHANGELOG.md`](CHANGELOG.md) is **required** here — and forbidden at an addon root — because
  `tests/test_versioning.lua` asserts the changelog accounts for the version every file is at, and
  has nowhere else to look.

## Standards compliance (read first)

This repo is built to the **Ka0s WoW Addon Standard**
(https://github.com/tusharsaxena/WowAddonStandards). All development here — features, refactors,
doc changes — MUST conform to it, as scoped by `library-stack-§7`'s applicability list above.

**If a change would deviate from the standard, STOP and flag the deviation explicitly.** Do not
silently deviate and do not silently "fix" to match. Surface it and let the user decide which of
two things it is:

1. **An accepted deviation** — this repo intentionally differs. Record it as a row in
   `## Documented deviations` below, shaped
   `| Rule | What differs | Why | Decided | Re-check trigger |`, where Rule is the `filename-§N`
   reference. The register lives in this file rather than in `docs/ARCHITECTURE.md`, because
   `documentation-§3`'s `docs/` trio, `docs/ARCHITECTURE.md` among it, does not bind a library repo
   (`library-stack-§7`) and a register with no file is a
   register nobody writes to. The reasoning may live in an audit or review bundle and the row cites
   it, but a deviation not in the register is not ratified.
2. **A change to the standard itself** — the standard's definition should evolve; the update belongs
   upstream in the WowAddonStandards repo, after which this repo follows the new rule.

When in doubt, treat standard conformance as a hard requirement and ask.

**One extra rule this repo carries, because it is upstream of ten others.** Everything in
`LibKa0s/` and `testkit/` is **vendored** — into `<Addon>/libs/LibKa0s/` and `<Addon>/tests/_kit/`
respectively. A defect shipped from here reappears in every consumer, and a fix is only real once it
is re-vendored. Never patch a vendored copy downstream; fix it here and copy across.

## Documented deviations

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `localization-§5` | `testkit/mock_base.lua` and `testkit/mock_record.lua` reproduce AceTimer-3.0's handle field, read as a member access (`.cancelled`), and the `IsCancelled` method of Blizzard's `C_Timer` handles, verbatim; `tests/test_mock_ace.lua`, the suite that pins those fakes, reads both as the fakes spell them | Third-party API identifiers, not prose. The kit's AceTimer fake hands out AceTimer's own handle table, and a suite written against the real field reads `handle.cancelled`; a kit that renamed it would answer nil there and pass, which is fidelity rule 1's failure (`testkit/mock_base.lua`'s header). The same for `IsCancelled`, which a `C_Timer.NewTimer` handle answers in the client. `tests/test_prose.lua`'s `RATIFIED` carries exactly these spellings for exactly these two files, matched as `.cancelled` and `iscancelled`, and its `AUTHORED_RATIFIED` the same two for `tests/test_mock_ace.lua` and for this register, which names them, so prose in the same files is still held to US English. Filed by the v1.31.0 review (commit `1f1790c`, recorded in `docs/api/testkit/version-17-docs.md`); the second path arrived with kit revision 22, which peeled the timer queue and both handle kinds out to `testkit/mock_record.lua`, and the suite's path with the US-English sweep of `tests/` (`LK-29`). | 2026-09-12, owner decision on the v1.31.0 review; extended to `tests/test_mock_ace.lua` 2026-09-24, executing `LK-29` | AceTimer renames the field, or the kit stops modeling the handle (and `C_Timer` renames `IsCancelled`, or the kit stops modeling `NewTimer` handles). `tests/test_prose.lua` reddens on its own if any of these exemptions stops matching. |
| `localization-§5` | `lib.ICONS` keeps `minimise`, the one British spelling left in the shipped payload | The key is not prose. `lib.Icon` (`LibKa0s/Media.lua:202`) builds the texture path **from** the key — `base .. ICON_DIR .. "\\" .. name` — and the file on disk is `minimise.tga`, vendored into every consumer's `libs/LibKa0s/media/icons/`. Renaming the key alone points at a texture that does not exist, and `Media.lua:190-196` records what that costs: a texture that fails to load draws nothing and raises nothing, so the icon simply disappears from every consumer's title bar with no error anywhere. Renaming it safely needs a second `.tga` or an alias map, which is a change to `Media.lua`'s surface, not a spelling fix. Filed as `LK-06` in `docs/audits/2026-09-07/`, which names the key as "a key consumers bind against" and asks for an alias rather than a rename. | 2026-09-07, executing `M1-LK-11` | A `minimize.tga` shipped beside the current file, or an alias map in `lib.Icon` — either ends this row, and the key moves in the same change as the eleven consumers' re-vendor. `tests/test_prose.lua` reddens on its own if the exemption ever stops matching, so a dead row cannot sit here unnoticed. |
| `localization-§5` | The kit ships a US-English gate (`tests/_kit/test_prose.lua`) and this repo leaves it unwired, running its own `tests/test_prose.lua` instead. `testing-§9` and `localization-§5` between them permit exactly that — wire the kit's copy, or wire your own and record why the kit's is unwired — and this row is the record. The suite inventory reads it and reports the kit's copy once, as a declared skip carrying this reason, so the decline appears in `docs/test-cases.md` and in every run's output rather than as a gate nobody knows is not running. | The kit's copy is the broader gate over the same rule and the narrower one over this repo. Broader: it reads the whole tracked set, where this repo's reads only the two folders whose bytes ship. Narrower: this repo's copy carries two cases the kit's has no equivalent for — no non-ASCII byte reaches a player from the shipped library, the em dash excepted, and no retired `§N.M` section reference survives in the shipped library or the shipped kit — and wiring the kit's copy alone would retire both over the payloads eleven consumers receive by copy and cannot fix for themselves. The ASCII case reads `LibKa0s/` only: the kit prints to a terminal and `tests/_kit/` never ships, so from kit revision 26 kit strings carry the section sign in their citations. What the extra breadth would cost was measured on 2026-09-23 at kit revision 25: the kit's copy reports **1121 lines across 147 files** here. **Twelve of them are in the shipped payload outside the gate's own source, and all twelve are the two rows above** — the gate this repo runs is already green over everything it ships. The other 1109 are records this repo must not rewrite or does not write at all: 560 in `docs/api/`'s frozen per-version documents, 150 under `tests/`, 118 under `docs/adoption/`, 107 under `docs/superpowers/`, 63 in `CHANGELOG.md`'s entries, 46 in the generated `docs/test-cases.md`, 21 in `docs/adoption-prompt.md`, and 23 in `testkit/test_prose.lua` itself, which quotes every forbidden spelling in order to forbid it and gained six more with kit revision 25's carve-out fixtures. Re-measured 2026-09-23 after the revision-25 fix passes, with the kit's gate wired in a throwaway copy of this checkout; the figures before that re-measurement were 1115 / 143 / 17. The kit's exclusion list named five frozen-bundle folders at revision 25 and this repo has three more of its own. Revision 26 takes one of the three, `docs/superpowers/`, into the kit's list with `docs/investigations/` (which this repo does not have), so the 107 lines there leave the count, and reads the two `docs/automated-tests/` store-root files back in, which this repo's own gate now reads as well; closing the gap with per-file waivers is the whole-file waiver `localization-§5` forbids, and closing it with `skipDirs` would leave 150 real hits under `tests/`, which is a US-English sweep and not an integration. That sweep landed on 2026-09-24 (`LK-29`, resolving the 2026-09-23 audit's `LibKa0s-A-07`): `tests/`, the live document of every major under `docs/api/` and that folder's README, `docs/releasing.md`, `README.md`, `DEPENDENCIES.md`, this file and `tools/artwork/` carry **0** prose hits, and `tests/test_prose.lua` now gates them in a case of its own. | 2026-09-23, integrating kit revision 25 | The kit's copy grows the non-ASCII and retired-section cases, **or** `docs/api/`, `docs/adoption/`, `docs/superpowers/` and released changelog entries join the kit's own frozen-bundle exclusions and this repo's `tests/` prose is swept to US English. Either ends this row. The sweep half is done (0 prose hits under `tests/` and in the live docs since 2026-09-24), so what is left of the second is the kit's own frozen-bundle exclusions. |
| `compat` | `LibKa0s/Perf.lua` reads the specialization globals inline (`P.Context`, `LibKa0s/Perf.lua:707-715`), duplicating `LibKa0s-Compat-1.0`'s spec pair (`lib.GetSpecialization`, `LibKa0s/Compat.lua:270`, and `lib.GetSpecializationInfo`, `:289`). The copies are not identical: Perf's takes the namespaced rung for the index reader only and calls the `GetSpecializationInfo` global directly, where Compat's ladders both. | Raising Perf's floor to Compat is a vendoring break for eleven consumers (`ls -d ../*/libs/LibKa0s/Perf.lua \| wc -l` from this checkout, 11 on 2026-09-23) in a release declared additive: v1.55.0 moves no existing file's minor, and a new floor is the change to the vendoring `library-stack-§7` treats as breaking. Ruled as reading A of the Compat major's open question on this read; [the Compat document](docs/api/Compat/version-1-docs.md) states the same decision under *The library's own inline spec read*. This row supersedes `LK-31` in the frozen `docs/audits/2026-09-08/` bundle (`04_TECHNICAL_DESIGN.md`, `05_EXECUTION_PLAN.md` step 5), which asked for one owner of the spec reader and proposed `Core.lua`, with `Env.lua` as the alternative. Neither was taken; Compat now exists as that owner, and the only open question is when Perf floors on it. The bundle is not edited. | 2026-09-23 | The next Perf floor raise made for any other reason. |
| `events-frames-taint-§1` | Three widget-owned private frames call `RegisterEvent` raw, with no pcall'd per-event helper, no player-reachable rejected-name record and no AceEvent: `LibKa0s/OptionsTabs.lua`'s combat lock (`PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` on `lib.__combatFrame`, in `lib.__syncCombatEvents` and `lib.__pageShown`), `LibKa0s/Widgets.lua`'s popup-menu dismiss (`GLOBAL_MOUSE_DOWN` on the shared dropdown menu, in the dropdown button's `OnClick`), and `LibKa0s/Options.lua`'s park frame (`PLAYER_REGEN_ENABLED` on `lib.__parkFrame`, in `lib.__parkRegistration`, from Options minor 24 and `LK-25`). | The section is written against an addon's event traffic (`addon:RegisterEvent`, a module's disable path, the player-facing debug verb), and these frames carry one widget's UI state, not the host's. Its per-event isolation exists so that one retired or misspelled name cannot deafen a registration block; the names here are stable core client events, so that failure has no route in. This row is **not** justified by "the library cannot use AceEvent": `LibKa0s/Bus.lua` already resolves AceEvent-3.0 at call time, and `lib.SafeRegisterEvent` (`LibKa0s/Core.lua`) is the pcall'd helper the section asks for, available to any of these sites. Filed as `LibKa0s-A-10` by the 2026-09-23 audit, which chose a register row over that helper route: three minors and a re-vendor for no reachable benefit. | 2026-09-24, executing `LK-30` of the 2026-09-23 remediation plan | Any of these frames registers an event newer than the current expansion, or a fourth private registration site appears in `LibKa0s/`. Either reopens the choice between this row and routing every site through `lib.SafeRegisterEvent`. |

**Five rows.** Two are not prose at all — a path fragment and two third-party API identifiers. The
third declines a kit gate in favor of this repo's own, which is a state `testing-§9` names and the
suite inventory reads. The fourth keeps one duplicated client read out of a release that promised to
change no existing file. The fifth keeps three widget-owned UI frames on raw core-event
registration, outside a rule written for addon event traffic. The table is otherwise empty
on purpose:
the alternative is a register that gets created in the same breath as the first deviation, by whoever
is already arguing for it.

`library-stack-§7`'s "does not apply" list is **not** a deviation register — those sections do not
bind this repo at all, so there is nothing to ratify. A row belongs here only when a section that
*does* bind is knowingly not followed.

### Files over the 1500-line cap

`layout-§1` caps every **authored** `.lua` file this repository tracks at 1500 lines. Two things are
worth stating explicitly here, because this repo was one of the four that read the old, silent text
differently: the cap binds `tests/`, and it binds a Ka0s-owned library's own payload folder — that is
what `library-stack-§7`'s applicability list settles, and it is why the 2026-09-07 audit's Low grade
on both breaches below no longer stands. `testkit/` is **authored here** and capped like anything
else; `tests/_kit/` is this repo's own vendored copy of it and is not, on the same terms every
consumer's copy is exempt. The second carve-out, generated non-shipping data, has no instance here.

**The heading is nested, and the gate is the kit's.** From kit revision 25 the census's parent is
fixed at `## Documented deviations` in whichever document hosts it, so the level follows that
register rather than the host — a `##` register takes a `###` census beneath it, here and in the
ten repos that host theirs in `docs/ARCHITECTURE.md`. This repo owed that one-level move and this
is it. What reads the table is now `tests/_kit/test_layout_cap.lua`, wired as
`{ name = "test_layout_cap", dir = "tests/_kit/" }`; the hand-written copy this repo carried is
deleted, because a twelfth local copy of a gate the kit ships is the drift the kit gate exists to
end — five repos wrote their own and no two were byte-identical. The two facts the gate cannot
infer arrive through `Kit.layoutCap` in `tests/run.lua`: `hub = "CLAUDE.md"`, because this is where
a library repo keeps its engineer context, and no `exempt` set, because the generated-data
carve-out has no instance here.

A file over the cap has three terminal states, not one: peeled, an **open issue naming the seam** a
peel would follow, or a **ratified row** in the `## Documented deviations` register this heading
now nests under, carrying a re-check
trigger. What the rule refuses is a fourth state — a breach nothing anywhere remarks on, "the count
sitting in a bundle manifest that no document reads". This repo had precisely that: an `overCapFiles`
figure in the `docs/automated-tests/` manifests that no document read, and a RESULTS.md watch list
that denied it. This table is the remark, and it is why an audit **MUST NOT** re-file `layout-§1`
against a file in it.

Two files, measured 2026-09-23 at kit revision 25, re-measured the same day at v1.55.0
(`06b4051`, the three new majors) and again at kit revision 26 with neither row moving, and on
2026-09-24 during the remediation's first milestone, where `LibKa0s/OptionsWidgets.lua` had come
down to 3852 (`LK-28` moved `RenderTabbedSchema` out to `LibKa0s/OptionsTabs.lua`), with

```sh
git ls-files '*.lua' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn
```

| File | Lines (2026-09-24) | Disposition |
|---|---|---|
| `tests/test_options_widgets.lua` | 4086 | Issue [#33](https://github.com/tusharsaxena/LibKa0s/issues/33) — the `ResolveId` / `IdInput` / `IdList` cases (lines 814–2225 as measured at v1.47.0, 1412 of them, minor 24's `columns` block included) peel with `LibKa0s/OptionsWidgets.lua`'s id half, on that file's seam and in that file's commit. That does **not** clear the cap on its own and #33 says so; the further cut is chosen from the file as it stands after #32, not guessed at now |
| `LibKa0s/OptionsWidgets.lua` | 3852 | Issue [#32](https://github.com/tusharsaxena/LibKa0s/issues/32) — the id surface out to `OptionsIds.lua`: the module-scope `id resolution` and `suggestions while typing` blocks (lines 386–970, 585 of them) plus the lookup, list and suggestion-dropdown members inside `lib.__AttachWidgets` (lines 1813–3011, 1199 of them) — both ranges as measured at v1.47.0, to be re-derived from the file as it stands when the cut is made. Leaves the makers and the flow engine at 1471, on that measurement |

**v1.39.0 peeled the chrome, and the two Options rows survived it.** Issue [#16](https://github.com/tusharsaxena/LibKa0s/issues/16)
named one seam — the tab and page chrome — and that seam is now `LibKa0s/OptionsTabs.lua`, which
left v1.39.0 at 973 lines and is **1489** today, minor 22's combat lock, minor 23's dispatcher and,
on 2026-09-24, `RenderTabbedSchema` (`LK-28`) having landed in it since; its cases are in
`tests/test_options_tabs.lua` (1218; 842 before `LK-27` and `LK-28`).
Both issues are closed and both peels are done. What they did not do is clear the cap, and the
arithmetic says why rather than the effort: `OptionsWidgets.lua` was **1989** lines when #16 was
written and **3700** when it was executed, because Options minor 16's id surface landed in between;
it was 3922 with everything up to minor 30 in it, and is 3852 now that `RenderTabbedSchema` has
left it. A peel sized against the file of 2026-09-08 was never
going to fit the file of 2026-09-16. The rows above are retargeted at what is left rather than
deleted, which is the whole point of a census a gate reads.

**Both rows are issues, not register rows.** The sibling repository doing this same work gives
its *mirror suites* register rows rather than issues, on the argument that a suite has no seam of its
own. That argument holds here too and is written into #8 — the suite peels on the module's seam, in
the module's commit — but the row would have been a second record of a file that **already had an
open issue**, opened when the file was 1114 lines and carrying its own hard trigger, "crosses 1500 →
split". That trigger has fired. Rewriting the issue it fired on is one record; a register row beside
it would be two records free to disagree, which is the failure this section exists to prevent. The
deviation register above also stays deliberately near-empty (see its note), and a breach with a live
issue is not a deviation from the standard — it is one of the states the standard allows.

**`testkit/framework.lua` was a third row, and kit revision 26 peeled it rather than ratifying
it.** Kit revision 25's `resolveDir` / `adviceDir` pair, a fix two consumers needed before their
suites could run at all, took the file past the cap, and v1.55.0's complexity split left it at 1583.
Its row read "Ratified deviation row", but the `## Documented deviations` register above never held
one: a disposition naming a terminal state that did not exist, which the 2026-09-23 audit filed as
`LK-34`. Revision 26 moved the assertions and the surface-parity gate out to `testkit/asserts.lua`,
a seam that shares no state with the rest of the file, and that left `framework.lua` at 1381 with
nothing for the row to record, so the row is gone rather than repaired. The seam the row had named
for a peel, the suite inventory, is still there for the next revision that needs the room.

**The line counts are dated, and nothing asserts them.** What `tests/_kit/test_layout_cap.lua`
asserts is
the *membership* of this table, in both directions: a file that crosses 1500 and is not listed here
turns the suite red, and so does a row for a file that has fallen back under the cap or been deleted,
so the census cannot become a graveyard. A figure in this column is a measurement, not a claim about
today — `OptionsWidgets.lua` was 1838 at the 2026-09-07 review and the suite 2287, then 1989 and
2398 on 2026-09-08, 2812 and 3285 on 2026-09-16, 3113 and 3541 earlier on 2026-09-20, 3922 and 4086 on 2026-09-22, and both moved
while nobody was watching, which is the whole argument for having a gate rather than a paragraph.

**A peel here is a release, and v1.39.0 is the worked example.** `LibKa0s/` is re-vendored
whole-folder into eleven consumers and every file in it carries its own LibStub minor, so a peel adds
a payload file, a `LibKa0s.xml` row, a minor, a row in `tests/majors.lua`, the multi-file pairing
guard on its own minor **and** the shell's (`lib.__tabsMinor` / `lib.__tabsShellMinor` in
`LibKa0s/OptionsTabs.lua`, following `lib.__widgetsShellMinor`), **a component on the major's version
key**, an API document and a regenerated manifest — a deliberate release, not a tidy-up. The
2026-09-07 remediation plan ruled out splitting any file (`03_SPEC.md` § C22 non-goals) and that
cycle's deliverable was the disposition; this cycle executed it.

**The 1000–1500 band is on notice, not in breach**, and every figure in it was re-measured with the
same command on **2026-09-24 at kit revision 26** (v1.56.0, unreleased, after `LK-29`). It is prose
rather than a second table on purpose: the gate above reads every backticked-path table row under
this heading as a census row, so a band table here would be thirteen rows claiming to be breaches.
Thirteen files, two more than the eleven the band held when it was last written out:
`tests/test_widgets.lua` (1493),
`LibKa0s/OptionsTabs.lua` (1489; 1197 at the last write-out, which the write-out before that still
recorded at **973** — v1.39.0's peel figure — two releases after minor 22's combat lock and minor
23's dispatcher had moved into it; `LK-27`'s page-chrome fix and `LK-28`'s `RenderTabbedSchema` took
it the rest of the way),
`testkit/test_prose.lua` (1486; 335 at v1.54.2, and kit revision 25 took it to 1499, one line from
the cap, until kit revision 26 moved its published lists out to `testkit/prose_lists.lua`; 1464
after that peel, and `LK-07` / `LK-08` added the rest),
`LibKa0s/Options.lua` (1457; 1312 at v1.40.0, then 1460 at v1.46.0 with minor 22's combat lock,
whose event frame and cover geometry went to `LibKa0s/OptionsTabs.lua` to keep it under the cap,
1465 at v1.46.1 with the dispatcher moved there too, and 1476 at the last write-out; `LK-24` moved
the font preload out to 1376, `LK-25`'s park took it to 1454 and `LK-26` to 1457),
`testkit/mock_base.lua` (1454; 1452 with the shown-by-default flip's four comment lines, 1448 with
`testkit/mock_events.lua`'s load, hook and install lines, 1446 before them — it was 1499 at kit
revision 21, one line from the cap; kit 20's id lookups went to `testkit/mock_ids.lua` for that
reason, and kit 22's recording surveys to `testkit/mock_record.lua` for the same one, which is what
took it back down),
`testkit/framework.lua` (1385 with `assertLibraryConstant`'s expose line and LibStub-fallback
wiring; 1383 with the section-sign note on `KIT_GATE_RULE`; 1382 with `Kit.expose`'s
`assertErrorMatches` line; 1381 when the peel took it back into the band from the census above),
`tests/test_options.lua` (1339; 1307 at the last write-out),
`tests/test_schema.lua` (1335; 1101 when it was new at v1.55.0 with the Schema major, 1233 at the
last write-out, before `LK-22` and `LK-23`),
and, since v1.34.0, `tests/test_slash.lua` (1327 at v1.42.0, with minor 14's
reserved-but-unregistered case, and unmoved since; 1302 at minor 13's restored disabled surface,
1265 at minor 12, 1054 before the gate),
`LibKa0s/Perf.lua` (1319 with `LK-20`'s minor 13; 1308 with minor 12's latch, 1231 at v1.39.0,
tracked as [#7](https://github.com/tusharsaxena/LibKa0s/issues/7)),
`LibKa0s/Widgets.lua` (1266 with `LK-21`'s minor 10; 1232 before it),
`tests/test_options_tabs.lua` (1218, new to the band: 842 before `LK-27` and `LK-28` put their cases
in it), and `tests/test_options_idsuggest.lua` (1002, new to the band: 999 at the last write-out,
until `LK-05`'s shown-by-default frames). They are named so a later reader can tell the band was looked at rather than missed. The seven
the 2026-09-23 audit found with an expired or blank watch-list disposition carry one now (see *The
band's terminal states* below); the rest need none until they cross, and three are close enough that the next edit to each should
be a new file rather than an append: `tests/test_widgets.lua` at 1493 has seven lines of room,
`LibKa0s/OptionsTabs.lua` at 1489 eleven, and `testkit/test_prose.lua` at 1486 fourteen.
v1.32.0's
bulk-bracket cases went to their own suite, `tests/test_options_bulk.lua`, rather than into
`tests/test_options.lua`: they took it to 1544 lines, and they peel on a seam of their own. v1.33.0's
font-preload cases did the same, into `tests/test_options_fontpreload.lua`. **v1.48.0 is the band
paying for itself, twice in one release.** The drag handle written into `LibKa0s/Widgets.lua` took it
to **1540** and its cases appended to `tests/test_widgets.lua` would have taken that file past the
same line from seven under it, so both went to files of their own —
`LibKa0s/WidgetsDragHandle.lua` (507 then, 621 now) and `tests/test_widgets_draghandle.lua` (668
then, 901 now), neither of them in the band. That is a cut chosen while the seam was still obvious
rather than one sized against a file three releases older than the peel, which is what the two rows
above record going wrong.

**The band's terminal states, ruled 2026-09-24.** `automated-tests-§4` refuses an "accepted" that
outlives three consecutive release runs and a newly crossed entry with no disposition, and the
2026-09-23 audit (`LibKa0s-A-03`) found seven band files in one state or the other. Each now has one
of the two terminal states a band entry may carry, and `docs/automated-tests/RESULTS.md`'s
Disposition cells point here:

- `tests/test_options.lua` (1339) — issue [#35](https://github.com/tusharsaxena/LibKa0s/issues/35):
  the render/refresh block peels to `tests/test_options_render.lua`. This is the "owed a tracked ID"
  the watch list carried with no ID.
- `LibKa0s/Widgets.lua` (1266) — issue [#36](https://github.com/tusharsaxena/LibKa0s/issues/36):
  per-widget files, `ReorderList` first.
- `tests/test_widgets.lua` (1493) — issue [#37](https://github.com/tusharsaxena/LibKa0s/issues/37):
  split by widget family, the `ReorderList` and row-box cases first; its trigger is *any* new case.
- `tests/test_schema.lua` (1335) — issue [#38](https://github.com/tusharsaxena/LibKa0s/issues/38):
  split by pipeline stage, the write stage onward first.
- `testkit/test_prose.lua` (1486, still in the band after `LK-01` / `LK-07`) — issue
  [#39](https://github.com/tusharsaxena/LibKa0s/issues/39): the narrowing and coverage machinery
  peels to a kit module of its own at the next kit revision that touches the file.
- `LibKa0s/Options.lua` (1457) — **re-ruled 2026-09-24: accepted.** It passed the old "re-check at
  1350" at 1476 with nobody re-ruling it. `LK-24` then took the seam that ruling had named, the font
  preload, out to `LibKa0s/OptionsScroll.lua`, and what came back (`LK-25`'s park, `LK-26`) is combat
  handling on the panel builder every host enters through, where a split is a published-surface
  change rather than an internal tidy. **Re-check trigger: the next member added to `Options.lua`,
  or 1475 lines**, whichever comes first; at either, the next member goes to a new file.
- `LibKa0s/OptionsTabs.lua` (1489, measured after `LK-28`) — **re-ruled 2026-09-24: accepted.** It is
  the v1.39.0 chrome peel plus minor 22's combat lock, minor 23's dispatcher, `LK-27`'s page-chrome
  fix and `LK-28`'s `RenderTabbedSchema`, all of it the tabbed page's own machinery with no second
  seam inside it. **Re-check trigger: the next member added to `OptionsTabs.lua`, or 1495 lines**;
  with eleven lines of room, that member is a new file, not an append.

The two re-rule triggers sit above the 1450 the plan wrote for them because both files were
already past 1450 when they were ruled: 1457 and 1489 as measured, not the "about 1416" the plan
projected for `Options.lua`. A trigger that has already fired on the day it is written is no
trigger.

**`testkit/framework.lua` left the band during kit revision 25 and came back at 26.** It was
never named in the band at all until that revision's write-out put it at 1484; the revision's two
fix passes took it to **1571**, which is a breach and not a notice, so the row moved up into the
table rather than staying in this paragraph, and kit revision 26's peel brought it back down. The previous write-out of this band said the figures
around it were re-measured at kit revision 25 and that only `testkit/framework.lua` had moved. That
was wrong on the day: the same revision took `testkit/test_prose.lua` from 335 to 1499, into the
band, and nothing named it. The re-measurement above is the correction.

**`tests/test_slash.lua` (1327) — re-ruled 2026-09-24: accepted**, by the review of `LK-33`. The
v1.56.0 release run (`docs/automated-tests/20260924-040553/`) left its Disposition cell as carried
from v1.34.0, "466 lines clear of the cap … Re-check at 1350", when the file already stood at 1327
with 173 lines of room, and that bundle's `ANALYSIS.md` says every Disposition cell was "ruled at
this run" and lists the row as *Carried: re-check at 1350*. Both are wrong for this row; the bundle
is frozen, so this paragraph and the row's `RESULTS.md` cell are the correction. The file is a flat
list of independent cases mirroring `LibKa0s/Slash.lua` (863), and the parser block (`ParseBool`
through `ParseValue`) is its peel seam, as `tests/test_slash_parse.lua`. **Re-check trigger: the
next Slash minor that adds parser cases, or 1400 lines**, whichever comes first; at either, the
parser block peels before the append.

## Documentation map

`documentation-§3`'s tier model does not bind a library repo (see the applicability list above), so
there is no `ARCHITECTURE.md` and no Tier 1 set. What the tier model is *for* does still apply here:
a reader must be able to tell a doc that is missing from one that was never meant to exist, and no
page under `docs/` should be reachable only by listing the directory. So this section is the register,
in the place a library keeps its registers — this file.

**Every `.md` under `docs/` appears below.** Frozen and generated directories are named once each and
never enumerated per run: `docs/audits/`, `docs/reviews/`, `docs/automated-tests/`,
`docs/adoption/`, `docs/superpowers/`.

| Doc | Covers |
|---|---|
| [`README.md`](README.md) | What each module is, how to install and re-vendor, the repo layout |
| [`docs/api/`](docs/api/) | **The source of truth for every public contract** — one document per shipped version, per major (`Core`, `Env`, `Compat`, `Lifecycle`, `Bus`, `Schema`, `Pool`, `Item`, `Media`, `Widgets`, `DebugLog`, `Slash`, `Launcher`, `Options`, `Perf`, and `testkit`), and beside each one a generated `members-<version-key>.json` naming that version's public surface as data. A superseded document is never edited to describe new behavior; a manifest is never hand-edited at all — regenerate with `lua tools/gen-api-members.lua` |
| [`docs/releasing.md`](docs/releasing.md) | The two version numbers (repo semver and the load-bearing per-file LibStub minor), the numbered release order, and the re-vendor rule |
| [`docs/record-schema.md`](docs/record-schema.md) | The in-game Perf capture record, field by field — the contract each consumer's `perf-analysis/README.md` points at rather than restating |
| [`docs/adoption-prompt.md`](docs/adoption-prompt.md) | The brief handed to a consumer repo adopting a major: what to wire, what to delete, and what must not be hand-rolled |
| [`docs/fast-gate-adoption-prompt.md`](docs/fast-gate-adoption-prompt.md) | The drop-in brief for adopting the fast test gate in a consumer repo — what to copy, and the measured before/after it replaced |
| [`docs/adoption-report.md`](docs/adoption-report.md) | The collection-wide adoption state — which consumer has taken which major, and what each declined |
| [`docs/test-cases.md`](docs/test-cases.md) | The generated case inventory; regenerate with `lua tests/run.lua --list`, never by hand |
| [`docs/automated-tests/README.md`](docs/automated-tests/README.md) | The four out-of-game suites, what each gates at which checkpoint, and where the frozen bundles live |
| [`docs/automated-tests/RESULTS.md`](docs/automated-tests/RESULTS.md) | One row per run; generated, never hand-edited |
| [`CHANGELOG.md`](CHANGELOG.md) | Required at a library root (`library-stack-§7`) — `testing-§10`'s versioning suite reads it |
| [`DEPENDENCIES.md`](DEPENDENCIES.md) | What to install before any of the above will run |

Adding a page under `docs/` means adding a row here in the same change. A page reachable only by `ls`
is the failure this table exists to prevent — `docs/adoption-prompt.md`, `docs/adoption-report.md`
and `docs/adoption/` were each in exactly that state before this section was written.

## The green gate

No commit without both of these clean, from the repo root:

```sh
lua tests/run.lua   # 0 failed  — `lua` MUST be 5.1; see DEPENDENCIES.md for why
luacheck .          # 0 warnings / 0 errors
```

That `luacheck` figure is **scoped by `.luacheckrc`'s `exclude_files`**, not repo-wide: everything
but `tests/_kit/` (the same scope `docs/releasing.md` step 1 gives). How many files that is, no
prose here says: luacheck prints it (`in N files`), and every run's
[`docs/automated-tests/RESULTS.md`](docs/automated-tests/RESULTS.md) *Lint* section carries it,
generated, with the exclusions named beside it. A hand-typed copy of that count is one more figure
to drift, and it did. 0/0 only means something if the files carrying the change are inside the
checked set.
