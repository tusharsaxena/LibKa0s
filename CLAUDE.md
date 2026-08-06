# CLAUDE.md — LibKa0s

LibKa0s adheres to the **Ka0s WoW Addon Standard** (v2.22.0) —
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
  `versioning-git`; `localization-§5` (US English in authored text — a British spelling here is
  vendored into eight consumers and becomes eight findings); `documentation-§5`; `documentation-§7`.
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

**One extra rule this repo carries, because it is upstream of eight others.** Everything in
`LibKa0s/` and `testkit/` is **vendored** — into `<Addon>/libs/LibKa0s/` and `<Addon>/tests/_kit/`
respectively. A defect shipped from here reappears in every consumer, and a fix is only real once it
is re-vendored. Never patch a vendored copy downstream; fix it here and copy across.

## Documented deviations

| Rule | What differs | Why | Decided | Re-check trigger |
|---|---|---|---|---|

**None ratified today.** The table is here empty on purpose: the alternative is a register that gets
created in the same breath as the first deviation, by whoever is already arguing for it.

`library-stack-§7`'s "does not apply" list is **not** a deviation register — those sections do not
bind this repo at all, so there is nothing to ratify. A row belongs here only when a section that
*does* bind is knowingly not followed.

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
| [`docs/api/`](docs/api/) | **The source of truth for every public contract** — one document per shipped version, per major (`Core`, `DebugLog`, `Options`, `Perf`, `Slash`, `testkit`). A superseded document is never edited to describe new behavior |
| [`docs/releasing.md`](docs/releasing.md) | The two version numbers (repo semver and the load-bearing per-file LibStub minor), the numbered release order, and the re-vendor rule |
| [`docs/record-schema.md`](docs/record-schema.md) | The in-game Perf capture record, field by field — the contract each consumer's `perf-runs/README.md` points at rather than restating |
| [`docs/adoption-prompt.md`](docs/adoption-prompt.md) | The brief handed to a consumer repo adopting a major: what to wire, what to delete, and what must not be hand-rolled |
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

That `luacheck` figure is **scoped by `.luacheckrc`'s `exclude_files`**, not repo-wide — twelve files
today, the eight in `LibKa0s/` plus four under `testkit/`. 0/0 only means something if the files
carrying the change are inside the checked set.
