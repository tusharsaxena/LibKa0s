# `LibKa0s-DebugLog-1.0` — version 12

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the DebugLog surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-DebugLog-1.0` |
| Files and minors | `DebugLog.lua` minor **12** |
| Shipped in | v1.16.0 |
| Status | **Current** |
| Supersedes | [version 11](./version-11-docs.md) — whose copy window was this file's own, the fifth copy in the collection |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) and `LibKa0s-Widgets-1.0` minor ≥ 7 (`NEEDS_WIDGETS = 7`) |
| Confirm in-game | `LibStub("LibKa0s-DebugLog-1.0").MODULES` → `{ DebugLog = 12 }` |

`Since` in the tables below is the DebugLog minor in which the member first appeared. Minors 1 and 2
were never tagged, so a `Since` of 1 or 2 means "present for as long as any consumer could have had
this major".

## What this major is

The on-screen debug console: a movable window with a color-coded log, a copy box, a plain-text
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

It depends on LibStub and on no addon framework. As of this version it depends on **two** sibling
majors rather than one — `LibKa0s-Core-1.0` and `LibKa0s-Widgets-1.0` — and returns before
`NewLibrary` if either is missing or below the minor it needs.

## What changed at this version

**The copy window is now drawn by `LibKa0s-Widgets-1.0`'s `CopyWindow`.** That is the whole change,
and everything else here follows from it: a new hard dependency floor, one descriptor fallback, one
behavior gained, and a list of the things that deliberately did not move.

No member was removed and no member was repurposed. A host needs a re-vendor of the **whole**
`LibKa0s/` folder and no code change.

| | | Since |
|---|---|---|
| `NEEDS_WIDGETS = 7` | A hard load-time floor. Absent or older, this module is **absent** rather than half-wired. See [Why the floor is hard](#why-the-floor-is-hard). | **12** |
| `addonName` falls back to `name` | Only for the copy window's descriptor, which requires one. The field itself is still optional here and still `Since` **9**. See [Why `addonName` gained a fallback](#why-addonname-gained-a-fallback). | fallback at **12** |
| The copy window re-anchors on every show | It lands over the console wherever the console has since been dragged, instead of wherever the copy window itself was last left. Behavior **gained**. | **12** |
| `_copyWindowForTest` / `_copyFrameForTest` | Test seams recorded on the instance by `ShowCopy()` — the handle and the frame it built. | **12** |

### Why the copy window moved out of this file

It was **the fifth copy of the same fifty-two lines** in the collection, and the last one living
outside Widgets. `Widgets.CopyWindow` arrived at Widgets minor 6 and took the other three; this one
did not go with them, and version 11 recorded why: it was wired to `escClose`, `applySkin` and
`dragBar`, which are locals of *this* file, and it named its scroll frame, which the shared member
had no way to express.

Widgets minor 7 closed that last gap. `scrollName` is the field it added, and it exists because of
this window: `UIPanelScrollFrameTemplate` derives its scrollbar children's names from its parent's,
so an anonymous scroll frame leaves them unnamed — invisible until somebody tries to skin or find
one. The debug console had always named it and the three other adopters never had.

The three locals turned out to be descriptor fields, and two of them are the *library's* rather than
this file's:

| What kept it here | Where it went |
|---|---|
| `applySkin` | The descriptor's `applySkin` field — already the host's-or-Core's seam, so it hands over unchanged and still covers both windows. |
| `escClose` | `CopyWindow` registers `UISpecialFrames` itself, for all four of its callers. |
| `dragBar` | Nothing to hand over: `CopyWindow` builds its own title bar, the same 26px one. |
| the named scroll frame | Widgets minor 7's `scrollName`. |

The handle is built lazily on first use and kept, because `CopyWindow` is itself lazy — nothing is
created until the first `Show`, which matters on a window most sessions never open.

### Why the floor is hard

`DebugLog.lua` now returns **before `NewLibrary`** if `LibKa0s-Widgets-1.0` is absent or below minor
7, exactly as it has always done for Core. There is no degraded mode and that is deliberate.

**A console whose Copy button silently does nothing is worse than no console.** The host's own
degradation stub — the one every Ka0s addon writes for the case where the library did not load — only
fires when the major is genuinely absent. Half-wire the module instead and the stub never runs, the
host reports a working console, and the user presses Copy on a perf capture and gets nothing, with
nowhere to look and nothing said. Absence is diagnosable; a dead button is not.

The floor also costs nothing a correct install could trip over. **Both files ship in one payload and
whole-folder vendoring is mandatory** — `DebugLog.lua` and `Widgets.lua` are never released
separately and are never meant to be copied separately. A host that trips this floor therefore has a
**broken** vendored copy rather than an unlucky one, and finding that out at load is the point.

### Why `addonName` gained a fallback

`CopyWindow` **refuses** a descriptor with no string `addonName` — it answers `nil` rather than a
handle, because it cannot resolve the collection's close art without knowing which addon folder the
vendored copy sits in. This library has always treated `addonName` as **optional**.

Left alone, those two facts collide: a host that never set `addonName` would have **lost its copy
window entirely** on this upgrade rather than gained a shared one, and lost it silently, since
`ShowCopy()` returns on a `nil` handle. So the descriptor handed to `CopyWindow` passes
`d.addonName or d.name`.

This is the same fallback `PerfPanel`'s own `CopyWindow` descriptor already uses, which is why it is
a convergence rather than a new idea.

What the fallback does **not** do is change what `addonName` means here. A host that omits it still
gets the version-8 windows down to the pixel: `d.name` reaches `CopyWindow` only as the string it
resolves close art from, and where that resolves to nothing, the close control falls back exactly as
it does anywhere else. The advice in [Why a name and not a boolean](#why-a-name-and-not-a-boolean)
is unchanged — a host that wants the collection's art passes its real folder name, and passing
`d.name` deliberately is still the wrong move.

### What the window gained

**It re-anchors to the console on every show.** The hand-rolled window anchored once, at build, to
`CENTER` — so on the second and every later open it appeared wherever it had last been dragged,
however far the console had since moved. `CopyWindow` consults its `anchorTo` on **every** `Show`, so
the popup lands over the window that spawned it. That is what its three other callers already do, and
it is the one respect in which this window behaves differently from version 11.

The console frame is handed over as `anchorTo = function() return frame end` — a function rather than
the frame, because the console frame is itself lazy and may not exist when the copy window's
descriptor is written.

One smaller visual difference comes with the shared member: `CopyWindow` paints its own denser
backdrop (`0.06, 0.06, 0.08, 0.95`) after the skin runs. It is a wall of small monospace text and the
world bleeding through costs legibility there in a way it does not on a frame showing four controls.

### What did not change, stated explicitly

These are the things a converged window is most likely to quietly lose, so each is named and each is
pinned by a test:

| | |
|---|---|
| `<name>DebugCopyWindow` | The global frame name is preserved, passed as `CopyWindow`'s `name`. It is what goes into `UISpecialFrames`, and a host test or a skinning addon may hold it. |
| `<name>DebugCopyScroll` | The scroll frame's global name is preserved, via `scrollName`. Its scrollbar children's names derive from it. |
| The `applySkin` seam | Still covers **both** windows. The same function object goes to `CopyWindow`, so a host that re-skins one re-skins both and the two cannot drift apart. |
| The `makeCloseButton` descriptor field | Still covers **both** windows, as it has since minor 4. It is forwarded to `CopyWindow`, which gained the field at Widgets minor 7 for exactly this reason — a hardcoded Core × upstream would have quietly narrowed a contract this library had already published. |
| 560 × 360 | The copy window is the same size. `CopyWindow`'s own default is 640 × 420; this caller passes its own. |
| `D:CopyText()` | Unchanged. It is still `table.concat(buffer, "\n")`, and it is still split out from `ShowCopy` because an `EditBox` is write-only through the frame API. |

The `Show` order — width, then text, then cursor, then show, then focus, then highlight — is also
unchanged, but it is no longer spelled out here: it is `CopyWindow`'s, and it is load-bearing there
for the same reasons it was load-bearing here.

### The 1500-line cap, from version 11

`lib.MAX_BUFFER` is **1500**, and this version does not move it.

The cap is not a display preference. **The perf capture workflow pastes out of this buffer**:
`perf report` prints its summary into the console and `perf dump` writes the whole JSON record as a
single line, so a capture is read by opening the copy window and pressing Ctrl+C. At 500 a long run
overflowed the buffer and lost its head — silently, because a buffer that has dropped its oldest
lines looks exactly like one that was started later.

**The copy window is a view of the buffer, not a second store.** `CopyText()` is
`table.concat(buffer, "\n")` and the window caps nothing of its own, so the buffer cap *is* the copy
cap. That is still true with the window drawn by Widgets: `ShowCopy()` hands `CopyText()` in as
text, and `CopyWindow` holds no buffer of its own.

What has to move with the cap is the message frame's own `SetMaxLines`: the cap and `SetMaxLines` are
one decision written in two places, and letting them drift makes the visible log and the copied
buffer disagree about what happened.

### What version 10 corrected, and why the forwarder carries every argument

Version 10 fixed two things version 9 shipped, and both still hold here.

`lib.MakeCloseButton` forwards onto `Core.MakeCloseButton`, and at version 9 it took **two**
arguments where Core's had grown a third — so a host that passed `addonName` got copy and clear as
icons beside a close button that was still a multiplication sign. A forwarder that loses an argument
is not a failure any layer can report: Core saw no addon name and did exactly what it does without
one, which is a perfectly good button. The forwarder exists so that a Core upgraded underneath an
unchanged `DebugLog.lua` is still the one that draws (see
[The empty `makeCloseButton`](#the-empty-makeclosebutton)), which means it has to carry **every**
argument Core takes or the upgrade arrives half-applied.

The icon controls also carry **no tooltip**. Version 9's anchored `ANCHOR_BOTTOM`, which put it on
top of the first line of the log — the thing the window exists to show — every time the pointer
crossed the title bar. The `label` argument is still passed and still used: it is what the
**text-button fallback** draws when there is no art.

### The `addonName` field and the icon controls, from versions 9 and 10

**One optional descriptor field, `addonName`.** Additive: a host that does not pass it gets the
version-8 windows down to the pixel, and every existing field behaves exactly as it did.

| | | Since |
|---|---|---|
| `addonName` | The host's own addon FOLDER name, from its first vararg. Given it, both windows draw the collection's own art — `close`, `copy` and `clear` out of `LibKa0s-Media-1.0` — instead of a multiplication sign and two words. | **9** |
| Icon title-bar controls | Copy and Clear become 18×18 icon buttons with 12px of art, matching the close control, so the three are one size and one pitch. **No tooltip** — see above; version 9 had one. | **9** |
| `frame.clearButton` / `frame.copyButton` | The two controls, recorded on the frame the way `titleBarOffsets` and `titleText` already are — the only handle a host's test has on which of the two shapes it got. | **9** |

These are the **console** window's controls, and this version does not touch them. The copy window
has only ever had a close control, and that one is `CopyWindow`'s now.

### Why a name and not a boolean

A texture path is absolute from `Interface\AddOns\` and this library is **vendored**: there is no
one path to it, and a copy cannot know which addon folder it was copied into. The host has that
string as its first vararg and nothing else does.

**Do not pass `d.name` blindly.** That field seeds the frame globals and only *happens* to equal the
folder name in most hosts; they are different questions and a host where they differ would get a
path into nowhere — which draws nothing and raises nothing. The minor-12 fallback does exactly that
substitution, and only where the alternative was no window at all: it buys a copy window that opens,
not the collection's art.

### The offsets move when the icons do

Copy and Clear were 42 and 40 wide as words and are 18 each as icons, so with `addonName` the
derived offsets tighten:

| | Words (no `addonName`) | Icons |
|---|---|---|
| `close` | `-6` | `-6` |
| `clear` | `-30` | `-30` |
| `copy` | `-78` | `-54` |

`frame.titleBarOffsets` still reports whichever it built, and a host close button wider than 18
still pushes both out of its way.

### What the marks do not say

Dropping a word for a mark costs the one thing the word was doing, and version 10 accepts that cost
rather than paying it with a tooltip over the log. A host that wants the words back omits
`addonName`; there is no third setting.

## Lib-level surface

| Name | Since | Meaning |
|---|---|---|
| `lib.FormatPlain(ts, tag, msg)` | 1 | `"<ts> \| [<tag>] <msg>"` — what the buffer holds and the copy window mirrors. Pure and lib-level, so a host's tests call it directly. |
| `lib.FormatColored(ts, tag, msg)` | 1 | The console view's line: timestamp muted steel-blue (`6f8faf`), `[tag]` muted tan/gold (`c9a66b`), separator and message default white. |
| `lib.MAX_BUFFER` | 1 | The line cap (**1500** as of minor 11; 500 through minor 10). Fixed by the standard rather than by the host: the cap and the message frame's own `SetMaxLines` must move together or the visible log and the copied buffer diverge. 1500 because the perf capture workflow pastes out of this buffer — `perf dump` writes a whole JSON record as one line — and the copy window is a *view* of the buffer rather than a second store, so this one number caps both. |
| `lib.MakeCloseButton` | 1 | Re-exported from Core, so a host that draws a close button on its own windows gets it from **one** factory rather than growing a lookalike. Forwards through the `core` table at call time, not captured at load. |
| `lib.STRINGS` | 1 | Every user-visible string, keyed for the descriptor's `L` override. Tags (`[Debug]`, `[Init]`) are deliberately *not* here — log-scrapers and host tests read them, so they are structure rather than prose. |
| `lib.MODULES` | 1 | `{ DebugLog = <minor> }` — the live minor of every file in this major. |
| `lib:New(descriptor)` | 1 | Build a console for one host. See below. |

## The console descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `name` | string | yes | 1 | Seeds the frame globals `<name>DebugWindow`, `<name>DebugCopyWindow` and `<name>DebugCopyScroll` — all three unchanged at minor 12, the last two now passed to `CopyWindow` as `name` and `scrollName`. Two hosts sharing a name would clobber each other's globals and each other's Esc handler. |
| `title` | string | yes | 1 | The human title; the library appends its own `" — Debug"`. |
| `font` | string | yes | 1 | Path to the monospace font the console renders in. Required rather than defaulted because a nil here raises inside `SetFont`, halfway through building a window that is then un-closable. |
| `fontSize` | number | no | 1 | Defaults to `10`. Applies to both windows, the copy window's via `CopyWindow`'s `fontSize`. |
| `isEnabled` | function | yes | 1 | Reads the host's logging flag. The library never stores it. |
| `setEnabled` | function | yes | 1 | Writes it. Always handed a real boolean. |
| `print` | function(line) | no | 1 | Where the chat acknowledgement goes. Defaults to the chat frame, untagged — a host that wants its own tag passes its printer, which is what every Ka0s addon does. |
| `safeToString` | function | no | 1 | Defaults to Core's. Every logged value goes through it, so a combat-protected value renders rather than raising downstream. |
| `initSummary` | function | no | 1 | Returns one line naming version/schema/profile. The library owns *when* it is emitted (on enable, as the `[Init]` line); only the host can know what it says. |
| `onVisibilityChanged` | function | no | 1 | Fired on both `OnShow` and `OnHide`, so a host can repaint a settings panel whose checkbox mirrors the console's visibility. |
| `slash` | string | no | 1 | Composes the checkbox tooltip's `"<slash> debug"` reference. |
| `L` | table | no | 1 | Locale override, keyed identically to `lib.STRINGS`. **Pass a PLAIN table holding only the keys you actually translate — never an addon-wide locale table.** See [The `L` trap](#the-l-trap). |
| `skin` | table | no | 1 | Overrides `Core.SKIN`. Handed straight to `Core.ApplySkin`, so a partial table (backdrop fields only, no `innerBorder`) degrades to a plain backdrop rather than raising. |
| `applySkin` | function | no | **4** | Owns the **whole** skin job, for the console and the copy window alike, replacing the library's own. Since minor 12 the copy window's half is served by handing this same function to `CopyWindow` as its `applySkin`, which runs it instead of `Core.ApplySkin` — so the two windows still cannot drift apart. As of Core minor 3 the library's own default already draws the full Ka0s edge, so this is for chrome that differs in SHAPE rather than color, or for a host that wants its console to track its own re-skin seam. Handed the fully-built frame — `frame.title` and `frame.divider` are already assigned — and run after the Hide and the Esc wiring, so a surprise inside it cannot strand a visible window nobody can close. |
| `addonName` | string | no | **9** | The host's own addon folder name. Given it, both windows draw this collection's art; omitted, they draw the version-8 glyph and words. **As of minor 12 the copy window's descriptor falls back to `name` when this is absent**, because `CopyWindow` refuses a descriptor without one — see [Why `addonName` gained a fallback](#why-addonname-gained-a-fallback). The field itself is still optional and still means the same thing. |
| `makeCloseButton` | function | no | **4** | `function(parent, onClick)` → button or nil. Overrides Core's × on **both** windows — since minor 12 the copy window's half is served by forwarding it to `CopyWindow`, which gained the matching field at Widgets minor 7 so that this published contract would not narrow. May answer `nil`, exactly as Core's own does where `CreateFrame` is unavailable. The Copy/Clear title-bar offsets are derived from the returned button's width, so a button wider than Core's 18 pushes them out of its way rather than colliding. **Rarely the right field, and it has no consumer today** — these are the library's windows, so they wear the library's close glyph, and a host whose own main window closes with something else must not push that difference onto them (`standalone-windows`). Pass it only for a close control genuinely *different in kind*. See [The empty `makeCloseButton`](#the-empty-makeclosebutton). |

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
| `CopyText()` | 1 | The whole buffer as one newline-joined string. Unchanged at minor 12. |
| `ShowCopy()` | 1 | Open the copy window over the console, filled with the buffer, focused and selected — Ctrl+C, then Esc. As of minor 12 the window is `LibKa0s-Widgets-1.0`'s `CopyWindow`, built lazily on the first call and kept; it re-anchors to the console on **every** call rather than staying where it was last dragged. |
| `_copyWindowForTest` | **12** | The `CopyWindow` handle, recorded on the instance by `ShowCopy()`. A test seam: the handle is otherwise a local, and this is what a suite reads to assert which window it got. |
| `_copyFrameForTest` | **12** | The frame that handle built, from `win:GetFrame()`. The copy window's `EditBox` is write-only through the frame API, which is why `CopyText()` exists — this is for the frame's own properties (its global name, its size, its named scroll child). |
| `Show()` / `Hide()` / `IsShown()` / `Toggle()` | 1 | Window visibility. `Hide` never builds a frame: a settings panel calls `IsShown` on every refresh, and a `Hide` that constructed a window would build one nobody asked for. |
| `IsEnabled()` | 1 | The host's flag, read through the descriptor and coerced to a boolean. |
| `RefreshHeader()` | 1 | Repaint the title-bar toggle — `Debug: ON` green, `Debug: OFF` red. |
| `SetEnabled(on)` | 1 | The single seam for changing debug state: writes the host's flag, repaints the header, prints the color-coded chat ack, brackets the console with a `[Debug]` line, and on enable follows it with the descriptor's `[Init]` summary. The slash command and the header toggle both come through here, so the ack and the header label can never disagree. |
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

That is a different relationship from the one this version adds to Widgets, and the difference is
worth naming. DebugLog *does* resolve `LibKa0s-Widgets-1.0` directly, at load, and refuses to exist
without it. Widgets never resolves DebugLog, so there is no cycle to form — the dependency runs one
way, which is exactly the property the Options arrangement cannot have and therefore has to avoid
having at all.

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

## The empty `makeCloseButton`

**No shipped consumer passes it, and that is a recorded decision rather than an oversight.** As of
v1.5.0 the hook is exercised by nothing outside this library's own suite. It arrived at minor 4
alongside `applySkin`, both defaulting to what minor 3 did, specifically so BankLedger and LootHistory
could adopt the module without losing the 24×24 class-colored × their consoles then wore. Both have
since dropped it deliberately: Core minor 3 made the Ka0s edge the library's own default, at which
point overriding the close button meant re-specifying what the library already drew. Each seam file
carries an explicit note where the field used to be — `../BankLedger/core/DebugLogSetup.lua:111-116`
and `../LootHistory/core/DebugLogSetup.lua:125-130` — and LootHistory records the drop as
`LIBKA0S-18`/`-19`. `applySkin`, its twin, went the other way: two consumers, both still passing it,
both for the reason it was added.

The hook is **retained on purpose**, and not merely because `-1.0` forbids removing it. What it is
for is a host whose console chrome is not Ka0s chrome at all — a close control different in *kind*,
not in color — and that host does not exist in this collection because every host in this collection
is a Ka0s addon. A surface with no consumer inside a fleet that shares one visual standard is not
evidence the surface is wrong; it is evidence the standard is doing its job, which is the same reason
`applySkin` covers the whole chrome job for every case a Ka0s host has actually had.

Minor 12 is the first time the zero cost something. Converging the copy window onto `CopyWindow`
meant handing a field with no consumer across a major boundary, and Widgets had to grow
`makeCloseButton` at its own minor 7 to receive it — a field with no consumer on that side either.
The alternative was a hardcoded Core × upstream, which would have quietly narrowed a contract this
document has published since minor 4. An unused published field is still a published field, and the
cheap thing to do with one is honor it, not discover later which host was relying on it.

What follows for a reader is where the guarantee stops. The hook's behavior on the console window is
pinned by `tests/test_debuglog.lua` — the factory being called once per window, the `onClick` it is
handed really hiding the console, a `nil` answer being survivable exactly as Core's own is, and the
Copy/Clear offsets deriving from the returned button's width in both the wider-button and
unmeasurable-width arms — and the no-hook default is pinned on both windows. So what is fixed here is
the library's side of the contract: what the factory is called with, what it may answer, and what the
title bar does with either. What is *not* fixed by any host is the shape — nothing outside these
cases has ever asked the library for a close button, so the field's ergonomics are pinned by the
library's own assumptions about what such a host would want rather than by one. A first host arriving
later should treat a misfit as a library gap on first contact, the same way `applySkin`'s second host
did.

Nothing needs doing about this. Pass nothing and both windows close with Core's ×; the zero is
written down because an unrecorded decision is indistinguishable from a mistake, and a documented,
tested, unused field otherwise reads as one to every reader who finds it.

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed, so a host written against minor 1 keeps working unmodified here.

The one thing that is *not* additive at this version is the **load-time floor**, and it sits below
the API rather than in it. `NEEDS_WIDGETS = 7` can make this major absent on a copy where minor 11
would have loaded — but only on a copy where `LibKa0s/` was vendored piecemeal, which the collection
does not permit. Re-vendor the whole folder and the floor is unobservable.
