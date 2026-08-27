# `testkit` — version 14

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **14** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased |
| Status | **Current** |
| Supersedes | [version 13](version-13-docs.md) — `CreateFrame` records its arguments on the frame it returns |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `14` |

## What changed at this version

One file, `mock_base.lua`, and one gap in `stubFrame`. `SetEnabled`/`Enable`/`Disable`/`IsEnabled`
now track a real boolean on the frame, the same way `Show`/`Hide`/`IsShown` already track `__shown`.
`framework.lua` moves only for `Kit.VERSION` itself.

| | | Since |
|---|---|---|
| `frame.__enabled` | The frame's tracked enabled state, `true` unless `SetEnabled(false)`/`Disable()` was called | **14** |
| `frame:SetEnabled(v)` | Sets `__enabled` to `not not v` | **14** |
| `frame:Enable()` | Sets `__enabled` to `true` | **14** |
| `frame:Disable()` | Sets `__enabled` to `false` | **14** |
| `frame:IsEnabled()` | Returns `__enabled` | **14** |

It was this (nothing — the four methods fell through the blanket capitalized no-op):

```lua
setmetatable(f, { __index = function(_, k)
  if type(k) == "string" and k:match("^%u") then
    return function() return f end
  end
  return nil
end })
```

and it is now this, added beside the existing `Show`/`Hide`/`IsShown` block, ahead of that
metatable's fall-through:

```lua
f.__enabled = true
function f:SetEnabled(v) self.__enabled = not not v; return self end
function f:Enable() self.__enabled = true; return self end
function f:Disable() self.__enabled = false; return self end
function f:IsEnabled() return self.__enabled end
```

### Why: a stub that silently succeeds is worse than no stub

This is fidelity rule 1, and rule 2 (*"Geometry and naming must return real values, not the
frame"*) applied to the one boolean it was missed on. `SetEnabled` and `IsEnabled` are ordinary
Frame API — every one of the collection's addons that draws a button can call them — and until this
revision the mock answered `IsEnabled()` with the frame table itself, which is always truthy. An
assertion like `assertFalse(button:IsEnabled())` could not fail no matter what `SetEnabled` was
actually told, in this repo's own suite or in any consumer's.

### Why: it surfaced now

`LibKa0s-Options-1.0`'s new `O.TabStrip` (OptionsWidgets.lua) marks its selected tab the way
Blizzard's own tab groups do — by disabling it, rather than by a second piece of art — and its own
test tried to assert exactly that: the active tab's button answers `IsEnabled() == false`. Against
the old stub that assertion could not fail, which means it was not actually testing the thing it
claimed to. A gap that was previously never queried this way became a hole the first caller fell
into.

## For consumers: purely additive

Every consumer takes a kit revision, so it is worth being exact about what arrives.

The change adds one boolean field and four methods to a stub that previously answered all four
methods with a no-op. It removes nothing, renames nothing, and changes no other method's behavior:
`Show`, `Hide`, `IsShown`, `SetScript` and everything else on `stubFrame()` are untouched. A suite
that never calls `SetEnabled`/`Enable`/`Disable`/`IsEnabled` sees no difference at all — same cases,
same counts, same output.

The one thing worth doing after re-vendoring: if a suite already worked around the gap with a local
`SetEnabled`/`IsEnabled` shim (assigning them directly on a mocked button, or checking a custom field
instead of the real method), that local shim is now redundant and should be deleted so the next
reader is not left wondering which of the two is authoritative.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

There is nothing to switch on and nothing to configure. The suite should be green immediately; if it
is not, the failure is a local `SetEnabled`/`IsEnabled` shim disagreeing with the kit's, not a
behavior change.

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
