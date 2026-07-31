# LibKa0s

## What it is

A Ka0s-owned shared library, vendored into Ka0s WoW addons the way Ace3 is — copied into each
addon's `libs/` folder rather than depended on at runtime. One LibStub major per module. Four
modules ship today:

- **`LibKa0s-Core-1.0`** — the small stateless seams every other module sits on: secret-safe
  stringification, the window skin and its close button, and a prefixed chat printer.
- **`LibKa0s-DebugLog-1.0`** — the on-screen debug console: the window, the copy window, the two
  formatters, the buffer, and the seam that turns logging on and off.
- **`LibKa0s-Slash-1.0`** — the slash dispatcher, the help renderer, the schema CLI
  (`list`/`get`/`set`/`reset`/`resetall`/`version`) and the type-aware value parser.
- **`LibKa0s-Perf-1.0`** — a repeatable A/B performance capture for one host addon.

DebugLog, Slash and Perf each require Core and refuse to register without it.

Everything from *Why it exists* down to *The public surface* documents `LibKa0s-Perf-1.0`. Core,
DebugLog and Slash have their own sections, below those.

## Why it exists

WoW's built-in Addon Profiler attributes a shared frame's CPU to whichever addon created it, so
enabling or disabling addons to isolate a cost just moves the blame around rather than answering the
question. The only trustworthy answer to "is this cost even mine?" is two combat-gated measurement
windows over the same fight, differing only in whether the host addon is inert, with load order and
shared-frame ownership held fixed throughout.

## Installing

1. Copy `LibKa0s/` into `<Addon>/libs/LibKa0s/` — the whole folder, every time. The modules are
   siblings that ship as one released copy, and `DebugLog.lua`, `Slash.lua` and `Perf.lua` each
   return without registering at all when `Core.lua` is missing or older than the minor they need.
2. Add `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block, after Ace3.
3. If you adopt Perf, declare `## SavedVariables: <Addon>PerfDB` in the TOC (the global name you'll
   pass as the descriptor's `sv`). Core and DebugLog persist nothing.

Do **not** list LibKa0s under `## Dependencies:` — it is vendored, not depended on, and every Ka0s
addon must work with no other addon installed.

## The descriptor

Everything a host supplies to `lib:New(descriptor)`. Within `LibKa0s-Perf-1.0` the contract is
**additive-only**: a field may be added in a later minor, never removed or repurposed — a host
written against minor 1 keeps working unmodified against any later minor.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `name` | string | yes | Host identifier. Seeds the default `slash`, the sampler and panel frame names, and `BuildRecord`'s `addon` field. |
| `sv` | string | yes | The global SavedVariables table name the capture ring is persisted to. Must be declared in the host's TOC. |
| `suspend` | function | yes | Makes the host inert without a `/reload`. See the host contract below. |
| `resume` | function | yes | Restores everything `suspend` took away. See the host contract below. |
| `log` | function(line) | no | Console-only sink. Defaults to `print`. |
| `print` | function(line) | no | Chat-and-console sink, for what the user must see while looking at the game. Defaults to `print`. |
| `showLog` | function | no | Reveals the host's own log/console window. Defaults to a no-op. The lib owns no console frame of its own, so this is how `start`, `report` and `dump` bring the log into view. |
| `onChange` | function | no | Called after every state transition, once the panel has already repainted. Lets the host republish on its own message bus. Defaults to a no-op. |
| `L` | table | no | Locale override table, keyed identically to `lib.STRINGS`. Hosts on the Ka0s standard pass their `NS.L`; unlocalised hosts pass nothing and get the built-in English strings. |
| `slash` | string | no | The command prefix shown in the panel's command column and in `Usage()`/`StatusLines()`. Defaults to `"/" .. name:lower()`. |
| `title` | string | no | Panel title (before the `— Perf Run` suffix). Defaults to `name`. |
| `ring` | number | no | Depth of the SavedVariables capture ring. Defaults to `lib.DEFAULT_RING` (10). |
| `buckets` | array of `{ key, within }` | no | Declares report order and nesting for `Note()` buckets. `within` names the parent bucket key for buckets that nest (e.g. `paintBar` runs inside `repaintPass`). A bracket calling `Note()` with an undeclared key still records, it just doesn't appear in the report. |
| `version` | string | no | Host addon version, stamped into `BuildRecord`. Defaults to `"?"`. |
| `decorate` | function(frame, api) | no | Panel chrome hook, called once at frame creation with the frame and `{ Show, Hide, Toggle, TITLE_H, PAD, ROW_W }`. Takes precedence over the lib's own chrome: a host that supplies it draws its own close button and divider, and a host that omits it gets `Core.MakeCloseButton` on the title bar rather than nothing. The two paths are exclusive — running both would stack two × on the same corner. |

`slash`, `title` and `showLog` exist specifically because this library serves more than one host.
The addon this was extracted from hardcoded `/at perf` into its usage text, `"AbsorbTracker"` into
the panel title, and a direct call to its own console frame's `:Show()` — none of which a second
consumer could reuse. All three are now descriptor fields the lib reads through instead of literals
it owns.

## A worked integration example

The first real consumer, AbsorbTracker's `core/PerfSetup.lua`, verbatim. Read the
`suspend`/`resume` contract below before writing your own pair — those two are the only part of a
descriptor that can make a capture silently lie rather than fail:

```lua
local addonName, NS = ...

local lib = LibStub and LibStub("LibKa0s-Perf-1.0", true)
if not lib then
    -- A missing vendored lib must degrade, not error at load: the addon's own function is unaffected
    -- by the absence of a diagnostics harness. The stub therefore has to cover EVERY member the
    -- addon calls, not just the bracket idiom (`on`/`Note`) and the show-decision ladder
    -- (`suspended`) — `/at perf` is registered unconditionally, so OnCommand has to answer too, and
    -- an honest "it is not installed" beats a Lua error in exactly the install this branch exists
    -- for.
    NS.Perf = {
        on        = false,
        suspended = false,
        Note      = function() end,
        OnCommand = function()
            return { "Performance measurement is unavailable: the LibKa0s library is missing from " ..
                "this installation of Absorb Tracker (expected in libs/LibKa0s)." }
        end,
    }
    return
end

NS.Perf = lib:New({
    name    = addonName,
    title   = "Absorb Tracker",
    slash   = "/at",
    version = NS.version,
    sv      = "AbsorbTrackerPerfDB",

    -- Ordered for the report, and the nesting is DECLARED rather than left as prose: repaintPass
    -- contains the three per-bar buckets, so their totals must never be summed as if disjoint.
    buckets = {
        { key = "absorbEvent" },                        -- addon:OnAbsorbChanged
        { key = "repaintPass" },                        -- doRepaint, one coalesced pass over every unit
        { key = "paintBar",    within = "repaintPass" },-- NS.UpdateAbsorbBar, per bar
        { key = "appearance",  within = "repaintPass" },-- NS.UpdateBarAppearance, per bar
        { key = "visibility",  within = "repaintPass" },-- NS.ApplyVisibility, per bar
    },

    --- Make the addon inert without a /reload.
    ---
    --- Visibility is NOT enforced by hiding frames here. NS.ShouldShowBar checks NS.Perf.suspended
    --- as step 0 of its ladder, so publishing VISIBILITY is enough and nothing — a combat
    --- transition, a target swap, a settings change — can re-show a bar behind suspend's back.
    suspend = function()
        local addon = NS.addon
        if addon then
            local frames = addon.__unitEventFrames
            if frames then
                for _, f in pairs(frames) do f:UnregisterAllEvents() end
            end
            if addon.UnregisterEvent then
                for _, event in ipairs({
                    "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
                }) do
                    addon:UnregisterEvent(event)
                end
            end
        end
        if NS.CancelPendingRepaint then NS.CancelPendingRepaint() end
        if NS.bus then NS.bus:SendMessage(NS.MSG.VISIBILITY) end
    end,

    --- Restore everything suspend took away. SyncUnitEventFrames rebuilds the per-unit registrations
    --- from the CURRENT enabled set, so a unit toggled while suspended comes back correctly.
    resume = function()
        local addon = NS.addon
        if addon then
            if addon.RegisterLifecycleEvents then addon:RegisterLifecycleEvents() end
            if addon.SyncUnitEventFrames then addon:SyncUnitEventFrames() end
        end
        if NS.bus then
            NS.bus:SendMessage(NS.MSG.VISIBILITY)
            NS.bus:SendMessage(NS.MSG.APPEARANCE)
            NS.bus:SendMessage(NS.MSG.REPAINT)
        end
    end,

    -- Perf output is deliberately NOT gated on NS.State.debug, unlike NS.Debug. That gate keeps the
    -- addon free when idle, and a perf run is explicit user action — none of it executes unless
    -- someone typed `/at perf start`. Gating it meant a user who started a run without first
    -- enabling debug logging watched a console that stayed empty while a capture was plainly running.
    log = function(line)
        if NS.DebugLog and NS.DebugLog.Add then
            NS.DebugLog:Add("Perf", line)
        else
            NS.Print(line)
        end
    end,

    print = function(line) NS.Print(line) end,

    -- `start`, `report` and `dump` want the console in front of the user. Everything else must not
    -- pop it open — a lifecycle line mid-combat is the last moment to throw a window on screen.
    showLog = function()
        if NS.DebugLog and NS.DebugLog.Show and not NS.DebugLog:IsShown() then
            NS.DebugLog:Show()
        end
    end,

    -- Built by the debug console's own close-button factory rather than a lookalike, so the two
    -- windows cannot drift apart. Guarded only because a close button is worth degrading over,
    -- not erroring over.
    decorate = function(frame, api)
        if NS.DebugLog and NS.DebugLog.MakeCloseButton then
            -- Resolved HERE rather than into a local at load time. `decorate` fires at frame-build
            -- time, long after every file has loaded, which is the only reason this file may reach
            -- for a member of a module that loads after it. Hoisting the lookup reintroduces the
            -- ordering hazard.
            local close = NS.DebugLog.MakeCloseButton(frame, api.Hide)
            -- The factory answers nil where CreateFrame is unavailable — a close button is worth
            -- degrading over, not erroring over.
            if close then
                close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -(api.TITLE_H - 18) / 2)
                frame.closeButton = close
            end
        end
    end,
})
```

Every hot-path call site then reads the frozen idiom straight off the instance:

```lua
local t0 = NS.Perf.on and debugprofilestop()
-- ... work ...
if t0 then NS.Perf.Note("paintBar", debugprofilestop() - t0) end
```

## The host contract for `suspend`/`resume`

The lib owns only the `suspended` state and the announcement; the host owns what "inert" means. Get
either of these wrong and a capture doesn't error — it silently lies:

1. **`suspend` MUST make the host inert without a `/reload`.** Reloading, or disabling the addon
   through the AddOns list, shifts shared-frame ownership — which is the exact confound that makes
   the built-in Addon Profiler untrustworthy for this question in the first place. `suspend` and
   `resume` must flip the host's behaviour in place, live, mid-session.
2. **Visibility MUST be enforced at the source**, i.e. as a check the host's own show-decision makes
   (`if perf.suspended then return end` inside whatever function decides to show a frame) — never by
   having `suspend` reach in and imperatively hide frames itself. Imperative hiding is a snapshot: the
   next combat transition, target swap, or settings change re-shows the frame behind suspend's back,
   because nothing is stopping it from being shown again. A check at the source holds for the whole
   suspended window, not just the instant `suspend` ran.

## The public surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Meaning |
|---|---|
| `Note(key, ms)` | Record one bracketed measurement into bucket `key`. |
| `Reset()` | Zero every counter — buckets, completion/review flags, FPS arms. |
| `Log(fmt, ...)` | Console-only line, colour-stripped. |
| `Announce(fmt, ...)` | Chat-and-console line, for what the user must see mid-fight. |
| `MarkReviewed(key)` | Mark a review action (`report`/`dump`) used, without disabling it. |
| `Progress()` | The run as a table of step states (`ready`/`busy`/`done`/`locked`/`used`/`cancel`), for a panel to render. |
| `Context()` | Who / where / what, snapshotted once at `Start()`. |
| `ContextLines(ctx)` | `Context()` rendered as display lines, shared by the chat ack and the report. |
| `BuildRecord(label)` | Assemble the current capture into the record schema (`docs/record-schema.md`). |
| `Save(record)` | Append a record to the host's SavedVariables ring, trimming past `ring`. |
| `FormatReport(record)` | Render a record as plain lines, for `Log`/testing. |
| `Start(label)` | Begin an experiment. Samples nothing until a window is armed. |
| `Measure(token)` | Arm window `"a"` or `"b"`; sets suspend state as the independent variable. |
| `Stop()` | End the experiment, detach the sampler, return the record. **Does not resume.** If Experiment B ran, the host is still inert when `Stop()` returns and stays that way until something calls `Resume()` — a host driving this API directly owns that call. The asymmetry is deliberate: `OnCommand("finish")` resumes *before* it saves, so that an error in `Save` or `FormatReport` cannot strand the addon dead for the session, and it can only order it that way because `Stop()` leaves the suspend state alone. |
| `Cancel()` | Abandon a run in flight; discards everything, restores the host if suspended. |
| `Suspend()` | Make the host inert; calls the descriptor's `suspend`. |
| `Resume()` | Restore the host; calls the descriptor's `resume`. |
| `Usage()` | Help text lines for the host to print. |
| `OnCommand(args)` | Run one perf sub-command; returns the chat lines to print. |
| `StatusLines()` | Phase summary plus `Usage()`, for a bare `perf` with no sub-verb. |
| `ShowPanel()` / `HidePanel()` / `TogglePanel()` | Show, hide, or toggle the step panel. |
| `RefreshPanel()` | Repaint every panel row from `Progress()`. |
| `IsPanelShown()` | Whether the panel frame is currently shown. |
| `STEPS` | The panel's rows in workflow order, each `{ key, string, label, command }`. `key` indexes `Progress()`, `string` is the `STRINGS`/`L` key, `label` is the resolved text (re-resolved on every repaint, so a locale table filled in after `New()` still lands), and `command` is the sub-verb a click dispatches. |
| `PanelStateOf(key)` | The current state of one `STEPS` row, straight from `Progress()`. Nil-safe: `"locked"` before there is anything to render. |
| `PanelIsActionable(key)` | Whether that row may be clicked — `ready`, `cancel` or `used`. A host drawing its own chrome in `decorate` reads these two rather than reaching into `Progress()` itself. |
| `EncodeJSON(value)` | The lib's hand-rolled JSON encoder, mirrored onto every instance. |
| `SCHEMA` | The record schema version this build of the lib emits. |
| `on` | Plain boolean field — read directly by every hot-path bracket. |

## `LibKa0s-Core-1.0`

Two seams that have nothing to do with each other except that both are tiny, stateless and wanted by
everything. The **secret-safe seam**: a value WoW protects in combat survives `tostring()` and the
`..` operator and raises only inside `table.concat`, so a detector has to probe the operation that
actually rejects it. The **window chrome seam**: a debug console and a perf panel that each draw
their own lookalike backdrop drift apart one hex digit at a time, so the values are shared rather
than copied. On top of both sits the prefixed chat printer, the one instance-shaped thing here.

Core depends on LibStub and nothing else — no Ace3 — which is what keeps `LibKa0s-Perf-1.0`
adoptable by addons that are not on the Ace substrate even now that Perf requires it.

Everything on the cross-module path is a lib-level function, never a handed-around instance: a
stateless function that exists at minor 1 still exists at minor 9, which makes "a Core from any
vendored copy works with a caller from any other" true by construction.

| Name | Meaning |
|---|---|
| `IsConcatSafe(v)` | Whether `v` survives the `table.concat` every emitted line ends in. Probes `table.concat` itself, not `..` — `..` silently propagates secretness and reports a secret as safe. |
| `SafeToString(v)` | Concat-safe stringifier. Ordinary values → `tostring(v)`; an un-concatenable (secret) value → `lib.SECRET`. `nil` and booleans are answered up front, so they are never masked. |
| `SECRET` | What an un-renderable value renders as (`"<secret>"`). Exported so a host's tests, its docs and this implementation cannot drift apart. |
| `SKIN` | The one skin every Ka0s window wears — the backdrop fields plus `bg` and `border`, in one table because taking the backdrop without the colours is exactly the drift this prevents. |
| `ApplySkin(frame)` | Wear the skin. A no-op on a frame with no `SetBackdrop`: undecorated is not broken. |
| `MakeCloseButton(parent, onClick)` | The thin × a Ka0s window closes with, returned unanchored for the caller to place. Returns `nil` where `CreateFrame` is unavailable (headless harness, or a load path with no UI). |
| `lib:New(descriptor)` | Build a prefixed chat printer for one host. See below. |

### The printer descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `prefix` | string or function | yes | The tag, **verbatim** — never synthesised from an abbreviation, because the collection's tags differ in case, colour and trailing space. A function is re-read on *every* call, which is what lets a host whose prefix constant lives in a later-loading file pass `function() return NS.PREFIX end` instead of capturing `nil` forever. A prefix that has not resolved yet emits the body alone: an untagged line beats one reading `nil something happened`. |
| `sep` | string | no | Separates the prefix from the body. Defaults to `" "`; a tag that carries its own trailing space passes `""`. |
| `sink` | function(line) | no | Where a finished line goes. Defaults to `DEFAULT_CHAT_FRAME:AddMessage`. Injectable because hosts capture chat at exactly this seam in their headless harnesses. |

The returned printer's two members are plain functions, not methods — a host does
`local print = NS.Print` at file scope and calls it bare, so neither may need a `self`:

| Name | Meaning |
|---|---|
| `Print(...)` | Space-joined, prefix-tagged, secret-safe. Mirrors `print()`'s shape, so a host's existing naked `print(...)` call sites keep working once `print` is bound to this. |
| `Format(fmt, ...)` | `format()` over pre-stringified arguments, so a secret reaching a `%s` slot renders as the sentinel instead of raising on its way to the chat frame. |

## `LibKa0s-DebugLog-1.0`

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

Like Perf, it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework, and it returns
before `NewLibrary` if Core is missing or below the minor it needs.

| Name | Meaning |
|---|---|
| `lib.FormatPlain(ts, tag, msg)` | `"<ts> \| [<tag>] <msg>"` — what the buffer holds and the copy window mirrors. Pure and lib-level, so a host's tests call it directly. |
| `lib.FormatColored(ts, tag, msg)` | The console view's line: timestamp muted steel-blue (`6f8faf`), `[tag]` muted tan/gold (`c9a66b`), separator and message default white. |
| `lib.MAX_BUFFER` | The line cap (500). Fixed by the standard rather than by the host: the cap and the message frame's own `SetMaxLines` must move together or the visible log and the copied buffer diverge. |
| `lib.MakeCloseButton` | Re-exported from Core, so a host that draws a close button on its own windows gets it from **one** factory rather than growing a lookalike. |
| `lib.STRINGS` | Every user-visible string, keyed for the descriptor's `L` override. Tags (`[Debug]`, `[Init]`) are deliberately *not* here — log-scrapers and host tests read them, so they are structure rather than prose. |
| `lib:New(descriptor)` | Build a console for one host. See below. |

### The console descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `name` | string | yes | Seeds the frame globals `<name>DebugWindow`, `<name>DebugCopyWindow` and `<name>DebugCopyScroll`. Two hosts sharing a name would clobber each other's globals and each other's Esc handler. |
| `title` | string | yes | The human title; the library appends its own `" — Debug"`. |
| `font` | string | yes | Path to the monospace font the console renders in. Required rather than defaulted because a nil here raises inside `SetFont`, halfway through building a window that is then un-closable. |
| `fontSize` | number | no | Defaults to `10`. |
| `isEnabled` | function | yes | Reads the host's logging flag. The library never stores it. |
| `setEnabled` | function | yes | Writes it. Always handed a real boolean. |
| `print` | function(line) | no | Where the chat acknowledgement goes. Defaults to the chat frame, untagged — a host that wants its own tag passes its printer, which is what every Ka0s addon does. |
| `safeToString` | function | no | Defaults to Core's. Every logged value goes through it, so a combat-protected value renders rather than raising downstream. |
| `initSummary` | function | no | Returns one line naming version/schema/profile. The library owns *when* it is emitted (on enable, as the `[Init]` line); only the host can know what it says. |
| `onVisibilityChanged` | function | no | Fired on both `OnShow` and `OnHide`, so a host can repaint a settings panel whose checkbox mirrors the console's visibility. |
| `slash` | string | no | Composes the checkbox tooltip's `"<slash> debug"` reference. |
| `L` | table | no | Locale override, keyed identically to `lib.STRINGS`. |
| `skin` | table | no | Overrides `Core.SKIN`. |

### The public surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Meaning |
|---|---|
| `buffer` | The plain-text lines, a dense array, newest last and capped at `MAX_BUFFER`. Read directly by host tests across the collection — it is part of the contract, not an internal. |
| `FormatPlain` / `FormatColored` / `MakeCloseButton` | The lib-level members, mirrored onto the instance so a host holds one object. |
| `Text(key)` | Resolve one user-visible string, the descriptor's `L` first, then `lib.STRINGS`. |
| `Add(tag, msg)` | Append one line. **Ungated on purpose**: the enable seam's own bracket lines and a host's perf output both have to land whatever the flag says. |
| `Debug(tag, fmt, ...)` | The gated sink, and a plain function rather than a method — hosts bind it bare (`NS.Debug = D.Debug`) and call it from everywhere. Zero-allocation when off: it returns before building the argument table. |
| `BufferSize()` | `#buffer`. |
| `LastLine()` | The newest buffered line. |
| `FindLine(substr)` | The newest line containing `substr`. Plain search, not a pattern — callers are looking for a tag or a message fragment, neither of which is written as a Lua pattern. |
| `Clear()` | Empty the log frame and the buffer, then repaint the scrollbar and the status line. |
| `UpdateScrollBar()` | Re-sync the slider with the message frame's scroll offset. The two run in opposite directions, so they are related by `maxOffset - value`. |
| `UpdateStatus()` | Repaint the `N / MAX` line counter. |
| `ShowCopy()` | Open the copy window over the console, filled with the buffer, focused and selected — Ctrl+C, then Esc. |
| `Show()` / `Hide()` / `IsShown()` / `Toggle()` | Window visibility. `Hide` never builds a frame: a settings panel calls `IsShown` on every refresh, and a `Hide` that constructed a window would build one nobody asked for. |
| `IsEnabled()` | The host's flag, read through the descriptor and coerced to a boolean. |
| `RefreshHeader()` | Repaint the title-bar toggle — `Debug: ON` green, `Debug: OFF` red. |
| `SetEnabled(on)` | The single seam for changing debug state: writes the host's flag, repaints the header, prints the colour-coded chat ack, brackets the console with a `[Debug]` line, and on enable follows it with the descriptor's `[Init]` summary. The slash command and the header toggle both come through here, so the ack and the header label can never disagree. |
| `ConsoleCheckbox()` | The data contract below. |
| `_toggleClickForTest` / `_frameForTest` | Test seams. A headless mock's `Show`/`Hide` track visibility without firing `OnShow`/`OnHide`, and stub `GetScript`, so the click handler and the visibility callback are only reachable directly. |

### The `ConsoleCheckbox()` data contract

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

## `LibKa0s-Slash-1.0`

The slash dispatcher, the help renderer, the schema CLI and the value parser — everything between
"the user typed `/at something`" and "a setting changed", minus the settings themselves.

Four-plus copies of it exist across the collection, in two different shapes, and the divergence is
not cosmetic. One shape parses values by bare coercion, so `set barWidth 99999` stores 99999 and a
`get` on a colour prints a table address. This library takes the type-aware shape — clamping, enum
validation, colour tuples — on the view that a CLI silently accepting a value it cannot honour is
worse than one that refuses.

Like DebugLog and Perf, it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework, and
it returns before `NewLibrary` if Core is missing or below the minor it needs.

### Why the commands table stays the host's

`commands` is required, and it is the host's own ordered `{ name, description, handler }` table,
passed in rather than owned. That is the load-bearing decision in this module.

A host owns its verbs; it also renders them on its own About or landing page. If the library owned
the table, the options module drawing that page would have to resolve `LibKa0s-Slash-1.0` to read
it — and an options library and a slash library each reaching for the other is a real dependency
cycle between two majors at load time. The table crossing between them as plain data is what keeps
them independent. It is the same argument as DebugLog's `ConsoleCheckbox()` data contract, run in
the other direction.

The practical consequence is that the seven-or-so verbs a host actually implements (`lock`, `test`,
`toggle`, …) never leave the host, so adopting this library cannot break them. What moves here is
the dispatch, the help rendering, and the schema verbs.

### `reset` takes a path, not a page

`Sl:CliReset(rest)` resets **one** setting, named by its path. There is deliberately no page-shaped
form (`reset general`, `reset bar`): a page is a property of a settings panel, not of the data, and
every schema-driven panel already carries a Defaults button that resets its page across every unit.
The capability is not lost, it just lives where the concept does. `CliResetAll()` is unaffected and
resets everything.

### The lib-level formatters and parser

Stateless and lib-level, never per-instance: a host's tests call them directly, and nothing about a
rendered row depends on which instance rendered it.

| Name | Meaning |
|---|---|
| `lib.FormatRow(command, description)` | One command row: `\|cFFFFFF00` command, an em dash with a single space either side, `\|cFFFFFFFF` description. **Not** indented — the indent belongs to whoever renders, because a chat line sits under a header and a settings-panel label does not. This is the one command-row formatter in the collection; the `/at list` header, its group headings and any host annotation are a different, lower-case-hex family and stay that way. |
| `lib.FormatKV(path, valueStr)` | One `key = value` pair, gold key and white value, no trailing colon. Used by the list rows and by the get/set echo, so a setting reads identically wherever it is printed. |
| `lib.FormatValue(row, v)` | Render a stored value by the row's declared type — a colour as `{r, g, b, a}` to two places, a number through the row's `fmt`, an empty string as `STRINGS.NONE`, anything else through Core's `SafeToString`. |
| `lib.ParseValue(row, text)` | The type-aware parser. Returns the value, or `nil` plus a reason. |
| `lib.STRINGS` | Every user-visible string, keyed for the descriptor's `L` override. |

`ParseValue` is where the type-awareness lives, and its two failure modes are deliberately not the
same. A **number out of range clamps** rather than failing, because a user typing a width larger
than the panel allows means "as wide as it goes". A **string outside its enum fails**, because there
is no such reading of a misspelt texture name. A row's `values` may be a function, evaluated at call
time rather than at load, since a host's media list is populated by another addon and is not
knowable when the schema row is declared. Colours accept `r g b [a]` in either 0–1 or 0–255 and are
rescaled **jointly** — `255 128 0` is one colour expressed in one scale, and dividing only the
channels that happen to exceed 1 would mangle the rest.

Failure is signalled by a `nil` first return plus a message. No row type has a valid value that is
itself `nil`, which is what makes that unambiguous; adding one would be a contract change rather
than a new type.

### The dispatcher descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `slash` | string | yes | The command prefix, **with** its slash: `"/at"`. Every usage line and every help row is composed from it. |
| `commands` | table | yes | The host's ordered `{ name, description, handler }` triples. Passed in, never owned — see above. The handler is called with the rest of the line, verbatim. |
| `slashAliases` | table | no | Other chat commands reaching the same dispatcher. The first is named in the help header. Registering them is the host's job; this library registers no slash command of its own. |
| `aliases` | table | no | Map of typed verb → real verb, for backwards compatibility (`{ options = "config" }`). |
| `print` | function(line) | no | Where lines go. Defaults to the chat frame. Hosts pass their prefixed printer. |
| `version` | function | no | Returns the host's version string, for the help header and `version`. |
| `get` | function(path) | no | Read one setting by path. |
| `set` | function(path, v) | no | Write one setting by path. |
| `findRow` | function(path) | no | Resolve a path to a schema row, or nil. |
| `allRows` | function | no | Every row, in declaration order — which is the order `list` prints. |
| `applyDefault` | function(row) | no | Restore one row to its default. |
| `parse` | function(row, text) | no | Defaults to `lib.ParseValue`. |
| `groupKey` | function(row) | no | Row → the heading it lists under. Defaults to `row.page`. |
| `L` | table | no | Locale override, keyed identically to `lib.STRINGS`. |

Only `slash` and `commands` are required, and both raise rather than defaulting: a dispatcher with
no prefix has nothing to compose usage lines from, and one with no verb table answers every input
with "unknown command". Everything schema-shaped is optional, so a host with no settings schema gets
a working dispatcher and help renderer and simply never wires the CLI verbs into `commands`.

### The public surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Meaning |
|---|---|
| `OnSlash(msg)` | The entry point. An empty line prints help; otherwise the first token is lowercased, mapped through `aliases`, and dispatched. Only the verb is lowercased — `rest` keeps its case, because schema paths are case-sensitive, and its internal spacing, because a colour is several tokens. An unknown verb says so and then prints help. |
| `PrintHelp()` | The header, then `HelpRows()`, through the descriptor's `print`. |
| `HelpHeader()` | `v<version> — slash commands`, plus the alias note when `slashAliases` has one. |
| `HelpRows()` | The command rows, indented two spaces, because each sits under a header in chat. |
| `LandingRows()` | The same rows, same colours and spacing, **no** indent — for a settings panel, where each row is its own label and a leading indent reads as a mistake. |
| `BuildListLines()` | The `list` output as lines, without printing: header, then each `groupKey` heading in declaration order with its rows beneath. Returns the empty-state line when there are no rows. Grouped in declaration order rather than alphabetically, because a schema's order is the order its panel shows and a listing that disagreed with the panel would be its own puzzle. |
| `CliList()` | `BuildListLines()`, printed. |
| `CliGet(rest)` | Echo one setting. |
| `CliSet(rest)` | Parse and store one setting, then echo it by **re-reading** — a clamped number is only visible to the user because the echo reports what was actually stored, not what was typed. |
| `CliReset(rest)` | Reset one setting by path, and echo it. Never annotated. |
| `CliResetAll()` | `applyDefault` over every row, then one acknowledgement. |
| `CliVersion()` | The host's version. |
| `SetRowAnnotator(fn)` | Install a host suffix appended to a rendered setting — most usefully a note that the stored value is not the one in effect. Applied at exactly three sites: a list row, a get echo and a set echo. Never on reset or resetall, where an explanation of what a value means is noise stapled to an acknowledgement that the value went away. |
| `Text(key)` | Resolve one user-visible string, the descriptor's `L` first, then `lib.STRINGS`. |

## Development

Green gate before every commit, run from the repo root:

```bash
lua tests/run.lua
luacheck .
```

Both must be 0/0 before a release — `lua tests/run.lua` reports `N passed, 0 failed, N total`,
`luacheck .` reports `0 warnings / 0 errors`.

`docs/test-cases.md` is the generated inventory of what the suite covers, and it is the
authoritative case count. Regenerate it in the same change that adds or removes a test:

```bash
lua tests/run.lua --list > docs/test-cases.md
```

`--list` builds every suite and prints the case names without running them, so it is also the
quickest way to see whether a new suite file is actually wired into the suite list. The renderer in
`testkit/framework.lua` writes CRLF itself, matching `docs/`'s `.gitattributes` convention — there
is no `| sed 's/$/\r/'` to remember, because a regeneration command with a pipeline in it is one
someone eventually runs without the pipeline.

### The shared test kit

`testkit/` holds the registry, the assertions, the source loader and the universal half of the
WoW-API mock, shared across the collection and vendored into each addon as `tests/_kit/`. It is
**not** a LibStub major and never ships. See [`testkit/README.md`](./testkit/README.md) for the
vendoring discipline, what a consuming `tests/run.lua` looks like, and the mock-fidelity rules.

This repo consumes its own kit through `tests/_kit/` rather than reaching into `testkit/` directly,
so LibKa0s is a consumer on the same terms as every addon: `diff -r testkit tests/_kit` is the same
gate here as it is downstream, and a kit change that would break a consumer breaks this repo first.

### Versioning

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans; each
**file** in `LibKa0s/` separately carries a LibStub **minor** integer, bumped on every released change
to that file — that is what LibStub compares when it picks a winner between two vendored copies, so a
released change that skips its bump reaches no host that already carries the old copy.

`lib.MODULES` publishes the live minor of every file — today
`{ Core = 1, DebugLog = 1, Slash = 1, Perf = 2, PerfPanel = 2 }` — which is how you answer "which
panel is attached to which probe?" from in-game, once several addons each ship their own vendored
copy.
`tests/test_versioning.lua` enforces that `MODULES` and `CHANGELOG.md`'s version block agree, so a
bump cannot land without its changelog entry, nor an entry without its bump.

Full release order — bump, changelog, regenerate, tag, then **re-vendor every consumer** — is in
[docs/releasing.md](docs/releasing.md). That last step is the one that gets forgotten: it already
happened once, with both repos' suites green throughout.

Re-vendoring is **whole-folder**, never file by file. `Perf.lua` resolves `LibKa0s-Core-1.0` before
it calls `NewLibrary` and returns outright if Core is missing or below the minor it needs, so a
consumer that copied a new `Perf.lua` over an old `Core.lua` gets no probe at all rather than a
half-updated one — the host's setup stub then says "perf is not installed", which is the honest
answer.

## Repo layout

```
LibKa0s/            -- the only folder that ships; vendor this into <Addon>/libs/LibKa0s/
  LibKa0s.xml        -- lib load list, referenced from the host addon's TOC lib block; Core first
  Core.lua           -- LibKa0s-Core-1.0, MINOR at the top of the file
  DebugLog.lua       -- LibKa0s-DebugLog-1.0, MINOR at the top of the file; needs Core
  Slash.lua          -- LibKa0s-Slash-1.0, MINOR at the top of the file; needs Core
  Perf.lua           -- LibKa0s-Perf-1.0, MINOR at the top of the file; needs Core
  PerfPanel.lua      -- the clickable step panel, part of the same module, PANEL_MINOR of its own
testkit/             -- the shared headless harness, vendored into each addon as tests/_kit/
                        (never shipped: it lives under tests/, which every .pkgmeta already excludes)
tests/               -- this repo's own test harness, consuming testkit/ through tests/_kit/
docs/                -- development docs (not shipped)
  releasing.md       -- the two version numbers, the release order, the re-vendor rule
  record-schema.md   -- the capture record, field by field
  adoption-prompt.md -- the per-addon adoption prompt
  test-cases.md      -- generated case inventory
LICENSE
README.md
CHANGELOG.md
.luacheckrc
```
