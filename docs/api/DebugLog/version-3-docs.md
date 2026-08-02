# `LibKa0s-DebugLog-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the DebugLog surface points here rather than restating it. It describes the
> contract *as it was at this version* — a later version is a different document, not an edit to
> this one.

| | |
|---|---|
| Major | `LibKa0s-DebugLog-1.0` |
| Files and minors | `DebugLog.lua` minor **3** |
| Shipped in | v1.0.0, v1.1.0, v1.1.1 |
| Status | Superseded |
| Supersedes | minors 1–2 (pre-release, never vendored) |
| Superseded by | [version 4](./version-4-docs.md) |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-DebugLog-1.0").MODULES` → `{ DebugLog = 3 }` |

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

**The `L` resolver switched to `rawget`.** Many addon-wide locale tables carry a metatable whose
`__index` answers the key itself, so a missing key answered its own name instead of `nil` and the
library's default never got a chance to resolve. From this minor the lookup is a `rawget`, so a
metatable-backed table no longer poisons it. Passing a plain scoped table is still the contract —
see [The `L` trap](#the-l-trap).

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
| `skin` | table | no | 1 | Overrides `Core.SKIN`. |

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `buffer` | 1 | The plain-text lines, a dense array, newest last and capped at `MAX_BUFFER`. Read directly by host tests across the collection — it is part of the contract, not an internal. |
| `FormatPlain` / `FormatColored` / `MakeCloseButton` | 1 | The lib-level members, mirrored onto the instance so a host holds one object. |
| `Text(key)` | 1 | Resolve one user-visible string, the descriptor's `L` first, then `lib.STRINGS`. |
| `Add(tag, msg)` | 1 | Append one line. **Ungated on purpose**: the enable seam's own bracket lines and a host's perf output both have to land whatever the flag says. |
| `Debug(tag, fmt, ...)` | 1 | The gated sink, and a plain function rather than a method — hosts bind it bare (`NS.Debug = D.Debug`) and call it from everywhere. Zero-allocation when off: it returns before building the argument table. |
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
never gets a chance to resolve. This minor is where the resolver switched to `rawget`, so a metatable-backed
table no longer poisons the lookup — but passing a scoped table is still the contract, because it is
the only form that is correct on every minor.

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed, so a host written against minor 1 keeps working unmodified here.
