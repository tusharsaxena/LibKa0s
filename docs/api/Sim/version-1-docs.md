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

**Sessions arrive in the next commit of this release.** This version documents the Compat answer
seam only. The session constructor, the step machine (`SimTimeline.lua`) and the panel
(`SimPanel.lua`) join the major before v1.75.0 is released, and the version key grows to
`<Sim>.<SimTimeline>.<SimPanel>` as they do; each step gets its own document.

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
| `opts.debug` | no | `fn(tag, fmt, ...)`. The sink `Live` writes a traceback to until a session binds; once one binds, the session's own debug sink is used. The tag is `"Sim"`. Anything but a function or `nil` raises. |

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
- **The active flag is driven only by a bound session.** Until a session binds (next commit of this
  release), the seam is idle and every member answers live, guarded members included.
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

## Host obligations so far

- Every client read the simulator answers, and every outward action, is a Compat member read at
  call time. Never `local x = Compat.Member`: a captured member is the live one and escapes the seam.
- `NewSeam` runs in a setup file loaded straight after the Compat files.
- A suite asserts `seam:Unwrapped()` is empty after the whole addon loads.

## What is not here

| Not in Sim-1.0 | Stays in | Re-check trigger |
|---|---|---|
| `seam:IsActive()` | the session (it answers whether it is active) | never on the seam: OWNER_SCOPE C.7 |
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
frame, timer or event registration exists until `NewSeam` is called, so a host that never simulates
pays parse time and nothing else.
