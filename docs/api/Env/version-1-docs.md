# `LibKa0s-Env-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Env surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Env-1.0` |
| Files and minors | `Env.lua` minor **1** |
| Shipped in | v1.14.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Env-1.0").MODULES` → `{ Env = 1 }` |

## What this major is

**The handful of client facts every Ka0s addon reads, read one way.** Four functions over three
Blizzard surfaces: the TOC manifest, the player's map id, and the player's zone labels. No state, no
frames, no events, no addon framework.

`GetAddOnMetadata` alone was written **eleven times across nine addons** before this module. Six
copies sat in a `core/Compat.lua`, in four different spellings — two-space and four-space indent, the
parameter called `field` and called `key`, globals reached bare and through `_G.` — and the other
five were the same six-line ladder inlined at the call site, where no audit of the shim files would
have found them. Not one of the eleven behaved differently from any other.

That is the whole case for the module, and it is also its boundary. There is no addon-specific
behavior here to make configurable and no plausible future in which one host needs a different
answer, which is what separates this from the wider `Compat` extraction that was measured against
the evidence and rejected: a container reader is BankLedger's, a mail decoder is LootHistory's, and
this is nobody's.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called** — the gate is there so that a host holding a partial payload gets every module
absent rather than a working half, and "is LibKa0s here?" stays one question.

## Why the metadata calls take the addon's own name

Same reason `LibKa0s-Media-1.0`'s do: this library is **vendored**, so there is no one path to it and
a copy cannot know which addon folder it was copied into. Lua offers a file no way to ask — `...`
carries the addon name only for a file the TOC loads directly, and `LibKa0s.xml` is loaded from
inside `libs/`. The host has its own name verbatim as the first vararg of every file its TOC loads,
so it passes it:

```lua
local addonName, NS = ...
local Env = LibStub and LibStub("LibKa0s-Env-1.0", true)

NS.version = Env and Env.Version(addonName, NS.VERSION) or NS.VERSION
```

## Lib-level surface

Read straight off the LibStub table. Every function is stateless.

| Name | Since | Meaning |
|---|---|---|
| `GetAddOnMetadata(addonName, field)` | 1 | One field of an addon's TOC manifest, or `nil`. Reads `C_AddOns.GetAddOnMetadata` where it exists, the deprecated bare global where it does not, and answers `nil` where neither does. |
| `Version(addonName[, fallback])` | 1 | The addon's own version string. The TOC's `Version` when it can be read and is non-empty, otherwise `fallback` (which may be `nil`). |
| `GetPlayerMapID()` | 1 | The player's current UI map id via `C_Map.GetBestMapForUnit("player")`, or `nil`. |
| `GetZone()` | 1 | Two values: zone and subzone. **Always two strings** — `""`, never `nil`. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Env-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Env = <minor> }` — the live minor, and the value that picks this document. |

### `nil` from `GetAddOnMetadata` is a real answer

A field the TOC does not carry answers `nil` on a perfectly healthy client, so `nil` does not mean
"this client is degraded" and must not be treated as an error. A caller that needs a value supplies
its own.

### Why `Version` is a member rather than a call site's problem

Because the eleven call sites overwhelmingly want one thing — the addon's own version, for an About
page, a slash banner or a perf descriptor — and they spelled the fallback nine different ways getting
it: `or NS.version or "?"`, `or NS.VERSION`, `or ""`. A bare metadata passthrough would have
preserved every one of those spellings.

It prefers the **TOC** over the fallback, because the TOC is what the packager stamped and the
fallback is a constant somebody has to remember to edit; returning the constant in preference would
make a correctly packaged addon report a stale number. An empty-string TOC value counts as unreadable
and falls through.

The fallback stays **visible at the call site, as an argument**, because which constant a host falls
back to is genuinely its own business.

### `GetPlayerMapID` is best-effort by design

A map id is a stamp on a stored record, and a record with no map id is worth more than a raise during
a zone transition. There is no retry and no event wiring here; a host that needs a map id at a
precise moment already owns the event that tells it when that moment is.

### `GetZone` answers `""` and never `nil`, and that is load-bearing

Consumers bucket `""` with `nil` deliberately in storage and in their zone filters, and they wrote
that decision down. A library that "improved" this to `nil` would silently move stored rows between
buckets on the first re-render after an upgrade — a data-shaped defect with no error attached to it.

Both returns are strings on every path, including the one where neither `GetZoneText` nor
`GetSubZoneText` exists.

## Degraded clients

Every function is a two-rung ladder over an API Blizzard has already moved once, and the rung a live
client exercises is the top one — so the bottom rung is the half that ships untested unless a test
removes the API. `tests/test_env.lua` reaches each one by **removing the global from the mock
environment** rather than by stubbing the function under test, so the case is genuinely "this client
does not have that API".

| Missing | `GetAddOnMetadata` | `Version` | `GetPlayerMapID` | `GetZone` |
|---|---|---|---|---|
| nothing | the TOC value | the TOC value | the map id | zone, subzone |
| `C_AddOns` | the bare global's value | the bare global's value | — | — |
| `C_AddOns` and `GetAddOnMetadata` | `nil` | `fallback` | — | — |
| `C_Map` | — | — | `nil` | — |
| `GetZoneText` / `GetSubZoneText` | — | — | — | `""` for the missing one |

## Adopting it

```lua
local addonName, NS = ...

local Env = LibStub and LibStub("LibKa0s-Env-1.0", true)

NS.version = Env and Env.Version(addonName, NS.VERSION) or NS.VERSION

function NS:Where()
    if not Env then return nil, "", "" end
    local zone, subZone = Env.GetZone()
    return Env.GetPlayerMapID(), zone, subZone
end
```

**A host with no LibKa0s** (the degraded install every Ka0s addon models) gets `nil` from the
`LibStub` lookup and must degrade as it does for every other module — which for this major means
keeping the ladder it already had, or accepting the same empty answers the table above describes.

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Env.lua` is a new entry in `LibKa0s.xml`, so a consumer whose test harness derives its load list
from that XML picks it up with no edit; a consumer that re-types the list adds one row.
