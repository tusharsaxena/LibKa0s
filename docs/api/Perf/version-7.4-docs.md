# `LibKa0s-Perf-1.0` — version 7.4

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Perf surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Perf-1.0` |
| Files and minors | `Perf.lua` **7** · `PerfPanel.lua` **4** |
| Version key | `<Perf>.<PerfPanel>`, in load order — the same two numbers `lib.MODULES` reports |
| Shipped in | v1.10.2 |
| Status | **Current** |
| Supersedes | [version 7.3](./version-7.3-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Record schema | 2 — see [`docs/record-schema.md`](../../record-schema.md) |
| Confirm in-game | `LibStub("LibKa0s-Perf-1.0").MODULES` → `{ Perf = 7, PerfPanel = 4 }` |

`Since` names the file and minor a member first appeared in — `P7` for `Perf.lua` minor 7, `PP4`
for `PerfPanel.lua` minor 4. It is `1` for nearly everything: this major did not move at all between
the first tag and minor 6, so every adopter before that version is on the same one.

Adopters today: **AbsorbTracker** (`core/PerfSetup.lua`), **KickCD** (`core/PerfSetup.lua`),
**ConsumableMaster** (`modules/PerfSetup.lua`).

## What this major is

A repeatable A/B performance capture for one host addon: the probe, the guided run, the record
it writes, and the clickable step panel that drives it.

Two files, one major — `Perf.lua` (the probe and the run) and `PerfPanel.lua` (the step panel). One
major for the same reason Options is one: a shell and a panel from different vendored copies is not
a state LibStub can detect. **This is why the version key above is a pair.**

## What changed at this version

**The panel's own close button is told which addon is asking.** `Perf.lua` does not move.

1. **`Core.MakeCloseButton` is called with three arguments** from the panel's no-`decorate` path.
   Core grew a third parameter — the addon's own **folder** name — at Core minor 6, and the catalog's
   `close` icon is drawn only when it is given one; called with two, Core draws the multiplication
   sign it has always drawn. `PerfPanel.lua` minor 3 shipped the two-argument call, so a host that
   passed no `decorate` got a perf panel wearing × beside a debug console wearing the mark.

   A dropped argument is not a failure any layer can report. Core saw no addon name and drew exactly
   what it draws without one, which is a perfectly good button; a texture path that is never built
   draws nothing and raises nothing. The only symptom was the look — the same class of defect, in
   the same week, as the console's own forwarder at DebugLog minor 10.

2. **`addonName` joins the descriptor**, optional, falling back to `name`. `name` is also the
   frame-global prefix (`<name>PerfPanel`, `<name>PerfSampler`), so a host whose window names differ
   from its folder now has somewhere to say which is which. Every host in the collection passes its
   folder name as `name` and needs nothing: **the fix reaches an unmodified host on the re-vendor
   alone.**

3. **A host that passes `decorate` is unaffected**, and still owns the corner outright — the library
   builds no close button on that path. What it must not do is repeat minor 3's mistake at its own
   call site: an addon **MUST** build the control through the single wrapper that carries its folder
   name rather than calling the factory with two arguments (standalone-windows, debug-logging-§12).

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
| `addonName` | string | no | PP4 | The host's own addon **folder** name, from its first vararg — what `Core.MakeCloseButton` builds the `close` icon's texture path from on the no-`decorate` path. Defaults to `name`, which is what every host in the collection already passes, so this is an escape hatch rather than a step. The library is vendored and cannot infer a folder, which is why it has to be told. |
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
| `buckets` | array of `{ key, within }` | no | 1 | Declares report order and nesting for `Note()` buckets. `within` names the parent bucket key for buckets that nest (e.g. `paintBar` runs inside `repaintPass`). A bracket calling `Note()` with an undeclared key still records, it just doesn't appear in the report. **`within` is a claim, and from `Perf.lua` minor 7 the record says whether the capture confirmed it** — see [Verifiable containment](#verifiable-containment). |
| `version` | string | no | 1 | Host addon version, stamped into `BuildRecord`. Defaults to `"?"`. |
| `decorate` | function(frame, api) | no | 1 | Panel chrome hook, called once at frame creation with the frame and `{ Show, Hide, Toggle, TITLE_H, PAD, ROW_W }`. Takes precedence over the lib's own chrome: a host that supplies it draws its own close button and divider, and a host that omits it gets `Core.MakeCloseButton` on the title bar rather than nothing — drawn with `addonName or name`, so it wears the collection's mark rather than the fallback glyph (`PerfPanel.lua` minor 4). The two paths are exclusive — running both would stack two close controls on the same corner. |

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

    -- OPTIONAL FROM PerfPanel MINOR 4, and most hosts should now omit it: the library's own path
    -- draws the same mark from the same factory. It is kept here because it is the shape a host
    -- with real chrome of its own needs.
    --
    -- Built by the addon's OWN close-button factory rather than a lookalike, so the perf panel and
    -- the debug console cannot drift apart. NS.MakeCloseButton is the host's one-line wrapper over
    -- Core's, and it is the single place that says which addon folder the mark's texture path is
    -- built from. CALLING THE FACTORY DIRECTLY WITH TWO ARGUMENTS IS THE BUG THIS MINOR FIXED --
    -- the dropped third argument is the addon name, and a texture path that is never built draws
    -- nothing and raises nothing, so the panel quietly wears × while every suite stays green.
    decorate = function(frame, api)
        if NS.MakeCloseButton then
            local close = NS.MakeCloseButton(frame, api.Hide)
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
| `Note(key, ms, parentKey)` | 1 · `parentKey` **P7** | Record one bracketed measurement into bucket `key`. `parentKey` is optional and names the bucket this work actually ran inside — the **observed** containment. Omitted, nothing is observed and the report says so. Raises, naming the caller, on a nil `key`. |
| `Open(key)` | **P7** (`Open()` was P6) | Open a Shape B measurement bracket on `key`. No-op while the probe is off. See [Bracketing a multi-exit function](#bracketing-a-multi-exit-function). |
| `Close(key)` | **P7** (`Close(t0, key)` was P6) | Close the bracket `Open(key)` opened, recording its elapsed ms under `key` and the enclosing bracket's key as the observed parent. A `Close` with no matching open slot is a **silent no-op**. |
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

## Verifiable containment

`buckets = { { key = "paintBar", within = "repaintPass" } }` is a **claim about where the work
runs**, written once and read months later beside the numbers it is supposed to explain. Through
minor 6 nothing checked it: `within` was copied into every record and printed as a flat containment
sentence, so a wrong declaration was indistinguishable from a right one. One adopter's descriptor
declares two buckets inside a pass neither ever runs in, and every capture it has archived asserts
that containment as fact. **A wrong `within` is worse than none** — a reader who trusts it subtracts
the wrong parent's time.

From minor 7 containment is **supplied at the recording call** and the record carries both values:

```lua
-- Shape A: pass the parent explicitly. The bucket really does run inside `appearance`.
local t0 = Perf.on and debugprofilestop()
NS.ApplyVisibility(bar)
if t0 then Perf.Note("visibility", debugprofilestop() - t0, "appearance") end
```

| Record field | Meaning |
|---|---|
| `within` | what the **descriptor declared** |
| `observedWithin` | the parent a **call site actually passed** — absent when none did |
| `observedMixed` | `true` only where one bucket was observed under two *different* parents |

and the report says which of the three states it is in:

```
(buckets nest: paintBar observed inside repaintPass,
               appearance declares itself within repaintPass — not observed,
               visibility declares itself within repaintPass but was observed inside appearance
               — do not sum)
```

**Why the parent is taken at the recording call rather than inferred from a bracket stack.** The
inline Shape A form — `local t0 = Perf.on and debugprofilestop()` … `Perf.Note(key, …)` — is what
every wired host in the collection actually uses; a stack maintained by `Open`/`Close` would have
observed nothing at all, because there were no `Open`/`Close` call sites to maintain it. Taking the
parent here also keeps adoption **per call site**: a host passes it where it knows the answer, and
gets an honest "declared, not observed" everywhere else.

## Bracketing a multi-exit function

`P.Open(key)` / `P.Close(key)` — Shape B in performance-§2. `P.Note` is unchanged, so a host on the
inline Shape A form keeps working untouched.

```lua
P.Open("pollSpell")
if not pollable(id) then P.Close("pollSpell") return nil end
if cached[id] then P.Close("pollSpell") return cached[id] end
...
P.Close("pollSpell")
return state
```

Both calls are no-ops while `P.on` is false, and a `Close` with no matching open slot is a no-op
too — which is what collapses **every exit to one unconditional statement** instead of its own
`if __t0 then P.Note(...) end`.

**State the cost honestly.** This pair is **not** free when capture is off: it is **two real Lua
calls plus the boolean test inside each**, against the inline form's **none**. Minor 6's docstring
claimed it cost "one boolean test and nothing else, and allocates nothing on either path", which was
simply false. Shape A is therefore the default, and is **mandatory** on anything running per frame
or per combat-log event; where a multi-exit region is also a hot path, restructure it to one exit
rather than paying two calls a frame.

**`Open` takes the key** (it did not, through minor 6). A slot with no identity cannot be matched to
its `Close` and cannot name a parent for a bracket opened inside it — so a bracket nested in another
now records its containment **observed**, which is precisely what minor 6's shape could not do.

**An exit that forgot its `Close` is discarded, not credited.** The leaked slot is dropped when an
enclosing bracket closes rather than being recorded at a stop time it never reached: crediting it
with whatever ran afterwards would put a fabricated number in the report, and a fabricated number is
worse than a missing one.

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
removed or repurposed, so a host written against minor 1 keeps working unmodified here — **with one
exception, in this version, stated rather than buried.**

**`Open` and `Close` changed signature at `Perf.lua` minor 7.** `Open()` → `t0` / `Close(t0, key)`
became `Open(key)` / `Close(key)`. That is a repurposing, not an addition, and it is the only one in
this major's history. It was taken rather than deprecated because a grep of the entire collection —
all eight consumers — finds **zero** `Open` / `Close` call sites: every wired host uses the inline
`Note` form. Carrying a second spelling forever to preserve compatibility with no caller would have
been surface the library keeps for nothing (library-stack-§7, anti-patterns #55). A host that *did*
hold the old spelling gets a Lua error at the call site rather than a silent miscount — `Close(t0,
key)` now reads `t0` as the bucket key and finds no matching slot, so it records nothing.

`Note` is untouched: the third argument is optional, and every two-argument call site keeps its
exact old meaning.

The **record schema is not**, and that is the deliberate difference. `lib.SCHEMA` is a data contract
rather than an API contract: schema 2 took a clean break from schema 1 with no migration, and old
records are discarded rather than converted. See [`docs/record-schema.md`](../../record-schema.md).

`PerfPanel.lua` minor 4 is additive in both directions: `addonName` is a new optional field, and a
host that passes nothing gets a better-looking button from the same call it always made.

The two files move as one. A consumer holding `Perf.lua` from one vendored copy and `PerfPanel.lua`
from another is not a supported state and LibStub cannot detect it — which is why
`docs/releasing.md` mandates whole-folder re-vendoring.
