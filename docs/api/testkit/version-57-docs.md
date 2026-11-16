# `testkit` — version 57

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 56 lists, plus `mock_screen.lua` |
| Version | **57** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased (v1.105.0) |
| Status | **Current** |
| Supersedes | [version 56](version-56-docs.md) — a frame held only by its registration could be collected, and no suite could fake a screen to place a tooltip on |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `57` |

Everything revision 56 describes is unchanged here except what follows. One file is added,
`mock_screen.lua` (LibKa0s#92, plan row LK-92A). Three change: `framework.lua`, whose `Kit.VERSION`
is 57, `mock_events.lua` and `mock_ace.lua` (LibKa0s#75, plan row LK-75). Both rode the one
revision on purpose (design section 3.2): a consumer re-vendors the kit once for v1.105.0.

## What changed

### A registered frame is held while it has a raw registration (LibKa0s#75, half 2)

The client never frees a frame, so a frame an addon made, registered for an event and then let go of
keeps hearing that event. Through revision 56 the kit's only reference to such a frame was
`mock_base.lua`'s weak-keyed `frameSet`, so the next garbage collection freed it, and `M.__fire` and
`M.__registrations()` silently stopped seeing it. A consumer suite that forced a collection lost the
frame's events with no error (OutfitterReborn worked around it in `0694218` by holding the frame
itself).

- **The hold.** `mock_events.lua`'s `Events.decorateFrame` wraps a tracked frame's `RegisterEvent` and
  `RegisterUnitEvent`: once the stub has recorded the registration (after the `__badEvents` check,
  which still raises before anything is recorded or held), the frame goes into a strong set.
- **The release.** `UnregisterEvent` and `UnregisterAllEvents` are wrapped too. After the stub runs,
  the frame leaves the set when both `__frameEvents` and `__unitEvents` are empty. The stub's
  `UnregisterEvent` clears only the raw table, as before, so a frame with a per-unit registration
  left stays held, and stays in the survey.
- **The embedded frame.** `AceEvent:Embed` replaces a frame's `UnregisterAllEvents` with
  `mock_ace.lua`'s, which already cleared the two raw tables. It now releases the hold too, through
  the build's `M.__releaseFrame`.
- **Per build.** The set lives on the build (`M`), never in the module, so a dropped build takes its
  registered frames with it. A module-level hold would keep every build alive through its frames'
  closures, the revision 22 leak `tests/test_mock_base.lua` pins.
- **Unchanged.** `frameSet` stays weak, so a frame that never registered, or whose last registration
  is gone, is still not kept alive by the survey. AceEvent targets were never affected: the
  CallbackHandler fake's lists hold them strongly while they are registered. Half 1 of #75, the
  guarded `unregisterAll`, shipped in revision 51.

### Two build seams

| Member | What it answers |
|---|---|
| `M.__heldFrame(f)` | `true` while the build holds `f` for a raw registration, `false` otherwise |
| `M.__releaseFrame(f)` | Drops the hold on `f` if nothing raw is registered on it; safe on any frame. `mock_ace.lua` calls it, and a consumer's own mock that clears a frame's `__frameEvents` / `__unitEvents` directly calls it too |

Both appear on a build once it has made its first tracked frame. `M.__kitHeldFrames` is the set
itself and is internal.

### A fake screen and a tooltip recorder (LibKa0s#92): `mock_screen.lua`

Through revision 56 every geometry read on a base frame (`GetLeft`, `GetTop`,
`GetEffectiveScale`, `GetCenter`) answered from `mock_base.lua`'s metatable, with the frame itself,
so a tooltip placer that guards its reads (as `LibKa0s-Tooltip-1.0` does) placed nothing and no
suite could assert where a tooltip opened. WowAddonStandards standalone-windows' *Tooltip placement*
asks for exactly that assertion (Verification, SHOULD): "driving the fake screen through a
right-fits and a right-does-not-fit layout and asserting the side, the top alignment and the gap
from the tooltip's recorded points".

**Opt-in**, a file of its own, as `mock_layers.lua` is, because most suites never ask. It returns an
installer, called on a finished mock, which returns the screen:

```lua
local scr = dofile("tests/_kit/mock_screen.lua")(M, { width = 1920, height = 1080, scale = 1 })
```

| Member | What it does |
|---|---|
| the installer `(M, opts)` | Sets `M.UIParent`'s `GetWidth`, `GetHeight`, `GetEffectiveScale`, `GetLeft` (0), `GetBottom` (0), `GetRight`, `GetTop` and `GetCenter` by rawset, from `opts.width`, `opts.height` and `opts.scale` (defaults 1920, 1080, 1). Answers `scr` |
| `scr.restore()` | Puts UIParent's previous raw fields back |
| `scr.resize(w, h, s)` | Moves the screen (each optional) |
| `scr.frame(spec)` | A tracked frame (`M.CreateFrame`) answering `GetLeft`, `GetBottom`, `GetRight`, `GetTop`, `GetWidth`, `GetHeight`, `GetCenter` from `spec.left`, `spec.bottom`, `spec.width`, `spec.height` in its own units (a missing figure answers nil: an unplaced frame), `GetEffectiveScale` (`spec.scale`, 1), `GetParent` (`spec.parent`, UIParent) and `IsShown` (`spec.shown`, true). `frame:__place(l, b, w, h)` moves it |
| `scr.tooltip(spec)` | A tracked frame that records `SetOwner`, `ClearAllPoints`, `SetPoint` and `SetAnchorType` in one ordered log (`tip.__log`), keeps its points (`tip.__points`, the last in `tip.__point`), answers `GetOwner`, `GetAnchorType`, `GetWidth` / `GetHeight` (`spec.width`, `spec.height`, defaults 200 and 80) and `GetEffectiveScale` (`spec.scale`). `tip:__size(w, h)` grows it |
| `scr.rectOf(tip)` | The tooltip's `left, bottom, right, top` in **screen units**, from its last point, when that point is on UIParent or on a frame this screen built; nil otherwise. An unknown point name raises naming it |
| `scr.ops(tip)` | The log's op names in order, as one string (`"SetOwner SetAnchorType ClearAllPoints SetPoint"`) |

Figures a case gives are in the frame's **own** units, as the client's `GetLeft` answers; screen
units are own units times the frame's effective scale. Frames built before the install and frames
the base builds for itself are not touched; `M.GameTooltip` stays the base's, so a suite builds its
tooltip with `scr.tooltip` and hands it to the code under test. Cases in LibKa0s's
`tests/test_mock_screen.lua`; the library's own use is `tests/test_tooltip_place.lua`.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md` (the whole folder, so the new
`mock_screen.lua` arrives with it; nothing loads it unless a suite asks), and run the full suite. A suite that
relied, knowingly or not, on a collection dropping a registered frame (for example a teardown check
that counted `M.__registrations()` after letting the frame go out of scope) now sees the registration
and turns red. That is the client's behavior. A suite that held a frame only to keep its events alive
may drop that hold, but need not.
