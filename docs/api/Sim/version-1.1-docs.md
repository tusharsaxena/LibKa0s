# `LibKa0s-Sim-1.0` — version 1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Sim surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Sim-1.0` |
| Files and minors | `Sim.lua` **1** · `SimTimeline.lua` **1** |
| Version key | `<Sim>.<SimTimeline>.<SimPanel>`, in load order — the numbers `lib.MODULES` reports; `SimPanel.lua` joins it later in this release |
| Shipped in | v1.75.0 |
| Status | **Current** |
| Supersedes | — (first version; briefly keyed `1` on the release branch, and no release carried that key) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (no Core member is called); `SimTimeline.lua` needs nothing beyond the shell |
| Confirm in-game | `LibStub("LibKa0s-Sim-1.0").MODULES` → `{ Sim = 1, SimTimeline = 1 }` |

**The panel arrives in the next commits of this release.** This version documents the Compat
answer seam, the session that binds it, the step machine and the verbs (`SimTimeline.lua`). The
panel (`SimPanel.lua`) joins the major before v1.75.0 is released, and the version key grows to
`<Sim>.<SimTimeline>.<SimPanel>` as it does. Until it attaches, the session carries fallbacks for
its members (below).

## What changed at this version

`SimTimeline.lua` minor 1 joins the major, a secondary file paired on the shell's minor
(`lib.__timelineMinor` / `lib.__timelineShellMinor`, Perf's idiom), and the version key grows from
`1` to `1.1`. It overwrites the shell's timeline fallbacks with the step machine (*The step
machine*, below): `Steps`, `Step`, `Run`, `Pause`, `Resume` and `Restart`, the host's `gate`, the
per-step `stepDelay`, and `Status()`'s `pos`, `total`, `playing`, `paused` and `settling`. It
also overwrites the `RunVerb` fallback with the typed grammar every host's `sim` slash verb shares
(*The verbs*, below), which reads the descriptor's `verbs`, `why`, `usage` and `statusLine`.
`Sim.STRINGS` gains `BUILDING`, `PLAYING`, `NOT_PLAYING`, `NOT_PAUSED`, `DONE`, `SETTLING`,
`STEP_LINE`, `STEP_FAILED`, `FINISHED` and `ERROR`, and for the verbs `STATUS_IDLE`,
`STATUS_RUNNING`, `STATUS_SIZE`, `STATUS_RANDOM`, the six `STATE_*` words, `VERB_FAILED` and one
`USAGE_*` line per generic verb. No member of the shell changes. Version `1`
was never released: this document was `version-1-docs.md` until the key moved, on the release
branch (the unreleased-key rule).

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
| `MODULES` | 1 | `{ Sim = <minor>, SimTimeline = <minor> }`: the live minors, and the values that pick this document. |

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
| `play` | yes | `fn(step, session) -> detail?`. Drives one step's events through `sim:Fire`; its answer is the step's `detail`. It runs under `pcall`, and an error pauses the run (*The step machine*). |
| `refusal` | no | `fn(opts) -> line|nil`. Run **inside `seam:Live`**, so it reads the real world; it owns every host rule (stood-down wording, test mode, combat, instance, group, per-scenario prerequisites). The library adds no world rule and relaxes none. An error in it is re-raised by `Start` after `Live` writes its traceback. |
| `gate` | no | `fn(session) -> open, line?`. Checked before every step: by `Step`, by every `Run` tick and by the panel's click-ahead. Closed means the host's world has not settled (LootHistory passes its Reconciler settle, OWNER_SCOPE C.12). With no gate, the gate is always open (DropWatcher). A gate that raises counts as closed and writes a debug line. |
| `stepDelay` | no | A number, or `fn(step) -> seconds`: the pause after `step` before `Run` plays the next one. Default `2`. Read when each timer is set. A host passes a fixed constant or a function of the step; there is no schema row for it (OWNER_SCOPE C.11). |
| `verbs` | no | `{ [verb] = { parse = fn(words) -> cmd|nil, run = fn(cmd, sim) -> ok, code, free = bool? } }`: the host's extra verbs, tried after the generic ones (*The verbs*). `words[1]` is the verb, lowercased. |
| `why` | no | `{ [code] = line }`: the line a host verb's failure code prints. |
| `usage` | no | `{ lines }`, printed verbatim after the library's usage. |
| `statusLine` | no | `fn(status, session) -> line|{lines}`, appended to the library's status line. An error in it is a debug line. |
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
| `sim:Status() -> t` | `{ active, scenario, size, seed, startedAt, events, ready, pos, total, playing, paused, settling }`. While idle, or when `SimTimeline.lua` is absent, `pos` and `total` are `0` and the three flags `false`. A fresh table each call; a host merges its own fields into its copy. |
| `sim:AddListener(fn)` | Registers `fn(sim)`, run under `pcall` on every transition: start, ready, step, run, pause, stop (and a gate that closes under a step). Permanent. |

**Fallbacks.** When `SimTimeline.lua` or `SimPanel.lua` has not attached, the instance still
answers every member it owns: `Steps()` and `PanelRows()` answer `{}`, `Step()` answers
`nil, "absent"`, `Run`, `Pause`, `Resume` and `Restart` answer `false, "absent"`, `RunVerb` prints
`NO_TIMELINE` and answers `false, "absent"`, `ShowPanel`, `TogglePanel` and `IsPanelShown` answer
`false`, and `HidePanel`, `RefreshPanel` and `ResetPanelPosition` do nothing. The attach files
overwrite them through an internal handshake (`lib.__AttachTimeline`, `lib.__AttachPanel`, and the
ctx table `New` hands both) that is not contract. At this version `SimTimeline.lua` attaches and
`SimPanel.lua` does not yet exist, so the timeline and verb members are live and the panel members
are the fallbacks.

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
| `sim:Restart()` | `true` or `false, code` | Code: `notRunning`. `Stop("restart")`, then `Start{ scenario, size }` with a **fresh seed**, so `prepare` runs again. A refusal is printed by `Start` and answered `false, "refused"`. |

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
- A `gate` that can close answers its own line, so a player who steps by hand is told what the
  world is waiting for.
- Saved data is the host's: the library never intercepts a write, so session-only stores and an
  invariant test are the host's.
- The slash surface is one feature-verb row, `{ "sim", desc, function(rest) NS.Sim:RunVerb(rest) end }`,
  with no launcher entry and no key binding (OWNER_SCOPE C.11).

## What is not here

| Not in Sim-1.0 | Stays in | Re-check trigger |
|---|---|---|
| `seam:IsActive()` | the session (`sim:IsActive()`) | never on the seam: OWNER_SCOPE C.7 |
| `sim:RunTo(index)` | the panel's click-ahead, through the internal attach handshake | never public: OWNER_SCOPE C.7 |
| A `help` verb | the usage, which any unknown word prints | never: OWNER_SCOPE C.7 |
| A launcher entry or key binding for the simulator | the host's one `sim` slash row | never: OWNER_SCOPE C.11 |
| A schema row for the step delay | a fixed host constant or `fn(step)` in `d.stepDelay` | never: OWNER_SCOPE C.11 |
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

`Sim.lua` and `SimTimeline.lua` are entries in `LibKa0s.xml`, after `PerfPanel.lua`, so the
whole-folder copy brings them in with no load-list change in the host. **Payload weight:** the file
bodies only define functions; no frame, timer or event registration exists until `NewSeam` or
`New` is called (and no timer until a session calls `After`), so a host that never simulates pays
parse time and nothing else.
