# 01 — Current state

**Repo:** `LibKa0s` (Ka0s-owned shared library, not an addon).
**Run date:** 2026-09-07. **Standard audited against:** **v2.38.0 (2026-09-02)** — the version at the
top of `standards/STANDARDS.md`, fetched with `curl` from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`, index plus **all 26 section
files** listed under *Sections*, plus `standards/ADDONS.md`.
**Prior run:** `docs/audits/2026-08-05/` (standard v2.21.0, prefix `LK-`). IDs continue that prefix.

## Which rule set this run used

`AUDIT.md` step 1's **switch rule** applies: this repo has **no `.toc`**, so it is a
**Ka0s-owned library repo** (`standards/ADDONS.md` → *Ka0s-owned library repos*) and is measured
against **`library-stack-§7`'s applicability list**, not the addon rule set.

**Applies, unchanged** (§7's first list): `testing-§1`, `testing-§9`, `testing-§10`, `testing-§11`;
`lint`; `automated-tests`; `versioning-git`; `line-endings`; `localization-§5`; `documentation-§5`;
`documentation-§7`.

**Treated as NOT APPLICABLE** (§7's second list) — recorded here, filed nowhere:

| Section | Why it does not bind |
|---|---|
| `documentation-§1` | No player-facing README; no badge row, no bundled-library inventory check, no `## Libraries` grep. |
| `documentation-§2` | The addon `CLAUDE.md` stub shape assumes an addon; `CLAUDE.md` here is §7's substitute. No LibKa0s provenance line is owed — **this repo is the upstream**. |
| `documentation-§3` | The `docs/` trio, the five verification-and-record docs, and the **whole tier model** (`scope.md`, `module-map.md`, `schema.md`, `settings-panel.md`, `data-flow.md`, `common-tasks.md`, all Tier 2, `## Documentation map` in an `ARCHITECTURE.md` that does not exist here). Its *register purpose* survives, in `CLAUDE.md` — checked below. |
| `toc-file` | No TOC. Position annotations, `X-Curse-Project-ID` and the `# Core` block checks are all vacuous. |
| `options-ui` | No settings canvas here. The nine content checks bind the **consumer** that wires `LibKa0s-Options-1.0`. (§16's composer contract is still cited below where the library's own composer is defective.) |
| `slash-commands` | No slash surface; the dispatcher is a module consumers wire. |
| `preview-mode` | No on-screen display. |
| `savedvariables` | No SavedVariables file. |
| `packaging` | No `.pkgmeta`, no CurseForge package. The dot-entry sweep is not run. |
| `library-stack-§7`'s vendoring/`diff -r` checks | **Inverted here.** There is no `libs/`; this repo *is* the ship folder. The equivalent gate is `testkit/` ↔ `tests/_kit/` byte-identity, which is green. |

Sections in **neither** §7 list — `layout`, `architecture`, `performance`, `compat`, `anti-patterns`,
`naming-cheatsheet`, `public-api`, `standalone-windows`, `events-frames-taint`, `debug-logging`,
`audit-review-history`, `open-evolutions` — are an upstream gap; see **LK-27**. This run applied
`layout-§1`'s LOC bands (they are pulled in transitively by `automated-tests-§4`, which *is* in the
applies list), `compat`'s deprecated-API rule, and the `anti-patterns` list, and treated the rest as
addon-shaped.

## Layout

Repo root: `LibKa0s/` (ship payload), `testkit/` (harness master), `tests/` (suite + vendored
`tests/_kit/`), `docs/`, `tools/`, `media/logos/`, and the root doc set.

- **Ship payload** — `LibKa0s/` holds **14** `.lua` files across **10 LibStub majors**, one aggregate
  `LibKa0s/LibKa0s.xml`, `LibKa0s/LICENSE`, and the non-code `LibKa0s/media/` payload (fonts, 130
  icons, 6 textures). Majors: `Core`, `Env`, `Item`, `Pool`, `Media`, `Widgets`, `DebugLog`, `Slash`,
  `Options` (**four** files — `Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua`,
  `OptionsCompose.lua`), `Perf` (`Perf.lua`, `PerfPanel.lua`).
- **Media** — `media/logos/ka0s.logo.{jpg,png}` at the repo root is the collection logo, which
  `AUDIT.md` names as legitimately remaining. No private duplicate of the shared payload
  (anti-pattern #63 clean).
- **LOC** — six files at or over `layout-§1`'s 1000-line on-notice threshold; **two over the 1500
  cap** (`LibKa0s/OptionsWidgets.lua` 1838, `tests/test_options_widgets.lua` 2287). See **LK-18**.

## Root doc set

| File | State |
|---|---|
| `README.md` | Present, consumer-facing. Names the standard at `:3` — but as **v2.28.0** (LK-26). |
| `CLAUDE.md` | Present, 118 lines. Carries `## Standards compliance (read first)` (`:37`), `## Documented deviations` (`:64`, empty by design), `## Documentation map` (`:76`), `## The green gate` (`:107`). §7 substitutes 1 and 4 satisfied. |
| `DEPENDENCIES.md` | Present, evidence-based, three groups, WSL2/Ubuntu commands with the PEP-668 `pipx` workaround, per-tool verify lines, and a "verified with" block naming 18 linted files. `documentation-§7` **compliant**. |
| `CHANGELOG.md` | Present — **required** at a library root per §7; `tests/test_versioning.lua` reads it. Head is `## v1.25.0 — 2026-09-03`. |
| `LICENSE` | MIT. |
| `.luacheckrc` | `std = "lua51"`, `exclude_files = { "tests/", "docs/" }`, commented `read_globals`, one commented `globals` entry (`_G`), three `ignore` codes each with a written reason. |
| `.gitattributes` | Present, **byte-identical to `line-endings-§5`'s canonical client-bound body** (81 lines, verified by diff). |

## Documentation map (§7 substitute 4)

`CLAUDE.md:76-105` carries the map. Checked **in both directions** and it resolves both ways: every
live `.md` under `docs/` has a row or falls under a named frozen directory
(`docs/audits/`, `docs/reviews/`, `docs/automated-tests/`, `docs/adoption/`, `docs/superpowers/`),
and every row resolves to a file or directory on disk. No dangling rows, no orphans. **Compliant.**

## Deviation register (§7's home for a ratified decision)

`CLAUDE.md:64-74`. The table is **empty**, with a written statement that nothing is ratified today
and a note that §7's "does not apply" list is not a deviation register. That reasoning is correct.
One decision is nonetheless ratified elsewhere and owes a row — see **LK-25**.

## Issue store (`audit-review-history`)

Read with `gh issue list --state all --limit 200 --json number,title,state,labels,url`. 15 issues,
every one carrying a `state:` label and a `severity:` label. No `[status]` title prefix survives
(anti-pattern #62 clean). No `docs/pending/LEDGER.md` and no `docs/pending/` directory
(anti-pattern #60 clean).

- Open: #15 (`state:untriaged`, `severity:high`, `bug`), #12, #9, #8, #7, #6, #5, #3, #2, #1.
- Closed: #14, #13, #11 (`state:done`), #10 (`state:will-not-do`), #4 (`state:done`).
- #10 is a declined **enhancement**, not a declined standards rule, so it owes no register row.
- #7 and #8 are the two `layout-§1` band dispositions, each with an owner. They record a
  non-violation, so they owe no register row either.

## Tests, lint, complexity — as observed today

- `luacheck .` → **0 warnings / 0 errors in 18 files** (luacheck 1.2.0). Scope is `.luacheckrc:4`'s
  exclusion set: the 14 files in `LibKa0s/` plus the 4 in `testkit/`; no test code.
- `lua tests/run.lua` (Lua 5.1.5) → **764 passed, 0 failed, 0 skipped, 764 total**.
- `lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` → **13678 NLOC, 1900 functions, avg CCN 1.9,
  0 warnings, "No thresholds exceeded"** — reproducing the newest bundle
  `docs/automated-tests/20260903-161751/complexity.txt` **exactly**. No drift (anti-pattern #51 clean
  *for the numbers*; the prose around them is a different matter — LK-17).
- `testing-§9` — the load list is **derived** (`tests/run.lua:24`, `Loader.xmlFiles("LibKa0s/LibKa0s.xml")`)
  and the declared suite list (`tests/run.lua:112-118`) is pinned in **both** directions by
  `Kit.assertSuiteInventory` (`testkit/framework.lua:277-316`). **Compliant** — LK-09 from the prior
  run is closed.
- `testing-§10` — versioning suite present, 8 cases, including "every major's live version has its
  API document on disk" (`tests/test_versioning.lua:165`). **LK-15 from the prior run is closed.**
- `testing-§11` — the library-side kit-sync gate is green: `testkit/` and `tests/_kit/` hold the same
  files, byte-identical, README included, and the runner is mode `100755` in the index in both copies.

## Line endings

`.gitattributes` present; pin `* text=auto eol=crlf` (`:26`) — correct for a client-bound repo, which
§7 names this one explicitly; `*.sh text eol=lf` (`:34`); 20 `binary` markings. Body diffs **clean**
against `line-endings-§5`'s canonical client-bound file. The **working-tree check (e)** reports
**7 tracked files** disagreeing with the pin — see **LK-24**.

## Automated-tests record

`docs/automated-tests/` holds **31 run bundles** plus `README.md` and `RESULTS.md`. The runner is
vendored at `tests/_kit/run-automated-tests.sh`, executable, byte-identical to its master. `RESULTS.md`
is one file, overwritten in place, 31 rows, with four standing sections and a watch list below the
table. `docs/complexity.md` (retired v2.19.0) is **absent**; `docs/perf-runs/` (retired v2.29.0) is
**absent**; `file-index.md` / `conventions.md` are **absent**.
