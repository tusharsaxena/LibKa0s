# `LibKa0s-DebugLog-1.0` — version 7

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the DebugLog surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-DebugLog-1.0` |
| Files and minors | `DebugLog.lua` minor **7** |
| Shipped in | v1.5.0 |
| Status | **Current** |
| Supersedes | [version 6](./version-6-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-DebugLog-1.0").MODULES` → `{ DebugLog = 7 }` |

`Since` in the tables below is the DebugLog minor in which the member first appeared. Minors 1 and 2
were never tagged, so a `Since` of 1 or 2 means "present for as long as any consumer could have had
this major".

## What this major is

The on-screen debug console: a movable window with a colour-coded log, a copy box, a plain-text
buffer, and the one seam that turns logging on and off.

It exists because the console is the most-duplicated thing in the collection — seven hand-transcribed
copies of a window the standard already specifies down to the hex codes, drifting one digit at a
time. What is genuinely per-addon is only the *content* of what gets logged, so everything else lives
here and the host supplies a descriptor.

Two decisions are worth stating up front, because both look like details and neither is:

- **The enable flag is not stored here.** The host owns it, and the library reads and writes it
  through the required `isEnabled`/`setEnabled` pair. A library keeping its own copy would leave two
  truths about whether logging is on, and the host's is the one its slash command and its settings
  panel read.
- **Every frame is per-instance**, and every frame global is derived from the descriptor's `name`. A
  lib-level singleton would give two addons one console — and, worse, one `UISpecialFrames`
  registration, so Esc would close whichever window registered last.

Like every module but Core, it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework,
and it returns before `NewLibrary` if Core is missing or below the minor it needs.

## What changed at this version

**The gated sink can no longer raise on a format it cannot fill.** `Debug(tag, fmt, ...)`
routes every vararg through `safeToString` and then hands the results to `string.format`.
That covers a `%s` slot — but a WoW combat "secret" is a **number**, and a host logging one
through a **numeric** slot (`Debug("Absorb", "total=%d", UnitGetTotalAbsorbs("player"))`)
handed `"<secret>"` to `%d`, where `string.format` raises exactly as the unguarded secret
would have. The guard made the common case safe and left the case it existed for no safer.

The format is now `pcall`’d. On failure the line still **lands**: the format string
verbatim, then the stringified arguments, space-joined — a dropped line is the other way to
lose the diagnostic. **A satisfiable format renders byte-for-byte as it did at minor 6**, so
no host’s console output changes; the only behaviour that moved is a path that threw.

Nothing to do at a call site. Found by WhatGroup, whose hand-written console had guarded
this and whose suite went red on the first load of this one.

## Lib-level surface

| Name | Since | Meaning |
|---|---|---|
| `lib.FormatPlain(ts, tag, msg)` | 1 | `"<ts> \| [<tag>] <msg>"` — what the buffer holds and the copy window mirrors. Pure and lib-level, so a host's tests call it directly. |
| `lib.FormatColored(ts, tag, msg)` | 1 | The console view's line: timestamp muted steel-blue (`6f8faf`), `[tag]` muted tan/gold (`c9a66b`), separator and message default white. |
| `lib.MAX_BUFFER` | 1 | The line cap (500). Fixed by the standard rather than by the host: the cap and the message frame's own `SetMaxLines` must move together or the visible log and the copied buffer diverge. |
| `lib.MakeCloseButton` | 1 | Re-exported from Core, so a host that draws a close button on its own windows gets it from **one** factory rather than growing a lookalike. Forwards through the `core` table at call time, not captured at load. |
| `lib.STRINGS` | 1 | Every user-visible string, keyed for the descriptor's `L` override. Tags (`[Debug]`, `[Init]`) are deliberately *not* here — log-scrapers and host tests read them, so they are structure rather than prose. |
| `lib.MODULES` | 1 | `{ DebugLog = <minor> }` — the live minor of every file in this major. |
| `lib:New(descriptor)` | 1 | Build a console for one host. See below. |

## The console descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `name` | string | yes | 1 | Seeds the frame globals `<name>DebugWindow`, `<name>DebugCopyWindow` and `<name>DebugCopyScroll`. Two hosts sharing a name would clobber each other's globals and each other's Esc handler. |
| `title` | string | yes | 1 | The human title; the library appends its own `" — Debug"`. |
| `font` | string | yes | 1 | Path to the monospace font the console renders in. Required rather than defaulted because a nil here raises inside `SetFont`, halfway through building a window that is then un-closable. |
| `fontSize` | number | no | 1 | Defaults to `10`. |
| `isEnabled` | function | yes | 1 | Reads the host's logging flag. The library never stores it. |
| `setEnabled` | function | yes | 1 | Writes it. Always handed a real boolean. |
| `print` | function(line) | no | 1 | Where the chat acknowledgement goes. Defaults to the chat frame, untagged — a host that wants its own tag passes its printer, which is what every Ka0s addon does. |
| `safeToString` | function | no | 1 | Defaults to Core's. Every logged value goes through it, so a combat-protected value renders rather than raising downstream. |
| `initSummary` | function | no | 1 | Returns one line naming version/schema/profile. The library owns *when* it is emitted (on enable, as the `[Init]` line); only the host can know what it says. |
| `onVisibilityChanged` | function | no | 1 | Fired on both `OnShow` and `OnHide`, so a host can repaint a settings panel whose checkbox mirrors the console's visibility. |
| `slash` | string | no | 1 | Composes the checkbox tooltip's `"<slash> debug"` reference. |
| `L` | table | no | 1 | Locale override, keyed identically to `lib.STRINGS`. **Pass a PLAIN table holding only the keys you actually translate — never an addon-wide locale table.** See [The `L` trap](#the-l-trap). |
| `skin` | table | no | 1 | Overrides `Core.SKIN`. Handed straight to `Core.ApplySkin`, so a partial table (backdrop fields only, no `innerBorder`) degrades to a plain backdrop rather than raising. |
| `applySkin` | function | no | **4** | Owns the **whole** skin job, for the console and the copy window alike, replacing the library's own. As of Core minor 3 the library's own default already draws the full Ka0s edge, so this is for chrome that differs in SHAPE rather than colour, or for a host that wants its console to track its own re-skin seam. Handed the fully-built frame — `frame.title` and `frame.divider` are already assigned — and run after the Hide and the Esc wiring, so a surprise inside it cannot strand a visible window nobody can close. |
| `makeCloseButton` | function | no | **4** | `function(parent, onClick)` → button or nil. Overrides Core's × on **both** windows. May answer `nil`, exactly as Core's own does where `CreateFrame` is unavailable. The Copy/Clear title-bar offsets are derived from the returned button's width, so a button wider than Core's 18 pushes them out of its way rather than colliding. **Rarely the right field, and it has no consumer today** — these are the library's windows, so they wear the library's close glyph, and a host whose own main window closes with something else must not push that difference onto them (`standalone-windows`). Pass it only for a close control genuinely *different in kind*. |

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `buffer` | 1 | The plain-text lines, a dense array, newest last and capped at `MAX_BUFFER`. Read directly by host tests across the collection — it is part of the contract, not an internal. |
| `FormatPlain` / `FormatColored` / `MakeCloseButton` | 1 | The lib-level members, mirrored onto the instance so a host holds one object. |
| `Text(key)` | 1 | Resolve one user-visible string, the descriptor's `L` first, then `lib.STRINGS`. |
| `Add(tag, msg)` | 1 | Append one line. **Ungated on purpose**: the enable seam's own bracket lines and a host's perf output both have to land whatever the flag says. |
| `Debug(tag, fmt, ...)` | 1 (raise-proof format: **7**) | The gated sink, and a plain function rather than a method — hosts bind it bare (`NS.Debug = D.Debug`) and call it from everywhere. Zero-allocation when off: it returns before building the argument table. Every vararg goes through `safeToString`, and **as of minor 7 the `string.format` itself is `pcall`’d**: a format the stringified arguments cannot satisfy (a secret reaching a `%d` slot) lands as the format string followed by those arguments, space-joined, instead of raising inside the sink. |
| `BufferSize()` | 1 | `#buffer`. |
| `LastLine()` | 1 | The newest buffered line. |
| `FindLine(substr)` | 1 | The newest line containing `substr`. Plain search, not a pattern — callers are looking for a tag or a message fragment, neither of which is written as a Lua pattern. |
| `Clear()` | 1 | Empty the log frame and the buffer, then repaint the scrollbar and the status line. |
| `UpdateScrollBar()` | 1 | Re-sync the slider with the message frame's scroll offset. The two run in opposite directions, so they are related by `maxOffset - value`. |
| `UpdateStatus()` | 1 | Repaint the `N / MAX` line counter. |
| `CopyText()` | 1 | The whole buffer as one newline-joined string. |
| `ShowCopy()` | 1 | Open the copy window over the console, filled with the buffer, focused and selected — Ctrl+C, then Esc. |
| `Show()` / `Hide()` / `IsShown()` / `Toggle()` | 1 | Window visibility. `Hide` never builds a frame: a settings panel calls `IsShown` on every refresh, and a `Hide` that constructed a window would build one nobody asked for. |
| `IsEnabled()` | 1 | The host's flag, read through the descriptor and coerced to a boolean. |
| `RefreshHeader()` | 1 | Repaint the title-bar toggle — `Debug: ON` green, `Debug: OFF` red. |
| `SetEnabled(on)` | 1 | The single seam for changing debug state: writes the host's flag, repaints the header, prints the colour-coded chat ack, brackets the console with a `[Debug]` line, and on enable follows it with the descriptor's `[Init]` summary. The slash command and the header toggle both come through here, so the ack and the header label can never disagree. |
| `ConsoleCheckbox()` | 1 | The data contract below. |
| `_toggleClickForTest` / `_frameForTest` | 1 | Test seams. A headless mock's `Show`/`Hide` track visibility without firing `OnShow`/`OnHide`, and stub `GetScript`, so the click handler and the visibility callback are only reachable directly. |

## The `ConsoleCheckbox()` data contract

`ConsoleCheckbox()` returns a plain table, and that is the whole point:

```lua
{ label = "Debug console", tooltip = "…", get = function() … end, set = function(v) … end }
```

It is **data, not a widget** — a *data contract*, consumed by the Options module and rendered by it,
with the host assembling the two. Neither library ever reaches for the other: DebugLog does not know
an options library exists, and the options library never resolves `LibKa0s-DebugLog-1.0`. That is
deliberate, and it is what keeps a real dependency cycle from forming between two majors that would
otherwise each need the other at load time.

The checkbox toggles the window's **visibility** only, never the logging flag. Those are separate
controls, and a user who closes the console does not expect logging to stop — which is exactly what
the tooltip says, composed from the descriptor's `slash`.

## The `L` trap

`L` must be a **plain table holding only the keys you actually translate** — never an addon-wide
locale table. Many locale tables carry a metatable whose `__index` answers the key itself, so a
missing `L["STEP_START"]` answers `"STEP_START"` rather than `nil`, and the library's own default
never gets a chance to resolve. From DebugLog minor 3 onward the resolver uses `rawget`, so a
metatable-backed table no longer poisons the lookup — but passing a scoped table is still the
contract, because it is the only form that is correct on every minor.

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed, so a host written against minor 1 keeps working unmodified here.
