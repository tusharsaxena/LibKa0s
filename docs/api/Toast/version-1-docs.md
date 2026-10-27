# `LibKa0s-Toast-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Toast surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Toast-1.0` |
| File | `Toast.lua` minor **1** |
| Shipped in | v1.79.0 (unreleased, opened 2026-10-28) |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (`NEEDS_CORE = 1`) |
| Optional at call time | Core's `ApplySkin` and `MakeCloseButton`, each presence-checked; through them, `LibKa0s-Media-1.0` (the close icon) and `LibKa0s-Skin-1.0` (the owner's skin), neither read by this file |
| Confirm in-game | `LibStub("LibKa0s-Toast-1.0").MODULES` → `{ Toast = 1 }` |

## What this major is

**The alert-toast shell.** A small frame near the top of the screen that shows one alert at a time,
queues the rest, closes itself after a while, and can be placed by the player in the host's test
mode. The library owns that shell; the host owns what the toast says.

It is promoted from Ka0s Drop Watcher's upgrade toast (its `modules/Toast.lua`) under
[LibKa0s#60](https://github.com/tusharsaxena/LibKa0s/issues/60), approved by the owner on
2026-10-25, with Ka0s DPS Race's new-best toast (DpsRace#5) as the second consumer.
`library-stack-§7`'s three bars, as the issue recorded them:

1. **Two consumers, same semantics.** The queue, the lifetime, the drag, the scale and the sound
   behave the same for both.
2. **No per-consumer escape hatches.** The content builder is the one presentation argument. There
   is no combat flag and no queue-or-replace flag: a host that holds toasts in combat does not call
   `Show` in combat (or calls `Hold` and `Release`), and a host that wants a toast to replace
   another calls `Remove` first.
3. **A stable abstraction.** A queued, timed, dismissable alert frame is a long-lived shape.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework.

### It runs beside the v1.77.0 payload

Toast reads nothing from Core beyond `ApplySkin(frame, skin)` and `MakeCloseButton(parent, onClick,
addonName)`, both present in v1.77.0 (Core minor 12) and both checked with `type(...) ==
"function"` at call time. It reads no other major. A consumer may therefore vendor `Toast.lua` alone
beside an older whole-folder copy (Ka0s DPS Race does this ahead of its next full re-vendor, loading
the file from its own TOC after `LibKa0s.xml`), and the only difference is the skin owner:

| Core in the client | The toast's skin | The close mark |
|---|---|---|
| minor 13 or newer, `LibKa0s-Skin-1.0` present, `d.owner` a registered skin owner | the owner's skin, repainted with it (`ApplySkin(frame, nil, owner)` hands the frame to the owner's facade) | the owner's close colors |
| minor 13 or newer, any other case | Core's `SKIN` | Core's mark, the `close` icon when `d.owner` is passed and declared |
| minor 12 (v1.77.0) or older | Core's `SKIN` (the extra argument is ignored) | Core's mark, as above |
| no `ApplySkin` / no `MakeCloseButton` | none: an undecorated frame | none; a right-click still closes |

## Members

Read straight off the LibStub table.

| Name | Since | Meaning |
|---|---|---|
| `Toast:New(d)` | 1 | A new toast instance for descriptor `d` (below). Raises when `d` is not a table or `d.build` is not a function. Builds no frame: the frame is made on the first toast shown. |
| `DURATION` | 1 | `8`: the seconds a toast stays when `d.duration` answers nothing usable. |
| `MAX_QUEUE` | 1 | `5`: payloads that may wait when `d.maxQueue` is absent. |
| `WIDTH` · `HEIGHT` | 1 | `320` · `64`: the frame's size until `d.width` / `d.height` or the builder sets one. |
| `POINT` | 1 | `{ "TOP", "TOP", 0, -160 }`: where a toast sits with no saved and no default position, in UIParent's units. |
| `STRATA` | 1 | `"HIGH"`: frame-layering's T5 alert tier. |
| `PREVIEW` | 1 | `"LibKa0s-Toast-preview"`: the key `Preview` queues under, so `Remove(Toast.PREVIEW)` ends a preview. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Toast-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Toast = <minor> }`. |

## The descriptor

Every field but `build` is optional. A field marked *value or getter* may be a plain value or a
function answering it; a getter is called each time the value is needed (at each show, drag or
`Refresh`), so it reads the host's profile live and a profile switch needs only a `Refresh`.

| Field | Since | Meaning |
|---|---|---|
| `build(frame, payload)` | 1 | **Required, and the one presentation argument.** Draws `payload` on the toast's frame and answers `width, height` (either may be nil to keep the current one), or `false` to skip this payload (the next waiting one is tried). Called each time a payload comes to the screen, so a builder creates its rows once (on its first call, stashed on the frame) and fills them on every call. Runs under `pcall`: a raise is handed to `geterrorhandler()`, costs that payload, and the next one still shows. Anchor rows clear of `frame.close` (top-right, 18 px, 4 px in) when it exists. |
| `owner` | 1 | The host's addon folder name: passed to `ApplySkin` and `MakeCloseButton` (see the table above). |
| `name` | 1 | The frame's global name; nil for an anonymous frame. |
| `width` · `height` | 1 | The frame's size before the builder sets one; `WIDTH` / `HEIGHT` when absent. |
| `duration` | 1 | *Value or getter.* Seconds on screen; anything but a positive number is `DURATION`. |
| `scale` | 1 | *Value or getter.* The frame's own scale; anything but a positive number is `1`. |
| `sound` | 1 | *Value or getter.* `true` plays an alert as each toast shows; anything else is silent. |
| `soundKit` | 1 | *Value or getter.* The `PlaySound` id, played on the `"Master"` channel. Absent: `SOUNDKIT.UI_EPICLOOT_TOAST`, else `SOUNDKIT.RAID_WARNING`. |
| `draggable` | 1 | *Value or getter.* The toast moves with the left button only while this is `true` (the host's test mode). |
| `getPosition()` · `setPosition(point)` | 1 | The saved position, in the host's profile. `point` is `{ point, relativePoint, x, y }` in **UIParent's units**; `setPosition(nil)` is `ResetPosition`. A drag hands the new point to `setPosition`; the shell never stores one itself. |
| `defaultPosition` | 1 | A point table used when `getPosition` answers none; `POINT` when absent. |
| `maxQueue` | 1 | Payloads that may wait; `MAX_QUEUE` when absent. Past it the oldest waiting payload is dropped. |
| `debug(tag, fmt, ...)` | 1 | A debug sink, called under `pcall` with the tag `"TOAST"`: queued, shown, expired, builder failures. |

## The instance

Colon-called (`toast:Show(...)`). The members are copied onto each instance, so a host's degradation
stub mirrors them by name.

| Member | Since | Meaning |
|---|---|---|
| `Show(payload, opts)` | 1 | Queue `payload`; it shows now when nothing is on screen and the toast is not held. `opts.key` names it for `Remove`; `opts.sticky = true` gives it no countdown. Answers `true`. |
| `Dismiss()` | 1 | Close the toast on screen; the next waiting one shows. |
| `Remove(key)` | 1 | Drop every waiting payload queued under `key`, and close the toast on screen when it is `key`'s (the next one shows). Answers how many went; `0` for a nil key. |
| `Clear()` | 1 | **The stand-down hook.** The toast on screen goes, nothing waits, the countdown is canceled and a hold is released, with nothing shown. Builds nothing when nothing was built. |
| `Hold()` | 1 | Stop showing: a toast on screen goes back to the head of the queue (it gets its full duration again when it returns), and `Show` only queues until `Release`. For a host that holds alerts in combat. |
| `Release()` | 1 | Undo `Hold`: what waits shows, the held toast first. |
| `Preview(payload)` | 1 | Test mode's helper: show `payload` now, sticky, under the key `PREVIEW`. A toast on screen goes back to the head of the queue, a previous preview is replaced, and it shows past a `Hold` without releasing it: closing it shows nothing more until `Release`. It closes like any toast, or with `Remove(Toast.PREVIEW)`. |
| `Pause()` · `Resume()` | 1 | Stop the countdown keeping the time left, and resume it with that time (never less than one second). The frame's `OnEnter` / `OnLeave` call them; `OnLeave` resumes only when the pointer is not still over the frame, and otherwise checks every 0.2 seconds until it is, so the resume never depends on a child control's own `OnLeave` (a skin repaint may set the close mark's scripts again). No-ops on a sticky toast. |
| `Attach(widget)` | 1 | Wire a control the builder made: hovering it pauses, leaving it resumes, a right-click on it closes the toast. Uses `HookScript`, so the control's own scripts stay. A non-widget is ignored. |
| `Refresh()` | 1 | Re-read `scale` and the position and re-anchor a built frame (after the host's scale row, or a profile switch). |
| `ResetPosition()` | 1 | `setPosition(nil)`, then re-anchor: the toast goes back to `defaultPosition` or `POINT`. |
| `Current()` | 1 | The payload on screen and its key, or nil. |
| `Stats()` | 1 | `{ built, shown, waiting, held, paused, sticky, key }`, for a host's diagnostics report and suites. |
| `Frame()` | 1 | The frame, or nil before the first toast. Its `close` field is the close mark, when there is one. |

## The frame

Made on the first toast shown, once per instance: `CreateFrame("Frame", d.name, UIParent,
"BackdropTemplate")`, hidden until a payload is drawn.

- **The T5 alert tier** (frame-layering): `HIGH` strata, toplevel, mouse-enabled, clamped to the
  screen. Nothing on it is protected, so it shows and hides in combat.
- **Lifetime.** A toast closes when its countdown ends, on its close mark, or on a right-click
  anywhere on it or on an attached control. A left-click does nothing (the builder's controls keep
  their own clicks, and test mode's drag uses the left button).
- **Placement.** The scale is applied first and the saved point second, divided by the scale; a drag
  stores the frame's point times its scale. So the point is always in UIParent's units, and a scale
  change grows or shrinks the toast about the anchor the player placed without rewriting it (Drop
  Watcher's behavior, kept).

## Adopting it

A host keeps the content, the decision to toast, the settings rows (enable, duration, sound, scale,
the preview) and every string. A sketch, Ka0s DPS Race's shape:

```lua
local _, NS = ...
-- modules/BestToast.lua: the new-best toast on LibKa0s-Toast-1.0 (library-stack-§7).
local Toast = LibStub and LibStub("LibKa0s-Toast-1.0", true)
local function setting(k) return NS.Setting("toast." .. k) end

local function build(frame, best)
    if not frame.line then
        frame.line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.line:SetPoint("TOPLEFT", 10, -10)
    end
    frame.line:SetText(best.text)
    return math.max(240, frame.line:GetStringWidth() + 40), 40
end

NS.BestToast = Toast and Toast:New({
    owner = "DpsRace", name = "DpsRaceBestToast", build = build,
    duration = function() return setting("duration") end,
    scale = function() return setting("scale") end,
    sound = function() return setting("sound") end,
    draggable = function() return NS.State.testMode == true end,
    getPosition = function() return NS.addon.db.profile.toast.point end,
    setPosition = function(pt) NS.addon.db.profile.toast.point = pt end,
}) or NS.ToastStub   -- the degradation stub below
```

The host's stand-down calls `Clear()`; its profile reload calls `Refresh()`; its test mode calls
`Preview(sample)` on, and `Remove(Toast.PREVIEW)` off. Drop Watcher's combat hold becomes `Hold()` on
`PLAYER_REGEN_DISABLED` and `Release()` on `PLAYER_REGEN_ENABLED`, and its "the drop left the feed"
path becomes `Remove(dropId)`.

### The degradation stub

A host that degrades without the library (anti-pattern #47) carries a stub of the **instance**,
since that is what it calls. Each member is a no-op answering what an empty toast answers:

```lua
NS.ToastStub = {
    Show = function() return false end, Dismiss = function() end, Remove = function() return 0 end,
    Clear = function() end, Hold = function() end, Release = function() end,
    Preview = function() end, Pause = function() end, Resume = function() end,
    Attach = function() end, Refresh = function() end, ResetPosition = function() end,
    Current = function() return nil end, Frame = function() return nil end,
    Stats = function() return { built = false, shown = false, waiting = 0, held = false,
        paused = false, sticky = false } end,
}
```

Pin it with a parity case against a live instance (`T.assertSurfaceParity(liveInstance, NS.ToastStub,
"Toast instance")`), the form a Slash or Options instance stub uses; `members-1.json` lists the
lib-level surface, which a host reads through `Toast:New` only.

## What is not here

| Not in Toast-1.0 | Stays in | Re-check trigger |
|---|---|---|
| The content (rows, icons, buttons, tooltips) | each host's builder | — (the one presentation argument) |
| When to toast (qualifying, once per item, after combat) | each host | — |
| A combat flag | the host: it does not call `Show` in combat, or calls `Hold` / `Release` | a design review finds a behavior only the library can express; that would be a reason to reject the promotion (LibKa0s#60 bar 2) |
| Queue-or-replace policy | the host: `Remove(key)` before `Show` | the same |
| A close-reason callback (expired, closed, removed) | — | a host needs to tell a player's close from an expiry |
| Settings rows and strings | each host's schema and locale | an `O.ToastGroup` composer once two hosts' rows converge |
| Fade-in or fade-out animation | — | both hosts ask for one |

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Toast.lua` is an entry in `LibKa0s.xml`, after `Glow.lua`, so the whole-folder copy brings it in
with no load-list change in the host. A host vendoring the file alone ahead of a full re-vendor
(above) lists it in its TOC after `LibKa0s.xml` and records that as a temporary deviation.
