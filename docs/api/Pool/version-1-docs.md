# `LibKa0s-Pool-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Pool surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Pool-1.0` |
| Files and minors | `Pool.lua` minor **1** |
| Shipped in | v1.15.0 |
| Status | Superseded |
| Supersedes | — (first version) |
| Superseded by | [version 2](./version-2-docs.md) — the keyed pool, and a `ReleaseAll` that refuses one |
| Confirm in-game | `LibStub("LibKa0s-Pool-1.0").MODULES` → `{ Pool = 1 }` |

## What this major is

**The free/active widget pool this collection kept rewriting.** Four functions, no state of its own,
no frame API beyond `:Show()` and `:Hide()`, and no addon framework.

Four copies of this pool shipped across two addons. Three recycled correctly. The fourth hid its
active objects and dropped them — nothing was ever returned to the free list, so `Acquire` fell
through to `factory()` on every call. None of that is visible from outside: the charts draw
correctly, the suite stays green, and the only symptom is a client that gets heavier the longer a
window is open, because frames are never destroyed in WoW.

Two addons wrote the same eleven lines and one of them got the second half wrong. That is the case
for a library in its purest form, and it is also the boundary: there is nothing addon-specific here
to make configurable.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called** — the gate is there so that a host holding a partial payload gets every module
absent rather than a working half, and "is LibKa0s here?" stays one question.

## What a pool is here

A plain table with two arrays and **no metatable**:

```lua
{ free = { … }, active = { … } }
```

Plain on purpose. A host holding a pool built before a minor upgrade keeps working, a host without
this library writes a nine-line local copy rather than a redesign, and a pool is inspectable in a
debugger without knowing anything about this module.

## Lib-level surface

Read straight off the LibStub table. Every function is stateless; the pool table you pass in is the
only state there is.

| Name | Since | Meaning |
|---|---|---|
| `New()` | 1 | A fresh, empty pool — `{ free = {}, active = {} }`. A distinct table on every call. |
| `Acquire(pool, factory)` | 1 | An object off the free list, or `factory()` when the free list is empty. The object is moved to `active`, **shown**, and returned. |
| `ReleaseAll(pool[, before])` | 1 | Hides every active object and **returns it to the free list**. `before(object)` runs on each object while it is still shown. |
| `Counts(pool)` | 1 | Two numbers: how many objects are parked and how many are out — `#free, #active`. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Pool-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Pool = <minor> }` — the live minor, and the value that picks this document. |

### `Acquire` shows what it hands back

Every consumer wants that: a pooled widget is acquired in order to be drawn. A caller that wants it
hidden hides it, which is one line at one call site rather than a flag on every call.

`factory` is called with **no arguments** and must return an object carrying `:Show()` and `:Hide()`.
It is a closure the host owns, so the fully-wired widget it builds — anchors, textures, scripts —
stays the host's business.

### `ReleaseAll` is the whole module

The second half is the point. A release that only hides is an allocator wearing a pool's name, and
that is not hypothetical — it shipped. After `ReleaseAll`, `Counts` answers `n, 0`; a pool that
failed to recycle would answer `0, 0`, which is the only way a leak is observable at all.

### The `before` hook, and nested pools

`before` is optional and runs on each object **before** it is hidden, which is what makes one
function cover a nested pool: a host releasing a pool of list panels releases each panel's own row
pool first.

```lua
Pool.ReleaseAll(panelPool, function(p) Pool.ReleaseAll(p._rows) end)
```

Without the hook that host needs a second library member, and the two drift the way the four
hand-rolled copies did.

### Identity is preserved across a release

The object handed back by a later `Acquire` is one of the objects released earlier, unchanged. Hosts
stash per-object state on the widget — a full label for a tooltip, a row's record id — and a pool
that quietly swapped identities would make that state follow the wrong row.

## What it deliberately is not

**Not Blizzard's `CreateFramePool`.** That one owns frame creation, resetter functions and a
template; every caller here already has its own factory closure building a fully-wired widget.

**Not a per-object `Release`.** No consumer releases one object at a time, and a member nobody calls
is a member nobody tests.

**Not a frame pool at all**, strictly. Nothing in this module knows what a frame is: any table with
`:Show()` and `:Hide()` pools, which is what the suite exercises.

## Adopting it

```lua
local Pool = LibStub and LibStub("LibKa0s-Pool-1.0", true)

function Panel:Build()
    self.rows = self.rows or (Pool and Pool.New())
end

function Panel:Render(records)
    if not Pool then return end
    Pool.ReleaseAll(self.rows)
    for i = 1, #records do
        local row = Pool.Acquire(self.rows, function() return self:NewRow() end)
        row:SetRecord(records[i])
    end
end
```

**A host with no LibKa0s** (the degraded install every Ka0s addon models) gets `nil` from the
`LibStub` lookup and must degrade as it does for every other module — which for this major means
keeping the local pool it already had.

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Pool.lua` is a new entry in `LibKa0s.xml`, so a consumer whose test harness derives its load list
from that XML picks it up with no edit; a consumer that re-types the list adds one row.

## Moving to version 2

**Take it, and nothing you have written needs to change.** `New`, `Acquire`, `ReleaseAll` and
`Counts` behave at version 2 exactly as they do here for a pool built by `New()`. A host needs a
re-vendor and no code change.

What version 2 adds is a **second pool shape**, for a host that needs to find one live object by name
on a hot path: `NewKeyed()` builds `{ free = {…}, active = { [key] = … } }` — the same free list, the
same factory contract, with `active` read as a map rather than an array — and it comes with
`AcquireKeyed(pool, key, factory)`, `ReleaseAllKeyed(pool[, before])` and `CountsKeyed(pool)`. Two
consumers had keyed their active set by domain identity before the variant existed and could not
adopt this version at all; KickCD's icon grid keys buttons by spellID so a cooldown-state message
reaches one widget without a scan.

The one thing that is not purely additive is a **new failure**: at version 2, `ReleaseAll` raises
`"LibKa0s-Pool: ReleaseAll was handed a keyed pool — use ReleaseAllKeyed"` when anything is left in
`active` after its array walk. A pool built by `New()` and used as this document describes can never
reach that state, so no correct version-1 host trips it. It is there for the host that hand-rolls a
keyed pool and then ports it to `ReleaseAll`, which recreates the exact defect this major was written
to end: the array loop walks nothing over a keyed table, so nothing is recycled, `Acquire` falls
through to `factory()` forever, and no suite goes red.
