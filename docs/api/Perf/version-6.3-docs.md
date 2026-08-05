# `LibKa0s-Perf-1.0` — version 6.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Perf surface points here rather than restating it. It describes the
> contract *as it was at this version* — a later version is a different document, not an edit to
> this one.

| | |
|---|---|
| Major | `LibKa0s-Perf-1.0` |
| Files and minors | `Perf.lua` **6** · `PerfPanel.lua` **3** |
| Version key | `<Perf>.<PerfPanel>`, in load order — the same two numbers `lib.MODULES` reports |
| Shipped in | v1.7.0 |
| Status | Superseded |
| Supersedes | [version 5.3](./version-5.3-docs.md) |
| Superseded by | [version 7.3](./version-7.3-docs.md) |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Record schema | 2 — see [`docs/record-schema.md`](../../record-schema.md) |
| Confirm in-game | `LibStub("LibKa0s-Perf-1.0").MODULES` → `{ Perf = 6, PerfPanel = 3 }` |

`Since` names the file and minor a member first appeared in — `P6` for `Perf.lua` minor 6, `PP2`
for `PerfPanel.lua` minor 2. It is `1` for nearly everything: this major did not move at all between
the first tag and minor 6, so every adopter before this version is on the same one.

Adopters today: **AbsorbTracker** (`core/PerfSetup.lua`), **KickCD** (`core/PerfSetup.lua`),
**ConsumableMaster** (`modules/PerfSetup.lua`).

## What this major is

A repeatable A/B performance capture for one host addon: the probe, the guided run, the record
it writes, and the clickable step panel that drives it.

Two files, one major — `Perf.lua` (the probe and the run) and `PerfPanel.lua` (the step panel). One
major for the same reason Options is one: a shell and a panel from different vendored copies is not
a state LibStub can detect. **This is why the version key above is a pair.**

## What changed at this version

**Two new instance members, `P.Open()` and `P.Close(t0, key)`, and nothing else.** No descriptor
field, no bucket key, no record-schema field and no printed line moved, so a host written against
5.3 is correct here unmodified — including `P.Note`, which the pair is built on rather than
replacing. `PerfPanel.lua` does not move.

They exist for **multi-exit** functions; see
[Bracketing a multi-exit function](#bracketing-a-multi-exit-function).

Internally, `FormatReport` and `Progress` were restructured into named builders (the FPS lines, the
bucket lines, the nesting note, and the two step-state resolvers) to bring the file under the
collection's complexity cap. Every line they emit is byte-identical to 5.3's.

## Why it exists

WoW's built-in Addon Profiler attributes a shared frame's CPU to whichever addon created it, so
enabling or disabling addons to isolate a cost just moves the blame around rather than answering the
question. The only trustworthy answer to "is this cost even mine?" is two combat-gated measurement
windows over the same fight, differing only in whether the host addon is inert, with load order and
shared-frame ownership held fixed throughout.

**Both measurement windows are combat-gated at this version**: `Measure("a")` arms a window that
starts the moment combat does and ends when combat ends, and nothing between is measured. An
out-of-combat variant is proposed but not built — see
[LibKa0s#5](https://github.com/tusharsaxena/LibKa0s/issues/5). That is why BankLedger, LootHistory
and PanelMaster vendor this major without wiring a Perf module: they do no meaningful in-combat work,
so there is nothing here for them to measure yet.

## Lib-level surface

| Name | Since | Meaning |
|---|---|---|
| `lib.EncodeJSON(value)` | 1 | The hand-rolled JSON encoder. Mirrored onto every instance. |
| `lib.SCHEMA` | 1 | The record schema version this build emits — **2** here. See [`docs/record-schema.md`](../../record-schema.md). |
| `lib.DEFAULT_RING` | 1 | Default depth of the SavedVariables capture ring (**10**), used when the descriptor omits `ring`. |
| `lib.STRINGS` | 1 | Every user-visible string, keyed for the descriptor's `L` override. |
| `lib.MODULES` | 1 | `{ Perf = <minor>, PerfPanel = <minor> }` — the live minor of every file in this major. |
| `lib:New(descriptor)` | 1 | Build a probe for one host. |

## The descriptor

Everything a host supplies to `lib:New(descriptor)`. Within `LibKa0s-Perf-1.0` the contract is
**additive-only**: a field may be added in a later minor, never removed or repurposed — a host
written against minor 1 keeps working unmodified against any later minor.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `name` | string | yes | 1 | Host identifier. Seeds the default `slash`, the sampler and panel frame names, and `BuildRecord`'s `addon` field. |
| `sv` | string | yes | 1 | The global SavedVariables table name the capture ring is persisted to. Must be declared in the host's TOC. |
| `suspend` | function | yes | 1 | Makes the host inert without a `/reload`. See [the host contract](#the-host-contract-for-suspendresume). |
| `resume` | function | yes | 1 | Restores everything `suspend` took away. See [the host contract](#the-host-contract-for-suspendresume). |
| `log` | function(line) | no | 1 | Console-only sink. Defaults to `print`. |
| `print` | function(line) | no | 1 | Chat-and-console sink, for what the user must see while looking at the game. Defaults to `print`. |
| `showLog` | function | no | 1 | Reveals the host's own log/console window. Defaults to a no-op. The lib owns no console frame of its own, so this is how `start`, `report` and `dump` bring the log into view. |
| `onChange` | function | no | 1 | Called after every state transition, once the panel has already repainted. Lets the host republish on its own message bus. Defaults to a no-op. |
| `L` | table | no | 1 | Locale override, keyed identically to `lib.STRINGS`. **Pass a PLAIN table holding only the keys you actually translate — never an addon-wide locale table.** See [The `L` trap](#the-l-trap). Unlocalised hosts pass nothing and get the built-in English strings. |
| `slash` | string | no | 1 | The command prefix shown in the panel's command column and in `Usage()`/`StatusLines()`. Defaults to `"/" .. name:lower()`. |
| `title` | string | no | 1 | Panel title (before the `— Perf Run` suffix). Defaults to `name`. |
| `ring` | number | no | 1 | Depth of the SavedVariables capture ring. Defaults to `lib.DEFAULT_RING` (10). |
| `buckets` | array of `{ key, within }` | no | 1 | Declares report order and nesting for `Note()` buckets. `within` names the parent bucket key for buckets that nest (e.g. `paintBar` runs inside `repaintPass`). A bracket calling `Note()` with an undeclared key still records, it just doesn't appear in the report. |
| `version` | string | no | 1 | Host addon version, stamped into `BuildRecord`. Defaults to `"?"`. |
| `decorate` | function(frame, api) | no | 1 | Panel chrome hook, called once at frame creation with the frame and `{ Show, Hide, Toggle, TITLE_H, PAD, ROW_W }`. Takes precedence over the lib's own chrome: a host that supplies it draws its own close button and divider, and a host that omits it gets `Core.MakeCloseButton` on the title bar rather than nothing. The two paths are exclusive — running both would stack two × on the same corner. |

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

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `Note(key, ms)` | 1 | Record one bracketed measurement into bucket `key`. |
| `Open()` | **P6** | → `debugprofilestop()`, or **`nil` when the probe is off**. Opens a measurement bracket. See [Bracketing a multi-exit function](#bracketing-a-multi-exit-function). |
| `Close(t0, key)` | **P6** | Close a bracket opened by `Open()`, recording its elapsed ms under `key`. A `nil` `t0` is a **silent no-op**. |
| `Reset()` | 1 | Zero every counter — buckets, completion/review flags, FPS arms. |
| `Log(fmt, ...)` | 1 | Console-only line, colour-stripped. |
| `Announce(fmt, ...)` | 1 | Chat-and-console line, for what the user must see mid-fight. |
| `MarkReviewed(key)` | 1 | Mark a review action (`report`/`dump`) used, without disabling it. |
| `Progress()` | 1 | The run as a table of step states (`ready`/`busy`/`done`/`locked`/`used`/`cancel`), for a panel to render. |
| `Context()` | 1 | Who / where / what, snapshotted once at `Start()`. |
| `ContextLines(ctx)` | 1 | `Context()` rendered as display lines, shared by the chat ack and the report. |
| `BuildRecord(label)` | 1 | Assemble the current capture into the record schema (`docs/record-schema.md`). |
| `Save(record)` | 1 | Append a record to the host's SavedVariables ring, trimming past `ring`. |
| `FormatReport(record)` | 1 | Render a record as plain lines, for `Log`/testing. |
| `Start(label)` | 1 | Begin an experiment. Samples nothing until a window is armed. |
| `Measure(token)` | 1 | Arm window `"a"` or `"b"`; sets suspend state as the independent variable. |
| `Stop()` | 1 | End the experiment, detach the sampler, return the record. **Does not resume.** If Experiment B ran, the host is still inert when `Stop()` returns and stays that way until something calls `Resume()` — a host driving this API directly owns that call. The asymmetry is deliberate: `OnCommand("finish")` resumes *before* it saves, so that an error in `Save` or `FormatReport` cannot strand the addon dead for the session, and it can only order it that way because `Stop()` leaves the suspend state alone. |
| `Cancel()` | 1 | Abandon a run in flight; discards everything, restores the host if suspended. |
| `Suspend()` | 1 | Make the host inert; calls the descriptor's `suspend`. |
| `Resume()` | 1 | Restore the host; calls the descriptor's `resume`. |
| `Usage()` | 1 | Help text lines for the host to print. |
| `OnCommand(args)` | 1 | Run one perf sub-command; returns the chat lines to print. |
| `StatusLines()` | 1 | Phase summary plus `Usage()`, for a bare `perf` with no sub-verb. |
| `ShowPanel()` / `HidePanel()` / `TogglePanel()` | 1 | Show, hide, or toggle the step panel. |
| `RefreshPanel()` | 1 | Repaint every panel row from `Progress()`. |
| `IsPanelShown()` | 1 | Whether the panel frame is currently shown. |
| `STEPS` | 1 | The panel's rows in workflow order, each `{ key, string, label, command }`. `key` indexes `Progress()`, `string` is the `STRINGS`/`L` key, `label` is the resolved text (re-resolved on every repaint, so a locale table filled in after `New()` still lands), and `command` is the sub-verb a click dispatches. |
| `PanelStateOf(key)` | 1 | The current state of one `STEPS` row, straight from `Progress()`. Nil-safe: `"locked"` before there is anything to render. |
| `PanelIsActionable(key)` | 1 | Whether that row may be clicked — `ready`, `cancel` or `used`. A host drawing its own chrome in `decorate` reads these two rather than reaching into `Progress()` itself. |
| `EncodeJSON(value)` | 1 | The lib's hand-rolled JSON encoder, mirrored onto every instance. |
| `SCHEMA` | 1 | The record schema version this build of the lib emits. |
| `on` | 1 | Plain boolean field — read directly by every hot-path bracket. |
| `suspended` | 1 | Plain boolean field, the one the host contract above tells a show-decision to consult. Set by `Suspend()`/`Resume()`; `Stop()` leaves it alone. |
| `__buckets()` / `__fpsArms()` / `__completed()` / `__reviewed()` / `__sampler()` / `__panel()` | 1 | Test seams over state that is otherwise private. A host suite asserting that a declared bucket was actually reached has no other handle on it. |

## Bracketing a multi-exit function

`P.Open()` / `P.Close(t0, key)`, new at `Perf.lua` minor 6. `P.Note` is unchanged, so an existing
host keeps working untouched.

```lua
local t0 = P.Open()
if not pollable(id) then P.Close(t0, "pollSpell") return nil end
if cached[id] then P.Close(t0, "pollSpell") return cached[id] end
...
P.Close(t0, "pollSpell")
return state
```

`Open()` returns `nil` when `P.on` is false, and `Close` treats a `nil` `t0` as a no-op — which is
what collapses **every exit to one unconditional statement** instead of its own
`if __t0 then P.Note(...) end`.

**Why this is in the library rather than in each host.** One adopter's four-exit spell poll paid
that branch per exit, and its own comment records that the instrumentation was originally *omitted*
for exactly that reason — an omission that then cost 73.9 ms of unattributed time in the first live
capture. A measurement seam whose ergonomics discourage instrumenting the multi-exit functions that
most need measuring is a seam with a hole in it.

**Deliberately not a closure-returning `Bracket(key)`.** A closure per bracket allocates on a path
whose entire contract is costing nothing when the probe is off — which is also why `P.on` stays a
plain boolean field on a plain table that every call site reads directly.

The bucket **key set is untouched**, so a host suite pinning "the declared bucket list and the
bracketed call sites agree exactly" keeps passing across the migration from `Note` to the pair.

## The `L` trap

`L` must be a **plain table holding only the keys you actually translate** — never an addon-wide
locale table. Many locale tables carry a metatable whose `__index` answers the key itself, so a
missing `L["STEP_START"]` answers `"STEP_START"` rather than `nil` and the library's own default
never resolves. From `Perf` minor 4 the resolver uses `rawget`, so a metatable-backed table no
longer poisons the lookup — but passing a scoped table is still the contract, because it is the only
form that is correct on every minor.

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed, so a host written against minor 1 keeps working unmodified here.

The **record schema is not**, and that is the deliberate difference. `lib.SCHEMA` is a data contract
rather than an API contract: schema 2 took a clean break from schema 1 with no migration, and old
records are discarded rather than converted. See [`docs/record-schema.md`](../../record-schema.md).

The two files move as one. A consumer holding `Perf.lua` from one vendored copy and `PerfPanel.lua`
from another is not a supported state and LibStub cannot detect it — which is why
`docs/releasing.md` mandates whole-folder re-vendoring.

## Moving to version 7.3

**One breaking change and one addition.** `PerfPanel.lua` does not move.

| Changed at 7.3 | What you do |
|---|---|
| `P.Open()` → `t0` / `P.Close(t0, key)` **became** `P.Open(key)` / `P.Close(key)` | Rewrite the call site. The reading is kept inside the library now, so the local `t0` goes away and the key moves from `Close` to `Open`. **Nothing in the collection held the old spelling** — this is why it was replaced rather than deprecated. |
| `P.Note(key, ms)` **gains** an optional third argument, `parentKey` | Nothing, unless you want it. Pass the bucket the work actually ran inside and the record reports the containment **observed** instead of merely declared. |

Everything else at 7.3 is the library telling the truth where this version did not: the report no
longer states a descriptor's `within` as observed fact, `Cancel()` clears the context stamp it used
to leave standing, `Note`/`Open` name the caller on a nil key, and the `Open`/`Close` docstring no
longer claims the pair is free when capture is off — it is two Lua calls, and this version's
docstring saying otherwise was a defect. No `lib.SCHEMA` bump: the new `observedWithin` and
`observedMixed` bucket fields are optional and additive, so a ring written by this version is read
unchanged.
