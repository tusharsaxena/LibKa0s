# `LibKa0s-Sim-1.0` — version 2.2.2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Sim surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Sim-1.0` |
| Files and minors | `Sim.lua` **2** · `SimTimeline.lua` **2** · `SimPanel.lua` **2** |
| Version key | `<Sim>.<SimTimeline>.<SimPanel>`, in load order — the numbers `lib.MODULES` reports |
| Shipped in | v1.75.0 |
| Status | **Current** |
| Supersedes | [2.2.1](./version-2.2.1-docs.md) (carried only by the local `v1.75.0` tag before the release), which superseded [1.1.1](./version-1.1.1-docs.md) (the same; earlier keyed `1`, then `1.1`, on the release branch, and no release carried either key) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (no Core member is called); `SimTimeline.lua` needs nothing beyond the shell; `SimPanel.lua` has an attach-file floor of `LibKa0s-Core-1.0` ≥ 9 and `LibKa0s-Widgets-1.0` present (*The panel*, below) |
| Confirm in-game | `LibStub("LibKa0s-Sim-1.0").MODULES` → `{ Sim = 2, SimTimeline = 2, SimPanel = 2 }` |

## What changed at this version

**`SimPanel.lua` minor 2: the picker reads its scenario at use (a third contract gap DropWatcher's
migration found, its item DW-04).** **No member is added or removed**, and the members manifest
lists the same surface.

- **The panel's scenario is read at use, not at `New`.** Minor 1 read `d.scenarios.names[1]` once,
  inside `New`, to seed the picker, so a host that fills its scenarios after `New` (legal since
  `Sim.lua` 2) got a picker choice of nil for good: an idle Start row reading `Start: nil`, and a
  picker whose `START` ran `start nil`. Now the panel's scenario is the picker's choice while that
  def resolves, else the first name `d.scenarios.names` lists **when the rows are composed or the
  button is pressed**: the idle Start row, its preview steps, its command, its click, the picker's
  selected value, its size dropdown, its `START` button and that button's tooltip all read it. A
  picked scenario the host later drops from `defs` falls back the same way.
- **Nothing listed yet: the Start row is inert.** While `d.scenarios.names` is empty the idle Start
  row is `locked` and not actionable (label `PANEL_START` with an empty name, command
  `slash .. " start"`), the picker's `START` is disabled, and no preview steps are drawn. At minor 1
  that row was `ready` and ran `start nil`, which printed `UNKNOWN_SCENARIO`.
- **An audit of every other descriptor read** found none fixed at `New` that a host can fill
  later; *What is read at use, and what is fixed* (under *Descriptor*, below) is the list.

The key moves `2.2.1` -> `2.2.2`. Key `2.2.1` was carried by the local `v1.75.0` tag the adopters'
run branches re-vendored from, so its document is kept, Superseded, rather than renamed.

**Previously, at `2.2.1`** (the local `v1.75.0` tag only): **`Sim.lua` minor 2 and
`SimTimeline.lua` minor 2: two contract gaps DropWatcher's migration found (its item DW-02).** Both widen what existing members accept; **no member is added or removed**, and
the members manifest lists the same surface.

- **`Start` reads the scenarios at call time.** Minor 1 froze the set of known names when `New`
  ran, so a host that filled `d.scenarios` after `New` (DropWatcher builds its scenario table when
  its world module loads) had every name refused as unknown. Now `Start` reads `d.scenarios.names`
  and `d.scenarios.defs` when it is called, as the step machine, the verbs and the panel already
  did. `New` still checks every entry present when it runs and still accepts an empty `names`
  list. A def listed after `New` is checked on its `Start`, with the checks and the error text `New`
  uses (a missing def, a missing `timeline`, `sizes` that is not a list), naming `Start` instead of
  `New`; it **raises**, as `New` does, because it is a host programming error. `UNKNOWN_SCENARIO`
  lists the live names.
- **`prepare` receives the caller's extra start options.** Minor 1 handed `prepare` a fresh
  `{ scenario, size, seed }`, so a host's own start fields (DropWatcher's `band` and `classFilter`)
  never arrived. Now `prepare`'s `opts` is a shallow copy of the table passed to `Start`, with
  `scenario`, `size` and `seed` set to the resolved values; the caller's table is never written.
  The library reads no other field, the timeline's `opts` stay `{ scenario, size, seed }`, and
  `refusal(opts)` still gets the caller's own table. **`Restart()`** (`SimTimeline.lua`) starts
  again with the same extra fields, every one but `seed`, which is fresh as before. The panel's
  Start row and picker run the typed `start` verb, which has no extra fields, so they are
  unchanged.

The key moves `1.1.1` -> `2.2.1`. Key `1.1.1` was carried only by the local `v1.75.0` tag, which
three adopters' run branches had re-vendored from, so its document is kept, Superseded, rather than
renamed.

**Previously, at `1.1.1`** (the local `v1.75.0` tag only): `SimPanel.lua` minor 1 joined the
major, the third file, paired on the shell's minor (`lib.__panelMinor` / `lib.__panelShellMinor`),
and the version key grew from `1.1` to `1.1.1`. It overwrites the shell's panel fallbacks with the docked step panel (*The panel*, below):
`ShowPanel`, `HidePanel`, `TogglePanel`, `IsPanelShown`, `RefreshPanel`, `ResetPanelPosition` and
`PanelRows`, the picker and the run controls, and the session-only placement. The descriptor's
`panel` fields now draw something: `title`, `stepLabel`, `stepTip`, `startTip`, `stopTip`,
`anchorTo` and `check`. `Sim.STRINGS` gains `PANEL_START`, `START`, `PANEL_STOP`, `RUN_ALL`,
`PAUSE`, `RESUME`, `RESTART`, `STOP`, `RANDOM` and `RAN_AGO`. No member of the shell or of
`SimTimeline.lua` changed. Neither `1` nor `1.1` was released: that document was
`version-1-docs.md`, then `version-1.1-docs.md`, until the key moved, on the release branch (the
unreleased-key rule).

**Previously, at `1.1`** (never released): `SimTimeline.lua` minor 1 joined the major and the key
grew from `1` to `1.1`, overwriting the shell's timeline fallbacks with the step machine and the
`RunVerb` fallback with the typed grammar (*The step machine* and *The verbs*, below).

## What this major is

**The in-client simulator's shell.** A host simulates the client by answering every client read
and every outward action from the simulator while a session runs. The host already routes those
through its own Compat table (compat-§1), so the simulator's whole reach into the host is one
wrap of that table: the seam.

Three hosts simulate this way: DropWatcher wrote the seam first (`core/SimSeam.lua`), and
LootHistory and BankLedger would have copied it. The owner ruled the seam, the session and the step
machine into one major with one set of semantics
([#54](https://github.com/tusharsaxena/LibKa0s/issues/54)), so that a fix to "a guarded member never
reaches the client" is made once.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called**: the gate is there so that a host holding a partial payload gets every module
absent rather than a working half.

## Members

Read straight off the LibStub table.

| Name | Since | Meaning |
|---|---|---|
| `Sim:NewSeam(compat, opts) -> seam` | 1 | Wraps the host's Compat table in place, once, and answers its seam. Below. |
| `Sim:New(d) -> sim` | 1 | Binds one session to a seam and answers its instance. Below. |
| `STRINGS` | 1 | The built-in English lines, every key overridable through `d.L` (below). |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Sim-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Sim = <minor>, SimTimeline = <minor>, SimPanel = <minor> }`: the live minors, and the values that pick this document. |

## The seam: `Sim:NewSeam(compat, opts)`

Call it at file load, in a setup file the TOC loads **straight after** the host's Compat files (a
LOAD-BEARING TOC comment), before any other file can read a Compat member.

### Arguments

| Field | Required | Meaning |
|---|---|---|
| `compat` | yes | The host's own Compat table. Wrapped **in place, once**: a second `NewSeam` on the same table raises. |
| `opts.name` | yes | A non-empty string naming the seam in every error and debug line. |
| `opts.pure` | no | `{[key] = true}`. These members answer for nobody (secret guards, text helpers) and are never wrapped. |
| `opts.guarded` | no | `{[key] = fn}`. The safe answer while a session is active. A key that is not a wrapped member (pure, unknown, or not a function) raises at load, and so does an answer that is not a function. |
| `opts.debug` | no | `fn(tag, fmt, ...)`. The sink `Live` writes a traceback to until a session binds, with the tag `"Sim"`; once one binds, the traceback goes to the session's own `d.debug` as a `SIM` line. Anything but a function or `nil` raises. |

Members of `compat` that are not functions are left alone.

### The wrap rule

Every function member not in `opts.pure` is replaced by a closure whose idle path is one
upvalue-field test:

```lua
if state.active and (g or not state.bypass) then return answer(key, live, g, ...) end
return live(...)
```

`g` is `opts.guarded[key]`. `answer` calls the key's provider as `provider(fallback, ...)`, where
`fallback = g or live`; with no provider it calls `fallback(...)`.

- **Idle cost.** One table read per call, and no allocation (pinned by
  `tests/test_sim_seam.lua`). Arguments, returns and nil holes pass straight through.
- **The active flag is driven only by a bound session.** It is on from `sim:Start` until step (4)
  of the stop; at any other time the seam is idle and every member answers live, guarded members
  included. There is no other route to it, and no test hook.
- **A guarded member never reaches the client while a session is active**, inside `Live` included,
  and a provider's first argument is the guarded answer, never the live member, so no provider can
  reach the client by mistake. Idle, a guarded member calls live.

### Seam members

The seam is a plain table with exactly these four members, colon-called.

| Member | Contract |
|---|---|
| `seam:SetProvider(key, fn)` | Registers the provider `fn(fallback, ...)` for one wrapped key; `nil` releases it. **Raises** on a key that is not wrapped (pure, unknown or not a function): a typo is caught at load. **Raises** when a second non-nil provider is set for a key that already has one, even the same function: two owners of one answer is a bug. Release with `nil` first. A provider that is not a function raises. |
| `seam:Live(fn, ...) -> ...` | Runs `fn(...)` with bypass on: ordinary members answer live, guarded members stay guarded. Nesting-safe, and bypass is restored on every exit. An error is re-raised **with its original value** (`error(v, 0)`, so a table survives and a string gets no second position prefix), after its traceback is written to the debug sink; a sink that raises never masks the error. Nil holes in the returns survive. `fn` that is not a function raises. |
| `seam:Keys()` | The wrapped keys, sorted, as a fresh table each call. For diagnostics and host coverage tests. |
| `seam:Unwrapped()` | The sorted keys of function members of `compat` that are neither pure nor still the seam's wrapper: a member added after `NewSeam`, or one replaced by assignment. **A host suite MUST assert it is empty** after the whole addon loads. A non-function member and a replaced pure member are not escapes. |

## The session: `Sim:New(d)`

Call it when the host's simulator module loads. It binds the seam `d.seam` names: **one seam binds
one session**, and a second `New` on the same seam raises, as does a seam `NewSeam` did not make.

### Descriptor

A missing required field raises in `New`, naming the field (Perf's `required()` style); an optional
field of the wrong type raises the same way.

| Field | Required | Contract |
|---|---|---|
| `name` | yes | The addon folder. Error text, the panel's close-mark folder, and its frame name, `<name>SimPanel`. |
| `seam` | yes | From `Sim:NewSeam`, not yet bound. |
| `slash` | yes | The typed prefix, for example `"/dw sim"`. |
| `deliver` | yes | `fn(event, ...) -> n`. Calls exactly the handlers the client's registration would call for this event, in order, and answers how many ran. **Any string is a legal event name** (`hook:<name>`, `GUILDBANK_FRAME_SHOWN`). Each call is `pcall`ed by the library; per-handler isolation is the host's. |
| `isStoodDown` | yes | `fn() -> bool`, read at call time. |
| `scenarios` | yes | `{ names = {ordered}, defs = { [name] = { label, sizes = {n, ...}?, timeline = fn(def, opts) -> steps } } }`. Every listed name needs a def with a `timeline` function; a name that is not in `names` is unknown to `Start`. **Read at call time** (since 2): `New` checks the entries present when it runs and accepts an empty `names` list, and a host may fill both tables in place afterwards; `Start` checks a def listed after `New` the way `New` would, and raises on the same errors. The panel's picker reads them at use too (since `SimPanel.lua` 2). |
| `prepare` | yes | `fn(session, def, opts, ready)`. Builds the host's world and calls `ready()`, sync or async. `opts` is a shallow copy of the table the host passed to `Start`, with `scenario`, `size` and `seed` set to the resolved values (since 2; at 1 it was a fresh `{ scenario, size, seed }`), so a host's own start fields reach it. The library reads no other field. |
| `play` | yes | `fn(step, session) -> detail?`. Drives one step's events through `sim:Fire`; its answer is the step's `detail`. It runs under `pcall`, and an error pauses the run (*The step machine*). |
| `refusal` | no | `fn(opts) -> line|nil`. Run **inside `seam:Live`**, so it reads the real world; it owns every host rule (stood-down wording, test mode, combat, instance, group, per-scenario prerequisites). The library adds no world rule and relaxes none. An error in it is re-raised by `Start` after `Live` writes its traceback. |
| `gate` | no | `fn(session) -> open, line?`. Checked before every step: by `Step`, by every `Run` tick and by the panel's click-ahead. Closed means the host's world has not settled (LootHistory passes its Reconciler settle, OWNER_SCOPE C.12). With no gate, the gate is always open (DropWatcher). A gate that raises counts as closed and writes a debug line. |
| `stepDelay` | no | A number, or `fn(step) -> seconds`: the pause after `step` before `Run` plays the next one. Default `2`. Read when each timer is set. The library reads no setting: a new simulator passes a fixed constant or a function of the step, with no schema row (OWNER_SCOPE C.11; BankLedger's is `math.max(1.5, step.settle or 0)`). DropWatcher's `sim.stepDelay` setting predates the major and survives its migration as a reader passed here. |
| `verbs` | no | `{ [verb] = { parse = fn(words) -> cmd|nil, run = fn(cmd, sim) -> ok, code, free = bool? } }`: the host's extra verbs, tried after the generic ones (*The verbs*). `words[1]` is the verb, lowercased. |
| `why` | no | `{ [code] = line }`: the line a host verb's failure code prints. |
| `usage` | no | `{ lines }`, printed verbatim after the library's usage. |
| `statusLine` | no | `fn(status, session) -> line|{lines}`, appended to the library's status line. An error in it is a debug line. |
| `stopText` | no | `{ [reason] = line }`. The stop line for a reason, the library's own reasons included. |
| `L` | no | Locale table. Any `STRINGS` key is overridden through `rawget`, so a locale table whose metatable answers an unknown key with the key does not shadow the built-in line. |
| `print` | no | `fn(line)`, read at call time. Default: `DEFAULT_CHAT_FRAME:AddMessage`. |
| `debug` | no | `fn(tag, fmt, ...)`, read at call time, tag `"SIM"`. Default: none. A sink that raises is ignored. |
| `panel` | no | Presentation only: `title`, `stepLabel`, `stepTip`, `startTip`, `stopTip`, `anchorTo`, `check` (*The panel*, below). Any other key raises: there is no `button` and no `tooltip` (the library draws its own button and uses GameTooltip) and no `store` (the panel position is session-only, nothing is written to SavedVariables). OWNER_SCOPE C.7 and C.11. |

### What is read at use, and what is fixed

A host may fill any descriptor table in place after `New`, or assign an optional field for the
first time, and the library reads the new value at its next use: `scenarios` (`Start`, the step
machine, the verbs, the panel and its picker), `verbs`, `why`, `usage`, `statusLine`, `stopText`,
`L`, `print`, `debug`, `refusal`, `gate`, `stepDelay`, `isStoodDown`, `deliver`, `prepare`, `play`,
`slash`, and the `panel` fields `title`, `stepLabel`, `stepTip`, `startTip`, `stopTip` and
`anchorTo`. `tests/test_sim_panel.lua` pins each of them filled after `New`. Fixed, on purpose:

- **`seam`** is bound at `New`: one seam binds one session, and a later `d.seam` is never read.
- **The descriptor's checks** (the required fields, the optional fields' types, the `panel` keys)
  run at `New` only. A field assigned later is not type-checked; every reader guards its type and
  treats a wrong one as absent. A scenario def listed later is checked by `Start` instead.
- **`name`** names the panel's frame (`<name>SimPanel`) and its close mark's addon folder when the
  panel is built, on the first `ShowPanel`: a frame's global name cannot change.
- **`panel.check`** is read when the panel is built, on the first `ShowPanel`, because the done
  mark is a texture created with each row. A host sets it before the panel is first shown.
- **A session's steps** are built from its def's `timeline` once, on the session's first read, and
  are that session's for its life (the timeline is pure; a restart builds them again).

### Instance members

Colon-called. Every member is a closure over the instance's private state; the instance carries no
public `active` or `delivering` field and **no `Live`** (the one `Live` is on the seam).

| Member | Contract |
|---|---|
| `sim:Start(opts) -> ok, line` | `opts = { scenario, size?, seed?, ... }`: any other field is the host's own, passed through to `prepare` untouched (since 2). The scenarios are read when `Start` is called (since 2); a listed scenario whose def is malformed raises, naming the field, as `New` would. Refusals, in this order, each printed and answered `false, line`: (1) an unknown scenario, `UNKNOWN_SCENARIO` with the scenario names as they stand; (2) `ALREADY_RUNNING` (a session is live or stopping); (3) `refusal(opts)`, inside `seam:Live`; (4) the backstop, `isStoodDown()`, `STOOD_DOWN`. Then the session `{ sim = true, scenario, size, seed, startedAt = time(), events = 0 }`, the seam on, `STARTED` printed (formatted with the def's `label`, else the scenario name), `prepare` called under `pcall` with the resolved copy of `opts` and a `ready` bound to this session, and listeners told. `size` is set only when the def has `sizes` (`0`, the default, means random); `seed` defaults to a time-derived integer that differs on every start. A `prepare` error becomes `Stop("error")`; when the session ends inside `prepare`, `Start` answers `false` with no line, the stop line having printed. |
| `sim:Stop(reason) -> bool` | The stop below. `reason` defaults to `"stop"`. Answers `false` when idle and when a stop is already under way. |
| `sim:IsActive()` | True from `Start` until step (4) of the stop. |
| `sim:IsDelivering()` | True only inside `Fire`, nesting-safe; false again once a session that ended inside `deliver` returns. Hosts use it to tell a simulated input from a real one. |
| `sim:Session()` | The live session table, or nil. **Host fields go on this table** (the host bag: a world, members, a log); the library's fields on it are read-only by convention. Timers and internals are not on it. |
| `sim:Fire(event, ...) -> n` | `0` unless a session is active and not stopping. An observed stand-down (`isStoodDown()` true while active) first calls `Stop("standDown")` and answers `0`. Otherwise it counts the event, writes a debug line, sets delivering, `pcall`s `deliver(event, ...)` and restores delivering; an error is a debug line and answers `0`. |
| `sim:After(delay, fn) -> handle|nil` | A session timer (`C_Timer`): nil when idle or stopping. `fn` runs under `pcall`, only while the same session is live. `handle:Cancel()` cancels it **and forgets it**; every live handle is canceled at stop. |
| `sim:OnStopGuarded(fn)` | Registers `fn(session)`, run at stop **while the seam still answers**. Permanent and ordered, normally at file load. |
| `sim:OnStop(fn)` | Registers `fn(session, reason)`, run at stop **after the seam is off**. Permanent and ordered. |
| `sim:DeliverForCleanup(event, ...) -> n` | Delivers through `deliver` **only during the OnStop phase**, with the seam off, and answers `0` at any other time **and while `isStoodDown()`** (OWNER_SCOPE C.3). For undoing an edge the simulation raised. |
| `sim:Status() -> t` | `{ active, scenario, size, seed, startedAt, events, ready, pos, total, playing, paused, settling }`. While idle, or when `SimTimeline.lua` is absent, `pos` and `total` are `0` and the three flags `false`. A fresh table each call; a host merges its own fields into its copy. |
| `sim:AddListener(fn)` | Registers `fn(sim)`, run under `pcall` on every transition: start, ready, step, run, pause, stop (and a gate that closes under a step). Permanent. |

**Fallbacks.** When `SimTimeline.lua` or `SimPanel.lua` has not attached, the instance still
answers every member it owns: `Steps()` and `PanelRows()` answer `{}`, `Step()` answers
`nil, "absent"`, `Run`, `Pause`, `Resume` and `Restart` answer `false, "absent"`, `RunVerb` prints
`NO_TIMELINE` and answers `false, "absent"`, `ShowPanel`, `TogglePanel` and `IsPanelShown` answer
`false`, and `HidePanel`, `RefreshPanel` and `ResetPanelPosition` do nothing. The attach files
overwrite them through an internal handshake (`lib.__AttachTimeline`, `lib.__AttachPanel`, and the
ctx table `New` hands both) that is not contract. At this version both attach in a full payload;
`SimPanel.lua` stays out when its attach-file floor is unmet, and the panel members are then the
fallbacks while the seam, the session, the step machine and the verbs work unchanged.

## The step machine (`SimTimeline.lua`)

A session's steps are its scenario's `timeline(def, { scenario, size, seed })`, built the first
time the session is read. A step is the host's table with at least `kind`; the library adds
`ranAt`, `detail` and `index` to a step that has run, and **writes nothing else into it**. A step's
label in the lines below is `d.panel.stepLabel(step, i, steps)` when the host gives one, else
`step.label`, else `step.kind`.

| Member | Answers | Contract |
|---|---|---|
| `sim:Steps()` | the live list | The session's steps, the same table each call. `{}` while idle. |
| `sim:Step()` | `step` or `nil, code` | Codes: `notRunning`, `building` (until the session's `ready()`), `done`, `settling`, `failed`. `settling`: the gate is closed; its line, else `SETTLING`, is printed and the step does not advance. On success it advances `pos`, `pcall`s `play`, stamps `ranAt`, `detail` (`play`'s answer) and `index`, prints `STEP_LINE` and tells listeners. **A `play` error** counts the step as run with detail `ERROR`, pauses the run, writes the error to the debug sink, prints `STEP_FAILED` and answers `nil, "failed"`. |
| `sim:Run()` | `true` or `false, code` | Codes: `notRunning`, `building`, `playing`, `done`. Clears `paused`, tells listeners and plays to the end: the first tick runs at once, and each tick checks the gate. Closed: it re-polls after `GATE_POLL` (0.25 s) without advancing, printing the gate's line once per settling spell. Open: it plays a step and sets the next tick after `stepDelay(step)`. `playing` is true from `Run` until the run finishes, pauses or stops. |
| `sim:Pause()` | `true` or `false, code` | Code: `notPlaying`. Cancels the pending tick or poll, **leaving no live timer**, and sets `paused`. |
| `sim:Resume()` | `true` or `false, code` | Code: `notPaused`. Clears `paused` and answers `Run()`. |
| `sim:Restart()` | `true` or `false, code` | Code: `notRunning`. `Stop("restart")`, then `Start{ scenario, size, ... }` with a **fresh seed**, so `prepare` runs again; the host's extra start fields the session was started with are carried, every one but `seed` (since 2). A refusal is printed by `Start` and answered `false, "refused"`. |

**The end.** When the step that plays is the last one, whether `Step`, `Run` or the click-ahead
played it, `FINISHED` is printed, formatted with `d.slash`, the playing slot clears and listeners
are told.

**The session token (OWNER_SCOPE C.1).** `Step`, every `Run` tick and the click-ahead capture the
session before `play` and bail if it changed during `play` (a `Stop` or a `Restart` from inside the
host's own `play`): no stamp, no `STEP_LINE`, no next tick. A `ready()` from an earlier session is
ignored (*`ready()`*, above), so a restart during an async `prepare` cannot ready the new session.

**Timers.** Every tick and poll is the session's own `sim:After`, so it dies with the session:
`Stop`'s step (1) cancels the pending one and forgets the run.

**The click-ahead is internal (OWNER_SCOPE C.7).** The panel's click on a row ahead plays every step
up to and including that row, back to back with no `stepDelay`, honoring the gate by polling, and
synchronous while the gate stays open; a step failure or a `done` / `notRunning` answer ends it. It
is a file-local function the panel receives through the attach handshake, **never an instance
member** (`sim.RunTo` is nil). It occupies `Run`'s `playing` slot (C.2): while its gate poll is
pending, `Run` and a second click-ahead answer `playing`, and `Pause` and `Stop` cancel it.

## The panel (`SimPanel.lua`)

A docked window listing the session's steps as clickable rows, each beside the slash command that
does the same thing, with the scenario picker under them while no simulation runs and the run
controls while one does. It teaches the typed form while the player clicks: **the click path is the
typed path.**

**Attach-file floor.** `SimPanel.lua` attaches only with `LibKa0s-Core-1.0` ≥ 9 (the width-only
resize) and `LibKa0s-Widgets-1.0` present (the picker's `W.Dropdown`). With the floor unmet the file
returns before it registers, `MODULES.SimPanel` is absent, and the shell's panel fallbacks answer;
a headless simulator (seam, session, timeline, verbs) is never lost to a missing panel.

**The renderer is library-internal (LK-11's outcome B, [#53](https://github.com/tusharsaxena/LibKa0s/issues/53)).**
The owner's scope made the step panel a public widget, `W.StepPanel`, only if Perf's panel could be
rebuilt on it with every Perf suite passing unedited. It could not, so there is **no public step
panel**: the renderer is a file-local section of `SimPanel.lua`, with no contract a host may read,
and a deliberate duplicate of `PerfPanel.lua`'s renderer (the same geometry, palette and chrome;
each file's header names the other). The library's own suites reach it through
`lib.__StepPanel`, an **internal test seam** under `library-stack-§7`'s `__` clause: no host reads
it, the members manifest leaves it out, and it may change or go with a minor bump.

### Rows

`Start`, then one row per timeline step, then `Stop`. A row is addressed by its **index**, because
step keys repeat: `0` for Start, `i` for timeline step `i`, `#steps + 1` for Stop. States are Perf's
set and no other: `done`, `busy`, `ready`, `locked`, `cancel` (no new state, ever).

| Row | State | Actionable |
|---|---|---|
| Timeline row before `pos` | `done` | no |
| Timeline row at `pos` | `busy` while the run plays or the gate holds the next step, else `done` | no |
| Timeline row at `pos + 1` | `ready` | yes: the typed `step` |
| Timeline rows further ahead | `locked` | **yes**: the click-ahead plays every step up to and including it |
| Any timeline row while idle, stopping, or before the session's `ready()` | `locked` | no |
| Start | `ready` while idle (`locked` while no scenario is listed), `busy` until `ready()` (and while stopping), then `done` | only while idle, and a scenario is listed |
| Stop | `cancel` while a session runs, else `locked` | only while a session runs |

- **Command column.** Start: `slash .. " start " .. name`, plus `" " .. size` when the picked
  scenario has sizes and a size other than random (`0`) is picked. A timeline row:
  `slash .. " step"`. Stop: `slash .. " stop"`.
- **Labels.** Start: `PANEL_START` with the scenario's `label` (else its name). A timeline row:
  `d.panel.stepLabel(step, i, steps)`, else `step.label`, else `step.kind`. Stop: `PANEL_STOP`.
- **Tips.** Start: `d.panel.startTip`; a timeline row: `d.panel.stepTip(step, i)`; Stop:
  `d.panel.stopTip`. Each is a list of lines, a line being `{ left, right? }` or a string; a done
  row adds `RAN_AGO` (Start from the session's `startedAt`, a step from its `ranAt`), formatted
  with `12s`, `3m` or `2h`. The tip is drawn on GameTooltip, the row's label as its title and a
  `{ left, right }` line as a double line.
- **Preview while idle.** The rows are the picked scenario's `timeline(def, { scenario, size,
  seed = 0 })` at `pos` 0, every step `locked`. The timeline is pure, so composing plays nothing;
  one that raises previews no steps and writes a debug line.

`sim:PanelRows()` answers exactly these rows as a fresh list of fresh tables
`{ key, index, label, command, state, actionable, tip }`, where `key` is `"start"`, `"step"` or
`"stop"`. It is published so a host suite asserts its rows without reaching a `__` field, and it
composes whether or not the panel was ever shown.

### Clicks

A click re-composes the rows from the live model and re-checks `actionable` at the clicked
position, so **a stale row never acts** (a row painted actionable on a panel that has not repainted
since does nothing). Then: Start runs `RunVerb("start <name> [size]")`; Stop runs
`RunVerb("stop")`; the `ready` row runs `RunVerb("step")`; a row ahead runs the internal
click-ahead (*The step machine*), whose per-step lines are the typed ones, and a failure code it
answers prints its WHY line (`PLAYING` while a run plays, for example). Every action is a verb or
the click-ahead, so a click prints exactly what typing prints.

### The footer

- **Idle: the picker.** A scenario `W.Dropdown` built from `scenarios.names` and each def's
  `label`; a size `W.Dropdown`, shown only when the picked def has `sizes`, offering `RANDOM` (`0`)
  then each size; and a `START` button that runs the same verb the Start row does. The picker starts
  on the first scenario, and while a session runs it follows the session's scenario. The choice is
  read at use (since `SimPanel.lua` 2): while the picked def resolves it stands, otherwise the first
  name `scenarios.names` lists at that moment, so scenarios filled after `New` are picked up; with
  none listed, `START` is disabled.
- **Running: the controls.** `RUN_ALL` (`run`; enabled while steps are left and nothing plays),
  `PAUSE` / `RESUME`, swapping on the run's `paused` state (`pause` enabled while playing,
  `resume` while steps are left), `RESTART` (`restart`) and `STOP` (`stop`). Every control is a
  verb.
- **The button** is the library's own: a Core-skinned box with a centered label, gold under the
  pointer, gray while disabled, and a GameTooltip naming its typed command. There is no
  `d.panel.button` and no `d.panel.tooltip` (OWNER_SCOPE C.7).

### Refresh and visibility

- A shown panel repaints on **every listener notification** (a typed verb, a click, a timer step,
  ready, stop), and its height follows the row count, the width-only resize bounds re-pinned
  whenever the count changes (OWNER_SCOPE C.5).
- `ShowPanel()` answers `false` and does nothing **while `isStoodDown()`**. The stop hides the panel
  when it runs stood down (step 6) and repaints it otherwise.
- Every non-click way the picker leaves the screen closes the shared dropdown menu (Widgets'
  `CloseMenu`), so none leaves it orphaned: `HidePanel()`, Escape (the frame's `OnHide`, since
  `UISpecialFrames` hides the frame without going through `HidePanel`), and a typed start that
  swaps the picker out for the controls.

### Placement (session-only)

1. **A point dragged this session wins.** On drag stop the panel's point is remembered in the
   instance's memory and nowhere else: **nothing is written to SavedVariables**, and there is no
   `d.panel.store` (OWNER_SCOPE C.11). A `/reload` forgets it.
2. Else it **docks right** of `d.panel.anchorTo()`, `DOCK_GAP` (8) px from it, top edges aligned,
3. or **left** of it when the right has no room on the screen,
4. or **floats** at `CENTER` +420 when neither side fits, or when `anchorTo` is absent or answers
   nil.

It is placed on **every** `ShowPanel`, so with no dragged point it redocks to wherever the anchor is
now. `ResetPanelPosition()` forgets the dragged point and, when the panel is shown, redocks it at
once.

### Instance members

| Member | Contract |
|---|---|
| `sim:ShowPanel() -> bool` | Builds the panel on first use, places it and shows it. `false` while stood down, and headless (no `CreateFrame`). |
| `sim:HidePanel()` | Hides it (and the shared dropdown menu). |
| `sim:TogglePanel() -> bool` | Hides a shown panel (`false`), else `ShowPanel()`. |
| `sim:IsPanelShown() -> bool` | Whether it is shown. |
| `sim:RefreshPanel()` | Repaints a shown panel; a no-op otherwise. |
| `sim:ResetPanelPosition()` | Forgets the dragged point (above). |
| `sim:PanelRows() -> rows` | The composed rows (above). Pure. |

### `d.panel` fields (presentation only)

| Field | Default | Contract |
|---|---|---|
| `title` | `name .. " - Simulation"` | A string, or `fn() -> string`, re-read on every repaint. |
| `stepLabel` | `step.label`, else `step.kind` | `fn(step, i, steps) -> string`. Also names a step in `STEP_LINE` and `STEP_FAILED`. |
| `stepTip` | none | `fn(step, i) -> { lines }`. |
| `startTip`, `stopTip` | none | `{ lines }`, or a function answering them. |
| `anchorTo` | none (float) | `fn() -> frame|nil`: the window the panel docks beside. |
| `check` | none (the dot only) | The done mark's texture path, **host-passed** (for example the host's `NS.Icon("confirm")`), drawn over a hidden dot and tinted with the state color. The library draws no icon of its own here, so the set of library-drawn icons does not grow; the host declares the icon it resolves on its own `LibKa0s icons:` line. |

A callback that raises is a debug line and its default.

## The verbs: `sim:RunVerb(line) -> ok, code` (`SimTimeline.lua`)

One grammar for every host's `/<slash> sim`. Every result is printed through `d.print`. The line
is split on whitespace and its first word, the verb, is lowercased.

| Typed | Effect | Answers |
|---|---|---|
| (empty, or blank) | The status line, then the usage, then `ShowPanel()` | `true` |
| `start <name> [size]` | `Start{ scenario = name, size = tonumber(size) }`. The name matches a scenario exactly, else ignoring case. With no name, the usage | `true`; `false, "refused"` (Start printed its line); `false, "usage"` |
| `run` · `step` · `pause` · `resume` · `restart` | The control of the same name, printing exactly its own lines | `true` or `false, code` |
| `stop` | `Stop("stop")` | `true` |
| `status` | The status line | `true` |
| `panel` | `TogglePanel()` | `true` |
| a key of `d.verbs` | The host's verb (below) | its `ok, code` |
| anything else, `help` included | The usage | `false, "usage"` |

- **There is no `help` verb (OWNER_SCOPE C.7).** `help` is an unknown word, and the usage it prints
  is the help. A host that defines its own `help` in `d.verbs` gets it, like any host verb.
- **The generic verbs win.** A host verb with a generic verb's name is never reached.
- **Free verbs** run idle: the empty line, `status`, `start`, `panel`, and a host verb marked
  `free = true`. Every other verb prints `NOT_RUNNING` and answers `false, "notRunning"` while no
  session is active, before its control or its `parse` is called.
- **WHY lines.** A failure code prints the library's line for it (`notRunning` → `NOT_RUNNING`,
  `building` → `BUILDING`, `playing` → `PLAYING`, `done` → `DONE`, `settling` → `SETTLING`,
  `notPlaying` → `NOT_PLAYING`, `notPaused` → `NOT_PAUSED`), else `d.why[code]`, else nothing. A
  code whose line has already printed is **silent**: `refused` (the refusal line), `failed`
  (`STEP_FAILED`) and `usage`; and a typed `step` on a closed gate answers `settling` after `Step`
  printed the gate's own line, so it prints no second one.
- **A host verb** is `parse(words)` then `run(cmd, sim)`, each under `pcall`. `parse` answering
  `nil` prints the usage (`false, "usage"`). An error in either writes a debug line, prints
  `VERB_FAILED` and answers `false, "error"`. `run`'s failure code prints its WHY line by the rule
  above, so a host verb may answer a library code too.
- **The status line.** Idle: `STATUS_IDLE` with the scenario names. Running: `STATUS_RUNNING` with
  the scenario (`STATUS_SIZE` adds the size when the scenario has sizes, `STATUS_RANDOM` for `0`),
  the seed, `pos` of `total` and a state word: `STATE_BUILDING` before `ready()`, else
  `STATE_DONE` once every step has run, else `STATE_SETTLING`, `STATE_PLAYING`, `STATE_PAUSED`, or
  `STATE_WAITING`. Then `d.statusLine(Status(), Session())`, a line or a list.
- **The usage.** The ten `USAGE_*` lines, each formatted with `d.slash`, then `d.usage` verbatim.
- **The click path is the typed path.** The panel calls `RunVerb` (or the internal click-ahead,
  which prints the same per-step lines), so a click prints exactly what typing prints.

**Host wiring** (documented, not enforced): one Slash-1.0 feature-verb row,
`{ "sim", desc, function(rest) NS.Sim:RunVerb(rest) end }`. Being a feature verb, the dispatcher
refuses it while the addon is disabled. The simulator is slash-only: **no launcher entry and no key
binding** (OWNER_SCOPE C.11).

### `ready()` (OWNER_SCOPE C.1)

`ready` is bound to the session that issued it. A `ready()` from an earlier session (after a
restart, or a stop then a start), a second `ready()` from this one, and a `ready()` during a stop are
ignored. The first good call sets `Status().ready` and tells listeners.

### The stop

`Stop` sets `stopping` as it is entered; that is what makes it **re-entrancy-safe**: a `Stop` from
inside `Fire` → `deliver`, from a stop callback or a listener, or a second `Stop` in a row is a no-op
answering `false`. Each step after (1) runs under `pcall`, so one that raises never skips the rest.

1. Cancel the run and every session timer.
2. `stopping`: `IsActive()` stays true and the seam still answers, but `Fire` and `After` refuse.
3. The `OnStopGuarded` list.
4. The seam off; the session and delivering cleared; the cleanup phase entered.
5. The `OnStop` list (`DeliverForCleanup` is legal here).
6. The cleanup phase left; the panel hidden if `isStoodDown()`, else repainted; listeners told.
7. The stop line: `stopText[reason]`, else the library's line for `stop` (`STOPPED`), `restart`
   (`STOPPED_RESTART`) and `error` (`STOPPED_ERROR`), else `STOPPED_REASON` formatted with the
   reason. Then one debug line with the event count and the reason.

The library emits four reasons itself: `stop`, `restart`, `error` and `standDown` (the self-stop
backstop in `Fire`, which prints `STOPPED_REASON` unless `stopText.standDown` says otherwise). Every
other reason comes from the host.

**Simulated delivery swallows errors on purpose.** A live dispatcher rethrows the first error; `Fire`
turns an error in `deliver` into a debug line and answers `0`, so a session survives a bad handler.

### STRINGS

| Key | Built-in |
|---|---|
| `STARTED` | `Simulation started (%s).` Neutral: **it makes no saved-data claim**, because that guarantee is the host's, and each host overrides it with its own line. |
| `STOPPED` | `Simulation stopped.` |
| `STOPPED_RESTART` | `Simulation stopped to restart.` |
| `STOPPED_ERROR` | `Simulation stopped: it failed to build. The debug log has the error.` |
| `STOPPED_REASON` | `Simulation stopped (%s).` |
| `ALREADY_RUNNING` | `A simulation is already running.` |
| `STOOD_DOWN` | `A simulation cannot start while the addon is disabled.` |
| `UNKNOWN_SCENARIO` | `Unknown scenario '%s'. Scenarios: %s.` |
| `NOT_RUNNING` | `No simulation is running.` |
| `NO_TIMELINE` | `The simulator's timeline is not loaded (SimTimeline.lua).` |
| `BUILDING` | `The simulation is still building its world.` (`SimTimeline.lua`, as are the keys below) |
| `PLAYING` | `The simulation is already playing.` |
| `NOT_PLAYING` | `The simulation is not playing.` |
| `NOT_PAUSED` | `The simulation is not paused.` |
| `DONE` | `Every step of the simulation has run.` |
| `SETTLING` | `Waiting for the simulated world to settle.` The gate's own line wins when it gives one. |
| `STEP_LINE` | `Simulation step %d of %d: %s.` (position, total, label) |
| `STEP_FAILED` | `Simulation step %d of %d failed: %s. The run is paused; the debug log has the error.` |
| `FINISHED` | `Simulation finished: %s stop ends it.` (`d.slash`) |
| `ERROR` | `error`: a failed step's `detail`. |
| `STATUS_IDLE` | `Simulation: idle. Scenarios: %s.` (the scenario names) |
| `STATUS_RUNNING` | `Simulation: %s, seed %s, step %d of %d, %s.` (scenario, seed, position, total, state word) |
| `STATUS_SIZE` | `%s (size %s)` (scenario, size) |
| `STATUS_RANDOM` | `random`: size `0`. |
| `STATE_BUILDING` · `STATE_PLAYING` · `STATE_PAUSED` · `STATE_SETTLING` · `STATE_WAITING` · `STATE_DONE` | `building` · `playing` · `paused` · `settling` · `waiting for a step` · `finished` |
| `VERB_FAILED` | `Simulation verb '%s' failed. The debug log has the error.` |
| `USAGE_BARE` | `%s: the status, this usage and the step panel.` (each `USAGE_*` takes `d.slash`) |
| `USAGE_START` | `%s start <scenario> [size]: start a simulation.` |
| `USAGE_RUN` | `%s run: play every step, pausing between them.` |
| `USAGE_STEP` | `%s step: play the next step.` |
| `USAGE_PAUSE` | `%s pause: pause a run.` |
| `USAGE_RESUME` | `%s resume: resume a paused run.` |
| `USAGE_RESTART` | `%s restart: start the same scenario again with a fresh seed.` |
| `USAGE_STOP` | `%s stop: end the simulation.` |
| `USAGE_STATUS` | `%s status: where the simulation stands.` |
| `USAGE_PANEL` | `%s panel: show or hide the step panel.` |
| `PANEL_START` | `Start: %s` (the scenario's label; `SimPanel.lua`, as are the keys below) |
| `START` | `Start`: the picker's button. |
| `PANEL_STOP` | `Stop simulation` |
| `RUN_ALL` · `PAUSE` · `RESUME` · `RESTART` · `STOP` | `Run all` · `Pause` · `Resume` · `Restart` · `Stop`: the controls. |
| `RANDOM` | `Random`: the size dropdown's `0`. |
| `RAN_AGO` | `Ran %s ago` (`12s`, `3m`, `2h`): a done row's tip line. |

## What the library enforces, and what it only documents

[#54](https://github.com/tusharsaxena/LibKa0s/issues/54) listed five safety rules as "enforced by
the library". Only one of them, that stop cleans everything, can be: the library never sees a
host's saved data, its sends, its players or its world, so it guards only what the host routes
through the seam. This table is the split
(design-sim §5, with OWNER_SCOPE C's fixes). A **yes** is pinned by this repo's suites; a **no** is
the host's, and its row names what the host owes.

| Property | Enforced by the library | Host obligation |
|---|---|---|
| A guarded member never reaches the client while a session is active, inside `Live` and providers included | **yes** | Classify its members correctly: every member that sends or acts on the world is `guarded` (H1). |
| The idle seam costs one field test and allocates nothing | **yes** | — |
| The refusal order: unknown scenario, already running, the host's `refusal` read inside `Live`, then the stood-down backstop | **yes** | Own every world rule in `refusal` (H5): the library adds none and relaxes none. |
| No simulated event outside a live, not-stopping, not-stood-down session | **yes**: `Fire` answers `0`, and self-stops on an observed stand-down | Call `Stop("standDown")` **first** in its stand-down steps (H6). |
| Timers die with the session; a canceled handle is forgotten | **yes** | Use `sim:After`, never a raw `C_Timer`, inside the simulation. |
| The stop runs the guarded steps, then turns the seam off, then runs the rest, each step isolated; a second or nested `Stop` is a no-op (C.1) | **yes** | Put a step that must still see simulated answers in `OnStopGuarded`. |
| Cleanup delivery happens only in the `OnStop` phase, and never while stood down (C.3) | **yes** | — |
| A `ready()` acts only for the session that issued it (C.1); the click-ahead shares `Run`'s `playing` slot (C.2) | **yes** | — |
| `Live` restores bypass on every exit and keeps the original error value (C.8) | **yes** | Read the real world only through `Live`. |
| One owner per answer: a second `SetProvider` for a key raises (C.8) | **yes** | Release with `nil` before handing a key to a new provider. |
| Nothing escapes the wrap | **detected**, not prevented: `seam:Unwrapped()` (C.8) | Create the seam straight after the Compat files (a LOAD-BEARING TOC comment), never `local x = Compat.Member`, and assert `Unwrapped()` empty in a suite (H2). |
| The panel position is session-only (C.11) | **yes**: held in the instance's memory, never in SavedVariables | — (H10) |
| Saved data is untouched | **no**: the library never sees a write | Session-only stores for every SavedVariables write the capture path reaches, and a byte-identical before/after test (H4). |
| Nothing is sent, and nothing acts on a real player | **only for guarded keys** | Never call a hooked or world-changing client function from a simulator file except through a guarded Compat member (LootHistory pins this with a static scan). |
| Reads that other LibKa0s majors (Env, Item) make on the host's behalf | **no**: they are outside the seam | Route through Compat whatever the simulation must answer (LootHistory's zone and map reads). |
| Dispatch fidelity | **no** | `deliver` calls only the handlers the client's registration would call, in client order, skipping events the client rejected (H3). |
| Real input in the middle of a session | **no** | Classify it: stop and deliver it live (LootHistory's interference), stop first (BankLedger's real bank open), or absorb it. |
| Test mode and simulation are exclusive | **no** | Refuse each while the other runs (H5). |
| A marker on screen while a session runs | **no**: the library supplies `IsActive` | preview-mode's marker rule (standard v2.86.0): the title or a `W.TestStrip` label, plus the footer (H8). |
| It refuses in a real group, an instance or combat | **no**: no world rule is the library's | Each host's `refusal` says which apply to it (H5). |

**Simulated delivery swallows errors on purpose.** A live dispatcher rethrows the first error;
`Fire` turns an error in `deliver` into a debug line and answers `0`, so a session survives a bad
handler. A host suite that wants to see a handler's error reads the debug sink.

**`STARTED` makes no saved-data claim.** Whether a simulation writes nothing is the host's guarantee
(H4), not the library's, so the built-in line says only that a simulation started, and each host
overrides it through `d.L` with its own line once its invariant test backs the claim.

## The host contract (H1–H10)

MUSTs for every host, restated in each host's own spec. The library enforces none of them (the table
above says where it backs one up), so each is the host's to test.

- **H1. Every client read the simulator answers, and every outward action, is a Compat member read
  at call time** (`NS.Compat.Member(...)`). A captured member (`local x = Compat.Member`) is the live
  one and escapes the seam. Every member that sends or acts on the world is in `opts.guarded`.
- **H2. `Sim:NewSeam` runs in a setup file loaded straight after the Compat files**, with a
  LOAD-BEARING TOC comment, before any other file can read a Compat member. A suite asserts
  `seam:Unwrapped()` is empty after the whole addon loads.
- **H3. One `deliver`** reproduces the client's handler set and order for any event name the host
  fires, pseudo-events included (`hook:<name>`, `GUILDBANK_FRAME_SHOWN`), and skips the events the
  client rejected at registration.
- **H4. Session-only storage** for every SavedVariables write the capture path reaches, plus a
  byte-identical before/after test of the saved tables across a whole session.
- **H5. `refusal`** covers stood-down, test mode and the world rules that apply to the host (group,
  instance, combat, per-scenario prerequisites), and test mode refuses while a simulation runs.
  Destructive host commands (a purge, a reset, a delete) refuse while a session is active.
- **H6. `sim:Stop("standDown")` is the first stand-down step.** A host reason (a profile event,
  combat, a real frame opening) calls `Stop` with that reason, and a `stopText` entry where it wants
  its own line.
- **H7. One Slash-1.0 feature-verb row**, `{ "sim", desc, function(rest) NS.Sim:RunVerb(rest) end }`,
  which the dispatcher refuses while the addon is disabled. **Slash-only** (C.11): no launcher entry
  and no key binding.
- **H8. A preview-mode marker** while a session runs (the table above), a `sim` section in the
  diagnostics dump, and a `Sim` debug tag (the descriptor's `debug` sink).
- **H9. The degradation stub** below, with a surface-parity case for the session and the seam.
- **H10. The panel position is session-only** (C.11, superseding design-sim's window-state reading):
  the library holds a dragged point in memory, the host writes nothing for it, it is never a schema
  row and never a SavedVariables key, and the host's window-state documentation says so. Nothing a
  simulation does writes to SavedVariables.

And four rulings that bind every host alongside them:

- **Host members never hang on the library instance (C.4).** The host keeps its own table, for
  example `NS.SimHost`, for its host fields: its `Status` extras, `HistoryLog`, `MarkGUID`,
  `SetRestriction` and the like. It holds the seam separately (for example `NS.SimSeam`) for
  `SetProvider` and `Live`. Host fields of a running session go on the session table
  (`sim:Session()`, the host bag). `tests/test_sim_host.lua` pins a host shaped this way.
- **Restriction and chat-lockdown simulation stays host code (C.9).** DropWatcher's model, its
  providers and its verbs are DropWatcher's; the library carries no restriction notion.
- **Fixed, slash-only, unsaved (C.11).** The step delay is a host constant or a function of the step,
  never a schema row; the simulator has no launcher entry and no key binding; nothing is saved.
- **A host whose world settles asynchronously passes a `gate` (C.12).** LootHistory's answers closed
  while its Reconciler has a pending settle, BankLedger's while a lag timer or a held baseline is
  pending, and each answers its own line, so a player stepping by hand is told what the world waits
  for. The gate is read before every step, by `Step`, every `Run` tick and the click-ahead, so the
  click-ahead waits correctly where a per-step delay alone would only pace `Run`. A host with nothing
  to settle passes none (DropWatcher).

Two presentation obligations close it: `d.panel.anchorTo` answers the host's main window while it is
shown and nil while it is not, so the panel floats rather than docking beside a hidden frame; and
`d.panel.check` is the host's own resolved icon path, declared on its `LibKa0s icons:` line.

## Adopting it

**Adoption is required of none** (OWNER_SCOPE F, the Compat, Bus and Schema precedent). A host that
never calls `NewSeam` or `New` owes nothing: the files arrive with the whole-folder copy and never
run.

**1. The setup file, straight after Compat.** One file, in the TOC slot right after the host's Compat
files, with the comment that keeps it there:

```toc
# LOAD-BEARING: wraps every NS.Compat member at load (LibKa0s-Sim-1.0's seam). It must load straight
# after the Compat files and before any file that reads a Compat member.
core\SimSetup.lua
```

```lua
local _, NS = ...
-- core/SimSetup.lua: the LibKa0s-Sim-1.0 seam (library-stack-§7). Absent major: the inert stubs below.
local Sim = LibStub and LibStub("LibKa0s-Sim-1.0", true)
if Sim then
  NS.SimSeam = Sim:NewSeam(NS.Compat, {
    name = "MyAddon",
    pure = PURE,          -- { [key] = true }: secret guards, text helpers
    guarded = GUARDED,    -- { [key] = fn }: the safe answer for every member that acts
    debug = function(tag, fmt, ...) NS.Debug(tag, fmt, ...) end,
  })
else
  NS.SimSeam = newSeamStub()
end
```

The simulator module then calls `Sim:New(d)` with `seam = NS.SimSeam` and publishes the instance as
`NS.Sim` (or `newSimStub(print)` when the major is absent). Host fields go on `NS.SimHost`, never on
`NS.Sim` (C.4).

**2. The reference stub.** A host reads `NS.Sim:IsActive()` and `NS.Sim:IsDelivering()` on hot
real-event paths and calls `NS.SimSeam:Live(fn, ...)` around client reads, so the stub is
**mandatory**: one missing member raises on exactly the degraded path it exists to survive. Copy it
from `tests/test_sim_stub.lua`, which pins it member by member:

```lua
local NEEDS_LINE = "The simulator needs LibKa0s-Sim-1.0."

local function newSeamStub()
  local seam = {}
  function seam.SetProvider() end
  function seam.Live(_, fn, ...) return fn(...) end
  function seam.Keys() return {} end
  function seam.Unwrapped() return {} end
  return seam
end

local function newSimStub(say)
  local sim = {}
  local function no() return false end
  local function noop() end
  local function absent() return false, "absent" end
  sim.IsActive, sim.IsDelivering, sim.IsPanelShown = no, no, no
  function sim.Fire() return 0 end
  function sim.DeliverForCleanup() return 0 end
  function sim.After() return nil end
  function sim.Start() say(NEEDS_LINE); return false, NEEDS_LINE end
  sim.Stop = no
  sim.OnStop, sim.OnStopGuarded, sim.AddListener = noop, noop, noop
  function sim.Status() return { active = false } end
  function sim.Session() return nil end
  function sim.Steps() return {} end
  function sim.Step() return nil, "absent" end
  sim.Run, sim.Pause, sim.Resume, sim.Restart = absent, absent, absent, absent
  function sim.RunVerb() say(NEEDS_LINE); return false, "absent" end
  sim.ShowPanel, sim.TogglePanel = no, no
  sim.HidePanel, sim.RefreshPanel, sim.ResetPanelPosition = noop, noop, noop
  function sim.PanelRows() return {} end
  return sim
end
```

The instance surface is the same whether or not `SimTimeline.lua` and `SimPanel.lua` attached (the
shell's fallbacks), so one stub fits every payload. It must carry nothing the live surface does
not: no `IsGuarded`, no `IsActive` on the seam.

**3. The `Unwrapped`-empty assertion**, in a host suite that loads the whole addon:

```lua
T.assertEqual(#NS.SimSeam:Unwrapped(), 0, "every Compat member is wrapped or pure")
```

**4. A stub parity case.** No manifest lists instance members, because `Sim:New` builds them per
host, so the live half is a real instance registered through `Kit.setSurfaceSource`, compared both
ways with an empty ignore set:

```lua
local restore = T.setSurfaceSource({ ["LibKa0s-Sim-1.0"] = liveSim })
T.assertSurfaceParity(newSimStub(print), "LibKa0s-Sim-1.0", {})
T.setSurfaceSource(restore)
T.assertSurfaceParity(newSimStub(print), liveSim, "stub over the live instance", {})
T.assertSurfaceParity(newSeamStub(), liveSeam, "seam stub over the live seam", {})
```

### Adopters

| Host | Shape | Since |
|---|---|---|
| **DropWatcher** | **Migrated**: its own seam, session, step machine, verbs and panel (`core/SimSeam.lua` and its `modules/Sim*.lua`) were the source of this major; it moves onto it and deletes its generic copy, keeping its world, events, roster, scenarios, restriction model (C.9) and `sim.stepDelay` setting reader. | its v1.75.0 re-vendor |
| **LootHistory** | **New simulator** (`/lh sim`): a deterministic fixture world, six scenarios, a Reconciler-settled `gate`, one `loot` host verb, destructive surfaces refused during a session. | its v1.75.0 re-vendor |
| **BankLedger** | **New simulator** (`/bl sim`): warband, guild and one-sided scenarios with a `gate` and a `settle`-paced `stepDelay`, `/bl purge` refused during a session. | its v1.75.0 re-vendor |

**Future candidates**, left open and repointed at this major: MultiMeters#60, WhatGroup#24 and
KickCD#38. None is owed; each adopts when its own simulator is built.

## What is not here

| Not in Sim-1.0 | Stays in | Re-check trigger |
|---|---|---|
| The five "safety rules enforced by the library" as [#54](https://github.com/tusharsaxena/LibKa0s/issues/54) worded them: nothing is sent; saved data is never written; the simulator never acts on a real player; stop cleans everything; it refuses to start in a real group, an instance or combat | **Stop cleans everything** is enforced (the two-phase stop, every session timer canceled). The other four are host obligations: guarded members cover only what the host routes through the seam, and every world rule is the host's `refusal` (*What the library enforces*, H4, H5) | a library-level hook that can see a host's sends, saved writes or world without the host routing them, which no addon framework offers |
| `seam:IsActive()` | the session (`sim:IsActive()`) | never on the seam: OWNER_SCOPE C.7 |
| `sim:RunTo(index)` | the panel's click-ahead, through the internal attach handshake | never public: OWNER_SCOPE C.7 |
| A `help` verb | the usage, which any unknown word prints | never: OWNER_SCOPE C.7 |
| A launcher entry or key binding for the simulator | the host's one `sim` slash row | never: OWNER_SCOPE C.11 |
| A schema row for the step delay | a fixed host constant or `fn(step)` in `d.stepDelay` | never: OWNER_SCOPE C.11 |
| `sim:Live(fn, ...)` | the seam (`seam:Live`): one `Live` | never: OWNER_SCOPE C.7 |
| `d.panel.button`, `d.panel.tooltip` | the library's own button and GameTooltip | never: OWNER_SCOPE C.7 (DropWatcher's visible line changes are accepted and on its smoke list) |
| A saved panel position (`d.panel.store`) | a dragged point held in the instance's memory for the session (H10) | never: nothing a simulation does writes to SavedVariables (OWNER_SCOPE C.11) |
| A public step-panel widget (`W.StepPanel`) | a file-local renderer in `SimPanel.lua`, duplicated on purpose with `PerfPanel.lua`'s; `lib.__StepPanel` is an internal test seam | a second consumer that can take the renderer with no edit to its suites (LK-11's outcome B, [#53](https://github.com/tusharsaxena/LibKa0s/issues/53)) |
| A StepPanel `place` or `onDragStop` hook | `SimPanel.lua` positions the frame itself and hooks `OnDragStop` | never: OWNER_SCOPE C.7 |
| `seam:IsGuarded(key)` | the host, which classified its own keys | never: OWNER_SCOPE C.7 |
| A `__newindex` auto-wrap on the host's table | `seam:Unwrapped()` and the host suite that asserts it empty | never: it adds magic to the host's table and still misses a replacement (OWNER_SCOPE C.8) |
| Restriction and chat-lockdown simulation | the host (DropWatcher) | never: OWNER_SCOPE C.9 |
| Any SavedVariables read or write | the host's session-only stores | never |
| Behavior flags | host data, callbacks with one meaning, presentation arguments | never: `library-stack-§7` bar 2 |

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Sim.lua`, `SimTimeline.lua` and `SimPanel.lua` are entries in `LibKa0s.xml`, after `PerfPanel.lua`, so the
whole-folder copy brings them in with no load-list change in the host. **Payload weight:** the file
bodies only define functions; no frame, timer or event registration exists until `NewSeam` or
`New` is called (and no timer until a session calls `After`, no frame until `ShowPanel`), so a
host that never simulates pays parse time and nothing else. Whole-folder vendoring ships the major
into all fourteen consumers of this payload; the three adopters wire it, and the other eleven pay
parse time only.
