# `LibKa0s-Lifecycle-1.0` — version 2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Lifecycle surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Lifecycle-1.0` |
| Files and minors | `Lifecycle.lua` minor **2** |
| Shipped in | v1.56.0 |
| Status | **Current** |
| Supersedes | [version 1](./version-1-docs.md) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Lifecycle-1.0").MODULES` → `{ Lifecycle = 2 }` |

## What changed at this version

**Nothing the code does.** Version 2 documents a rule version 1 left unsaid — a `standDown` or
`standUp` callback must not take or release a hold on its own latch — and pins what happens when one
does anyway (see *Re-entrancy* below, review finding `LibKa0s-R-17`). The only change to
`Lifecycle.lua` is that comment, but a comment still changes the file's bytes, and a released change
to a file moves its LibStub minor. No member is added or removed, so the manifest differs from
version 1's only in the minor, and a host needs no code change.

## What this major is

**One addon, many reasons to be inert, one way down and one way back up.** A hold set, an edge, and
two host callbacks. It owns no frames, no events, no settings and no storage; it does not know what
a registration is. What it knows is whether the set is empty.

### The problem it exists for

Every addon in this collection already owns the machinery to make itself genuinely inert. It was
built for the perf module's second arm — unregister the events, cancel the tickers, let the show
ladder answer no — and it is tested, and it works. **Disable declined to use it.** Eleven addons
implement "disabled" as a *draw gate*: the frames go away, the registrations stay, and the client
goes on walking the addon's registration list on every `UNIT_AURA` in a twenty-five-man raid,
building the argument frame, entering Lua, and running the comparison that decides to leave.

That cost is precisely what a player switching an addon off is trying to stop paying, and it is
invisible from every surface they can see — which is how the draw gate survived eleven audits. From
the outside it looks identical to standing down.

The fix is **not** a second teardown path beside the perf one. A second path is the anti-pattern:
two mechanisms that both mean "be inert" drift, and the day they disagree the addon is half down —
some events unregistered, some frames still drawn — a state nobody designed and no test covers.
Both reasons become **named holds on one latch**.

### Why a latch and not a boolean

Two independent reasons to be down means four states, and the interesting one is the state a
boolean cannot represent: the addon is perf-suspended **and** the player has disabled it, the perf
run finishes, and `resume` runs. With a boolean, resume writes `false` and the addon comes back to
life under a player who switched it off. With a hold set, releasing `perf` leaves `disabled` taken,
the set is still non-empty, and nothing is rebuilt.

**Releasing one hold MUST NOT resurrect an addon the other is still holding down.** That sentence
is the whole reason this major exists.

### What it deliberately does not do

It persists **nothing**: no SavedVariables reference, no state that survives a reload. The
`disabled` hold is re-taken at load from the stored enable path, because surviving a `/reload` is
the entire point of that setting; the `perf` hold is session-only, and re-taking it across a reload
would leave a player's addon dead with no visible cause.

There is **no `:StandUp()` member**, and its absence is a feature. A bare stand-up is exactly the
bug the latch exists to prevent, so the only route out is releasing the hold that put the addon
down.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called** — the gate is there so that a host holding a partial payload gets every module
absent rather than a working half, and "is LibKa0s here?" stays one question
(`library-stack-§7`).

## Library surface

| Member | Since | What it is |
|---|---|---|
| `lib.HOLD_DISABLED` | 1 | `"disabled"` — the hold taken from the stored enable path. |
| `lib.HOLD_PERF` | 1 | `"perf"` — the hold `LibKa0s-Perf-1.0` takes for Experiment B. |
| `lib:New(descriptor)` | 1 | One latch for one addon. |

The two keys are exported rather than left as literals because two majors and every host in the
collection have to spell them the same way. Typed at each call site there are fourteen spellings,
and the day one of them reads `"Perf"` the perf arm takes a hold nothing releases.

The key space is otherwise the host's: an addon that wants a `combat` hold or a `loading` hold
takes one, and nothing here reserves it.

## The descriptor

| Field | Type | Required | What it is |
|---|---|---|---|
| `name` | string | yes | The addon's FOLDER name. Diagnostic output only: nothing branches on it. |
| `standDown` | function | yes | Called with **no arguments** when the hold set goes EMPTY → NON-EMPTY. |
| `standUp` | function | yes | Called with **no arguments** when the hold set goes NON-EMPTY → EMPTY. |
| `print` | function | no | The host's tagged printer. Used **only** by `:PrintHolds()`. |

`standDown` is where the host does its teardown: every `RegisterEvent`, `RegisterUnitEvent`,
`RegisterMessage`, `RegisterBucketEvent` and raw `frame:RegisterEvent` it owns actually
unregistered, every AceTimer handle, `C_Timer` ticker and `OnUpdate` canceled, and its show ladder
answering no **at the source** rather than by imperatively hiding frames — a hidden frame comes back
on a combat transition, a target swap or a settings change.

`standUp` rebuilds **from current state**, never from a snapshot taken on the way down: a setting
can be changed while the addon is down, and the rebuild has to reflect the setting as it is now
(`performance-§6`).

**The library prints nothing unless a line is asked for.** A latch that announced every edge would
narrate a perf run and a profile switch into a player's chat.

## Instance surface

| Member | Since | What it does |
|---|---|---|
| `lc:Hold(key)` | 1 | Adds `key`. Calls `standDown` **exactly once** if the set WAS empty. A key already held is a no-op. Answers whether this call stood the addon down. |
| `lc:Release(key)` | 1 | Removes `key`. Calls `standUp` **exactly once** if the set BECOMES empty. A key not held is a no-op. Answers whether this call stood the addon up. |
| `lc:Set(key, held)` | 1 | `Hold` when `held` is truthy, `Release` otherwise. |
| `lc:IsHeld(key)` | 1 | Boolean. |
| `lc:IsDown()` | 1 | Is the hold set non-empty — is the addon stood down. |
| `lc:Holds()` | 1 | A **fresh sorted array** of held keys. Never the internal table. |
| `lc:Reevaluate()` | 1 | Re-runs the empty/non-empty decision, firing a callback only on an actual edge. Idempotent. |
| `lc:PrintHolds()` | 1 | The one line this library ever prints, through `descriptor.print`. Answers `false` with no printer. |
| `lc.name` | 1 | The descriptor's `name`. |

`:Set` is what a host binds its enable path's `onChange` to:

```lua
lc:Set("disabled", not enabled)
```

written once, in the library's shape, rather than as a branch each host writes for itself — a branch
written eleven times is a branch one host writes backwards.

`:Reevaluate()` is for a **profile switch**. AceDB's `OnProfileChanged` / `OnProfileCopied` /
`OnProfileReset` can flip the stored enable path without any verb or checkbox being touched, so the
host re-reads the path, calls `:Set("disabled", not enabled)` and then this — and gets a stand-down
or a stand-up only if the new profile actually disagrees with the old one.

`:Holds()` is fresh and sorted, and both halves are load-bearing: handing back the internal table
would let a caller mutate the hold set by writing to what looks like a report, and `pairs` order is
not an order — a suite asserting on an unsorted list passes or fails on somebody else's hash seed.

## Hard invariants

Each of these has a case in `tests/test_lifecycle.lua`.

1. `standDown` and `standUp` are each called **at most once per edge**, and never on a non-edge.
2. `Hold("a"); Hold("b"); Release("a")` calls `standDown` **once** and `standUp` **never**.
3. `Hold("a"); Release("a"); Hold("a")` calls `standDown`, `standUp`, `standDown` — in that order,
   once each.
4. Hold order is irrelevant: `Hold(a); Hold(b); Release(b); Release(a)` and the reverse each produce
   exactly one `standDown` and one `standUp`.
5. The latch persists nothing.
6. **An error raised inside a host callback MUST NOT leave the hold set inconsistent.** The set is
   mutated and the edge recorded *before* the callback is invoked, so a throwing `standUp` still
   leaves the set empty and the latch up; the error reaches the host's own error handler and the
   next `Hold` behaves correctly. Update-after would leave the latch believing the addon was still
   down over an empty hold set, with no hold left to release.
7. **A nested edge runs to completion inside the outer one** (version 2, characterization). See
   *Re-entrancy*.

## Re-entrancy

**A `standDown` or `standUp` callback MUST NOT take or release a hold on its own latch** — no
`Hold`, `Release` or `Set` from inside a callback, and no `Reevaluate` after one. This is a rule on
the host, not something the latch enforces: nothing here queues a nested edge or refuses one.

What happens if a callback does it anyway is fixed, and `tests/test_lifecycle.lua` pins it. The edge
calls the callback synchronously, so a hold taken or released inside it re-enters the edge, and the
nested edge runs **to completion inside the outer one**. A `standDown` that releases the hold that
put the addon down fires `standUp` before `standDown` has returned:

```
Hold("disabled")
  standDown enters
    Release("disabled")  -- answers true: this call was an edge
      standUp runs
  standDown returns
Hold answers true; IsDown() is false; the set is empty
```

**The latch stays consistent.** The edge is recorded before each callback runs (invariant 6), so
afterwards the hold set, the recorded edge and `IsDown()` all agree. What does not stay consistent
is the host: its teardown is interrupted halfway by its own rebuild, and then the rest of the
teardown runs over the rebuilt addon. No host is written for that state, which is why the rule
exists. A host that needs a follow-up edge (take a second hold, release the first) defers it until
the callback has returned.

No shipped callback in the collection touches its latch.

## Worked example

```lua
local Lifecycle = LibStub("LibKa0s-Lifecycle-1.0", true)

NS.lifecycle = Lifecycle:New{
  name      = "MyAddon",
  standDown = NS.StandDown,     -- unregister everything, cancel everything, hide at the source
  standUp   = NS.StandUp,       -- rebuild from the settings as they are NOW
  print     = NS.Print,
}

-- At load, from the stored path. Not a special case: it is the same call the checkbox makes.
NS.lifecycle:Set("disabled", not NS.db.profile.enabled)

-- The settings schema's onChange, and the `enable` / `disable` verbs, all land here.
function NS.OnEnabledChanged(enabled)
  NS.lifecycle:Set("disabled", not enabled)
end

-- AceDB's profile callbacks, which can flip the path with nothing else being touched.
local function onProfile()
  NS.lifecycle:Set("disabled", not NS.db.profile.enabled)
  NS.lifecycle:Reevaluate()
end
NS.db.RegisterCallback(NS, "OnProfileChanged", onProfile)
NS.db.RegisterCallback(NS, "OnProfileCopied",  onProfile)
NS.db.RegisterCallback(NS, "OnProfileReset",   onProfile)
```

The perf probe takes the other hold itself; a host never writes `Hold("perf")`.

## What survives a stand-down

Not this module's decision, but the reason the seam is shaped this way: `standDown` tears down
*features*, never *setup*. The chat command registration, the dispatcher and the `COMMANDS` table;
the settings-category registration and the panel body; the AceDB handle, the single write seam and
AceDB's profile callbacks; the launcher's registration — all of these stay, because a disabled addon
still has to be reachable by the player who wants to enable it again.

The one sanctioned exception on the teardown side is a hook that cannot be undone:
`hooksecurefunc` has no un-hook, so such a hook gates its own body and returns. A raw hook or an
AceHook hook **must** be un-hooked, because it can be.
