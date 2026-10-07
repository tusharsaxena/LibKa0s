# 01 — Current state

**Repo:** `LibKa0s`, branch `feat/2026-10-07-review-audit-remediation`, HEAD `353f286` (clean tree at
audit start), newest tag `v1.70.0`.
**Standard audited against:** Ka0s WoW Addon Standard **v2.76.1 (2026-10-07)**, fetched verbatim with
`curl -fsSL` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`: `AUDIT.md`,
`standards/STANDARDS.md`, `standards/ADDONS.md` and all 27 section files the Sections list links.
**Run date:** 2026-10-07. **Prefix:** `LK-` (stable since 2026-08-05; the 2026-09-23 run ended at
`LK-38`, so new IDs here start at `LK-39`).

## Kind and rule set

- `dev-copilot-profile` reported `profile=wow`, `kind=library`, `reason=name:LibKa0s`.
- `standards/ADDONS.md` lists `LibKa0s` as a Ka0s-owned library repo, so the table agrees with the detector.
- The `AUDIT.md` discriminator gives the same answer: there is no `.toc`, and the repo ships a client-bound
  Lua payload (`LibKa0s/`) that eleven addons vendor into `libs/`.
- **Rule set:** `library-stack-§7`'s three applicability lists (*Applies, unchanged*; *Does not apply*;
  *Applies, read for a library repo*) plus its *Substitutes* list.
- Sections on the *Does not apply* list produce no entries. That list is `documentation-§1`/`§2`/`§3`
  (including the tier model), `toc-file`, `options-ui`, `slash-commands`, `preview-mode`, `launcher`,
  `savedvariables` and `packaging`.
- The addon-only playbook checks also do not run here. These include the disabled-state census, the
  diagnostics dump, the launcher, the settings-panel content checks, the re-vendor bundle check, the
  `diff -r` vendored-payload check (there is no `libs/` here) and the provenance line.
- **Unclassified subsections.** `library-stack-§7` says its lists are exhaustive, but a few subsections
  appear in none of them: `localization-§1`–`§4`, `testing-§2`–`§8` and `§12`–`§15`, and
  `documentation-§8`/`§9`.
  - Under the section's own default these **apply unchanged**, and they were read on that basis.
  - None produces a finding here. `documentation-§9` covers authored Lua under the addon source folders
    (`core/`, `modules/` and so on), and the library has none of those. `documentation-§8` covers
    documentation-and-tooling repos.
  - The gap belongs to the standard and is recorded as upstream observation U3 in `02_DEVIATIONS.md`.

## Snapshot, section by section

### Layout (`layout`, read for a library repo)
- **Shape.** The payload folder is `LibKa0s/`: 34 `.lua` files, `LibKa0s.xml` and `media/`. Beside it
  sit `tests/`, `testkit/` (the vendored copy is in `tests/_kit/`), `docs/`, `tools/` and `media/logos/`.
- **The cap.** The default census scope is `git ls-files '*.lua'` minus `libs/` and `tests/_kit/`, which
  is 153 files. **No file is over 1500 lines.** Six files are in the 1000–1500 band:
  - `testkit/mock_base.lua` 1458
  - `LibKa0s/OptionsWidgets.lua` 1444
  - `LibKa0s/OptionsIds.lua` 1359
  - `LibKa0s/OptionsTabs.lua` 1349
  - `LibKa0s/Options.lua` 1288
  - `LibKa0s/OptionsIdList.lua` 1246
- **The census.** `CLAUDE.md:94` `### Files over the 1500-line cap` sits under `## Documented deviations`
  (`:69`), as required. `CLAUDE.md:125` reads *"Nothing is over the cap today"*.
- **The gate.** `tests/_kit/test_layout_cap.lua` is wired at `tests/run.lua:104`.
- **Generators.** `tools/artwork/bar_textures.py`, `tools/artwork/icon_cleaner.py` and
  `tools/gen-api-members.lua` all sit under `tools/` and outside the payload. `DEPENDENCIES.md:99-101`
  names Python 3, Pillow and NumPy.
- **Media.** `LibKa0s/media/{fonts,icons,textures}` are typed subfolders, holding 113 icon TGAs and
  7 textures. The repo's own media is `media/logos/`.

### Library stack (`library-stack`)
- **Inventory.** 15 majors across 34 files: `tests/majors.lua` lists 15 majors whose file lists sum to
  34, and `LibKa0s/LibKa0s.xml` has 34 `<Script file=` lines. The per-major split is Options 10,
  Widgets 5, Perf 4, DebugLog 3, Slash 2 and the other ten 1 each. That matches `library-stack-§7`
  at v2.76.1 and the README module table.
- **Per-file minors** are published on `lib.MODULES`. `tests/test_versioning.lua` couples the minors to
  `CHANGELOG.md` and to `docs/api/` (green).
- **`library-stack-§9`.** There is exactly one sentinel-guarded `LSM30_Border` re-registration
  (`LibKa0s/Options.lua:312-314`).
- **Promotion bars.** `WidgetsLineChart.lua` was promoted with one consumer. Register row 6 records it
  as accepted (owner, 2026-10-07).
- **Consumers.** All 11 sibling addons name `v1.70.0` in their root `CLAUDE.md` provenance line, and
  only LootHistory draws a `LineChart`.

### Architecture, events, compat (bind inside the payload)
- **Events.** The payload has three raw `RegisterEvent` sites on private widget frames:
  - `LibKa0s/OptionsCombat.lua:90-91` and `:127-128`
  - `LibKa0s/OptionsRegistry.lua:92`
  - `LibKa0s/Widgets.lua:392`

  They are covered by register row 5, whose trigger ("a fourth private registration site") has not
  fired. The pcall'd helper family lives in `LibKa0s/Core.lua:478-497`.
- **Compat.** `LibKa0s-Compat-1.0` (`LibKa0s/Compat.lua`) owns the spell and spec ladders, and Perf's
  inline spec read is register row 4. Two inline addon-API ladders keep a deprecated global as their
  last rung:
  - `LibKa0s/Env.lua:61-66` (`GetAddOnMetadata`)
  - `LibKa0s/OptionsIdList.lua:485` (`IsAddOnLoaded`)

  The first is the dead rung the compat section uses as its own worked example. Both are filed as `LK-39`.
- **Bus.** There is no `Ka0s_` message literal in the payload.

### Lint (`lint`)
- `.luacheckrc` has `exclude_files = { "tests/_kit/" }` (`:4`). The harness global `LK_TEST` is in
  `files["tests/"]`, not in top-level `read_globals`.
- `ignore = { "212/self", "212/event", "432/self" }` is narrow and commented. It suppresses **152**
  warnings (measured; see `03_EVIDENCE.md` §E3).
- `luacheck .` reports **0 warnings / 0 errors in 153 files**.

### Testing (`testing-§1`, `§9`, `§10`, `§11`)
- `lua tests/run.lua`: **2087 passed, 0 failed, 2 skipped, 2089 total**. Both skips are declared:
  - the kit prose gate, declined by register row 3;
  - the diagnostics opt-out case, which does not apply because this repo keeps the default.
- Kit gates wired in `tests/run.lua:103-106`: `test_eol`, `test_layout_cap` and `test_lizard_sighted`.
- The repo's own `test_versioning`, `test_kitsync` and `test_prose` are at `tests/run.lua:94`.
- `diff -r testkit tests/_kit` is empty. Kit revision 37 (`testkit/framework.lua:20`).
- `docs/test-cases.md` is byte-identical (CR stripped) to a fresh `lua tests/run.lua --list`.

### Automated tests (`automated-tests`) and complexity (`performance-§10`)
- **Runner.** It is executable (`100755`) in both `testkit/` and `tests/_kit/`.
  `docs/automated-tests/README.md` and `RESULTS.md` both exist, and there is no retired
  `docs/complexity.md`.
- **Release bundles.** Every tag from v1.55.0 to v1.70.0 has a bundle whose `manifest.json` `release`
  names it, and every release bundle from v1.56.0 on carries `ANALYSIS.md`.
- **Release-gate sentence.** Every `CHANGELOG.md` entry from v1.56.0 to v1.70.0 states the perf skip.
- **Complexity.** The sighted complexity suite (run as written, `--no-bundle`) reports 0 warnings, max
  CCN 15, 42163 NLOC and 6382 functions, the same figures as the newest bundle `20261007-102304`. That
  bundle measured `6b401e1`. It is 6 commits behind HEAD, and those 6 commits change no `.lua` file.
  `blindFiles` is 0.
- **Watch list.** It has six band entries:
  - five dispositioned *Accepted*, each carried across 7 to 10 consecutive release runs (`LK-17d`);
  - one *On notice* (`testkit/mock_base.lua`), whose authored figure is stale (`LK-29`).

### Line endings (`line-endings`)
- `.gitattributes` is present at 84 lines. The pin is `* text=auto eol=crlf` (`:26`), which is correct
  for a client-bound library.
- `*.sh` and `*.py` are pinned `text eol=lf` (`:36-37`), and 23 binary types are marked.
- **The body is byte-identical to the canonical client-bound body** (`line-endings-§5`), with no tail.
- Check (e) finds **0** files that disagree with the pin. The kit gate `test_eol` is wired and green.

### Localization (`localization-§5`)
- The repo's own `tests/test_prose.lua` is green. Three register rows (1–3) record the exemptions.
- An independent sweep with the kit's published lists, over the live authored set described in
  `03_EVIDENCE.md` §E7, finds **22 unratified lines in two live docs**: `docs/adoption-prompt.md` (18)
  and `docs/adoption-report.md` (4). This is `LK-28`.

### Documentation (`documentation-§4`–`§7`, and the *Substitutes*)
- Root `CLAUDE.md` carries `## Standards compliance (read first)` (`:41`), the register (`:69`), the
  census (`:94`), `## Documentation map` (`:418`) and the green gate (`:450`).
- `DEPENDENCIES.md` is present.
- `README.md:3` points at the standard and names **v2.76.0**. v2.76.1 was published later the same day,
  after v1.70.0's release step 7 had checked the pointer. That is an observation, not a finding.
- `CHANGELOG.md` is present, as the library repo requires.
- There is no `TODO.md`, and no retired `complexity.md`, `file-index.md`, `conventions.md`, `perf-runs/`
  or `LEDGER.md`.
- **Documentation map.** The 13 rows all resolve. Every `.md` under `docs/` outside the five named
  frozen and generated directories has a row, or sits under the `docs/api/` directory row.
- **Citations.** The live, non-frozen tracked set has 383 files. It contains 3353 `filename-§N`
  citations, **0 out of range** against the fetched section heading counts, and 0 retired dotted `§N.M`
  references in the payloads.
  - There is one raw `file:line` citation into the standard, at `LibKa0s/Slash.lua:267`. It is tracked
    as open issue #43 and filed here as `LK-41`.

### Audit and review history, and the register (`audit-review-history`)
- Every bundle under `docs/audits/` (four) and `docs/reviews/` (four, before today) has exactly one
  commit, so all are frozen. No `docs/automated-tests/<stamp>/` bundle has a second commit.
- **Register.** There are six rows (`CLAUDE.md:73-78`). No row's trigger has fired. No row's cited rule
  has changed in a way that would end it: `events-frames-taint-§1` still requires the pcall'd helper, and
  its two carve-outs do not cover widget frames.
- **Evidence ids.** Rows 3 and 5 (and the band prose at `CLAUDE.md:335`) cite `LibKa0s-A-07`,
  `LibKa0s-A-10` and `LibKa0s-A-03` as "the 2026-09-23 audit's" ids. That bundle uses `LK-*` ids. The
  same rows also cite the cross-repo plan items `LK-29` and `LK-30`, which collide with this repo's own
  audit ids. This is `LK-42`.
- **Issue store.** There are 44 issues: 5 open and 39 closed. Every issue carries one `state:` label and
  one `severity:` label. Four **closed** issues (#32, #33, #37, #39) carry `state:triaged`, which is an
  open-only label (`LK-40`).
  - The seven `state:will-not-do` issues (#10, #21–#26) record plan-scope or API-design declines, not
    departures from a binding MUST or SHOULD, so none owes a register row. #22's subject (the
    `minimise` key) has register row 2 anyway.

### Versioning (`versioning-git`)
- Tags are annotated (`git cat-file -t v1.70.0` returns `tag`). The semver tag axis is kept separate
  from the per-file minors.

## Prior run (2026-09-23) carried forward

| Prior ID | State now |
|---|---|
| `LK-17d` | **Recurs**: the shelf-life shape is unchanged, and five *Accepted* cells now span 7 to 10 release runs |
| `LK-19` | Closed: every release bundle from v1.56.0 on has `ANALYSIS.md`, and `docs/releasing.md:135-136` and `:180` now require it |
| `LK-28` | **Recurs, narrowed**: the 210-line sweep landed (register row 3), but two live docs it never counted carry 22 lines |
| `LK-29` | **Recurs, different figure**: the three 2026-09-23 figures are fixed, and a new stale figure is at `CLAUDE.md:219` and `RESULTS.md:193` |
| `LK-30` | Closed: the watch list's warned-functions table prints its header row (`RESULTS.md:179-180`) |
| `LK-32` | Closed: `20260924-040553/ANALYSIS.md:140` states the correction |
| `LK-33`, `LK-34` | Closed: nothing is over the cap, and the census and watch list agree |
| `LK-35` | Closed: every tag from v1.55.0 on has a release bundle, and the six earlier gaps are named at `20260924-040553/ANALYSIS.md:126` |
| `LK-36` | Closed: every entry from v1.56.0 to v1.70.0 states the perf skip |
| `LK-37` | **Recorded**: register row 5 (`CLAUDE.md:77`) |
| `LK-38` | Closed: row 1 now cites commit `1f1790c` and `docs/api/testkit/version-17-docs.md`, and both resolve |
