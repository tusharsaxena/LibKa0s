# `testkit` — version 13

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **13** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.16.0 |
| Status | **Current** |
| Supersedes | [version 12](version-12-docs.md) — the loader caches compiled chunks, and the runner can fan its suites out across processes |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `13` |

## What changed at this version

One file, `mock_base.lua`, and one function in it. `CreateFrame` records the arguments it is called
with on the frame it hands back, instead of throwing them away. Nothing is removed, nothing is
renamed, and no existing assertion changes meaning — the four recorded fields are new keys on a stub
that previously had no answer for them at all. `framework.lua` moves only for `Kit.VERSION` itself.

| | | Since |
|---|---|---|
| `frame.__frameType` | The first argument to `CreateFrame` — `"Frame"`, `"Button"`, `"ScrollFrame"`, … | **13** |
| `frame.__name` | The second: the global name the caller asked for, or `nil` for an anonymous frame | **13** |
| `frame.__parent` | The third, as passed — the parent frame object itself, not a name | **13** |
| `frame.__template` | The fourth: the inherited template string, e.g. `"UIPanelScrollFrameTemplate"` | **13** |

It was this:

```lua
M.CreateFrame = function() return stubFrame() end
```

and it is now this:

```lua
M.CreateFrame = function(frameType, name, parent, template)
  local f = stubFrame()
  f.__frameType, f.__name, f.__parent, f.__template = frameType, name, parent, template
  return f
end
```

### Why: a frame's name is load-bearing, and no suite could see it

This is fidelity rule 3 — *anything a test needs to observe must be recorded, not no-opped* — applied
to the one call every addon in the collection makes most often.

A frame's global name is not decorative. `UIPanelScrollFrameTemplate` derives its scrollbar
children's names from its parent's name, so an anonymous scroll frame leaves its scrollbar unnamed,
and `UISpecialFrames` is a list of global **names**, so a window registered for Escape-to-close is
registered by string or not at all. "Did this frame get the name it needs?" is therefore a question
a suite has to be able to ask about real production code — and until this revision it could not ask
it at all. The old stub took four arguments and kept none of them, so a frame created with the right
name and a frame created with none were the same table.

### Why: what that gap actually cost

It is not hypothetical. `LibKa0s-Widgets-1.0`'s copy window built its scroll frame anonymously and
shipped that way for **five versions**. Every consumer's suite was green throughout, because there
was nothing in the mock for a test to assert against: the scrollbar children the template would have
named were unnamed in the client, and unobservable out of it.

What surfaced it was not a test. It was `LibKa0s-DebugLog-1.0` minor 12 converging its own copy
window — the one copy of the four that **had** named its scroll frame — onto the shared member, at
which point the two implementations visibly disagreed about a frame that had been shipping wrong the
whole time. That is a defect found by a merge rather than by a gate, which is the outcome fidelity
rule 3 exists to prevent. `scrollName` is now a descriptor field on `CopyWindow`, and
`tests/test_widgets.lua` pins both branches of it — the named frame and the deliberately anonymous
default — which is a case that could not have been written against a kit that discards the argument.

### Why: recorded on the frame, not answered by `GetName()`

`GetName()` still returns `nil`, deliberately, and this is the line the kit does not cross.

`LibKa0s-Options-1.0`'s scrollbar patch **concatenates** `GetName()`. Handing it a real string would
send it down a different code path than the one it takes today — the mock would stop being a thing
production code is measured against and start being a thing that changes the measurement. Fidelity
rule 2 already requires `GetName()` to return a string or `nil` rather than the frame, because
concatenating a table raises; it does not require the mock to invent a name the client would have
assigned.

So the kit **records, it does not start behaving differently**. `__name` is an observation channel
for the test, sitting beside `__scripts`, `__unitEvents` and `__stopwatch`, and it is inert as far as
the code under test is concerned. Production code reads `GetName()` and sees exactly what it saw at
revision 12; a test reads `frame.__name` and sees what the caller asked for.

## For consumers: purely additive

Every consumer takes a kit revision, so it is worth being exact about what arrives.

The change adds four keys to a table that did not have them. It removes nothing, renames nothing, and
alters no return value: `CreateFrame` still returns a stub frame with the same methods and the same
metatable fall-through, and any lowercase or custom field an addon stashes on a frame is untouched.
A suite that never reads `__frameType`, `__name`, `__parent` or `__template` sees no difference at
all — same cases, same counts, same output.

The one thing worth doing after re-vendoring is looking for a **local** version of this. A suite that
had already worked around the gap by wrapping or replacing the mock's `CreateFrame` to record the
same arguments now has that recording twice; the local copy is redundant and should be deleted, so
the next reader is not left wondering which of the two is authoritative.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

There is nothing to switch on and nothing to configure. The suite should be green immediately; if it
is not, the failure is a local `CreateFrame` shim disagreeing with the kit's, not a behavior change.

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
