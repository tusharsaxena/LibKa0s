# `LibKa0s-Tooltip-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Tooltip surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Tooltip-1.0` |
| Files and minors | `Tooltip.lua` minor **1** |
| Shipped in | v1.105.0 |
| Status | **Current** |
| Supersedes | — (the first version of this major) |
| Superseded by | — |
| Requires | LibStub only. No `NEEDS_*` floor: the major reads no other LibKa0s major |
| Confirm in-game | `LibStub("LibKa0s-Tooltip-1.0").MODULES` → `{ Tooltip = 1 }` |

## What changed at this version: the major is new (`LK-92A`, LibKa0s#92)

`LK-92A` of Ka0sAddonsCommonTasks `docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/` (design section 3.6,
research notes R2 and R9). WowAddonStandards v2.112.0 (standalone-windows, *Tooltip placement*;
launcher-§7; anti-pattern #119) rules where every tooltip of a Ka0s window, HUD display,
library-drawn window, library menu and minimap button opens, and names a library surface, "LibKa0s
tooltip placement", that is to publish a beside-the-window placer, an attached-centered placer, a
launcher placer and `TIP_GAP = 2`. This major is that surface. It is loaded by `LibKa0s.xml`
directly after `CorePixel.lua`, before every major that will place a tooltip through it.

The library's own sites moved onto the placers in the same release (`LK-92B`): IconBrowser, the
Widgets dropdown, reorder handle and drag handle, SimPanel, Charts, the Launcher's minimap tooltip
and the skin picker (*The library's own sites*, below).

**Amended before the tag, smoke round 1 (`SR-L1`, ruling 2 of Ka0sAddonsCommonTasks
`docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS/SR1_SMOKE_ROUND1.md`).** The owner's first smoke pass found a
tooltip attached below a title-bar mark illegible: it opened where the pointer was. The chrome rule
is now **one rule for every attached tooltip, above the element**, flipping below only when there is
no room above; the pointer hangs down from its hotspot, so above is the side it never covers. The
`zone` argument (`"top"` below, `"bottom"` above) that chose the side is **retired**: no caller
outside the library passed it (the collection's addons were grepped for `PlaceAttached` callers at
the amendment; Ka0s Aura Master's `Anchors.PlaceAttached` is its own, unrelated function), so the
third argument is now `opts`. A string there is no table, so it reads as no options and moves
nothing. Still minor 1: the major is new in this unreleased version.

**Amended before the tag, smoke round 1 (`SR-L2`, ruling 3 of the same `SR1_SMOKE_ROUND1.md`).**
Every title-bar control on every library window carries a tooltip, the debug console's included. The
mechanism is here, beside the placer it uses: `AttachTitleTip`, and the close's words, `CLOSE_STRINGS`,
`SetCloseTip` and `CloseTip` (*The title-bar tooltip*, below). Still minor 1.

## The title-bar tooltip (`SR-L2`)

`AttachTitleTip(btn, words, owner)` hooks a tooltip onto one title-bar control (`HookScript`, so the
control's own hover pair keeps running): on enter, the game tooltip owned by `btn` at `ANCHOR_NONE`,
one line, `words` (a string, or a function of `btn` read on each hover; empty or nil shows nothing),
in `owner`'s `gtip.title` when `owner` is a registered skin owner (through LibKa0s-Core-1.0's facade,
read at hover time; the tooltip's own color otherwise), wrapped, shown, then `PlaceAttached` above the
control (unreadable geometry: `BOTTOM` on its `TOP` + `TIP_GAP`, never the cursor); on leave, hidden
when `btn` still owns it. A second call replaces only the words and the owner. The words are kept on
the control as the private `__titleTip` and `__titleTipOwner`.

Who calls it: `Core.MakeCloseButton` (Core minor 18) for every close, with `CloseTip(addonName)`;
Widgets' `HeaderButtons` for an adopted or host-made close (or the window's `closeTip`); the debug
console for its Debug toggle and Diagnostics link (DebugLogWindow minor 5). Widgets' header marks
show their own `tip` the same way (WidgetsHeader minor 1), and a HUD drag strip's marks through its
descriptors, with the library's words where the host wrote none (WidgetsDragHandleTip minor 1). An
addon's own title-bar controls take it at adoption.

The close's words: `CLOSE_STRINGS` is `{ CLOSE_TIP = "Close" }`; `SetCloseTip(owner, words)` records
`owner`'s own (a translation; `nil` or `""` clears; `false` for an owner that is not a non-empty
string), read on each hover, so one call reaches closes already built; `CloseTip(owner)` answers
them, else `CLOSE_STRINGS.CLOSE_TIP`. The per-owner table (`__closeTips`) is kept across a minor
upgrade, as the groups are.

## What this major is

**Three placers, a window-group registry and the pure solvers behind them.** It owns no frames, no
events and no SavedVariables, and depends on nothing but LibStub: the consumers span Widgets,
Charts, Sim, IconBrowser, the Launcher and every addon, and a leaf major adds no edge between them.

- **The body rule** (`PlaceBeside`): beside the window group, outside its outer edge. The tooltip's
  `TOPLEFT` at the group's right edge + `TIP_GAP` when it fits on the right, else its `TOPRIGHT` at
  the group's left edge - `TIP_GAP`; its top level with the hovered element's top, clamped on
  screen. A companion panel's own tooltips prefer its side away from the main window. When neither
  side fits, the chrome rule above the element, flipping below at the screen's top (rule 4).
- **The chrome rule** (`PlaceAttached`): centered on the element and **above it**, whatever the
  element is (title bar, strip, tabs, filter bar, toolbar, a modal's controls, a HUD's drag strip or
  mover handle, a header mark, a footer, a grip): `BOTTOM` on its `TOP` + `TIP_GAP`. Flipped
  **below**, `TOP` on its `BOTTOM` - `TIP_GAP`, only when the screen has no room above; slid sideways
  only as far as it must. With room on neither side it stays above.
- **The launcher rule** (`PlaceLauncher`): attached to the minimap button, toward the screen's
  center: the vertical side by the screen half the button's center is in (upper half: below the
  button), the horizontal by its third (right third: right edges level; left: left edges; middle:
  centered), `TIP_GAP` off the button.

## How a placement is applied

1. **Own** the tooltip with `Own(tip, element)` (`SetOwner(element, "ANCHOR_NONE")`), or with
   `{ owner = UIParent }` for an element in a restricted layout tree.
2. **Fill and Show** it, so its real width and height are known.
3. **Place** it. The body and chrome placers write **one absolute point on UIParent's
   `BOTTOMLEFT`**, computed here: safe in a restricted tree (a frame under
   `DisableUntrustedLayoutScriptsTemplate` refuses an anchor to it), and the clamp is exact. The
   tooltip does not follow a window dragged while it shows; the pointer leaves on a drag anyway. The
   launcher placer is the one **relative** anchor (the tooltip's point on the button's), because a
   minimap button is not restricted and a relative point needs no size.
4. If the tooltip grows later (item data arriving after Show), `Replace(tip)` runs the same placer
   again with the same arguments.

**Units.** Every edge is read in screen units: a frame's `GetLeft` / `GetBottom` / `GetRight` /
`GetTop` times its own `GetEffectiveScale()`, and the screen is UIParent's width and height times
UIParent's effective scale. A point is written back in the tooltip's own units (divided by the
tooltip's effective scale), so a window at 0.8 and a tooltip at 1.0 measure in one space, and the
gap is `TIP_GAP` screen units under every skin and scale (skinning-§4, *Geometry is
skin-invariant*).

**Comparison tooltips** (body rule 5). Before its point, `PlaceBeside` calls
`tip:SetAnchorType("ANCHOR_RIGHT" | "ANCHOR_LEFT", 0, 0)` for the side it chose, so the client's
comparison manager opens `ShoppingTooltip1` / `ShoppingTooltip2` further out on the same side. It is
called **before** `ClearAllPoints` and `SetPoint`, in the order the client's own bag uses (its item
tooltip anchors call `SetAnchorType` and then `SetPoint`), so an anchor type that re-anchors the
tooltip cannot undo the point. That the point survives in game is a smoke check
(`docs/smoke-tests.md` of each window's host; item tooltip plus Shift-compare near the right edge).
The fallback above or below the element sets no anchor type. `opts.comparisons = false` skips it.

**Unreadable geometry.** A geometry read that is not a plain number answers nil: an unplaced frame,
a method that answers something else, or a **secret value** (`issecretvalue`, read bare at call time,
so no arithmetic ever touches one). A placer whose screen, tooltip or element cannot be read writes
**nothing** and answers nil, so the caller keeps its own anchor; its fallback is `PlaceAttached`,
then a plain attach on the element, **never the cursor**. `opts.rect(frame)` answers a frame's
`left, bottom, right, top` in screen units in place of the reads, for a host that can read a frame
the library cannot (Ka0s Aura Master's strip rect, read through its own secret guard); a non-number
from it counts as unreadable. A body tooltip whose window group cannot be read (but whose element
can) takes the fallback above the element.

## Window groups

The body rule measures the **whole window group**: the window plus every frame docked to it that
moves with it (standalone-windows' *Terms*). `PlaceBeside`'s `group` argument says what it is:

| `group` | Means |
|---|---|
| a frame | that frame alone |
| a list of frames | those frames, the first one the main window |
| `{ main = frame, panels = { ... } }` | `main` and every **shown** panel |
| a function | called on each placement; answers one of the above |
| `nil` | `GroupOf(element)` |

`SetGroup(window, companions)` registers a window and the frames docked to it (a list, or a function
answering one, re-read on each hover so a hidden panel drops out). `GroupOf(element)` then answers
`frames, main, host`: the nearest ancestor of the element (or the element) that is a registered
window or one of its companions decides the group, `frames` being the window and its **shown**
companions (main first) and `host` the member the element is in. With no registered ancestor, the
outermost ancestor under UIParent is a group of one (`frames = { outer }`, `main = host = outer`). A
menu's entries pass the **menu frame** as the group (body rule 6).

The companion side: when `host` is not the main window, the tooltip prefers the side `host` lies on
relative to the main window's center, so a panel docked on the main window's right opens its tooltips
on its right, and when that side does not fit the tooltip goes outside the group's other outer edge,
beyond the main window. Either way it sits outside the whole group. `opts.prefer` overrides.

## Lib-level surface

| Member | Kind | Since | Contract |
|---|---|---|---|
| `TIP_GAP` | number | 1 | `2`, the gap in screen units between a tooltip and what it is placed against. Read it; the placers read a file-local, so a write moves no tooltip. |
| `Own(tip, element, opts)` | function | 1 | `tip:SetOwner(opts.owner or element, "ANCHOR_NONE")`; answers `tip`. A non-table tooltip or one without `SetOwner` is answered untouched. |
| `PlaceBeside(tip, element, group, opts)` | function | 1 | The body rule on a shown tooltip. `group` as the table above. `opts`: `prefer` (`"right"` \| `"left"`), `comparisons` (`false` skips `SetAnchorType`), `rect` (above). Answers `"right"`, `"left"`, the fallback's `"above"` / `"below"`, or nil with nothing placed when the geometry cannot be read. |
| `PlaceAttached(tip, element, opts)` | function | 1 | The chrome rule on a shown tooltip. `opts.rect` as above; a non-table third argument (the retired `zone`, `"top"` or `"bottom"`) is read as no options and chooses nothing. Answers `"above"` (the tooltip's `BOTTOM` at the element's top + gap) or `"below"` (its `TOP` at the element's bottom - gap, only when there is no room above), or nil with nothing placed. |
| `PlaceLauncher(tip, button, opts)` | function | 1 | The launcher rule: `ClearAllPoints`, then `SetPoint(point, button, relativePoint, 0, ±TIP_GAP / tooltipScale)`. Answers the tooltip's point (`"TOPRIGHT"`, `"BOTTOM"`, ...), or nil with nothing placed. |
| `SetGroup(window, companions)` | function | 1 | Registers `window` as a group's main frame with `companions` (a list, or a function answering one). `nil` registers the window alone; `false` removes the registration. Weak-keyed: a released window is not kept alive. |
| `GroupOf(element)` | function | 1 | `frames, main, host` (above), or nil for a non-table. |
| `AttachTitleTip(btn, words, owner)` | function | 1 | Hooks a title-bar control's tooltip (*The title-bar tooltip*): `words` a string or a function of `btn`, in `owner`'s `gtip.title`, above the control. Answers `btn`, or nil for a non-frame. A second call replaces the words and the owner. |
| `CLOSE_STRINGS` | table | 1 | `{ CLOSE_TIP = "Close" }`, a close's default tooltip words. |
| `SetCloseTip(owner, words)` | function | 1 | Records `owner`'s own words for its closes; `nil` or `""` clears. Answers `true`, or `false` for an owner that is not a non-empty string. |
| `CloseTip(owner)` | function | 1 | `owner`'s words, else `CLOSE_STRINGS.CLOSE_TIP`. |
| `Replace(tip)` | function | 1 | Runs `tip`'s last placement again with the same arguments; answers what that placer answers, or nil when nothing was placed on it yet. The last call is kept on the tooltip as the private `__ka0sTip`. |
| `__solveBeside(gl, gr, elemTop, tipW, tipH, screenW, screenH, gap, prefer)` | function | 1 | Pure. `side, point, x, y` (`"right", "TOPLEFT", gr + gap, y` or `"left", "TOPRIGHT", gl - gap, y`, with `y` the element's top clamped so the tooltip stays on screen), or nil when neither side fits. Right fits when `gr + gap + tipW <= screenW`, left when `gl - gap - tipW >= 0`; `prefer = "left"` tries the left first. |
| `__solveAttached(el, eb, er, et, tipW, tipH, screenW, screenH, gap)` | function | 1 | Pure. `side, point, x, y`: `"above", "BOTTOM", cx, et + gap` or `"below", "TOP", cx, eb - gap`, `cx` the element's center slid so the tooltip stays on screen (its left edge on the screen's when it is wider than the screen). Above (room when `et + gap + tipH <= screenH`) unless there is no room above and room below (`eb - gap - tipH >= 0`); with room on neither side, above. A tenth argument, the retired zone, is ignored. |
| `__solveLauncher(bl, bb, br, bt, screenW, screenH, gap)` | function | 1 | Pure. `point, relativePoint, dx, dy`: `<V><H>` on `<opposite V><H>`, `<V>` `TOP` when the button's center is above the screen's middle (`dy = -gap`) and `BOTTOM` otherwise (`dy = gap`), `<H>` `RIGHT` past two thirds, `LEFT` under one third, else empty; `dx` 0. |

Every solver figure is in screen units from the screen's bottom-left. The solvers touch no frame, so
a host test can drive them directly. `MAJOR`, `MINOR` and `MODULES` are the usual bookkeeping, and
`__groups` (the registry) and `__closeTips` are private. None of these, and none of the three `__solve*` (a leading
`__` is outside `Kit.publicMembers`' surface), is in the member manifest, `members-1.json`, so a
library-absent stub need not carry them; they are documented here because a host test may call them.

## Testing a host's placements

Kit revision 57 ships `tests/_kit/mock_screen.lua`, an opt-in fake screen and tooltip recorder
(`docs/api/testkit/version-57-docs.md`). Install it on the suite's mock, build the window, its rows
and a tooltip on it, place, and read the tooltip's landed rect back in screen units:

```lua
local scr = dofile("tests/_kit/mock_screen.lua")(M, { width = 1920, height = 1080 })
local win = scr.frame{ left = 1500, bottom = 300, width = 300, height = 400 }
local row = scr.frame{ left = 1500, bottom = 580, width = 300, height = 20, parent = win }
local tip = scr.tooltip{ width = 250, height = 90 }
Tip.Own(tip, row); Tip.PlaceBeside(tip, row, win)       -- "left"
local l, b, r, t = scr.rectOf(tip)                       -- r == 1498, t == 600
scr.restore()
```

That is the standard's headless SHOULD (*Tooltip placement*, Verification): a right-fits and a
right-does-not-fit layout, asserting the side, the top alignment and the gap from the recorded
points. This repo's own cases are `tests/test_tooltip.lua` (the solvers) and
`tests/test_tooltip_place.lua` (the placers).

## The library's own sites (`LK-92B`)

Every library tooltip goes through these placers in the same release, each reading this major at
call time, and attaching above its element by a relative point (`BOTTOM` on its `TOP`, 0, 2) when a
placer answers nil:

| Site | Placer | Element and group |
|---|---|---|
| IconBrowser cell | `PlaceBeside` | the cell; the browser window |
| IconBrowser toolbar control | `PlaceAttached` | the control |
| Dropdown and context-menu entry (a string, or a host renderer's tooltip it showed, owned by the row) | `PlaceBeside` | the entry; its menu level |
| ReorderList handle | `PlaceBeside` | the handle; `GroupOf` |
| SimPanel control and step row | `PlaceBeside` | the control; `GroupOf` (the panel) |
| DragHandle strip and marks | `PlaceAttached`, owned by UIParent | the strip (a mark places by its strip); a host `tooltipPlace` answering `true` wins |
| Charts default tooltip, and `ctx:PlaceTip` for a host's own | `PlaceBeside` | the mark; `host.group`, else `GroupOf` |
| Launcher, LibDBIcon's tooltip on the addon's own button | `PlaceLauncher` | the button |
| Skin picker toolbar (gear, eye, dropdown) | `PlaceAttached` | the control |
| Header mark (`W.HeaderButtons`, every library window's title-bar strip) | `PlaceAttached` | the mark |
| Title-bar control (`AttachTitleTip`: every close, the console's toggle and Diagnostics link; `SR-L2`) | `PlaceAttached` | the control |

`tests/test_tooltip_sites.lua` drives each on the fake screen, and `tests/test_tooltip_guard.lua`
holds the payload, outside the Settings-canvas Options files, to no `ANCHOR_CURSOR`,
`ANCHOR_CURSOR_RIGHT`, `ANCHOR_RIGHT` or `ANCHOR_TOP`, with a closed allowlist (the comparison side
here, and the Charts host seam's legacy anchors).

## What a consumer owes

Nothing at the re-vendor of the tag that ships it beyond the re-vendor itself: a host whose tests
load library files by name adds `Tooltip.lua` after `CorePixel.lua`. Moving the host's own tooltip
placements onto the placers is its adoption item under LibKa0s#92, which the standard's v2.113.0
wording owes at adoption, not at the re-vendor.
