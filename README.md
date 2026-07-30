# LibKa0s

## What it is

A Ka0s-owned shared library, vendored into Ka0s WoW addons the way Ace3 is — copied into each
addon's `libs/` folder rather than depended on at runtime. One LibStub major per module. The first
module is `LibKa0s-Perf-1.0`, a repeatable A/B performance capture for one host addon.

## Why it exists

WoW's built-in Addon Profiler attributes a shared frame's CPU to whichever addon created it, so
enabling or disabling addons to isolate a cost just moves the blame around rather than answering the
question. The only trustworthy answer to "is this cost even mine?" is two combat-gated measurement
windows over the same fight, differing only in whether the host addon is inert, with load order and
shared-frame ownership held fixed throughout.

## Installing

1. Copy `LibKa0s/` into `<Addon>/libs/LibKa0s/`.
2. Add `libs\LibKa0s\LibKa0s.xml` to the TOC's lib block, after Ace3.
3. Declare `## SavedVariables: <Addon>PerfDB` in the TOC (the global name you'll pass as the
   descriptor's `sv`).

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
| `showLog` | function | no | Reveals the host's own log/console window. Defaults to a no-op. The lib owns no console frame of its own, so this is how `report`/`dump` bring the log into view. |
| `onChange` | function | no | Called after every state transition, once the panel has already repainted. Lets the host republish on its own message bus. Defaults to a no-op. |
| `L` | table | no | Locale override table, keyed identically to `lib.STRINGS`. Hosts on the Ka0s standard pass their `NS.L`; unlocalised hosts pass nothing and get the built-in English strings. |
| `slash` | string | no | The command prefix shown in the panel's command column and in `Usage()`/`StatusLines()`. Defaults to `"/" .. name:lower()`. |
| `title` | string | no | Panel title (before the `— Perf Run` suffix). Defaults to `name`. |
| `ring` | number | no | Depth of the SavedVariables capture ring. Defaults to `lib.DEFAULT_RING` (10). |
| `buckets` | array of `{ key, within }` | no | Declares report order and nesting for `Note()` buckets. `within` names the parent bucket key for buckets that nest (e.g. `paintBar` runs inside `repaintPass`). A bracket calling `Note()` with an undeclared key still records, it just doesn't appear in the report. |
| `version` | string | no | Host addon version, stamped into `BuildRecord`. Defaults to `"?"`. |
| `decorate` | function(frame, api) | no | Panel chrome hook, called once at frame creation with the frame and `{ Show, Hide, Toggle, TITLE_H, PAD, ROW_W }`. Lets the host draw its own close button and divider; the lib knows nothing about a host's chrome. |

`slash`, `title` and `showLog` exist specifically because this library serves more than one host.
The addon this was extracted from hardcoded `/at perf` into its usage text, `"AbsorbTracker"` into
the panel title, and a direct call to its own console frame's `:Show()` — none of which a second
consumer could reuse. All three are now descriptor fields the lib reads through instead of literals
it owns.

## A worked integration example

The shape a host wires up — illustrative of the descriptor as implemented, not a literal file (the
first real consumer, AbsorbTracker's `core/PerfSetup.lua`, lands in a later task):

```lua
local addonName, NS = ...

local Lib = LibStub("LibKa0s-Perf-1.0")

NS.Perf = Lib:New{
  name    = addonName,
  sv      = "AbsorbTrackerPerfDB",
  version = NS.version,

  log     = function(line) NS.DebugLog:Add("Perf", line) end,
  print   = print,
  showLog = function() NS.DebugLog:Show() end,
  onChange = function()
    if NS.bus and NS.MSG and NS.MSG.PERF then NS.bus:SendMessage(NS.MSG.PERF) end
  end,
  L = NS.L,

  buckets = {
    { key = "absorbEvent" },                              -- addon:OnAbsorbChanged
    { key = "repaintPass" },                               -- doRepaint, one coalesced pass
    { key = "paintBar",    within = "repaintPass" },        -- NS.UpdateAbsorbBar, per bar
    { key = "appearance",  within = "repaintPass" },        -- NS.UpdateBarAppearance, per bar
    { key = "visibility",  within = "repaintPass" },        -- NS.ApplyVisibility, per bar
  },

  -- See "The host contract for suspend/resume" below before writing these two.
  suspend = function()
    local addon = NS.addon
    if addon and addon.__unitEventFrames then
      for _, f in pairs(addon.__unitEventFrames) do f:UnregisterAllEvents() end
    end
    if NS.bus then NS.bus:SendMessage(NS.MSG.VISIBILITY) end
  end,
  resume = function()
    local addon = NS.addon
    if addon and addon.SyncUnitEventFrames then addon:SyncUnitEventFrames() end
    if NS.bus then NS.bus:SendMessage(NS.MSG.VISIBILITY) end
  end,
}
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
| `Stop()` | End the experiment, detach the sampler, return the record. |
| `Cancel()` | Abandon a run in flight; discards everything, restores the host if suspended. |
| `Suspend()` | Make the host inert; calls the descriptor's `suspend`. |
| `Resume()` | Restore the host; calls the descriptor's `resume`. |
| `Usage()` | Help text lines for the host to print. |
| `OnCommand(args)` | Run one perf sub-command; returns the chat lines to print. |
| `StatusLines()` | Phase summary plus `Usage()`, for a bare `perf` with no sub-verb. |
| `ShowPanel()` / `HidePanel()` / `TogglePanel()` | Show, hide, or toggle the step panel. |
| `RefreshPanel()` | Repaint every panel row from `Progress()`. |
| `IsPanelShown()` | Whether the panel frame is currently shown. |
| `EncodeJSON(value)` | The lib's hand-rolled JSON encoder, mirrored onto every instance. |
| `SCHEMA` | The record schema version this build of the lib emits. |
| `on` | Plain boolean field — read directly by every hot-path bracket. |

## Development

Green gate before every commit, run from the repo root:

```bash
lua tests/run.lua
luacheck .
```

Both must be 0/0 before a release — `lua tests/run.lua` reports `N passed, 0 failed, N total`,
`luacheck .` reports `0 warnings / 0 errors`.

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans; each
module separately carries a LibStub **minor** integer, bumped on every released change to that
module — that is what LibStub compares when it picks a winner between two vendored copies.

## Repo layout

```
LibKa0s/            -- the only folder that ships; vendor this into <Addon>/libs/LibKa0s/
  LibKa0s.xml        -- lib load list, referenced from the host addon's TOC lib block
  Perf.lua           -- LibKa0s-Perf-1.0
  PerfPanel.lua       -- the clickable step panel, part of the same module
tests/               -- headless Lua test harness (not shipped)
docs/                -- development docs (not shipped)
LICENSE
README.md
CHANGELOG.md
.luacheckrc
```
