# `LibKa0s-Schema-1.0` — version 2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Schema surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Schema-1.0` |
| Files and minors | `Schema.lua` minor **2** |
| Shipped in | v1.56.0 |
| Status | **Current** |
| Supersedes | [version 1](./version-1-docs.md) — no `normalize`, no batch, and the instance id stopped short of a row's `get` and of `ApplyDefault` |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Schema-1.0").MODULES` → `{ Schema = 2 }` |

## What changed at version 2

`Schema.lua` moves to minor **2**. The lib-level surface is unchanged (`members-2.json` differs from
`members-1.json` in its version key alone); the instance gains one member and the row one field, and
every change is additive — a host written against version 1 sees no difference unless it passes the
new arguments or sets the new field.

- **`SetMany(entries, opts)`**, the all-or-nothing batch. Every entry is resolved, validated and
  normalized before any is stored; one refusal answers `false, err, why, index` with nothing stored
  and nothing called. A batch that passes stores every entry in order, then runs every row's
  `onChange` in order, then tells the host once through the new descriptor field `announceBatch`
  (or `announce` once per write without it). With `opts.act` the batch is one bulk bracket and so
  one `[Set] <act> <scope>: N rows` line. See [The batch](#the-batch-setmany).
- **`row.normalize(value, resolvedId)`**, after `validate` accepts and before the store. It answers
  the value to store, or `nil, why`, which refuses with `INVALID`. The normalized value is what is
  stored, logged and handed to `onChange` and `announce`. Two consumers carry this semantic in front
  of their own seams today (AuraMaster, ConsumableMaster), which is `library-stack-§7` bar 2.
- **The instance id reaches a row's own `get`**: `Get(path, instanceId)` calls
  `row.get(instanceId)`, where version 1 called `row.get()` (review finding `LibKa0s-R-14`).
- **`ApplyDefault(row, instanceId)`** forwards the id to `Set`, where version 1's
  `ApplyDefault(row)` wrote with none (the same finding).

`Set` and `SetMany` share one preparation step, so a batch refuses on exactly the rules a single
write does, and `Set`'s answers keep their version-1 arity: `false, err, why` for a value refusal
(three values even when `why` is nil) and `false, err` for a missing root.

## What this major is

**The settings schema's runtime, without the schema.** A host keeps its rows — paths, labels,
defaults, widgets, `onChange` reactions — and this major supplies the machinery every host had
written for itself around them: dotted-path primitives, a path index, the single write seam
(`architecture-§5`), the bulk bracket that makes a sweep one debug line (`debug-logging-§10`), the
profile reset's changed-row count, and the load-time shape check.

Nine addons carried that machinery as nine copies, and the copies had drifted where it mattered:
which row wins on a duplicate path, whether a table value is copied into the store, whether the bulk
line counts rows that were already at their default, whether a raising `onChange` is swallowed. Each
of those is now one answer, recorded below with the reading taken.

### What it deliberately does not do

- **It owns no storage.** Where a stored row's value lives is the host's `resolveRoot`; a row whose
  storage is somewhere else (session state, the global store, an inverted key) carries its own
  `get`/`set`.
- **It sends no message and refreshes no panel.** What a write announces is the host's `announce`.
- **It formats no value.** The `[Set]` line takes the host's `format` — the same function the host
  hands `LibKa0s-Slash-1.0`'s descriptor — so the two majors compose instead of overlapping.
- **It owns no migration, no AceDB defaults builder, and no page ordering or filtering** — the last
  is the Options descriptor's `rowsForPage`.
- **It exports no deep copy.** Copying happens inside the seam where it is part of a semantic.
- **It carries no single-consumer write semantic**: no per-write old value, no skip flags. A host
  that needs one keeps it in front of this seam (`library-stack-§7` bar 2). Two semantics left this
  list at version 2 because a second consumer arrived for each — the post-validate `normalize` and
  the all-or-nothing batch (`SetMany`) — and are documented below. A refusal is the exception, which belongs in `validate` because a wrapper cannot
  see a reset ([A gate in front of the seam](#a-gate-in-front-of-the-seam)). A host whose write
  semantics cannot be expressed here keeps its own `Set` and calls the primitives, the registry and
  the bracket when the library is present
  ([A host that keeps its own seam](#a-host-that-keeps-its-own-seam)).

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called** — the floor is a load-payload check, as on `LibKa0s-Lifecycle-1.0`, so a host
holding a partial payload gets every module absent rather than a working half (`library-stack-§7`).

## Library surface

All pure; none holds per-host state. Lib-level so a host that keeps its own seam still calls them.

| Member | Since | What it is |
|---|---|---|
| `lib.SplitPath(path)` | 1 | The segments of a dotted path, as **one shared array per path string** (memoized). **Callers MUST NOT mutate it.** Empty segments are dropped (`"a..b"` → `{ "a", "b" }`); a non-string is `tostring`ed first; `nil` is the empty path. |
| `lib.Read(root, pathOrParts, first)` | 1 | The value at the path under `root`, starting at segment `first` (default 1). `nil` when `root` is not a table, when any intermediate is not a table, and for the empty path — the root itself is never an answer. |
| `lib.Write(root, pathOrParts, value, first)` | 1 | Stores `value` itself at the path, creating intermediates and **replacing** a non-table intermediate with `{}`. No-op when `root` is not a table or the path is empty. |
| `lib.SameValue(a, b)` | 1 | `a == b` first (so `-0` equals `0`, `nil` equals `nil`); otherwise tables by content, both directions, recursively. `false` and an absent key differ. No cycle detection, no metatable. |
| `lib.STRINGS` | 1 | `NOT_FOUND = "Setting not found: %s"`, `INVALID = "Invalid value for %s"`, `NO_ROOT = "Setting has nowhere to be stored yet: %s"`. |
| `lib:New(descriptor)` | 1 | One runtime for one host. Raises `LibKa0s-Schema-1.0: descriptor.rows must be a table`. |

`pathOrParts` is a path string (split through `SplitPath`) or an already-split array, which is what
lets a host whose resolver consumed a leading `container.` segment pass its parts and a `first` of 2.

**Allocation.** A warm `Read` allocates nothing: the split is cached per distinct path and the walk
is an integer loop. Two hosts carry measured ceilings on their read path (a dormant repaint pass and
a per-element show decision), and a suite case pins 1000 warm reads under 1 KB of heap growth. The
cache is bounded by the distinct paths ever asked for.

## The descriptor

The descriptor is **held by reference**, and every field except `rows` is read **at call time** — a
host may fill `announce` or `debug` after `:New`, as `LibKa0s-Lifecycle-1.0` reads `print`. A field
of the wrong type counts as absent.

| Field | Type | Required | What it is |
|---|---|---|---|
| `rows` | array | **yes** | The host's live schema array, **never copied**. `AllRows()` answers this exact table. Rows already in it are indexed at `:New`. |
| `resolveRoot` | `function(parts, instanceId) -> root, first, resolvedId` \| `nil, reason` | no | Where a **stored** row's path lives. `first` is the index of the first segment inside `root` (default 1). `resolvedId`, when given, replaces `instanceId` in what `validate`, `onChange` and `announce` receive. A root that is not a table means "nowhere, now", and the second value is used as the refusal text **only if it is a string** — `function() return NS.db and NS.db.global, 1 end` answers `nil, 1` before the db exists, and the 1 is not a reason. `parts` is the shared `SplitPath` array. Absent: only rows carrying `get`/`set` are readable and writable. |
| `announce` | `function(row, path, value, resolvedId)` | no | The post-write tail: the bus message, the panel refresh. Called once per successful `Set`, **after** `onChange`, including for closure and `sessionOnly` rows — the host filters on `row.sessionOnly` itself. Also once per write of a `SetMany` batch when `announceBatch` is absent. |
| `announceBatch` | `function(writes, resolvedId)` | no | **Since 2.** `SetMany`'s tail, called **once** per successful non-empty batch, after every `onChange`, **in place of** `announce`. `writes` is an array, in entry order, of `{ row = , path = , value = , rid = }` — `value` the stored (normalized) value, `rid` that write's resolved id — and `resolvedId` is the first write's. Never called by `Set`. |
| `debug` | `function(tag, fmt, ...)` | no | The host's debug sink. Absent: nothing is logged. |
| `debugEnabled` | `function() -> boolean` | no | Asked **before** a line is formatted. Absent: always log. It is what keeps a color-picker drag, which reaches the seam every frame, from running the host's formatter with debug off. |
| `format` | `function(row, value) -> string` | no | Renders a value for the `[Set]` line. Absent (or answering `nil`): `tostring(value)` — a string, so a sink that ends in `string.format` cannot raise on a boolean. |
| `print` | `function(line)` | no | Used by `Validate` only. Absent: `Validate` still counts, silently. |
| `resetExempt` | set `{ [path] = true }` | no | Rows a **sweep** must not reset (`launcher-§3`'s minimap row). Honored by `ApplyDefault` **only while a bracket is open**, so a named single-row reset still works. |
| `L` | table | no | Overrides `lib.STRINGS` by key, read with **`rawget`** — a Ka0s locale table answers every key with the key itself, and a plain index would mask every string the host did not override (the *`L` trap* `LibKa0s-Slash-1.0` documents). |

### Row fields this major reads

**Only** `path`, `default`, `validate`, `normalize`, `onChange`, `get`, `set`, `sessionOnly`, `type`,
`page` and `group`. Every other field is Options' or Slash's and passes through untouched.

| Row field | Meaning here |
|---|---|
| `path` | The key. A row without a non-empty string path is not indexed. |
| `default` | What `Default` / `ApplyDefault` restore. **`nil` means no restore.** |
| `validate(value, resolvedId) -> ok, why` | Refuse before storing. A bare `false` is the `why = nil` case. |
| `normalize(value, resolvedId) -> value \| nil, why` | **Since 2.** Runs after `validate` accepts and before the missing-root refusal and the store. Answers the value to store, or `nil, why`: a refusal with `INVALID` and that `why`, nothing stored and nothing called. `false` is a value, not a refusal. Because `nil` refuses, a normalize cannot clear a setting to absence; a row that needs that stores through its own `set`. |
| `onChange(value, resolvedId)` | The row's reaction, after the store. Receives the value **as given** — the normalized value when the row has `normalize` — not the stored copy. |
| `get(instanceId)` / `set(value)` on a path row | The row's own storage. `get` receives the `instanceId` `Get` was called with (**since 2**; version 1 passed none). `set` receives the value as given (never a copy; the normalized value when the row has `normalize`) and `resolveRoot` is never called for the row. |
| `sessionOnly` | Not in any store a profile reset reaches. Without `set` a write stores nothing and still reacts and announces; without `get` a read answers `nil`. Skipped by `CountOffDefault` and by `Validate`'s resolution check. |
| `type`, `page`, `group` | Shape checks in `Validate`. |

**How it composes with `LibKa0s-Options-1.0`.** Options reads and writes a row that has a `path`
only through its descriptor, and consults `row.get`/`row.set` itself only on a **path-less** bound
row. This major gives `get`/`set` their meaning on a **path** row — the half Options leaves behind
the descriptor. The two never disagree about a row: Options calls `d.get(path)`, which is `inst.Get`,
which calls `row.get(instanceId)`. Path-less bound rows are not indexed here and are exempt from `Validate`'s
path check.

## Instance surface

**Every instance member is a closure bound at `:New` and is dot-called**: `inst.Set(path, v)`, never
`inst:Set(...)`. The Options and Slash descriptors take their seams **as values** —
`set = inst.Set`, `findRow = inst.FindRow`, `bulkBegin = inst.BulkBegin` — and a member that needed
`self` could not be handed over that way. `lib:New` itself stays colon-called, like every major's
constructor.

The library does not choose the host's public name for the seam: a host binds whichever it has
(`NS.SetByPath = inst.Set`, or `function NS.Schema:Set(p, v, id) return inst.Set(p, v, id) end`).

| Member | Since | Answers | Absent root / row / callback |
|---|---|---|---|
| `AllRows()` | 1 | the descriptor's `rows` (identity) | — |
| `FindRow(path)` | 1 | row or `nil` | non-string → `nil`. **First-registered wins** on a duplicate path. |
| `AddRows(list, at)` | 1 | number added | non-table → `0`. `at` nil, non-number or past the end appends; `at >= 1` inserts the rows in order starting there; `at < 1` is the head. Re-indexes. |
| `Reindex()` | 1 | nothing | For a host that mutated `AllRows()` in place. Until it is called the index answers the rows as they were. |
| `Get(path, instanceId)` | 1 | value | row has `get` → `row.get(instanceId)` (the id since 2); `sessionOnly` without `get` → `nil`; otherwise `resolveRoot` + `lib.Read`. A path with **no row** is still read (a debugging `get` of an interior node). Root absent → `nil`; non-string path → `nil`. |
| `Set(path, value, instanceId)` | 1 | `true` \| `false, err[, why]` | See the pipeline below. |
| `SetMany(entries, opts)` | 2 | `true` \| `false, err, why, index` | See [The batch](#the-batch-setmany). A non-table `entries` is the empty batch; a non-table `opts` is `{}`. |
| `Default(path)` | 1 | deep copy of the row's `default` | unknown path → `nil` |
| `ApplyDefault(row, instanceId)` | 1 | `Set`'s answers, or `false` | `Set(row.path, copy of default, instanceId)` — the id **since 2**. Not a table / no string `path` / `default == nil` → `false`, nothing written. In `resetExempt` while a bracket is open → `false`. |
| `BulkBegin(act, scope)` | 1 | nothing | The descriptors' `bulkBegin`. |
| `BulkEnd(act, scope, count, err, info)` | 1 | nothing | Unpaired → no-op, depth never negative. `count` is ignored. |
| `BulkRun(act, scope, fn)` | 1 | nothing; re-raises `fn`'s error **unchanged** | `fn(info)`; `info.profileReset = true` silences the line. |
| `BulkAdd(n)` | 1 | nothing | outside a bracket, or `n` not a number → nothing |
| `InBulk()` | 1 | boolean | — |
| `CountOffDefault(pred)` | 1 | number | See *The profile reset's count*. |
| `ResetCounted(resetFn, pred)` | 1 | nothing; re-raises unchanged | — |
| `ConsumeResetCount()` | 1 | number or `nil` | — |
| `Validate(spec)` | 1 | `errors, resolved, missing` | `print` absent → silent counts; `defaultsRoot` absent → no resolution check. |

### The `Set` pipeline — the order is the contract

1. `path` not a string, or no indexed row → `false, NOT_FOUND`. **An unknown path is refused, never
   stored** (`architecture-§5` scopes the seam to schema-row paths).
2. A **stored** row (no `set`, not `sessionOnly`): `root, first, resolvedId = resolveRoot(parts,
   instanceId)`.
3. `validate(value, resolvedId)` → falsy: `false, INVALID, why`.
4. **Since 2:** `normalize(value, resolvedId)` → `nil`: `false, INVALID, why`. Otherwise its answer
   is the value from here on.
5. A stored row with no root → `false, reason` (the resolver's string) or `NO_ROOT`. **After**
   validate and normalize, so a bad value is named before a missing root.
6. Inside a bracket: snapshot `before = Get(path, instanceId)` (deep-copied).
7. **Store.** `row.set(value)` with the value as given; a `sessionOnly` row without `set` stores
   nothing; otherwise `lib.Write(root, parts, deepcopy(value), first)` — **a table is copied in**, so
   the caller's table and the store never alias.
8. Inside a bracket: tally `+1` iff `Get(path, instanceId)` is not `SameValue` to `before`. Taken
   **before any host code runs**, so a raising `onChange` cannot drop a write that landed.
9. **Log**, outside a bracket only: `debug("Set", "%s = %s", path, shown)` when `debug` is present
   and `debugEnabled` is absent or true.
10. `row.onChange(value, resolvedId)`. **Errors propagate** — the value is stored and the line
   written, so the host's error handler never sees less than happened.
11. `announce(row, path, value, resolvedId)`.
12. `true`.

`resolvedId` is `instanceId` unless the resolver returned a third value; for a closure or
`sessionOnly` row the resolver is not called and it is `instanceId`.

### The batch: `SetMany`

`SetMany(entries, opts)` writes several rows as **one act, all or nothing**.
`entries = { { path = , value = }, ... }`, `opts = { instanceId = , act = , scope = }`, every field
optional.

1. **Phase 1, nothing stored.** Each entry, in order, goes through steps 1–5 of the `Set` pipeline
   with `opts.instanceId`: an unknown path (or an entry that is not a table) is `NOT_FOUND`, then
   the root, `validate`, `normalize` and the missing root. The first refusal answers
   **`false, err, why, index`** — `index` the entry's position — and nothing has been stored and
   nothing called but earlier entries' own `validate` and `normalize`.
2. **Phase 2, the stores.** Every entry is stored in entry order (step 7), each tallied inside a
   bracket or logged with its own `[Set]` line outside one (steps 6, 8, 9). With **`opts.act`** given
   the whole of phase 2 and 3 runs inside one `BulkRun(opts.act, opts.scope, ...)`, so a batch
   outside any other bracket writes **one** `[Set] <act> <scope>: N rows` line, `N` counting the
   entries whose read-back moved. Without `act` and outside a bracket, each write logs its own line;
   inside a host's open bracket, the writes join that bracket's tally.
3. **Phase 3, the reactions.** Every row's `onChange(value, resolvedId)` runs, in entry order,
   **after every store has landed** — a reaction reading a sibling row sees the whole batch, and a
   raising `onChange` cannot leave the store half-written. It propagates, the remaining reactions
   and the announce do not run, and with `act` the bracket still closes, its line marked
   ` (stopped by an error)`.
4. **Phase 4, the announce.** `announceBatch(writes, resolvedId)` **once**, after the bracket's
   line; without it, `announce(row, path, value, resolvedId)` once per write, in entry order. An
   empty batch announces nothing (with `act` it still writes its `0 rows` line).
5. `true`.

A path named twice in one batch is written twice, in order, and appears twice in `writes`.

### The bulk bracket (`debug-logging-§10`)

One tally shared across nesting levels and a depth counter. The **outermost** `BulkEnd` emits, with
its own `act` and `scope`:

```
debug("Set", "%s %s: %d rows%s", act, scope, N, failed and " (stopped by an error)" or "")
```

unless any level reported `info.profileReset`, or `ConsumeResetCount` ran while the bracket was
open. `N` is the library's own tally of writes whose **read-back** value moved, plus `BulkAdd`
contributions — never the Options/Slash `count`, which includes rows already at their default. The
read-back test is what makes a closure row that stores a transformed value (clear-to-absence, an
inverted key, a normalized string) count correctly. The line honors `debugEnabled`. A begun bracket
always closes: `BulkRun` pcalls `fn`, calls `BulkEnd` with the raised value as `err`, then re-raises
it with `error(err, 0)` — a table error comes back by identity.

### The profile reset's count

`CountOffDefault(pred)` counts the rows in `AllRows()` that are **indexed** (a later duplicate is
not), have a string `path`, are not `sessionOnly`, are not excluded by `pred(row)` — **only an
explicit `false` excludes**; absent `pred` counts all — and whose `Get(path)` is not `SameValue` to
`default`. With no root, `Get` is `nil`, so a row counts iff it has a default.

`ResetCounted(resetFn, pred)` sets the pending count to `CountOffDefault(pred)`, runs `resetFn`
under `pcall`, and clears the pending count on **both** exits, so a reset that never reached the
handler cannot hand its number to a later one. `ConsumeResetCount()` answers the pending count once
and clears it; it **also marks an open bracket as a profile reset**, so a reset fired inside a bulk
act emits the handler's line and no second bulk line.

### `Validate(spec)`

`spec = { types = set?, pages = set?, defaultsRoot = function(parts, row) -> root, first }`.
`types` defaults to `{ bool, number, string, color }`, the four Options widget types; a host's set
**replaces** it. `pages` is checked only when given.

Each failure is printed once through `descriptor.print` as
`|cffff0000schema error|r: row #<i> (<path>): <msg>` and counted in `errors`:

- the row is not a table;
- `path` missing or empty — **unless** the row carries both `get` and `set` (an Options bound row);
- `type` not in `types`;
- `page` not in `pages`;
- `group` not a non-empty string (`options-ui-§13`);
- `path` already used by an earlier row — `duplicate` names the earlier row's index.

Resolution, for a row with a path that is not `sessionOnly`, when `defaultsRoot` is given:
`root, first = defaultsRoot(parts, row)`; a non-table root skips the row (a profiles page, a row in
no defaults tree); `lib.Read(root, parts, first) ~= nil` counts `resolved`, otherwise the row prints
``"`path` does not resolve against the defaults"`` and counts `missing`. `Validate` prints and counts;
it never refuses.

## Hard invariants

Each of these has a case in `tests/test_schema.lua`.

1. An unknown path is refused, and a refused write — unknown path, `validate`, missing root — stores
   nothing and calls nothing.
2. A successful write runs `debug` → `onChange` → `announce`, once each, in that order.
3. A table value is stored as a copy; a closure row's `set` receives the value itself.
4. `validate` runs before the missing-root refusal.
5. A raising `onChange` propagates, after the store and the line, and `announce` does not run.
6. With `debugEnabled` answering false, neither `debug` nor `format` is called.
7. `FindRow` is first-wins on a duplicate path, and a head insert re-indexes.
8. `ApplyDefault` with `default == nil` writes nothing; `resetExempt` binds only inside a bracket.
9. A bracket emits exactly one line, at the outermost close, counting read-back changes — a row
   stored at `false` and written `false` again is not a change — and nothing when any level reset the
   profile.
10. A begun bracket always closes, and `BulkRun` re-raises the same error value.
11. A write inside a bracket counts even when its `onChange` raises.
12. The pending reset count is taken once and cleared on both exits of `ResetCounted`.
13. Every instance member works taken as a bare value and called without `self`.
14. A warm `Read` allocates nothing.
15. With Core absent the module does not register.

Minor 2's invariants are pinned in `tests/test_schema_batch.lua`:

16. A batch with one refused entry — unknown path, `validate`, `normalize` — stores nothing, calls
    nothing, and answers the entry's index.
17. A batch that passes stores every entry, runs every `onChange` after every store, and calls
    `announceBatch` exactly once (or `announce` once per write without it).
18. With `act`, a batch is exactly one bracket line counting the rows it moved, and the bracket
    closes even when an `onChange` raises.
19. `normalize`'s answer is what is stored and what `onChange` and `announce` receive; `nil, why`
    refuses with `INVALID`, and `normalize` runs only after `validate` accepts.
20. `Get` hands `instanceId` to a row's `get`, and `ApplyDefault(row, id)` writes through `Set` with
    that id.

## Worked example

```lua
-- HostSchemaStub: the host's degradation stub (see "The degradation stub" below).
local SchemaLib = LibStub("LibKa0s-Schema-1.0", true) or HostSchemaStub

local S = SchemaLib:New{
  rows         = NS.Schema,                       -- the live array; page files AddRows into it
  resolveRoot  = function(parts)
    if parts[1] == "global" then return NS.db and NS.db.global, 2 end
    return NS.db and NS.db.profile, 1
  end,
  announce     = function(row)
    if not row.sessionOnly and NS.bus then NS.bus:SendMessage(NS.MSG.CONFIG) end
  end,
  debug        = NS.Debug,
  debugEnabled = function() return NS.State and NS.State.debug end,
  format       = NS.FormatSchemaValue,            -- the same function the Slash descriptor takes
  print        = NS.Print,
  resetExempt  = { [NS.Constants.MINIMAP_PATH] = true },
}
NS.SchemaRuntime = S

-- The host keeps its public names, so no call site moves.
NS.SetByPath, NS.FindSchemaRow, NS.RegisterSchemaRows = S.Set, S.FindRow, S.AddRows

-- The Options / Slash descriptors take the members as values.
local descriptor = {
  get = S.Get, set = S.Set, findRow = S.FindRow, allRows = S.AllRows,
  applyDefault = S.ApplyDefault, bulkBegin = S.BulkBegin, bulkEnd = S.BulkEnd,
}

-- A profile reset the addon drives, counted for the OnProfileReset handler's one line.
local function notMinimap(row) return row.path ~= NS.Constants.MINIMAP_PATH end
function NS.ResetProfileCounted(db) S.ResetCounted(function() db:ResetProfile() end, notMinimap) end
NS.ConsumeResetCount = S.ConsumeResetCount

-- Since 2: a copy between two instances is one act, one line and one announce.
S.SetMany({
  { path = "focus.width",  value = S.Get("target.width") },
  { path = "focus.height", value = S.Get("target.height") },
}, { act = "copy", scope = "target→focus" })
```

## The degradation stub

Every other major is reached by the panel, the CLI or a diagnostic. This one is reached by the
addon's **feature runtime** and by **host-owned writers**. The runtime is a repaint pass or a show
decision reading its settings. The writers are host verbs, the degraded Options stub's Reset All
and a combat re-lock, all writing through the seam. A load missing this major is missing Options and
Slash too (whole-folder vendoring; all three floor on Core), but that does **not** make `Set`
unreachable. `options-ui-§1` asks the Options stub to keep Reset All real, and `slash-commands-§1`
says the host verbs keep working without the library. In AbsorbTracker, for example, the host verbs
(`settings/Slash.lua:487`), the Options stub's Reset All (`settings/OptionsSetup.lua:383`) and the
combat re-lock (`core/AbsorbTracker.lua:259`) all write through `NS.SetByPath`. A stub that refused
`Set` would break every one of them on the degraded path it exists to survive (anti-pattern #56,
shape 2).

The stub a host writes is therefore **write-completing and log-silent**. It completes everything a
player can observe: reads, writes, the row's reaction, the announce, and the sweep veto. It does not
reproduce what only feeds the debug console: the `[Set]` line, the bracket's tally and the profile
reset's count. Every host that adopts this major also falls back to a `LibKa0s-DebugLog-1.0` stub
whose `Add` and debug sink are empty functions, so the degraded build has nowhere to show one.

| Member | Stub answer |
|---|---|
| `AllRows`, `AddRows`, `FindRow`, `Reindex` | Real: rows held by reference, append/insert, a linear first-match `FindRow`, `Reindex` a no-op. Page files call `AddRows` at file load. |
| `Get` | Real: `row.get(instanceId)` if present, `nil` for a `sessionOnly` row without one, else the host's own root and a plain walk. |
| `Set` | Real, in the seam's order **without the log and the tally**: unknown path refused (never stored), `validate`, `normalize` (its answer stored; `nil` refuses), missing root refused, store (`row.set` with the value; nothing for `sessionOnly` without `set`; otherwise a **copy** written at the path), `onChange`, `announce`, `true`. Refusals are in the host's own words. |
| `SetMany(entries, opts)` | **Since 2.** Real, with the library's **all-or-nothing** semantics and **log-silent**: every entry prepared as `Set` prepares it, the first refusal answers `false, err, why, index` with nothing stored; then every store, every `onChange`, and `announceBatch` once (or `announce` per write). `opts.act` is not read — there is no line to make one of. |
| `ApplyDefault(row, instanceId)` | Real: `false` for no string path or `default == nil`; `false` for a `resetExempt` row **while a bracket is open**; otherwise `Set(row.path, copy of row.default, instanceId)`. |
| `Default(path)` | A copy of the row's `default`, or `nil`. |
| `BulkBegin` / `BulkEnd` / `InBulk` | A depth counter and nothing else. `ApplyDefault`'s sweep veto reads it (`launcher-§3`). No tally, no line. |
| `BulkRun(act, scope, fn)` | `BulkBegin`, `fn({ profileReset = false })` under `pcall`, `BulkEnd`, then re-raise the error unchanged. |
| `BulkAdd` | No-op. |
| `CountOffDefault` · `ResetCounted(fn)` · `ConsumeResetCount` | `0` · runs `fn()` · `nil`. The count exists only for the reset handler's debug line. |
| `Validate` | `0, 0, 0` and one honest line. |

**The lib level too.** A host whose own code calls the primitives (a data layer's path walk, a
`SameValue` in a reset verb) needs them when the library is absent. The instance stub's `Get` and
`Set` already carry a split, a read walk and a write walk, so the stub exposes them once as a stub
library: `SplitPath`, `Read`, `Write`, `SameValue`, and `New(d)` returning the instance stub. The host
then keeps **one** seam and no call site moves:

```lua
local SchemaLib = LibStub and LibStub("LibKa0s-Schema-1.0", true) or HostSchemaStub
```

The stub carries no `STRINGS`. Its refusals are the host's own words, not a copy of the library's
constants.

**Pinning it.** The instance surface is **not** in `members-2.json`, which lists lib-level members
only. A host therefore pins the instance stub against a live instance with the kit's two-table form,
and the stub library by name:

```lua
T.assertSurfaceParity(liveInstance, stub, "schema instance vs host stub")
T.assertSurfaceParity(HostSchemaStub, "LibKa0s-Schema-1.0", { "STRINGS" })
```

A runner that registers a table-map surface source adds `["LibKa0s-Schema-1.0"]` to it, as for any
by-name call. Beyond the member set, a host pins one degraded write per writer kind it has (a host
verb, Reset All, any runtime writer) landing in the store.

**The reference.** `tests/test_schema.lua` carries `referenceStub`, the stub this section describes.
It is built with no upvalue and in an environment of plain Lua, so it cannot reach the library it
stands in for. The suite pins its surface on both levels, its store and reaction order against a
live instance on the same writes and the same batches, its sweep veto, and its primitives against
the library's. It measures 172 non-blank, non-comment lines at version 2 (132 at version 1). 101 of
them are the write half (the copy, the write walk, the shared preparation, `Set`, `SetMany`,
`Default`, `ApplyDefault` and the depth-only bracket); the rest is the read-completing half and
`SameValue`. A host copies it and trims what it does not call, except a member the parity pin
requires: a host that never batches still carries `SetMany`.

**This is a deliberate, documented duplication**, and a host's stub carries a comment naming this
section. `LibKa0s-Compat-1.0`'s guard stubs rest on the same ground: "the library is absent" is not
"the settings cannot be written". The standard at v2.63.0 does not name this stub class.
`options-ui-§1`'s no-copy MUST lists widget makers, the flow engine, the header and layout
constants, and not a runtime write path. Whether anti-pattern #47 reaches a degradation write path
is an open question for an upstream ruling. The alternative reading, a refusing `Set`, would leave
every host verb, Reset All and runtime writer dead on the degraded path, and each adopter would have
to record that as a deviation from `slash-commands-§1`.

### A host that keeps its own seam

A **partial** adopter keeps its own `Set` (and with it, its own primitives and bracket) because its
write semantics cannot be expressed here. Its own code is already its library-absent answer. So its
delta is **"call the library when present, else the host's existing function"**, never "delete":

```lua
local Read = SchemaLib and SchemaLib.Read or readFrom       -- readFrom: the host's own walk
```

The cost is stated plainly. In minor 1 this removed **none** of a partial adopter's walker or bracket
code. What it buys is that the live path runs the shared, tested copy. The degraded path runs the
host's own copy, and the host's library-absent suite keeps pinning it. A partial adopter for which
that trade is not worth two code paths MAY defer adoption until it adopts `Set`.

### A gate in front of the seam

Bind the Options and Slash descriptors' `set` / `applyDefault` straight to the instance members
**only when the host has no pre-seam gate**. `ApplyDefault` calls the instance's own `Set`, never
the descriptor's `set`, so a host wrapper in front of `Set` is bypassed by every reset, whatever the
descriptors are bound to. A refusal the host needs on every write path belongs in the row's
`validate`, which `Set` runs on every entry: a player's write, a CLI `set`, a reset and a
value-bound descriptor. `validate` may carry the host's own side effects on refusal (a chat line, a
panel refresh that snaps the widget back), and it answers `false, why`.

## Moving to version 2 from version 1

Nothing to do for a host that neither batches nor normalizes: every version-1 call answers as it
did. A host with a degradation stub adds `SetMany` to it (see the last adoption note). A host whose
closure `get` ignored its argument keeps working; one that wants the id now receives it.

## Adoption notes

- **Behavior that changes for some hosts, each on purpose.** An unknown path is refused rather than
  stored; a table value is copied into the store; a raising `onChange` propagates rather than being
  caught; the `[Set]` line is written before `onChange` rather than after; `default == nil` means
  no restore; the first of two duplicate rows wins, and `Validate` reports the duplicate; `group` is
  required on every row. A host crossing any of these pins the new behavior in its own suite in the
  adoption commit.
- **Refusal wording.** Hosts that printed `"unknown path: "` or `"invalid value"` change wording;
  `descriptor.L` restores theirs.
- **Bulk callback shape.** `BulkRun` hands `fn(info)`, the Options/Slash `bulkEnd(..., info)` shape.
  A host whose `fn` returned `true` to mean "this was a profile reset" writes
  `info.profileReset = true` instead.
- **Perf.** A host with a measured read-path ceiling re-runs its `tests/perf.lua` at adoption.
- **The degraded build's debug lines.** Under the log-silent stub a library-less build writes no
  `[Set]` line, no bracket line and no reset count. A host suite that pins those lines on its
  degraded build re-pins them in the adoption commit to what the stub does: the writes landed, and
  the lines are absent. The degraded DebugLog stub already discards those lines, so they were never
  something a player could see. The degraded **writes** stay pinned.
- **A pre-seam gate moves into `validate`.** A host that refuses some values in a wrapper in front
  of its seam moves the check into the row's `validate` before binding the descriptors to the
  instance members, and adds a case that drives the refusal through the CLI's `set`.
- **A version-1 stub goes red on the re-vendor.** Every host that already carries a Schema
  degradation stub pinned with the two-table `T.assertSurfaceParity` (AbsorbTracker, BankLedger,
  LootHistory, PanelMaster, PrettyChat at v1.55.0) must add `SetMany` to it, with the semantics in
  the stub table above; adding it before the re-vendor is harmless against version 1. A stub that
  forwards `instanceId` to `row.get` and through `ApplyDefault`, and honors `normalize`, matches
  this version's store as well as its surface.

### Per-host mappings at version 2

What each host that has not yet adopted `Set` maps onto, so the adoption commit is a translation
rather than a redesign:

- **KickCD** (#22). `announce` reads the host's own `row.section` field (this major passes every
  field it does not read through untouched) to send `CONFIG_CHANGED` with the section, and
  `announceBatch` sends each distinct section once. The SESSION and GLOBAL paths become rows with
  their own `get`/`set` (a `sessionOnly` row for session state). The master switch is the `enabled`
  row's `onChange`, which runs **before** `announce`, so the stand-down or wake-up has happened by
  the time the bus message goes out. Copy styling is one `SetMany` with `act = "copy"`.
- **ConsumableMaster** (#39). The type rules' validate-and-coerce splits: the refusal stays in
  `validate`, and the coercion (a number clamped, a table copied) moves into `normalize`.
  `SetManyAndRefresh` becomes `SetMany` plus an `announceBatch` that runs the host's reactions and
  one bar re-apply, so a page reset is still one `applyBar`.
- **MultiMeters** (#52). `SetByPaths` becomes `SetMany(entries, { instanceId = windowId })` against a
  window-aware `resolveRoot(parts, windowId)`; `announceBatch` sends `CONFIG_CHANGED` once per batch.
  The single-path writes go through `Set`.
- **AuraMaster** (#21). Its `SetByPath` normalizes after validating; with `row.normalize` that
  semantic is now expressible here, so a partial adoption — the primitives, the registry, the
  bracket and `Validate`, with the host's seam kept until it is re-evaluated — no longer rests on a
  semantic the library refuses to carry.
