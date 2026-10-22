# `LibKa0s-Sim-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Sim surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Sim-1.0` |
| File | `Sim.lua` minor **1** |
| Shipped in | v1.75.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (no Core member is called) |
| Confirm in-game | `LibStub("LibKa0s-Sim-1.0").MODULES` → `{ Sim = 1 }` |

**The step machine and the panel arrive in the next commits of this release.** This version
documents the Compat answer seam and the session that binds it. The step machine
(`SimTimeline.lua`) and the panel (`SimPanel.lua`) join the major before v1.75.0 is released, and
the version key grows to `<Sim>.<SimTimeline>.<SimPanel>` as they do; each step gets its own
document. Until they attach, the session carries fallbacks for their members (below).

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
| `MODULES` | 1 | `{ Sim = <minor> }`: the live minor, and the value that picks this document. |

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
| `name` | yes | The addon folder. Error text, and later the panel's frame name. |
| `seam` | yes | From `Sim:NewSeam`, not yet bound. |
| `slash` | yes | The typed prefix, for example `"/dw sim"`. |
| `deliver` | yes | `fn(event, ...) -> n`. Calls exactly the handlers the client's registration would call for this event, in order, and answers how many ran. **Any string is a legal event name** (`hook:<name>`, `GUILDBANK_FRAME_SHOWN`). Each call is `pcall`ed by the library; per-handler isolation is the host's. |
| `isStoodDown` | yes | `fn() -> bool`, read at call time. |
| `scenarios` | yes | `{ names = {ordered}, defs = { [name] = { label, sizes = {n, ...}?, timeline = fn(def, opts) -> steps } } }`. Every listed name needs a def with a `timeline` function; a name that is not in `names` is unknown to `Start`. |
| `prepare` | yes | `fn(session, def, opts, ready)`. Builds the host's world and calls `ready()`, sync or async. `opts` is `{ scenario, size, seed }`. |
| `play` | yes | `fn(step, session) -> detail?`. Drives one step (the step machine, next commit). |
| `refusal` | no | `fn(opts) -> line|nil`. Run **inside `seam:Live`**, so it reads the real world; it owns every host rule (stood-down wording, test mode, combat, instance, group, per-scenario prerequisites). The library adds no world rule and relaxes none. An error in it is re-raised by `Start` after `Live` writes its traceback. |
| `gate`, `stepDelay`, `verbs`, `why`, `usage`, `statusLine` | no | Read by the step machine and the verbs (next commits). Type-checked here: `stepDelay` is a number or `fn(step) -> seconds`. |
| `stopText` | no | `{ [reason] = line }`. The stop line for a reason, the library's own reasons included. |
| `L` | no | Locale table. Any `STRINGS` key is overridden through `rawget`, so a locale table whose metatable answers an unknown key with the key does not shadow the built-in line. |
| `print` | no | `fn(line)`, read at call time. Default: `DEFAULT_CHAT_FRAME:AddMessage`. |
| `debug` | no | `fn(tag, fmt, ...)`, read at call time, tag `"SIM"`. Default: none. A sink that raises is ignored. |
| `panel` | no | Presentation only: `title`, `stepLabel`, `stepTip`, `startTip`, `stopTip`, `anchorTo`, `check`. Any other key raises: there is no `button` and no `tooltip` (the library draws its own button and uses GameTooltip) and no `store` (the panel position is session-only, nothing is written to SavedVariables). OWNER_SCOPE C.7 and C.11. |

### Instance members

Colon-called. Every member is a closure over the instance's private state; the instance carries no
public `active` or `delivering` field and **no `Live`** (the one `Live` is on the seam).

| Member | Contract |
|---|---|
| `sim:Start(opts) -> ok, line` | `opts = { scenario, size?, seed? }`. Refusals, in this order, each printed and answered `false, line`: (1) an unknown scenario, `UNKNOWN_SCENARIO` with the scenario names; (2) `ALREADY_RUNNING` (a session is live or stopping); (3) `refusal(opts)`, inside `seam:Live`; (4) the backstop, `isStoodDown()`, `STOOD_DOWN`. Then the session `{ sim = true, scenario, size, seed, startedAt = time(), events = 0 }`, the seam on, `STARTED` printed (formatted with the def's `label`, else the scenario name), `prepare` called under `pcall` with a `ready` bound to this session, and listeners told. `size` is set only when the def has `sizes` (`0`, the default, means random); `seed` defaults to a time-derived integer that differs on every start. A `prepare` error becomes `Stop("error")`; when the session ends inside `prepare`, `Start` answers `false` with no line, the stop line having printed. |
| `sim:Stop(reason) -> bool` | The stop below. `reason` defaults to `"stop"`. Answers `false` when idle and when a stop is already under way. |
| `sim:IsActive()` | True from `Start` until step (4) of the stop. |
| `sim:IsDelivering()` | True only inside `Fire`, nesting-safe; false again once a session that ended inside `deliver` returns. Hosts use it to tell a simulated input from a real one. |
| `sim:Session()` | The live session table, or nil. **Host fields go on this table** (the host bag: a world, members, a log); the library's fields on it are read-only by convention. Timers and internals are not on it. |
| `sim:Fire(event, ...) -> n` | `0` unless a session is active and not stopping. An observed stand-down (`isStoodDown()` true while active) first calls `Stop("standDown")` and answers `0`. Otherwise it counts the event, writes a debug line, sets delivering, `pcall`s `deliver(event, ...)` and restores delivering; an error is a debug line and answers `0`. |
| `sim:After(delay, fn) -> handle|nil` | A session timer (`C_Timer`): nil when idle or stopping. `fn` runs under `pcall`, only while the same session is live. `handle:Cancel()` cancels it **and forgets it**; every live handle is canceled at stop. |
| `sim:OnStopGuarded(fn)` | Registers `fn(session)`, run at stop **while the seam still answers**. Permanent and ordered, normally at file load. |
| `sim:OnStop(fn)` | Registers `fn(session, reason)`, run at stop **after the seam is off**. Permanent and ordered. |
| `sim:DeliverForCleanup(event, ...) -> n` | Delivers through `deliver` **only during the OnStop phase**, with the seam off, and answers `0` at any other time **and while `isStoodDown()`** (OWNER_SCOPE C.3). For undoing an edge the simulation raised. |
| `sim:Status() -> t` | `{ active, scenario, size, seed, startedAt, events, ready, pos, total, playing, paused, settling }`. Until the step machine attaches, `pos` and `total` are `0` and the three flags `false`. A fresh table each call; a host merges its own fields into its copy. |
| `sim:AddListener(fn)` | Registers `fn(sim)`, run under `pcall` on every transition (start, ready, stop; the step machine adds step, run and pause). Permanent. |

**Fallbacks.** Until `SimTimeline.lua` and `SimPanel.lua` attach, the instance still answers every
member they own: `Steps()` and `PanelRows()` answer `{}`, `Step()` answers `nil, "absent"`, `Run`,
`Pause`, `Resume` and `Restart` answer `false, "absent"`, `RunVerb` prints `NO_TIMELINE` and answers
`false, "absent"`, `ShowPanel`, `TogglePanel` and `IsPanelShown` answer `false`, and `HidePanel`,
`RefreshPanel` and `ResetPanelPosition` do nothing. The attach files overwrite them through an
internal handshake (`lib.__AttachTimeline`, `lib.__AttachPanel`) that is not contract.

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

## The host contract (OWNER_SCOPE C.4)

**Host members never hang on the library instance.** The host keeps its own table (for example
`NS.SimHost`) for its host fields: its `Status` extras, `HistoryLog`, `MarkGUID`, `SetRestriction`
and the like. It holds the seam separately for `SetProvider`. Host fields of a running session go
on the session table (`sim:Session()`, the host bag).

## Host obligations so far

- Every client read the simulator answers, and every outward action, is a Compat member read at
  call time. Never `local x = Compat.Member`: a captured member is the live one and escapes the seam.
- `NewSeam` runs in a setup file loaded straight after the Compat files.
- A suite asserts `seam:Unwrapped()` is empty after the whole addon loads.
- `refusal` covers stood-down, test mode and the world rules that apply to the host.
- `sim:Stop("standDown")` is the first stand-down step; a host reason (`group`, `combat`, a real
  frame) calls `Stop` with that reason and, where it wants its own line, a `stopText` entry.
- Every timer inside the simulation is `sim:After`, never a raw `C_Timer`, so it dies with the
  session. A step that must still see simulated answers goes in `OnStopGuarded`.
- Saved data is the host's: the library never intercepts a write, so session-only stores and an
  invariant test are the host's.

## What is not here

| Not in Sim-1.0 | Stays in | Re-check trigger |
|---|---|---|
| `seam:IsActive()` | the session (`sim:IsActive()`) | never on the seam: OWNER_SCOPE C.7 |
| `sim:Live(fn, ...)` | the seam (`seam:Live`): one `Live` | never: OWNER_SCOPE C.7 |
| `d.panel.button`, `d.panel.tooltip`, `d.panel.store` | the library's own button and GameTooltip; a session-only position | never: OWNER_SCOPE C.7 and C.11 |
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

`Sim.lua` is an entry in `LibKa0s.xml`, after `PerfPanel.lua`, so the whole-folder copy brings it in
with no load-list change in the host. **Payload weight:** the file body only defines functions; no
frame, timer or event registration exists until `NewSeam` or `New` is called (and no timer until a
session calls `After`), so a host that never simulates pays parse time and nothing else.
