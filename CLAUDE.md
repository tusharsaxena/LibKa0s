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
  (US English in authored text — a British spelling here is vendored into every consumer and
  becomes one finding per consumer); `documentation-§5`; `documentation-§7`.
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

**One extra rule this repo carries, because it is upstream of every consumer addon.** Everything in
`LibKa0s/` and `testkit/` is **vendored** — into `<Addon>/libs/LibKa0s/` and `<Addon>/tests/_kit/`
respectively. A defect shipped from here reappears in every consumer, and a fix is only real once it
is re-vendored. Never patch a vendored copy downstream; fix it here and copy across.

## Documented deviations

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|
| `localization-§5` | `testkit/mock_base.lua` and `testkit/mock_record.lua` reproduce AceTimer-3.0's handle field, read as a member access (`.cancelled`), and the `IsCancelled` method of Blizzard's `C_Timer` handles, verbatim; `tests/test_mock_ace.lua`, the suite that pins those fakes, reads both as the fakes spell them | Third-party API identifiers, not prose. The kit's AceTimer fake hands out AceTimer's own handle table, and a suite written against the real field reads `handle.cancelled`; a kit that renamed it would answer nil there and pass, which is fidelity rule 1's failure (`testkit/mock_base.lua`'s header). The same for `IsCancelled`, which a `C_Timer.NewTimer` handle answers in the client. `tests/test_prose.lua`'s `RATIFIED` carries exactly these spellings for exactly these two files, matched as `.cancelled` and `iscancelled`, and its `AUTHORED_RATIFIED` the same two for `tests/test_mock_ace.lua` and for this register, which names them, so prose in the same files is still held to US English. Filed by the v1.31.0 review (commit `1f1790c`, recorded in `docs/api/testkit/version-17-docs.md`); the second path arrived with kit revision 22, which peeled the timer queue and both handle kinds out to `testkit/mock_record.lua`, and the suite's path with the US-English sweep of `tests/` (commit `68072ed`, `LK-29` of Ka0sAddonsCommonTasks `docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/`). | 2026-09-12, owner decision on the v1.31.0 review; extended to `tests/test_mock_ace.lua` 2026-09-24, executing that plan's `LK-29` | AceTimer renames the field, or the kit stops modeling the handle (and `C_Timer` renames `IsCancelled`, or the kit stops modeling `NewTimer` handles). `tests/test_prose.lua` reddens on its own if any of these exemptions stops matching. |
| `localization-§5` | `lib.ICONS` keeps `minimise`, the one British spelling left in the shipped payload | The key is not prose. `lib.Icon` (`LibKa0s/Media.lua:309`) builds the texture path **from** the key — `base .. ICON_DIR .. "\\" .. name` — and the file on disk is `minimise.tga`, vendored into every consumer's `libs/LibKa0s/media/icons/`. Renaming the key alone points at a texture that does not exist, and `Media.lua:293-299` records what that costs: a texture that fails to load draws nothing and raises nothing, so the icon simply disappears from every consumer's title bar with no error anywhere. Renaming it safely needs a second `.tga` or an alias map, which is a change to `Media.lua`'s surface, not a spelling fix. Filed as `LK-06` in `docs/audits/2026-09-07/`, which names the key as "a key consumers bind against" and asks for an alias rather than a rename. | 2026-09-07, executing `M1-LK-11` | A `minimize.tga` shipped beside the current file, or an alias map in `lib.Icon` — either ends this row, and the key moves in the same change as the eleven consumers' re-vendor. `tests/test_prose.lua` reddens on its own if the exemption ever stops matching, so a dead row cannot sit here unnoticed. |
| `localization-§5` | `tools/artwork/fonts.py` spells `DialogueUI`, in the path and the record of the Friz Quadrata it copies | A third-party add-on's folder name, not prose: the path is what `--fetch` opens, and a respelled one finds nothing. `tests/test_prose.lua`'s `AUTHORED_RATIFIED` carries the exact name for that one file | 2026-10-31, the owner's font run, Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` | The copy moves to another source, and the gate reddens when the exemption stops matching. |
| `localization-§5` | The kit ships a US-English gate (`tests/_kit/test_prose.lua`) and this repo leaves it unwired, running its own `tests/test_prose.lua` instead. `testing-§9` and `localization-§5` between them permit exactly that — wire the kit's copy, or wire your own and record why the kit's is unwired — and this row is the record. The suite inventory reads it and reports the kit's copy once, as a declared skip carrying this reason, so the decline appears in `docs/test-cases.md` and in every run's output rather than as a gate nobody knows is not running. | The kit's copy is the broader gate over the same rule and the narrower one over this repo. Broader: it reads the whole tracked set, where this repo's reads only the two folders whose bytes ship. Narrower: this repo's copy carries two cases the kit's has no equivalent for — no non-ASCII byte reaches a player from the shipped library, the em dash excepted, and no retired `§N.M` section reference survives in the shipped library or the shipped kit — and wiring the kit's copy alone would retire both over the payloads eleven consumers receive by copy and cannot fix for themselves. The ASCII case reads `LibKa0s/` only: the kit prints to a terminal and `tests/_kit/` never ships, so from kit revision 26 kit strings carry the section sign in their citations. What the extra breadth would cost was measured on 2026-09-23 at kit revision 25: the kit's copy reports **1121 lines across 147 files** here. **Twelve of them are in the shipped payload outside the gate's own source, and all twelve are the two rows above** — the gate this repo runs is already green over everything it ships. The other 1109 are records this repo must not rewrite or does not write at all: 560 in `docs/api/`'s frozen per-version documents, 150 under `tests/`, 118 under `docs/adoption/`, 107 under `docs/superpowers/`, 63 in `CHANGELOG.md`'s entries, 46 in the generated `docs/test-cases.md`, and 23 in `testkit/test_prose.lua` itself, which quotes every forbidden spelling in order to forbid it and gained six more with kit revision 25's carve-out fixtures. That 2026-09-23 figure also counted 21 lines in `docs/adoption-prompt.md`, which is a live page and not a record: it has since been swept to US English with `docs/adoption-report.md`, and `tests/test_prose.lua` gates both (`LK-08` of Ka0sAddonsCommonTasks `docs/2026-10-07-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/`, resolving `LK-28` of this repo's `docs/audits/2026-10-07/`). The measurement itself is not recomputed. Re-measured 2026-09-23 after the revision-25 fix passes, with the kit's gate wired in a throwaway copy of this checkout; the figures before that re-measurement were 1115 / 143 / 17. The kit's exclusion list named five frozen-bundle folders at revision 25 and this repo has three more of its own. Revision 26 takes one of the three, `docs/superpowers/`, into the kit's list with `docs/investigations/` (which this repo does not have), so the 107 lines there leave the count, and reads the two `docs/automated-tests/` store-root files back in, which this repo's own gate now reads as well; closing the gap with per-file waivers is the whole-file waiver `localization-§5` forbids, and closing it with `skipDirs` would leave 150 real hits under `tests/`, which is a US-English sweep and not an integration. That sweep landed on 2026-09-24 (commit `68072ed`, `LK-29` of Ka0sAddonsCommonTasks `docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/`, resolving `LK-28` of this repo's `docs/audits/2026-09-23/`): `tests/`, the live document of every major under `docs/api/` and that folder's README, `docs/releasing.md`, `README.md`, `DEPENDENCIES.md`, this file and `tools/artwork/` carry **0** prose hits (the two adoption pages joined them on 2026-10-07), and `tests/test_prose.lua` now gates them in a case of its own. | 2026-09-23, integrating kit revision 25 | The kit's copy grows the non-ASCII and retired-section cases, **or** `docs/api/`, `docs/adoption/`, `docs/superpowers/` and released changelog entries join the kit's own frozen-bundle exclusions and this repo's `tests/` prose is swept to US English. Either ends this row. The sweep half is done (0 prose hits under `tests/` and in the live docs since 2026-09-24), so what is left of the second is the kit's own frozen-bundle exclusions. |
| `compat` | `LibKa0s/Perf.lua` reads the specialization globals inline (`P.Context`'s `C_SpecializationInfo.GetSpecialization` / `GetSpecializationInfo` read in `LibKa0s/Perf.lua`, in the file-level `specName` P.Context's reader table calls since `GI-LK-11`, cited by function rather than line because Perf's line numbers move with every peel), duplicating `LibKa0s-Compat-1.0`'s spec pair (`lib.GetSpecialization`, `LibKa0s/Compat.lua:270`, and `lib.GetSpecializationInfo`, `:289`). The copies are not identical: Perf's takes the namespaced rung for the index reader only and calls the `GetSpecializationInfo` global directly, where Compat's ladders both. | Raising Perf's floor to Compat is a vendoring break for eleven consumers (`ls -d ../*/libs/LibKa0s/Perf.lua \| wc -l` from this checkout, 11 on 2026-09-23) in a release declared additive: v1.55.0 moves no existing file's minor, and a new floor is the change to the vendoring `library-stack-§7` treats as breaking. Ruled as reading A of the Compat major's open question on this read; [the Compat document](docs/api/Compat/version-1-docs.md) states the same decision under *The library's own inline spec read*. This row supersedes `LK-31` in the frozen `docs/audits/2026-09-08/` bundle (`04_TECHNICAL_DESIGN.md`, `05_EXECUTION_PLAN.md` step 5), which asked for one owner of the spec reader and proposed `Core.lua`, with `Env.lua` as the alternative. Neither was taken; Compat now exists as that owner, and the only open question is when Perf floors on it. The bundle is not edited. | 2026-09-23 | The next Perf floor raise made for any other reason. |
| `events-frames-taint-§1` | Three widget-owned private frames call `RegisterEvent` raw, with no pcall'd per-event helper, no player-reachable rejected-name record and no AceEvent: `LibKa0s/OptionsCombat.lua`'s combat lock (`PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` on `lib.__combatFrame`, in `lib.__syncCombatEvents` and `lib.__pageShown`; `LibKa0s/OptionsTabs.lua`'s until the 2026-09-26 automated-tests sweep moved it there, unchanged), `LibKa0s/Widgets.lua`'s popup-menu dismiss (`GLOBAL_MOUSE_DOWN` on the shared dropdown menu, in the dropdown button's `OnClick`), and `LibKa0s/OptionsRegistry.lua`'s park frame (`PLAYER_REGEN_ENABLED` on `lib.__parkFrame`, in `lib.__parkRegistration`, from Options minor 24 and commit `d02a161` (`LK-25` of Ka0sAddonsCommonTasks `docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/`); `LibKa0s/Options.lua`'s until the same sweep moved it there, unchanged). | The section is written against an addon's event traffic (`addon:RegisterEvent`, a module's disable path, the player-facing debug verb), and these frames carry one widget's UI state, not the host's. Its per-event isolation exists so that one retired or misspelled name cannot deafen a registration block; the names here are stable core client events, so that failure has no route in. This row is **not** justified by "the library cannot use AceEvent": `LibKa0s/Bus.lua` already resolves AceEvent-3.0 at call time, and `lib.SafeRegisterEvent` (`LibKa0s/Core.lua`) is the pcall'd helper the section asks for, available to any of these sites. Filed as `LK-37` by the 2026-09-23 audit (`docs/audits/2026-09-23/`), which chose a register row over that helper route: three minors and a re-vendor for no reachable benefit. `LibKa0s/OptionsKeybinds.lua`'s `UPDATE_BINDINGS` frame (`lib.__keybindEventFrame`, from OptionsKeybinds minor 3) registers through `lib.SafeRegisterEvent` on purpose, so it is not a fourth raw site and does not fire this row's trigger. | 2026-09-24, executing `LK-30` of Ka0sAddonsCommonTasks `docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/` (commit `6eaa41f`) | Any of these frames registers an event newer than the current expansion, or a fourth private registration site appears in `LibKa0s/`. Either reopens the choice between this row and routing every site through `lib.SafeRegisterEvent`. |
| `library-stack-§7` | `LibKa0s/WidgetsLineChart.lua` (Widgets key 12.1.4.1, v1.69.0) is promoted into the library with **one** consumer, LootHistory's Timeline tab (its `NS.MakeLineChart` seam), where the section's "What earns promotion into a Ka0s-owned lib" bar 1 asks for two or more consumers with the same semantics. | The owner ruled to build the chart here from the start (LootHistory `docs/superpowers/specs/2026-10-06-timeline-ledger-design.md`, §13 F3) rather than inside the addon and lift it later: a chart is a widget any Ka0s addon with a time series can draw, its math is pinned headless here (`tests/test_widgets_linechart_math.lua`), and it ships as a secondary file paired on the Widgets shell's minor, so it costs no consumer a setup seam and a host that draws no chart owes nothing. A ratification recorded only in an addon's spec is in no register, so the timeline-ledger plan's standards flag S1 put it to the owner, who chose this row over an upstream change to the standard. Its first re-check trigger ("one release passes after v1.69.0 with no second consumer named") fired at v1.70.0, which named none; the owner then ruled to keep the chart here, and the row stands as an **accepted** deviation. | 2026-10-06, the timeline-ledger plan's S1; accepted 2026-10-07 by the owner, after its re-check trigger fired at v1.70.0 | A second addon draws a chart (then the row is retired), or the chart's API needs a breaking change. |
| `library-stack-§7` | `LibKa0s/OptionsDrawer.lua` (Options key 29.2.34.2.4.8.1.7.4.2.1, v1.73.0), `O.Drawer`, is promoted into the library with **one** consumer, Ka0s Quick Comms' When tab (`settings/Groups_When.lua`), where the section's "What earns promotion into a Ka0s-owned lib" bar 1 asks for two or more consumers with the same semantics. | The owner ruled to build the drawer here rather than inside the addon (Quick Comms `docs/superpowers/specs/2026-10-18-when-drawers-design.md`, goal 2: "If needed, create a new LibKa0s component to build this"), so that it looks like the settings panel the library already draws and any Ka0s page with a list of conditions or filters can fold them the same way. It ships as an eleventh file paired on the Options shell's minor and attached behind a guard, so a host that draws no drawer owes nothing but a `Drawer` no-op in a degradation stub pinned by name; its body ctx and its pooled-frame hygiene are pinned headless here (`tests/test_options_drawer.lua`). The spec flagged the one-consumer promotion for this register, as the line chart's was. | 2026-10-18, the owner's ruling recorded in that spec (L1 of its plan) | A second addon draws a drawer (then the row is retired), or one release passes after v1.73.0 with no second consumer named (then the choice between this row and moving the drawer into Quick Comms is reopened for the owner), or the drawer's API needs a breaking change. |
| `automated-tests-§4` | Five files in `layout-§1`'s 1000–1500 band have been carried as *accepted* past the watch list's three-run shelf life, and this row is their tracker. Measured 2026-10-07 with the command under *Files over the 1500-line cap*, each with its seam and its trigger: `LibKa0s/OptionsWidgets.lua` (1066 at minor 39, measured 2026-10-31, after the flow engine peeled on its named seam to `LibKa0s/OptionsFlow.lua` (360); seam now: the choice grid, `O.ChoiceGrid` and its helpers; trigger: 1250 lines or the next maker added), `LibKa0s/OptionsIdList.lua` (1290, re-measured 2026-10-31 at minor 7; no seam inside it, since the list and its entry-line layout are one piece of machinery, so at the trigger a seam is named before the append; trigger: 1350 lines), `LibKa0s/OptionsTabs.lua` (1382, re-measured 2026-10-31 at minor 11, no member added; seam: the tabbed page, `O.RenderTabbedSchema` and its helpers; trigger: the next member added or 1400 lines) and `LibKa0s/Options.lua` (1335, re-measured 2026-10-31 at minor 34, no member added; 1332 at minor 33's one guarded `__AttachAppearance` line in `attachHalves` and its two header lines, no member added: the Appearance tab's members are `LibKa0s/OptionsAppearance.lua`'s, attached the way `OptionsKeybinds.lua`'s are; 1329 at minor 32's one `__AttachSkinAce` line in `attachHalves`, no member added (1325 at minor 31's two skin calls); seam: the reset walk, `runBulk`, `O.RestoreDefaults` and `O.RestoreAllDefaults`; trigger: the next member added or 1400 lines). Peeled for v1.84.0 (step 1 of Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`, on these seams), and out of this row: `LibKa0s/OptionsIds.lua`. | No file is over the cap, four have a named seam and the fifth has its trigger, and a peel is a release with a re-vendor into eleven consumers (*A peel here is a release* below), so each is scheduled at its trigger rather than now. The section asks for a tracked deviation with an id and an owner once an *accepted* outlives three release runs. Three of the five cells cited issue #32, which is closed, and an item of the finished 2026-09-26 automated-tests sweep, and neither is a tracker. Filed as `LK-17d` by the 2026-10-07 audit (`docs/audits/2026-10-07/`), which asked for an open issue per file. That remediation run ruled out opening new issues, so the tracker is this row (item `LK-09` of Ka0sAddonsCommonTasks `docs/2026-10-07-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/`). | 2026-10-07, owner Tushar Saxena, under the owner's standing autonomy for that plan | Any of the five reaches its trigger, and then that file peels on its named seam in the change that reaches it. **Or** a GitHub issue is opened to track the band, and then this row is retired in favor of it. |
| `automated-tests-§4` | Six payload files in `layout-§1`'s 1000–1500 band had a fired re-check trigger, a spent three-run shelf life or no tracker, and this row is their tracker (id `FX-LK-SIZE`). Measured 2026-10-31, each with its seam and its trigger: `testkit/mock_base.lua` (1465; seam: the Ace fakes, the CallbackHandler registry through AceGUI; trigger: 1490 lines, or any kit change that adds more than 30 lines here), `LibKa0s/OptionsSkinPicker.lua` (1256 at minor 5, after the rows' section left it for `LibKa0s/OptionsSkinPickerRows.lua`; seam: the queue, to a file of its own; trigger: 1400 lines) and `LibKa0s/SkinPaint.lua` (1002; seam: the window block, to `LibKa0s/SkinPaintExtras.lua`; trigger: 1050 lines or the next SkinPaint minor). Peeled for v1.84.0 (step 1 of Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`, on these seams), and out of this row: `LibKa0s/Skin.lua`, `LibKa0s/SkinDefs.lua`, `LibKa0s/SimPanel.lua`. | No file is over the cap. Each seam is a new shipped file or a kit file, so a peel is a release with a re-vendor into every consumer (*A peel here is a release* below), and the remediation plan of 2026-10-31 rules out editing the payload, so no release follows it. `Skin.lua`, `SkinDefs.lua` and `SimPanel.lua` had spent the shelf life as *accepted*; `testkit/mock_base.lua` sat *on notice* outside any tracker; `OptionsSkinPicker.lua` and `SkinPaint.lua` join so that every payload row in the band has one. | 2026-10-31, owner Tushar Saxena, `FX-LK-SIZE` of Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/` | Any of the six reaches its trigger, and then that file peels on its named seam in the change that reaches it. **Or** a GitHub issue is opened to track the band, and then this row is retired in favor of it. |

**Ten rows.** Three are not prose at all — a path fragment, two third-party API identifiers and a
third-party add-on's folder name. The fourth declines a kit gate in favor of this repo's own, which is a state `testing-§9` names and the
suite inventory reads. The fifth keeps one duplicated client read out of a release that promised to
change no existing file. The sixth keeps three widget-owned UI frames on raw core-event
registration, outside a rule written for addon event traffic. The seventh promotes a widget with one
consumer, on the owner's ruling, accepted again after its first trigger fired, with a trigger that retires it or reopens it. The eighth does the same for the drawer, on its first release. The ninth tracks five band files whose acceptance
outlived its shelf life, each with the seam it peels on and the trigger that peels it. The tenth does the same for six payload files. The table is otherwise
empty on purpose:
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
consumer addons, which host theirs in `docs/ARCHITECTURE.md`. This repo owed that one-level move and this
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
that denied it. This section is the remark, and it is why an audit **MUST NOT** re-file `layout-§1`
against a file in it.

**Nothing is over the cap today**, measured 2026-09-26 at the end of the automated-tests sweep's
suite split, with the command below. There were two rows at the start of that sweep, and both left
the census in it. `LibKa0s/OptionsWidgets.lua` (3852 on 2026-09-24, after `LK-28` moved
`RenderTabbedSchema` out to `LibKa0s/OptionsTabs.lua`) left when issue #32's id surface moved out to
`LibKa0s/OptionsIds.lua` and `LibKa0s/OptionsIdList.lua`, which took it to 1422. The id surface was
about 2460 lines, more than one file under the cap can hold, so it went to two files rather than the
one #32 named. `tests/test_options_widgets.lua` (4086) left in two steps under issue #33: its
`ResolveId` / `IdInput` / `IdList` cases (92 of them, 1834 lines) went with the module's id half, in
that file's commit, to `tests/test_options_ids.lua`, `tests/test_options_idlist.lua` and
`tests/test_options_idlist_layout.lua` with their benches in `tests/fixture_ids.lua` (4086 → 2257),
and the 2257 that were left split on the suite's own case seams, every case moved unchanged:
`tests/test_options_choicegrid.lua` (425, `O.ChoiceGrid`), `tests/test_options_flow.lua` (801, the
flow engine and the tabbed page) and `tests/test_options_landing.lua` (340, `O.TextRow` and
`O.BuildLandingPage`), with the makers staying behind (717) and the shared bench in
`tests/fixture_widgets.lua`. The rows were earlier measured 2026-09-23 at kit revision 25, at
v1.55.0 (`06b4051`) and at kit revision 26, with

```sh
git ls-files '*.lua' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn
```

**v1.39.0 peeled the chrome, and the two Options rows survived it.** Issue [#16](https://github.com/tusharsaxena/LibKa0s/issues/16)
named one seam — the tab and page chrome — and that seam is now `LibKa0s/OptionsTabs.lua`, which
left v1.39.0 at 973 lines and reached **1493**, minor 22's combat lock, minor 23's dispatcher, minor 5's rail inset (`SR-LK-01`, v1.61.0) and,
on 2026-09-24, `RenderTabbedSchema` (`LK-28`) having landed in it since; its cases are in
`tests/test_options_tabs.lua` (1218; 842 before `LK-27` and `LK-28`; 954 after the 2026-09-26
sweep split the tabbed page's cases out to `tests/test_options_tabbed.lua`). On 2026-09-26 the
automated-tests sweep moved the combat lock's page chrome out to `LibKa0s/OptionsCombat.lua` (249),
which took it to **1293**.
Both issues are closed and both peels are done. What they did not do is clear the cap, and the
arithmetic says why rather than the effort: `OptionsWidgets.lua` was **1989** lines when #16 was
written and **3700** when it was executed, because Options minor 16's id surface landed in between;
it was 3922 with everything up to minor 30 in it, and is 3852 now that `RenderTabbedSchema` has
left it. A peel sized against the file of 2026-09-08 was never
going to fit the file of 2026-09-16. The rows were retargeted at what was left rather than
deleted, which is the whole point of a census a gate reads, until the 2026-09-26 sweep's id peel
and suite split took both under the cap (above).

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
for a peel, the suite inventory, was taken on 2026-09-26 by kit revision 28 (the automated-tests
sweep's `ATS-03`), which moved it and the path helpers it keys on, unchanged, to
`testkit/inventory.lua` (515) and left `framework.lua` at 920, out of the band.

**The line counts are dated, and nothing asserts them.** What `tests/_kit/test_layout_cap.lua`
asserts is
the *membership* of this table, in both directions: a file that crosses 1500 and is not listed here
turns the suite red, and so does a row for a file that has fallen back under the cap or been deleted,
so the census cannot become a graveyard. A figure in this column is a measurement, not a claim about
today — `OptionsWidgets.lua` was 1838 at the 2026-09-07 review and the suite 2287, then 1989 and
2398 on 2026-09-08, 2812 and 3285 on 2026-09-16, 3113 and 3541 earlier on 2026-09-20, 3922 and 4086 on 2026-09-22, and both moved
while nobody was watching, which is the whole argument for having a gate rather than a paragraph.

**A peel here is a release, and v1.39.0 is the worked example.** `LibKa0s/` is re-vendored
whole-folder into every consumer and every file in it carries its own LibStub minor, so a peel adds
a payload file, a `LibKa0s.xml` row, a minor, a row in `tests/majors.lua`, the multi-file pairing
guard on its own minor **and** the shell's (`lib.__tabsMinor` / `lib.__tabsShellMinor` in
`LibKa0s/OptionsTabs.lua`, following `lib.__widgetsShellMinor`), **a component on the major's version
key**, an API document and a regenerated manifest — a deliberate release, not a tidy-up. The
2026-09-07 remediation plan ruled out splitting any file (`03_SPEC.md` § C22 non-goals) and that
cycle's deliverable was the disposition; this cycle executed it.

**The 1000–1500 band is on notice, not in breach**, and every figure in it was re-measured with the
same command on **2026-09-26 at v1.62.0's release, kit revision 31**, after the automated-tests
sweep. It is prose rather than a second table on purpose: the gate above reads every
backticked-path table row under this heading as a census row, so a band table here would be ten
rows claiming to be breaches. Ten files at that write-out, three fewer than the thirteen of the
2026-09-24 write-out: the sweep took six out and its id peel brought three in. Six now:
`tests/test_options.lua`, `tests/test_schema.lua`, `LibKa0s/Widgets.lua` and `LibKa0s/Perf.lua`
left on 2026-10-01 (below), and `LibKa0s/Slash.lua` came in and left again the same day. Seven
at v1.76.0 (2026-10-23): `tests/test_sim_panel.lua` came in. Nine at v1.77.0 (2026-10-24): `LibKa0s/DebugLog.lua`
and `tests/test_options_compose.lua` came in. Eight on 2026-10-25 (`LK-09` of Ka0sAddonsCommonTasks
`docs/2026-10-25-SKINNING/`): `LibKa0s/DebugLog.lua` left on its named seam (below). Re-measured at
v1.78.0's close (2026-10-25): still eight, nothing over 1500, and every figure
below is current. Re-measured 2026-10-27 after the skin-feedback rounds (`SF-*` of
Ka0sAddonsCommonTasks `docs/2026-10-26-SKIN_FEEDBACK/`): still eight, none of them touched. Re-measured at v1.79.0's close
(2026-10-28, `SO-05` of Ka0sAddonsCommonTasks `docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER/`): still eight, nothing over
1500, every figure below current; the release's new files, `LibKa0s/OptionsSkinPicker.lua` (765),
`LibKa0s/Toast.lua` (460) and `tests/test_options_skin_picker.lua` (966), are out of the band. Re-measured at v1.80.0's
close (2026-10-29, the release close of Ka0sAddonsCommonTasks `docs/2026-10-29-SKINNING_ROLLOUT/`): **nine**, nothing over
1500. `LibKa0s/Skin.lua` came in (below); the other eight are untouched since v1.79.0, so their figures stand. The
release's other grown files are out of the band: `LibKa0s/SkinPaint.lua` 994, `LibKa0s/SkinAce.lua` 917,
`LibKa0s/OptionsCompose.lua` 848, `LibKa0s/SkinPaintControls.lua` 752. Re-measured 2026-10-30 on the branch of
Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/` (the run that releases v1.81.0): **twelve**, nothing over
1500, no re-check trigger fired. Three came in: `LibKa0s/SkinDefs.lua` and `tests/test_options_skin_picker.lua` (below),
and `LibKa0s/SimPanel.lua` (1018, recorded with SimPanel's history further down). `LibKa0s/OptionsIds.lua`,
`LibKa0s/OptionsIdList.lua` and `LibKa0s/Skin.lua` grew and their figures below are re-measured; `LibKa0s/OptionsTabs.lua`
(1382, two comment lines of `LK-06c`) and `LibKa0s/OptionsWidgets.lua` (1447, unchanged) added no member or maker, and
`LibKa0s/Options.lua` is untouched (1335). The run's other grown payload files are out of the band:
`LibKa0s/SkinPaint.lua` 979 at minor 12. Re-measured at v1.81.0's close (2026-10-30, the release close of the same run): still
**twelve**, nothing over 1500, no re-check trigger fired, every figure below current (the font-height fix and the
consumer notes moved no band file). Re-measured 2026-10-30 on the branch of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/` (the run that releases v1.82.0, `LK-13`): **fourteen**, nothing over 1500.
Two came in, `LibKa0s/SkinPaint.lua` (1002) and `tests/test_options_appearance.lua` (1231), both below;
`LibKa0s/OptionsWidgets.lua` peeled on its named seam to the new `LibKa0s/OptionsSwitch.lua` (163) at its trigger and
stays in the band at 1370; `LibKa0s/Skin.lua`, `LibKa0s/SkinDefs.lua` and `tests/test_options_skin_picker.lua` grew under
their triggers, re-measured below; the other band files are untouched. Re-measured at v1.82.0's close (2026-10-30,
the release close of the same run): still **fourteen**, nothing over 1500, no re-check trigger fired, every figure below current (the close's one
CCN split is in `LibKa0s/WidgetsDragHandle.lua`, 951, out of the band). Re-measured at v1.83.0's close (2026-10-31, the release close of
Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`): still **fourteen**, nothing over 1500. Three re-check
triggers fired, `LibKa0s/Skin.lua`'s, `LibKa0s/SkinDefs.lua`'s and `tests/test_options_appearance.lua`'s, and each is re-ruled
below; a peel at the close would land after the release's independent review and, for the two payload files, move
the Skin key again. The new `LibKa0s/OptionsMedia.lua` (450) is out of the band. Re-measured 2026-10-31 after the picker-rows addendum of the same
run: **fifteen**, nothing over 1500. `LibKa0s/OptionsSkinPicker.lua` came in (below), and `LibKa0s/Skin.lua` grew (below). Re-measured at the pre-merge automated-test run (2026-10-31,
`docs/automated-tests/20261031-202020/`): still **fifteen**, nothing over 1500, no re-check trigger fired. Re-measured 2026-10-31 by
`FX-LK-SIZE` of Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/`: **eleven**, nothing over 1500. Four suites left
on their named seams (the paragraph after this list), and the six payload files whose rows had spent their shelf life moved
to the tenth register row, because that plan edits no payload.
Largest first:

- `testkit/mock_base.lua` (1465 with kit revision 43's one comment line pointing at `testkit/mock_paint.lua`, measured 2026-10-25, under its 1490 re-check trigger; 1464 with kit revision 39's six `__kitEver` lines, measured 2026-10-14, under its 1490 re-check trigger; 1458 with kit revision 37's two `mock_lines.lua` lines; 1456 unchanged by kit revision 35, whose GetHeight comment rewrite
  retiring the geometry flip added no line; 1456 with kit revision 33's two `mock_resize.lua` lines; 1454 before them,
  1452 with the shown-by-default flip's four comment lines, 1448 with
  `testkit/mock_events.lua`'s load, hook and install lines, 1446 before them — it was 1499 at kit
  revision 21, one line from the cap; kit 20's id lookups went to `testkit/mock_ids.lua` for that
  reason, and kit 22's recording surveys to `testkit/mock_record.lua` for the same one). The closest
  file to the cap; its `RESULTS.md` re-check trigger is 1490 lines, or any kit
  change that adds more than 30 lines here.
- `LibKa0s/OptionsWidgets.lua` (1066 at minor 39, measured 2026-10-31: 1375 -> 1066 when the flow engine peeled to `LibKa0s/OptionsFlow.lua` (360), and the v1.84.0 list above records it; 1375 at minor 38, whose picker fallback added no maker; 1422 new to the band: it came down from the census's 3852 when the id surface left it), ruled below. Still in the band by 66 lines; the seam left is the choice grid.
- `LibKa0s/OptionsTabs.lua` (1382 at minor 11, two comment lines of `LK-06c`, measured 2026-10-30; 1380 at minor 10's thin skin calls and their three file-local helpers (`LK-07` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`), measured 2026-10-25, no member added and under its 1400 re-check trigger; 1350 at minor 9, which dropped the `O.__releaseChrome` export and added
  its header note, LibKa0s#45, measured 2026-10-22; 1349 with minor 8's three `RenderTabbedSchema` opts, AbsorbTracker#32,
  measured 2026-10-01, no member added and under its 1400 re-check trigger; 1294 at v1.65.0; 1293 after the sweep moved its combat half to
  `LibKa0s/OptionsCombat.lua`; 1493 with `SR-LK-01`'s rail inset, 1489 before it; 973 at v1.39.0's
  peel, and minor 22's combat lock, minor 23's dispatcher, `LK-27`'s page-chrome fix and `LK-28`'s
  `RenderTabbedSchema` took it the rest of the way), peeled then accepted, below.
- `LibKa0s/Options.lua` (1335 with minor 34's one guarded `__AttachSkinPicker` line in `attachHalves` and its two header lines (`PK-01` of Ka0sAddonsCommonTasks `docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER/`), measured 2026-10-28, no member added, the picker's members in `LibKa0s/OptionsSkinPicker.lua`; 1332 with minor 33's one guarded `__AttachAppearance` line in `attachHalves` and its header lines (`LK-10` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`), measured 2026-10-25, no member added, the attach-row exception `OptionsKeybinds.lua` set, and under its 1400 re-check trigger; `LibKa0s/OptionsAppearance.lua`, the new file the members live in, is 627 at minor 3's Font and texture section (re-measured 2026-10-28; 481 at minor 2, 409 at minor 1), out of the band; 1329 with minor 32's one `__AttachSkinAce` line in `attachHalves` (`LK-08` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`), measured 2026-10-25, no member added and under its 1400 re-check trigger; 1325 with minor 31's two thin skin calls and the `addonName` docblock's skin-owner sentence (`LK-07` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`), measured 2026-10-25, no member added and under its 1400 re-check trigger; 1320 with minor 30's guarded `OptionsKeybinds.lua` attach and the attach chain moved into a local `attachHalves` inside `lib:New` (the v1.77.0 release run measured `lib.New` at CCN 16), measured 2026-10-24, no member added and under its 1400 re-check trigger; 1316 before that split; 1288 with minor 28's `addonName` docblock, LibKa0s#42, measured 2026-10-02; 1282 with v1.65.0's combat-refusal lines and their one private member, `O.__combatRefused`, which fires the re-check trigger below and is re-ruled there; 1261 after the sweep moved its page registry to
  `LibKa0s/OptionsRegistry.lua`; 1462 before; 1312 at v1.40.0, 1460 at v1.46.0 with minor 22's
  combat lock, and `LK-24` to `LK-26` moved the font preload out and the park in), peeled then
  accepted, below.
- `LibKa0s/OptionsIdList.lua` (1290 with `LK-06d`'s tooltip lines and `LK-06c`'s shared id gray (Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`), measured 2026-10-30, under its 1350 re-check trigger; 1268 with minor 6's skinned help tints (`LK-07` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`), measured 2026-10-25, under its 1350 re-check trigger; 1251 at v1.75.0's minor 5, the #57 help-mark comment, measured
  2026-10-22, under its 1350 re-check trigger; 1247 at v1.71.0's minor 4, measured 2026-10-07; 1246 with minor 3's loaded-addon check on `addonName`, LibKa0s#42, measured 2026-10-02;
  1197 at v1.65.0; 1193 new: the id peel), ruled below.
- `LibKa0s/OptionsSkinPicker.lua` (1256 at minor 5, measured 2026-10-31: 1455 -> 1256 when the rows' section and its header notes peeled to `LibKa0s/OptionsSkinPickerRows.lua` (268); 1359, new to the band, measured 2026-10-31 at minor 4, the picker-rows addendum of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/`) -- **accepted.** Still in the band, because about 140 of its lines are header notes. The seam left is the queue (`queue` through `dropWaiting`), to a file of its own with its own minor, paired on the shell. **Re-check trigger: 1400 lines.**
- `LibKa0s/SkinPaint.lua` (1002, new to the band, measured 2026-10-30: 979 → 1002 with minor 13's mono-role
  outline (`LK-03`) and `P.color` (`LK-14`) of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`) —
  **accepted.** Two lines over the band's floor, and about seventy of its lines are the minor-by-minor header notes
  the Skin document already records. The seam is the window block (the table `Shell` hands `Core.ApplySkin`, the
  inner rule and the edge holder), to `LibKa0s/SkinPaintExtras.lua` as Panel and Inset went at minor 11.
  **Re-check trigger: 1050 lines, or the next SkinPaint minor.**

**The v1.84.0 peels, 2026-10-31.** Each file below left the band on the seam its row named, as a pure move (step 1 of Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`), with no logic edited:

- `LibKa0s/Skin.lua` 1232 → 1045 at minor 11, the owner-token block to `LibKa0s/SkinOwnerTokens.lua` (233), `isSchemaName` through `takeTokens`, `__RemapName`, `ownValue`, `withOwnTokens` and `__Remap`, paired on the Skin shell.
- `LibKa0s/SkinDefs.lua` 1104 → 455 at minor 19, the eight other skins to `LibKa0s/SkinDefsOthers.lua` (686), `FOLLOW`, `ICON_EDGE`, `HUD_FACE`, `register` and the eight `register(...)` blocks, paired on the Skin shell.
- `LibKa0s/SimPanel.lua` 1018 → 672 at minor 9, the renderer section to `LibKa0s/SimPanelRender.lua` (400), which loads after the adapter, reads the six locals the two share from `lib.__panelKit` and publishes `lib.__StepPanel`, paired on the Sim shell.
- `LibKa0s/OptionsSkinPicker.lua` 1455 → 1256 at minor 5, the rows' section, `onRow` through `syncControls`, and its header notes to `LibKa0s/OptionsSkinPickerRows.lua` (268), attached by `lib.__AttachSkinPickerRows`. It stays in the band, below.
- `LibKa0s/OptionsIds.lua` 1412 → 806 at minor 6, the module-scope suggestions-while-typing block and the dropdown members to `LibKa0s/OptionsIdSuggest.lua` (676), attached by `lib.__AttachIdSuggest`.
- `LibKa0s/OptionsWidgets.lua` 1375 → 1066 at minor 39, the flow engine (`gridGap`, `startGroup` through `endGroup`, `O.RenderGrid`, the switched sections' wiring, `flowRows`, `O.RenderRows`, `O.RenderSchema` and the untabbed `O.RenderTabbedSchema`) to `LibKa0s/OptionsFlow.lua` (360), attached by `lib.__AttachFlow`. It stays in the band, below.

Four suites left the band on 2026-10-31, each on the seam its row named and each move unchanged (`FX-LK-SIZE` of
Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/`). `tests/test_sim_panel.lua` went 1056 → 683, the *frame, the
picker and the controls* section to `tests/test_sim_panel_controls.lua` (292), its bench to `tests/fixture_sim_panel.lua`.
`tests/test_options_skin_picker.lua` went 1129 → 864, the *one window across addons* section to
`tests/test_options_skin_picker_shared.lua` (256). `tests/test_options_compose.lua` went 1012 → 726, the record-backed arm to
`tests/test_options_compose_arm.lua` (295). `tests/test_options_appearance.lua` went 1266 → 648, its minor-4 sections to
`tests/test_options_appearance_overrides.lua` (505), named for what they cover rather than the watch list's `_v4`, with the
bench in the new `tests/fixture_appearance.lua`. `tests/test_options_skin_picker_rows.lua` (843) stays out of the band.

`LibKa0s/Perf.lua` left the band on 2026-10-01, 1307 → 975, closing issue
[#7](https://github.com/tusharsaxena/LibKa0s/issues/7) in two peels at minor 14. The first moved the
command surface, unchanged, to `LibKa0s/PerfCommands.lua` (230): 1319 → 1170, then 22 lines for #12's
zero-count ancestors, 100 for #1's budgets and 15 for `GI-LK-11`'s `P.Context` reader table took it
back to 1307. The second (`GI-LK-07R`, the addendum's A2) moved the issue's own seam, the capture,
unchanged, to `LibKa0s/PerfSampler.lua` (418): the Shape B brackets and their free list, the
measurement windows and the FPS sampler, `P.Start` through `P.Cancel`, and `P.Suspend` / `P.Resume`,
paired on the probe's minor like the other two. The open depth went with the brackets, so the window
edges reset it in their own file and `P.Reset` zeroes it through the function the installer hands
back; the FPS arms and the completion pair are read through getters because `P.Reset` replaces
them. What is left is the probe, the record and the report. It is 997 with minor 15's top-level
observation in `Note` (F20 of DropWatcher's 2026-10-14 review), measured 2026-10-14, three under
the trigger. **Re-check trigger: 1000 lines**; the report sections (`addFpsLines` through `lib.__budgetOver`, file-level already) are the next seam.
`LibKa0s/Slash.lua` came into the band on 2026-10-01 and left it the same day, 1030 → 877: 999 at
v1.65.0, 1006 with minor 19's resolver (issue #40), 1030 with `GI-LK-11`'s file-level descriptor
helpers. `GI-LK-03R` (the addendum's A2) moved the seam its entry named, the parser block
(`lib.ParseBool` through `lib.ParseValue`, with `enumList` and `allowedText`), unchanged, to
`LibKa0s/SlashParse.lua` (195), a secondary file paired on the shell's minor; the cut
`tests/test_slash_parse.lua` had already made on the suite side. **Re-check trigger: 1000 lines**;
the profile verb (`lib.ProfileNames`, `Sl:ProfileSwitch`, `Sl:CliProfile`) is the next seam.
`LibKa0s/Widgets.lua` left the band on 2026-10-01, 1303 → 655, closing issue #36: `ReorderList`,
the row box and their machinery moved unchanged to `LibKa0s/WidgetsReorder.lua` (680) at Widgets
minor 12, a secondary file paired on the shell's minor as `LibKa0s/WidgetsDragHandle.lua` is. The
dropdown and the copy window stay; the copy window is the next seam if the file grows back.
It has grown back, out of the band: 853 at v1.76.0's minor 14 (the strip's `kind`, measured
2026-10-23), 834 at v1.75.0's minor 13 (measured 2026-10-22), 655 before
`W.SearchBox` (#52), the hoisted `SKIN` table and `W.TestStrip` (#48) with their header notes. The
copy window stayed the next seam, and the re-check trigger was 1000 lines. **It fired at Widgets
minor 16** (`LK-06` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`, the skin owner), which
took the file to 1010, so the copy window peeled before the commit, on that seam, to
`LibKa0s/WidgetsCopyWindow.lua` (293), a sixth Widgets file paired on the shell's minor
(`__copyMinor`), and the file is 758, measured 2026-10-25. The search box is the next seam; the
re-check trigger stays 1000 lines. `LibKa0s/DebugLog.lua` was
999 at v1.75.0's minor 20, re-measured 2026-10-22: the #57 comment correction added no line, so it
stayed one under the band until v1.77.0's minor 21 took it in (1008, measured 2026-10-24, accepted
with the console window as its seam and "1100 lines, or the next DebugLog minor that adds a window
feature" as its trigger). **That trigger fired at DebugLog minor 22** (`LK-09` of
Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`), whose window feature is the skin owner: the
window (`EnsureFrame`, the drag bar and their chrome helpers) peeled first, unchanged, on that seam,
to `LibKa0s/DebugLogWindow.lua` (575), a fourth DebugLog file paired on the shell's minor
(`__windowMinor`), and the owner was added there. `LibKa0s/DebugLog.lua` left the band, 1008 → 663,
measured 2026-10-25. The logging half (`append` through `CopyText`) is the next seam; the re-check
trigger is 1000 lines. `LibKa0s/Perf.lua` was not touched by the same item (still 997): PerfPanel
minor 10's skin owner is painted in `LibKa0s/PerfPanel.lua` (346). Of v1.75.0's new files `tests/test_sim_panel.lua` came into the band first
(1056 at v1.76.0) and left it on 2026-10-31 (above); `LibKa0s/SimPanel.lua`, the largest payload file among them, came
into the band at SimPanel minor 8 (1018, measured 2026-10-30: its tooltip palette, `LK-06d`, and its
skinned labels, owned dropdowns and grip owner, `LK-06b`, of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`; the renderer section is the seam, to a file of its own,
when the next SimPanel minor grows it); 997
at SimPanel minor 7's skin owner (`LK-09` of Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`,
measured 2026-10-25, three under the band: the renderer section is the seam if it grows, to a file
of its own), 956 at SimPanel minor 6's toplevel and popup re-raise (v1.77.0, measured 2026-10-24); 949 after SimPanel
minor 5 with the step-label bound (v1.76.0; 929 before it, 919 after minor 4).
`tests/test_options.lua` left the band on 2026-10-01, 1339 → 988, closing issue #35: the page
registry, its combat-refusing open and the two refresh tiers, 24 of 85 cases, moved unchanged to
`tests/test_options_render.lua` (373), the render/refresh seam the issue named plus the page-registry
section beside it and `RefreshAllPanels`' fan-out case, without which the suite would have sat at
1000, still on the band's edge. `tests/test_schema.lua` left the same day, 1335 → 705, closing
issue #38: the write stage onward (the write seam, defaults, the bulk bracket and the profile
reset's count), 41 of 73 cases, moved unchanged to `tests/test_schema_write.lua` (506), with the
fixture constructors both suites read in `tests/fixture_schema.lua` (179). The reference
degradation stub stays in `tests/test_schema.lua` beside the cases that pin it.

Six left the band in the sweep, each on a seam named below: `testkit/test_prose.lua` 1486 → 750
(issue #39, kit revision 29), `testkit/framework.lua` 1386 → 920 (kit revision 28; 984 at kit
revision 31, with the runner's `--layout-cap-exempt` answer; 994 at kit revision 35, whose
inventory renderer split into helpers, six under the band), and four
suites, `tests/test_widgets.lua` 1493 → 861 (issue #37), `tests/test_slash.lua` 1339 → 848,
`tests/test_options_tabs.lua` 1218 → 954 and `tests/test_options_idsuggest.lua` 1002 → 691. The
three that sat within fifteen lines of the cap, `testkit/test_prose.lua` and, at 1493,
`LibKa0s/OptionsTabs.lua` and `tests/test_widgets.lua`, are among them. They are named so a later
reader can tell the band was looked at rather than missed. Every file in it carries a disposition in
`docs/automated-tests/RESULTS.md` (see *The band's terminal states* below): an issue naming its
seam, or an acceptance with a re-check trigger, which past its shelf life is the
`automated-tests-§4` register row.
v1.32.0's
bulk-bracket cases went to their own suite, `tests/test_options_bulk.lua`, rather than into
`tests/test_options.lua`: they took it to 1544 lines, and they peel on a seam of their own. v1.33.0's
font-preload cases did the same, into `tests/test_options_fontpreload.lua`. **v1.48.0 is the band
paying for itself, twice in one release.** The drag handle written into `LibKa0s/Widgets.lua` took it
to **1540** and its cases appended to `tests/test_widgets.lua` would have taken that file past the
same line from seven under it, so both went to files of their own —
`LibKa0s/WidgetsDragHandle.lua` (507 then, 675 now) and `tests/test_widgets_draghandle.lua` (668
then, 813 now), neither of them in the band. At v1.68.0 that suite would have reached 1123 with
minor 4's placement-hook cases, so they went to `tests/test_widgets_draghandle_place.lua` (241)
and the bench to `tests/fixture_draghandle.lua` (122), the same exit taken again. That is a cut chosen while the seam was still obvious
rather than one sized against a file three releases older than the peel, which is what the two rows
above record going wrong.

**The id peel, 2026-09-26 (the automated-tests sweep), puts three source files into the band, and rules each.**
None was in it before: `LibKa0s/OptionsWidgets.lua` came down from the census, and the other two are
new.

- `LibKa0s/OptionsWidgets.lua` (1422) — **accepted.** The makers, the choice grid, the landing page
  and the flow engine, with the id surface gone. **Re-check trigger: 1450 lines, or the next maker
  added**; the flow engine (`flowRows`, the switched sections) is the seam at either. The switched
  sections took that seam on 2026-10-30 (`LibKa0s/OptionsSwitch.lua`, at the trigger, 1447 -> 1370);
  `flowRows` took the rest on 2026-10-31 (`LibKa0s/OptionsFlow.lua`, 1375 -> 1066).
  **Tracked 2026-10-07** by the `automated-tests-§4` row in `## Documented deviations` above, which
  carries its seam and trigger; this ruling is not renewed here.
- `LibKa0s/OptionsIds.lua` (1358) — **accepted**, then **peeled 2026-10-31** on the seam named here (the v1.84.0 peels, above), and the file is 806, out of the band.
- `LibKa0s/OptionsIdList.lua` (1193) — **accepted.** The list and its entry-line layout, one piece
  of machinery. **Re-check trigger: 1350 lines.**
  **Tracked 2026-10-07** by the `automated-tests-§4` row in `## Documented deviations` above, which
  carries its seam and trigger; this ruling is not renewed here.

The suites the id cases went to are out of the band: `tests/test_options_ids.lua` 724,
`tests/test_options_idlist.lua` 379, `tests/test_options_idlist_layout.lua` 665, and so are the
suites the rest of `tests/test_options_widgets.lua` split into: `tests/test_options_choicegrid.lua`
425, `tests/test_options_flow.lua` 801, `tests/test_options_landing.lua` 340, and the makers left
behind at 717.
`tests/test_options_idsuggest.lua` (1002), whose re-check trigger was "1200 lines, or #32's peel",
now pairs with `LibKa0s/OptionsIds.lua`, the module the peel gave it; it moved no case in that peel.

**The 2026-09-26 sweep's suite split takes four suites out of the band**, each on its
own case seams, every case moved unchanged and 1745 in all before and after:

- `tests/test_widgets.lua` 1493 → 861: the `ReorderList` and row-box cases, 24 of 81, went to
  `tests/test_widgets_reorderlist.lua` (527), with the geometry factory both use in
  `tests/fixture_geom.lua` (154). This is issue #37's split.
- `tests/test_slash.lua` 1339 → 848: `ParseBool` and the parser, 24 of 110, went to
  `tests/test_slash_parse.lua` (225), the seam its watch-list entry named, and the disabled gate, 16,
  to `tests/test_slash_disabled.lua` (298).
- `tests/test_options_tabs.lua` 1218 → 954: the tabbed page's `opts` and the banner's action, 13 of
  54, went to `tests/test_options_tabbed.lua` (291).
- `tests/test_options_idsuggest.lua` 1002 → 691: the dropdown's frames, 11 of 40, went to
  `tests/test_options_idsuggest_frames.lua` (254), with the bench both use in
  `tests/fixture_idsuggest.lua` (112).

None of the seven new files is in the band.

**The band's terminal states, ruled 2026-09-24.** `automated-tests-§4` refuses an "accepted" that
outlives three consecutive release runs and a newly crossed entry with no disposition, and the
2026-09-23 audit (`LK-17d` in `docs/audits/2026-09-23/`) found seven band files in one state or the other. Each now has one
of the two terminal states a band entry may carry, and `docs/automated-tests/RESULTS.md`'s
Disposition cells point here. The 2026-10-07 audit (`LK-17d` in `docs/audits/2026-10-07/`) found the
five *accepted* entries below past that shelf life again; they are now one tracked row in the
register above, and each entry points at it instead of re-arguing its acceptance:

- `tests/test_options.lua` (1339) — issue [#35](https://github.com/tusharsaxena/LibKa0s/issues/35):
  the render/refresh block peels to `tests/test_options_render.lua`. This is the "owed a tracked ID"
  the watch list carried with no ID. **Peeled 2026-10-01**: that block, the page-registry section
  beside it and `RefreshAllPanels`' fan-out case are `tests/test_options_render.lua`, and the file is
  988, out of the band.
- `LibKa0s/Widgets.lua` (1266) — issue [#36](https://github.com/tusharsaxena/LibKa0s/issues/36):
  per-widget files, `ReorderList` first. **Peeled 2026-10-01**: `ReorderList` is
  `LibKa0s/WidgetsReorder.lua`, and the file is 655, out of the band.
- `tests/test_widgets.lua` (1493) — issue [#37](https://github.com/tusharsaxena/LibKa0s/issues/37):
  split by widget family, the `ReorderList` and row-box cases first; its trigger is *any* new case.
  **Split 2026-09-26**: those cases are `tests/test_widgets_reorderlist.lua`, and the
  file is 861, out of the band.
- `tests/test_schema.lua` (1335) — issue [#38](https://github.com/tusharsaxena/LibKa0s/issues/38):
  split by pipeline stage, the write stage onward first. **Split 2026-10-01**: those cases are
  `tests/test_schema_write.lua`, the shared constructors `tests/fixture_schema.lua`, and the file is
  705, out of the band.
- `testkit/test_prose.lua` (1486, still in the band after `LK-01` / `LK-07`) — issue
  [#39](https://github.com/tusharsaxena/LibKa0s/issues/39): the narrowing and coverage machinery
  peels to a kit module of its own at the next kit revision that touches the file.
  **Peeled 2026-09-26** by kit revision 29 (the automated-tests sweep's `ATS-07`): the machinery is
  `testkit/prose_coverage.lua` (404) and the self-tests `testkit/prose_selftests.lua` (426), and
  the file is 750, out of the band.
- `LibKa0s/Options.lua` (1261, measured 2026-09-26 after its peel) — **peeled 2026-09-26, then
  accepted.** Re-ruled *accepted* at 1462 on 2026-09-24 (it had passed the old "re-check at 1350" at
  1476 with nobody re-ruling it; `LK-24` then took the font preload out to
  `LibKa0s/OptionsScroll.lua`, and `LK-25`'s park and `LK-26` came back in), and carried that way past
  `automated-tests-§4`'s shelf life (the 2026-09-26 sweep's `ATS-03`). That ruling read the park as
  combat handling a split would turn into a published-surface change. It is not: the park has one
  caller, `CreateOptionsPanel`, and the page registry around it (the page queue, the main category,
  `RegisterOptionsPage`, `CreateOptionsPanel`, `OpenOptionsPanel`) keeps state nothing else in the
  shell reads and reaches the instance only through members. The sweep moved both, unchanged, to
  `LibKa0s/OptionsRegistry.lua` (263, out of the band) at Options minor 26, attached where the
  members were defined, so no member moves on the instance. What is left is the layout and strings,
  the LSM30 patch, the lock's predicate, and the instance: the panel factory, the scroll, the
  reset/refresh trio and the combat edges. **Re-check trigger: the next member added to
  `Options.lua`, or 1400 lines**; the reset walk (`runBulk`, `O.RestoreDefaults`,
  `O.RestoreAllDefaults`, about 140 lines, reached only through members and the descriptor) is the
  next seam.
  **Re-ruled 2026-10-01 at v1.65.0: accepted** (1282). The member the trigger caught is the private
  `O.__combatRefused`, the combat lock's refusal line (gap G3), which sits with the instance's
  combat edges that re-arm it rather than in the reset walk, so the seam and the trigger stand as written,
  counted from this release.
  **Tracked 2026-10-07** by the `automated-tests-§4` row in `## Documented deviations` above, which
  carries its seam and trigger; this ruling is not renewed here.
- `LibKa0s/OptionsTabs.lua` (1293, measured 2026-09-26 after its peel) — **peeled 2026-09-26,
  then accepted.** Re-ruled *accepted* at 1493 on 2026-09-24 as "the tabbed page's own machinery
  with no second seam inside it", and carried that way past `automated-tests-§4`'s shelf life (the
  2026-09-26 sweep's `ATS-03` / `ATS-06`). The ruling missed one: the combat lock's page chrome
  (minors 2 and 3 — the event frame, the page-scoped registration, the dispatcher, the cover and its
  level) reads no local of the strip and meets it only through `lib` fields. The sweep moved it,
  unchanged, to `LibKa0s/OptionsCombat.lua` (249, out of the band) at OptionsTabs minor 6. What is
  left is the strip, its art, the banner, the header block, the sub-strip and the tabbed page.
  **Re-check trigger: the next member added to `OptionsTabs.lua`, or 1400 lines**; the tabbed page
  (`O.RenderTabbedSchema` and its helpers, about 165 lines) is the next seam.
  **Tracked 2026-10-07** by the `automated-tests-§4` row in `## Documented deviations` above, which
  carries its seam and trigger; this ruling is not renewed here.

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

**`tests/test_slash.lua` (1339 at v1.60.0's `DR-LK-04`) — re-ruled 2026-09-24: accepted**, by the review of `LK-33`. The
v1.56.0 release run (`docs/automated-tests/20260924-040553/`) left its Disposition cell as carried
from v1.34.0, "466 lines clear of the cap … Re-check at 1350", when the file already stood at 1327,
and that bundle's `ANALYSIS.md` says every Disposition cell was "ruled at
this run" and lists the row as *Carried: re-check at 1350*. Both are wrong for this row; the bundle
is frozen, so this paragraph and the row's `RESULTS.md` cell are the correction. The file is a flat
list of independent cases mirroring `LibKa0s/Slash.lua` (866), and the parser block (`ParseBool`
through `ParseValue`) is its peel seam, as `tests/test_slash_parse.lua`. **Re-check trigger: the
next Slash minor that adds parser cases, or 1400 lines**, whichever comes first; at either, the
parser block peels before the append. **Split 2026-09-26**: the parser block is
`tests/test_slash_parse.lua` and the disabled gate `tests/test_slash_disabled.lua`, and the file is
848, out of the band.

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
| [`docs/api/`](docs/api/) | **The source of truth for every public contract** — one document per shipped version, per major (`Core`, `Env`, `Compat`, `Lifecycle`, `Bus`, `Schema`, `Pool`, `Item`, `Glow`, `Toast`, `Media`, `Skin`, `Widgets`, `DebugLog`, `Slash`, `Launcher`, `Options`, `Perf`, `Sim`, and `testkit`), and beside each one a generated `members-<version-key>.json` naming that version's public surface as data. A superseded document is never edited to describe new behavior; a manifest is never hand-edited at all — regenerate with `lua tools/gen-api-members.lua` |
| [`docs/api/CONSUMERS.md`](docs/api/CONSUMERS.md) | The consumer census: for every public export, which hosts call it (file:line), each textual hit classified as call / host duplicate / degradation stub, and a verdict on every zero-consumer export. Stamped with the version it measured; re-run with the tool it names after a release that adds a surface |
| [`docs/releasing.md`](docs/releasing.md) | The two version numbers (repo semver and the load-bearing per-file LibStub minor), the numbered release order, and the re-vendor rule |
| [`docs/record-schema.md`](docs/record-schema.md) | The in-game Perf capture record, field by field — the contract each consumer's `perf-analysis/README.md` points at rather than restating |
| [`docs/adoption-prompt.md`](docs/adoption-prompt.md) | The brief handed to a consumer repo adopting a major: what to wire, what to delete, and what must not be hand-rolled |
| [`docs/fast-gate-adoption-prompt.md`](docs/fast-gate-adoption-prompt.md) | The drop-in brief for adopting the fast test gate in a consumer repo — what to copy, and the measured before/after it replaced |
| [`docs/adoption-report.md`](docs/adoption-report.md) | The collection-wide adoption state — which consumer has taken which major, and what each declined |
| [`docs/skins/README.md`](docs/skins/README.md) | The skin mockups: a standalone browser page and its Design-canvas sources, kept as the design reference for the nine skins and the starting point for `LibKa0s/SkinDefs.lua`'s token tables |
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
~/.claude/dev-copilot/bin/ka0s-bounded luacheck .  # 0 warnings / 0 errors; luacheck loads no kit, so it runs bounded (testing-§15)
```

That `luacheck` figure is **scoped by `.luacheckrc`'s `exclude_files`**, not repo-wide: everything
but `tests/_kit/` (the same scope `docs/releasing.md` step 1 gives). How many files that is, no
prose here says: luacheck prints it (`in N files`), and every run's
[`docs/automated-tests/RESULTS.md`](docs/automated-tests/RESULTS.md) *Lint* section carries it,
generated, with the exclusions named beside it. A hand-typed copy of that count is one more figure
to drift, and it did. 0/0 only means something if the files carrying the change are inside the
checked set.
