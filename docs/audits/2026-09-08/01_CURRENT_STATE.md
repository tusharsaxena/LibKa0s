# 01 — Current state

**Audited against:** Ka0s WoW Addon Standard **v2.39.0 (2026-09-07)** —
`standards/STANDARDS.md:1`, resolved from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master` and confirmed before any
measurement was taken. The playbook followed is that repo's `AUDIT.md` at the same ref.

**Repo:** `LibKa0s`, branch `master`, HEAD **`9668a29`** (`Merge branch
'feat/2026-09-07-audit-review-remediation'`), working tree clean.

**Rule set used: `library-stack-§7`'s applicability list.** This repository has **no `.toc`**, so
`AUDIT.md` step 1's switch rule applies: it is a **Ka0s-owned library repo**, not an addon, and is
measured against §7's three applicability lists rather than the addon sections. That block changed
this cycle — at v2.38.0 §7 shipped **two** lists and a *Substitutes* list; v2.39.0 (`M1-STD-08`)
adds the third, **Applies, read for a library repo**, and declares the three **exhaustive over the
Sections list** with *applies* as the default. Twelve sections that sat unclassified at the last
audit now have an explicit disposition, and two of this run's entries live in that newly-classified
space.

The repo states the same scoping for itself at `CLAUDE.md:6-35`, and it now matches the standard.

---

## What binds, and what does not

| List | Sections |
|---|---|
| **Applies, unchanged** | `testing-§1/§9/§10/§11`, `lint`, `automated-tests`, `versioning-git`, `line-endings`, `localization-§5`, `documentation-§5`, `documentation-§7` |
| **Applies, read for a library repo** | `layout`, `library-stack`, `architecture`, `performance`, `compat`, `anti-patterns`, `public-api`, `debug-logging`, `events-frames-taint`, `standalone-windows`, `naming-cheatsheet`, `audit-review-history`, `documentation-§4`, `open-evolutions` |
| **Does not apply** | `documentation-§1`, `documentation-§2` as written, `documentation-§3`'s trio / verification-and-record set / **whole tier model**, `toc-file`, `options-ui`, `slash-commands`, `preview-mode`, `savedvariables`, `packaging` |

`documentation-§3`'s tier model is **not** evaluated here, and the `docs/` directory-listing check
`AUDIT.md` step 4 describes is **not run**: `library-stack-§7` removes it explicitly, and four of
Tier 1's six docs have no subject in a repo with no settings canvas, no SavedVariables and no
in-game pipeline. What replaces it is §7's **Substitutes** list, checked below.

---

## Layout (`layout`, read for a library)

- **Payload:** `LibKa0s/` — 14 authored `.lua` files plus `LICENSE` and `media/`, loaded by the one
  aggregate `LibKa0s/LibKa0s.xml` (14 `<Script>` entries, matching `library-stack-§7`'s *ten majors
  across fourteen files*).
- **Repo shape:** `LibKa0s/` (payload) · `testkit/` (authored harness, vendored downstream) ·
  `tests/` (suite + `tests/_kit/`, this repo's own vendored copy of `testkit/`) · `docs/` ·
  `tools/` · `media/logos/`. No `libs/` — the headless suite runs on the kit's mocks. No `core/`,
  `defaults/`, `settings/`, `locales/`, `modules/` skeleton, which §7 says does not bind.
- **`layout-§1` cap.** v2.39.0 states what the cap binds — every authored `.lua` the repo tracks,
  `tests/` and a library's own payload folder included, with `tests/_kit/` the vendored carve-out.
  Measured today: **two** files over 1500 — `tests/test_options_widgets.lua` (2398) and
  `LibKa0s/OptionsWidgets.lua` (1989). Both sit in a **terminal compliant state**: an open issue
  naming the seam (#8, #16) plus the census at `CLAUDE.md:102-105`, which
  `tests/test_layout_cap.lua` gates in both directions. `layout-§1` says an audit **MUST NOT**
  re-file against a file in that state, so nothing is filed. Five files are in the 1000–1500 band;
  `tests/test_widgets.lua` at 1493 is seven lines from the cap.
- **`layout-§3`.** `LibKa0s/media/` is typed — `fonts/` (1 face + its OFL), `icons/` (114 `.tga`),
  `textures/` (7 `.tga`). The repo's own `media/logos/` holds the collection logo only. Nothing
  loose in either.

## Library stack (`library-stack`)

- §7 binds this repo directly. Ten majors, fourteen files, one aggregate XML — verified against
  `LibKa0s/LibKa0s.xml` rather than against prose.
- **§9 (new at v2.39.0) — the widget re-registration is the library's.** Published as
  `lib.__PatchLSM30Border()` at `LibKa0s/Options.lua:269`, idempotent behind the
  `lib.__lsmBorderPatched` sentinel at `:270`. This is `M1-LK-05`, and it is what the five addon-side
  `core/LSMPatch.lua` copies now call instead of registering for themselves.
- §5/§6 survive as constraints on what the payload may contain: no fork of an Ace lib, no addon-suite
  dependency. Nothing in the payload violates either.
- **`diff -r` against a source repo is not applicable** — this repo *is* the source. Its equivalent
  is the kit-sync gate (`tests/test_kitsync.lua`), which asserts `testkit/` and `tests/_kit/` hold the
  same file set, byte-identical, README included, and both at mode 100755 for the runner. Green.

## Lint (`lint`)

`.luacheckrc:4` reads `exclude_files = { "tests/_kit/" }` and `:57-59` carries
`files["tests/"] = { globals = { "LK_TEST" } }`. That is exactly the shape v2.39.0's `lint` template
mandates, and it is this cycle's `M1-LK-12`. `luacheck .` is **0 warnings / 0 errors in 51 files**.
The two authored documents that describe that scope have **not** followed it — see `LK-29`.

## Testing (`testing-§1/§9/§10/§11`)

`lua tests/run.lua` → **795 passed, 0 failed, 0 skipped, 795 total**. The load list derives from
`LibKa0s.xml` (`tests/run.lua:24`); the suite list is pinned both ways by
`Kit.assertSuiteInventory`. The versioning suite gates the changelog, the per-file minors, the API
document per major and each major's published member manifest. `Kit.assertSurfaceParity`
(`M1-LK-09`) is present and exercised by `tests/test_surface_parity.lua`. The EOL gate
(`tests/_kit/test_eol.lua`, kit revision 15) runs over the whole tracked set and is green.

## Automated tests (`automated-tests`)

- Runner: `testkit/run-automated-tests.sh` (authored here, vendored as `tests/_kit/`), executable in
  both copies.
- `docs/automated-tests/README.md` and `RESULTS.md` both present; **34** frozen bundles, newest
  `20260908-181447` (`addonVersion` 1.27.0, `release: null`, verdict green).
- Manifest now carries the `gates` object per suite — the machine-readable half §4 gained this
  cycle — alongside the legacy `gating` boolean.
- `RESULTS.md`'s lead-in names the checkpoint per suite including the tag gate and *NOT EVALUATED*
  (`:10-20`), and the `Tests` cell reads `passed/skipped/total` (`:22`, `:26`). Both were open
  findings last cycle and both are closed.
- The complexity watch list is regenerated, seven entries, every one with a disposition. One
  disposition is 25 release runs old — `LK-17d`. The warned-functions half is prose, not a table —
  `LK-30`.
- **19 of 34 bundles carry no `ANALYSIS.md`, and 19 of the 30 release runs among them carry
  none** — including both releases cut this cycle. See `LK-19`.

## Performance (`performance`, read for a library)

The wiring MUST does not bind — there is no addon to wire and no slash surface. `performance-§10`'s
`lizard` measurement and its **release** checkpoint do. Run verbatim today, the numbers reproduce
`20260908-181447/complexity.txt` exactly: 14564 NLOC, 1993 functions, avg CCN 2.0, max CCN 14,
**0** warnings. No drift, no hand-editing.

## Compat (`compat`, newly classified)

No single `Compat` owner. Two deprecated-API sites in the payload, both correctly guarded and both
answering on today's client: `LibKa0s/Env.lua:60-67` (`C_AddOns.GetAddOnMetadata` → global) and
`LibKa0s/Perf.lua:656-658` (`C_SpecializationInfo.GetSpecialization` → global). The second is this
cycle's `M1-LK-13`, which closed the finding that there was **no** namespaced rung; it placed the
shim inline rather than at the owner. See `LK-31`.

## Line endings (`line-endings`)

`.gitattributes` present at the root, **81 lines**, and it diffs **clean** against `line-endings-§5`'s
canonical **client-bound** body with nothing in the tail — so no `§5 appendix` is claimed and none is
needed (the only extension-less tracked files are `LICENSE` and `LibKa0s/LICENSE`, both text).

- pin: `.gitattributes:26` — `* text=auto eol=crlf`
- `*.sh` carve-out: `.gitattributes:34` — `*.sh text eol=lf`
- binary marks: 20
- working tree vs declared pin: **0 files disagree** (last cycle: 7)
- owner: `tests/_kit/test_eol.lua`, kit revision 15, whole tracked set, green

## Documentation (`documentation-§4/§5/§7` + §7 Substitutes)

| Substitute | State |
|---|---|
| Root `CLAUDE.md` with `## Standards compliance (read first)` | Present, `CLAUDE.md:37` |
| Root `DEPENDENCIES.md` | Present; three-grouped, evidence-based, one verify line per tool. Its lint-scope sentence is stale — `LK-29` |
| `README.md` pointer naming the version | `README.md:3` — "v2.39.0". Current |
| `## Documentation map` in root `CLAUDE.md` | `CLAUDE.md:137-166`. Resolves in **both** directions: every live `.md` under `docs/` has a row, every row resolves, and the five frozen/generated directories are named once each |
| Root `CHANGELOG.md` | Present and gated by `tests/test_versioning.lua` |

`documentation-§4`: no root `TODO.md`. No retired `docs/complexity.md`, `docs/file-index.md`,
`docs/conventions.md`, `docs/perf-runs/` or `docs/pending/`.

## Audit and review history (`audit-review-history`)

- Frozen dated bundles under `docs/audits/` (2026-08-05, 2026-09-07) and `docs/reviews/`
  (2026-07-31, 2026-08-05, 2026-09-07). None touched by this run.
- **The register.** `CLAUDE.md:64-68` carries `## Documented deviations` with **one** row
  (`localization-§5`, the `lib.ICONS` `minimise` key). All three of §7's MUSTs were run against it —
  read before filing, rule-change check, and the trigger-and-evidence evaluation. Details in
  `03_EVIDENCE.md`; the row stands.
- **Issue store.** 26 issues, read with `gh issue list --json`. Every one carries a `state:` and a
  `severity:` label; no `[status]` title prefix anywhere; no `docs/pending/LEDGER.md`. Eight closed
  `state:will-not-do` issues were each checked against the **inverse rule** — a ratified decline with
  no register row is itself a finding. #22 (the `minimise` key) is a declined standards rule **and has
  its register row**. The other seven decline enhancements, proposals or scheduling, not standards
  rules, and owe no row.

## Shared subsystems

This repo **is** the library. There is nothing to hand-roll here and anti-patterns #45, #47 and #48
have no instance. The consumer-side gates this repo owns — `testkit/vendor_sync.lua` (provenance line
in root `CLAUDE.md`, no `README.md` fallback) and `testkit/test_eol.lua` — are audited as *source*
here and as *vendored payload* in each consumer.
