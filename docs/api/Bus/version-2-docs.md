# `LibKa0s-Bus-1.0` — version 2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Bus surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Bus-1.0` |
| Files and minors | `Bus.lua` minor **2** |
| Shipped in | v1.56.0 |
| Status | **Current** |
| Supersedes | [version 1](./version-1-docs.md) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Bus-1.0").MODULES` → `{ Bus = 2 }` |

## What changed at this version

**The bus re-stamps its tracking wrappers at every edge, so a newer AceEvent-3.0 loading later in
the session no longer takes a target out of the record for good.** No member is added or removed,
so the manifest differs from version 1's only in the minor, and every host gets the fix by
re-vendoring with no code change.

| | | Since |
|---|---|---|
| `bus:StandDown()` / `bus:StandUp()` | Re-stamp every target this bus created **first**, in every case — including the idempotent and the refused calls — before doing anything else. | **2** |
| `bus:StandDown()` | Answers a trailing second value: the number of targets re-stamped. | **2** |
| `bus:StandUp()` | Answers a trailing third value: the number of targets re-stamped. | **2** |
| A re-stamped target | Its wrappers forward to the member the re-embed left behind, adopted as the new raw member. | **2** |

At version 1, AceEvent-3.0's upgrade loop re-embedding a target overwrote its six wrappers with the
raw mixins for the rest of the session. A registration made through the overwritten members went
straight to CallbackHandler and was never recorded, so `StandDown` left it live on a target with an
empty record, and `StandUp` never brought it back on one with a recorded entry (review finding
`LibKa0s-R-05`). See *The re-stamp* below for what is closed and the window that remains.

**The trailing values are additive.** A host that reads `local n = bus:StandDown()` or
`local replayed, rejected = bus:StandUp()` is unaffected. One that forwards the call in the last
position of an argument list — `assertEqual(x, bus:StandDown())`, or `return bus:StandDown()`
into such a call — now passes one more value there.

## What this major is

**Two things an addon's message bus needs and every host was writing for itself:** a record of
what each bus receiver is registered for, so a stood-down addon can take all of it down and bring
back exactly what is wanted now; and a strict, validated catalog of the addon's message names.

### The stand-down record

Every addon in the collection gives each bus receiver a private AceEvent target, because two
receivers of one message on one target overwrite each other in CallbackHandler
(`architecture-§4`). A stood-down addon has to unregister every event and message those receivers
hold (`slash-commands-§7`), and a stood-up one has to put back what is wanted **now** — a receiver
can drop or gain a registration while the addon is down, so a snapshot taken on the way down is the
wrong answer.

Four repos wrote that record by hand. PartyFrameEnhanced recorded events and messages; AbsorbTracker,
ConsumableMaster and MultiMeters recorded messages only. None disagreed with the widest on
correctness, so this major is that union design, without the two defects the copies carried: a key
list that gained a duplicate on every re-register, and CallbackHandler's optional `arg` dropped on
replay.

### The catalog

`architecture-§4` requires every bus message to be declared **once**, as a constant, and the naming
cheatsheet requires the wire name `Ka0s_<Addon>_<Event>` with `<Event>` in PascalCase. `Catalog`
validates that declaration at load and hands back a **strict** copy, so a mistyped key raises at the
call site — for a publisher as well as a subscriber. Without it a mistyped constant fails at once
only for a subscriber (CallbackHandler raises on a non-string name); a publisher's
`SendMessage(nil)` is silent, because CallbackHandler's `Fire` returns quietly on an event nobody
registered.

### What it deliberately does not do

- **It owns no hold set, no edge and no callbacks.** `LibKa0s-Lifecycle-1.0` decides *when* an addon
  stands down; the host calls `bus:StandDown()` and `bus:StandUp()` from inside its own latch
  callbacks, at the position in its sequence it chooses. That position is load-bearing and differs
  per host — one brings the bus down last so a final publish still reaches receivers, another brings
  it up first so the publishes at the end of its rebuild are heard — so the library cannot pick it.
- **It does not replace the untracked factory.** The bare `NS.NewBusTarget()` (four lines of
  `AceEvent:Embed`) stays host code, as `architecture-§4` prints it. A host keeps it for receivers
  that must survive a stand-down, such as a settings panel's live refresh, and for modules that
  rebuild their receivers from scratch.
- **It does not touch the publisher.** Sending is not a registration.
- **It never prints.**

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer). **No Core member is called** — the
floor is the load-payload check `library-stack-§7` asks for, so a host holding a partial payload gets
every module absent rather than a working half. `AceEvent-3.0` is resolved **at call time** with
`LibStub("AceEvent-3.0", true)`, as Options, Media and Launcher resolve their optional libraries; no
floor on it is declared, because the payload may not contain it (`library-stack-§6`).

## Library surface

| Member | Since | What it is |
|---|---|---|
| `lib:New(descriptor)` | 1 | The record for one addon's tracked receivers. **One per addon**, beside its latch. |
| `lib.Catalog(addonName, messages)` | 1 | **Dot-called.** Validates the message table and answers a fresh, strict copy. |

## The descriptor

| Field | Type | Required | What it is |
|---|---|---|---|
| `name` | string | yes | The addon's folder name. Published as `bus.name`; diagnostic only, never branched on. |
| `isDown` | function | no | The latch predicate. While it answers truthy, `StandUp` is refused. |

`isDown` is a closure, not a latch reference, because a host builds its bus in `core/Bus.lua` long
before its latch exists: `isDown = function() return NS.IsStoodDown() end` resolves the host's
predicate when it is asked. Inside the latch's own `standUp` callback the latch has already recorded
the edge, so `isDown()` answers false there and the replay proceeds; anywhere else while a hold is
taken it answers true, and a bare stand-up of the registrations is refused. That is Lifecycle's "no
bare stand-up" rule carried into the one member here that could otherwise be one.

`New` raises (level 2) when `name` is missing or not a non-empty string, or when `isDown` is given
and is not a function.

## Instance surface

| Member | Since | Answers | What it does |
|---|---|---|---|
| `bus:NewTarget()` | 1 | a target, or **nil** | A fresh AceEvent-embedded table whose six register/unregister members are wrapped (below). One per receiver, never shared. `nil` when `AceEvent-3.0` is not in LibStub. |
| `bus:StandDown()` | 1 | number, number | Raw-unregisters every tracked registration, events **and** messages, and keeps the record. Answers the number of recorded entries, then (**since 2**) the number of targets re-stamped. Idempotent: a second call answers `0` and takes nothing down. Not guarded by `isDown`. |
| `bus:StandUp()` | 1 | number, array, number | Replays the record as it is **now**. Answers `replayed, rejected` — the entries made live, and a **fresh sorted** array of `"event:NAME"` / `"message:NAME"` for the entries that raised — then (**since 2**) the number of targets re-stamped. `0, {}` when already up, and `0, {}` (the bus staying down) while `isDown()` answers truthy, each with the re-stamp count after them. Never raises. |
| `bus.name` | 1 | — | The descriptor's `name`. |

## A tracked target

`NewTarget` embeds AceEvent into a fresh table, captures the six raw members, and stamps a wrapper
over each: `RegisterEvent`, `UnregisterEvent`, `UnregisterAllEvents`, `RegisterMessage`,
`UnregisterMessage`, `UnregisterAllMessages`. `SendMessage` is left raw.

Each wrapper calls the raw member it holds **at call time**, so a raw member the re-stamp adopts is
the one called from then on.

### The re-stamp

AceEvent-3.0 ends its file with an upgrade loop that calls `Embed` again on every table in
`AceEvent.embeds`. A newer minor loading after a Ka0s host has created targets therefore writes the
six raw members back over the bus's wrappers. **Both edges re-stamp first:** `StandDown` and
`StandUp` walk every target this bus created and, for each of the six members that no longer holds
its wrapper, adopt what they find there as the new raw member and put the wrapper back. They do it
before their own idempotence and `isDown` checks, so a no-op or refused call still re-stamps, and
they answer the number of targets re-stamped as a trailing value for the host's debug seam.

**The residual window.** A registration made between a re-embed and the next edge goes straight to
CallbackHandler and is untracked. At that edge, `StandDown` still takes it down when its target
holds a recorded entry (the raw unregister-all clears the whole target), but it is not in the
record, so `StandUp` does not bring it back; on a target whose record is empty it stays live. From
the edge on the target is tracked again. The edges are the only moments the record is read, which
is why they are where it is repaired: there is no fork of Ace3 and no metatable proxy on the target.

### The record

Per target, one entry per `(kind, name)`, holding the handler **exactly as given** — a function, a
method name, or `nil` (AceEvent's "the method named for the event") — and the optional argument
**with its count**, because CallbackHandler tells "no arg" from "arg is nil" by counting. The replay
passes the same arity, so an explicit `nil` argument comes back as an explicit `nil` argument.

**The record never holds a key twice.** Re-registering an existing key replaces the entry in place
and keeps its position — CallbackHandler's own rule, one callback per `(event, target)` with the
later one winning — so the record and the live registration never disagree about which handler
wins. Unregistering removes the key.

Only a call on the target itself is recorded; a wrapped member reached with some other `self` is
passed straight to the raw member.

### While up (the state `New` answers)

- **Register:** the raw call **first**, then the record. A raw call that raises — the client's
  `Attempt to register unknown event` — reaches the caller unchanged and is **not recorded**, so a
  host's own pcall helper (`events-frames-taint-§1`) sees exactly the raise it sees today.
- **Unregister / UnregisterAll:** forget, then raw.

### While down

- **Register:** **record only, no raw call.** The registration goes live at `StandUp`. This is what
  makes "a stood-down addon registers nothing" structural for every tracked receiver, rather than a
  `not NS.IsStoodDown()` guard each site has to remember.
- **Unregister / UnregisterAll:** forget, then raw — a no-op on the registry, kept unconditional so
  the two paths cannot drift.

In both states a non-string name is handed straight to the raw call, so CallbackHandler raises its
own usage error and nothing is recorded.

### The replay

`StandUp` walks targets in creation order and entries in first-registration order. Dispatch order
is not observable through CallbackHandler, so this order exists for a deterministic replay and a
deterministic `rejected` list, and for nothing else.

Each entry replays through `pcall`, so one entry that raises cannot leave the rest unregistered —
`events-frames-taint-§1`'s "a block MUST survive one bad name", applied to the replay loop. A raising
entry is dropped from the record, whatever the raw call left behind in CallbackHandler is
unregistered, and its name goes into `rejected`. **Nothing is raised out of `StandUp`:** it runs
inside the host's `standUp` callback, and a raise there would abort the rest of the host's rebuild.
The host logs `rejected` through its debug seam.

Only an entry recorded **while down** was never validated by a raw call, so in practice `rejected`
is empty.

### Retention

The bus holds a target **strongly** exactly while its record is non-empty, and lets go the moment it
empties — through any unregister path, including `UnregisterAll*`. So:

- A target nothing but CallbackHandler holds survives a stand-down (which drops CallbackHandler's
  reference) and is there to replay.
- A target its owner retires by emptying it leaves the bus, with **no `Retire` member needed**.
  Outside that window the bus holds no strong reference to it at all.

**Since 2** the bus also keeps every target it created in a **weak-keyed** set, so the edges can
re-stamp a target whose record is empty. Lua 5.1 has no ephemerons, so that set releases a target
only because nothing reachable from the bus's per-target record names the target: the wrappers
recognize their own target by looking it up in the set, rather than by holding it.

In the client, AceEvent-3.0's own `embeds` set also holds every table it has embedded, for the whole
session. The bus does not lean on that internal, and it is why "leaves the bus" is the promise rather
than "is collected".

## Answers with a dependency absent

| Member | LibStub, Core or this file absent, or Core below the floor | `AceEvent-3.0` absent from LibStub |
|---|---|---|
| `lib:New` | the major is **absent**: `LibStub("LibKa0s-Bus-1.0", true)` answers nil and the host's stub answers | works — the instance is bookkeeping |
| `lib.Catalog` | absent; the host's stub hands back its own plain table | works — a pure function |
| `bus:NewTarget` | — | **nil**, which callers already treat as "no bus" |
| `bus:StandDown` | — | `0, 0` — nothing was ever tracked or created |
| `bus:StandUp` | — | `0, {}, 0` |

AceEvent is looked up on every `NewTarget`, never cached as absent, so a library that registers
after this file loads is still found.

## `Catalog`

```lua
local MSG = {
  -- Sender: modules/ContainerManager.lua. Payload: none.
  CONTAINERS_CHANGED = "Ka0s_AuraMaster_ContainersChanged",
}
NS.MSG = Bus and Bus.Catalog(addonName, MSG) or MSG
```

It takes the host's **full wire names**, not suffixes, so the same table is the declaration on the
live path and on the degraded one, and each `Ka0s_` literal still appears exactly once in the repo.

It raises at load (level 2 at the caller), naming the offending key, when:

| Check | Rule it enforces |
|---|---|
| `addonName` is a non-empty string | — |
| `messages` is a non-empty table | — |
| every key is a string matching `^%u[%u%d_]*$` | the key is SCREAMING_SNAKE |
| every value is a string starting `Ka0s_<addonName>_` | `architecture-§4`'s prefix |
| the part after the prefix matches `^%u[%a%d]*$` **and** holds a lowercase letter | `<Event>` is PascalCase |
| no two keys share a value | declare-once: two constants for one wire name are two declarations |

Keys are checked in sorted order, so which refusal a table with several faults raises is
deterministic. A colon call (`Bus:Catalog(...)`) is refused by name. The past-participle SHOULD for
`<Event>` is not checked; it is not mechanically decidable.

What it answers is a **fresh** table holding exactly the declared keys — `pairs` enumerates them, so
a doc-parity test can still walk it — whose metatable raises `"<addonName>: no bus message named
<KEY>"` on reading an undeclared key, and raises on adding a new one. The host's input table is not
mutated and gains no metatable. An existing key can still be reassigned (a raw field write never
reaches `__newindex`); the gate for that is review, not runtime.

A host that probes a key for presence (`NS.MSG and NS.MSG.SOME_KEY`) keeps working when the key is
declared, and raises when it is not — which is the point: the probe existed only because the host
could not be sure of its own catalog.

## Hard invariants

Each has a case in `tests/test_bus.lua`, named here by its title.

1. **`StandDown` takes events and messages down** and answers the entry count — *StandDown takes
   events AND messages down and answers the entry count*.
2. **`StandDown` keeps the record; `StandUp` replays it** — *StandDown keeps the record and StandUp
   replays it*.
3. **The replay is the record as it is now**, not a snapshot — *StandUp replays the record as it is
   NOW*.
4. **A registration made while down is recorded and not live** until `StandUp` — *a registration
   made while down is recorded and NOT live until StandUp*.
5. **Both members are idempotent** — *StandDown and StandUp are idempotent*.
6. **A key is never recorded twice**; the later handler wins — *re-registering a key replaces the
   entry in place and never duplicates it*.
7. **Every handler form survives the round trip**, including the optional argument and an explicit
   `nil` one — *every handler form survives the round trip with CallbackHandler's arguments*.
8. **`UnregisterAllEvents` forgets events only**, as AceEvent keeps the two registries apart — *the
   record follows every wrapper*.
9. **A raw register that raises while up propagates and is not recorded** — *a raw register that
   raises while up reaches the caller and is not recorded*.
10. **One entry that raises on replay does not stop the others, `StandUp` never raises, and the
    rejected entry leaves the record** — the two replay cases.
11. **`StandUp` is refused while `isDown()` answers true**, and the bus stays down — *StandUp is
    refused while isDown answers true*, and end to end through Lifecycle: `Hold(disabled);
    Hold(perf); Release(perf)` leaves the registrations down, and `Release(disabled)` brings them up.
12. **Retention:** a target only CallbackHandler holds survives a stand-down and a full collection;
    an emptied target leaves the bus.
13. **Two buses share nothing.**
14. **`SendMessage` is raw**, and a tracked target can publish while its own receivers are down.
15. **The bus prints nothing.**
16. **Without AceEvent** every member answers the table above, and the lookup is at call time.
17. **`Catalog` refuses each malformed declaration** (one row per check), **answers a fresh copy**,
    and **is strict** on read and on write.
18. **A re-embedded target is re-stamped at the next edge**, and a registration made after that
    edge stands down and is replayed — *a re-embedded target is re-stamped at the next edge, so
    later registrations stand down*, and *after a re-stamp, a registration made while down is
    recorded and not live*.
19. **The re-stamp adopts the member it found as the new raw member**, and counts a target once —
    *the re-stamp adopts the new raw member and counts a target once*.

## Worked example

```lua
-- core/Bus.lua
local addonName, NS = ...
local Bus = LibStub and LibStub("LibKa0s-Bus-1.0", true)
if not Bus then
  -- Degraded: the payload is missing. Receivers still get a private target, but nothing is
  -- recorded, so a disable leaves registrations live on bus targets. Stated in the host's
  -- `## Known Limitations`, not hidden.
  Bus = {
    New = function(_, d)
      return {
        name = d and d.name,
        NewTarget = function()
          local AceEvent = LibStub and LibStub("AceEvent-3.0", true)
          if not AceEvent then return nil end
          local t = {}; AceEvent:Embed(t); return t
        end,
        StandDown = function() return 0, 0 end,
        StandUp   = function() return 0, {}, 0 end,
      }
    end,
    Catalog = function(_, messages) return messages end,
  }
end

-- The publisher stays host code: sending is not a registration.
local AceEvent = LibStub("AceEvent-3.0", true)
NS.bus = AceEvent and AceEvent:Embed({})

-- The record, asking the latch through a closure: the latch is built later, in LifecycleSetup.
NS.busRecord = Bus:New{ name = addonName, isDown = function() return NS.IsStoodDown() end }
function NS.NewBusTarget() return NS.busRecord:NewTarget() end
function NS.BusStandDown() return NS.busRecord:StandDown() end
function NS.BusStandUp()
  local replayed, rejected, restamped = NS.busRecord:StandUp()
  if #rejected > 0 then NS.Debug("bus: rejected on stand-up: %s", table.concat(rejected, ", ")) end
  if restamped > 0 then NS.Debug("bus: re-stamped %d re-embedded target(s)", restamped) end
  return replayed
end

NS.MSG = Bus.Catalog(addonName, {
  -- Sender: modules/Roster.lua. Payload: none.
  ROSTER_CHANGED = "Ka0s_MyAddon_RosterChanged",
})

-- core/LifecycleSetup.lua: the host picks the position in its own sequence.
NS.lifecycle = LibStub("LibKa0s-Lifecycle-1.0"):New{
  name      = addonName,
  standDown = function() NS.SuspendModules(); NS.BusStandDown() end,   -- bus LAST on the way down
  standUp   = function() NS.BusStandUp(); NS.ResumeModules() end,      -- bus FIRST on the way up
}
```

A host's test suite holds that stub to the live surface with
`Kit.assertSurfaceParity(stub, "LibKa0s-Bus-1.0")`; the members it owes are `New` and `Catalog`
(`members-2.json`).

## Known limitations

1. **A registration made between an AceEvent-3.0 re-embed and the next edge is untracked** — the
   residual window under *The re-stamp*. The collection vendors AceEvent-3.0 minor 4 everywhere, so
   no re-embed happens today. Re-check trigger: any AceEvent-3.0 minor above 4 in any consumer's
   `libs/`.
2. **A registration made on a tracked target while the bus is down is not validated until
   `StandUp`.** A bad event name, or a method name the target does not carry, surfaces in
   `rejected`, not at the call site.
3. **A test probe made through a tracked factory is part of the record.** A consumer suite that
   builds throwaway receivers through a tracked `NS.NewBusTarget()` should empty them
   (`t:UnregisterAllMessages()`) or build them as untracked embeds, or a later stand-down/stand-up
   case replays them.
4. **A raw register's error now carries one more stack frame.** The raise is the raw member's own,
   unchanged in text, but its position prefix can point at the wrapper in `Bus.lua` rather than at the
   caller. A host that matches on the message body is unaffected.
5. **`UnregisterAll*` called with several targets** (`t.UnregisterAllMessages(t, other)`, a form
   CallbackHandler accepts) forgets only the record of the first when it is the target itself; the
   raw call still unregisters all of them. No consumer uses the multi-target form.
