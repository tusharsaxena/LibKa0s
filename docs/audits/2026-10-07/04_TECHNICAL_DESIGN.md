# 04 — Technical design

Remediation design for the seven roots in `02_DEVIATIONS.md`.

**What it touches.** Six roots are documents, records or issue labels. One (`LK-39`) touches the
payload, and its outcome depends on the live client, so it can go one of two ways. Only `LK-39` and
the optional `LK-41` fix change bytes that eleven consumers vendor.

## Group A — documents only, no release (`LK-17d`, `LK-28`, `LK-29`, `LK-42`)

These change no Lua and no payload. They can land on one branch and need no version bump.

### `LK-17d` — convert five *Accepted* band cells into tracked deviations
- **Files.** The authored Disposition column of `docs/automated-tests/RESULTS.md` (`:188-192`), and the
  band rulings in `CLAUDE.md` (*The id peel … rules each*, *The band's terminal states*).
- **Shape.** Open one `state:triaged` issue for each file: `OptionsWidgets.lua`, `OptionsIds.lua`,
  `OptionsIdList.lua`, `OptionsTabs.lua` and `Options.lua`.
  - Each issue body carries the seam and the re-check trigger the cell already states:
    - `OptionsWidgets.lua`: the flow engine, trigger 1450 or the next maker;
    - `OptionsIds.lua`: the suggestion half, trigger 1450;
    - `OptionsIdList.lua`: no seam named, trigger 1350;
    - `OptionsTabs.lua`: the tabbed page, trigger the next member or 1400;
    - `Options.lua`: the reset walk, trigger the next member or 1400.
  - The owner is the repo owner. Each cell is then rewritten to *already tracked as [#NN] — seam X,
    trigger Y*.
- **Constraint.** The Disposition column is the only authored cell, and the runner carries it forward
  unchanged. The edit therefore lands once and is carried from then on.
  - Do **not** hand-edit any generated cell, and do not edit any frozen bundle's `RESULTS.md` copy.
  - The next release run's `ANALYSIS.md` notes the conversion once.
- **Alternative** (owner's choice per file): peel now, on the named seam. That is a library release
  (new file, new minor, `tests/majors.lua`, `LibKa0s.xml`, API document, manifest) and belongs to its
  own cycle, not to this documents-only group.
- **Risk.** None to code. The risk is in the process: an issue opened without a seam is a second
  "accepted" under a new name. Each issue must name one.

### `LK-28` — US-English sweep of the two adoption docs
- **Files.** `docs/adoption-prompt.md` (18 lines) and `docs/adoption-report.md` (4 lines), at the lines
  listed in `03_EVIDENCE.md` §E7. Also `tests/test_prose.lua`, to add both files to the live-doc case,
  and `CLAUDE.md:75`, to strike *"21 in `docs/adoption-prompt.md`"* from register row 3's list of
  records.
- **Shape.**
  - Make word-level substitutions with the published list: colour→color, colours→colors,
    coloured→colored, modelling→modeling, judgement→judgment, standardised→standardized,
    artefact→artifact, behaviour→behavior, summarise→summarize, renormalise→renormalize,
    licence→license.
  - Remove `ALLOWED` words as whole words first, as the matcher does.
  - Do not touch quoted identifiers. None of the 22 lines is one.
- **Constraint.** `docs/adoption/` (frozen bundles) stays out of scope. Only the two root-level briefs
  change.
- **Risk.** A prompt is pasted into consumer sessions, so a stray rename inside a code span would
  mislead an agent. Review the diff line by line.

### `LK-29` — the stale headroom figure
- **Files.** `CLAUDE.md:219` and `docs/automated-tests/RESULTS.md:193`, the authored cell only.
- **Shape.** The preferred fix drops the derived *"44 lines of room / from breach"* and keeps the
  measured count (already on `:213` and in the generated LOC column) and the trigger (1490). A derived
  number beside a measured one is the drift. The minimal fix changes 44 to 42 in both places.
- **Risk.** None.

### `LK-42` — make the register's evidence ids resolve here
- **Files.** `CLAUDE.md:75` (row 3), `:77` (row 5) and `:335`.
- **Shape.**
  - `LibKa0s-A-07` → `LK-28`, `LibKa0s-A-10` → `LK-37`, `LibKa0s-A-03` → `LK-17d`. Each of these
    resolves under `docs/audits/2026-09-23/`.
  - For the cross-repo plan items, either qualify them (*Ka0sAddonsCommonTasks
    `docs/2026-09-23-REVIEW_AND_STANDARDS_AUDIT_REMEDIATION/` item `LK-29`*) or replace them with this
    repo's commit sha for the change.
  - Rows stay in place and only the citations change. That is a doc change, not a re-decision
    (`audit-review-history`).
- **Constraint.** Do not edit `docs/automated-tests/20260924-040553/ANALYSIS.md` or any other frozen
  record that uses the `LibKa0s-A-*` form. Those are what they recorded.
- **Risk.** None.

## Group B — issue store (`LK-40`)

- **Shape.** For #32, #33, #37 and #39, run
  `gh issue edit <n> --remove-label state:triaged --add-label state:done`. Use the `gh` subcommands
  only, and space the four calls out.
- **Note.** This touches the issue store, not the tree. Leave no commit. If the remediation plan keys
  completion to commits, record it in that plan's `exceptions.tsv`, with
  `gh issue list --state closed --label state:triaged --json number` returning `[]` as the proof.

## Group C — payload (`LK-39`, and `LK-41` optionally)

### `LK-39` — the dead fallback rungs
- **Precondition (owner, in-game).** `/dump GetAddOnMetadata, IsAddOnLoaded` on the live retail client.
- **Branch 1: a global is nil, so the rung is dead.**
  - `LibKa0s/Env.lua`:
    - delete the `if GetAddOnMetadata then … end` block (`:64-66`);
    - rewrite the docblock at `:52-55` (the namespaced reader, else nil);
    - bump `LibKa0s-Env-1.0` to minor 2.
  - `LibKa0s/OptionsIdList.lua:485`: reduce the ladder to `C_AddOns and C_AddOns.IsAddOnLoaded`. The
    *trusted when neither exists* branch at `:486` already covers a client without it. Bump
    OptionsIdList to minor 4, which bumps the Options version key.
  - `tests/test_env.lua:31`: replace the fallback case with one that asserts nil when `C_AddOns` is
    absent.
  - `.luacheckrc:8-9`: drop `"GetAddOnMetadata"` and `"IsAddOnLoaded"` from `read_globals`, so lint
    then refuses a re-introduction.
  - Release work: CHANGELOG version block, new API documents (`Env/version-2-docs.md`, and the Options
    key), `lua tools/gen-api-members.lua`, a release run with `ANALYSIS.md`, and a re-vendor in all
    eleven consumers.
  - **This is not a floor raise.** Nothing floors on Env minor 2, so it is additive to the vendoring.
- **Branch 2: a global is present.** The payload is right and the standard's worked case is wrong for
  retail.
  - File the correction upstream against `compat`, citing this bundle and the `/dump` output.
  - Keep the rung, and record a register row here (`compat`, *rung kept: the global is live on
    retail*, trigger *the global is removed*) until the standard changes.
- **Risk.** Low. On every client that has `C_AddOns`, which is every client the collection admits, the
  deleted rung was unreachable.

### `LK-41` — the `file:line` citation
- Fold it into the next release that changes `LibKa0s/Slash.lua` for any reason. If there is none, ship
  it alongside `LK-39`'s release, since that release re-vendors anyway.
- Change `(slash-commands.md:34)` to `(slash-commands-§1)` and bump the Slash minor (Slash shell minor
  20).
- Close #43 `state:done` in the same change.
- **Constraint.** Never patch it in a consumer's vendored copy.

## Ordering constraints

1. Groups A and B are independent of each other and of C, and can land first.
2. `LK-39` waits for the owner's in-game `/dump`. Its two branches are mutually exclusive.
3. `LK-41` rides on the first payload release, and `LK-39`'s branch 1 is the natural carrier.
4. The release for C runs the full `docs/releasing.md` order, including the release bundle,
   `ANALYSIS.md` and the perf-skip sentence. Its `ANALYSIS.md` notes the `LK-17d` conversion.

## Upstream (WowAddonStandards), for the consolidated plan

- **U1.** In `library-stack-§7`'s inter-module paragraph, replace the line citations with the symbol
  `NEEDS_POOL` and name all three attach files (`OptionsWidgets.lua`, `OptionsTabs.lua`,
  `OptionsNav.lua`).
- **U2.** Depends on `LK-39`'s branch: correct the compat worked example, or confirm it.
- **U3.** Either classify `localization-§1`–`§4`, `testing-§2`–`§8`/`§12`–`§15` and
  `documentation-§8`/`§9` in `library-stack-§7`'s lists, or soften the claim that the lists are
  exhaustive.
