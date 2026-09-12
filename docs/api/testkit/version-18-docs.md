# `testkit` — version 18

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **18** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.33.0 |
| Status | Superseded |
| Supersedes | [version 17](version-17-docs.md) — the Ace surfaces six consumer harnesses migrate onto: AceAddon's object model and lifecycle, AceEvent on CallbackHandler's terms, a real AceTimer, AceConsole's chat commands |
| Superseded by | [version 19](version-19-docs.md) — the AceDB fake's `OnProfileReset` carries no key, as AceDB-3.0 fires it |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `18` |

Everything revision 17 describes is unchanged here except the one argument below. For the Ace
surfaces, the two deliberate divergences and what each migrated harness keeps locally, read
[version 17](version-17-docs.md).

## What changed at this version

**One argument.** The AceDB fake's `CopyProfile` fires `OnProfileCopied` with the **source**
profile's key as the callback's third argument, which is what AceDB-3.0 does:

```lua
-- AceDB-3.0.lua, DBObjectLib:CopyProfile
-- Callback: OnProfileCopied, database, sourceProfileKey
self.callbacks:Fire("OnProfileCopied", self, name)
```

Through revision 17 the fake's one `fire(event)` called every callback as `cb(event, db, current)`,
with the active profile as the third argument whatever the event. For a switch that is right,
because the active profile is the one switched to. For a copy it is wrong: a copy of `"Raid"` into
`"Default"` reached a handler as a copy of `"Default"`. Every consumer with a copy handler logs
`copied profile '<source>' → '<active>'`, and the four on the kit's AceDB (AbsorbTracker,
AuraMaster, PrettyChat, WhatGroup) pinned that line by calling the handler directly, because going
through `CopyProfile` could only produce `'Default' → 'Default'`. That is fidelity rule 5's failure: the convenient behavior modeled in
place of the real one.

| Event | Third argument at 17 | At 18 | AceDB-3.0 |
|---|---|---|---|
| `OnProfileChanged` (`SetProfile(name)`) | the active profile, which is `name` | `name`, unchanged | `name` |
| `OnProfileCopied` (`CopyProfile(name)`) | the active profile | **`name`, the source** | `name` |
| `OnProfileReset` (`ResetProfile()`) | the active profile | the active profile, unchanged | none |

`OnProfileReset` keeps the key it has always carried here, although AceDB-3.0 passes none. A
handler that reads a third argument on a reset would get `nil` in the client and a key under the
kit. No consumer's reset handler reads one today, and changing it is a revision of its own rather
than a rider on this one.

Two files change: `mock_base.lua`, and `framework.lua`, which changes only its revision number.
`README.md` gains a paragraph. `loader.lua`, `vendor_sync.lua`, `test_eol.lua` and
`run-automated-tests.sh` are untouched. `tests/test_mock_ace.lua` pins all three events: one copy
fires one callback, with the database second and the source third, and the copy lands in the
active profile with the source's values.

### Revision 18 is not the geometry flip

[Version 17](version-17-docs.md#revision-17-is-not-the-geometry-flip) left the flip, deleting
`self.__geomLive and` from `GetHeight` and `GetWidth`, at "the next revision that ships it alone, 18
at the earliest". **Revision 18 does not ship it.** A frame nobody armed still answers 0, and
`tests/test_mock_base.lua`'s first case still pins that. The plan is unchanged: the flip is its own
revision with its own adoption, because roughly 308 test files across ten repositories lean on
geometry answering zero. Only the number moves: **19 at the earliest**. The comment in
`mock_base.lua` says so as well.

## For consumers: nothing moves

**Measured.** The whole v1.33.0 payload, `testkit/` into `tests/_kit/` and `LibKa0s/` into
`libs/LibKa0s/`, went into scratch clones of all ten consumers. Each was measured against its own
suite at the same commit before the drop:

| Consumer | Commit | Kit 17, v1.32.0 | Kit 18, v1.33.0 |
|---|---|---|---|
| AbsorbTracker | `f26769c` | 585 / 0 failed / 2 skipped / 587 | 585 / 0 / 2 / 587 |
| AuraMaster | `c1fc62d` | 264 / 0 / 2 / 266 | 264 / 0 / 2 / 266 |
| BankLedger | `996bd9f` | 869 / 0 / 2 / 871 | 869 / 0 / 2 / 871 |
| ConsumableMaster | `3e5a381` | 850 / 0 / 2 / 852 | 850 / 0 / 2 / 852 |
| KickCD | `f16a392` | 927 / 0 / 2 / 929 | 927 / 0 / 2 / 929 |
| LootHistory | `ee2c8ec` | 736 / 0 / 2 / 738 | 736 / 0 / 2 / 738 |
| MultiMeters | `c5441f6` | 1819 / 0 / 2 / 1821 | 1819 / 0 / 2 / 1821 |
| PanelMaster | `a947e35` | 805 / 0 / 2 / 807 | 805 / 0 / 2 / 807 |
| PrettyChat | `a0fdd98` | 348 / 0 / 2 / 350 | 348 / 0 / 2 / 350 |
| WhatGroup | `03860d2` | 600 / 0 / 2 / 602 | 600 / 0 / 2 / 602 |

The two skips in every row are the vendored-payload pair cases, because the clones had no sibling
LibKa0s.

### Which tests go through the copy path

**Through the kit's `CopyProfile`**, and so now handed the source. None pins the source name, so
each passes with either key and none changes outcome:

| Test | What it asserts about the copy |
|---|---|
| AbsorbTracker `tests/test_slashcmds.lua:521`, *"/at profile copy pulls another profile's values into the current one"* | The copied value, the unchanged active profile and the chat line. No log key. |
| AbsorbTracker `tests/test_slashcmds.lua:647`, *"/at profile copy reaches the copy handler, one line"* | One line, and its prefix `[Set] copied profile '` (`:653`–`:654`). It reads `'Default' → 'Default'` at 17 and `'CopyFrom' → 'Default'` at 18. |
| AuraMaster `tests/test_bulklog.lua:126`, the reset-and-copy case | `^%[Set%] copied profile '.-' → 'Default'$` (`:148`). The `'.-'` matched `'Default'` at 17 and matches `'Raid'` at 18. |
| AuraMaster `tests/test_containermanager.lua:446`, *"a profile copy in combat keeps a reused id parked…"* | Parking and rebuild state (`keptIdStaysParked`, `:404`–`:435`). No key. |
| PrettyChat `tests/test_debuglog.lua:366`, *"a profile copy logs one [Set] copied line and nothing else"* | The prefix `[Set] copied profile '` and the suffix `' → 'Default'` (`:373`–`:374`). `'Default' → 'Default'` at 17, `'Alt' → 'Default'` at 18. |

Three of these, AbsorbTracker's `:647`, AuraMaster's `:126` and PrettyChat's `:366`, now exercise the
real source name without asserting it. Tightening each to the full line is the consumer's call.

**Not through the kit's `CopyProfile`**, so revision 18 cannot reach them:

- **ConsumableMaster** has its own AceDB (`tests/wow_mock.lua:359`–`:488`, written into
  `__libs["AceDB-3.0"]` at `:510`–`:512`), whose `CopyProfile` already fires with the source
  (`:473`–`:481`). `tests/test_bulklog.lua:289` and `:388` assert `'Alt' → 'Default'` through it.
- **MultiMeters** wraps the kit's AceDB (`tests/wow_mock.lua:1222`–`:1275`). The wrapper re-fires
  string-form handlers itself, with the source for a copy, and production registers its copy
  handler in string form, so the kit's `fire` never reaches it. `tests/test_database.lua:213`
  asserts `'Default' → 'Raid'` through the wrapper.
- **KickCD** (`tests/wow_mock.lua:502`–`:570`, `CopyProfile` a no-op), **PanelMaster**
  (`:415`–`:464`, no `CopyProfile`; `test_debuglog.lua:497` fires the event by hand) and
  **BankLedger** (`:598`–`:606`, no callbacks at all) replace the fake.
- **LootHistory** has no copy handler. **WhatGroup** uses the kit's AceDB, but its one copy test
  (`tests/test_debuglog.lua:434`) calls the handler directly.

The tests that pin the source name all call the handler directly and are unaffected:
AbsorbTracker `tests/test_slashcmds.lua:637`, AuraMaster `tests/test_bulklog.lua:152`, KickCD
`tests/test_settings_log.lua:377`, PrettyChat `tests/test_debuglog.lua:381` and `:440`, and WhatGroup
`tests/test_debuglog.lua:434`.

### Comments that go stale

These describe the kit passing the active profile. They are no longer true at 18, and each is the
consumer's to correct at its re-vendor:

- AbsorbTracker `tests/test_slashcmds.lua:638`–`:639`
- AuraMaster `tests/test_bulklog.lua:149`–`:150`
- PrettyChat `tests/test_debuglog.lua:382`–`:384`
- WhatGroup `tests/test_debuglog.lua:436`–`:437`, and `core/WhatGroup.lua:198`–`:199` in production
  source
- ConsumableMaster `tests/wow_mock.lua:356` says the kit's AceDB has "no … profile key". That was
  loosely true before and is less true now.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

Nothing to switch on and nothing to delete: the total does not move. A consumer that wants to drive
its copy handler through `CopyProfile` rather than calling it directly can now do so.

## Vendoring

Whole-folder, from the library repo's root — the same cwd `docs/releasing.md` assumes:

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**Never edit `tests/_kit/` in a consumer.** A kit problem is a finding to fix here and re-vendor; a
local patch is a fork nobody knows about, and the next re-vendor silently reverts it.

LibKa0s is a consumer on the same terms as every addon: it reaches its own kit through `tests/_kit/`
rather than into `testkit/` directly, so `diff -r testkit tests/_kit` is the same gate here as it is
downstream, and a kit change that would break a consumer breaks this repo first.

## Bumping the revision

1. Change the kit, with its test.
2. Bump `Kit.VERSION` at the top of `testkit/framework.lua`.
3. Write `docs/api/testkit/version-<N>-docs.md`; mark this one `Superseded` and fill in its
   `Superseded by`. `tests/test_kitsync.lua` fails if the document for the live version is missing.
4. Re-vendor into `tests/_kit/` here **and** into every consumer's `tests/_kit/`, then run each
   repo's suite.
5. Add the row to [`../README.md`](../README.md).

## Moving to revision 19

One argument goes. The AceDB fake's `ResetProfile` now fires `OnProfileReset` with the database
alone, `(event, db)`, which is what AceDB-3.0 does. At this revision it passed the active profile as
a third argument, so a reset handler that read one passed here and got `nil` in the client.
`OnProfileChanged` and `OnProfileCopied` are unchanged. Nothing else in the kit moves, and it is
still not the geometry flip, which moves to 20 at the earliest. No production reset handler in the
collection reads the key. See [version 19](version-19-docs.md).
