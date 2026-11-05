# `testkit` — version 51

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 50 lists |
| Version | **51** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.89.0 |
| Status | **Current** |
| Supersedes | [version 50](version-50-docs.md) — the same surface, with an unregister that could disturb a dispatch in flight |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `51` |

Everything revision 50 describes is unchanged here except what follows.

## What changed

### `mock_ace.lua`: an unregister clears only a registration that exists

The CallbackHandler registry behind the AceEvent fake (`UnregisterEvent`, `UnregisterAllEvents`, `UnregisterMessage`, `UnregisterAllMessages`, and the library's own `AceEvent.UnregisterMessage` / `AceEvent.UnregisterAllMessages`) now clears a target's entry, in the live list and in the mid-dispatch queue, only when the target has one. That is CallbackHandler-1.0's own guard (`if callbacks[self] then ... end`).

Through revision 50 the fake assigned nil to the key whether or not it was there. In Lua 5.1 that inserts an absent key, and once the list's free nodes run out it rehashes. When a handler had just unregistered itself, the rehash dropped its dead key, and the dispatch's `next(list, key)` raised `invalid key to 'next'` or skipped a registrant. Whether it did depended on the hash order of the run, so a consumer saw it as a flake: Outfitter Reborn's `bar: a profile switch redraws the bar...` case failed about one run in six. `tests/test_mock_ace.lua`'s *unregistering targets that hold no registration leaves a send in flight intact* pins it for both paths.

No member is added, renamed or removed, and no case name changes.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`. Nothing else: no declaration, suite or call changes. A consumer case that failed intermittently with `invalid key to 'next'` out of `mock_ace.lua`'s `fire`, or that missed a handler after an `UnregisterAll*` in a handler, should now pass every run.
