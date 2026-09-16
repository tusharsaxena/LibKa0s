# `testkit` — version 22

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, **`mock_record.lua`**, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **22** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.40.0 |
| Status | **Current** |
| Supersedes | [version 21](version-21-docs.md) — the pooled CheckBox `check` texture |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `22` |

Everything revision 21 describes is unchanged here except the additions below. **One file is added**
(`mock_record.lua`), three change (`framework.lua` for the revision number, `mock_base.lua` for the
frame recorder and the install, `run-automated-tests.sh` for two thinned RESULTS.md sections) and
`README.md` gains a section. `loader.lua`, `mock_ids.lua`, `vendor_sync.lua` and `test_eol.lua` are
untouched.

## What changed at this version

### The five surveys, and why they arrived together

An addon that has been switched off has to answer "nothing" to five questions, and until this
revision a suite could ask only two of them, badly.

That is not a coverage gap. It is what made the question unaskable. Eleven addons in this collection
implement "disabled" as a **draw gate**: the frames go away, the registrations stay, and the client
goes on walking the addon's registration list on every `UNIT_AURA` in a twenty-five-man raid,
building the argument frame, entering Lua and running the comparison that decides to leave. From
outside, that is indistinguishable from an addon that genuinely stood down — which is exactly how
the draw gate survived eleven audits. **A suite written against a handler's early return cannot tell
the two apart, because an early return is what a draw gate does.** A suite written against the
registration set can.

| Member | Contract |
|---|---|
| `M.__registrations()` | An array of `{ target, kind, event, unit }` for every LIVE registration, in a stable order. `kind` is one of `"event"` (AceEvent `RegisterEvent`), `"message"` (`RegisterMessage`), `"bucket"` / `"bucketMessage"` (AceBucket), `"frame"` (a raw `frame:RegisterEvent`) or `"unit"` (`frame:RegisterUnitEvent`, **one row per unit token**). Entries are REMOVED on the corresponding unregister and on `UnregisterAllEvents`. |
| `M.__timers()` | An array of every armed AceTimer handle, un-canceled `C_Timer` ticker and frame carrying an `OnUpdate` script. Entries leave on cancel and on `SetScript("OnUpdate", nil)`. |
| `M.__shownFrames()` | An array of every frame this build made that is currently shown, in creation order. |
| `M.__svWrites()` | An array of `{ path, value }` for every write that reached a watched SavedVariables tree since the last reset, in path order. |
| `M.__resetSvWrites()` | Re-baselines. Every write from here on is a write the next report carries. |
| `M.__watchSv(globalName)` | Adds a SavedVariables root the AceDB fake did not create — a host that writes `_G[name]` directly, as `LibKa0s-Perf-1.0`'s record ring does. Re-baselines. |
| `M.__printed()` | An array (a copy, not the live log) of every line that reached the chat frame. |
| `M.__resetPrinted()` | Empties it. |
| `M.__recordPrint(line)` | Records a line for a host printer that does not end at `DEFAULT_CHAT_FRAME`. |
| `M.__fire(event, ...)` | Dispatches to the **live registration set only** — AceEvent targets, buckets, and frames whose raw or per-unit registration is still in place. Answers how many handlers ran. |
| `M.__fireUnconditional(target, event, ...)` | Fires at `target` **whether or not it is still registered**. Answers 1 or 0. |

### Why `__fireUnconditional` is not a convenience

`M.__fire` over an empty registry runs nothing, so "no SavedVariables write, no printed line, no
frame shown" is true of a correctly stood-down addon **and** of a harness that lost the ability to
dispatch at all. Firing at a target whose registration has been removed is what proves a survivor
WOULD have been caught: the handler is still there, it is simply no longer reachable from the
client, and this reaches it anyway. A suite that omits that step is asserting on its own silence.

It resolves a handler in this order: the frame's `OnEvent` script; the recorded AceEvent handler;
and last, **the method named for the event**. The last rung is the one that matters after a
stand-down: AceEvent's default method IS the event's own name, the recorded handler is removed on
unregister — correctly, because that is what makes the registration set falsifiable — and the method
itself is still on the addon table. That method is precisely the survivor this member exists to
reach.

### The raw `frame:RegisterEvent` the frame stub used to forget

Through revision 21 `frame:RegisterEvent` was answered by the frame stub's metatable, which returned
the frame and remembered nothing, so an addon whose events sit on a plain `CreateFrame` — which is
most of them, and all of the per-unit ones — had a registration set no suite could see. Revision 22
records it.

| Member | Contract |
|---|---|
| `frame:RegisterEvent(event)` | Records into `frame.__frameEvents`. |
| `frame:UnregisterEvent(event)` | Removes it. |
| `frame:IsEventRegistered(event)` | Answers from the same table. Through 21 this came from the metatable and was truthy for every event, registered or not. |
| `frame:UnregisterAllEvents()` | Clears `__frameEvents` **and** `__unitEvents`. An AceEvent-embedded frame's own `UnregisterAllEvents` now clears both raw tables too. |

`RegisterUnitEvent` recorded as it always did, into `frame.__unitEvents`; the survey is what turns it
into one row per unit token, because the per-unit filter is what a stand-down widens by accident.

### `M.__timers` is both the pending queue and the live set

`M.__timers` **indexed** is, as it always was, the array of entries waiting for `__fireTimers`, and
every existing suite keeps indexing it. **Called** — `M.__timers()` — it answers the live set
instead. The two are different questions and both are needed: the queue answers *what is pending*,
the live set answers *is anything still going to wake up*, which a pending-queue read cannot — a
repeating ticker that has just fired is absent from the queue for a moment and is still very much
alive.

A metatable rather than a second member because the name is the answer: `M.__timers` is where every
consumer already looks for timers, and an `M.__liveTimers()` beside it would be a second place to
look and a second thing to forget.

### `AceBucket-3.0`

A bucket is a registration, and until this revision the kit had no model of one at all — so an addon
that coalesced its `UNIT_AURA` traffic through AceBucket had a registration set no suite could see,
and a stand-down that forgot `UnregisterAllBuckets` passed every test in its repo.

| Member | Contract |
|---|---|
| `t:RegisterBucketEvent(events, interval, callback)` | `events` is a string or an array. `callback` is a function or a method name that must exist on `self`. Answers a handle. |
| `t:RegisterBucketMessage(messages, interval, callback)` | The same, recorded under kind `"bucketMessage"`. |
| `t:UnregisterBucket(handle)` | Answers whether it was registered. |
| `t:UnregisterAllBuckets()` | Every bucket this target holds. |

Fired through `M.__fire`, a bucket coalesces onto the kit's one timer queue and calls back on
`M.__fireTimers()` with a table of what it saw — so two events in a window are one callback, and a
bucket left armed on a stood-down addon shows up in `M.__timers()` like any other timer. A bucket
unregistered between the event and the tick does **not** call back, as the real library's own
cancellation makes true.

It is deliberately not modeled beyond that. What a suite asks a bucket is "are you still registered"
and "did you fire"; a fuller fake would be a second implementation of a library nobody is testing.

### How SavedVariables writes are observed

**A snapshot diff, not an interception, and the reason is Lua 5.1 rather than taste.** A recording
proxy over `db.profile` would have to keep the data in a shadow table to see a write to a key that
already exists — `__newindex` fires only for an ABSENT key — and 5.1 has no `__pairs`, so every
`for k, v in pairs(db.profile)` in production code would then iterate nothing. That is a mock that
silently changes what the addon does, which is worse than one that reports a little less.

What the diff cannot see is a write of the identical value over itself. What it is asked to prove is
that a stood-down addon wrote **nothing**, and a write that changed nothing changed nothing. Where a
suite needs the stronger claim, it writes a sentinel first and asserts the sentinel survived.

Clearing a key counts as a write and is reported with a `nil` value: `db.profile.x = nil` is how a
setting is cleared, and a report that only saw additions would call that no write at all.

### Where the code lives

`mock_record.lua` is a **new file**, and `mock_base.lua` installs it itself — it is **not** opt-in
the way `mock_ids.lua` is. A survey a consumer forgets to switch on does not fail a stand-down
suite; it passes it over an empty table, which is the one outcome worse than having no suite. The
kit vendors as one folder, and a copy missing `mock_record.lua` **raises** on the first `base()`
rather than degrading.

The timer queue and the `AceDB-3.0` fake move there with the surveys, because the timer queue IS the
record of what is scheduled and a SavedVariables write has to land somewhere before it can be
reported. That also keeps `mock_base.lua` under `layout-§1`'s 1500-line cap, which it sat one line
under at revision 21 — the same reason revision 20's id lookups went to `mock_ids.lua`.

Nothing an existing suite calls moves or changes signature. `M.__libs["AceDB-3.0"]`,
`M.__fireTimers()`, `M.C_Timer` and `M.__timers` are all where they were.

### `run-automated-tests.sh`: two standing sections that had thinned

The RESULTS.md generator emitted **thinner** standing sections than the collection's earlier records
carried, and consumers noticed: one agent hand-patched its own `RESULTS.md` to compensate, which
`automated-tests-§4` forbids — `Disposition` is the one authored cell — and which the next re-vendor
would revert anyway. Both are fixed at source.

- **Lint** now NAMES the `exclude_files` entries it read out of `.luacheckrc`, rather than saying
  "sets a multi-line `exclude_files`; read it there". That deferral fired the moment the declaration
  wrapped onto a second line, which is every repo that excludes more than one path — precisely the
  repos where the scope of a `0/0` is worth stating. A standing section that defers to another file
  for the one fact it exists to carry is a section a reader stops reading.

  A `sed` range cannot extract the declaration, which is why it is `awk`:
  `sed -n '/a/,/}/p'` never ends a range on the line it began on, so the single-line form —
  `exclude_files = { "tests/_kit/" }`, which is what most of the collection carries — ran on past its
  own closing brace and swallowed the whole of `read_globals`, reporting every WoW API name as an
  excluded path.

- **Perf** now names the scenarios, as a table re-rendered from this run's own `tests/perf.lua`
  output — the column names come from that output's own header, so a repo whose scenarios report a
  different fifth column is rendered correctly without the script knowing what that column is. A
  bare count says a measurement happened; it does not say which code path was measured, and it
  cannot say that the scenario a reader cares about is missing from the run — which is the only way
  a perf record silently stops covering something.

Nothing in either section is hand-written or hardcoded: every figure comes from the run's own
artifacts, and a repo that adds an exclusion or a scenario gets it named on the next run without the
script being touched.

### Revision 22 is not the geometry flip

Revision 19 moved the flip, deleting `self.__geomLive and` from `GetHeight` and `GetWidth`, to "20 at
the earliest". Revisions 20, 21 and 22 do not ship it. A frame nobody armed still answers 0. The flip
is still its own revision with its own adoption.
