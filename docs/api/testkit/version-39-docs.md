# `testkit` — version 39

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **39** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.72.0 |
| Status | **Current** |
| Supersedes | [version 38](version-38-docs.md) — `M.__fireUnconditional` could not reach a handler registered under a method name, or as a function, once it was unregistered |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `39` |

Everything revision 38 describes is unchanged here except what follows. One file is added,
`latch.lua`, with one new member on the kit table, `Kit.assertLatchHoldOrder`. Four files change:
`framework.lua`, whose `Kit.VERSION` is 39 and which loads `latch.lua` and publishes its member
through `Kit.expose`; `mock_base.lua`, whose AceEvent `RegisterEvent` also keeps each event's
handler where unregister never reaches; `mock_record.lua`, whose `M.__fireUnconditional` reads that
record; and `README.md`, which says so. No public member is renamed or removed, no kit case name
changes and `M.__fireUnconditional`'s signature and return contract do not move.

## What changed

### `M.__fireUnconditional` reaches a method-name or function handler after unregister

`M.__fireUnconditional(target, event, ...)` is the falsification half of a stand-down suite: it fires
at a target whose registration is gone, to prove a survivor would have been caught. Through revision
38 it looked in three places — the target's `OnEvent` script, the live `__events[event]` and a method
named for the event — and answered 0 when none matched. `UnregisterEvent` and `UnregisterAllEvents`
clear `__events[event]`, correctly, so a handler registered as

```lua
addon:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")   -- a method name
addon:RegisterEvent("PLAYER_REGEN_ENABLED", function(event) end) -- a function
```

matched none of them after a stand-down, the handler never ran, and the 0 read like a quiet addon.
That is the most common way an addon registers an event, and the kit's own case covered only the
default handler, whose method name is the event's. DropWatcher's "disabled 3" case passed for that
reason (DropWatcher's 2026-10-14 review, F19).

From revision 39:

- **`RegisterEvent` keeps a never-cleared record** of each event's handler as the client would call
  it: the method name (the event's own name when none was given) or the function. It lives as
  `__kitEver` on the `__events` table's **metatable**, beside `__kitBuild`, so it is invisible to
  `next` and `pairs` over `__events`, to `M.__registrations()` and to every survey; `__events` itself
  is unchanged, recorded and cleared exactly as before. A later `RegisterEvent` for the same event
  replaces the record, and a second `Embed` in the same build carries it over. A target reused by a
  later build starts with no record, as it starts with no registration.
- **`M.__fireUnconditional` reads it** after the live `__events[event]` and before the last-resort
  method named for the event: a function is called `handler(event, ...)`, a method name
  `target[method](target, event, ...)`, CallbackHandler's own two calls. A method that merely shares
  the event's name is not what the registration named, so the record wins when both exist.
- **The return contract is unchanged:** 1 when a handler was reached, **0 when nothing was**, and it
  never raises. A suite proves reach by asserting the count, for example
  `assertEqual(M.__fireUnconditional(addon, e1) + M.__fireUnconditional(addon, e2), 2)`
  (`slash-commands-§7` step 6). The review's first fix raised on 0; that was declined (decision D2
  of DropWatcher's 2026-10-14 remediation) because it would turn red, on their next re-vendor, every
  consumer suite that calls this at a target with nothing to reach.

Five cases in this repository's `tests/test_mock_record.lua` pin it: the method-name handler after
`UnregisterAllEvents` (with the record invisible to `next(__events)`), a function handler after
`UnregisterEvent`, the latest of two registrations, 0 without a raise for a target that never
registered the event and for a non-table, and the record surviving a second `Embed`. They are **not**
kit cases, so a consumer's suites list does not change.

### `Kit.assertLatchHoldOrder`, the `slash-commands-§7` step-10 helper, in a new file `latch.lua`

Step 10 of the disabled-state conformance suite (two holds, one latch: releasing one hold must not
resurrect an addon the other still holds down) was written by hand in every addon, each against its
own seams. From revision 39 the kit ships it. `latch.lua` returns `function(Kit)`, `framework.lua`
loads it once from its own folder beside `secrets.lua`, and `Kit.expose` copies the member onto the
consumer's test table (`T.assertLatchHoldOrder`). Since 39.

```lua
Kit.assertLatchHoldOrder{
  lifecycle  = NS.Lifecycle,   -- Hold(key), Release(key), IsHeld(key)
  perfHold   = NS.HOLD_PERF,   -- the perf hold's key ("perf")
  setEnabled = setEnabled,     -- function(bool): the addon's single enable write seam
  regSet     = regSet,         -- function(): the live registration set, an array
  key        = nil,            -- optional function(entry) -> string
  label      = "MyAddon",      -- optional; leads every failure message
}
```

| Field | Required | Meaning |
|---|---|---|
| `lifecycle` | yes (table) | The addon's `LibKa0s-Lifecycle-1.0` instance, or anything answering `Hold`, `Release` and `IsHeld` |
| `perfHold` | yes (string) | The perf hold's key |
| `setEnabled` | yes (function) | The enable write seam the `enable` / `disable` verbs and the settings toggle all reach |
| `regSet` | yes (function) | Returns the live registration set as an array. A string entry is its own key; a table entry is keyed by its `target`, `kind`, `event` and `unit` fields (the shape of `M.__registrations()`'s rows) |
| `key` | no | Overrides how an entry is keyed |
| `label` | no | Prefixed to every failure message |

What it asserts, in order:

1. **Baseline.** `R_on = regSet()`, keyed and sorted, is non-empty. Raised before anything is held.
2. **Order A (perf held first).** `Hold(perf)`; `setEnabled(false)`; `Release(perf)`; the set is
   empty ("releasing perf resurrected an addon the player had disabled"); `setEnabled(true)`; the
   set equals `R_on`.
3. **Order B (disabled first).** `setEnabled(false)`; `Hold(perf)`; `setEnabled(true)`; the set is
   empty ("enabling resurrected an addon the perf hold was holding down") and perf is still held;
   `Release(perf)`; the set equals `R_on`.

"Equals `R_on`" is compared **by key**, never by count alone, so a stand-up that rebuilds the same
number of registrations under different names or units fails. Each order runs under `pcall`;
whatever happens, the helper then releases perf and calls `setEnabled(true)`, and a failure is
re-raised with its order named (`order A` / `order B`). Invalid `opts` raise naming the field. On
success it returns `R_on`'s sorted key list.

Two choices are deliberate. The perf hold is taken **through the latch directly**, not through
`LibKa0s-Perf-1.0`'s `P.Suspend`: the invariant is the latch's, and the hand-written cases it
replaces did the same; a suite that wants the `P.Suspend` route drives it in a case of its own. And
the helper does **not** carry the consumer's `testing-§12` falsification claim: the consumer keeps
its `-- red under: ...` comment at the call site.

Nine cases in this repository's `tests/test_kit_latch.lua` pin it, against the real
`LibKa0s-Lifecycle-1.0` and a recording host: a conformant host passes both orders and is left up
with no hold; an enable path that stands up directly fails order B; a disable path that takes no
hold fails order A; a same-size rebuild under different keys fails; an empty `R_on` fails; the
label leads the message; table rows and `opts.key` are keyed; missing fields raise. They are **not**
kit cases, so a consumer's suites list does not change. From DropWatcher's 2026-10-14 review (F21).

**What a consumer may see on re-vendor.** A stand-down case that fires unconditionally at a handler
registered under a method name, which ran nothing before, now runs it. If that handler writes
SavedVariables, prints or shows a frame while disabled, the case goes red for a real reason: the
addon's guard is the fix, not the test.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

The suites list and every kit case name are unchanged. A consumer's own prose that names the
revision it holds (`kit revision 38`) moves to 39 in the same commit, and its stand-down suite
should assert the counts `M.__fireUnconditional` returns. A consumer whose step-10 case is written
by hand may switch it to `T.assertLatchHoldOrder`, keeping its `-- red under:` comment at the call
site; nothing requires it to.
