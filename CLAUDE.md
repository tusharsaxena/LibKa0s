# CLAUDE.md — LibKa0s

LibKa0s adheres to the **Ka0s WoW Addon Standard** (v2.56.0) —
<https://github.com/tusharsaxena/WowAddonStandards>.

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
  `documentation-§3`'s `docs/` trio, its five verification-and-record docs **and its whole
  topic-detail tier model** (Tier 1's `scope.md`, `module-map.md`, `schema.md`, `settings-panel.md`,
  `data-flow.md`, `common-tasks.md`; Tier 2; the `## Documentation map` section of an
  `ARCHITECTURE.md` that does not exist here) — a library has no settings canvas, no SavedVariables
  and no in-game pipeline, so four of the six Tier 1 docs have no subject; `toc-file`, `options-ui`,
  `slash-commands`, `preview-mode`, `savedvariables`, `packaging`.
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
   `documentation-§3`'s `docs/` trio does not bind a library repo and a register with no file is a
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
| `localization-§5` | `testkit/mock_base.lua` and `testkit/mock_record.lua` reproduce AceTimer-3.0's handle field `cancelled` (as a member access, `.cancelled`) and the `IsCancelled` method of Blizzard's `C_Timer` handles, verbatim | Third-party API identifiers, not prose. The kit's AceTimer fake hands out AceTimer's own handle table, and a suite written against the real field reads `handle.cancelled`; a kit that renamed it would answer nil there and pass, which is fidelity rule 1's failure (`testkit/mock_base.lua`'s header). The same for `IsCancelled`, which a `C_Timer.NewTimer` handle answers in the client. `tests/test_prose.lua`'s `RATIFIED` carries exactly these spellings for exactly these two files, matched as `.cancelled` and `iscancelled`, so prose in the same files is still held to US English. Filed by the v1.31.0 review; the second path arrived with kit revision 22, which peeled the timer queue and both handle kinds out to `testkit/mock_record.lua`. | 2026-09-12, owner decision on the v1.31.0 review | AceTimer renames the field, or the kit stops modeling the handle (and `C_Timer` renames `IsCancelled`, or the kit stops modeling `NewTimer` handles). `tests/test_prose.lua` reddens on its own if either exemption stops matching. |
| `localization-§5` | `lib.ICONS` keeps `minimise`, the one British spelling left in the shipped payload | The key is not prose. `lib.Icon` (`LibKa0s/Media.lua:202`) builds the texture path **from** the key — `base .. ICON_DIR .. "\\" .. name` — and the file on disk is `minimise.tga`, vendored into every consumer's `libs/LibKa0s/media/icons/`. Renaming the key alone points at a texture that does not exist, and `Media.lua:190-196` records what that costs: a texture that fails to load draws nothing and raises nothing, so the icon simply disappears from every consumer's title bar with no error anywhere. Renaming it safely needs a second `.tga` or an alias map, which is a change to `Media.lua`'s surface, not a spelling fix. Filed as `LK-06` in `docs/audits/2026-09-07/`, which names the key as "a key consumers bind against" and asks for an alias rather than a rename. | 2026-09-07, executing `M1-LK-11` | A `minimize.tga` shipped beside the current file, or an alias map in `lib.Icon` — either ends this row, and the key moves in the same change as the eleven consumers' re-vendor. `tests/test_prose.lua` reddens on its own if the exemption ever stops matching, so a dead row cannot sit here unnoticed. |

**Two rows, and neither is prose**: a path fragment, and two third-party API identifiers. The table
is otherwise empty on purpose:
the alternative is a register that gets created in the same breath as the first deviation, by whoever
is already arguing for it.

`library-stack-§7`'s "does not apply" list is **not** a deviation register — those sections do not
bind this repo at all, so there is nothing to ratify. A row belongs here only when a section that
*does* bind is knowingly not followed.

## Files over the 1500-line cap

`layout-§1` caps every **authored** `.lua` file this repository tracks at 1500 lines. Two things are
worth stating explicitly here, because this repo was one of the four that read the old, silent text
differently: the cap binds `tests/`, and it binds a Ka0s-owned library's own payload folder — that is
what `library-stack-§7`'s applicability list settles, and it is why the 2026-09-07 audit's Low grade
on both breaches below no longer stands. `testkit/` is **authored here** and capped like anything
else; `tests/_kit/` is this repo's own vendored copy of it and is not, on the same terms every
consumer's copy is exempt. The second carve-out, generated non-shipping data, has no instance here.

A file over the cap has three terminal states, not one: peeled, an **open issue naming the seam** a
peel would follow, or a **ratified row** in `## Documented deviations` above carrying a re-check
trigger. What the rule refuses is a fourth state — a breach nothing anywhere remarks on, "the count
sitting in a bundle manifest that no document reads". This repo had precisely that: an `overCapFiles`
figure in the `docs/automated-tests/` manifests that no document read, and a RESULTS.md watch list
that denied it. This table is the remark, and it is why an audit **MUST NOT** re-file `layout-§1`
against a file in it.

Two files, measured 2026-09-16 at v1.40.0 with

```sh
git ls-files '*.lua' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn
```

| File | Lines (2026-09-16) | Disposition |
|---|---|---|
| `tests/test_options_widgets.lua` | 3285 | Issue [#33](https://github.com/tusharsaxena/LibKa0s/issues/33) — the `ResolveId` / `IdInput` / `IdList` cases (~1030) peel with `LibKa0s/OptionsWidgets.lua`'s id half, on that file's seam and in that file's commit. That does **not** clear the cap on its own and #33 says so; the further cut is chosen from the file as it stands after #32, not guessed at now |
| `LibKa0s/OptionsWidgets.lua` | 2812 | Issue [#32](https://github.com/tusharsaxena/LibKa0s/issues/32) — the id surface out to `OptionsIds.lua`: the module-scope `id resolution` and `suggestions while typing` blocks (~585) plus the lookup, dropdown and list members inside `lib.__AttachWidgets` (~765). Leaves the makers and the flow engine at ~1460 |

**v1.39.0 peeled the chrome, and both rows survived it.** Issue [#16](https://github.com/tusharsaxena/LibKa0s/issues/16)
named one seam — the tab and page chrome — and that seam is now `LibKa0s/OptionsTabs.lua` (973
lines), with its thirty-six cases in `tests/test_options_tabs.lua` (842). Both issues are closed and
both peels are done. What they did not do is clear the cap, and the arithmetic says why rather than
the effort: `OptionsWidgets.lua` was **1989** lines when #16 was written and **3700** when it was
executed, because Options minor 16's id surface landed in between; it is 2812 now. A peel sized
against the file of 2026-09-08 was never going to fit the file of 2026-09-16. The rows above are
retargeted at what is left rather than deleted, which is the whole point of a census a gate reads.

**Both are issues, and neither is a register row.** The sibling repository doing this same work gives
its *mirror suites* register rows rather than issues, on the argument that a suite has no seam of its
own. That argument holds here too and is written into #8 — the suite peels on the module's seam, in
the module's commit — but the row would have been a second record of a file that **already had an
open issue**, opened when the file was 1114 lines and carrying its own hard trigger, "crosses 1500 →
split". That trigger has fired. Rewriting the issue it fired on is one record; a register row beside
it would be two records free to disagree, which is the failure this section exists to prevent. The
deviation register above also stays deliberately near-empty (see its note), and a breach with a live
issue is not a deviation from the standard — it is one of the states the standard allows.

**The line counts are dated, and nothing asserts them.** What `tests/test_layout_cap.lua` asserts is
the *membership* of this table, in both directions: a file that crosses 1500 and is not listed here
turns the suite red, and so does a row for a file that has fallen back under the cap or been deleted,
so the census cannot become a graveyard. A figure in this column is a measurement, not a claim about
today — `OptionsWidgets.lua` was 1838 at the 2026-09-07 review and the suite 2287, then 1989 and
2398 on 2026-09-08, and both moved while nobody was watching, which is the whole argument for having a gate rather than a paragraph.

**A peel here is a release, and v1.39.0 is the worked example.** `LibKa0s/` is re-vendored
whole-folder into eleven consumers and every file in it carries its own LibStub minor, so a peel adds
a payload file, a `LibKa0s.xml` row, a minor, a row in `tests/majors.lua`, the multi-file pairing
guard on its own minor **and** the shell's (`__tabsMinor` / `__tabsShellMinor`,
`LibKa0s/OptionsTabs.lua:39`, following `__widgetsShellMinor`), **a component on the major's version
key**, an API document and a regenerated manifest — a deliberate release, not a tidy-up. The
2026-09-07 remediation plan ruled out splitting any file (`03_SPEC.md` § C22 non-goals) and that
cycle's deliverable was the disposition; this cycle executed it.

**The 1000–1500 band is on notice, not in breach**, measured with the same command on 2026-09-16 at
v1.40.0: `tests/test_widgets.lua` (1493), since kit revision 17
`testkit/mock_base.lua` (1437 — it was 1499 at kit revision 21, one line from the cap; kit 20's id lookups went to `testkit/mock_ids.lua` for that reason, and kit 22's recording surveys to `testkit/mock_record.lua` for the same one, which is what took it back down), `LibKa0s/Options.lua` (1312), `LibKa0s/Perf.lua` (1308 with minor 12's latch, 1231 at v1.39.0, tracked as
[#7](https://github.com/tusharsaxena/LibKa0s/issues/7)), `tests/test_options.lua` (1303), and, since v1.34.0, `tests/test_slash.lua` (1265 with Slash minor 12's disabled-gate cases, 1054 before them), and `LibKa0s/Widgets.lua` (1232). They are
named so a later reader can tell the band was looked at rather than missed; none needs a disposition
until it crosses, and `tests/test_widgets.lua` at 1493 is seven lines from needing one. **v1.39.0's
two new files are not even in the band** — `LibKa0s/OptionsTabs.lua` at 973 and
`tests/test_options_tabs.lua` at 842 — and they are named here only so a reader can see that the
peel landed clear of it rather than one edit from needing its own disposition. v1.32.0's
bulk-bracket cases went to their own suite, `tests/test_options_bulk.lua`, rather than into
`tests/test_options.lua`: they took it to 1544 lines, and they peel on a seam of their own. v1.33.0's
font-preload cases did the same, into `tests/test_options_fontpreload.lua`.

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
| [`docs/api/`](docs/api/) | **The source of truth for every public contract** — one document per shipped version, per major (`Core`, `Env`, `Pool`, `Item`, `Media`, `Widgets`, `DebugLog`, `Slash`, `Launcher`, `Options`, `Perf`, and `testkit`), and beside each one a generated `members-<version-key>.json` naming that version's public surface as data. A superseded document is never edited to describe new behavior; a manifest is never hand-edited at all — regenerate with `lua tools/gen-api-members.lua` |
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

That `luacheck` figure is **scoped by `.luacheckrc`'s `exclude_files`**, not repo-wide — sixty-five
files at v1.40.0, everything but `tests/_kit/` (the same scope `docs/releasing.md` step 1 gives). 0/0
only means something if the files carrying the change are inside the checked set.
