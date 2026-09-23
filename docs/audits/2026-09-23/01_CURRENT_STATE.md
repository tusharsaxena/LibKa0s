# 01 — Current state: LibKa0s

**Run date:** 2026-09-23. **Audited commit:** `46ccaa6` (`Merge branch 'suite/2026-09-22-standards-sweep'`),
on branch `feat/2026-09-23-review-audit-remediation`, with a clean tree for every tracked file this audit reads.
**Standard:** Ka0s WoW Addon Standard **v2.64.0 (2026-09-23)**. This was fetched with `curl -fsSL` from
`https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`: `AUDIT.md`,
`standards/STANDARDS.md`, all **27** section files its Sections list links, and `standards/ADDONS.md`. Every
fetch succeeded.
**Prefix:** `LK-`, assigned 2026-08-05 and stable. New IDs continue from `LK-33`.
**Previous audit:** `docs/audits/2026-09-08/`, against v2.39.0.
**Runner note:** the task brief said `ka0s-bounded` was not on `PATH`. The binary exists at
`~/.claude/wow-addon/bin/ka0s-bounded`, so every `luacheck`, `lua tests/run.lua` and `lizard` run in this
bundle went through it by absolute path. None of those runs exited 124 or 137.

## Repository kind, and the rule set used

**Kind: Ka0s-owned library repo** (`AUDIT.md` step 1; `documentation-§8`'s discriminator):

- the repo has no `.toc`;
- it ships a client-bound Lua payload (`LibKa0s/`, 146 tracked files) that eleven consumers vendor into
  `libs/LibKa0s/`;
- `standards/ADDONS.md` lists `LibKa0s` among the Ka0s-owned library repos.

**Rule set: `library-stack-§7`'s three applicability lists.** They classify every section in the Sections
list. I checked that mechanically against the 27 fetched files, and none is unclassified.

| List | Sections |
|---|---|
| Applies, unchanged | `testing-§1`, `§9`, `§10`, `§11`; `lint`; `automated-tests`; `versioning-git`; `line-endings`; `localization-§5`; `documentation-§5`, `§7` |
| Applies, read for a library | `layout`; `library-stack`; `architecture` (the module pattern and bus only); `performance` (`§10` only); `compat`; `anti-patterns`; `public-api`; `debug-logging`; `events-frames-taint`; `standalone-windows`; `naming-cheatsheet`; `audit-review-history`; `documentation-§4`; `open-evolutions` |
| Does not apply | `documentation-§1`, `§2`, `§3` (the trio, the verification docs, the tier model, the addon-shaped `## Documentation map`); `toc-file`; `options-ui`; `slash-commands`; `preview-mode`; `launcher`; `savedvariables`; `packaging` |

The *Does not apply* sections are not measured here and produce no entries. That includes the whole
`slash-commands-§7` disabled-state census: this repo has no addon to stand down and no slash surface. It
also includes the `docs/` tier-model checks (a)–(f), `.pkgmeta`, the TOC annotations, `## IconTexture`,
the launcher and the settings-panel content checks. The library-side halves of those subsystems (the
Lifecycle latch, the Slash dispatcher, the Launcher, the Options composers) are measured in the consumers
that wire them.

## Snapshot, section by section

### Layout (`layout`, read for a library)

- **Shape.** The repo holds the payload folder `LibKa0s/` (21 `.lua`, `LibKa0s.xml`, `LICENSE` and the
  `media/` subtree with `icons/`, `textures/` and `fonts/`). Beside it sit `testkit/` (11 files),
  `tests/` (61 tracked, including the vendored `tests/_kit/`), `tools/` (`gen-api-members.lua` and
  `artwork/{icon_cleaner,bar_textures}.py`), `docs/`, `media/logos/` (the collection logo only) and the
  root docs.
- **Authored Lua census.** `git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'` returns **81** files
  and 48,609 lines. Three files are over the 1500 cap and ten sit in the 1000–1500 band (`03_EVIDENCE.md` §E1).
- **Over-cap census.** `CLAUDE.md:89` `### Files over the 1500-line cap` is nested under
  `## Documented deviations` (`:69`), as `layout-§1` and `library-stack-§7` require for this host. It has
  three rows (`:129-131`). Two point at open issues (#33 and #32, both `state:triaged`). The third,
  `testkit/framework.lua`, claims a "Ratified deviation row", but the register table has no such row. That
  is `LK-34`.
- **Gate.** `tests/_kit/test_layout_cap.lua` is wired by pair (`tests/run.lua:95`,
  `{ name = "test_layout_cap", dir = "tests/_kit/" }`) with `Kit.layoutCap = { hub = "CLAUDE.md" }`
  (`:71`), and the hand-written local copy is gone (`git ls-files tests/test_layout_cap.lua` is empty). Its
  seven cases and seven self-tests pass.
- **Generators.** `git ls-files '*.py' '*.sh'` returns `tools/artwork/bar_textures.py`,
  `tools/artwork/icon_cleaner.py` and the runner (`testkit/run-automated-tests.sh` plus its vendored copy).
  The runner writes only a dated record and is not a generator. Both `.py` files and
  `tools/gen-api-members.lua` sit under `tools/`, outside the payload, and `DEPENDENCIES.md:98-100` names
  Python 3, Pillow and NumPy. This conforms.

### Library stack (`library-stack`)

- **Majors and files.** `grep -c 'major = "LibKa0s-' tests/majors.lua` gives **15**, and
  `grep -c '<Script file=' LibKa0s/LibKa0s.xml` gives **21**. Both match `library-stack-§7`'s table and
  the repo's own prose (`README.md:13,78`; `docs/releasing.md:26,47,182`).
- **Consumers.** `ls -d ../*/libs/LibKa0s/Perf.lua | wc -l` gives **11**, matching every "eleven
  consumers" in the repo's prose.
- **Kit sync (`testing-§11`).** `diff -r testkit tests/_kit` is **empty**, byte and content alike. The
  kit is at `Kit.VERSION = 25` (`testkit/framework.lua:20`).
- **`§9`.** The `LSM30_Border` re-registration is the library's and sits behind the
  `lib.__lsmBorderPatched` sentinel (`LibKa0s/Options.lua:294`).
- **`§1`–`§6`, anti-patterns #45, #47 and #48.** This repo has no `libs/` folder and is the upstream,
  so these have no instance.

### Deviation register (`audit-review-history`, hosted in root `CLAUDE.md`)

`CLAUDE.md:69-76` holds **four rows**, and `:78` says so.

| # | Rule | Subject | Trigger fired? | Evidence resolves? |
|---|---|---|---|---|
| 1 | `localization-§5` | `.cancelled` / `IsCancelled` in `testkit/mock_base.lua` and `mock_record.lua` | No: `tests/test_prose.lua` is green | "the v1.31.0 review" has no bundle under `docs/reviews/`. It resolves to commit `1f1790c`. That is `LK-38`, Info |
| 2 | `localization-§5` | `lib.ICONS`' `minimise` | No: `LibKa0s/media/icons/` holds `minimise.tga` only, and `lib.Icon` (`LibKa0s/Media.lua:202-207`) has no alias map | Yes: `LK-06` appears in `docs/audits/2026-09-07/02_DEVIATIONS.md` |
| 3 | `localization-§5` | The kit prose gate is unwired and the repo's own `tests/test_prose.lua` runs instead | No: `testkit/test_prose.lua` has no non-ASCII case and no retired-section case, and the `tests/` sweep has not happened | Self-evidencing: measured in-row |
| 4 | `compat` | `LibKa0s/Perf.lua:707-715` reads the spec globals inline, duplicating `Compat.lua:270` and `:289` | No: v1.55.0 moved no existing file's minor | Yes: `LK-31` in `docs/audits/2026-09-08/04_TECHNICAL_DESIGN.md` and `05_EXECUTION_PLAN.md`; `docs/api/Compat/version-1-docs.md:289` |

- **Cited rules.** None of the four cited rules changed in a way that retires its row at v2.64.0.
- **Row 3 now covers the 2026-09-08 `LK-28d`.** Row 3 ratifies the gate's narrower scope (the two shipped
  folders), so `LK-28d` is recorded as accepted. It does **not** ratify the British spellings themselves:
  its own trigger names the `tests/` sweep as outstanding. `LK-28` therefore stays open.

### Issue store (`audit-review-history`)

I ran `gh issue list --state all --limit 200 --json …`, which returned **34** issues.

- **Open: 14.** `state:triaged` #1, #2, #3, #5, #6, #7, #9, #32, #33; `state:untriaged` #12, #17, #18,
  #19, #20, #34.
- **Closed `state:will-not-do`: 7.** #10, #21, #22, #23, #24, #25, #26.
- **Closed `state:done`: the rest.**
- **Inverse register rule.** Only #22 declines a standards rule (`localization-§5`), and register row 2
  carries it. #10, #21, #23 and #24–#26 decline enhancements, an API change or scheduling.
- **Hygiene.** There is no `docs/pending/`, no `LEDGER.md` and no `[status]` title prefix, and every
  issue has a `state:` label.
- **Observation, not a finding:** #17–#20 are consumer-side items titled "deferred to kit 16". The kit is
  now at revision 25, and they remain `state:untriaged`. Untriaged is the store's ordinary backlog state,
  so they are left to `/wow-addon:issue-triage`.

### Lint (`lint`)

- **Run.** `luacheck .` (bounded) reports **0 warnings / 0 errors in 81 files**, exit 0.
- **Config.** `.luacheckrc:4` reads `exclude_files = { "tests/_kit/" }`, which is exactly the narrowing
  `lint` allows. The harness globals sit in a `files["tests/"]` stanza (`.luacheckrc:67`), not in
  top-level `read_globals`. `ignore = { "212/self", "212/event", "432/self" }` (`:56`) is the standard's
  usual unused-argument set.

### Testing (`testing-§1`, `§9`, `§10`, `§11`)

- **Run.** `lua tests/run.lua` (bounded) reports **1484 passed, 0 failed, 1 skipped, 1485 total**, exit 0.
  The one skip is the declared decline of `tests/_kit/test_prose.lua`, and it carries register row 3's
  reason.
- **Suites.** `tests/run.lua:85` lists `test_versioning`, `test_kitsync` and `test_prose`, and `:95`
  wires the kit's `test_layout_cap`. The eol and layout-cap kit gates are green.
- **Inventory.** `docs/test-cases.md` is byte-identical to the latest bundle's `test-cases.md`.

### Automated tests (`automated-tests`) and complexity (`performance-§10`)

- **Runner.** `testkit/run-automated-tests.sh` is mode `100755` and identical to its vendored copy.
  `docs/automated-tests/README.md` and `RESULTS.md` both exist, and there is no retired
  `docs/complexity.md`.
- **Bundles.** There are 74 in total. 68 carry a `release` stamp, and 23 carry an `ANALYSIS.md`.
- **Latest bundle.** `20260923-144526` has `release` `1.55.0`, measured sha `ae48f3f`, clean, verdict
  green. It is **4 commits** behind HEAD (`git rev-list --count ae48f3f..HEAD`). Those four commits touch
  only `docs/automated-tests/` and `docs/releasing.md`, so no code has changed since the measurement.
- **`lizard`.** The verbatim run (`lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .`) reports *No
  thresholds exceeded*: NLOC 30419, 4248 functions, average CCN 2.0, 0 warnings. That reproduces the
  bundle's `complexity.txt` footer exactly, so there is **no drift** and no anti-pattern #51.
- **Watch list.** `RESULTS.md:157-169` has 13 rows: 10 on notice and 3 over the cap. Their dispositions
  are graded in `LK-17d` and `LK-33`.
- **Tags without a release bundle, since the 2026-09-08 audit:** `v1.28.0`, `v1.29.0`, `v1.36.0`,
  `v1.36.1`, `v1.54.1`, `v1.54.2`. That is `LK-35`.
- **`manifest.json`'s `addonVersion`.** It reads `1.54.2` on the v1.55.0 release run. That is by design:
  a library's version comes from `git describe`'s newest tag (`testkit/run-automated-tests.sh:93`), and
  the tag is cut after the run. It is not filed.

### Versioning and git (`versioning-git`)

- The tags are semver, and both `v1.55.0` and `v1.54.2` are annotated (`git cat-file -t` returns `tag`).
- File minors are gated separately by `tests/test_versioning.lua`.
- Work on the current branch follows an explicit owner request, so it is not a trunk-based deviation.

### Line endings (`line-endings`)

- **Pin.** `.gitattributes` has **84 lines**, pin `* text=auto eol=crlf` (`:26`), `*.sh text eol=lf`
  (`:36`), `*.py text eol=lf` (`:37`) and 20 `binary` lines.
- **Body.** Its first 84 lines are **identical** to `line-endings-§5`'s client-bound canonical body, with
  an empty tail and no appendix.
- **Working tree.** Check (e) reports **0** files that disagree with the pin. The owning gate
  (`tests/_kit/test_eol.lua`, kit revision 25) is green.

### Localization (`localization-§5`)

- **Shipped payload.** `LibKa0s/` has one hit (`minimise`, register row 2) and `testkit/` has 11 (the
  `cancelled` identifiers, register row 1). Both are ratified.
- **Live authored text.** It carries **210 lines in 33 files** from the published `BRITISH` list. That is
  `LK-28`.

### Compat (`compat`)

- **Owners.** `LibKa0s-Compat-1.0` (`LibKa0s/Compat.lua`) and `LibKa0s/Env.lua` own the version-variant
  readers.
- **Deprecated-global sweep.** Outside those two files, the payload's only hit is `LibKa0s/Perf.lua:707-712`,
  which is register row 4 (accepted). `LibKa0s/OptionsWidgets.lua:398` calls the namespaced
  `C_Spell.GetSpellInfo` behind a presence guard, which is compliant.

### Events, frames and taint (`events-frames-taint`)

- **Raw registrations in the payload:**
  - `LibKa0s/OptionsTabs.lua:102-103` and `:139-140` register `PLAYER_REGEN_DISABLED` and
    `PLAYER_REGEN_ENABLED` on the combat-lock frame.
  - `LibKa0s/Widgets.lua:393` registers `GLOBAL_MOUSE_DOWN` on the popup menu.
- **What is missing.** None of these goes through a `pcall`ed helper, and none records a rejected name.
  That is `LK-37`, and this is the first audit of this repo to run the check.

### Architecture, bus and naming (`architecture-§4`, `naming-cheatsheet`)

- The payload sends and registers no `Ka0s_` message literal. The only hit is a test fixture
  (`tests/test_mock_record.lua:88`).
- `LibKa0s-Bus-1.0`'s `Catalog` is the library-owned declaration table.

### Documentation (`documentation-§4`, `§5`, `§7`) and the `library-stack-§7` substitutes

- **`CLAUDE.md`.** It carries `## Standards compliance (read first)` (`:41`), `## Documented deviations`
  (`:69`) with the nested census (`:89`), and `## Documentation map` (`:228`).
- **Documentation map.** It covers the **8** live `.md` files under `docs/` outside the frozen and
  generated stores, plus `docs/api/` as a directory. Every row resolves, and no live page is missing. The
  frozen stores (`audits/`, `reviews/`, `automated-tests/`, `adoption/`, `superpowers/`) are named once
  each at `:237-238`.
- **`README.md:3`.** It points at the standard and names **v2.64.0**, which matches the fetched version.
- **Root files.** `DEPENDENCIES.md` exists, `CHANGELOG.md` exists (required here), and there is no
  `TODO.md`.
- **Hand-written figures that no longer match the tree:**
  - `CLAUDE.md:268-269` says "eighty" files, where the measured count is 81.
  - `CLAUDE.md:203` gives `tests/test_schema.lua` as 1101 lines, where it is 1233.
  - `CLAUDE.md:180` cites `OptionsTabs.lua:39` for a guard that is at `:43-46`.

  That is `LK-29`.
- **Frozen bundles.** `docs/audits/{2026-08-05,2026-09-07,2026-09-08}` and `docs/reviews/2026-09-07`
  each have exactly one commit (their creation), so none has been edited since.

### Standalone windows, debug logging and public API

The library owns the window chrome (`Core.MakeCloseButton`, `SKIN`) and the console. Each major carries a
`docs/api/<Major>/version-N-docs.md` plus a generated `members-*.json`, and `tests/test_versioning.lua`
gates them. No deviation surfaced this run. The detailed contracts are the consumers' to audit where they
wire them.
