# `testkit` — version 16

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `test_eol.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **16** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.30.0 |
| Status | **Current** |
| Supersedes | [version 15](version-15-docs.md) — the runner writes the record, `test_eol.lua` ships, and the geometry opt-in lands |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `16` |

## What changed at this version

Four gaps, all found by one consumer. AuraMaster had to shim each of them locally, and each had a
named issue on this repo: [#27](https://github.com/tusharsaxena/LibKa0s/issues/27),
[#28](https://github.com/tusharsaxena/LibKa0s/issues/28),
[#29](https://github.com/tusharsaxena/LibKa0s/issues/29) and
[#30](https://github.com/tusharsaxena/LibKa0s/issues/30). Two files change: `mock_base.lua`, where
three Ace fakes move closer to the real Ace3, and `vendor_sync.lua`, which registers one more case.
`framework.lua` changes only its revision number. `loader.lua`, `test_eol.lua` and
`run-automated-tests.sh` are untouched.

| | At 15 | At 16 |
|---|---|---|
| `AceGUI:Release(w)` | Absent. Calling it raised, so every consumer that releases a widget carried its own | Modeled on the real one's order, plus a recorder: `w.__released`, `AceGUI.__released` |
| A target made by `AceEvent:Embed(t)` | Messages only; `t:RegisterEvent` raised | `RegisterEvent`, `UnregisterEvent` and `UnregisterAllEvents`, recorded on `t.__events` by the **same three functions** the `NewAddon` target carries |
| The `NewAddon` target's console mixins | `Print` only | `Print` **and** `Printf`, both through one AceConsole-shaped local, both honoring a chat-frame first argument |
| `VendorSync.register` | One case per payload pair | One more: the runner's recorded mode in the consuming repo's git index |

What did **not** change matters as much: `GetHeight` and `GetWidth` still answer 0 for every frame
nobody armed. See [Revision 16 is not the geometry flip](#revision-16-is-not-the-geometry-flip).

### `AceGUI:Release`, and the order it happens in (#27)

The kit's AceGUI factory handed widgets out and never took one back. A consumer whose settings page
releases the previous render's widgets — AuraMaster's and AbsorbTracker's chrome bands both do —
raised on the call, so each carried its own `Release`. Two hand-written copies of one fake is the
failure the kit exists to prevent.

It follows `AceGUI-3.0.lua`'s `Release`, step for step:

1. **Return at once if the widget is already being released.** The real guard is the field
   `isQueuedForRelease`, and it stops a release reached from the widget's own `OnRelease` callback.
   It is set for the duration and cleared at the end, exactly as the real one does.
2. **Hide the frame.**
3. **Fire `"OnRelease"`** through the widget's callbacks, as `fn(widget, "OnRelease")`, while the
   widget still has its children and its callbacks. LibKa0s's own `OptionsWidgets.lua` relies on
   that order: it hides its band texture from an `OnRelease` callback, which is only safe because
   AceGUI fires the callback before it clears them.
4. **`ReleaseChildren`**, then the widget's own **`:OnRelease()`** method if it has one.
5. **Wipe the widget.** `userdata` and the callbacks are cleared **in place**, so a widget handed
   back cannot fire a stale handler or carry stale data. The size fields the real one nils go too:
   `width`, `height`, `relWidth`, `relHeight`, `noAutoHeight`, and `relativeWidth`, which is this
   fake's recorder for `SetRelativeWidth`. The frame's points are cleared and its parent is reset
   to `UIParent`.

Every widget from this factory now carries `userdata = {}`, AceGUI's documented per-widget scratch
table, and a **`widget:Release()`** method that is `AceGUI:Release(widget)`, as the real
`WidgetBase.Release` is. Correct code may call either form.

On top of that sits the recorder, which a test needs and the client does not:

| Member | What it records |
|---|---|
| `widget.__released` | `true` once the widget has been released |
| `AceGUI.__released` | Every widget released, in the order it happened |
| `widget.isQueuedForRelease` | The real guard's own field. It is `true` only while the release runs, and `nil` afterwards |

**`AceGUI:Release(nil)` raises**, as it does in the client on its first line. AuraMaster's shim
returned quietly instead, and fidelity rule 1 is the reason the kit does not: a host that can pass
nil has a bug the suite must be able to see.

**Releasing the same widget twice raises** `"Attempt to Release Widget that is already released"`,
the real message. Double release is the typical `Release` bug: a page that releases a ledger of
widgets after a render, and holds one twice, has it. The client raises from `delWidget` at the
**end** of the second release, after re-running the steps above. This factory never reuses a
widget, so any second release of the same object is the bug, and the fake raises at the **top**,
before it touches the widget. The second release is not recorded in `AceGUI.__released`.

**Two deliberate differences from the real one.** The real `Release` puts the widget in a pool that
a later `Create` may hand back. This factory never reuses a widget, so a `Create` after a `Release`
is always fresh. And the children go through the widget's own `ReleaseChildren`, which on a widget
from this factory **forgets** them rather than releasing each one through `Release`. The real
`ReleaseChildren` releases each child. Making the fake do that would change every re-rendering
panel in the collection, because a panel calls `ReleaseChildren` on every render. That is a
revision of its own, and this one does not do it. So the children of a released widget are gone
from `children`, but they are not marked `__released` and they are not in `AceGUI.__released`.

### AceEvent's event half on an embed (#29)

The real `AceEvent:Embed` stamps seven mixins onto its target, and three of them are the **event**
half: `RegisterEvent`, `UnregisterEvent` and `UnregisterAllEvents`. The kit's Embed modeled only the
message half. So a module that registers its game events on a target of its own — the
`NS.NewBusTarget()` shape `architecture-§4` prescribes and `events-frames-taint-§1` requires — hit a
nil field headlessly, while the `NewAddon` target, the one place the kit did model events, worked.

Both call sites now share **one implementation**. The three functions are module-level locals in
`mock_base.lua`, stamped onto both targets by one helper, so they are the same function objects on
both. `tests/test_mock_base.lua` asserts that identity, so the two cannot drift apart.

| Member | Contract |
|---|---|
| `t:RegisterEvent(event, handler)` | Validated first, then `t.__events[event] = handler or true`. Returns `t` |
| `t:UnregisterEvent(event)` | `t.__events[event] = nil`. Raises when `event` is not a string. Returns `t` |
| `t:UnregisterAllEvents()` | Clears `t.__events` **in place**, so a table a test captured stays the live one. Messages are untouched, as they are in the client, where the two live in separate CallbackHandler registries. Returns `t`. **New on the `NewAddon` target too** |
| `t.__events` | `[event] = handler` (or `true`). A test fires a handler the way CallbackHandler fires a function ref: `t.__events[event](event, ...)` |

**`RegisterEvent` refuses what CallbackHandler refuses.** A registration the client raises on must
not pass headlessly (fidelity rule 1), so the fake checks the same things, with the same messages:

- The event must be a string.
- The method defaults to the event's own name, so `t:RegisterEvent("PLAYER_LOGIN")` needs a
  `t.PLAYER_LOGIN` function.
- The method must be a function or a string, and a string must name a function `t` carries at the
  time of the call. `t:RegisterEvent(e, "OnTypo")` raises.

What is recorded does not change: the handler as given, or `true`. A string method is recorded as
the string, and a test fires it the way CallbackHandler does, `t[method](t, event, ...)`. The
optional third argument, CallbackHandler's `arg`, is accepted and not recorded. Every production
registration in the ten consumers already passes these checks; they were measured against it (see
below).

**The registry belongs to the mock build, not the target.** The real registry lives inside the
library, keyed by `(event, target)`. The fake keeps one per build, keyed by target, and each
`Embed` or `NewAddon` points `t.__events` at the target's table in it. So a second `Embed` in the
same build forgets nothing, and a target table that a later build embeds again starts with nothing
registered, as a fresh client library would. This is the same per-build isolation the message bus
has always had. Before revision 16 the `NewAddon` target got a fresh table on every call. No
consumer in the collection passes `NewAddon` or `Embed` a table carrying its own `__events`.

### `Printf`, and the reclaim it exists to test (#30)

AceConsole-3.0's mixins are `Print` **and** `Printf`. An addon that publishes its own `NS.Printf`
on the addon object gets it clobbered by `NewAddon` exactly as it gets `NS.Print` clobbered, and
must take both back afterwards (`architecture-§2`, anti-pattern #36). The kit stamped only `Print`,
so an addon that forgot to take `Printf` back passed every suite.

Both mixins now end in one local, as they do in `AceConsole-3.0.lua`:

| Call | Renders |
|---|---|
| `t:Print(...)` | `"|cff33ff99<t>|r:"`, then every argument, space-joined |
| `t:Printf(fmt, ...)` | The same prefix, then `string.format(fmt, ...)` |
| `NS.Printf(fmt, ...)`, called **bare** | `fmt` lands in `self`: it renders green with a trailing colon, and what *follows* it is formatted — `NS.Printf("%d items", 3)` prints `"|cff33ff99%d items|r: 3"` |
| `NS.Printf(fmt)`, bare with nothing after it | **Raises**, as `string.format()` with no arguments does in the client |
| `t:Print(frame, ...)` / `t:Printf(frame, fmt, ...)` | A first argument with an `AddMessage` member is the frame to print to, instead of `DEFAULT_CHAT_FRAME` |

**The chat-frame branch is new for `Print` as well.** It is the real behavior and the two mixins now
share the code that implements it. A clobbered `NS.Print` called with a chat frame as its second
argument now prints to that frame rather than to the default one. The default is still the harness
process's `DEFAULT_CHAT_FRAME` global, read at call time, and a nil one still prints nothing.

### The runner's recorded mode, in every consumer (#28)

`automated-tests-§2` requires that the vendored-payload gate assert
`tests/_kit/run-automated-tests.sh` is recorded `100755`. Byte identity cannot see a mode: the
executable bit is not in the file's bytes and `cp` does not carry it. Nor can the filesystem show
it. The collection runs on DrvFs, which reports `rwxrwxrwx` for everything, with
`core.fileMode=false`. The git index is the only place the bit lives. `tests/test_kitsync.lua` has
asserted it for this repo's two copies since revision 11, and no consumer had any check at all.

`VendorSync.register` now registers one more case, after the pair cases:

```
the automated-test runner is recorded executable (100755)
```

It runs `git -C <root> ls-files -s -- <runner>` and asserts the mode is `100755`. An untracked
runner fails with a message saying so. Where the index cannot be read — no `io.popen`, no git, or a
`root` that is not a work tree — it **skips** with the reason, which always ends with the runner's
mode "was NOT checked". It never passes silently. It needs no sibling LibKa0s checkout, which is why
it is a case of its own and not a third pair. A missing sibling must not skip it.

| Opt | Default | Use |
|---|---|---|
| `runner` | `"tests/_kit/run-automated-tests.sh"` | The runner's path, relative to `root` |
| `runnerCase` | `"the automated-test runner is recorded executable (100755)"` | The case name, for a repo that keeps its own naming |

**In this repo** the default path is also correct, because LibKa0s vendors its own kit to
`tests/_kit/` on the same terms as a consumer. LibKa0s still cannot run `VendorSync.register` end to
end, since there is no sibling to compare against. So `tests/test_kitsync.lua` drives the new case
through a stand-in test table. It asserts a pass on this repo's own vendored copy, a failure on a
`100644` path and on an untracked one, and a skip with a reason for a missing work tree and a
missing `io.popen`. Its existing case, which checks both copies of the runner here, stays: the
consumer case reads one path, and this repo has two.

### Revision 16 is not the geometry flip

[Version 15](version-15-docs.md#what-revision-16-will-do-and-why-it-is-not-this-one) said that
revision 16 would delete the `self.__geomLive and` from `GetHeight` and `GetWidth`. **It does not.**
Both still read `(self.__geomLive and self.__geomH) or 0`, and a frame nobody armed still answers 0.
`tests/test_mock_base.lua`'s first case still pins that.

The plan behind the number still holds: the flip is its own revision, with its own adoption, and
it is shared with nothing. Roughly 308 test files across ten repositories lean on geometry answering
zero, and shipping the flip together with four unrelated fixes is exactly the version of it that
plan exists to rule out. Only the number moves: the flip is the next revision that ships it alone,
17 at the earliest. The comment in `mock_base.lua` says so as well.

## For consumers: +1 case, one collision, and shims to delete

**Measured, not assumed.** This revision's `testkit/` was dropped into fresh clones of all ten
consumers at their current `master`. Every total moved by exactly one — the runner-mode case, which
passes in all ten. The table was measured again after the double-release raise, the wipe, the
`RegisterEvent` validation and the per-build registry went in, and every row came back identical:

| Consumer | Before | After |
|---|---|---|
| AbsorbTracker | 558 / 2 skipped / 560 | 559 / 2 / 561 |
| BankLedger | 847 / 2 / 849 | 848 / 2 / 850 |
| ConsumableMaster | 794 / 2 / 796 | 795 / 2 / 797 |
| KickCD | 868 / 2 / 870 | 869 / 2 / 871 |
| LootHistory | 718 / 2 / 720 | 718 / **1 failed** / 2 / 721 |
| MultiMeters | 1746 / 2 / 1748 | 1747 / 2 / 1749 |
| PanelMaster | 781 / 2 / 783 | 782 / 2 / 784 |
| PrettyChat | 326 / 2 / 328 | 327 / 2 / 329 |
| WhatGroup | 566 / 2 / 568 | 567 / 2 / 569 |
| AuraMaster | 249 / 2 / 251 | 250 / 2 / 252 |

The two skips in every row are the vendored-payload pair cases. The clones had no sibling LibKa0s
beside them, so those cases skipped in both runs and say so.

**LootHistory is the one collision, and the revision cannot avoid it.** Its `tests/wow_mock.lua`
wraps `AceEvent:Embed` and installs a private event registry only when
`rawget(obj, "RegisterEvent") == nil` after the kit's Embed has run. At 16 that is never true, so
its `M.__fireAceEvent` drives nothing, and
`browser: a combat transition re-applies visibility through the private event target` goes red. The
collision is #29's fix itself. The adoption is to delete that shim and fire the recorded handler
directly: `target.__events[event](event, ...)`, reaching the target through the module's test seam.

**Shims this revision makes redundant.** Delete them in the re-vendor commit, so the next reader is
not left wondering which of two answers is authoritative:

- **AuraMaster**: `tests/wow_mock.lua`'s three blocks — "AceGUI:Release", "AceConsole's Printf" and
  "AceEvent's event half on an embed" — with their header bullet, and the local runner-mode case in
  `tests/test_vendor_sync.lua`. The kit registers the same check, named without the `vendor: `
  prefix. Measured with all four removed and this revision in: 248 passed, 2 skipped, 1 failed out
  of 251, the same total as today, since one local case goes out and one kit case comes in. The one
  failure is AuraMaster's own citation gate: `DEPENDENCIES.md:45` cites
  `tests/test_vendor_sync.lua:36`, a line the deletion removes. Point the citation at the kit's
  `tests/_kit/vendor_sync.lua` in the same commit.
- **AbsorbTracker**: the `AceGUI:Release` shim in `tests/wow_mock.lua`, which overwrites the kit's.
  Measured with the shim removed: 559 passed, 2 skipped, 561 total, the same as with it, so nothing
  there releases a widget twice.
- **PrettyChat**: `object.Printf = noop` in its `NewAddon` wrapper overwrites the kit's `Printf`, and
  with it the forgotten-reclaim failure this revision exists to surface. Not measured with the line
  removed.

BankLedger and MultiMeters replace the AceEvent fake wholesale and are unaffected by #29.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

Nothing to switch on. Expect `+1` on the total, and move `docs/test-cases.md` and the README
`[tests]` badge in the same commit. Expect the runner-mode case to pass, since every consumer's
runner is already recorded `100755`. If it fails, the fix it names is
`git update-index --chmod=+x tests/_kit/run-automated-tests.sh`. Delete the shims listed above in
the same commit. Anything else that moves is not this kit revision.

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
