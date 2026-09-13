# `testkit` — version 20

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **20** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.35.0 |
| Status | **Current** |
| Supersedes | [version 19](version-19-docs.md) — the AceDB fake's `OnProfileReset` carries no profile key, as AceDB-3.0 fires it |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `20` |

Everything revision 19 describes is unchanged here except the two additions below. For the Ace
surfaces, the two deliberate divergences and what each migrated harness keeps locally, read
[version 17](version-17-docs.md); for the profile-event keys, [version 18](version-18-docs.md) and
[version 19](version-19-docs.md).

## What changed at this version

Revision 20 ships with LibKa0s-Options-1.0's `O.ResolveId`, `O.IdInput` and `O.IdList` (v1.35.0).
Both additions exist so a suite can drive those widgets. **Neither changes what an existing suite
sees.**

### A new file, `mock_ids.lua`: opt-in id lookups

The widgets turn a typed name into an id through the client (`C_Spell.GetSpellInfo(name)`,
`C_Item.GetItemInfoInstant(name)`), and an id into a name and an icon (`C_Spell.GetSpellInfo(id)`,
`C_Item.GetItemNameByID(id)`, `C_CurrencyInfo.GetCurrencyInfo(id)`). The base mock stubs none of
them. `mock_ids.lua` returns an installer, called on a finished mock:

```lua
local base = dofile("tests/_kit/mock_base.lua")

return function()
  local M = base()
  M.C_Item = { RequestLoadItemDataByID = function(id) end }   -- the harness's own first
  dofile("tests/_kit/mock_ids.lua")(M)                         -- then the lookups it lacks
  return M
end
```

| Member | Contract |
|---|---|
| `M.addIdRecord(kind, id, name, icon, uncached, quality)` | Seeds one record. `kind` is `"spell"`, `"item"` or `"currency"`. `quality` is an item's `Enum.ItemQuality` number, and optional. |
| `M.clearIdRecords()` | Empties every kind. The records live on the mock, so a harness that builds one mock per run must clear them between cases. |
| `M.__idRecords` | `{ spell = {}, item = {}, currency = {} }`, id-keyed. |
| `C_Spell.GetSpellInfo(idOrName)` | A SpellInfo table (`name`, `iconID`, `spellID`, …), or nil. |
| `C_Item.GetItemInfoInstant(idOrNameOrLink)` | `id, "Miscellaneous", "Junk", "", icon, 15, 0`, or nil. |
| `C_Item.GetItemNameByID(id)` | The name, or nil while the item is uncached. |
| `C_Item.GetItemQualityByID(idOrLink)` | The record's `quality`, or nil while the item is uncached or when it was seeded with none. `O.IdList` colors an item's name with it. |
| `C_CurrencyInfo.GetCurrencyInfo(id)` | A CurrencyInfo table (`name`, `iconFileID`, …), or nil. |

A name lookup ignores case, as the client's does, and answers the **lowest** matching id, so two
records that share a name resolve the same way on every run. An item added `uncached` is one the
client has not loaded. Its icon answers by id, because `GetItemInfoInstant` needs no cache. Its name
and quality do not answer, by id or by name, until the record is added again without the flag,
which is how a suite lands a load. The installer supplies no quality palette: a harness that wants
to see an item name colored also defines `ITEM_QUALITY_COLORS`, as the client does.

**Why it is opt-in, and why it is a file of its own:**

- **The base must not grow these namespaces.** ConsumableMaster (`tests/test_compat.lua:146`,
  `tests/test_bagscanner.lua:125`), WhatGroup (`tests/test_compat.lua:107`–`:143`) and MultiMeters
  (`tests/test_compat.lua:76`) reach their Compat fallbacks by clearing `C_Spell` or `C_Item`. The
  loader reads the mock before `_G`, so a base-level namespace would resolve ahead of a cleared one
  and make those branches unreachable. It is the same reason the base carries no `C_AddOns`.
- **The installer fills only what is missing.** BankLedger and LootHistory define their own
  `C_Item` (and LootHistory its own `C_CurrencyInfo`). Their functions are kept, and only the keys
  they lack join them. A harness whose own `GetItemInfoInstant` cannot answer a name keeps that
  limit until it adds one.
- **`mock_base.lua` sits at `layout-§1`'s cap.** It is 1487 lines at this revision. A surface a
  suite asks for is a file of its own rather than a breach of the cap.

### Three widget methods on the AceGUI fake

| Method | Records | Why |
|---|---|---|
| `GetText()` | answers what `SetText` stored | AceGUI's EditBox answers what is typed; an Add button beside it reads the box. |
| `SetType(t)` | `w.checkType` | A CheckBox's `"radio"` look (`O.ChoiceGrid`). |
| `DisableButton(v)` | `w.buttonDisabled` | An EditBox asked to hide its own Okay button (`O.IdInput`). |

Library code guards `SetType` and `DisableButton` before calling them, so a host's own AceGUI fake
without them still draws. The fake now answers `GetText` where it used to answer nil, and no
production file in the collection branches on that absence. The only `.SetType` guards in the
consumers are on LuaCurve objects, not on AceGUI widgets.

Four files change: `framework.lua` (the revision number), `mock_base.lua` (the three methods),
`README.md` (a section), and the new `mock_ids.lua`. `loader.lua`, `vendor_sync.lua`, `test_eol.lua`
and `run-automated-tests.sh` are untouched. `tests/test_mock_base.lua` pins the lookups and the
three methods:
- absent until installed;
- only the missing keys are filled;
- a name in any case;
- the uncached item's two answers;
- an item's quality, by id and by link, and none while it is uncached;
- currencies and `clearIdRecords`;
- the three widget methods.

### Revision 20 is not the geometry flip

Revision 19 moved the flip, deleting `self.__geomLive and` from `GetHeight` and `GetWidth`, to "20
at the earliest". **Revision 20 does not ship it.** A frame nobody armed still answers 0. The flip is
still its own revision with its own adoption.
