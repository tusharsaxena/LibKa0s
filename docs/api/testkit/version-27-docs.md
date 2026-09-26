# `testkit` — version 27

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `test_layout_cap.lua`, **`test_diagnostics_contract.lua`**, `run-automated-tests.sh`, `README.md` |
| Version | **27** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.60.0 |
| Status | Superseded |
| Supersedes | [version 26](version-26-docs.md) — the two peels, the two assertions and the event fakes |
| Superseded by | [version 28](version-28-docs.md) — the suite inventory in `inventory.lua` |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `27` |

Everything revision 26 describes is unchanged here except what follows. One file is added,
`test_diagnostics_contract.lua`, the kit's fourth own suite. One file changes: `framework.lua`, whose
`Kit.VERSION` is 27 and whose `KIT_GATE_RULE` table gains the new suite's row. No member is added,
removed or renamed, and no mock changes.

## What changed

### A fourth kit suite: `test_diagnostics_contract.lua` (`debug-logging-§14`)

The Ka0s WoW Addon Standard v2.68.0 makes a diagnostics dump a MUST for every addon: exactly two
forms, `/<slash> diagnostics` and `/<slash> debug diagnostics`, write one report into the debug
console, and they work while the addon is disabled. LibKa0s v1.60.0 builds the report
(`LibKa0s-DebugLog-1.0` 14.1, `DebugLogDiagnostics.lua`); what is left in each addon is its
dispatcher, and this suite is that half of the rule, run against the addon's own dispatcher rather
than written eleven times.

Seven cases, each run through the consumer's dispatch function:

| Case | Proves |
|---|---|
| both forms run the report | `diagnostics` and `debug diagnostics` each write exactly one new report (one new begin marker) |
| the debug word is matched in any case | `debug DIAGNOSTICS` writes one |
| both markers carry the brand | the begin marker reads `[Diag] ==== <brand> diagnostics begin ====`, the buffer's last line is the end marker, and its `N line(s)` counts every line from the begin marker to the end, both included |
| the report appends | a line written before the report survives it, and the report follows it |
| the report lands with logging off | a report is written with the debug flag off, and the flag is still off after it |
| both forms run while disabled | with the addon stood down, both forms still write one report each |
| no other name runs the report | `debug diag`, `diag`, `debug dx`, `dx`, and `debug <word>` and `<word>` for every name in `retired`, write no report |

The append, ungated and while-disabled cases carry `testing-§12` falsification comments. A report is
counted by its begin marker in the console's `buffer`, so the suite needs nothing from the addon
beyond the five facts below.

### Wiring: `Kit.diagnostics`

The consumer's facts arrive on the kit table before `Kit.run`, as `Kit.layoutCap`'s do:

```lua
Kit.diagnostics = {
  brand       = "Ka0s Aura Master",               -- the DebugLog descriptor's brandName
  dispatch    = function(line) ... end,            -- run "/<slash> <line>" through the addon's
                                                   -- own slash handler
  console     = function() return NS.DebugLog end, -- the live DebugLog instance
  setDebug    = function(on) ... end,              -- write the debug flag directly, no chat
  setDisabled = function(off) ... end,             -- stand the addon down (true) or up (false)
  retired     = { "dump" },                        -- optional: this addon's own retired names
  reset       = function() ... end,                -- optional: run before every case
}
Kit.run{ dir = "tests/", suites = { ..., { name = "test_diagnostics_contract",
  dir = "tests/_kit/" } } }
```

A missing or mistyped fact fails the case that reads it and names every missing key. Before every
case the suite calls `reset`, then `setDisabled(false)` and `setDebug(false)`, and a case that
stands the addon down stands it back up whatever happened.

**Until the addon has its report, the suite skips once, by name.** With `Kit.diagnostics` unset it
registers one declared skip, `diagnostics contract: debug-logging-§14`, whose reason says the
dispatcher is not wired yet and that every Ka0s addon owes the report. This is the one clean skip,
and it exists for the re-vendor: an addon takes kit revision 27 before it writes its report, the
suite inventory asks for the new suite to be declared, and the re-vendor commit has to stay green.
The skip is printed in every run and written into `docs/test-cases.md`, so an addon that never wires
it is visible, and the standard's audit check reads for it.

`framework.lua`'s `KIT_GATE_RULE` gains `test_diagnostics_contract = "debug-logging-§14"`, so a
decline row for this suite in `## Documented deviations` is matched on that rule as well as on the
kit's path. No Ka0s addon is expected to decline it; the row is there so a decline, if one is ever
ruled, is keyed like every other.

LibKa0s wires the suite against a fixture host, `tests/fixture_diagnostics.lua`: a DebugLog console
and a Slash dispatcher gated on an enabled flag, with a `debug` verb that routes through
`DebugVerb` and a `diagnostics` verb. The report is live there while disabled through Slash 16's
`LIVE_VERBS` alone.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

then, in the consuming `tests/run.lua`, add
`{ name = "test_diagnostics_contract", dir = "tests/_kit/" }` to the suites list. The inventory
fails the run until it is there. With nothing else, the suite skips once. Once the addon ships its
report, set `Kit.diagnostics` before `Kit.run` and the seven cases run. Regenerate
`docs/test-cases.md`: it gains the skip, or the seven cases.
