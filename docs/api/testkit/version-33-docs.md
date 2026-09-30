# `testkit` — version 33

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **33** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | never in a published tag: superseded inside v1.64.0, before the tag was published |
| Status | Superseded |
| Supersedes | [version 32](version-32-docs.md) — the README's copy and consumer counts |
| Superseded by | [version 34](version-34-docs.md) — the diagnostics contract has a run turn logging on |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `33` |

Everything revision 32 describes is unchanged here except what follows. **One file is added,
`mock_resize.lua`**, and three change: `mock_base.lua`, which loads it and passes every tracked
frame through it (two lines); `framework.lua`, whose `Kit.VERSION` is 33 and which changes in nothing
else; and `README.md`, whose file table names the new file. No public member, kit case or runner
output changes.

## What changed

### Mock frames record the resize surface (`mock_resize.lua`)

LibKa0s v1.64.0 makes the debug console, every `Widgets.CopyWindow` and the perf panel resizable from
a bottom-right grip (`LibKa0s-Core-1.0` minor 9's `MakeResizable`). Through revision 32 every call
that takes answered from `mock_base.lua`'s metatable, which hands back the frame itself, so
`IsResizable()` and `IsUserPlaced()` were truthy whatever the frame had been told and
`GetResizeBounds()` answered a table where the client answers four numbers (fidelity rules 1 and 3).
Every frame the mock tracks now carries, as plain recording methods:

| Method | What it records and answers |
|---|---|
| `SetResizable(v)` / `IsResizable()` | A boolean, `false` until set. Field `__resizable`. |
| `SetResizeBounds(minW, minH, maxW, maxH)` / `GetResizeBounds()` | The four numbers, answered as four numbers; four zeros before any bounds are set. Field `__resizeBounds`. |
| `StartSizing(point)` | The point (`__sizing`, default `"BOTTOMRIGHT"`) and a count (`__sizingCount`), and it **marks the frame user-placed**, as the client does. |
| `StartMoving()` | Marks the frame user-placed, as the client does. It was a metatable no-op through revision 32. |
| `StopMovingOrSizing()` | Clears `__sizing` and counts the stop (`__stopCount`). It does not clear the user-placed flag, which is the client's behavior and the reason a caller that wants a frame kept out of the layout cache has to. |
| `SetUserPlaced(v)` / `IsUserPlaced()` | A boolean, `false` until something sets it. Field `__userPlaced`. |

The user-placed flag is modeled because it is the edge the library's grip handles: the client
writes a named user-placed frame's anchor and size to `layout-local.txt`, so a resize that leaves a
window user-placed is how a size would reach the next session.

**What is not modeled, and why.** `StartSizing` does not change the frame's size; a suite states the
size the client's sizing would have left (`__setGeom`) and fires `OnSizeChanged`, as the Options
suites already drive a relayout. `SetSize`, `SetWidth` and `SetHeight` stay undefined and do not fire
`OnSizeChanged`: `mock_base.lua` leaves the setters off the frame on purpose, so a test can rawset a
recorder over one and rawset `nil` to restore, and the client runs `OnSizeChanged` from its layout
pass rather than inside the setter, so a synchronous fire would be a re-entrancy the client never
has. The client's layout cache itself, and its raise on sizing a frame that is not resizable, are
not modeled either; a `/reload` cannot be simulated headlessly.

**What a consumer suite may notice.** `IsResizable()`, `IsUserPlaced()` and `GetResizeBounds()` now
answer real values, so an assertion that passed only because they answered the frame (truthy) goes
red, as it should. `StartMoving()` now sets `__userPlaced`; nothing else about a drag changes.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change and no kit case name changes, so a consumer's
`docs/test-cases.md` does not change. A copy that leaves out `mock_resize.lua` fails at load, like
one missing `mock_record.lua` or `mock_events.lua`. A consumer's own prose that names the revision it
holds (`kit revision 32`) moves to 33 in the same commit.
