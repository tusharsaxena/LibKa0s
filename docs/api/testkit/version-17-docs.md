# `testkit` — version 17

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **17** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.31.0 |
| Status | **Current** |
| Supersedes | [version 16](version-16-docs.md) — `AceGUI:Release`, AceEvent's event half on an embed, `Printf`, and the runner's mode in every consumer |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `17` |

## What changed at this version

Six consumer harnesses replaced the kit's Ace fakes wholesale — BankLedger's `NewAddon` and
`AceEvent:Embed`, ConsumableMaster's four Ace libraries, KickCD's whole LibStub, PanelMaster's and
WhatGroup's `NewAddon` — so revision 16 reached none of their suites, and no later revision would
either. The owner decided on 2026-09-12 that they migrate **onto** the kit's fakes rather than keep
their copies (BankLedger#18 and #19, ConsumableMaster#38, KickCD#21, PanelMaster#50, WhatGroup#19).
That only works if the kit models what those copies were written to model. This revision is that
surface.

**What goes in is generic behavior, checked against the real Ace3 source** — `AceAddon-3.0.lua`
minor 13, `AceEvent-3.0.lua` minor 4, `CallbackHandler-1.0.lua` minor 8, `AceTimer-3.0.lua` minor
17, `AceConsole-3.0.lua` minor 7 and `AceGUI-3.0.lua`, as vendored in the consumers' `libs/`. Anything
addon-specific stays in the consumer, layered over the kit; [below](#for-the-six-migrations-what-stays-local)
is the list, per consumer.

Two files change: `mock_base.lua`, and `framework.lua`, which changes only its revision number.
`loader.lua`, `vendor_sync.lua`, `test_eol.lua` and `run-automated-tests.sh` are untouched.

| | At 16 | At 17 |
|---|---|---|
| `NewAddon([object,] name, lib, ...)` | Ignored the name and the list; stamped the event half, a no-op `RegisterChatCommand`, a fire-once `ScheduleTimer`, `Print` and `Printf` on everything | **Honors the list**: embeds exactly the named libraries, through `LibStub`, as `EmbedLibraries` does. Names the object, registers it with `GetAddon`, stamps AceAddon's fourteen mixins, queues it for the lifecycle |
| `NewAddon(target)` — exactly one argument, a table | As above | **Unchanged** — revision 16's behavior, kept for safety (see [Divergences](#two-deliberate-divergences)). Any other call without a string name raises |
| Modules | None | `NewModule` with prototypes, default libraries and default state; `GetModule`, `EnableModule`, `DisableModule`, `IterateModules`, `orderedModules` |
| Lifecycle | None | `ADDON_LOADED` / `PLAYER_LOGIN` on `AceAddon.frame`; `InitializeAddon`, `EnableAddon`, `DisableAddon`; `OnEmbedEnable` / `OnEmbedDisable` on every embedded library |
| AceEvent messages | `RegisterMessage(msg, fn)`, function handlers only; `UnregisterMessage`; `SendMessage` | CallbackHandler's rules: string methods, the default method named after the message, the optional `arg`, validation, **`UnregisterAllMessages`**, a registration made mid-dispatch applied when the dispatch ends, `AceEvent:SendMessage`, `M.__msgRegistry` |
| AceEvent events | Recorded on `t.__events`, validated | The same recorder, plus a real registration: **`M.__fireEvent(event, ...)`** dispatches the way AceEvent's frame does, and **`M.__badEvents`** makes the client refuse an unknown event |
| AceTimer | `Embed` returned the target untouched | A real surface: `ScheduleTimer`, `ScheduleRepeatingTimer`, `CancelTimer`, `CancelAllTimers`, `TimeLeft`, on the kit's queue |
| `M.__fireTimers()` | Ran every queued entry; answered nothing | **Skips a canceled entry** and answers how many ran. `C_Timer.NewTimer`'s `Cancel` is honored |
| AceConsole | `Embed` returned the target untouched | `Print`, `Printf`, `RegisterChatCommand`, `UnregisterChatCommand`; `AceConsole.commands`; `AceConsole:__slash(command, input)` |
| AceGUI | `WidgetRegistry`, `__widgetVersions` | Also `WidgetVersions` (the same table, under its real name), `LayoutRegistry`, `RegisterLayout`, `GetLayout` |

What did **not** change matters as much: `GetHeight` and `GetWidth` still answer 0 for every frame
nobody armed. See [Revision 17 is not the geometry flip](#revision-17-is-not-the-geometry-flip).

### AceAddon: `NewAddon` honors its mixin list

`AceAddon:NewAddon([object,] name, lib, ...)` follows `AceAddon-3.0.lua`:

1. **The name is validated.** A name that is not a string raises `'name' - string expected`; a name
   already registered in this build raises `Addon '<name>' already exists`.
2. **The object is named.** `object.name = name`, and its metatable gains `__tostring` returning the
   name, copied onto any metatable the object already had. So `tostring(addon)` is the name, and so is
   the green prefix `addon:Print(...)` renders — as in the client.
3. **The object model is stamped.** `modules`, `orderedModules`, `defaultModuleLibraries`, the
   fourteen mixins (`NewModule`, `GetModule`, `Enable`, `Disable`, `EnableModule`, `DisableModule`,
   `IsEnabled`, `SetDefaultModuleLibraries`, `SetDefaultModuleState`, `SetDefaultModulePrototype`,
   `SetEnabledState`, `IterateModules`, `IterateEmbeds`, `GetName`) and, where the object has none,
   `enabledState = true`, `defaultModuleState = true` and `IsModule`.
4. **Exactly the listed libraries are embedded**, each through `M.LibStub(name, true)` read at call
   time and its own `:Embed(object)`, as `EmbedLibrary` does. An unknown library raises
   `Cannot find a library instance of "<name>"`; one with no `Embed` raises `is not Embed capable`.
   A consumer that wraps or replaces a fake in `M.__libs` therefore gets its version embedded, and one
   that replaced `M.LibStub` gets its own registry consulted.
5. **The object is queued** for initialization.

`NewAddon(name, lib, ...)` — a string first — builds the object itself. `AceAddon:GetAddon(name,
silent)` finds an addon by name, raising for a missing one unless `silent`. `IterateAddons`,
`IterateAddonStatus`, `EmbedLibrary` and `EmbedLibraries` are the real ones. **The fake never reads
its receiver**, so a consumer that wraps it and calls through with its own table as `self` is
served, not broken.

An addon that forgot to list `AceTimer-3.0` and calls `self:ScheduleTimer` now hits a nil field
headlessly, exactly where it would in the client. At 16 the kit stamped every mixin on every addon, so
that addon passed.

### AceAddon: modules

`addon:NewModule(name, [prototype | lib], lib, ...)` builds a child addon named
`"<Parent>_<name>"`, registered with AceAddon under that name, with `moduleName = name`, `IsModule()
== true` and its enabled state from the parent's `defaultModuleState`. It embeds the listed libraries
and then the parent's `defaultModuleLibraries`. A table first argument, or the parent's
`defaultModulePrototype`, becomes the module's `__index`. `OnModuleCreated(parent, module)` is called
when the parent has one. The module is recorded in `modules[name]` and appended to `orderedModules`.
A non-string name, a prototype that is not a table, string or nil, and a second module under one name
all raise as the real one raises; so do the three `SetDefaultModule*` setters once a module exists.

### AceAddon: the lifecycle, driven the way the client drives it

The kit does what AceAddon's own frame does on `ADDON_LOADED` and `PLAYER_LOGIN`, so a test drives
it with the seam every frame already has:

```lua
local AceAddon = mocks.LibStub("AceAddon-3.0")
AceAddon.frame:__fire("OnEvent", "ADDON_LOADED", "MyAddon")  -- OnInitialize, no enabling yet
AceAddon.frame:__fire("OnEvent", "PLAYER_LOGIN")             -- initialize the rest, then enable
```

- Each pass initializes everything queued, in queue order — the addon first, its modules after it,
  in creation order — calling `OnInitialize` and each embedded library's `OnEmbedInitialize`.
  `ADDON_LOADED` records its argument as `addon.baseName` and ignores the six early-loading Blizzard
  addons the real one ignores.
- Once the client is logged in, each pass then enables everything queued. "Logged in" is
  `M.IsLoggedIn()`, read at call time where the environment models it, or the kit's own flag once
  `PLAYER_LOGIN` has fired — so an `ADDON_LOADED` that arrives after the login enables a
  load-on-demand addon, as the client's does. **`EnableAddon` runs the
  addon's `OnEnable` first, then `OnEmbedEnable`, then enables its `orderedModules` in order**,
  skipping any whose `enabledState` is false and any already enabled.
- `addon:Enable()` on an object still waiting to be initialized only records the state, as the real
  one does. `addon:Disable()` runs `OnDisable`, then each embedded library's `OnEmbedDisable`, then
  disables every module. It answers true once it has disabled and false when there was nothing to do.

A harness that wants only the enable cascade — KickCD's and MultiMeters' `__enableAll` — calls
`AceAddon:EnableAddon(addon)`, the real public member the login pass calls per addon.

**`OnEmbedDisable` does the real teardown.** AceEvent's unregisters every event and message the
target holds; AceTimer's cancels every timer it owns; AceConsole's unregisters its non-persistent
chat commands. So "disabling the addon silences it" is assertable without the addon doing it by hand.

### AceEvent: two CallbackHandler registries

AceEvent is a thin wrapper over two CallbackHandler registries, one for game events and one for
messages, and the kit now has one of each. Every dispatch rule a consumer had hand-rolled is
CallbackHandler's:

| Registration | Stored | Called on dispatch as |
|---|---|---|
| `t:RegisterMessage(msg, fn)` | `fn` itself | `fn(msg, ...)` |
| `t:RegisterMessage(msg, fn, arg)` | a closure | `fn(arg, msg, ...)` |
| `t:RegisterMessage(msg, "Method")` | a closure | `t:Method(msg, ...)` |
| `t:RegisterMessage(msg)` | a closure | `t[msg](t, msg, ...)` — the method named after the message |

The same four forms apply to `RegisterEvent`. A registration CallbackHandler refuses raises with its
message: a message that is not a string, a method that is neither a string nor a function, a string
naming no function on the target. `UnregisterMessage` raises for a non-string. One callback is kept
per (message, target), so a second registration on the same target overwrites the first, and a
`SendMessage` from any target reaches every target registered — the architecture-§4 shape.

**`t:UnregisterAllMessages()`** drops every message registration the target holds and nobody else's,
and leaves its events alone, as `UnregisterAllEvents` leaves its messages. Like CallbackHandler's it
takes any number of targets — `AceEvent.UnregisterAllMessages(a, b)` — and refuses none, or the
library alone. The library object carries the registration API as CallbackHandler publishes it:
`AceEvent.RegisterMessage("addonId", msg, fn)` registers under an addon-id string,
`AceEvent.UnregisterMessage` and `AceEvent.UnregisterAllMessages` undo it, and a method **name**
registered with the library itself as `self` raises `do not use Library:RegisterMessage(), use your
own 'self'`. **`AceEvent:SendMessage`**, on the library itself, fans out like any target's.

**A NEW registration made while a registry is dispatching waits for the dispatch to finish.** The
newcomer does not hear the message already in flight and hears the next one. That is CallbackHandler's
queue, and it also means a handler that registers a new callback can no longer disturb the traversal
it is running inside. An existing registration overwritten mid-dispatch takes effect at once, as it
does in the client.

**`M.__msgRegistry`** publishes the message registry: `[message] = { [target] = callable }`, where the
callable is what the table above says is stored. BankLedger and PanelMaster already read a table by
that name from their own buses; after migrating, it is the kit's.

**One divergence, kept.** CallbackHandler dispatches through `securecallfunction`, which hands a
handler's error to the error handler and carries on. The kit carries on too — every other handler
still runs — and then raises the **first** error out of `SendMessage` (or `M.__fireEvent`), the same
shape as the lifecycle cascade. A harness that swallowed it would be a stub that silently succeeds.

### AceEvent: firing a game event, and the events the client does not know

The event recorder is unchanged: `t.__events[event]` is still the handler as given, or `true`, and
the three event functions are still the same objects on every target. What is new is that each
registration is also made in the events registry, which gives two things.

**`M.__fireEvent(event, ...)`** dispatches a game event the way AceEvent's frame does: to every target
registered for it, in the forms above. A string method is called as `t[method](t, event, ...)`, and a
registration with no handler calls the method named after the event. It answers how many handlers ran,
so a case can assert the wiring and the behavior in one act. This is what WhatGroup's `fireAddonEvent`
and LootHistory's `target.__events[event](event, ...)` each hand-rolled. Several events routed to one
shared method still tell it which edge fired, because the event name is always the first argument
after `self`.

**`M.__badEvents`** is a set of event names this fake client does not know. Registering one raises
`Attempt to register unknown event "<NAME>"`, as retail's `frame:RegisterEvent` does. It raises where
the client raises: from AceEvent's `OnUsed`, which runs **after** CallbackHandler has stored the
callback and **only for the event's first registrant**. So the registration stays in `__events` after
the raise, and a second target registering the same event does not raise — because in the client it
does not either. BankLedger and PanelMaster each carried this table under this name; it is read at
call time, so a test that swaps it is heard. It is empty by default.

### AceTimer, on the kit's one queue

`AceTimer:Embed(t)` stamps the five real mixins. They follow `AceTimer-3.0.lua`:

| Call | Does |
|---|---|
| `t:ScheduleTimer(func, delay, ...)` | Queues a one-shot. `func` is a function or the name of a method on `t`, called with the extra arguments. Raises without a callback or a delay, and for a method `t` does not carry |
| `t:ScheduleRepeatingTimer(func, delay, ...)` | The same, and it re-queues itself after each run until canceled — from inside its own callback too |
| `t:CancelTimer(handle)` | Answers true and cancels a live timer; answers false for one already run or canceled |
| `t:CancelAllTimers()` | Cancels every live timer `t` owns, and nobody else's |
| `t:TimeLeft(handle)` | `handle.ends - GetTime()`, or 0 for a timer no longer live |

**The queue is the kit's own.** The real library schedules through `C_Timer.After`, and the kit's
`C_Timer.After` is a push onto `M.__timers`, so a timer lands there as
`{ fn = handle.callback, delay = <delay>, timer = handle }` and `M.__fireTimers()` runs it. It is pushed
**directly**, not through `M.C_Timer.After`, because the real library captured `C_Timer.After` when it
loaded: a consumer that later replaces `C_Timer.After` with a no-op — BankLedger and PanelMaster both
do, to keep another deferral from running — must not silence AceTimer with it.

The handle is AceTimer's own table: `object`, `func`, `looping`, `delay`, `ends`, `callback` and the
arguments. `delay` is floored at 0.01, as the real one floors it for `C_Timer`. `GetTime` is read at
call time, so a harness that pins its own clock is honored. **A canceled handle carries
`handle.cancelled = true`, AceTimer's own field name.** It is a third-party API identifier, not prose,
and renaming it would let a suite written against the real field read nil and pass; the prose gate
carries a ratified exemption for exactly this identifier, recorded in LibKa0s's `CLAUDE.md` →
*Documented deviations* (owner decision, 2026-09-12).

**A repeating timer keeps its period when the test does not move the clock.** AceTimer takes "how
late was this run" off the next delay. In the client a run is never early; headlessly a pass runs
wherever the test left `M.__now`, usually before the due time, and read unclamped that grew the delay
and `TimeLeft` by a period every pass. The kit clamps the "now" it compensates from to the due time,
so an on-time run re-queues at its own delay, and takes `ends` from the clock as the real one does.

### `M.__fireTimers()` honors cancellation

It runs every entry that was due and answers **how many actually ran**. An entry is skipped when it
was canceled: a `C_Timer.NewTimer` handle through its own `Cancel` (which revision 16 made a no-op; the
handle also answers `IsCancelled()`, as the client's does), the no-name `NewAddon` path's handle
through its `CancelTimer`,
an AceTimer handle through `CancelTimer`. So "three events, one reconcile pass" and "the pending timer
was canceled" are both assertable against the kit — the two things BankLedger's and PanelMaster's
own `__fireTimers` existed to make assertable. A `C_Timer.After` entry cannot be canceled, as in the
client. An entry queued while the pass runs waits for the next pass, as before.

### AceConsole

`AceConsole:Embed(t)` stamps `Print`, `Printf` — the same shared local revision 16 introduced —
`RegisterChatCommand` and `UnregisterChatCommand`. `GetArgs`, the fifth real mixin, is left out: it is
a quoted-string and hyperlink parser nothing in the collection calls, and an untested reimplementation
of it would be a subtly wrong shared helper waiting to be adopted.

`t:RegisterChatCommand(command, func, persist)` validates the command, records
`AceConsole.commands[command] = "ACECONSOLE_<COMMAND>"`, keeps the handler — a function, or a closure
calling `t[func](t, input, editBox)` — and answers true. **`AceConsole:__slash(command, input)`** runs
it the way typing `/command input` would, and raises for a command nobody registered.

The client writes the handler into the global `SlashCmdList` and the alias into
`SLASH_ACECONSOLE_<COMMAND>1`. The kit does the same **only where the environment already models
`SlashCmdList` as a table**. Inventing the global would flip the branch of any host that checks for
it, and MultiMeters asserts its mock has none. A non-persistent command (`persist == false`) is
recorded as the real one records it, and `OnEmbedDisable` / `OnEmbedEnable` unregister and restore it.

### AceGUI

`AceGUI.WidgetVersions` is now published beside `__widgetVersions` — **the same table**, under the name
the real library uses — so a host that reads AceGUI's own field sees what `RegisterWidgetType` wrote.
`AceGUI:RegisterLayout(name, fn)` records into `AceGUI.LayoutRegistry` under the upper-cased name and
raises for a layout that is not a function, and `AceGUI:GetLayout(name)` reads it back
case-insensitively, as the real pair does.

### Two deliberate divergences

1. **`NewAddon(target)` — exactly one argument, a table — keeps revision 16's behavior.** The real
   AceAddon raises on it. PrettyChat's and WhatGroup's harnesses called it that way on `master`; on
   their `fix/2026-09-12-triage` branches both now pass the name, so the path is kept for safety only.
   It stamps the event half, `RegisterChatCommand`, the fire-once `ScheduleTimer`, a `CancelTimer`
   that `__fireTimers` honors, `Print` and `Printf`, and none of the object model. **Anything else
   without a string name** — `NewAddon({}, nil, "AceEvent-3.0")`, a bare `NewAddon()` — goes through
   the real validation and raises.
2. **An error inside `OnInitialize`, `OnEnable`, `OnDisable` or `OnModuleCreated` is reported after
   the cascade, not swallowed.** The client catches it, hands it to `geterrorhandler()` and carries on
   with the next object. The kit catches it and carries on too, then raises the **first** such error
   from the outermost call once the cascade has finished — the login pass, `Enable`, `Disable`,
   `NewModule`. The siblings after it have still run, as in the client; the difference is only that
   the error is loud. A headless error handler that swallowed it would pass every suite.

### Revision 17 is not the geometry flip

[Version 16](version-16-docs.md#revision-16-is-not-the-geometry-flip) moved the flip — deleting the
`self.__geomLive and` from `GetHeight` and `GetWidth` — to "the next revision that ships it alone, 17
at the earliest". **Revision 17 does not ship it either.** It carries the harness surfaces six
consumers migrate onto, which the owner accepted on 2026-09-12 as revision 17's content. A frame nobody
armed still answers 0, and `tests/test_mock_base.lua`'s first case still pins that. The plan behind the
number is unchanged — the flip is its own revision, with its own adoption, shared with nothing, because
roughly 308 test files across ten repositories lean on geometry answering zero — so only the number
moves again: **18 at the earliest**. The comment in `mock_base.lua` says so as well.

## For consumers: nothing moves

**Measured, not assumed.** This revision's `testkit/` was dropped into fresh clones of all ten
consumers, and each was measured against a baseline taken at **the same commit** with revision 16's
kit — several consumers' `master` moved during the day, so a baseline from the morning would have
compared two different trees. Then the whole v1.31.0 payload, `LibKa0s/` into `libs/LibKa0s/` as well,
was measured again. Every row is identical in all three runs:

| Consumer | Commit | Rev 16 | Rev 17 | Rev 17 + v1.31.0 `libs/` |
|---|---|---|---|---|
| AbsorbTracker | `5bf0af8` | 563 / 2 skipped / 565 | 563 / 2 / 565 | 563 / 2 / 565 |
| AuraMaster | `ac356e9` | 249 / 2 / 251 | 249 / 2 / 251 | 249 / 2 / 251 |
| BankLedger | `5f42f5c` | 848 / 2 / 850 | 848 / 2 / 850 | 848 / 2 / 850 |
| ConsumableMaster | `541ebd8` | 795 / 2 / 797 | 795 / 2 / 797 | 795 / 2 / 797 |
| KickCD | `bb94a5b` | 886 / 2 / 888 | 886 / 2 / 888 | 886 / 2 / 888 |
| LootHistory | `0222fef` | 719 / 2 / 721 | 719 / 2 / 721 | 719 / 2 / 721 |
| MultiMeters | `8b5b417` | 1762 / 2 / 1764 | 1762 / 2 / 1764 | 1762 / 2 / 1764 |
| PanelMaster | `9c9e5ba` | 783 / 2 / 785 | 783 / 2 / 785 | 783 / 2 / 785 |
| PrettyChat | `61ff810` | 331 / 2 / 333 | 331 / 2 / 333 | 331 / 2 / 333 |
| WhatGroup | `3887767` | 571 / 2 / 573 | 571 / 2 / 573 | 571 / 2 / 573 |

The two skips in every row are the vendored-payload pair cases: the clones had no sibling LibKa0s.

**Four consumers reach the new `NewAddon` path**, because their harnesses call the kit's `NewAddon`
with a name: AbsorbTracker and AuraMaster directly, LootHistory and MultiMeters through wrappers. All
four list `AceEvent-3.0`, `AceTimer-3.0` and `AceConsole-3.0` in production, so each addon object
still carries every mixin it had — and now the message half, `UnregisterAllMessages`, a timer whose
cancel is honored, and the object model. Nothing in their suites moved. **PrettyChat and WhatGroup
reach the no-name path** and see revision 16 exactly. **BankLedger, ConsumableMaster, KickCD and
PanelMaster** still replace the fakes, so nothing reaches them until they migrate — which is what
the next section is for.

One thing was caught by the measurement rather than by this repo's suite. PanelMaster's harness wraps
`AceEvent:Embed` with a table of its own and calls the kit's through, so the kit's Embed ran with the
wrapper as `self`; a first draft that read `self.embeds` raised on PanelMaster's first bus target.
No fake reads its receiver now, and `tests/test_mock_ace.lua` pins the wrapper shape for all three
Embeds.

### Re-measured after the v1.31.0 review

The review changed the kit before release: `handle.cancelled` under AceTimer's own name, the no-name
path narrowed to a lone table, a repeating timer's period held when the clock does not move, the
no-name `CancelTimer` honored, a handler error no longer ending a dispatch, `IsLoggedIn` read at call
time, and the message registration API on the AceEvent library. Six harnesses had migrated or were
migrating onto the pre-review kit 17 on their `fix/2026-09-12-triage` branches, so the measurement
was taken there, three ways per consumer: as the branch stands (nine vendor the pre-review kit 17,
MultiMeters still kit 16), with the pre-review v1.31.0 payload dropped in, and with the reviewed
payload — kit and `libs/LibKa0s/` both.

| Consumer | Branch tip | As the branch stands | Pre-review v1.31.0 | Reviewed v1.31.0 |
|---|---|---|---|---|
| AbsorbTracker | `d6a2637` | 563 / 2 / 565 | 563 / 2 / 565 | 563 / 2 / 565 |
| AuraMaster | `7618fc8` | 250 / 2 / 252 | 250 / 2 / 252 | 250 / 2 / 252 |
| BankLedger | `f52326a` | 855 / 2 / 857 | 855 / 2 / 857 | 855 / 2 / 857 |
| ConsumableMaster | `d4e5af9` | 832 / 2 / 834 | 832 / 2 / 834 | 832 / 2 / 834 |
| KickCD | `c6aad74` | 899 / 2 / 901 | 899 / 2 / 901 | 899 / 2 / 901 |
| LootHistory | `c829724` | 722 / 2 / 724 | 722 / 2 / 724 | 722 / 2 / 724 |
| MultiMeters | `fa24bc5` | 1773 / 2 / 1775 | 1773 / 2 / 1775 | 1773 / 2 / 1775 |
| PanelMaster | `5f04c5f` | 787 / 2 / 789 | 787 / 2 / 789 | 787 / 2 / 789 |
| PrettyChat | `d11e92f` | 331 / 2 / 333 | 331 / 2 / 333 | 331 / 2 / 333 |
| WhatGroup | `abeebff` | 577 / 2 / 579 | 577 / 2 / 579 | 576 / **1 failed** / 2 / 579 |

**WhatGroup is the one that moves, and it is the spelling decision itself.** Its migrated
`tests/test_notify.lua:159` reads `firstHandle.canceled` — the pre-review kit's spelling — so
`notify: a re-fire cancels the in-flight timer so two can't race` goes red when the field becomes
AceTimer's own. The port is that one identifier; with it made, the branch is 579 / 0 failed / 2
skipped on the reviewed payload. Nothing else moves anywhere.

## For the six migrations: what stays local

Each consumer layers over the kit what is genuinely its own. The layering is the consumer's change,
made in its own repository after it re-vendors revision 17; nothing in this release makes it.

**BankLedger (#18, #19).** Takes from the kit: `NewAddon` (its production list is all three
libraries), the validated event half, `M.__badEvents`, the message half with `UnregisterAllMessages`
and `M.__msgRegistry`, AceTimer with cancellation, and `M.__fireTimers`' count. Keeps: its frame stub
(real geometry, OnHide, recorded `SetTexture`/`SetText`, frames shown by default), the
`defaultedStore` AceDB, `__settingsPanels`, the plain-table `DEFAULT_CHAT_FRAME`, the nil `GameTooltip`
and `StaticPopup_Show`, the `SetTitle` wrap on AceGUI, `LibStub.minors`, the no-op `C_Timer.After`
and the fixed clock. Test ports: `handle.canceled` reads `handle.cancelled`, `handle.callback` reads
the same; the
unknown-event message text differs, which nothing asserts. **`tests/test_ledger.lua`'s `reEnable`
re-registers the same events on `NS.addon` under a different `__badEvents` set in one build**, and
under the client's first-registrant rule an event already registered does not raise again — so that
helper unregisters the addon's events first, or builds fresh.

**ConsumableMaster (#38).** Takes from the kit: `NewAddon` (its list is AceEvent and AceConsole),
the recorded event half — which finally covers `core/PerfSetup.lua:57`'s guarded
`UnregisterAllEvents` — the message half with string-method dispatch, `GetAddon`, and AceGUI's
`__created`, `WidgetVersions`, `RegisterLayout` and `Release`. Keeps: publishing the addon as
`_G.KCM` (a thin wrapper around the kit's `NewAddon`), its AceDB with profiles and callbacks, its
permissive widget (`label`/`text` FontStrings, `__text`/`__label` recorders) as a wrap on
`AceGUI:Create`, `GetWidgetVersion` answering 0 for an unregistered type (the real one answers nil),
the LibSharedMedia fake registered into `M.__libs`, and its lenient LibStub, which answers nil for an
unknown major without the silent flag, as a wrapper over the kit's. Test ports: `M.busReg`
(unresolved handler names) becomes `M.__msgRegistry` (callables); `GetAddon` answers by name.

**KickCD (#21).** Takes from the kit: `NewModule`, `GetModule`, `EnableModule` and the module
lifecycle, message dispatch through string methods (its `resolveCallback`), the event half,
`AceGUI:Release`, AceConsole and `GetAddon`. It stops replacing LibStub: its non-Ace fakes
(LibSharedMedia, LibCustomGlow, the AceConfig trio, AceDBOptions, CallbackHandler) are registered into
`M.__libs`. Keeps: `__enableAll` as a one-line layer, `AceAddon:EnableAddon(self)` — the same order
its own had, addon first; its AceDB stubs; its frame model; its `C_Timer` queue of plain functions and
`__flushTimers` (production embeds no AceTimer); the `SetHighlight` recorder, as a wrap on
`AceGUI:Create`. Test ports: `tests/test_state.lua:103`'s `mocks.__embedAceEvent(t)` becomes
`LibStub("AceEvent-3.0"):Embed(t)`; `__busRegistry` becomes `M.__msgRegistry`.

**PanelMaster (#50).** Takes from the kit: `NewAddon` with the per-target recorded event half,
`UnregisterAllEvents`, `Printf`, `M.__badEvents`, AceTimer with cancellation and the queue's count,
and the message half with `M.__msgRegistry`, which retires its `embedBus`. Keeps: the frame stub,
`__switchProfile` AceDB, the `DEFAULT_CHAT_FRAME` capture, the Settings registry, `C_AddOns`,
`UnitClass`, the `SetTitle` and `editbox` wraps on AceGUI, the AceConfig and AceDBOptions fakes, and
the no-op `C_Timer.After`. Test ports: `tests/test_panel.lua:60`'s `M.__events["PLAYER_LOGIN"]` reads
`NS.addon.__events["PLAYER_LOGIN"]`; `tests/test_slash.lua:22-23`'s `M.__chatCommands` reads
`LibStub("AceConsole-3.0").commands`, or keeps a one-line recorder wrapped round the kit's
`RegisterChatCommand`. Its `Print` that **returns** its string is the one piece with no kit
counterpart — the real one returns nothing — and stays local only if a case reads the return.

**WhatGroup (#19).** Takes from the kit: the validated event half on the addon object (its wrapper
forwards the name and the list, leaving the no-name path), `M.__fireEvent` in place of
`fireAddonEvent`, `GetAddon`, the real `Enable` / `Disable` in place of its no-op stamps, and AceTimer,
repeating timers included. Its two queues stay separate for free: its `C_Timer.After` pushes onto its
own `mock.timers`, and the kit's AceTimer pushes onto `M.__timers`, so `fireAceTimers` becomes
`M.__fireTimers`. Keeps: the stateful frame stub with protection and combat refusal, the AceGUI wrap
(the `label` FontString, the `Fire` alias, the richer ScrollFrame), `hooksecurefunc` recording,
`C_LFGList`, the Settings registry and `mock._G = mock`. Test ports: `mock.addonEvents[...]` reads
`addon.__events[...]` — an explicit handler name is recorded identically, so the
`== "OnCombatStateChanged"` assertions hold; a handle's `repeating` reads `looping`;
`mock.chatCommands` reads `AceConsole.commands`; a handle's `canceled` reads `cancelled`.

### What the kit declined

**Known fidelity gaps, recorded rather than fixed.** Three places the kit still differs from the real
Ace3, none of which any consumer in the collection reaches today:

- **The library object's `RegisterEvent` family.** CallbackHandler publishes `RegisterEvent`,
  `UnregisterEvent` and `UnregisterAllEvents` onto the AceEvent library itself as well as onto every
  embed. The kit's library object carries the message family only; events are registered on a target.
- **When `IsLoggedIn` is read.** `AceAddon-3.0.lua` asks `IsLoggedIn()` after the initialize loop
  (its line 623); the kit reads it once, before that loop. The two differ only for an `OnInitialize`
  that changes the answer.
- **The no-name path's `CancelTimer` return value.** AceTimer's answers true for a live timer and
  false otherwise; the revision-16 stand-in the no-name `NewAddon` path stamps marks the handle and
  answers nothing.

- **`AceConsole:GetArgs`.** A parser nothing in the collection calls; see [AceConsole](#aceconsole).
- **`SetTitle` on AceGUI container widgets.** BankLedger and PanelMaster each add it, recording to
  different fields (`titleText`, `title`). Both wraps are guarded `if not w.SetTitle`, so a kit
  `SetTitle` would silently win over both and turn PanelMaster's reads red. It stays in the two wraps
  until it can land with both consumers' ports.
- **`LibStub:NewLibrary`'s second return.** The real one answers the **old** minor; the kit's answers
  the new one. It was found during this work and is not fixed in it: BankLedger's `LibStub.minors`
  wrapper reads that return as the registered minor, so the fix changes a consumer's harness and is
  a revision of its own.
- **`C_Timer.NewTimer`'s callback argument.** The client hands a `NewTimer` callback its handle; the
  kit's calls it with nothing, as every revision has. Nothing in the collection reads it, and passing
  it would change the arguments every existing `NewTimer` callback receives.
- **Multi-target `UnregisterAllEvents`.** CallbackHandler's takes several targets for events too.
  The event trio is the module-level set revision 16 made identical on every target, and it keeps the
  one-target form; `UnregisterAllMessages` takes several.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

Nothing to switch on and nothing to delete: the total does not move. The migrations above are each
consumer's own follow-up change, filed as its issue, and each is a harness change with its own test
ports rather than part of the re-vendor.

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
