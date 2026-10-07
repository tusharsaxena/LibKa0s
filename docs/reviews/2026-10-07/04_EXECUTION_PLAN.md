# 04 — Execution plan (LibKa0s, 2026-10-07)

Everything here lands in LibKa0s as one release, **v1.71.0**, followed by its re-vendor. There is no upstream milestone, because LibKa0s is the upstream. Branch: `feat/2026-10-07-review-audit-remediation` (already checked out). Gate after every task: `lua tests/run.lua` (0 failed) and `luacheck .` (0/0), both through `ka0s-bounded`.

## M1 — Library code fixes

**Done when** C-01 to C-04 are implemented with their new cases green and the gate is clean.

| Task | Role | Implements | Files |
|---|---|---|---|
| T1 | lua-refactorer | C-01 (F-001), C-02 (F-003) | `LibKa0s/WidgetsLineChart.lua`, `tests/test_widgets_linechart.lua`, `tests/test_widgets_linechart_math.lua` |
| T2 | test-author, then lua-refactorer | C-03 (F-002, F-005, F-007, F-008, F-009) | `LibKa0s/WidgetsAutocomplete.lua`, `tests/test_widgets_autocomplete.lua`, and `testkit/mock_base.lua` (plus the mirrored `tests/_kit/` copy and a `tests/test_mock_*.lua` case) **only if** the mock does not drop hooks on `SetScript` |
| T3 | lua-refactorer | C-04 (F-006) | `LibKa0s/SlashParse.lua`, `tests/test_slash_parse.lua` |

**Concurrency:** T1, T2 and T3 touch disjoint files and can run **in parallel**. Exception: if T2 needs the kit fix, it also touches `testkit/`, and the kit revision bump has to be serialized with M3's version-bearing files.

**Checkpoint CP1:** before M2, the coordinator reads the three diffs. In particular, confirm that each new negative case went red under its named mutation.

## M2 — Test records

**Done when** every negative case in the three suites carries a `-- red under:` note backed by a mutation that was actually run.

| Task | Role | Implements | Files |
|---|---|---|---|
| T4 | test-author | C-06 (F-011) | the three suites from T1 and T2 |

**Serialize after T1 and T2**, because it touches the same suite files.

## M3 — Release v1.71.0

**Done when** the version-bearing lines agree, `tests/test_versioning.lua` is green and the release record has been taken.

| Task | Role | Implements | Files |
|---|---|---|---|
| T5 | release-scribe | release steps 2–7 (`docs/releasing.md`), including C-05 | `CHANGELOG.md`, `docs/api/Widgets/version-12.1.4.3.2-docs.md` (+ members JSON via `lua tools/gen-api-members.lua`), `docs/api/Slash/version-19.2-docs.md` (+ JSON), `docs/test-cases.md` (regenerated), `README.md`/`docs/releasing.md` version lines, `testkit/framework.lua` `Kit.VERSION` if T2 needed the kit |
| T6 | release-scribe | release record | `docs/automated-tests/<stamp>/` via `/dev-copilot:bump-version` |

**Serialize** T5 after M2, and T6 after T5.

**Checkpoint CP2 (owner):** review the release diff. The tag is **not** pushed without the owner's go-ahead (collection `CLAUDE.md`).

## M4 — Re-vendor and consumer smoke

**Done when** all 11 consumers carry v1.71.0 byte-identical, each consumer's gate is green, and the owner has run `03_SMOKE_TESTS.md`.

| Task | Role | Implements | Files |
|---|---|---|---|
| T7 | re-vendorer | release step 8 | each consumer's `libs/LibKa0s/` and `tests/_kit/`, and its provenance line, through `/dev-copilot:wow-revendor-libka0s` |
| T8 | release-scribe | release step 9 | `docs/api/CONSUMERS.md` sweep |

**Parallel:** T7 per consumer, through the bounded runner's slot pool. T8 runs after T7.

**Checkpoint CP3 (owner):** in-client smoke (`03_SMOKE_TESTS.md`) and its sign-off table.

## Not executed: follow-ups that belong to other repos

- **F-010 consumer side:** LootHistory passes a localized `formatX`. This belongs in LootHistory's own task list, and only if C-05's observation confirms English labels.
- **F-004:** measure double render in LootHistory first (count `Render` calls per `TL:Layout` headless), then decide.

## Commit strategy

One commit per task, subject prefixed with the finding ids:
- `F-001 + F-003: LineChart minor 3 - clip segments to the plot, re-arm hover on SetData`
- `F-002 + F-005 + F-007 + F-008 + F-009: Autocomplete minor 2 - re-hookable, protected callbacks`
- `F-006: SlashParse minor 2 - refuse non-finite numbers`
- `F-011: red-under notes on the v1.69/v1.70 widget suites`
- `release: v1.71.0` (T5), then the release-record commit (T6)
- the re-vendor commits in each consumer

Every message ends with the session's attribution trailers.
