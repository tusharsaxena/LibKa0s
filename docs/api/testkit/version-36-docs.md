# `testkit` — version 36

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **36** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.68.1 |
| Status | Superseded |
| Supersedes | [version 35](version-35-docs.md) — the complexity suite measures a sighted shadow, with parity |
| Superseded by | [version 37](version-37-docs.md) — the mock answers Line regions |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `36` |

Everything revision 35 describes is unchanged here except what follows. No file is added. Three
files change: `run-automated-tests.sh` (one line it prints into `RESULTS.md`, and three comments),
`test_eol.lua` (one comment) and `framework.lua`, whose `Kit.VERSION` is 36 and which changes in
nothing else. No public member is added, removed or renamed, no kit case is added, removed or
renamed, no mock changes, and the manifest the runner writes is unchanged.

## What changed

### The kit names the dev-copilot plugin's commands

The `wow-addon` Claude Code plugin was merged into `dev-copilot` (v2.0.0, 2026-10-04), and its
commands were renamed: `/wow-addon:<x>` is `/dev-copilot:<x>` for the shared commands and
`/dev-copilot:wow-<x>` for the addon-only ones. The kit named three of them, and one path:

| File | Where | Was | Is |
|---|---|---|---|
| `run-automated-tests.sh` | the `RESULTS.md` lead-in it prints on every run | `/wow-addon:bump-version` | `/dev-copilot:bump-version` |
| `run-automated-tests.sh` | the dirty-tree refusal's comment, and the `gating` / `gates` comment | `/wow-addon:bump-version` | `/dev-copilot:bump-version` |
| `run-automated-tests.sh` | the eol pass's comment, naming the `Write`/`Edit` hook's script | `wow-addon/scripts/normalize-eol.sh` | `dev-copilot/scripts/normalize-eol.sh` |
| `test_eol.lua` | the header comment naming the agent that writes `ANALYSIS.md` | `/wow-addon:automated-tests` | `/dev-copilot:wow-automated-tests` |

**The one visible effect is in `RESULTS.md`.** Its runner-emitted lead-in names the command that
evaluates the release gate, so a consumer's next run rewrites that one line, and the file's diff shows
it once. No other output line changes: the console output, `manifest.json`'s fields, `tests.txt`,
`lint.txt` and `complexity.txt` are written exactly as revision 35 wrote them.

A revision rather than a silent edit because the kit's rule is that any released change to any file
in `testkit/` bumps `Kit.VERSION`: the files vendor as one folder, and byte-identity is the sync gate,
so a consumer holding revision 35's runner is holding a different kit. Superseded documents
([version 8](version-8-docs.md), [10](version-10-docs.md), [15](version-15-docs.md)) still name the
old commands, because they describe what those revisions shipped.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change and no kit case name changes, so a consumer's
`docs/test-cases.md` does not change. A consumer's own prose that names the revision it holds
(`kit revision 35`) moves to 36 in the same commit.

## Moving to 37

Copy the kit whole. A suite that counts frames is unaffected: a Line is not a frame and is not
tracked as one.
