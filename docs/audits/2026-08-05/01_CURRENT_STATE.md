# 01 — Current state

**Repo:** `LibKa0s` (`/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s`)
**Run date:** 2026-08-05
**Audited against:** **Ka0s WoW Addon Standard v2.21.0 (2026-08-04)** — `standards/STANDARDS.md`, plus
**all 25 section files** linked from its Sections map, plus the `AUDIT.md` playbook.
**HEAD at audit:** `a29fd6381c1e3335d73c7a4c617baa12fd65d92d` (branch `master`). Newest tag `v1.7.0`
(`6ce8548a8f02a2e521c0e483adf149eaf20c986c`).

## How the standard was resolved

```
RAW=https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master
curl -fsSL "$RAW/AUDIT.md"                -> AUDIT.md              (158 lines)
curl -fsSL "$RAW/standards/STANDARDS.md"  -> STANDARDS.md          (142 lines, v2.21.0 2026-08-04)
curl -fsSL "$RAW/standards/standards/<f>.md" for every file linked in the Sections list -> 25 files
```

The 25 section files discovered by following the Sections list (never hard-coded):
`layout`, `toc-file`, `library-stack`, `architecture`, `savedvariables`, `options-ui`,
`standalone-windows`, `preview-mode`, `slash-commands`, `localization`, `events-frames-taint`,
`public-api`, `compat`, `debug-logging`, `packaging`, `lint`, `testing`, `performance`,
`automated-tests`, `documentation`, `audit-review-history`, `versioning-git`, `naming-cheatsheet`,
`anti-patterns`, `open-evolutions`.

`diff -r` of the 25 fetched section files against the local `WowAddonStandards` working copy is
**empty**, and the fetched `STANDARDS.md` / `anti-patterns.md` are byte-identical to it — so the
sections read here are verifiably the published master text.

## What this repo is, and how the standard was applied

`LibKa0s` is **the shared library**, not an addon. It has no `.toc`, no `libs/`, no `.pkgmeta`, no
SavedVariables of its own, and cannot be loaded by the client on its own. Rules that presuppose an
addon (TOC fields, the player-facing README shape and badge row, `.pkgmeta`, AceDB/AceAddon
bootstrap, locales, media, in-game smoke tests, the vendored-library `diff -r`) are recorded here as
**N/A with a one-line reason** rather than as deviations. Rules that the standard writes explicitly
for "the lib repo" (`library-stack-§7`, `testing-§10`, `testing-§11`, `versioning-git`) and rules
whose purpose survives the addon/library distinction (`documentation`, `localization-§5`, `lint`,
`testing`, `automated-tests`, `layout-§1`'s LOC cap, `audit-review-history`) are audited normally.

This is the **first** `docs/audits/` run in this repo. Deviation-ID prefix assigned: **`LK-`**
(reused for all subsequent runs).

## Section-by-section snapshot

### layout
Not the addon tree (`core/ defaults/ settings/ locales/ modules/`) — **N/A**: a library ships one
flat payload folder. Actual shape (`README.md:198-230`):

- `LibKa0s/` — the ship payload: `LibKa0s.xml` + 8 `.lua` + `LICENSE`.
- `testkit/` — the shared headless harness, master copy.
- `tests/` — this repo's own suite, consuming the kit through `tests/_kit/`.
- `docs/` — `api/`, `automated-tests/`, `adoption/`, `reviews/`, `superpowers/`, plus
  `releasing.md`, `record-schema.md`, `test-cases.md`, `adoption-prompt.md`, `adoption-report.md`.
- Root: `README.md`, `CHANGELOG.md`, `LICENSE`, `.luacheckrc`, `.gitattributes`, `.gitignore`.

**`layout-§1`'s 1500-LOC cap applies and is met.** Largest files: `tests/test_options_widgets.lua`
1114, `LibKa0s/Perf.lua` 1052 — both in the 1000–1500 on-notice band, both carrying a disposition in
`docs/automated-tests/RESULTS.md:84-88`. Nothing over 1500.

### toc-file
**N/A** — a library has no `.toc`; it is loaded through each host addon's TOC lib block
(`README.md:33`). The `## X-Standard:` place of `documentation-§6`'s three-place rule is therefore
unavailable here, which is what makes the other two places load-bearing (see LK-02).

### library-stack
This repo **is** `library-stack-§7`'s subject. What it owns:

- **Five majors across eight files, one aggregate XML** — `LibKa0s/LibKa0s.xml:2-9` lists
  `Core.lua`, `DebugLog.lua`, `Slash.lua`, `Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua`,
  `Perf.lua`, `PerfPanel.lua`, Core first. Exactly the table in `library-stack-§7`.
- **One LibStub major per module**, each file carrying its own MINOR constant
  (`docs/releasing.md:23-30` names all eight by their exact constant names).
- **Dependency floors enforced by returning before `NewLibrary`** — documented at `README.md:27-32`
  and `README.md:55-57`; exercised by `tests/test_perf_isolation.lua`.
- **`lib.MODULES` published per major** (`README.md:61-68`), answering version skew at runtime.
- **`testkit/` is a sibling of the ship folder, not inside it** (`README.md:210-212`), so nothing
  lands under a consumer's `libs/`.
- **No `libs/` folder here** — so `AUDIT.md`'s vendored-library `diff -r` is **N/A** for
  `libs/`; the equivalent check that does apply is `diff -r testkit/ tests/_kit/`, run in
  `03_EVIDENCE.md` and **empty**.

### architecture / savedvariables / events-frames-taint / compat / preview-mode / standalone-windows / public-api
**N/A as addon rules** — no `NS` bootstrap, no AceAddon registration, no AceDB profile, no message
bus, no `NS.API.v1`, no `core/Compat.lua`, no preview mode, no addon main window. The library
*implements* behavior these sections describe on behalf of hosts (the window skin in `Core.lua`, the
combat guards in `Options.lua`/`Perf.lua`, the persistence in `Perf.lua`), and that behavior was
re-measured by the code review at `docs/reviews/2026-08-05/` (verdict: ship-ready, no Critical, no
High). `public-api`'s substance is met by a stronger mechanism here: `docs/api/`, one frozen document
per shipped version of every major, indexed by `docs/api/README.md`, with the additive-only contract
stated at `README.md:73-81`.

### options-ui / slash-commands / debug-logging / performance (the module behavior)
These sections describe what `LibKa0s-Options-1.0`, `LibKa0s-Slash-1.0`, `LibKa0s-DebugLog-1.0` and
`LibKa0s-Perf-1.0` **supply**. This repo is the supplier, so the sections read here as the library's
own specification rather than as consumer wiring; there is no descriptor/stub pair to snapshot
because there is no host. Coverage: `tests/test_options.lua` (908), `tests/test_options_widgets.lua`
(1114), `tests/test_slash.lua` (865), `tests/test_debuglog.lua` (746), and five perf suites
(`test_perf_core` 596, `test_perf_run` 412, `test_perf_panel` 569, `test_perf_command` 163,
`test_perf_isolation` 176).

### localization
`localization-§1`–`§4` (`NS.L`, locale-gated files, enUS base) — **N/A**: a library has no
`locales/`; it carries per-module `STRINGS` and a `rawget`-based host override, documented at
`README.md:83-120`. **`localization-§5` (US English as the source dialect) applies to every authored
string, comment and doc, and is not met** — see LK-06.

### packaging
**N/A** — no `.pkgmeta`; the library is vendored by copy, not packaged. `.gitattributes` is present
and correct, including `automated-tests-§2`'s `*.sh text eol=lf` carve-out.

### lint
`.luacheckrc` present at root. `std = "lua51"`, `codes = true`, `max_line_length = false`,
`exclude_files = { "tests/", "docs/" }`, a commented `read_globals` set, `globals = { "_G" }` with a
written justification (`.luacheckrc:27-28`), and three `ignore` codes each carrying a multi-line
reason (`.luacheckrc:29-40`). `luacheck .` is **0 warnings / 0 errors over 11 files**. The scope is
narrower than the tree (test code is excluded) and `RESULTS.md:34-42` says so explicitly rather than
letting the 0/0 read as repo-wide.

### testing
- `testing-§1` — the kit is here at its master path `testkit/`, and this repo **consumes it as a
  consumer** through `tests/_kit/` (`tests/run.lua:10-12`, `README.md:156-159`). Compliant.
- `testing-§2/§3/§4` — commands and green gate documented at `README.md:122-145`; gate is
  `lua tests/run.lua` + `luacheck .`.
- `testing-§5` — `docs/test-cases.md` is generated by `--list` and regenerates **byte-identical**
  today. The README badge half is **N/A** (no player-facing badge row on a library).
- `testing-§9` — load lists derived from the TOC: no TOC, so the XML is the equivalent source. The
  MAJORS table is gated by `tests/test_versioning.lua`; the **loader's file list and the suite list
  are not** — see LK-09.
- `testing-§10` — the versioning suite exists and is the standard's own named reference
  implementation: `tests/test_versioning.lua`, 7 cases covering registration, per-file registry,
  cross-major leakage, positive integers, basename uniqueness, changelog agreement, and secondary
  pairing, collecting misses before failing (`tests/test_versioning.lua:107-128`).
- `testing-§11` — the kit-sync suite exists: `tests/test_kitsync.lua`, 4 cases, byte-comparison with
  no normalization, README included.
- `testing-§12` — one case asserts only *that* it raised (LK-10). The rest of the suite uses
  `assertError`; the review's mutation probes reddened 8 of 9 guards.

### performance
`performance-§1`–`§8` describe the harness this repo **is**. `performance-§9`'s offline scenario
runner is **absent** (`tests/perf.lua` does not exist) and that absence is a standing, documented
state (`RESULTS.md:44-56`) — see LK-13. `performance-§10`'s complexity measurement is adopted in its
`automated-tests` form: no `docs/complexity.md` (correctly retired), raw output in the bundle, watch
list in `RESULTS.md`.

### automated-tests
- `§1` bundle — one bundle, `docs/automated-tests/20260805-002859/`, local-time stamp with offset
  (`manifest.json` `startedAt: 2026-08-05T00:28:59+05:30`), carrying `manifest.json`, `ANALYSIS.md`,
  `lint.txt`, `tests.txt`, `test-cases.md`, `complexity.txt`. No `perf.txt` — the suite skipped.
- `§2` runner — `tests/_kit/run-automated-tests.sh` present, executable (`-rwxrwxrwx`), LF
  (`file` reports "Bourne-Again shell script … executable", no CRLF), byte-identical to
  `testkit/run-automated-tests.sh`. `.gitattributes:22` carries `*.sh text eol=lf`.
- `§3` gating — stated for the **run** in `docs/automated-tests/README.md:29-40` and
  `RESULTS.md:9-11`. The **release gate** half is stated nowhere — LK-08.
- `§4` `RESULTS.md` — present, one file overwritten in place, one row, all required columns
  (lint w/e, files, tests, perf, NLOC, funcs, avg NLOC, avg CCN, max CCN, CCN warn, verdict), the
  watch list as **two tables with header rows**, band as a **column**, and standing prose sections
  for all four suites (`## Test suite`, `## Lint`, `## Perf`, `## Complexity watch list`).
- `§5` `ANALYSIS.md` — present in the bundle.
- `§6` checkpoint — the bundle is not produced by the release order — LK-07.
- `§7` — `docs/complexity.md` **absent** (correctly retired). `docs/perf-runs/` absent with a written
  reason (`docs/automated-tests/README.md:47-51`).

### documentation
| Required | Here |
|---|---|
| root `README.md` (full) | **present** — but library-shaped, not the 12-section player README (correctly, see N/A note) |
| root `CLAUDE.md` (stub) | **absent** — LK-01 |
| root `DEPENDENCIES.md` | **absent** — LK-03 |
| `docs/ARCHITECTURE.md` | **absent** — LK-05 |
| `docs/testing.md` | **absent** — LK-04 |
| `docs/smoke-tests.md` | **absent** — LK-12 (N/A-adjacent; a library cannot be loaded alone) |
| `docs/test-cases.md` | **present**, generated, byte-fresh |
| `docs/performance.md` | **absent** — LK-12 |
| `docs/perf-runs/README.md` | **absent, with a written reason** — LK-12 (accepted) |
| `docs/automated-tests/README.md` | **present** |
| `docs/automated-tests/RESULTS.md` | **present**, generated |
| no `TODO.md` | **satisfied** |
| no `docs/agent-context.md` | **satisfied** |

`documentation-§1`'s 12-section player README, badge row, `## What's new`, `## Screenshots`,
`## Usage`, `## FAQ`, `## Issues and feature requests`, `## Version History` are **N/A** — the README
of a library is read by the developer vendoring it, not by a player, and there is no CurseForge page
or project id. The `documentation-§1` rule that contributor material must stay out of the README is
**N/A** for the same reason (`README.md:122-194` is deliberately contributor-facing).

`documentation-§6`'s three-place standards reference: place 1 (TOC) is N/A, place 2 (README badge)
is **absent**, place 3 (`CLAUDE.md`) is **absent** — LK-02.

### audit-review-history
`docs/reviews/` holds two frozen dated bundles (`2026-07-31`, `2026-08-05`), five artifacts each.
`docs/audits/` did not exist before this run — this bundle creates it. `docs/adoption/` holds three
further frozen dated bundles, an extra history the standard neither requires nor forbids.

### versioning-git
Semver tags `v1.2.0` … `v1.7.0`. The two-axis rule (repo semver vs per-file LibStub minor) is stated
in three places and enforced mechanically by `tests/test_versioning.lua`
(`README.md:161-178`, `CHANGELOG.md:1-11`, `docs/releasing.md:3-13`). Trunk-based on `master`.
`versioning-git`'s re-vendor-commit-per-consumer rule is written into the release order
(`docs/releasing.md:65-80`).

### naming-cheatsheet / open-evolutions
Naming: the collection conventions are followed in the shipped payload
(`PascalCase` files, `SCREAMING_SNAKE` constants, `lib:New` descriptor). `open-evolutions` is
directional, not normative — nothing to measure.

### anti-patterns
Checked and **not** present: #7 (`externals:`), #14 (hostile license — MIT, shipped inside the
payload), #16 (>1500 LOC), #21 (feature branches), #26/#49 (root agent brief / scaffolding pack),
#45 (`diff -r testkit tests/_kit` empty), #47 (this repo *is* the library), #48 (whole-folder
payload, one aggregate XML), #51 (complexity numbers reproduce exactly today), #52 (no
metric-gaming refactor in the diff), #53 (two watch-list entries, first run, no streak),
#55 (`library-stack-§7`'s three bars are quoted back at candidates in `docs/superpowers/`).
Present: **#34** (the three-place standards reference — LK-02).
</content>
</invoke>
