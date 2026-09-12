# `testkit` — version 19

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **19** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.34.0 |
| Status | **Current** |
| Supersedes | [version 18](version-18-docs.md) — the AceDB fake's `OnProfileCopied` carries the source profile's key, as AceDB-3.0 fires it |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `19` |

Everything revision 18 describes is unchanged here except the one argument below. For the Ace
surfaces, the two deliberate divergences and what each migrated harness keeps locally, read
[version 17](version-17-docs.md); for the copy key, [version 18](version-18-docs.md).

## What changed at this version

**One argument, removed.** The AceDB fake's `ResetProfile` fires `OnProfileReset` with the database
alone, which is what AceDB-3.0 does:

```lua
-- AceDB-3.0.lua, DBObjectLib:ResetProfile
-- Callback: OnProfileReset, database
self.callbacks:Fire("OnProfileReset", self)
```

Through revision 18 the fake called every reset callback as `cb(event, db, <active profile>)`. A
handler that read that third argument passed under the kit and got `nil` in the client. Revision 18
recorded this and left it for its own revision; this is that revision. The fake's `fire` is now a
vararg, so a keyless event hands the callback **exactly two** arguments, `(event, db)`, the way
CallbackHandler does. A handler that counts its arguments sees what the client hands it.

| Event | Third argument at 18 | At 19 | AceDB-3.0 |
|---|---|---|---|
| `OnProfileChanged` (`SetProfile(name)`) | `name` | `name`, unchanged | `name` |
| `OnProfileCopied` (`CopyProfile(name)`) | `name`, the source | `name`, unchanged | `name` |
| `OnProfileReset` (`ResetProfile()`) | the active profile | **none** | none |

A reset handler that needs the profile's name asks the database: `db:GetCurrentProfile()`. That is
also what every production reset handler in the collection already does (see below).

Two files change: `mock_base.lua`, and `framework.lua`, which changes only its revision number.
`README.md` gains a paragraph. `loader.lua`, `vendor_sync.lua`, `test_eol.lua` and
`run-automated-tests.sh` are untouched. `tests/test_mock_ace.lua` pins it twice: the three-event
case now expects no key on the reset, and a new case counts the reset callback's arguments (two),
checks the database is the second, and checks the active profile is back at its defaults.

### Revision 19 is not the geometry flip

[Version 18](version-18-docs.md#revision-18-is-not-the-geometry-flip) left the flip, deleting
`self.__geomLive and` from `GetHeight` and `GetWidth`, at "19 at the earliest". **Revision 19 does
not ship it.** A frame nobody armed still answers 0, and `tests/test_mock_base.lua`'s first case
still pins that. The flip is still its own revision with its own adoption, because roughly 308 test
files across ten repositories lean on geometry answering zero. Only the number moves: **20 at the
earliest**. The comment in `mock_base.lua` says so as well.

## For consumers: nothing moves

**Measured.** The whole v1.34.0 payload, `testkit/` into `tests/_kit/` and `LibKa0s/` into
`libs/LibKa0s/`, went into scratch clones of all ten consumers, each at the branch it had checked out
on 2026-09-13. Every one of those branches already carried v1.33.0 and kit revision 18. Each clone
was measured against its own suite before and after the drop:

| Consumer | Branch | Commit | Before (v1.33.0, kit 18) | After (v1.34.0, kit 19) |
|---|---|---|---|---|
| AbsorbTracker | `chore/2026-09-12-libka0s-1.33.0` | `8dbda30` | 586 / 0 failed / 2 skipped / 588 | 586 / 0 / 2 / 588 |
| AuraMaster | `test/2026-09-12-coverage` | `e15aa9c` | 667 / 0 failed / 2 skipped / 669 | 667 / 0 / 2 / 669 |
| BankLedger | `chore/2026-09-12-libka0s-1.33.0` | `e6bd2a8` | 869 / 0 failed / 2 skipped / 871 | 869 / 0 / 2 / 871 |
| ConsumableMaster | `feat/2026-09-12-profiles-buttons` | `5cebe6a` | 870 / 0 failed / 2 skipped / 872 | 870 / 0 / 2 / 872 |
| KickCD | `chore/2026-09-12-libka0s-1.33.0` | `cae55d2` | 929 / 0 failed / 2 skipped / 931 | 929 / 0 / 2 / 931 |
| LootHistory | `chore/2026-09-12-libka0s-1.33.0` | `af81ba6` | 736 / 0 failed / 2 skipped / 738 | 736 / 0 / 2 / 738 |
| MultiMeters | `chore/2026-09-12-libka0s-1.33.0` | `e66fa0c` | 1821 / 0 failed / 2 skipped / 1823 | 1821 / 0 / 2 / 1823 |
| PanelMaster | `chore/2026-09-12-libka0s-1.33.0` | `0f487c7` | 805 / 0 failed / 2 skipped / 807 | 805 / 0 / 2 / 807 |
| PrettyChat | `chore/2026-09-12-libka0s-1.33.0` | `43f5afb` | 348 / 0 failed / 2 skipped / 350 | 348 / 0 / 2 / 350 |
| WhatGroup | `chore/2026-09-12-libka0s-1.33.0` | `0fb1ef9` | 606 / 0 failed / 2 skipped / 608 | 606 / 0 / 2 / 608 |

The two skips in every row are the vendored-payload pair cases, because the clones had no sibling
LibKa0s.

### Production reset handlers: none reads the key

Every consumer that registers `OnProfileReset` gets the profile's name from the database, so none of
them has the bug revision 18 described, and none changes behavior with the kit:

| Consumer | Handler | Where the name comes from |
|---|---|---|
| AbsorbTracker | `core/AbsorbTracker.lua:283`, no parameters | `NS.db:GetCurrentProfile()` (`:244`–`:246`) |
| AuraMaster | `core/Database.lua:233` drops every argument into `core/AuraMaster.lua:150` | `GetCurrentProfile` (`:122`–`:124`) |
| ConsumableMaster | one closure for all three events, `core/ConsumableMaster.lua:434`–`:468` | `d:GetCurrentProfile()` for the reset line (`:438`–`:440`); `key` is read for a copy only (`:442`) |
| KickCD | `core/Database.lua:786`, shared by all three events | reads its third argument only when the event is neither a copy nor a reset (`:793`); a reset takes `db.keys.profile` (`:791`) |
| MultiMeters | `core/Database.lua:899`, `(_, db)` | `GetCurrentProfile` (`:867`–`:870`) |
| PanelMaster | `core/Database.lua:102`, no parameters | `GetCurrentProfile` (`:90`–`:92`) |
| PrettyChat | `core/PrettyChat.lua:120`, no parameters | `GetCurrentProfile` (`:90`–`:93`) |
| WhatGroup | `core/WhatGroup.lua:244`–`:256`, no parameters | `self.db:GetCurrentProfile()` (`:246`) |

BankLedger and LootHistory register no reset handler. Line numbers are from each consumer's
checked-out branch on 2026-09-13.

### Which tests go through the reset path

**Through the kit's `ResetProfile`**, and so now handed no key. None asserts on the key: every
reset-log assertion builds the profile name from `GetCurrentProfile()` or hard-codes the active
profile. The closest:

- AbsorbTracker `tests/test_helpers.lua:381`–`:446` and `tests/test_slashcmds.lua:603`–`:635`, whose
  expected line is built from `NS.db:GetCurrentProfile()` (`test_helpers.lua:371`,
  `test_slashcmds.lua:594`).
- AuraMaster `tests/test_bulklog.lua:99`–`:143`, against `RESET_LINE`, hard-coded to `'Default'`
  (`:33`).
- PrettyChat `tests/test_debuglog.lua:345`–`:364` and `:406`–`:438`.
- WhatGroup `tests/test_debuglog.lua:226`–`:267`, `:401`–`:432`.

**Not through the kit's `ResetProfile`**, so revision 19 cannot reach them:

- **ConsumableMaster** (`tests/wow_mock.lua:440`–`:458`, installed at `:521`) and **KickCD**
  (`tests/wow_mock.lua:545`–`:566`) replace the fake, and both still fire `OnProfileReset` with the
  active profile as a third argument, which AceDB-3.0 does not. KickCD's comment at `:562`–`:564`
  says so. Neither production handler reads it, so it is harmless today; aligning each is the
  consumer's call.
- **MultiMeters** wraps the kit's AceDB (`tests/wow_mock.lua:1223`–`:1278`). String-form handlers
  are re-fired by the wrapper, already with no key on a reset; only function-form callbacks reach
  the kit's `fire`, and production registers none.
- **PanelMaster** (`tests/wow_mock.lua:435`–`:454`) fires through its own `__fire` with a
  non-AceDB shape, `(target, db, profileName)`; its handler takes no arguments.
- **BankLedger** (`tests/wow_mock.lua:598`–`:606`) has no `ResetProfile` and no callbacks.
- AbsorbTracker `tests/test_optionssetup.lua:141` and MultiMeters `tests/test_database.lua:307`,
  `:323` call the handler directly, already with `(event, db)` alone.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

Nothing to switch on and nothing to delete: the total does not move. A consumer whose own AceDB fake
still passes a key on a reset can drop it to match, on its own schedule.

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
