# `LibKa0s-Pool-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Pool surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Pool-1.0` |
| Files and minors | `Pool.lua` minor **3** |
| Shipped in | v1.17.0 |
| Status | **Current** |
| Supersedes | [version 2](./version-2-docs.md) — whose `ReleaseAll` parked the active set forward, so an ordered consumer's object-to-position mapping alternated on every render |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Pool-1.0").MODULES` → `{ Pool = 3 }` |

## What changed at this version

**`ReleaseAll` parks the active set backward, and the order it leaves behind is now a documented
guarantee.** Through version 2 it walked `for i = 1, #active`, while `Acquire` pops the free list
from the END. Those two together reverse the object-to-position mapping on every release: position
1's object is parked first, ends up at the bottom of the free list and is handed out last on the
next pass — which parks it back the other way. A consumer that assigns position by acquire order
therefore alternated between two mappings with period **2**, every render, indefinitely.

| | | Since |
|---|---|---|
| `ReleaseAll` parks backward | `for i = #active, 1, -1`, so position n is parked first and position 1 is left on top of the free list. | **3** |
| **Order survives a release** | After `ReleaseAll`, a fresh run of `Acquire` calls hands the objects back **in their original order** — position 1 gets the object position 1 had. An ordered consumer may rely on it. | **3** |
| `ReleaseAllKeyed` order stays undefined | Stated rather than changed: the key is the mapping there, and `pairs` order carries no meaning. | **3** |

**Nothing else moves, and no host has to change a line.** `New`, `Acquire`, `Counts`, the `before`
hook, the keyed half and the keyed-pool guard are all exactly as version 2 describes them. A host
that draws an unordered set sees no difference at all. Adopters need a re-vendor and no code change.

**Why this is a bump rather than a quiet correction.** Version 2's document said nothing about
ordering in either direction, so a host reading it could not have known which way the objects came
back — which is precisely how the defect below reached the client and stayed there. Publishing the
guarantee is the substance of this version; the loop direction is just how it is kept.

**The defect this ends.** MultiMeters pools one bar per ranked player and takes the rank from acquire
order, so every bar was handed a different player's figure four times a second. A damage figure is
not free to re-apply: it resolves through a visible transient, so each bar painted full and then
snapped back to its real width, continuously, for the whole fight. Preview mode looked perfect —
placeholder figures are plain and apply with no resolve step. Nothing in the pool could show it:
`Counts` answers `n, 0` either way, identity is preserved either way, nothing leaks, and no suite
went red. The objects were all correct and merely in the wrong places, so only the screen knew. The
hand-rolled pool that addon replaced walked its active list backward, which is why adopting this
major is what introduced the churn.

**Why not fix it from the other end.** Taking from the FRONT of the free list would work equally
well and would put an O(n) `table.remove(pool.free, 1)` shift on a per-frame path. The cost belongs
in the release, which runs once per render, not in the acquire, which runs once per widget.

## What this major is

**The free/active widget pool this collection kept rewriting.** Eight functions, no state of its own,
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

Since version 2 there is a second shape, for a host that needs to find one live object by name:

```lua
{ free = { … }, active = { [key] = … } }     -- built by NewKeyed()
```

Same free list, same objects, same factory contract. **Only `active` changes, from an array to a
map** — and that is the whole difference, which is why the keyed half is four members rather than a
second module.

Plain on purpose. A host holding a pool built before a minor upgrade keeps working, a host without
this library writes a nine-line local copy rather than a redesign, and a pool is inspectable in a
debugger without knowing anything about this module.

**The two shapes are not interchangeable.** A keyed pool is released by `ReleaseAllKeyed` and counted
by `CountsKeyed`; an array pool by `ReleaseAll` and `Counts`. Crossing them is the mistake the guard
below exists for.

## Lib-level surface

Read straight off the LibStub table. Every function is stateless; the pool table you pass in is the
only state there is.

| Name | Since | Meaning |
|---|---|---|
| `New()` | 1 | A fresh, empty pool — `{ free = {}, active = {} }`. A distinct table on every call. |
| `Acquire(pool, factory)` | 1 | An object off the free list, or `factory()` when the free list is empty. The object is appended to `active`, **shown**, and returned. |
| `ReleaseAll(pool[, before])` | 1 | Hides every active object and **returns it to the free list**, parking it so the next run of `Acquire` calls hands the objects back in the same order (since **3**). `before(object)` runs on each object while it is still shown. **Raises** if anything is left in `active` after the walk — see below. |
| `Counts(pool)` | 1 | Two numbers: how many objects are parked and how many are out — `#free, #active`. |
| `NewKeyed()` | 2 | A fresh, empty **keyed** pool. The same `{ free = {}, active = {} }` table; `active` is read as a map. |
| `AcquireKeyed(pool, key, factory)` | 2 | An object off the free list, or `factory()`, filed under `key`, **shown**, and returned. A `key` that is already live returns the object sitting there and builds nothing. |
| `ReleaseAllKeyed(pool[, before])` | 2 | Hides every active object, returns it to the free list and clears every key. `before(object, key)` runs on each object while it is still shown. Order carries no meaning here and is left undefined. |
| `CountsKeyed(pool)` | 2 | Two numbers for a keyed pool: `#free`, and the active map walked with `pairs`. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Pool-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Pool = <minor> }` — the live minor, and the value that picks this document. |

### `Acquire` shows what it hands back

Every consumer wants that: a pooled widget is acquired in order to be drawn. A caller that wants it
hidden hides it, which is one line at one call site rather than a flag on every call. `AcquireKeyed`
does the same, for the same reason.

`factory` is called with **no arguments** and must return an object carrying `:Show()` and `:Hide()`.
It is a closure the host owns, so the fully-wired widget it builds — anchors, textures, scripts —
stays the host's business. The keyed half changes nothing about that contract: the key indexes the
active set, it is never handed to the factory.

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

**`ReleaseAllKeyed` calls it as `before(object, key)`** — the key is handed over, where `ReleaseAll`
passes the object alone. A keyed host's per-object teardown usually needs the key (unregistering a
ticker filed under the same id, say), and recovering it by scanning the map would defeat the index
the variant exists for.

### Order is preserved across a release — since minor 3

**After `ReleaseAll`, the next run of `Acquire` calls hands the objects back in their original
order.** Acquire the pool's objects as positions 1..n, release them all, acquire n again: position 1
is handed the object it had last time, position 2 the object it had, and so on. **An ordered
consumer may rely on that** — a host that pools one widget per ranked row and takes the rank from
acquire order is doing the supported thing, not getting lucky.

It is a guarantee about a *whole* release-then-reacquire cycle, not about arithmetic on the free
list. `ReleaseAll` parks the active set backward (`for i = #active, 1, -1`) so position n goes in
first and position 1 is left on top, and `Acquire` pops from the end. Both halves are internal; the
promise is the round trip.

Two things it does not say. A pool released and then acquired a *different* number of times gets
the same prefix and no promise past it — acquire fewer and the tail stays parked; acquire more and
the extra objects come off the free list in whatever order earlier cycles left them, or are built by
`factory()`. And it says nothing about a host that mixes its own `table.insert` into `pool.free`,
which was never supported.

Why a widget pool cares at all: the object handed to a position is the object that position's state
was last applied to. When the mapping shuffles, every widget is re-pointed at a different record on
every render, and a value that is not free to re-apply — one that animates, resolves or fades on
being set — turns that into a permanent visual churn that nothing but the screen can see. Version 2
had exactly that, and the whole of it is under *What changed at this version* above.

### Identity is preserved across a release

The object handed back by a later `Acquire` is one of the objects released earlier, unchanged. Hosts
stash per-object state on the widget — a full label for a tooltip, a row's record id — and a pool
that quietly swapped identities would make that state follow the wrong row. The keyed half preserves
identity the same way, and across *different* keys: the free list is a single shared stack, so an
object acquired under `"a"` and released may come back under `"c"`.

### `AcquireKeyed` on a live key builds nothing

It returns the object already filed there. Overwriting would orphan the first object — the map would
hold only the second, and the first could never reach the free list again, which is the same leak by
a different route. A host that wants a different object under a key releases first.

### Why `CountsKeyed` exists at all

`Counts` reads `#active`. Over a map that is **0 however full the pool is**, which is precisely the
reading that made the original hand-rolled leak unobservable. A keyed host asserting on recycling —
which is the assertion this major exists to make possible — needs a counter that actually walks the
map, so it gets one.

## The `ReleaseAll` guard, and the one case it cannot catch

After the array walk, `ReleaseAll` empties `active` and then checks `next(active)`. Anything still
there is a keyed entry the loop could never have reached, and it raises:

```
LibKa0s-Pool: ReleaseAll was handed a keyed pool — use ReleaseAllKeyed
```

at level 2, so the error points at the caller rather than at this file.

**The net has one hole, and it is not closable.** A keyed pool whose keys happen to be `1..n` is
indistinguishable from an array pool — `#active` answers the same for both — so the array loop
consumes it and the guard never fires. It recycles correctly, by accident, and the accident stops the
moment a key goes missing from the sequence.

That hole is not where the mistake happens. A pool is keyed in order to index it by something the
host already has: a spellID, a frame name, a unit token. Domain identities do not form a dense
sequence from 1, so the case that actually occurs in a real host is the case the guard catches.

**So the guard is a safety net, not the contract.** The contract is that a keyed pool is released by
`ReleaseAllKeyed`. `tests/test_pool.lua` pins both halves — that the guard raises on a keyed pool,
and that it does not fire on `1..n` keys — because a limit that is only known is a limit that gets
quietly "fixed" into a behavior somebody depends on.

## What it deliberately is not

**Not Blizzard's `CreateFramePool`.** That one owns frame creation, resetter functions and a
template; every caller here already has its own factory closure building a fully-wired widget.

**Not a per-object `Release`.** No consumer releases one object at a time, and a member nobody calls
is a member nobody tests. Note that this is not weakened by the keyed half: `AcquireKeyed` gives a
host an O(1) *read* of one live object, not a way to retire it on its own.

**Not a third `pool.all` array.** MultiMeters carries one alongside `free` and `active`; one consumer
is not a shape, and adding a member for it would put a field in every pool this collection builds to
serve a list only one host reads.

**Not a frame pool at all**, strictly. Nothing in this module knows what a frame is: any table with
`:Show()` and `:Hide()` pools, which is what the suite exercises.

## Adopting it

The array pool, unchanged from version 1:

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

The keyed pool, for the host that has to reach one live object by name:

```lua
function Grid:Build()
    self.buttons = self.buttons or (Pool and Pool.NewKeyed())
end

function Grid:Render(spells)
    if not Pool then return end
    Pool.ReleaseAllKeyed(self.buttons, function(btn) btn:ClearAllPoints() end)
    for i = 1, #spells do
        Pool.AcquireKeyed(self.buttons, spells[i].id, function() return self:NewButton() end)
    end
end

function Grid:OnSpellState(payload)                  -- the hot path, no scan
    local btn = self.buttons and self.buttons.active[payload.spellID]
    if btn then btn:Apply(payload) end
end
```

Reaching into `active` to read one key is the point of the variant and is supported: it is a plain
map, on a table with no metatable. **Writing to it is not** — `AcquireKeyed` and `ReleaseAllKeyed`
own what goes in and what comes out, and a host that files an object by hand has an object the free
list will never see.

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

`Pool.lua` has been in `LibKa0s.xml` since version 1, so this version is a re-vendor and no edit: a
consumer already carrying the file picks the new minor up from the copy, and LibStub prefers it over
whatever else is loaded.
