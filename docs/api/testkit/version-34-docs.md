# `testkit` — version 34

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **34** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.64.0 |
| Status | **Current** |
| Supersedes | [version 33](version-33-docs.md) — mock frames record the resize surface |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `34` |

Everything revision 33 describes is unchanged here except what follows. Three files change:
`test_diagnostics_contract.lua`, whose cases follow `debug-logging-§14` at the Ka0s WoW Addon
Standard v2.71.0; `framework.lua`, whose `Kit.VERSION` is 34 and which changes in nothing else; and
`README.md`, whose section on the contract says the same. No public member, mock or runner output
changes.

## What changed

### The diagnostics contract: a run turns logging on for the session

The owner's call of 2026-09-30: running the diagnostics report also turns debug logging on for the
session, before it writes, unless the addon's DebugLog descriptor opts out with
`diagnosticsEnablesLogging = false`. LibKa0s does it in `DebugLogDiagnostics.lua` minor 2
(`LibKa0s-DebugLog-1.0` 17.2), through the flag's one seam, `SetEnabled(true)`. Through revision 33
the contract pinned the opposite.

| Case | Through revision 33 | Revision 34 |
|---|---|---|
| `diagnostics contract: the report lands with logging off and leaves it off` | the report lands with the flag off, and the flag is still off | **retired** |
| `diagnostics contract: the report lands with logging off and turns it on for the session` | — | the report lands with the flag off; the flag is on afterwards; exactly one new `[Debug] logging enabled` line (in the instance's own wording, `D:Text("LOG_ENABLED")`), written before the report's begin marker. A declared skip when the addon opts out |
| `diagnostics contract: an addon that opts out lands the report and leaves logging off` | — | the report lands with the flag off, the flag is still off, and no enable line was written. A declared skip unless the addon opts out |
| `diagnostics contract: with logging already on, the report writes no second enable line` | — | with the flag on (written directly, no chat), the report lands, the flag is still on, and no enable line was added |

**One new optional fact, `Kit.diagnostics.enablesLogging`.** A boolean, set to `false` only by an
addon whose descriptor sets `diagnosticsEnablesLogging = false`. The kit cannot read the descriptor
(it is the addon's own table, and the instance does not hand it out), so the addon declares it; the
declaration is still tested, because the case for the declared choice fails when the live report
does the opposite. Any other type is refused with a message. Every other fact is unchanged.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Re-vendor with the LibKa0s this revision ships in (v1.64.0 final, `DebugLogDiagnostics` 2): against
an older `libs/LibKa0s/` the turn-on case fails, since the report there leaves the flag alone. A
consumer's `docs/test-cases.md` changes: one case name retired, three added, one of them a declared
skip. Regenerate it, and the README's test badge if the pass count moved. An addon suite of its own
that asserts the report leaves logging off re-pins in the same commit. A consumer's own prose that
names the revision it holds (`kit revision 33`) moves to 34.
